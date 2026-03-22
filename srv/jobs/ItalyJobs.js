const cds = require('@sap/cds');
const BaseJob = require('./BaseJob');

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WHERE CLAUSE
// Applied consistently across all material queries
// ─────────────────────────────────────────────────────────────────────────────
const MATERIALS_WHERE_EXPR = `MAKTX <> 'Customer Service Holding Material' and
    HLEVEL6_NAME not like 'zz%' and
    HLEVEL1_NAME <> 'Animal Health' and
    HLEVEL1_NAME <> 'Consumer Health'`;

// ─────────────────────────────────────────────────────────────────────────────
// ProcessMaterials
// ─────────────────────────────────────────────────────────────────────────────
module.exports.ProcessMaterials = class ProcessMaterials extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
    }

    // override
    async onTick() {
        console.log('Processing Italy materials started ...');
        try {
            this.db = await cds.connect.to('db');
            await this.processNewMaterials();
        } catch (error) {
            console.error(error);
        }
        console.log('Processing Italy materials finished.');
    }

    async processNewMaterials() {
        try {
            await this.createHierarchyEntries();
            await this.createProductsMasterData();
            await this.clearItalyMaterialsTable();
        } catch (error) {
            console.error('Processing of new materials has failed.');
            console.error(error);
            return this.saveError(error);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Create Hierarchy Entries
    // ─────────────────────────────────────────────────────────────────────────
    async createHierarchyEntries() {
        const tx = cds.tx();
        try {
            const { ItalyMaterials } = this.db.entities('com.bayer.SXTENDER.MasterData.SAP');
            const { PT_TMPRDHIER } = this.db.entities('com.bayer.SXTENDER.MasterData');

            // Fetch all existing HLEVEL6 codes
            let existingRows = await tx.run(SELECT.from(PT_TMPRDHIER, ['HLEVEL6_CODE']));
            const existingHlevel6Code = existingRows.map(r => r.HLEVEL6_CODE.toString());

            // Build the select query
            let query = SELECT.distinct
                .from(ItalyMaterials, ['HLEVEL1_NAME', 'HLEVEL4_NAME', 'HLEVEL4_CODE', 'HLEVEL6_NAME', 'HLEVEL6_CODE'])
                .where(MATERIALS_WHERE_EXPR);

            // Only add NOT IN clause if there are existing codes (empty array causes SQL error)
            if (existingHlevel6Code.length > 0) {
                query.where('HLEVEL6_CODE NOT IN', existingHlevel6Code);
            }

            const newMaterials = await tx.run(query);

            if (newMaterials.length <= 0) {
                await tx.commit();
                console.log(`No hierarchy entries created — no new materials found in ${ItalyMaterials.name}`);
                return { message: `No hierarchy entries were created. No new materials were found in ${ItalyMaterials.name}` };
            }

            const hierarchyEntries = newMaterials.map(mat => {
                const name = (mat.HLEVEL1_NAME || '').toLowerCase();
                let hlevel1_code = 0;
                if (name === 'pharma') hlevel1_code = 8;
                else if (name === 'radiology') hlevel1_code = 65;

                return {
                    HLEVEL1_NAME: mat.HLEVEL1_NAME,
                    HLEVEL1_CODE: hlevel1_code,
                    HLEVEL2_NAME: '',
                    HLEVEL2_CODE: '',
                    HLEVEL3_NAME: '',
                    HLEVEL3_CODE: '',
                    HLEVEL4_NAME: mat.HLEVEL4_NAME,
                    HLEVEL4_CODE: mat.HLEVEL4_CODE,
                    HLEVEL5_NAME: '',
                    HLEVEL5_CODE: '',
                    HLEVEL6_NAME: mat.HLEVEL6_NAME,
                    HLEVEL6_CODE: mat.HLEVEL6_CODE,
                };
            });

            if (hierarchyEntries && hierarchyEntries.length > 0) {
                const result = await tx.run(INSERT(hierarchyEntries).into(PT_TMPRDHIER));
                await tx.commit();
                console.log(`${hierarchyEntries.length} hierarchy entries successfully created in ${PT_TMPRDHIER.name}.`);
                return result;
            }
            await tx.commit();
            return;

        } catch (error) {
            console.error('Creating hierarchy entries has failed.');
            console.error(error);
            await tx.rollback(error);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Orchestrate product master data creation
    // ─────────────────────────────────────────────────────────────────────────
    async createProductsMasterData() {
        try {
            const lastProductPackID = await this.getLastProductPackID();
            await this.createProductPacks(lastProductPackID);
            await this.createCountryProductPacks(lastProductPackID);
            await this.createSKUs();
            await this.createCOGS();
        } catch (error) {
            console.error('Creating products master data has failed.');
            console.error(error);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2a. Create Product Packs
    // ─────────────────────────────────────────────────────────────────────────
    async createProductPacks(lastProductPackID) {
        const tx = cds.tx();
        try {
            const { ItalyMaterials } = this.db.entities('com.bayer.SXTENDER.MasterData.SAP');
            const { PT_TMPRDPCK, PT_TMCTPRDPCK } = this.db.entities('com.bayer.SXTENDER.MasterData');

            // Get existing product pack names for Italy
            let existingRows = await tx.run(
                cds.parse.cql(`SELECT p.ProductPackName from ${PT_TMPRDPCK.name} AS p
                    inner join ${PT_TMCTPRDPCK.name} AS cp on p.PRODUCTPACKID = cp.PRODUCTPACKID
                    WHERE cp.CountryCode='IT'`)
            );
            const existingProductPackNames = existingRows.map(r => r.ProductPackName);

            // Build query avoiding NOT IN on empty array
            let query = SELECT
                .from(ItalyMaterials, ['MAKTX', 'HLEVEL6_CODE'])
                .where(MATERIALS_WHERE_EXPR)
                .groupBy('MAKTX, HLEVEL6_CODE');

            if (existingProductPackNames.length > 0) {
                query.where('MAKTX NOT IN', existingProductPackNames);
            }

            const materials = await tx.run(query);

            if (!materials || materials.length === 0) {
                await tx.commit();
                console.log('No new product packs to create.');
                return;
            }

            let nextID = lastProductPackID;
            const productPackEntries = materials.map(mat => ({
                PRODUCTPACKID: ++nextID,
                PRODUCTPACKNAME: mat.MAKTX,
                PRESENTATION: '',
                UOM: '',
                ACTIVERECORD: 'Yes',
                HLEVEL6_CODE: mat.HLEVEL6_CODE,
                CONCENTRATION: 1,
                PACKFACTOR: 1,
                PCINAME: '',
                MOLECULENAME: '',
                ACTIVE_SUBSTANCE: '',
                PRODUCTTYPE: 'Drug',
            }));

            if (productPackEntries && productPackEntries.length > 0) {
                const result = await tx.run(INSERT(productPackEntries).into(PT_TMPRDPCK));
                await tx.commit();
                console.log(`${productPackEntries.length} product packs successfully created in ${PT_TMPRDPCK.name}.`);
                return result;
            }
            await tx.commit();
            return;

        } catch (error) {
            console.error('Creating product packs has failed.');
            console.error(error);
            await tx.rollback(error);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2b. Create Country Product Packs
    // ─────────────────────────────────────────────────────────────────────────
    async createCountryProductPacks(lastProductPackID) {
        const tx = cds.tx();
        try {
            const { ItalyMaterials } = this.db.entities('com.bayer.SXTENDER.MasterData.SAP');
            const { PT_TMCTPRDPCK, PT_TMPRDPCK } = this.db.entities('com.bayer.SXTENDER.MasterData');

            // Get existing country product pack IDs for Italy
            let existingRows = await tx.run(
                cds.parse.cql(`SELECT ProductPackID from ${PT_TMCTPRDPCK.name} WHERE CountryCode='IT'`)
            );
            const existingProductPackIDs = existingRows.map(r => r.ProductPackID.toString());

            // Build base join query using CQL
            let query = cds.parse.cql(
                `SELECT max(material.COUNTRYOFORIG) as COUNTRYOFORIGIN, product.ProductPackID
                 FROM ${ItalyMaterials.name} AS material
                 inner join ${PT_TMPRDPCK.name} AS product ON material.MAKTX = product.ProductPackName`
            );

            // Build where conditions manually on the parsed CQL object
            // Filter: new packs only (ProductPackID > lastProductPackID) 
            // AND not already in country product packs
            const whereConditions = [
                { ref: ['product', 'ProductPackID'] },
                '>',
                { val: lastProductPackID },
            ];

            if (existingProductPackIDs.length > 0) {
                whereConditions.push('and');
                whereConditions.push({ ref: ['product', 'ProductPackID'] });
                whereConditions.push('not in');
                whereConditions.push({ list: existingProductPackIDs.map(v => ({ val: v })) });
            }

            query.SELECT.where = whereConditions;
            query.SELECT.groupBy = [{ ref: ['product', 'ProductPackID'] }];

            const materials = await tx.run(query);

            if (!materials || materials.length === 0) {
                await tx.commit();
                console.log('No new country product packs to create.');
                return;
            }

            let nextID = await this.getLastCountryProductPackID();

            const countryProductPackEntries = materials.map(mat => ({
                COUNTRYPRODUCTPACKID: ++nextID,
                COUNTRYCODE: 'IT',
                COUNTRYOFORIGIN: mat.COUNTRYOFORIGIN,
                SHELFLIFE: 1,
                REGISTERED: 2,
                ACTIVERECORD: 'Yes',
                PRODUCTPACKID: mat.ProductPackID,
                MANUFACTURER: 'NEW',
                Presentation_2: '',
                VTATax: 10,
                COMMENT: '',
                GOV_CODE: '',
                CODE1: '',
                CODE2: '',
                CODE3: '',
                QTY_THRESHOLD: 0,
            }));

            if (countryProductPackEntries && countryProductPackEntries.length > 0) {
                const result = await tx.run(INSERT(countryProductPackEntries).into(PT_TMCTPRDPCK));
                await tx.commit();
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
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2c. Create SKUs
    // ─────────────────────────────────────────────────────────────────────────
    async createSKUs() {
        const tx = cds.tx();
        try {
            const { ItalyMaterials } = this.db.entities('com.bayer.SXTENDER.MasterData.SAP');
            const { PT_TMSKUPRDPCK, PT_TMPRDPCK, PT_TMCTPRDPCK } = this.db.entities('com.bayer.SXTENDER.MasterData');

            // Get existing SKU codes (padded to 18 digits)
            let existingRows = await tx.run(
                cds.parse.cql(`SELECT DISTINCT SKUCode from ${PT_TMSKUPRDPCK.name}`)
            );
            const skuCodes = existingRows.map(r => this.addLeadingZeros(r.SKUCode, 18));

            // Build base join query
            let query = cds.parse.cql(
                `SELECT product.ProductPackID, material.MATNR
                 FROM ${ItalyMaterials.name} AS material
                 inner join ${PT_TMPRDPCK.name} AS product ON material.MAKTX = product.ProductPackName
                 inner join ${PT_TMCTPRDPCK.name} AS countryProduct ON product.ProductPackID = countryProduct.ProductPackID`
            );

            // Build where: CountryCode = 'IT' AND MATNR NOT IN existing SKUs
            const whereConditions = [
                { ref: ['countryProduct', 'CountryCode'] },
                '=',
                { val: 'IT' },
            ];

            if (skuCodes.length > 0) {
                whereConditions.push('and');
                whereConditions.push({ ref: ['material', 'MATNR'] });
                whereConditions.push('not in');
                whereConditions.push({ list: skuCodes.map(v => ({ val: v })) });
            }

            query.SELECT.where = whereConditions;
            query.SELECT.groupBy = [
                { ref: ['product', 'ProductPackID'] },
                { ref: ['material', 'MATNR'] },
            ];

            const materials = await tx.run(query);

            if (!materials || materials.length === 0) {
                await tx.commit();
                console.log('No new SKUs to create.');
                return;
            }

            let nextID = await this.getLastSkuProductPackID();

            const skuProductPackEntries = materials.map(mat => ({
                CountrySKUID: ++nextID,
                CountryCode: 'IT',
                ActiveRecord: 'Yes',
                ProductPackID: mat.ProductPackID,
                SKUCode: Number(mat.MATNR),
            }));

            if (skuProductPackEntries && skuProductPackEntries.length > 0) {
                const result = await tx.run(INSERT(skuProductPackEntries).into(PT_TMSKUPRDPCK));
                await tx.commit();
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
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2d. Create COGS
    // ─────────────────────────────────────────────────────────────────────────
    async createCOGS() {
        const tx = cds.tx();
        try {
            const { ItalyMaterials } = this.db.entities('com.bayer.SXTENDER.MasterData.SAP');
            const { PT_TMPRDPCK, PT_TMCTPRDPCK, PT_TMCOGS } = this.db.entities('com.bayer.SXTENDER.MasterData');

            let query = cds.parse.cql(
                `SELECT product.ProductPackID, MAX(COGS) as COGS
                 FROM ${ItalyMaterials.name} AS material
                 inner join ${PT_TMPRDPCK.name} AS product ON material.MAKTX = product.ProductPackName
                 inner join ${PT_TMCTPRDPCK.name} AS countryProduct ON product.ProductPackID = countryProduct.ProductPackID
                 where countryProduct.CountryCode='IT'`
            );

            query.SELECT.groupBy = [{ ref: ['product', 'ProductPackID'] }];

            const materials = await tx.run(query);

            if (!materials || materials.length === 0) {
                await tx.commit();
                console.log('No new COGS to create.');
                return;
            }

            let nextID = await this.getLastCogsID();

            const cogsEntries = materials.map(mat => ({
                COGSID: ++nextID,
                CountryCode: 'IT',
                ProductPackID: mat.ProductPackID,
                EffectiveDate: new Date().toISOString().slice(0, 10),
                EndDate: '9999-12-31',
                Currency: 'EUR',
                COGSType: 'Budget',
                COGS: mat.COGS,
                ActiveRecord: 'Yes',
            }));

            if (cogsEntries && cogsEntries.length > 0) {
                const result = await tx.run(INSERT(cogsEntries).into(PT_TMCOGS));
                await tx.commit();
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
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Clear ItalyMaterials table
    // ─────────────────────────────────────────────────────────────────────────
    async clearItalyMaterialsTable() {
        const tx = cds.tx();
        try {
            const { ItalyMaterials } = this.db.entities('com.bayer.SXTENDER.MasterData.SAP');
            console.log(`Clearing ${ItalyMaterials.name} table ...`);
            const result = await tx.run(DELETE.from(ItalyMaterials));
            await tx.commit();
            console.log(`${ItalyMaterials.name} table successfully cleared. ${result} records deleted.`);
            return result;
        } catch (error) {
            console.error('Clearing the Italy Materials table failed');
            console.error(error);
            await tx.rollback(error);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helper: get last IDs
    // ─────────────────────────────────────────────────────────────────────────
    async getLastProductPackID() {
        try {
            const { PT_TMPRDPCK } = this.db.entities('com.bayer.SXTENDER.MasterData');
            const row = await cds.run(SELECT.one.from(PT_TMPRDPCK, ['Max(PRODUCTPACKID) as max']));
            return row ? (row.max || 0) : 0;
        } catch (error) {
            console.error(error);
            return 0;
        }
    }

    async getLastCountryProductPackID() {
        try {
            const { PT_TMCTPRDPCK } = this.db.entities('com.bayer.SXTENDER.MasterData');
            // BUG FIX: was selecting Max(PRODUCTPACKID) — should be Max(COUNTRYPRODUCTPACKID)
            const row = await cds.run(SELECT.one.from(PT_TMCTPRDPCK, ['Max(COUNTRYPRODUCTPACKID) as max']));
            return row ? (row.max || 0) : 0;
        } catch (error) {
            console.error(error);
            return 0;
        }
    }

    async getLastSkuProductPackID() {
        try {
            const { PT_TMSKUPRDPCK } = this.db.entities('com.bayer.SXTENDER.MasterData');
            // BUG FIX: was selecting Max(COUNTRYSKUID) but column was COUNTRYSKUID — kept consistent
            const row = await cds.run(SELECT.one.from(PT_TMSKUPRDPCK, ['Max(COUNTRYSKUID) as max']));
            return row ? (row.max || 0) : 0;
        } catch (error) {
            console.error(error);
            return 0;
        }
    }

    async getLastCogsID() {
        try {
            const { PT_TMCOGS } = this.db.entities('com.bayer.SXTENDER.MasterData');
            const row = await cds.run(SELECT.one.from(PT_TMCOGS, ['Max(COGSID) as max']));
            return row ? (row.max || 0) : 0;
        } catch (error) {
            console.error(error);
            return 0;
        }
    }

    addLeadingZeros(num, size) {
        let str = num.toString();
        while (str.length < size) str = '0' + str;
        return str;
    }

    async saveError(error) {
        if (!error) throw new Error('You must provide an error object');
        const tx = cds.tx();
        try {
            const errorEntity = {
                JobName: 'ItalyJobs',
                JobDescription: 'ProcessMaterials',
                ErrorMessage: error.message,
                ResourceURL: '',
                ConsultationDate: new Date().toJSON(),
            };
            const result = await tx.run(INSERT.into('com.bayer.SXTENDER.AdminData.SchedulerErrorLog', errorEntity));
            await tx.commit();
            return result;
        } catch (err) {
            console.error(err);
            await tx.rollback(err);
        }
    }
};


// ─────────────────────────────────────────────────────────────────────────────
// ProcessCustomers
// ─────────────────────────────────────────────────────────────────────────────
module.exports.ProcessCustomers = class ProcessCustomers extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
    }

    // override
    async onTick() {
        console.log('Processing Italy customers started ...');
        try {
            this.db = await cds.connect.to('db');
            await this.processCustomers();
        } catch (error) {
            console.error(error);
        }
        console.log('Processing Italy customers finished.');
    }

    async processCustomers() {
        try {
            await this.createInstituteEntries();
            await this.updateInstituteEntries();
            await this.clearItalyCustomersTable();
        } catch (error) {
            console.error('Processing of Italy customers has failed.');
            console.error(error);
            return this.saveError(error);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Create Institute Entries
    // ─────────────────────────────────────────────────────────────────────────
    async createInstituteEntries() {
        const tx = cds.tx();
        try {
            const { ItalyCustomers } = this.db.entities('com.bayer.SXTENDER.MasterData.SAP');
            const { CountryProvinces, PT_TMINST } = this.db.entities('com.bayer.SXTENDER.MasterData');

            // Fetch existing customer IDs for Italy (padded)
            let existingRows = await tx.run(
                cds.parse.cql(`SELECT CustomerID from ${PT_TMINST.name} WHERE CountryCode = 'IT'`)
            );
            const customerNumbers = existingRows.map(r => this.addLeadingZeros(r.CustomerID, 10));

            // BUG FIX: was using cds.parse.expr hack — replaced with proper CDS where object
            let query = SELECT
                .from(`${ItalyCustomers.name} as customer`)
                .join(`${CountryProvinces.name} as province`)
                .on({ 'customer.E1KNA1M_REGIO': 'province.Name' })
                .where({
                    'customer.E1KNA1M_LAND1': 'IT',
                    'province.countrycode': 'IT',
                    'customer.E1KNA1M_KTOKD': { '<>': '0002' },
                });

            // Only add NOT IN when there are existing customers
            if (customerNumbers.length > 0) {
                query.where('customer.E1KNA1M_KUNNR NOT IN', customerNumbers);
            }

            const customers = await tx.run(query);

            if (!customers || customers.length === 0) {
                await tx.commit();
                console.log('No new institutes to create.');
                return;
            }

            let nextInstituteID = await this.getLastInstituteID();

            // NOTE: using for...of instead of .map() because we need to await
            // getPaymentTerms() for each customer. await inside .map() does NOT
            // wait — it returns an array of unresolved Promises instead.
            const instituteEntries = [];
            for (const cust of customers) {
                let InstType = cust.E1KNA1M_KTOKD;
                if (InstType === '0001') InstType = 'Sold To';
                if (InstType === '0002') InstType = 'Ship To';

                const paymentTerms = await this.getPaymentTerms(cust.E1KNVVM_ZTERM) || '';

                instituteEntries.push({
                    CountryCode: cust.E1KNA1M_LAND1,
                    InstituteID: ++nextInstituteID,
                    CustomerID: cust.E1KNA1M_KUNNR,
                    InstituteName: cust.E1KNA1M_NAME1,
                    InstituteType: this.getInstituteType(cust.E1KNVVM_KVGR3),
                    Address: `${cust.E1KNA1M_STRAS}, ${cust.E1KNA1M_PSTLZ} ${cust.E1KNA1M_ORT01} \\ VAT: ${cust.E1KNA1M_STCEG} \\ Fiscal Code: ${cust.E1KNA1M_STCD1}`,
                    ContactNo: cust.E1KNA1M_TELF1,
                    Fax: cust.E1KNA1M_TELFX,
                    ContactPerson: cust.E1KNA1M_STKZN,
                    ActiveRecord: 'Yes',
                    Comment: `${cust.E1KNVVM_KVGR3}, ${InstType}`,
                    City: cust.E1KNA1M_ORT01,
                    INSTITUTE_HIERARCHY_ID: 1,
                    State: '',
                    MercadoPublicoIssuer: '',
                    RegionID: cust.RegionID,
                    VatCode: cust.E1KNA1M_STCEG,
                    TaxCode: cust.E1KNA1M_STCD1,
                    INCOTerms: '',
                    PaymentTerms: paymentTerms,
                    ForAllBrands: 'TRUE',
                    DirectTender: 'TRUE',
                });
            }

            if (instituteEntries && instituteEntries.length > 0) {
                const result = await tx.run(INSERT(instituteEntries).into(PT_TMINST));
                await tx.commit();
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
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Update Institute Entries
    // ─────────────────────────────────────────────────────────────────────────
    async updateInstituteEntries() {
        const tx = cds.tx();
        try {
            const { ItalyCustomerUpdateInstituteEntriesView } = this.db.entities('com.bayer.SXTENDER.MasterDataViews');
            const { PT_TMINST } = this.db.entities('com.bayer.SXTENDER.MasterData');

            const customers = await tx.run(SELECT.from(ItalyCustomerUpdateInstituteEntriesView));

            if (!customers || customers.length === 0) {
                await tx.commit();
                console.log('No institutes to update.');
                return;
            }

            const promises = customers.map(cust => {
                let UpdateType = cust.E1KNA1M_KTOKD;
                if (UpdateType === '0001') UpdateType = 'Sold To';
                if (UpdateType === '0002') UpdateType = 'Ship To';

                const obj = {
                    CountryCode: cust.E1KNA1M_LAND1,
                    CustomerID: cust.E1KNA1M_KUNNR,
                    InstituteName: cust.E1KNA1M_NAME1,
                    InstituteType: this.getInstituteType(cust.E1KNVVM_KVGR3),
                    Address: `${cust.E1KNA1M_STRAS}, ${cust.E1KNA1M_PSTLZ} ${cust.E1KNA1M_ORT01}`,
                    ContactNo: cust.E1KNA1M_TELF1,
                    Fax: cust.E1KNA1M_TELFX,
                    ContactPerson: cust.E1KNA1M_STKZN,
                    ActiveRecord: 'Yes',
                    Comment: `${cust.E1KNVVM_KVGR3}, ${UpdateType}`,
                    City: cust.E1KNA1M_ORT01,
                    INSTITUTE_HIERARCHY_ID: 1,
                    RegionID: cust.RegionID,
                    VatCode: cust.E1KNA1M_STCEG,
                    TaxCode: cust.E1KNA1M_STCD1,
                    INCOTerms: '',
                    PaymentTerms: cust.PaymentTerms,
                    ForAllBrands: 'TRUE',
                    DirectTender: 'TRUE',
                };

                return tx.run(UPDATE(PT_TMINST).with(obj).where({ InstituteID: cust.InstituteID, CountryCode: cust.CountryCode }));
            });

            const result = await Promise.all(promises);
            await tx.commit();
            console.log(`${promises.length} Institutes successfully updated in ${PT_TMINST.name}.`);
            return result;

        } catch (error) {
            console.error('Updating Institutes has failed.');
            console.error(error);
            await tx.rollback(error);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helper: Get payment terms description
    // BUG FIX: original used `tx` that was out of scope — now creates its own tx
    // ─────────────────────────────────────────────────────────────────────────
    async getPaymentTerms(ZTERM) {
        if (!ZTERM) return '';
        const tx = cds.tx();
        try {
            const { PaymentTerms } = this.db.entities('com.bayer.SXTENDER.MasterData');
            const result = await tx.run(
                SELECT.one.from(PaymentTerms, ['Description']).where({ E1KNVVM_ZTERM: ZTERM })
            );
            await tx.commit();
            return result ? result.Description : '';
        } catch (error) {
            console.error('getPaymentTerms failed:', error);
            await tx.rollback(error);
            return '';
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helper: Map KVGR3 code to institute type
    // ─────────────────────────────────────────────────────────────────────────
    getInstituteType(id) {
        const KVGR3 = {
            I61: 'Private Account', I69: 'Private Account', I64: 'Private Account',
            I66: 'Private Account', I62: 'Private Account', OEM: 'OEM',
            I53: 'Private Account', I43: 'Private Account', I50: 'Private Account',
            I55: 'Private Account', I58: 'Private Account', BVL: 'Private Account',
            I44: 'Private Account', I54: 'Private Account', L31: 'Private Account',
            I45: 'Private Account', I67: 'Private Account', I57: 'Public Account',
            I49: 'Private Account', L40: 'Private Account', I68: 'Private Account',
            I42: 'Public Account',  I63: 'Public Account',  I56: 'Public Account',
            I65: 'Public Account',  I46: 'Private Account', I47: 'Private Account',
            I51: 'Private Account', BVK: 'Private Account', I59: 'Private Account',
            I40: 'Private Account', I41: 'Private Account', I52: 'Private Account',
            I60: 'Private Account', AUI: 'Private Account', I48: 'Private Account',
            DV:  'Private Account', I24: 'Private Account', L42: 'Private Account',
        };
        return KVGR3[id];
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helper: Look up institute type from DB when not in the static map
    // BUG FIX: original was async but not awaited at call site in updateInstituteEntries
    // ─────────────────────────────────────────────────────────────────────────
    async updateInstituteType(id) {
        const tx = cds.tx();
        try {
            const { PT_TMINST } = this.db.entities('com.bayer.SXTENDER.MasterData');
            const result = await tx.run(
                SELECT.one.from(PT_TMINST, ['InstituteType']).where({ CustomerID: parseInt(id), CountryCode: 'IT' })
            );
            await tx.commit();
            return result ? result.InstituteType : '';
        } catch (error) {
            console.error('updateInstituteType failed:', error);
            await tx.rollback(error);
            return '';
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Institute Brand helpers (currently called via createInstituteBrands)
    // ─────────────────────────────────────────────────────────────────────────
    async createInstituteBrands() {
        try {
            await this.createInstituteBrandTerms();
            await this.createInstituteDistributorBrands();
        } catch (error) {
            console.error(error);
        }
    }

    async createInstituteBrandTerms() {
        const tx = cds.tx();
        try {
            const { PT_TMINSBRTR } = this.db.entities('com.bayer.SXTENDER.MasterData');
            const { ItalyCustomerCreateInstituteBrandView } = this.db.entities('com.bayer.SXTENDER.MasterDataViews');

            const brandTerms = await tx.run(SELECT.from(ItalyCustomerCreateInstituteBrandView));

            if (!brandTerms || brandTerms.length <= 0) {
                await tx.commit();
                return;
            }

            let row = await tx.run(SELECT.one.from(PT_TMINSBRTR, ['Max(INSTITUTEBRANDTERMSID) as max']));
            let lastID = row ? (row.max || 0) : 0;

            const instituteBrandEntries = brandTerms.map(brandTerm => ({
                InstituteBrandTermsID: ++lastID,
                CountryCode: brandTerm.CountryCode,
                INCOTerms: '',
                PaymentTerms: '60 gg',
                ActiveRecord: 'Yes',
                InstituteID: brandTerm.InstituteID,
                HLevel4_Code: brandTerm.HLEVEL4_CODE,
            }));

            if (instituteBrandEntries && instituteBrandEntries.length > 0) {
                const result = await tx.run(INSERT(instituteBrandEntries).into(PT_TMINSBRTR));
                await tx.commit();
                console.log(`${instituteBrandEntries.length} Institute Brand Terms successfully created in ${PT_TMINSBRTR.name}.`);
                return result;
            }
            await tx.commit();
            return;

        } catch (error) {
            console.error('Creating Institute Brand Terms has failed.');
            console.error(error);
            await tx.rollback(error);
        }
    }

    async createInstituteDistributorBrands() {
        const tx = cds.tx();
        try {
            const { PT_TMINDSBR } = this.db.entities('com.bayer.SXTENDER.MasterData');
            const { ItalyCustomerCreateInstituteDistributorBrandView } = this.db.entities('com.bayer.SXTENDER.MasterDataViews');

            const brands = await tx.run(SELECT.from(ItalyCustomerCreateInstituteDistributorBrandView));

            if (!brands || brands.length <= 0) {
                await tx.commit();
                return;
            }

            let row = await tx.run(SELECT.one.from(PT_TMINDSBR, ['Max(INSTITUTEDISTBRANDRELATIONID) as max']));
            let lastID = row ? (row.max || 0) : 0;

            const instituteDistributorBrandEntries = brands.map(brand => ({
                InstituteDistBrandRelationID: ++lastID,
                CountryCode: brand.CountryCode,
                Commissionrate: 0,
                ActiveRecord: 'Yes',
                InstituteID: brand.InstituteID,
                DistributorID: brand.DistributorID,
                HLevel4_Code: brand.HLEVEL4_CODE,
            }));

            if (instituteDistributorBrandEntries && instituteDistributorBrandEntries.length > 0) {
                const result = await tx.run(INSERT(instituteDistributorBrandEntries).into(PT_TMINDSBR));
                await tx.commit();
                console.log(`${instituteDistributorBrandEntries.length} Institute Distributor Brands successfully created in ${PT_TMINDSBR.name}.`);
                return result;
            }
            await tx.commit();
            return;

        } catch (error) {
            console.error('Creating Institute Distributor Brands has failed.');
            console.error(error);
            await tx.rollback(error);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Clear ItalyCustomers table
    // ─────────────────────────────────────────────────────────────────────────
    async clearItalyCustomersTable() {
        const tx = cds.tx();
        try {
            const { ItalyCustomers } = this.db.entities('com.bayer.SXTENDER.MasterData.SAP');
            console.log(`Clearing ${ItalyCustomers.name} table ...`);
            const result = await tx.run(DELETE.from(ItalyCustomers));
            await tx.commit();
            console.log(`${ItalyCustomers.name} table successfully cleared. ${result} records deleted.`);
            return result;
        } catch (error) {
            console.error('Clearing the Italy Customers table failed');
            console.error(error);
            await tx.rollback(error);
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Helper: get last Institute ID
    // BUG FIX: original opened a tx but never reused this.db — now consistent
    // ─────────────────────────────────────────────────────────────────────────
    async getLastInstituteID() {
        const tx = cds.tx();
        try {
            const { PT_TMINST } = this.db.entities('com.bayer.SXTENDER.MasterData');
            const row = await tx.run(SELECT.one.from(PT_TMINST, ['Max(INSTITUTEID) as max']));
            await tx.commit();
            return row ? (row.max || 0) : 0;
        } catch (error) {
            console.error(error);
            await tx.rollback(error);
            return 0;
        }
    }

    addLeadingZeros(num, size) {
        let str = num.toString();
        while (str.length < size) str = '0' + str;
        return str;
    }

    async saveError(error) {
        if (!error) throw new Error('You must provide an error object');
        const tx = cds.tx();
        try {
            const errorEntity = {
                JobName: 'ItalyJobs',
                JobDescription: 'ProcessCustomers',
                ErrorMessage: error.message,
                ResourceURL: '',
                ConsultationDate: new Date().toJSON(),
            };
            const result = await tx.run(INSERT.into('com.bayer.SXTENDER.AdminData.SchedulerErrorLog', errorEntity));
            await tx.commit();
            return result;
        } catch (err) {
            console.error(err);
            await tx.rollback(err);
        }
    }
};