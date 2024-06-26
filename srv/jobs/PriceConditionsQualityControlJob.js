const cds = require('@sap/cds');
const BaseJob = require('./BaseJob');
const core = require('@sap-cloud-sdk/core');
const ServiceHelper = require('../utils/ServiceHelper');
const axios = require('axios');
const qs = require("qs");

module.exports = class PriceConditionQualityControl extends BaseJob {

    constructor(jobName,jobTime) {
        super(jobName,jobTime);
        this.jobName = jobName.toUpperCase();
        this.startTime = 0;
        this.failed = 0;
        this.success = 0;
        this.numberOfRecords = 0;
    }

     /**
     * Triggered when job has started
     */
    //override
    async onTick() {

        console.log(`JOB (${this.jobName }): Processing started ...`);
        this.startTime = new Date().getTime();
        this.db = await cds.connect.to('db');

        try {
            // Fetch data
            const customerPricesQC = await this.getCustomerPricesQC();
            this.numberOfRecords = customerPricesQC.length;

            // Process data
            await this.processCustomerPricesQC(customerPricesQC);

            // log finish
            this._finishMessage(this.numberOfRecords);

        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Processing failed. \n\nCause: ${error}`);
            //throw error;
        }
    }

    async _onProcessingSuccess (){
        this.success++;
    }

    /**
     * Logs and updates the status of the processed record in case of an error
     * @param {*} error 
     */
    async _onProcessingFail (error){
        this.failed++;
        console.log(error);
    }

    _finishMessage(processed){
        const end = new Date().getTime();
        const time = end - this.startTime;
        console.log(`JOB (${this.jobName }): Processing completed. - Processed: ${processed} Success: ${this.success} Failed: ${this.failed} - Execution time: ${time} ms`);
    }

    /**
     * Gets CustomerPricesQC records with status 'ToCheck'
     * @returns {Promise}
     */
    getCustomerPricesQC() {
        const { CustomerPricesQC } = this.db.entities("com.bayer.SXTENDER.PriceAgreementData");
        return SELECT.from(CustomerPricesQC).where({Status: 'ToCheck'});
    }

    /**
     * Updates CustomerPricesQC
     * @param {*} customerPriceQC 
     * @returns {Promise}
     */
    updateCustomerPriceQC(tx, customerPriceQC){
        if(!customerPriceQC) return false;
        const { CustomerPricesQC } = this.db.entities("com.bayer.SXTENDER.PriceAgreementData");
        return tx.run(UPDATE(CustomerPricesQC).with(customerPriceQC).where({ ID: customerPriceQC.ID }));
    };


    /**
     * Runs the given function as detached continuation in a specified event context.
     * @see https://cap.cloud.sap/docs/node.js/cds-context-tx#cds-spawn
     * @async
     * @callback Even though the callback function is executed as a background job, all asynchronous operations inside the callback function must be awaited. Otherwise, transaction handling does not work properly.
     * @param {*} fn 
     * @returns {Promise}
     */
    _runDetached(fn){
        return new Promise((resolve, reject) => {
            cds.spawn (fn)
            .on('succeeded', resolve)
            .on('failed', reject)
        })
    }
    
    async processCustomerPricesQC(customerPricesQC){

        if(!customerPricesQC || customerPricesQC.length <= 0) return;

        const spawnPromises = [];
        for(let qcPrice of customerPricesQC){

            spawnPromises.push(
                this._runDetached(async (tx) => {

                    // 1. create SAP request message
                    const requestMessage = this.createRequestMessage(qcPrice); 

                    // 2. get SAP response 
                    const response = await this.getPriceConditionFromSAP(qcPrice.CountryCode,requestMessage);

                    // 3. get response item
                    let item;
                    if(qcPrice.KSCHL === "YA01" || qcPrice.KSCHL === "YA03"){
                        item = response["data"]?.["_-BAY0_-GZ_FAST_PRIC_COND.Response"]?.["LT_OUT_FREE_PRICE_COND"]?.["item"];
                    }else {
                        item = response["data"]?.["_-BAY0_-GZ_FAST_PRIC_COND.Response"]?.["LT_OUT_PRICE_COND"]?.["item"];
                    }

                    // 4. map and validate response 
                    if(item){
                        if(!Array.isArray(item)){

                            // if(item.DATAB === qcPrice.DATAB && item.DATBI === qcPrice.DATBI){
                            //     qcPrice = this.mapResponseToFASTCustomerPricesQC(item, qcPrice);
                            //     qcPrice.Status = this.validatePriceCondition(qcPrice);
                            // }

                            if(qcPrice.KSCHL === "YA03"){
                                if(item.DATAB === qcPrice.DATAB && item.DATBI === qcPrice.DATBI && item.KNRMAT === qcPrice.BOMAT){
                                    qcPrice = this.mapResponseToFASTCustomerPricesQC(item, qcPrice);
                                    qcPrice.Status = this.validatePriceCondition(qcPrice);
                                }  
                            }else if(item.DATAB === qcPrice.DATAB && item.DATBI === qcPrice.DATBI){
                                qcPrice = this.mapResponseToFASTCustomerPricesQC(item, qcPrice);
                                qcPrice.Status = this.validatePriceCondition(qcPrice);
                            }
                            else{
                                if(qcPrice.CountChecks < 10) qcPrice.CountChecks++;
                                else qcPrice.Status = "NotInSAP";
                            }
                        }
                        else{

                            // item = item.find(i => i.DATAB === qcPrice.DATAB && i.DATBI === qcPrice.DATBI);

                            if(qcPrice.KSCHL === "YA03"){
                                item = item.find(i => i.DATAB === qcPrice.DATAB && i.DATBI === qcPrice.DATBI && i.KNRMAT === qcPrice.BOMAT);
                            }else{
                                item = item.find(i => i.DATAB === qcPrice.DATAB && i.DATBI === qcPrice.DATBI);  
                            }

                            if(item){
                                
                                qcPrice = this.mapResponseToFASTCustomerPricesQC(item, qcPrice);
                                qcPrice.Status = this.validatePriceCondition(qcPrice);
                            }
                            else{
                                if(qcPrice.CountChecks < 10) qcPrice.CountChecks++;
                                else qcPrice.Status = "NotInSAP";
                            }
                        }                           
                    }else{
                        if(qcPrice.CountChecks < 10) qcPrice.CountChecks++;
                        else qcPrice.Status = "NotInSAP";
                    }

                    // 5. update PriceCondition QC
                    await this.updateCustomerPriceQC(tx, qcPrice);
                    
                })
                .then(this._onProcessingSuccess.bind(this))
                .catch(this._onProcessingFail.bind(this))
            );
            
        };

        return Promise.all(spawnPromises);

    }

    
    createRequestMessage(qcPrice){
        const conditionType = qcPrice.KSCHL;
        return {
            "_-BAY0_-GZ_FAST_PRIC_COND": {
              "IT_INPUT_COND": {
                "item": [
                  {
                    "VKORG": qcPrice.VKORG,
                    "KSCHL": qcPrice.KSCHL,
                    "KUNNR": qcPrice.KUNNR,
                    "MATNR": qcPrice.MATNR,
                    "YCIG": qcPrice.YCIG
                  }
                 
                ]
              },
              "IV_PRICE_COND": (conditionType !== "YA01" &&  conditionType !== "YA03") ? "X" : "",
              "IV_FREE_COND": (conditionType === "YA01" ||  conditionType === "YA03") ? "X" : ""
            }
        }
          
    }

    mapResponseToFASTCustomerPricesQC(response, qcPrice){
        return Object.assign({}, qcPrice, {
            SAP_VKORG : response.VKORG || null,
            SAP_KSCHL : response.KSCHL || null,
            SAP_KUNNR : response.KUNNR || null,
            SAP_MATNR : response.MATNR || null,
            SAP_YCIG  : response.YCIG || null,          
            SAP_KBETR : response.KBETR || null,   
            SAP_KPEIN : response.KPEIN || null,   
            SAP_KONWA : response.KONWA || null,   
            SAP_DATAB : response.DATAB || null,   
            SAP_DATBI : response.DATBI || null,   
            SAP_VTWEG : response.VTWEG || null,   
            SAP_MAKTX : response.MAKTX || null,   
            SAP_DISPKNRMM : response.DISPKNRMM || null,
            SAP_DISPKNRNM : response.DISPKNRNM || null,
            SAP_KNRME : response.KNRME || null,   
            SAP_DISPKNRZM : response.DISPKNRZM || null,
            SAP_KNREZ : response.KNREZ || null,   
            SAP_KNRDD : response.KNRDD || null,   
            SAP_KPMEIN : response.KPMEIN || null,  
            SAP_KNRMAT : response.KNRMAT || null  
        }); 
    }


    validatePriceCondition(qcPrice){

        if(qcPrice.KSCHL === "YLTP" && qcPrice.CountryCode === "IT"){
            if (
                this.roundKBETR(qcPrice.KBETR) === this.roundKBETR(qcPrice.SAP_KBETR)
                && qcPrice.DATAB === qcPrice.SAP_DATAB
                && qcPrice.DATBI === qcPrice.SAP_DATBI
            )
            {
                return "OK";
            }
        }

        if(qcPrice.KSCHL === "YL60" || qcPrice.KSCHL === "YDC0"){
            if (
                this.formatKBETR(qcPrice.KBETR.slice(0,qcPrice.KBETR.length -1)) === this.formatKBETR(qcPrice.SAP_KBETR)
                && qcPrice.DATAB === qcPrice.SAP_DATAB
                && qcPrice.DATBI === qcPrice.SAP_DATBI
            )
            {
                return "OK";
            }
        }
        
        if((qcPrice.KSCHL === "YLTP" && qcPrice.CountryCode === "ES") || qcPrice.KSCHL === "YLTF"){
            if (
                this.roundKBETR(qcPrice.KBETR) === this.roundKBETR(qcPrice.SAP_KBETR)
                && qcPrice.KPEIN === qcPrice.SAP_KPEIN
                && qcPrice.DATAB === qcPrice.SAP_DATAB
                && qcPrice.DATBI === qcPrice.SAP_DATBI
            )
            {
                return "OK";
            }
        }

        if(qcPrice.KSCHL === "YA01" || qcPrice.KSCHL === "YA03"){
            if (
                qcPrice.DATAB === qcPrice.SAP_DATAB
                && qcPrice.DATBI === qcPrice.SAP_DATBI
                && this.addLeadingZeros(qcPrice.BOMAT,18) === qcPrice.SAP_KNRMAT
                && this.roundKBETR(qcPrice.KSTBM) === this.roundKBETR(qcPrice.SAP_DISPKNRZM)
                && this.roundKBETR(qcPrice.MIKBAS) === this.roundKBETR(qcPrice.SAP_DISPKNRMM)
                && this.roundKBETR(qcPrice.MXBAS) === this.roundKBETR(qcPrice.SAP_DISPKNRNM)
            )
            {
                return "OK";
            }
        }

        return "Failed";

    }

    /**
     * fotmat value from -12.00 to 12.000-
     * @param {string} val 
     * @returns 
     */
    formatKBETR(val){
        return Math.abs(val).toFixed(2).concat("-");
    }

    /**
     * round given value
     * @param {string} val 
     * @returns 
     */
    roundKBETR(val){
        return Number(val).toFixed(2);
    }

    async getPriceConditionFromSAP(countryCode, body){
        if (!body) {
            throw Error("The body of the request is missing.");
        }
        
        const { SchedulerApiConfig } = this.db.entities("com.bayer.SXTENDER.AdminData");
        const apiConfig = await SELECT.one.from(SchedulerApiConfig).where({Provider:'PriceAgreement', CountryCode: countryCode, Resource: "PriceConditionQC"});
        const url = `${apiConfig.Host}${apiConfig.BasePath}${apiConfig.ResourcePath}`;
        const oauthCredentials = await this.getBearerToken();

        console.log(`JOB (${this.jobName }): Calling ${url} ...`);

        return axios({
            method: 'post',
            url: url,
            headers: {
                'Authorization': `Bearer ${oauthCredentials.data.access_token}`,
                'Content-Type': 'application/json'
            },
            data: JSON.stringify(body)
        });
        
    };


    async getBearerToken() {
        const { SchedulerApiConfig, SchedulerApiConfigOAuth } = this.db.entities("com.bayer.SXTENDER.AdminData");

        // get api config
        const priceAgreementApi = await cds.run(SELECT.one.from(SchedulerApiConfig).where({Provider:'PriceAgreement', Resource: 'PriceConditionQC'}));
        const oauthAuth  = await cds.run(SELECT.one.from(SchedulerApiConfigOAuth, priceAgreementApi.OAuth_ID));
        
        if (oauthAuth.OAuthProvider && oauthAuth.ClientID && oauthAuth.ClientSecret) {
            console.log(`Calling ${oauthAuth.OAuthProvider}`);
            return axios({
                method: 'post',
                url: oauthAuth.OAuthProvider,
                headers: {
                    'Authorization': `Basic ${Buffer.from(`${oauthAuth.ClientID}:${oauthAuth.ClientSecret}`).toString('base64')}`,
                    'Content-Type': 'application/x-www-form-urlencoded'
                },
                data: qs.stringify({
                    'grant_type': oauthAuth.GrantType
                })
            });
        }

        throw Error("Missing OAUTH config parameters");
    };

    addLeadingZeros (num, size) {
        if (num === null) {
            throw new Error(`${num} doesn't exist`);
        }
        
        num = num.toString();
        while (num.length < size) num = "0" + num;
        return num;
    };


};