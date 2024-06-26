const cds = require('@sap/cds');
// const BaseCron = require('cron-es6');
const BaseJob = require('./BaseJob');
const core = require('@sap-cloud-sdk/core');
const ServiceHelper = require('../utils/ServiceHelper');
const axios = require('axios');
const qs = require("qs");

module.exports = class ExtendPriceAgreements extends BaseJob {

    constructor(jobName,jobTime) {
        super(jobName,jobTime);
    }

     /**
     * Triggered when job has started
     */
    //override
    async onTick() {

        console.log('Update expiry date started ...');

        try {
            this.db = await cds.connect.to('db'); 
            let aUpdatedPriceAgreements = await this.updatePriceAgreementExpiration();
            await this.syncPriceAgreements(aUpdatedPriceAgreements);
        } catch (error) {
            console.log(error);
        }

        // when the job has finished, call the stop()
        // this will trigger onComplete method
        // this.stop();
        console.log('Updating expiry dates finished.');
    }

    //this code is copied from pag-service file - make sure that these ones are in sync -- add comment to pag-service.js so we don't forget to do this in both places
    async syncPriceAgreements(ids){
        const { CustomerPrices } = this.db.entities("com.bayer.SXTENDER.PriceAgreementData");

        if(ids.length === 0){
            throw `No price agreements found for synchronization`;
        }

        const tx = cds.tx();
        const customerPrices = await tx.run(SELECT.from(CustomerPrices).where({ PriceAgreementId: { in: ids } }));
        if (customerPrices && customerPrices.length <= 0) {
            throw `No customer prices were found for the following PriceAgreement: ${ids}`;
        }
        const mainPriceConditions = customerPrices.filter(item => item.PriceCondition === "YLTP" || item.PriceCondition === "YLTF" || item.PriceCondition === "YL60" || item.PriceCondition === "YDC0");
        const updateMainConditionPromises = mainPriceConditions.map(custPrice => {
            return this.updateCustomerPrice(custPrice, tx);
        });
        // Synchronize
        let result = await Promise.all(updateMainConditionPromises); 
        // Set 'Synchronized' to true and add IDOC number from the response
        result = result.filter(res => res !== undefined);
        result.length > 0 && await this.updateCustomerPrices(result, mainPriceConditions); // !!the order of PriceCondition arrays is important

        return result;
    };

    async updateCustomerPrices(response, priceConditions){
        const { CustomerPrices } = this.db.entities("com.bayer.SXTENDER.PriceAgreementData");

        const tx = cds.tx();
        const refIdocIDs = response && response.map(res => res.headers.sapidocdbid) || [];
        const customerPriceIDs = priceConditions && priceConditions.map(condition => condition.ID) || [];
        if(refIdocIDs.length === customerPriceIDs.length){
            try {     
                const updatePromises = refIdocIDs.map((IdocID, index) => {
                    return tx.run(UPDATE(CustomerPrices).with({Synchronized: true, RefIdocNumber: IdocID}).where({ ID: customerPriceIDs[index] }));
                });
                await Promise.all(updatePromises);
                await tx.commit();
            } catch (error) {
                await tx.rollback(error);
            }
        }
    };
    //EHQUT-219174-Spain issue with the synchronization of price agreements only on regions
    async updateCustomerPrice(customerPrice, tx){
        
        const { PT_TMINST, PT_TMPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const { PT_TMOFRS, PT_TMTEND, PriceCondition } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
        const { PriceAgreements } = this.db.entities("com.bayer.SXTENDER.PriceAgreementData");

        let customerPricesQC = [];
        const effectiveDate = new Date(customerPrice.EffectiveDate);
        const expiryDate = new Date(customerPrice.ExpiryDate);
        const whereInstituteId = ServiceHelper.buildFullWhere("InstituteID", "=", customerPrice.InstituteId);
        const whereCountry = ServiceHelper.buildFullWhere("CountryCode", "=", customerPrice.CountryCode);

        let institute = await tx.run(SELECT.one.from(PT_TMINST).where(whereCountry).where(whereInstituteId));
        const body = await this.getPriceAgreementRequestBodyTemplate(institute); 
        if (!institute) {
            console.error(`No institute was found for InstituteID: ${customerPrice.InstituteId}`);
            return;
        }

        if(customerPrice.CountryCode === 'ES' && institute.InstituteType === 'Ship-To') return Promise.resolve(); //Customer prices should not be synchronized for ship to parties

        const wherePriceAgreementId = ServiceHelper.buildFullWhere("Id", "=", customerPrice.PriceAgreementId);
        let priceAgreement = await tx.run(SELECT.one.from(PriceAgreements).where(wherePriceAgreementId));
        if (!priceAgreement) {
            console.error(`No priceAgreement was found for PriceAgreementID: ${customerPrice.PriceAgreementId}`);
            return;
        }
        const whereOfferID = ServiceHelper.buildFullWhere("OfferID", "=", priceAgreement.OfferId);
        const whereProductpackID = ServiceHelper.buildFullWhere("PRODUCTPACKID", "=", customerPrice.ProductPackId);
        let offer = await tx.run(SELECT.one.from(PT_TMOFRS).where(whereOfferID));     
        if (!offer) {
            console.error(`No offer was found for OfferID: ${priceAgreement.OfferId}`);
            return;
        }

        const tender = await tx.run(SELECT.one.from(PT_TMTEND).where({TenderID: priceAgreement.TenderId}));

        let packFactor;
        if(customerPrice.ProductPackId){
            let productPack = await tx.run(SELECT.one.from(PT_TMPRDPCK).where(whereProductpackID));
            packFactor = productPack.PACKFACTOR;
        } else {
            packFactor = 1;
        }

        let kbetr = parseFloat(customerPrice.Price);
        
        // Spain only
        if(customerPrice.CountryCode === 'ES'){
            const wherePriceAgreement_ID = ServiceHelper.buildFullWhere("PriceAgreement_ID", "=", customerPrice.PriceAgreementId);
            const wherePriceConditionCode = ServiceHelper.buildFullWhere("PriceConditionCode", "=", customerPrice.PriceCondition);
            let priceCondition = await tx.run(SELECT.one.from(PriceCondition).where(wherePriceAgreement_ID).where(wherePriceConditionCode));     
            if (!priceCondition) {
                console.error(`No priceCondition was found for PriceAgreementID: ${customerPrice.PriceAgreementId}`);
                return;
            }
            // set KBETR value
            if(customerPrice.PriceCondition === "YLTF" || customerPrice.PriceCondition === "YLTP"){
                kbetr = Number(priceCondition.NetPriceWithoutTaxBeforeDeductionRD * 10000).toFixed(2);
                body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG.E1KONH.E1KONP.KPEIN = 10000;
                body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG.E1KONH.E1KONP.KRECH = "C";   
            } else {
                kbetr = priceCondition.Discount * 100;
            }
            // set KRECH for Descuento Comercial and Descuento Comercial 
            if (customerPrice.PriceCondition === "YL60" || customerPrice.PriceCondition === "YDC0") {
                body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG.E1KONH.E1KONP.KRECH = "A";

            }

            // set partner and sales organisation
            body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG.VKORG = "QFHC";
            body["_-BAY0_-GZ_SDCOND_A04"].IDOC.EDI_DC40.SNDPRN = "FAST_ES";

        }
        
        // KBETR per Pack or Unit
        //if(customerPrice.CountryCode === 'IT'){
            if ((offer.Division === "Pharma" || offer.Division === "Consumer Health") && priceAgreement.UoM === "Unit" ){// convert and send per pack
                kbetr  = kbetr * packFactor;
            }else if (offer.Division === "Radiology" && priceAgreement.UoM === "Pack" ) { // => radiology so per unit
                kbetr  = kbetr / packFactor;
            }
        //}
        //EHQUT-INC17748342-Rates incorrectly synchronized.
        //EHQUT-INC18178128-FAST - Error decimals discounts
        //we should add "-" only in case of Price Condition "YL60" and "YDC0"
        if (customerPrice.PriceCondition === "YL60" || customerPrice.PriceCondition === "YDC0"){
            kbetr = kbetr.toFixed(3) + "-";
        }
        
        body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG.KUNNR = parseInt(institute.CustomerID);
        body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG.MATNR = parseInt(customerPrice.MaterialNumber);
        body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG.E1KONH.DATAB = parseInt(`${effectiveDate.getFullYear()}${("0" + (effectiveDate.getMonth()+1)).slice(-2)}${("0" + effectiveDate.getDate()).slice(-2)}`);
        body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG.E1KONH.DATBI = parseInt(`${expiryDate.getFullYear()}${("0" + (expiryDate.getMonth()+1)).slice(-2)}${("0" + expiryDate.getDate()).slice(-2)}`);
        body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG.E1KONH.E1KONP.KBETR = kbetr;
        body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG.E1KONH.E1KONP.KSCHL = customerPrice.PriceCondition;
        body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG.KSCHL = customerPrice.PriceCondition;

        tender && (body["_-BAY0_-GZ_SDCOND_A04"].IDOC.E1KOMG["_-BAY0_-GZ_SDREFINFO01"].REFVAL = tender.SAPID);

        //Transforming the Date in correct format
        const datab = new Date(customerPrice.EffectiveDate).toISOString().split('T')[0];
        const datbi = new Date(customerPrice.ExpiryDate).toISOString().split('T')[0];

        customerPricesQC.push({CustomerPriceId: customerPrice.PriceAgreementId, CountryCode: customerPrice.CountryCode, KSCHL: customerPrice.PriceCondition, KUNNR: institute.CustomerID, MATNR: customerPrice.MaterialNumber,KBETR: kbetr, REFVAL: tender.SAPID, DATAB: datab, DATBI: datbi});
        const mappedcustomerPricesQC = this.mappedcustomerPrices(customerPricesQC);

        // 5. Insert PriceCondition QC
        mappedcustomerPricesQC && await this.insertCustomerPriceQC(mappedcustomerPricesQC);

        return await this.updatePriceConditions(customerPrice.CountryCode, "PriceCondition", body);

    }
    //EHQUT-219174-Spain issue with the synchronization of price agreements only on regions
    
    async getPriceAgreementRequestBodyTemplate(institute){
        return {
            "_-BAY0_-GZ_SDCOND_A04": {
              "IDOC": {
                "BEGIN": 1,
                "EDI_DC40": {
                  "SEGMENT": 1,
                  "TABNAM": "EDI_DC40",
                  "MANDT": 508,
                  "DOCNUM": 34952510,
                  "DOCREL": 740,
                  "STATUS": 53,
                  "DIRECT": 2,
                  "OUTMOD": "",
                  "IDOCTYP": "COND_A04",
                  "CIMTYP": "/BAY0/GZ_SDCOND_A04",
                  "MESTYP": "COND_A",
                  "MESCOD": "EXT",
                  "MESFCT": "ES",
                  "SNDPOR": "",  //this is different for DEV (D2RM508) /QA (Q2RM508)/PROD (P2RM508) | the value is added per environment in the CPI configuration
                  "SNDPRT": "LS",
                  "SNDPRN": "FAST_IT",
                  "RCVPOR": "",  //this is different for DEV (SAPD2R) /QA (SAPQ2R)/PROD (SAPP2R) | the value is added per environment in the CPI configuration
                  "RCVPRT": "LS",
                  "RCVPRN": "",  //this is different for DEV (D2RM508) /QA (Q2RM508)/PROD (P2RM508) | | the value is added per environment in the CPI configuration
                  "CREDAT": 20210916,
                  "CRETIM": 144213,
                  "SERIAL": 20210810101046
                },
                "E1KOMG": {
                  "SEGMENT": 1,
                  "KVEWE": "A",
                  "KOTABNR": institute.InstituteType === 'Region(s)' ? 879 : 878,
                  "KAPPL": "V",
                  "KSCHL": "YLTP",
                  "VKORG": "ITHC",
                  "VTWEG": 0,
                  "SPART": 0,
                  "KUNNR": 0,
                  "MATNR": 0,
                  "_-BAY0_-GZ_SDREFINFO01": {
                    "SEGMENT": 1,
                    "EDIQUAL": "CIG",
                    "REFVAL": "Z18178A124"
                  },
                  "E1KONH": {
                    "SEGMENT": 1,
                    "DATAB": 99991231,
                    "DATBI": 99991231,
                    "E1KONP": {
                      "SEGMENT": 1,
                      "KSCHL": "YLTP",
                      "KBETR": 0
                    }
                  }
                }
              }
            }
          };
    };

    mappedcustomerPrices(customerPrices) {

        console.log(`Mapping customerPrices to customerPricesQC ...`);
        customerPrices = customerPrices.reduce((prev, curr, idx, customerPrices) => {
            prev.push(
                {
                    CustomerPriceId             : curr.CustomerPriceId || null,
                    CountryCode                 : curr.CountryCode || null,
                    VKORG                       : curr.CountryCode == 'ES' ? "QFHC" : "ITHC" || null,   // Sales Organisation
                    KSCHL                       : curr.KSCHL || null,   // Condition Type
                    KUNNR                       : curr.KUNNR && this.addLeadingZeros(curr.KUNNR, 10) || null,   // Customer Number
                    MATNR                       : curr.MATNR && this.addLeadingZeros(curr.MATNR, 18) || null,   // Material Number
                    YCIG                        : curr.REFVAL || null,   // Contract Reference
                    KBETR                       : curr.KBETR || null,   // Condition Value
                    KPEIN                       : curr.CountryCode == 'IT' ? 1 : (curr.KSCHL == 'YLTF' || curr.KSCHL == 'YLTP') ? 10000 : null || null,   // Unit for price
                    DATAB                       : curr.DATAB || null,   // Effective Date
                    DATBI                       : curr.DATBI || null,   // Expiry Date
                    KRECH                       : (curr.KSCHL == 'YL60' || curr.KSCHL == 'YDC0') ? "A" : (curr.KSCHL == 'YLTF' || curr.KSCHL == 'YLTP') ? "C" : null || null,   // 
                    KONMS                       : null,   // 
                    MEINS                       : null,   // 
                    BOMAT                       : null,   // 
                    KSTBM                       : null,   // 
                    MIKBAS                      : null,   // 
                    MXBAS                       : null   //
                }
            );
            return prev;
        }, []);
        return customerPrices;

    };

    async insertCustomerPriceQC(customerPrices) {
        console.log(`JOB (${this.jobName }): Inserting of CustomerPrices into FAST table (CustomerPricesQC) ...`);
        const { CustomerPricesQC } = this.db.entities("com.bayer.SXTENDER.PriceAgreementData");
        const tx = cds.tx();
        if(!customerPrices) return false;
        try{
            await tx.run(INSERT(customerPrices).into(CustomerPricesQC));
            await tx.commit();
            console.log(`JOB (${this.jobName }): Inserting of CustomerPrices into FAST table (CustomerPricesQC) successfully completed.`);
            console.log(`JOB (${this.jobName }): CustomerPricesQC -> created: ${customerPrices.length}`);
            return true;
        }
        catch(error){
            await tx.rollback(error);
            console.error(`JOB (${this.jobName }): ERROR - Inserting of CustomerPrices into FAST table (CustomerPricesQC) failed`);
            console.error(error);
            throw error;
        }         
    };

    async updatePriceConditions(countryCode, resource, body){

        const { SchedulerApiConfig } = this.db.entities("com.bayer.SXTENDER.AdminData");

        if (!body) {
            throw Error("The body of the request is missing.");
        }
        
        const apiConfig = await cds.run(SELECT.one.from(SchedulerApiConfig).where({Provider:'PriceAgreement', CountryCode: countryCode, Resource: resource}));

        const url = `${apiConfig.Host}${apiConfig.BasePath}${apiConfig.ResourcePath}`;
        const oauthCredentials = await this.getBearerToken();

        console.log(`Synchronizing Price Conditions ...`);
        console.log(`Calling endpoint ${url}`);


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
        const priceAgreementApi = await cds.run(SELECT.one.from(SchedulerApiConfig).where({Provider:'PriceAgreement'}));
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

    async updatePriceAgreementExpiration(){
        const tx = cds.tx();
        try {

            const { PriceAgreements, CustomerPrices } = this.db.entities("com.bayer.SXTENDER.PriceAgreementData");

            //get all price agreements which have to be extended
            //first, calculate todays date - 1 day, as such that we can use this as a filter in our select


            const whereExpr = `ExtendPriceAgreement = true` //and expiry date is today - 1 
            const priceAgreements = await tx.run(SELECT.from(PriceAgreements).where(whereExpr));

            let aPriceAgreementsUpdated = [];
            const promises = [];
            
            priceAgreements.forEach(agreement => {
                let todayMinus1 = new Date();
                todayMinus1 = new Date(todayMinus1.setDate(todayMinus1.getDate()-1));
                if(!agreement.ExpiryDate || agreement.ExpiryDate.indexOf("T") === -1){
                    console.log(`AgreementID ${agreement.ID}:Expiry date ${agreement.ExpiryDate} is not valid, will not be processed...`);
                    return;
                }
                todayMinus1 = todayMinus1.toISOString().substr(0, agreement.ExpiryDate.lastIndexOf("T"));
                let agreementExpiryDate = agreement.ExpiryDate.substr(0, agreement.ExpiryDate.lastIndexOf("T"));

                if(agreementExpiryDate === todayMinus1){
                    let newDate = new Date(agreement.ExpiryDate);
                    newDate.setMonth(newDate.getMonth()+agreement.ExpiryExtensionPeriod);
                    newDate = newDate.toISOString().replace('T', ' ').replace('Z', '');
                    aPriceAgreementsUpdated.push(agreement.ID);

                    //update the actual price agreement withh the new price agreement date
                    promises.push(Promise.all([
                        tx.run(UPDATE(PriceAgreements).with({ExpiryDate: newDate, ExpiryExtensionAcknowledged: false}).where({ ID: agreement.ID })),
                        tx.run(UPDATE(CustomerPrices).with({ExpiryDate: newDate}).where({ PriceAgreementId: agreement.ID }))
                    ]));
                }
            });

            //execute the promises and log the output
            if(promises.length > 0){
                console.log(`Updating ${PriceAgreements.name} ...`);
                await Promise.all(promises);
                await tx.commit();
                console.log(`${promises.length} Expiry date(s) successfully updated in ${PriceAgreements.name}.`);
            }
            
            return aPriceAgreementsUpdated;

        } catch (error) {
            console.log('Updating expiry dates has failed.');
            console.log(error);
            await tx.rollback(error);
        }   
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