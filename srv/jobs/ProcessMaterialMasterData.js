const BaseJob = require('./BaseJob');

module.exports = class ProcessMaterialMasterData extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
        this.jobName = jobName.toUpperCase();
    }

    /**
    * Triggered when job has started
    */
    //override
    async onTick() {
        console.log(`JOB (${this.jobName}): Processing Material Master Data started...`);
        try {
            this.db = await cds.connect.to('db');
            // Call the method to process Material Master Data
            await this.processMaterialMasterData();
        } catch (error) {
            console.error(`JOB (${this.jobName}): Error processing Material Master Data:`, error);
            await this.updateInterimStatus('Failed', error.message);
        }
        console.log(`JOB (${this.jobName}): Processing Material Master Data finished.`);
    }

    async processMaterialMasterData() {
        await this.collectMaterialMasterData();
        await this.processProductPackData();
        await this.processCountryProductPackData();
        await this.processSkuProductPackData();
        await this.clearFASTCoreMaterial();
        await this.updateInterimStatus('Processed');
    }

    async clearFASTCoreMaterial() {
        console.log(`JOB (${this.jobName}): Clearing ${FASTCoreMaterial.name} table...`);
        const { FASTCoreMaterial } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        await DELETE.from(FASTCoreMaterial);
        console.log(`JOB (${this.jobName}): ${FASTCoreMaterial.name} table cleared.`);
    }

    async updateInterimStatus(status, comment = null) {
        const { INTERIM_SPAINMATERIALS } = this.db.entities("com.bayer.SXTENDER.MasterData");
        await UPDATE(INTERIM_SPAINMATERIALS).set({ Status: status, Comment: comment }).where({ Status: 'New' });
    }

    async collectMaterialMasterData() {
        const { FASTCoreMaterial } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        const { INTERIM_SPAINMATERIALS } = this.db.entities("com.bayer.SXTENDER.MasterData");

        // Logic to collect material master data
        console.log(`JOB (${this.jobName}): Collecting material master data...`);
        // Deep select to fetch FASTCoreMaterial and its associated description and sales specification text.
        // This approach avoids separate queries and potential issues with duplicate records from associations.
        const materials = await SELECT.from(FASTCoreMaterial).columns(m => {
            m.ID,
                m.ProductInternalID,
                m.ProductHierarchyInternalID,
                m.ItemCategoryGroupCode,
                m.ProductSalesProcessUsabilityProfileCode,
                m.EAN_UPC,
                m.PrdDesc(pd => {
                    pd.Description
                }),
                m.SalesSpec(ss => {
                    ss.SalesMeasureUnitCode,
                        ss.FirstSalesSpecificationProductGroupCode,
                        ss.FourthSalesSpecificationProductGroupCode,
                        ss.FifthSalesSpecificationProductGroupCode,
                        ss.SalesSpecTxt(sst => {
                            sst.SalesSpecTxtSAPScrptLn(sstsl => {
                                sstsl.SAPScriptLineText
                            })
                        })
                })
        });

        if (!materials || materials.length === 0) {
            console.log(`JOB (${this.jobName}): No material master data found.`);
            return;
        }

        console.log(`JOB (${this.jobName}): Mapping material master data to save in the ${INTERIM_SPAINMATERIALS.name} table.`);
        const mappedMaterials = materials.map(material => this.mappedMaterialsToInterimTable(material));
        console.log(`JOB (${this.jobName}): Mapping of material master data completed.`);

        if (!mappedMaterials || mappedMaterials.length === 0) {
            console.log(`JOB (${this.jobName}): No mapped material master data to save.`);
            return;
        }

        console.log(`JOB (${this.jobName}): Saving material master data to the ${INTERIM_SPAINMATERIALS.name} table.`);
        await INSERT.into(INTERIM_SPAINMATERIALS).entries(mappedMaterials);
        console.log(`JOB (${this.jobName}): Saving of material master data completed.`);

    }

    /**
     * Maps the collected material data to the structure of the INTERIM_SPAINMATERIALS table.
     * It combines descriptions from PrdDesc and SalesSpec associations.
     * @param {object} material - The material object from the SELECT query.
     * @returns {object} - The mapped material object for insertion.
     */
    mappedMaterialsToInterimTable(material) {
        const materialDescriptionElements = [];
        // Collect unique descriptions from the PrdDesc association.
        if (material.PrdDesc && material.PrdDesc.length > 0) {
            const descriptions = new Set(material.PrdDesc.map(d => d.Description));
            materialDescriptionElements.push(...descriptions);
        }

        // Collect unique sales specification texts from the nested associations.
        if (material.SalesSpec) {
            const texts = material.SalesSpec.flatMap(ss =>
                ss.SalesSpecTxt ? ss.SalesSpecTxt.flatMap(sst =>
                    sst.SalesSpecTxtSAPScrptLn ? sst.SalesSpecTxtSAPScrptLn.map(l => l.SAPScriptLineText) : []
                ) : []
            );
            const salesSpecText = [...new Set(texts)].join(' ');
            if (salesSpecText) {
                materialDescriptionElements.push(salesSpecText);
            }
        }

        const formattedProductHierarchyFields = this.formatFieldsFromProductHierarchy(material.ProductHierarchyInternalID);

        return {
            EAN_UPC: material.EAN_UPC,
            MaterialNumber: material.ProductInternalID,
            SAPName: materialDescriptionElements?.[0] || "",
            CommercialName: materialDescriptionElements?.[1] || "",
            ProductType: null,
            PackFactor: null,
            Presentation: null,
            Strength: null,
            UOM: null,
            SalesUnitOfMeasure: material.SalesSpec[0]?.SalesMeasureUnitCode,
            ProductHierarchy: material.ProductHierarchyInternalID || "",
            DivisionCode: formattedProductHierarchyFields.DivisionCode,
            Division: formattedProductHierarchyFields.Division,
            BrandID: formattedProductHierarchyFields.BrandID,
            MaterialGroup1: material.SalesSpec[0]?.FirstSalesSpecificationProductGroupCode || "",
            MaterialGroup4: material.SalesSpec[0]?.FourthSalesSpecificationProductGroupCode || "",
            MaterialGroup5: material.SalesSpec[0]?.FifthSalesSpecificationProductGroupCode || "",
            ItemCategoryGroup: material.ItemCategoryGroupCode || "",
            MaterialStatus: material.MaterialStatus || "",
            Status: "New"
        };
    }

    async processProductPackData() {
        console.log(`JOB (${this.jobName}): Processing Product Pack Data started...`);
        const { INTERIM_SPAINMATERIALS, PT_TMPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");

        const interimMaterials = await SELECT.from(INTERIM_SPAINMATERIALS).where({ Status: 'New' });

        if (!interimMaterials || interimMaterials.length === 0) {
            console.log(`JOB (${this.jobName}): No data found in ${INTERIM_SPAINMATERIALS.name}.`);
            return;
        }

        console.log(`JOB (${this.jobName}): Mapping data from ${INTERIM_SPAINMATERIALS.name} to ${PT_TMPRDPCK.name}.`);
        const existingProductPacks = await SELECT.from(PT_TMPRDPCK).columns('PRODUCTPACKNAME');
        const existingProductPackNames = new Set(existingProductPacks.map(p => p.PRODUCTPACKNAME));

        let maxProductPackIdResult = await SELECT.one.from(PT_TMPRDPCK).columns(['max(PRODUCTPACKID) as maxId']);
        let maxProductPackId = maxProductPackIdResult ? maxProductPackIdResult.maxId : 0;

        const productPacksToUpdate = [];
        const productPacksToInsert = [];

        for (const material of interimMaterials) {
            const productPackData = this.mapToProductPack(material);

            if (existingProductPackNames.has(material.CommercialName)) {
                productPacksToUpdate.push(productPackData);
            } else {
                maxProductPackId++;
                productPacksToInsert.push({ ...productPackData, PRODUCTPACKID: maxProductPackId });
                existingProductPackNames.add(material.CommercialName); // Add to set to avoid duplicate inserts
            }
        }
        console.log(`JOB (${this.jobName}): Mapping of data from ${INTERIM_SPAINMATERIALS.name} to  ${PT_TMPRDPCK.name} completed.`);

        if (productPacksToUpdate.length > 0) {
            console.log(`JOB (${this.jobName}): Updating ${productPacksToUpdate.length} product packs in  ${PT_TMPRDPCK.name}.`);
            const updatePromises = productPacksToUpdate.map(pack =>
                UPDATE(PT_TMPRDPCK).set(pack).where({ PRODUCTPACKNAME: pack.PRODUCTPACKNAME })
            );
            await Promise.all(updatePromises);
            console.log(`JOB (${this.jobName}): Updating of product packs in  ${PT_TMPRDPCK.name} completed.`);
        }

        if (productPacksToInsert.length > 0) {
            console.log(`JOB (${this.jobName}): Inserting ${productPacksToInsert.length} new product packs in  ${PT_TMPRDPCK.name}.`);
            await INSERT.into(PT_TMPRDPCK).entries(productPacksToInsert);
            console.log(`JOB (${this.jobName}): Insertion of new product packs in  ${PT_TMPRDPCK.name} completed.`);
        }
        console.log(`JOB (${this.jobName}): Processing Product Pack Data finished.`);
    }

    mapToProductPack(material) {
        return {
            PRODUCTPACKNAME: material.CommercialName,
            PRESENTATION: material.Presentation,
            UOM: material.UOM,
            ACTIVERECORD: 'Yes',
            HLEVEL6_CODE: material.ProductHierarchy,
            CONCENTRATION: material.Strength,
            PACKFACTOR: material.PackFactor,
            PCINAME: material.CommercialName,
            MOLECULENAME: 'NA',
            ACTIVE_SUBSTANCE: null,
            PRODUCTTYPE: material.ProductType,
            PRODUCTCLASS: 'NA',
            PRODUCTDESCRIPTION: material.CommercialName,
            PRODUCTFULLDESCRIPTION: material.CommercialName,
            NUCLEUS: null,
            PRODUCTGENERICNAME: material.SAPName,
            BUNDLE: null,
            OUTERCARTON: null,
            CALCULATIONFACTORIRP: null
        };
    }

    async processCountryProductPackData() {
        console.log(`JOB (${this.jobName}): Processing Country Product Pack Data started...`);
        const { INTERIM_SPAINMATERIALS, PT_TMCTPRDPCK, PT_TMPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");

        const interimMaterials = await SELECT.from(INTERIM_SPAINMATERIALS).where({ Status: 'New' });
        if (!interimMaterials || interimMaterials.length === 0) {
            console.log(`JOB (${this.jobName}): No data found in ${INTERIM_SPAINMATERIALS.name}.`);
            return;
        }

        const productPacks = await SELECT.from(PT_TMPRDPCK).columns('PRODUCTPACKID', 'PRODUCTPACKNAME');
        const productPackMap = new Map(productPacks.map(p => [p.PRODUCTPACKNAME, p.PRODUCTPACKID]));

        const existingCountryProductPacks = await SELECT.from(PT_TMCTPRDPCK).columns('EAN');
        const existingEANs = new Set(existingCountryProductPacks.map(p => p.EAN));

        let maxCountryProductPackIdResult = await SELECT.one.from(PT_TMCTPRDPCK).orderBy({ ref: ['COUNTRYPRODUCTPACKID'], sort: 'desc' });
        let maxCountryProductPackId = maxCountryProductPackIdResult ? maxCountryProductPackIdResult.COUNTRYPRODUCTPACKID : 0;

        const countryProductPacksToUpdate = [];
        const countryProductPacksToInsert = [];

        for (const material of interimMaterials) {
            const productPackId = productPackMap.get(material.CommercialName);
            if (productPackId) {
                const countryProductPackData = this.mapToCountryProductPack(material, productPackId);

                if (existingEANs.has(material.EAN_UPC)) {
                    countryProductPacksToUpdate.push(countryProductPackData);
                } else {
                    maxCountryProductPackId++;
                    countryProductPacksToInsert.push({ ...countryProductPackData, COUNTRYPRODUCTPACKID: maxCountryProductPackId });
                    existingEANs.add(material.EAN_UPC);
                }
            }
        }

        if (countryProductPacksToUpdate.length > 0) {
            console.log(`JOB (${this.jobName}): Updating ${countryProductPacksToUpdate.length} country product packs in ${PT_TMCTPRDPCK.name}.`);
            const updatePromises = countryProductPacksToUpdate.map(pack =>
                UPDATE(PT_TMCTPRDPCK).set(pack).where({ EAN: pack.EAN })
            );
            await Promise.all(updatePromises);
            console.log(`JOB (${this.jobName}): Updating of country product packs in ${PT_TMCTPRDPCK.name} completed.`);
        }

        if (countryProductPacksToInsert.length > 0) {
            console.log(`JOB (${this.jobName}): Inserting ${countryProductPacksToInsert.length} new country product packs in ${PT_TMCTPRDPCK.name}.`);
            await INSERT.into(PT_TMCTPRDPCK).entries(countryProductPacksToInsert);
            console.log(`JOB (${this.jobName}): Insertion of new country product packs in ${PT_TMCTPRDPCK.name} completed.`);
        }
        console.log(`JOB (${this.jobName}): Processing Country Product Pack Data finished.`);
    }

    mapToCountryProductPack(material, productPackId) {
        return {
            COUNTRYCODE: 'ES',
            COUNTRYOFORIGIN: 'NA',
            SHELFLIFE: 1,
            REGISTERED: 2,
            ACTIVERECORD: 'Yes',
            PRODUCTPACKID: productPackId,
            MANUFACTURER: 'NA',
            PRESENTATION_2: 'NA',
            VTATAX: 0,
            COMMENT: 'NA',
            GOV_CODE: 'NA',
            CODE1: 'NA',
            CODE2: 'NA',
            CODE3: 'NA',
            QTY_THRESHOLD: 0,
            BU: material.Division,
            GPP_GOVERNED: null,
            LAP_CURRENCY: null,
            LAP: 0,
            LAP_UNIT: null,
            PRAF_ID: null,
            PRAF_COMMENTS: null,
            REGISTRATIONDATE: null,
            REGISTRATIONVALIDUNTIL: null,
            PRODUCTSCOPE: null,
            PRODUCTGROUP: null,
            OUTSOURCEDSTATUS: null,
            EAN: material.EAN_UPC
        };
    }

    async processSkuProductPackData() {
        console.log(`JOB (${this.jobName}): Processing SKU Product Pack Data started...`);
        const { INTERIM_SPAINMATERIALS, PT_TMSKUPRDPCK, PT_TMPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");

        const interimMaterials = await SELECT.from(INTERIM_SPAINMATERIALS).where({ Status: 'New' });
        if (!interimMaterials || interimMaterials.length === 0) {
            console.log(`JOB (${this.jobName}): No data found in ${INTERIM_SPAINMATERIALS.name}.`);
            return;
        }

        const productPacks = await SELECT.from(PT_TMPRDPCK).columns('PRODUCTPACKID', 'PRODUCTPACKNAME');
        const productPackMap = new Map(productPacks.map(p => [p.PRODUCTPACKNAME, p.PRODUCTPACKID]));

        const existingSkuProductPacks = await SELECT.from(PT_TMSKUPRDPCK).columns('PRODUCTPACKID', 'SKUCODE');
        const existingSkuProductPackKeys = new Set(existingSkuProductPacks.map(p => `${p.PRODUCTPACKID}-${p.SKUCODE}`));

        let maxCountrySkuIdResult = await SELECT.one.from(PT_TMSKUPRDPCK).orderBy({ ref: ['COUNTRYSKUID'], sort: 'desc' });
        let maxCountrySkuId = maxCountrySkuIdResult ? maxCountrySkuIdResult.COUNTRYSKUID : 0;

        const skuProductPacksToUpdate = [];
        const skuProductPacksToInsert = [];

        for (const material of interimMaterials) {
            const productPackId = productPackMap.get(material.CommercialName);
            if (productPackId) {
                const skuProductPackData = this.mapToSkuProductPack(material, productPackId);
                const key = `${productPackId}-${material.MaterialNumber}`;

                if (existingSkuProductPackKeys.has(key)) {
                    skuProductPacksToUpdate.push(skuProductPackData);
                } else {
                    maxCountrySkuId++;
                    skuProductPacksToInsert.push({ ...skuProductPackData, COUNTRYSKUID: maxCountrySkuId });
                    existingSkuProductPackKeys.add(key);
                }
            }
        }

        if (skuProductPacksToUpdate.length > 0) {
            console.log(`JOB (${this.jobName}): Updating ${skuProductPacksToUpdate.length} SKU product packs in ${INTERIM_SPAINMATERIALS.name}.`);
            const updatePromises = skuProductPacksToUpdate.map(pack =>
                UPDATE(PT_TMSKUPRDPCK).set(pack).where({ PRODUCTPACKID: pack.PRODUCTPACKID, SKUCODE: pack.SKUCODE })
            );
            await Promise.all(updatePromises);
            console.log(`JOB (${this.jobName}): Updating of SKU product packs in ${INTERIM_SPAINMATERIALS.name} completed.`);
        }

        if (skuProductPacksToInsert.length > 0) {
            console.log(`JOB (${this.jobName}): Inserting ${skuProductPacksToInsert.length} new SKU product packs in ${INTERIM_SPAINMATERIALS.name}.`);
            await INSERT.into(PT_TMSKUPRDPCK).entries(skuProductPacksToInsert);
            console.log(`JOB (${this.jobName}): Insertion of new SKU product packs in ${PT_TMSKUPRDPCK.name} completed.`);
        }
        console.log(`JOB (${this.jobName}): Processing SKU Product Pack Data finished.`);
    }

    mapToSkuProductPack(material, productPackId) {
        return {
            COUNTRYCODE: 'ES',
            ACTIVERECORD: 'Yes',
            PRODUCTPACKID: productPackId,
            SKUCODE: material.MaterialNumber,
            VALIDFROM: null,
            VALIDTO: null
        };
    }

    formatFieldsFromProductHierarchy(productHierarchyInternalID) {
        const divisions = {
            '08': 'Pharma',
            '16': 'Consumer Health',
            '65': 'Radiology'
        }
        if (!productHierarchyInternalID) {
            return {
                DivisionCode: '',
                Division: '',
                BrandID: ''
            };
        }

        const divisionCode = productHierarchyInternalID.substring(0, 2);
        const brandID = productHierarchyInternalID.substring(7, 10);

        return {
            DivisionCode: divisions[divisionCode],
            Division: division,
            BrandID: brandID
        };
    }
};