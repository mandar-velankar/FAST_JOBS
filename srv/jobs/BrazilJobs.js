const cds = require('@sap/cds');
const { T } = require('ramda');
// const BaseCron = require('cron-es6');
const BaseJob = require('./BaseJob');

module.exports.ProcessMaterialsBrazil = class ProcessMaterialsBrazil extends BaseJob {

    constructor(jobName,jobTime) {
        super(jobName,jobTime);
    }

    /**
     * Triggered when job has started
     */
    //override
    async onTick() {

        console.log('Processing Brazil materials started ...');

        try {
            this.db = await cds.connect.to('db'); 
            await this.processNewMaterials();
            // await updateExistingMaterials(); // TODO: not implemented
        } catch (error) {
            console.log(error);
        }

        // when the job has finished, call the stop()
        // this will trigger onComplete method
        // this.stop();
        console.log('Processing Brazil materials finished.');
    }

    async processNewMaterials(){
        try {
            // 1. Create Hierarchy entries for new products
            await this.createHierarchyEntries();
            // 2. Create new products master data
            await this.createProductsMasterData();
            // 3. Delete BrazilMaterials table
            await this.clearBrazilMaterialsTable();
        } catch (error) {
            console.log('Processing of new materials has failed.');
            console.log(error);
            return this.saveError(error);
        }
    };

    /**
     * Create Hierarchy entries for new products
     * @return {Promise} Promise
     */
    async createHierarchyEntries(){
        const tx = cds.tx();
        try {

            const { BrazilMaterials } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const { PT_TMPRDHIER } = this.db.entities("com.bayer.SXTENDER.MasterData");

            let existingHlevel6Code = await tx.run(SELECT.from(PT_TMPRDHIER, ['HLEVEL6_CODE']));
            existingHlevel6Code = existingHlevel6Code.map(item => item.HLEVEL6_CODE.toString());

            const whereExpr = `MAKTX <> 'Customer Service Holding Material' and
            HLEVEL6_NAME not like 'zz%' and
            HLEVEL1_NAME <> 'Animal Health' and
            HLEVEL1_NAME <> 'Consumer Health'`;

            // 'not in' where expression was not wokring properly
            // because of this we are using this hack
            // TODO: find a better way to handle this
            let {xpr} = cds.parse.expr(`HLEVEL6_CODE not in '${existingHlevel6Code}'`);
            xpr[3].val = existingHlevel6Code;
            
            const newMaterials = await tx.run(SELECT.distinct.from(BrazilMaterials, ["HLEVEL1_NAME","HLEVEL4_NAME","HLEVEL4_CODE","HLEVEL6_NAME","HLEVEL6_CODE"]).where(whereExpr).where(xpr));
            
            if( newMaterials.length <= 0 ) return {message: `No hierarchy entries were created. No new materials were found in ${BrazilMaterials.name}`};

            const hierarchyEntries = newMaterials.map(mat => {
                let hlevel1_code = mat.HLEVEL1_NAME && mat.HLEVEL1_NAME.toLowerCase() === "Pharma".toLowerCase() ? 8 : mat.HLEVEL1_NAME.toLowerCase() === "Radiology".toLowerCase() ? 65 : 0; 
                return {
                    HLEVEL1_NAME: mat.HLEVEL1_NAME,
                    HLEVEL1_CODE: hlevel1_code, 
                    HLEVEL2_NAME: "",
                    HLEVEL2_CODE: "",
                    HLEVEL3_NAME: "",
                    HLEVEL3_CODE: "",
                    HLEVEL4_NAME: mat.HLEVEL4_NAME,
                    HLEVEL4_CODE: mat.HLEVEL4_CODE,
                    HLEVEL5_NAME: "",
                    HLEVEL5_CODE: "",
                    HLEVEL6_NAME: mat.HLEVEL6_NAME,
                    HLEVEL6_CODE: mat.HLEVEL6_CODE,
                }
            });

            if(hierarchyEntries && hierarchyEntries.length > 0){
                const result = await tx.run(INSERT(hierarchyEntries).into(PT_TMPRDHIER));
                await tx.commit(result);
                console.log(`${hierarchyEntries.length} hierarchy entries successfully created in ${PT_TMPRDHIER.name}.`);
                return result;
            }

            return;

        }catch (error) {
            console.error('Creating hierarchy entries has failed.');
            console.error(error);
            await tx.rollback(error);
        }

    };

    /**
     * Create new products master data
     * @param {Object} material Material 
     * @return {Promise} Promise
     */
    async createProductsMasterData(){
        try {
            const lastProductPackID = await this.getLastProductPackID();
            // 2.a Create new product packs
            await this.createProductPacks(lastProductPackID);
            // 2.b Create new Country Product Packs
            await this.createCountryProductPacks(lastProductPackID);
            // 2.c Create new SKUs
            await this.createSKUs();
            // 2.d Create new COGS
            await this.createCOGS();
        } catch (error) {
            console.log('Creating products master data has failed.');
            console.log(error);
        }
    };

     /**
     * Create new product packs
     * @return {Promise} Promise
     */
      async createProductPacks(lastProductPackID){

        const tx = cds.tx();
        try {

            const { BrazilMaterials } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const { PT_TMPRDPCK, PT_TMCTPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");

            let query = cds.parse.cql (`SELECT p.ProductPackName from ${PT_TMPRDPCK.name} AS p 
            inner join ${PT_TMCTPRDPCK.name} AS cp on p.PRODUCTPACKID = cp.PRODUCTPACKID WHERE cp.CountryCode='IT'`);
            let ProductPackNames =  await tx.run(query);
            ProductPackNames = ProductPackNames.map(item => item.ProductPackName);

            const whereExpr = `MAKTX <> 'Customer Service Holding Material' and
            HLEVEL6_NAME not like 'zz%' and
            HLEVEL1_NAME <> 'Animal Health' and
            HLEVEL1_NAME <> 'Consumer Health'`;

            // 'not in' where expression was not wokring properly
            // because of this we are using this hack
            // TODO: find a better way to handle this
            let {xpr} = cds.parse.expr(`MAKTX not in '${ProductPackNames}'`);
            xpr[3].val = ProductPackNames;
            
            const materials = await tx.run(SELECT.from(BrazilMaterials, ['MAKTX','HLEVEL6_CODE']).where(whereExpr).where(xpr).groupBy(`MAKTX, HLEVEL6_CODE`));

            const productPackEntries = materials.map(mat => {
                return {
                    PRODUCTPACKID: ++lastProductPackID,
                    PRODUCTPACKNAME: mat.MAKTX,
                    PRESENTATION: "",
                    UOM: "",
                    ACTIVERECORD: "Yes",
                    HLEVEL6_CODE: mat.HLEVEL6_CODE,
                    CONCENTRATION: 1,
                    PACKFACTOR: 1,
                    PCINAME: "",
                    MOLECULENAME: "",
                    ACTIVE_SUBSTANCE: "",
                    PRODUCTTYPE: "Drug"
                }
            });

            if(productPackEntries && productPackEntries.length > 0){
                const result = await tx.run(INSERT(productPackEntries).into(PT_TMPRDPCK));
                await tx.commit(result);
                console.log(`${productPackEntries.length} product packs successfully created in ${PT_TMPRDPCK.name}.`);
                return result;
            }
            await tx.commit()
            return;
            
        } catch (error) {
            console.error('Creating product packs has failed.');
            console.error(error);
            await tx.rollback(error);
        }
    };

    /**
     * Create new country product packs
     * @return {Promise} Promise
     */
     async createCountryProductPacks(lastProductPackID){

        const tx = cds.tx();
        try {

            const { BrazilMaterials } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const { PT_TMCTPRDPCK, PT_TMPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");

            let ProductPackIDs =  await tx.run(cds.parse.cql (`SELECT ProductPackID from ${PT_TMCTPRDPCK.name} WHERE CountryCode='IT'`));
            ProductPackIDs = ProductPackIDs.map(item => item.ProductPackID.toString());


            let query = cds.parse.cql (`SELECT max(material.COUNTRYOFORIG), product.ProductPackID FROM ${BrazilMaterials.name} AS material 
            inner join ${PT_TMPRDPCK.name} AS product ON material.MAKTX = product.ProductPackName`);

            // 'not in' where expression was not wokring properly
            // because of this we are using this hack
            // TODO: find a better way to handle this
            let {xpr} = cds.parse.expr(`product.ProductPackID not in '${ProductPackIDs}' AND product.ProductPackID > ${lastProductPackID}`);
            xpr[3].val = ProductPackIDs;
            query.SELECT.where = xpr;
            query.SELECT.groupBy = [
                {
                    "ref": ['product','ProductPackID']
                }
            ];

            const materials = await tx.run(query);
            let nextCountryProductPackID = await this.getLastCountryProductPackID();

            const countryProductPackEntries = materials.map(mat => {
                return {
                    COUNTRYPRODUCTPACKID: ++nextCountryProductPackID,
                    COUNTRYCODE: "IT",
                    COUNTRYOFORIGIN: mat.COUNTRYOFORIGIN,
                    SHELFLIFE: 1,
                    REGISTERED: 2,
                    ACTIVERECORD: "Yes",
                    PRODUCTPACKID: mat.ProductPackID,
                    MANUFACTURER:"NEW",
                    Presentation_2: "",
                    VTATax: 10,
                    COMMENT: "",
                    GOV_CODE: "",
                    CODE1: "",
                    CODE2: "",
                    CODE3:"",                    
                    QTY_THRESHOLD: 0,
                }
            });

            if(countryProductPackEntries && countryProductPackEntries.length > 0){
                const result = await tx.run(INSERT(countryProductPackEntries).into(PT_TMCTPRDPCK));
                await tx.commit(result);
                console.log(`${countryProductPackEntries.length} country product packs successfully created in ${PT_TMCTPRDPCK.name}.`);
                return result;
            }
            await tx.commit();
            return;

        } catch (error) {
            console.error('Creating country product packs has failed.');
            console.error(error);
            await tx.rollback(error);
        }  
    };

    /**
     * Create new SKUs
     * @return {Promise} Promise
     */
    async createSKUs(){

        const tx = cds.tx();
        try {

            const { BrazilMaterials } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const { PT_TMSKUPRDPCK, PT_TMPRDPCK, PT_TMCTPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");

            let skuCodes =  await tx.run(cds.parse.cql (`SELECT DISTINCT SKUCode from ${PT_TMSKUPRDPCK.name}`));
            skuCodes = skuCodes.map(item => this.addLeadingZeros(item.SKUCode, 18));

            let query = cds.parse.cql (`SELECT product.ProductPackID, MATNR FROM ${BrazilMaterials.name} AS material 
            inner join ${PT_TMPRDPCK.name} AS product ON material.MAKTX = product.ProductPackName
            inner join ${PT_TMCTPRDPCK.name} AS countryProduct ON product.ProductPackID = countryProduct.ProductPackID`);

            // 'not in' where expression was not wokring properly
            // because of this we are using this hack
            // TODO: find a better way to handle this
            let {xpr} = cds.parse.expr(`material.MATNR not in '${skuCodes}' AND countryProduct.CountryCode = 'IT'`);
            xpr[3].val = skuCodes;
            query.SELECT.where = xpr;
            query.SELECT.groupBy = [
                {
                    "ref": ['product','ProductPackID']
                },
                {
                    "ref": ['material','MATNR']
                }
            ];

            const materials = await tx.run(query);
            let nextSkuProductPackID = await this.getLastSkuProductPackID();

            const skuProductPackEntries = materials.map(mat => {
                return {
                    CountrySKUID: ++nextSkuProductPackID,
                    CountryCode: "IT",
                    ActiveRecord: "Yes",
                    ProductPackID: mat.ProductPackID,
                    SKUCode: Number(mat.MATNR),
                }
            });

            if(skuProductPackEntries && skuProductPackEntries.length > 0){
                const result = await tx.run(INSERT(skuProductPackEntries).into(PT_TMSKUPRDPCK));
                await tx.commit(result);
                console.log(`${skuProductPackEntries.length} SKUs successfully created in ${PT_TMSKUPRDPCK.name}.`);
                return result;
            }
            await tx.commit();
            return;

        } catch (error) {
            console.error('Creating SKUs has failed.');
            console.error(error);
            await tx.rollback(error);
        }   
    };

    /**
     * Create new COGS
     * @return {Promise} Promise
     */
     async createCOGS(){

        const tx = cds.tx();
        try {

            const { BrazilMaterials } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const { PT_TMPRDPCK, PT_TMCTPRDPCK, PT_TMCOGS } = this.db.entities("com.bayer.SXTENDER.MasterData");

            let query = cds.parse.cql (`SELECT product.ProductPackID, MAX(COGS) FROM ${BrazilMaterials.name} AS material 
            inner join ${PT_TMPRDPCK.name} AS product ON material.MAKTX = product.ProductPackName
            inner join ${PT_TMCTPRDPCK.name} AS countryProduct ON product.ProductPackID = countryProduct.ProductPackID
            where countryProduct.CountryCode='IT'`);

            // TODO: find a better way to handle this
            query.SELECT.groupBy = [
                {
                    "ref": ['product','ProductPackID']
                }
            ];

            const materials = await tx.run(query);
            let nextCogsID = await this.getLastCogsID();

            const cogsEntries = materials.map(mat => {
                return {
                    COGSID: ++nextCogsID,
                    CountryCode: "IT",
                    ProductPackID: mat.ProductPackID,
                    EffectiveDate: new Date().toISOString().slice(0, 10),
                    EndDate: "9999-12-31",
                    Currency: "EUR",
                    COGSType: "Budget",
                    COGS: mat.COGS,
                    ActiveRecord: "Yes",
                }
            });

            if(cogsEntries && cogsEntries.length > 0){
                const result = await tx.run(INSERT(cogsEntries).into(PT_TMCOGS));
                await tx.commit(result);
                console.log(`${cogsEntries.length} COGS successfully created in ${PT_TMCOGS.name}.`);
                return result;
            }
            await tx.commit();
            return;
            
        } catch (error) {
            console.error('Creating COGS has failed.');
            console.error(error);
            await tx.rollback(error);
        }    
    };

    /**
     * Clears the BrazilMaterials table
     * @return {Promise} Promise
     */
     async clearBrazilMaterialsTable(){
        const tx = cds.tx();
        try {
            const { BrazilMaterials } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");

            console.log(`Clearing ${BrazilMaterials.name} table ...`);

            const result = await tx.run(DELETE.from(BrazilMaterials));
            await tx.commit(result);

            console.log(`${BrazilMaterials.name} table successfully cleared. ${result} records deleted.`);
            return result;
            
        } catch (error) {
            console.error('Clearing the Brazil Materials table failed');
            console.error(error);
            await tx.rollback(error);
        }    
    };

    /**
     * Get the last product pack id from PT_TMPRDPCK entity
     * @returns {Promise} lastProductPackID 
     */
    async getLastProductPackID(){
        try {
            const { PT_TMPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");
            const lastProductPackID = await cds.run(SELECT.one.from(PT_TMPRDPCK, ['Max(PRODUCTPACKID) as max']));
            return lastProductPackID.max;
        } catch (error) {
            console.error(error);
        }
    };

    async getLastCountryProductPackID(){
        try {
            const { PT_TMCTPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");
            const lastCountryProductPackID = await cds.run(SELECT.one.from(PT_TMCTPRDPCK, ['Max(PRODUCTPACKID) as max']));
            return lastCountryProductPackID.max;
        } catch (error) {
            console.error(error);
        }
    };

    async getLastSkuProductPackID(){
        try {
            const { PT_TMSKUPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");
            const lastSkuProductPackID = await cds.run(SELECT.one.from(PT_TMSKUPRDPCK, ['Max(COUNTRYSKUID) as max']));
            return lastSkuProductPackID.max;
        } catch (error) {
            console.error(error);
        }
    };

    async getLastCogsID(){
        try {
            const { PT_TMCOGS } = this.db.entities("com.bayer.SXTENDER.MasterData");
            const lastCogsID = await cds.run(SELECT.one.from(PT_TMCOGS, ['Max(COGSID) as max']));
            return lastCogsID.max;
        } catch (error) {
            console.error(error);
        }
    };


    /**
     * Adds leading zero's to a number
     * @param {Integer} num Number
     * @param {Integer} size Length of the number
     * @returns 
     */
    addLeadingZeros (num, size) {
        num = num.toString();
        while (num.length < size) num = "0" + num;
        return num;
    };

    async updateExistingMaterials(materials){
        // TODO: not implemented
    };

    /**
     * Saves the error in the DB.
     * @param {Object} error 
     * @returns {Promise}
     */
     async saveError(error){

        if(!error && !jobDescription) throw new Error(`You must provide a job description and an error object`);

        const tx = cds.tx();
        try{

            const errorEntity = {
              JobName: "BrazilJobs",
              JobDescription: "ProcessMaterialsBrazil",
              ErrorMessage: error.message,
              ResourceURL: "",
              ConsultationDate: new Date().toJSON()
            };

            const result = await tx.run(INSERT.into('com.bayer.SXTENDER.AdminData.SchedulerErrorLog', errorEntity));
            await tx.commit(result);

            return result;

          }catch(err){
            console.error(err);
            await tx.rollback(err);
          }
  
      }

};


module.exports.ProcessCustomersBrazil = class ProcessCustomersBrazil extends BaseJob {

    constructor(jobName,jobTime) {
        super(jobName,jobTime);
    }

    /**
     * Triggered when job has started
     */
    //override
    async onTick() {

        console.log('Processing Brazil customers started ...');

        try {
            this.db = await cds.connect.to('db'); 
            await this.processCustomersBrazil();
        } catch (error) {
            console.log(error);
        }

        // when the job has finished, call the stop()
        // this will trigger onComplete method
        // this.stop();
        console.log('Processing Brazil customers finished.');
    }

    async processCustomersBrazil(){
        try {

            // 1. Create new Institute entries for new Customers
            await this.createInstituteEntries();
            // 2. Update Institute master data for existing Customers
            await this.updateInstituteEntries();

            // TODO: remove this code after the merge of Mater Data app
            // Until we have merged Master Data App branch
            // we must further ensure that master data constraints are 
            // correctly set so as to show all brands for each new institute.
            await this.createInstituteBrands();

            // 3. Delete BrazilCustomers table
            await this.clearBrazilCustomersTable();

        } catch (error) {
            console.log('Processing of Brazil customers has failed.');
            console.log(error);
            return this.saveError(error);
        }
    };

    /**
     * Create new Institute entries for new Customers
     * @return {Promise} Promise
     */
     async  createInstituteEntries(){

        const tx = cds.tx();
        try {


            const { BrazilCustomers } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const { CountryProvinces, PT_TMINST } = this.db.entities("com.bayer.SXTENDER.MasterData");

            let customerNumbers =  await tx.run(cds.parse.cql (`SELECT CustomerID from ${PT_TMINST.name} WHERE CountryCode = 'IT'`));
            customerNumbers = customerNumbers.map(item => this.addLeadingZeros(item.CustomerID, 10));

            let query = cds.parse.cql (`SELECT * FROM ${BrazilCustomers.name} AS customer 
            inner join ${CountryProvinces.name} AS province ON customer.E1KNA1M_REGIO = province.Name`);

            // 'not in' where expression was not wokring properly
            // because of this we are using this hack
            // TODO: find a better way to handle this
            let {xpr} = cds.parse.expr(`customer.E1KNA1M_KUNNR not in '${customerNumbers}' AND customer.E1KNA1M_LAND1 = 'IT'`);
            xpr[3].val = customerNumbers;
            query.SELECT.where = xpr;

            const customers = await tx.run(query);
            let nextInstituteID = await this.getLastInstituteID();

            const instituteEntries = customers.map(cust => {
                return {
                    CountryCode: cust.E1KNA1M_LAND1,
                    InstituteID: ++nextInstituteID,
                    CustomerID: cust.E1KNA1M_KUNNR,
                    InstituteName: cust.E1KNA1M_NAME1,
                    InstituteType: this.getInstituteType(cust.E1KNVVM_KVGR3),
                    Address: `${cust.E1KNA1M_STRAS}, ${cust.E1KNA1M_PSTLZ} ${cust.E1KNA1M_ORT01} \ VAT: ${cust.E1KNA1M_STCEG} \ Fiscal Code: ${cust.E1KNA1M_STCD1}`,
                    ContactNo: cust.E1KNA1M_TELF1,
                    Fax: cust.E1KNA1M_TELFX,
                    ContactPerson: cust.E1KNA1M_STKZN,
                    ActiveRecord: "Yes",
                    Comment: cust.E1KNVVM_KVGR3, // temp to keep track of code
                    City: cust.E1KNA1M_ORT01,
                    INSTITUTE_HIERARCHY_ID: 1,
                    State: "",
                    MercadoPublicoIssuer: "",
                    RegionID: cust.RegionID
                    // --"E1KNVVM_INCO1",--INCO1
                    // --"E1KNVVM_INCO2",--INCO2
                    // --"E1KNVVM_ZTERM",--PaymentTerms
                }
            });

            if(instituteEntries && instituteEntries.length > 0){
                const result = await tx.run(INSERT(instituteEntries).into(PT_TMINST));
                await tx.commit(result);
                console.log(`${instituteEntries.length} Institutes successfully created in ${PT_TMINST.name}.`);
                return result;
            }
            await tx.commit();
            return;

        } catch (error) {
            console.error('Creating Institutes has failed.');
            console.error(error);
            await tx.rollback(error);
        }   

    };


    /**
     * Update Institute entries for existing Customers
     * @return {Promise} Promise
     */
     async  updateInstituteEntries(){

        const tx = cds.tx();
        try {


            const { BrazilCustomers } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const { CountryProvinces, PT_TMINST } = this.db.entities("com.bayer.SXTENDER.MasterData");

            let query = cds.parse.cql (`SELECT * FROM ${BrazilCustomers.name} AS customer 
            inner join ${CountryProvinces.name} AS province ON customer.E1KNA1M_REGIO = province.Name
            inner join ${PT_TMINST.name} institute on customer.E1KNA1M_KUNNR = institute.CustomerID
            where customer.E1KNA1M_LAND1 = 'IT'`);

            const customers = await tx.run(query);

            const promises = customers.map(cust => {
                const obj = {
                    CountryCode: cust.E1KNA1M_LAND1,
                    CustomerID: cust.E1KNA1M_KUNNR,
                    InstituteName: cust.E1KNA1M_NAME1,
                    InstituteType: this.getInstituteType(cust.E1KNVVM_KVGR3) || "",
                    Address: `${cust.E1KNA1M_STRAS}, ${cust.E1KNA1M_PSTLZ} ${cust.E1KNA1M_ORT01} \ VAT: ${cust.E1KNA1M_STCEG} \ Fiscal Code: ${cust.E1KNA1M_STCD1}`,
                    ContactNo: cust.E1KNA1M_TELF1,
                    Fax: cust.E1KNA1M_TELFX,
                    ContactPerson: cust.E1KNA1M_STKZN,
                    ActiveRecord: "Yes",
                    Comment: cust.E1KNVVM_KVGR3, // temp to keep track of code
                    City: cust.E1KNA1M_ORT01,
                    INSTITUTE_HIERARCHY_ID: 1,
                    // State: "",
                    // MercadoPublicoIssuer: "",
                    RegionID: cust.RegionID
                    // --"E1KNVVM_INCO1",--INCO1
                    // --"E1KNVVM_INCO2",--INCO2
                    // --"E1KNVVM_ZTERM",--PaymentTerms
                }

                const result = tx.run(UPDATE(PT_TMINST).with(obj).where({ InstituteID: cust.InstituteID, CountryCode: cust.CountryCode }));
                // tx.commit(result);

                return result;
            });

            if(promises && promises.length > 0){
                console.log(`Updating ${PT_TMINST.name} ...`);
                const result = await Promise.all(promises);
                await tx.commit();
                console.log(`${promises.length} Institutes successfully updated in ${PT_TMINST.name}.`);
                return result;
            }
            await tx.commit();
            return;

        } catch (error) {
            console.log('Updating Institutes has failed.');
            console.log(error);
            await tx.rollback(error);
        }   

    };


    /**
     * 
     * @param {String} id Customer group 3
     * @returns {String} InstituteType 
     */
    getInstituteType(id){
        const KVGR3 = {
            "I61": "Private Account",
            "I69": "Private Account",
            "I64": "Private Account",
            "I66": "Private Account",
            "I62": "Private Account",
            "OEM": "OEM",
            "I53": "Private Account",
            "I43": "Private Account",
            "I50": "Private Account",
            "I55": "Private Account",
            "I58": "Private Account",
            "BVL": "Private Account",
            "I44": "Private Account",
            "I54": "Private Account",
            "L31": "Private Account",
            "I45": "Private Account",
            "I67": "Private Account",
            "I57": "Public Account",
            "I49": "Private Account",
            "L40": "Private Account",
            "I68": "Private Account",
            "I42": "Public Account",
            "I63": "Public Account",
            "I56": "Public Account",
            "I65": "Public Account",
            "I46": "Private Account",
            "I47": "Private Account",
            "I51": "Private Account",
            "BVK": "Private Account",
            "I59": "Private Account",
            "I40": "Private Account",
            "I41": "Private Account",
            "I52": "Private Account",
            "I60": "Private Account",
            "AUI": "Private Account",
            "I48": "Private Account"
        }
        return KVGR3[id];
    };


    /**
     * Until we have merged Master Data App branch (that handles the "Few/All" for direct brands), we must 
     * further ensure that master data constraints are correctly set so as to show all brands for each new institute.
     * @returns {Promise}  
     */
    async createInstituteBrands(){
        try {
            await this.createInstituteBrandTerms();
            await this.createInstituteDistributorBrands();

        } catch (error) {
            console.log(error);
        }
    };


    /**
     * Create Institute Brand Terms
     * @return {Promise} Promise
     */
     async createInstituteBrandTerms(){

        const tx = cds.tx();
        try {

            const { PT_TMINST, PT_TMINSBRTR, PT_TMCTPRDPCK, PT_TMPRDPCK, PT_TMPRDHIER } = this.db.entities("com.bayer.SXTENDER.MasterData");

            let instituteBrandTermsCompoundKeys =  await tx.run(cds.parse.cql (`SELECT CountryCode || InstituteID || HLEVEL4_CODE || ActiveRecord AS CompoundKey FROM ${PT_TMINSBRTR.name} WHERE CountryCode = 'IT'`));
            instituteBrandTermsCompoundKeys = instituteBrandTermsCompoundKeys.map(item => item.CompoundKey);

            let query = cds.parse.cql (`SELECT i.CountryCode, i.InstituteId, h.HLevel4_Code FROM ${PT_TMINST.name} AS i 
            INNER JOIN ${PT_TMCTPRDPCK.name} AS cp ON i.CountryCode = cp.CountryCode
            INNER JOIN ${PT_TMPRDPCK.name} AS p ON cp.ProductPackId = p.ProductPackId
            INNER JOIN ${PT_TMPRDHIER.name} AS h ON p.HLevel6_Code = h.HLevel6_Code
            GROUP BY i.CountryCode,i.InstituteId,h.HLevel4_Code
            ORDER BY i.InstituteId,h.HLevel4_Code`);

             // 'not in' where expression was not wokring properly
            // because of this we are using this hack
            // TODO: find a better way to handle this
            let {xpr} = cds.parse.expr(`i.CountryCode = 'IT' and (i.CountryCode || i.InstituteID || h.HLEVEL4_CODE || 'Yes') not in '${instituteBrandTermsCompoundKeys}'`);
            xpr[15].val = instituteBrandTermsCompoundKeys;
            query.SELECT.where = xpr;

            const brandTerms = await tx.run(query);

            if(brandTerms.length <= 0) return;

            let lastInstituteBrandTermsID = await tx.run(SELECT.one.from(PT_TMINSBRTR, ['Max(INSTITUTEBRANDTERMSID) as max']));
            lastInstituteBrandTermsID = lastInstituteBrandTermsID.max;

            const instituteBrandEntries = brandTerms.map(brandTerm => {
                return {
                    InstituteBrandTermsID: ++lastInstituteBrandTermsID,
                    CountryCode: brandTerm.CountryCode,
                    INCOTerms: "",
                    PaymentTerms: "",
                    ActiveRecord: "Yes",
                    InstituteID: brandTerm.InstituteId,
                    HLevel4_Code: brandTerm.HLevel4_Code
                }
            });

            const result = await tx.run(INSERT(instituteBrandEntries).into(PT_TMINSBRTR));
            await tx.commit(result);
            console.log(`${instituteBrandEntries.length} Institute Brand Terms successfully created in ${PT_TMINSBRTR.name}.`);
            return result;

        } catch (error) {
            console.error('Creating Institute Brand Terms has failed.');
            console.error(error);
            await tx.rollback(error);
        }   

    };

    /**
     * Create Institute Distributor Brands
     * @return {Promise} Promise
     */
     async createInstituteDistributorBrands(){

        const tx = cds.tx();
        try {

            const { PT_TMINST, PT_TMDIST, PT_TMCTPRDPCK, PT_TMPRDPCK, PT_TMPRDHIER, PT_TMINDSBR } = this.db.entities("com.bayer.SXTENDER.MasterData");

            let instituteDistributorBrandCompoundKeys =  await tx.run(cds.parse.cql (`SELECT CountryCode || InstituteID || DistributorId || HLEVEL4_CODE || ActiveRecord AS CompoundKey FROM ${PT_TMINDSBR.name} WHERE CountryCode = 'IT'`));
            instituteDistributorBrandCompoundKeys = instituteDistributorBrandCompoundKeys.map(item => item.CompoundKey);

            let query = cds.parse.cql (`SELECT i.CountryCode, i.InstituteId, d.DistributorId, h.HLevel4_Code FROM ${PT_TMINST.name} AS i 
            INNER JOIN ${PT_TMDIST.name} AS d ON i.CountryCode = d.CountryCode
            INNER JOIN ${PT_TMCTPRDPCK.name} AS cp ON i.CountryCode = cp.CountryCode
            INNER JOIN ${PT_TMPRDPCK.name} AS p ON cp.ProductPackId = p.ProductPackId
            INNER JOIN ${PT_TMPRDHIER.name} AS h ON p.HLevel6_Code = h.HLevel6_Code
            WHERE i.CountryCode = 'IT'
            GROUP BY i.CountryCode,i.InstituteId,h.HLevel4_Code,d.DistributorId
            ORDER BY i.InstituteId,d.DistributorId,h.HLevel4_Code`);

             // 'not in' where expression was not wokring properly
            // because of this we are using this hack
            // TODO: find a better way to handle this
            let {xpr} = cds.parse.expr(`i.CountryCode = 'IT' and (i.CountryCode || i.InstituteID || d.DistributorId || h.HLEVEL4_CODE || 'Yes') not in '${instituteDistributorBrandCompoundKeys}'`);
            xpr[17].val = instituteDistributorBrandCompoundKeys;
            query.SELECT.where = xpr;

            const brands = await tx.run(query);

            if(brands.length <= 0) return;

            let lastInstituteDistBrandRelationID = await tx.run(SELECT.one.from(PT_TMINDSBR, ['Max(INSTITUTEDISTBRANDRELATIONID) as max']));
            lastInstituteDistBrandRelationID = lastInstituteDistBrandRelationID.max;

            const instituteDistributorBrandEntries = brands.map(brand => {
                return {
                    InstituteDistBrandRelationID: ++lastInstituteDistBrandRelationID,
                    CountryCode: brand.CountryCode,
                    Commissionrate: 0,
                    ActiveRecord: "Yes",
                    InstituteID: brand.InstituteId,
                    DistributorID: brand.DistributorId,
                    HLevel4_Code: brand.HLevel4_Code
                }
            });

            const result = await tx.run(INSERT(instituteDistributorBrandEntries).into(PT_TMINDSBR));
            await tx.commit(result);
            console.log(`${instituteDistributorBrandEntries.length} Institute Distributor Brands successfully created in ${PT_TMINDSBR.name}.`);
            return result;

        } catch (error) {
            console.error('Creating Institute Distributor Brands has failed.');
            console.error(error);
            await tx.rollback(error);
        }     

    };

    /**
     * Clears the BrazilCustomers table
     * @return {Promise} Promise
     */
     async clearBrazilCustomersTable(){
        const tx = cds.tx();
        try {

            const { BrazilCustomers } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");

            console.log(`Clearing ${BrzilCustomers.name} table ...`);

            const result = await tx.run(DELETE.from(BrazilCustomers));
            await tx.commit(result);

            console.log(`${BrazilCustomers.name} table successfully cleared. ${result} records deleted.`);
            return result;
            
        } catch (error) {
            console.error('Clearing the Brazil Customers table failed');
            console.error(error);
            await tx.rollback(error);
        }    
    };


    async getLastInstituteID(){
        const tx = cds.tx();
        try {
            const { PT_TMINST } = this.db.entities("com.bayer.SXTENDER.MasterData");
            const lastInstituteID = await tx.run(SELECT.one.from(PT_TMINST, ['Max(INSTITUTEID) as max']));
            await tx.commit();
            return lastInstituteID.max;
        } catch (error) {
            console.error(error);
            await tx.rollback(error);
        }
    };


    /**
     * Adds leading zero's to a number
     * @param {Integer} num Number
     * @param {Integer} size Length of the number
     * @returns 
     */
     addLeadingZeros (num, size) {
        num = num.toString();
        while (num.length < size) num = "0" + num;
        return num;
    };


    /**
     * Saves the error in the DB.
     * @param {Object} error 
     * @returns {Promise}
     */
     async saveError(error){

        if(!error) throw new Error(`You must provide a error object`);

        const tx = cds.tx();
        try{

            const errorEntity = {
              JobName: "BrazilJobs",
              JobDescription: "ProcessMaterials",
              ErrorMessage: error.message,
              ResourceURL: "",
              ConsultationDate: new Date().toJSON()
            };

            const result = await tx.run(INSERT.into('com.bayer.SXTENDER.AdminData.SchedulerErrorLog', errorEntity));
            await tx.commit(result);

            return result;

          }catch(err){
            console.error(err);
            await tx.rollback(error);
          }
  
      }

};

module.exports.NewIBIZTenderNotifications = class NewIBIZTenderNotifications extends BaseJob {

    constructor(jobName,jobTime) {
        super(jobName,jobTime);
    }

    /**
     * Triggered when job has started
     */
    //override
    async onTick() {

        console.log('Processing IBIZ notification mails started ...');
        
        let date = new Date(); //get current datetime
        date.setHours(date.getHours() - 1) //only consider records created in the past hour

        try {
            this.db = await cds.connect.to('db'); 

            // get mail Template - direct tenders
            const templateNameDirect = 'IbizNotificationDirectTenders';
            const mailTemplateDirect = await this.getMailTemplate(templateNameDirect);

            // get mail Template - indirect tenders
            const templateNameIndirect = 'IbizNotificationIndirectTenders';
            const mailTemplateIndirect = await this.getMailTemplate(templateNameIndirect);

            //fetch data from db
            let directTenders = await this.getIbizDirectTenders(date);
            let indirectTenders = await this.getIbizIndirectTenders(date);

            //process direct tenders
            if (directTenders && directTenders.length > 0) {
                let mail = this.mapDataToMail(mailTemplateDirect,templateNameDirect, date)(directTenders);
                if(mail){
                    await this.addMailsToOutbox(mail, date);
                } else{
                    console.log(`No mail to add to outbox for template ${templateNameDirect}`);
                }
             } else {
                 console.log(`No notification mail to be send on ${date.toDateString()}`);
             }

             //process indirect tenders
            if (indirectTenders && indirectTenders.length > 0) {
                let mail = this.mapDataToMail(mailTemplateIndirect,templateNameIndirect, date)(indirectTenders);
                if(mail){
                    await this.addMailsToOutbox(mail, date);
                } else{
                    console.log(`No mail to add to outbox for template ${templateNameIndirect}`);
                }
             } else {
                 console.log(`No notification mail to be send on ${date.toDateString()}`);
             }
        } catch (error) {
            console.log(error);
        }

        // when the job has finished, call the stop()
        // this will trigger onComplete method
        // this.stop();
        console.log('Processing IBIZ notification mails finished.');
    }

    async getIbizDirectTenders(date) {
        console.log(`Fetching IBIZ direct tenders`);

        const { PT_TMINST, PT_TMDIST } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const { PT_TMTEND, PT_TMOFRS } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
        const tx = this.db.tx();
        return await tx.run(
            SELECT.from(`${PT_TMTEND.name} as tender`)
            .join(`${PT_TMOFRS.name} as offer`)
            .on({ 
                'offer.TenderID': { '=': 'tender.TenderID' } 
            })
            .join(`${PT_TMINST.name} as institute`)
            .on({ 
                'institute.InstituteID': { '=': 'tender.InstituteID' } 
            })
            .join(`${PT_TMDIST.name} as distributor`)
            .on({ 
                'distributor.DistributorID': { '=': 'offer.DistributorID' } 
            })
            .where({ 
                    'tender.CountryCode': 'BR', 
                    'tender.createdAt': { '>=': `${date.toJSON().substring(0,10)} ${date.getHours()}:${date.getMinutes()}:00.000000000` }, // only consider records created in the past hour
                    'distributor.DistributorName': 'Bayer Brazil'
            })
        ); 
    }

    /*async getIbizIndirectTenders(date) {
        console.log(`Fetching IBIZ indirect tenders`);
        let date = new Date(); //get current datetime
        date.setHours(date.getHours() - 1) //only consider records created in the past hour

        const { PT_TMINST, PT_TMDIST } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const { PT_TMTEND, PT_TMOFRS } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
        const tx = this.db.tx();
        return await tx.run(
            SELECT.from(`${PT_TMTEND.name} as tender`)
            .join(`${PT_TMOFRS.name} as offer`)
            .on({ 
                'offer.TenderID': { '=': 'tender.TenderID' } 
            })
            .join(`${PT_TMINST.name} as institute`)
            .on({ 
                'institute.InstituteID': { '=': 'tender.InstituteID' } 
            })
            .join(`${PT_TMDIST.name} as distributor`)
            .on({ 
                'distributor.DistributorID': { '=': 'offer.DistributorID' } 
            })
            .where({ 
                    'tender.CountryCode': 'BR', 
                    'tender.createdAt': { '>=': `${date.toJSON().substring(0,10)} ${date.getHours()}:${date.getMinutes()}:00.000000000` }, // only consider records created in the past hour
                    'distributor.DistributorName': { '!=': `Bayer Brazil` }
            })
        ); 
    }

    mapDataToMail = (template,mail,syncDate) => data => {
        const appEnv = cfenv.getAppEnv();
        const fastUIAppHost = appEnv.url.replace('fast-srv','fastui-app');
        
        // add/change some fields in the data array
        data.forEach(d => {
            d.BidDueDate = new Date(d.BidDueDate).toJSON().substring(0,10),
            d.PublicationDate = new Date(d.PublicationDate).toJSON().substring(0,10),
            d.URL = `${fastUIAppHost}/app/index.html#/priceagreements&/pa/PriceAgreements/${d.PriceAgreementId}`
        })
        const outbox = {
            CountryCode: data[0].CountryCode,
            TenderID: data[0].TenderId,
            OfferID: data[0].OfferId,
            Sender: 'FAST-Admin@bayer.com',
            Recipients: undefined,
            Subject: template.title,
            MailBody: this.generateMailBody(template, { 
                data: { 
                    SyncDate: syncDate.toDateString(), 
                    CustomerPrices: data 
                }
            }),
            Sent: false
        }
        if(!outbox.MailBody || outbox.MailBody === 'undefined') {
            console.log(`No template found for Customer Price of tender ${outbox.TenderID} with countrycode ${outbox.CountryCode}`);
            return;
        }
        return outbox;
    }

    async addMailsToOutbox(mail, syncDate) {
        console.log(`Adding notification mail for IBIZ contracts synchronised with SAP on: ${syncDate.toDateString()}`);
        const { OutgoingMails } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
        const tx = this.db.tx();
        try {
            const mailsResult = await tx.run(INSERT(mail).into(OutgoingMails));
            await tx.commit();
            return mailsResult;
        } catch (error) {
            console.error(error);
            await tx.rollback();
            throw error;
        }
    }

    generateMailBody(mail, data) {
        return Handlebars.compile("" + mail.content)(data);
    }

    async getMailTemplate(templateId) {
        console.log(`Get mail templates for IBIZ notification ${templateId}`);
        console.table(templateId);
        const tx = cds.tx();
        const { MailTemplate } = this.db.entities("com.bayer.SXTENDER.AdminData");
        try{
            const result = await tx.run(SELECT.one.from(MailTemplate)
            .columns('*', 'MailTemplateFile.title', 'MailTemplateFile.content')
            .where({ TemplateId: templateId }));
            await tx.commit();
            return result;
        }catch(error){
            console.error("No mail template found");
            await tx.rollback();
            return [];
        }
    }*/
};