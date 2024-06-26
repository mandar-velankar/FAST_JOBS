const cds = require('@sap/cds');
const BaseJob = require('../BaseJob');

module.exports = class ProcessMaterials extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
        this.jobName = jobName.toUpperCase();
    }

    /**
    * Triggered when job has started
    */
    //override
    async onTick() {
        console.log(`JOB (${this.jobName }): Processing Brazil materials ...`);
        const start = new Date().getTime();
        this.db = await cds.connect.to('db');
        const tx = this.db.tx();
        try {
            // Fetch data
            const allSAPMaterials = await this.getSAPMaterials(tx);

            // Process data
            await this.processMaterials(tx, allSAPMaterials);

            // Commit All
            await tx.commit();
            console.log(`JOB (${this.jobName }): Processing of Brazil materials successfully completed.`);
            const end = new Date().getTime();
            const time = end - start;
            console.log(`JOB (${this.jobName }): SUCCESS --> Execution time: ${time} ms`);

        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Processing of Brazil materials failed.`);
            console.error(error);
            await tx.rollback();
            //throw error;
        }
    }


    /**
     * This method fetches all the materials from COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILMATERIALS
     * @returns - A list of Materials
     */
    async getSAPMaterials(tx) {
        try {
            console.log(`JOB (${this.jobName }): Fetching Brazil materials from COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILMATERIALS ...`);
            const { BrazilMaterials } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const result = await tx.run(SELECT.from(BrazilMaterials));
            return result;
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching of Brazil materials from COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILMATERIALS failed`);
            console.error(error);
            throw error;
        }
    }

    /**
     * This method will process a list of Materials by Creating/Updating the following entities
     *  - PT_TMPRDHIER
     *  - PT_TMPRDPCK
     *  - PT_TMCTPRDPCK
     *  - PT_TMSKUPRDPCK
     * After successful processing, the COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILMATERIALS records will be deleted.
     * @param {[Object]} materials 
     */
    async processMaterials(tx, materials) {
        console.log(`JOB (${this.jobName }): Processing Brazil materials ...`);
        try {

            // 0. Mapping - Map SAP Materials to FAST
            const mappedHierarchy = this.mapSAPMaterialsToFASTHierarchy(materials);
            const mappedProductPacks = this.mapSAPMaterialsToFASTProductPack(materials);
            const mappedCountryProductPacks = this.mapSAPMaterialsToFASTCountryProductPack(materials);
            const mappedProductPackSKUs = this.mapSAPMaterialsToFASTProductPackSKU(materials);

            // 1. Create/update hierarchy entries in PT_TMPRDHIER
            await this.upsertFASTHierarchy(tx, mappedHierarchy);

            // 2. Create/update ProductPacks entries in PT_TMPRDPCK
            await this.upsertFASTProductPacks(tx, mappedProductPacks, mappedCountryProductPacks, mappedProductPackSKUs);

            // 3. Create/update CountryProductPacks entries in PT_TMCTPRDPCK
            await this.upsertFASTCountryProductPacks(tx, mappedCountryProductPacks);

            // 4. Create ProductPackSKUs entries in PT_TMSKUPRDPCK
            await this.upsertFASTProductPackSKUs(tx, mappedProductPackSKUs);

            // 5. Delete all records from BrazilMaterials after successful processing.
            const { BrazilMaterials } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            await tx.run(DELETE.from(BrazilMaterials));

            console.log(`JOB (${this.jobName }): Processing of Brazil materials successfully completed.`);

        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Processing of Brazil materials failed.`);
            console.error(error);
            throw error;
        }
    }

    /**
     * Maps Material fields from SAP (BRAZILMATERIALS) to FAST Hierarchy (PT_TMPRDHIER)
     * @param {[Objects]} materials 
     * @returns {[Objects]} hierarchy
     */
     mapSAPMaterialsToFASTHierarchy(materials) {
        console.log(`JOB (${this.jobName }): Mapping BRAZILMATERIALS to PT_TMPRDHIER ...`);
        materials = materials.reduce((prev, curr, idx, materials) => {
            prev.push(
                {
                    HLEVEL1_NAME: this.getDivisionName(curr.SETOR_ATIV),
                    HLEVEL1_CODE: curr.SETOR_ATIV,
                    HLEVEL2_NAME: null,
                    HLEVEL2_CODE: null,
                    HLEVEL3_NAME: null,
                    HLEVEL3_CODE: null,
                    HLEVEL4_NAME: curr.BRAND, // this.extractBrandNameFrom(curr.NOME),
                    HLEVEL4_CODE: curr.BRAND, // this.extractBrandNameFrom(curr.NOME),
                    HLEVEL5_NAME: null,
                    HLEVEL5_CODE: null,
                    HLEVEL6_NAME: curr.NOME,
                    HLEVEL6_CODE: curr.COD
                }
            );
            return prev;
        }, []);
        return materials;
    }

    /**
     * Maps Material fields from SAP (BRAZILMATERIALS) to FAST ProductPack (PT_TMPRDPCK)
     * @param {*} materials 
     * @returns {[Objects]} PT_TMPRDPCK objects
     */
     mapSAPMaterialsToFASTProductPack(materials) {
        console.log(`JOB (${this.jobName }): Mapping BRAZILMATERIALS to PT_TMPRDPCK ...`);
        materials = materials.reduce((prev, curr, idx, materials) => {
            prev.push(
                {
                    PRODUCTPACKID: "",
                    PRODUCTPACKNAME: curr.NOME,
                    PRESENTATION: "NA",
                    UOM: "NA",
                    ACTIVERECORD: "Yes",
                    HLEVEL6_CODE: curr.NOME,
                    CONCENTRATION: 1,
                    PACKFACTOR: 1,
                    PCIName: curr.APRES,
                    MoleculeName: "NA",
                    ACTIVE_SUBSTANCE: "NA",
                    ProductType: "NA",
                    ProductClass: "NA",
                    ProductDescription: "NA",
                    ProductFullDescription: "NA",
                    Nucleus: "NA",
                    ProductGenericName: "NA",
                }
            );
            return prev;
        }, []);
        return materials;
    }

    /**
     * Maps Material fields from SAP (BRAZILMATERIALS) to FAST CountryProductPack (PT_TMCTPRDPCK)
     * @param {*} materials 
     * @returns {[Objects]} PT_TMCTPRDPCK objects
     */
     mapSAPMaterialsToFASTCountryProductPack(materials) {
        console.log(`JOB (${this.jobName }): Mapping BRAZILMATERIALS to PT_TMCTPRDPCK ...`);
        materials = materials.reduce((prev, curr, idx, materials) => {
            prev.push(
                {
                    COUNTRYPRODUCTPACKID: "",
                    COUNTRYCODE: "BR",
                    COUNTRYOFORIGIN: curr.PROCEDENCIA,
                    SHELFLIFE: 1,
                    REGISTERED: 2,
                    ACTIVERECORD: "Yes",
                    PRODUCTPACKID: "",
                    MANUFACTURER: "NA",
                    Presentation_2: "NA",
                    VTATax: 0,
                    COMMENT: "",
                    GOV_CODE: curr.NREG,
                    CODE1: curr.CBAR,
                    CODE2: curr.GRUPO_MAT3,
                    CODE3: "",
                    QTY_THRESHOLD: 0,
                    BU: this.getDivisionName(curr.SETOR_ATIV),
                }
            );
            return prev;
        }, []);
        return materials;
    }


    /**
     * Maps Material fields from SAP (BRAZILMATERIALS) to FAST ProductPackSKU (PT_TMSKUPRDPCK)
     * @param {*} materials 
     * @returns {[Objects]} PT_TMSKUPRDPCK objects
     */
     mapSAPMaterialsToFASTProductPackSKU(materials) {
        console.log(`JOB (${this.jobName }): Mapping BRAZILMATERIALS to PT_TMSKUPRDPCK ...`);
        materials = materials.reduce((prev, curr, idx, materials) => {
            prev.push(
                {
                    CountrySKUID: "",
                    CountryCode: "BR",
                    ActiveRecord: "Yes",
                    ProductPackID: "", // --link from TMPRDPCK,
                    SKUCode: Number(curr.COD),
                }
            );
            return prev;
        }, []);
        return materials;
    }


    /**
     * Creates or Updates Hierarchies in FAST
     * @param {Array.Object} Mapped Hierarchies 
     * @returns 
     */
    async upsertFASTHierarchy(tx, mappedHierarchies) {
        const { PT_TMPRDHIER } = this.db.entities("com.bayer.SXTENDER.MasterData");

        // 1. get a list of existing Hierarchies from FAST
        const hierarchiesExistingInFAST = await this.getFASTHierarchies(tx, mappedHierarchies);
        // 2. devide mappedDistributors into New or Changed distributors
        const FASTNewHierarchies = [];
        const FASTChangedHierarchies = [];
        for (const hierarchy of mappedHierarchies) {
            let FASTHierarchyIdx = hierarchiesExistingInFAST.findIndex(FASTHierarchy => Number(FASTHierarchy.HLEVEL6_CODE) === Number(hierarchy.HLEVEL6_CODE));
            if (FASTHierarchyIdx > -1) {
                FASTChangedHierarchies.push(hierarchy);
            } else {
                FASTNewHierarchies.push(hierarchy);
            }
        }
        // 3. Upsert records into PT_TMDIST
        //Update is one by one: https://answers.sap.com/questions/13676137/bulk-update-in-cap-nodejs.html
        console.log(`JOB (${this.jobName }): Upserting Brazil Hierarchies into FAST table (PT_TMPRDHIER) ...`);
        try {
            for (const FASTHierarchy of FASTChangedHierarchies) {
                await tx.run(UPDATE(PT_TMPRDHIER, {HLEVEL6_CODE:FASTHierarchy.HLEVEL6_CODE}).with(FASTHierarchy));
            }
            FASTNewHierarchies && FASTNewHierarchies.length > 0 && await tx.run(INSERT(FASTNewHierarchies).into(PT_TMPRDHIER));
            console.log(`JOB (${this.jobName }): Upserting of Brazil Hierarchies into FAST table (PT_TMPRDHIER) successfully completed.`);
            console.log(`JOB (${this.jobName }): PT_TMPRDHIER -> created: ${FASTNewHierarchies.length}, updated: ${FASTChangedHierarchies.length}`);
            return true;
        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Upserting of Brazil Hierarchies into FAST table (PT_TMPRDHIER) failed`);
            console.error(error);
            throw error;
        }
    }

    /**
     * Creates or Updates ProductPacks in FAST + sets the ProductPackID in mappedCountryProductPacks and mappedProductPackSKUs
     * INFO: mappedProductPacks, mappedCountryProductPacks, mappedProductPackSKUs started from the same list of records to do the mapping,
     * this makes it safe to assume that the index in those arrays points to the same record. We will use this assumption to add
     * ProductPackID to mappedCountryProductPacks and mappedProductPackSKUs to set the link with mappedProductPacks
     * @param {Array<PT_TMPRDPCK>} mappedProductPacks
     * @param {Array<PT_TMCTPRDPCK>} mappedCountryProductPacks
     * @param {Array<PT_TMSKUPRDPCK>} mappedProductPackSKUs
     * @returns 
     */
     async upsertFASTProductPacks(tx, mappedProductPacks, mappedCountryProductPacks, mappedProductPackSKUs) {
        const { PT_TMPRDPCK} = this.db.entities("com.bayer.SXTENDER.MasterData");
        let nextProductPackID = await this.getNextValue(tx, PT_TMPRDPCK, "PRODUCTPACKID");
        
        // 0. SAP material may contain the same ProductPack per SKU, we must not process the same ProductPack more than ones
        const uniqueMappedProductPacks = Array.from(new Set(mappedProductPacks.map(d => d.PRODUCTPACKNAME)))
                                        .map(name => {
                                            return mappedProductPacks.find(d => d.PRODUCTPACKNAME === name)
                                        });
        // 1. get a list of existing ProductPacks from FAST
        const productPacksExistingInFAST = await this.getFASTProductPacks(tx, uniqueMappedProductPacks);
        // 2. devide mapped ProductPacks into New or Changed ProductPacks
        const FASTNewProductPacks = [];
        const FASTChangedProductPacks = [];
        for (const [index, productPack] of uniqueMappedProductPacks.entries()) {
            let FASTProductPackdx = productPacksExistingInFAST.findIndex(FASTProductPack => FASTProductPack.PRODUCTPACKNAME === productPack.PRODUCTPACKNAME);
            if (FASTProductPackdx > -1) {
                // copy over the ProductPackID from existing ProductPack
                const existingProductPackID = productPacksExistingInFAST[FASTProductPackdx].PRODUCTPACKID;
                productPack.PRODUCTPACKID = existingProductPackID;
                mappedCountryProductPacks[index].PRODUCTPACKID = existingProductPackID;
                mappedProductPackSKUs[index].ProductPackID = existingProductPackID;
                FASTChangedProductPacks.push(productPack);
            } else {
                // generate new ProductPackID and link it to CountryProductPacks and ProductPackSKUs
                const nextID = nextProductPackID++;
                productPack.PRODUCTPACKID = nextID;
                mappedCountryProductPacks[index].PRODUCTPACKID = nextID;
                mappedProductPackSKUs[index].ProductPackID = nextID;
                FASTNewProductPacks.push(productPack);
            }
        }

        // 3. some SKUs belong to the same ProductPack. These SKUs could't be mapped to a ProductPackID and therefore we need to handle them here
        const productPackSKUidxWithouPackID = mappedProductPackSKUs.reduce((prev, curr, idx) => { !curr.ProductPackID && prev.push(idx); return prev;}, []);
        productPackSKUidxWithouPackID.forEach(idx => {
            mappedProductPackSKUs[idx].ProductPackID = mappedProductPacks[idx].PRODUCTPACKID;
        });

        // 4. Upsert records into PT_TMPRDPCK 
        console.log(`JOB (${this.jobName }): Upserting Brazil ProductPacks into FAST table PT_TMPRDPCK ...`);
        try {
            for (const FASTProductPack of FASTChangedProductPacks) {
                await tx.run(UPDATE(PT_TMPRDPCK, {PRODUCTPACKID:FASTProductPack.PRODUCTPACKID}).with(FASTProductPack));
            }
            FASTNewProductPacks && FASTNewProductPacks.length > 0 && await tx.run(INSERT(FASTNewProductPacks).into(PT_TMPRDPCK));
            console.log(`JOB (${this.jobName }): Upserting of Brazil ProductPacks into FAST table PT_TMPRDPCK successfully completed.`);
            console.log(`JOB (${this.jobName }): PT_TMPRDPCK -> created: ${FASTNewProductPacks.length}, updated: ${FASTChangedProductPacks.length}`);
            return true;
        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Upserting of Brazil ProductPacks into FAST table PT_TMPRDPCK failed`);
            console.error(error);
            throw error;
        }
    }

    /**
     * Creates or Updates CountryProductPacks in FAST
     * @param {Array<PT_TMCTPRDPCK>} mappedCountryProductPacks
     * @returns 
     */
     async upsertFASTCountryProductPacks(tx, mappedCountryProductPacks) {
        const { PT_TMCTPRDPCK} = this.db.entities("com.bayer.SXTENDER.MasterData");
        let nextCountryProductPackID = await this.getNextValue(tx, PT_TMCTPRDPCK, "COUNTRYPRODUCTPACKID");

        // 0. SAP material may contain the same ProductPack per SKU, we must not process the same ProductPack more than ones
        // in this case we are filtering out the records that don't have a ProductPackId mapped from the previous steps
        const uniqueMappedCountryProductPacks = mappedCountryProductPacks.filter(c => c.PRODUCTPACKID);
        
        // 1. get a list of existing CountryProductPacks from FAST
        const countryProductPacksExistingInFAST = await this.getFASTCountryProductPacks(tx, uniqueMappedCountryProductPacks);
        // 2. devide mapped CountryProductPacks into New or Changed CountryProductPacks
        const FASTNewCountryProductPacks = [];
        const FASTChangedCountryProductPacks = [];
        for (const countryProductPack of uniqueMappedCountryProductPacks) {
            let FASTCountryProductPackdx = countryProductPacksExistingInFAST.findIndex(FASTCountryProductPack => FASTCountryProductPack.PRODUCTPACKNAME === countryProductPack.PRODUCTPACKNAME);
            if (FASTCountryProductPackdx > -1) {
                // copy over the ProductPackID and CountryProductPackID from existing ProductPack
                const existingProductPackID = countryProductPacksExistingInFAST[FASTCountryProductPackdx].PRODUCTPACKID;
                const existingCountryProductPackID = countryProductPacksExistingInFAST[FASTCountryProductPackdx].COUNTRYPRODUCTPACKID;
                countryProductPack.PRODUCTPACKID = existingProductPackID;
                countryProductPack.COUNTRYPRODUCTPACKID = existingCountryProductPackID;
                FASTChangedCountryProductPacks.push(countryProductPack);
            } else {
                // generate new CountryProductPackID
                countryProductPack.COUNTRYPRODUCTPACKID = nextCountryProductPackID++;
                FASTNewCountryProductPacks.push(countryProductPack);
            }
        }
        // 3. Upsert records into PT_TMCTPRDPCK 
        console.log(`JOB (${this.jobName }): Upserting Brazil CountryProductPacks into FAST table PT_TMCTPRDPCK ...`);
        try {
            for (const FASTCountryProductPack of FASTChangedCountryProductPacks) {
                await tx.run(UPDATE(PT_TMCTPRDPCK, {PRODUCTPACKID:FASTCountryProductPack.PRODUCTPACKID, COUNTRYCODE: 'BR'}).with(FASTCountryProductPack));
            }
            FASTNewCountryProductPacks && FASTNewCountryProductPacks.length > 0 && await tx.run(INSERT(FASTNewCountryProductPacks).into(PT_TMCTPRDPCK));
            console.log(`JOB (${this.jobName }): Upserting of Brazil CountryProductPacks into FAST table PT_TMCTPRDPCK successfully completed.`);
            console.log(`JOB (${this.jobName }): PT_TMCTPRDPCK -> created: ${FASTNewCountryProductPacks.length}, updated: ${FASTChangedCountryProductPacks.length}`);
            return true;
        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Upserting of Brazil CountryProductPacks into FAST table PT_TMCTPRDPCK failed`);
            console.error(error);
            throw error;
        }
    }

    /**
     * Creates ProductPackSKUs in FAST
     * No update needed as all fields are keys
     * @param {Array<PT_TMSKUPRDPCK>} mappedProductPackSKUs
     * @returns 
     */
     async upsertFASTProductPackSKUs(tx, mappedProductPackSKUs) {
        const { PT_TMSKUPRDPCK} = this.db.entities("com.bayer.SXTENDER.MasterData");
        let nextCountrySKUID = await this.getNextValue(tx, PT_TMSKUPRDPCK, "CountrySKUID");
        
        // 1. get a list of existing ProductPackSKUs from FAST
        const productPackSKUsExistingInFAST = await this.getFASTProductPackSKUs(tx, mappedProductPackSKUs);
        // 2. devide mapped ProductPackSKUs into New or Changed ProductPackSKUs
        const FASTNewProductPackSKUs = [];
        for (const productPackSKU of mappedProductPackSKUs) {
            let FASTProductPackSKUidx = productPackSKUsExistingInFAST.findIndex(FASTProductPackSKU => FASTProductPackSKU.PRODUCTPACKNAME === productPackSKU.PRODUCTPACKNAME);
            if (FASTProductPackSKUidx === -1) {
                // generate new nextCountrySKUID
                productPackSKU.CountrySKUID = nextCountrySKUID++;
                FASTNewProductPackSKUs.push(productPackSKU);
            }
        }
        // 3. Create records in PT_TMSKUPRDPCK 
        console.log(`JOB (${this.jobName }): Upserting Brazil ProductPackSKUs into FAST table PT_TMSKUPRDPCK ...`);
        try {
            FASTNewProductPackSKUs && FASTNewProductPackSKUs.length > 0 && await tx.run(INSERT(FASTNewProductPackSKUs).into(PT_TMSKUPRDPCK));
            console.log(`JOB (${this.jobName }): Upserting of Brazil ProductPackSKUs into FAST table PT_TMSKUPRDPCK successfully completed.`);
            console.log(`JOB (${this.jobName }): PT_TMSKUPRDPCK -> created: ${FASTNewProductPackSKUs.length}`);
            return true;
        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Upserting of Brazil ProductPackSKUs into FAST table PT_TMSKUPRDPCK failed`);
            console.error(error);
            throw error;
        }
    }
    

    /**
     * Gets a list of existing Hierarchies from FAST.
     * @param {Array} Hierarchies 
     * @returns {Array<PT_TMPRDHIER>} a list of existing Hierarchies
     */
    async getFASTHierarchies(tx, mappedHierarchies) {
        if(!mappedHierarchies || mappedHierarchies.length === 0){
            console.log(`JOB (${this.jobName }): No hierarchies were found in FAST (PT_TMPRDHIER)`);
            return [];
        }
        console.log(`JOB (${this.jobName }): Prepare fetching Brazil hierarchies from PT_TMPRDHIER`);

        // get all the HLEVEL6_NAMEs from mappedHierarchies
        let aHLEVEL6_CODEs = [];
        for (const hierarchy of mappedHierarchies) {
            aHLEVEL6_CODEs.push(hierarchy.HLEVEL6_CODE);
        }
        console.log(`JOB (${this.jobName }): Fetching Brazil hierarchies from PT_TMPRDHIER ...`);

        // get a list of distributors entities for given list of CustomerIDs
        const { PT_TMPRDHIER } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const result = await tx.run(SELECT.from(PT_TMPRDHIER).where({ HLEVEL6_CODE: { in: aHLEVEL6_CODEs } } ));
        return result;
    }

    /**
     * Gets a list of existing ProductPacks from FAST.
     * @param {Array<PT_TMPRDPCK>} ProductPacks 
     * @returns {Array<PT_TMPRDPCK>} a list of existing ProductPacks
     */
     async getFASTProductPacks(tx, mappedProductPacks) {
        if(!mappedProductPacks || mappedProductPacks.length === 0){
            console.log(`JOB (${this.jobName }): No ProductPacks were found in FAST (PT_TMPRDPCK)`);
            return [];
        }
        console.log(`JOB (${this.jobName }): Prepare fetching Brazil ProductPacks from PT_TMPRDPCK`);

        // get all the ProductPackNames from mappedProductPacks
        let productPackNames = [];
        for (const productPack of mappedProductPacks) {
            productPackNames.push(productPack.PRODUCTPACKNAME);
        }
        console.log(`JOB (${this.jobName }): Fetching Brazil ProductPacks from PT_TMPRDPCK ...`);

        // get a list of ProductPack entities for given list of ProductPackNames
        const { PT_TMPRDPCK, PT_TMCTPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const result = await tx.run(
            SELECT.from(`${PT_TMPRDPCK.name} as p`)
            .join(`${PT_TMCTPRDPCK.name} as cp`)
            .on({'p.PRODUCTPACKID': {'=': 'cp.PRODUCTPACKID'}})
            .where({'cp.COUNTRYCODE': {'=': 'BR'}})
            .where({ PRODUCTPACKNAME: { in: productPackNames } } )
        );
        return result;
    }

     /**
     * Gets a list of existing CountryProductPacks from FAST.
     * @param {Array<PT_TMCTPRDPCK>} CountryProductPacks 
     * @returns {Array<PT_TMCTPRDPCK>} a list of existing CountryProductPacks
     */
      async getFASTCountryProductPacks(tx, mappedCountryProductPacks) {
        if(!mappedCountryProductPacks || mappedCountryProductPacks.length === 0){
            console.log(`JOB (${this.jobName }): No CountryProductPacks were found in FAST (PT_TMCTPRDPCK)`);
            return [];
        }
        console.log(`JOB (${this.jobName }): Prepare fetching Brazil CountryProductPacks from PT_TMCTPRDPCK`);

        // get all the productPackIDs from mappedCountryProductPacks
        let productPackIDs = [];
        for (const productPack of mappedCountryProductPacks) {
            productPackIDs.push(productPack.PRODUCTPACKID);
        }
        console.log(`JOB (${this.jobName }): Fetching Brazil CountryProductPacks from PT_TMCTPRDPCK ...`);

        // get a list of ProductPack entities for given list of ProductPackNames
        const {PT_TMCTPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const result = await tx.run(SELECT.from(PT_TMCTPRDPCK).where({ PRODUCTPACKID: { in: productPackIDs}, COUNTRYCODE: 'BR' } ));
        return result;
    }

    /**
     * Gets a list of existing ProductPackSKUs from FAST.
     * @param {Array<PT_TMSKUPRDPCK>} ProductPackSKUs 
     * @returns {Array<PT_TMSKUPRDPCK>} a list of existing ProductPackSKUs
     */
     async getFASTProductPackSKUs(tx, mappedProductPackSKUs) {
        if(!mappedProductPackSKUs || mappedProductPackSKUs.length === 0){
            console.log(`JOB (${this.jobName }): No ProductPackSKUs were found in FAST (PT_TMSKUPRDPCK)`);
            return [];
        }
        console.log(`JOB (${this.jobName }): Prepare fetching Brazil ProductPackSKUs from PT_TMSKUPRDPCK`);

        // get all the productPackIDs and CODs from mappedProductPackSKUs
        let productPackIDs = [];
        let SKUCodes = [];
        for (const productPack of mappedProductPackSKUs) {
            productPackIDs.push(productPack.ProductPackID);
            SKUCodes.push(productPack.SKUCode);
        }
        console.log(`JOB (${this.jobName }): Fetching Brazil ProductPackSKUs from PT_TMSKUPRDPCK ...`);

        // get a list of ProductPack entities for given list of ProductPackNames
        const {PT_TMSKUPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const result = await tx.run(SELECT.from(PT_TMSKUPRDPCK).where({ ProductPackID: { in: productPackIDs},SKUCode: { in: SKUCodes}, CountryCode: 'BR' } ));
        return result;
    }
    
    /**
     * Gets the next highest value for a given field from table
     * @param {*} table 
     * @param {*} fieldname 
     * @returns - next highest value
     */
    async getNextValue (tx, table, fieldname){
        let nextValue = 1;
        try {
            let results = await tx.run(SELECT.from(table, ['Max(' + fieldname + ') as max']));
            if (results[0].max) {
                nextValue = results[0].max + 1
            }
            return nextValue;
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching next highest value for ${fieldname} from ${table.name} failed`);
            console.error(error);
            throw error;
        }
	}

    /**
     * Returns the DivisionName for a given DivisionCode
     * @param {String} divisionCode 
     * @returns {String} - DivisionName
     */
    getDivisionName(divisionCode){
        const divisions = {
            '08':'Pharma',
		    '65':'Radiology',
		    '16':'Consumer Health'
        }
        return divisions[divisionCode] || '00';
    }

    /**
     * Extracts text before comma or space (or full if not found)
     * @param {*} nome 
     * @return {String} - Brand name
     */
    extractBrandNameFrom(nome){
        const regx = /^[^\s|,]*/;
        return nome.match(regx)[0];
    }
    
};