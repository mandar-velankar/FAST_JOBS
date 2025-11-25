const BaseJob = require('./BaseJob');

module.exports = class ProcessMaterialMasterData extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
        this.jobName = jobName.toUpperCase();

        // Track last IDs to increment properly
        this.lastIds = {
            ProductPack: 0,
            CountryProductPack: 0,
            SkuProductPack: 0
        };
    }

    async onTick() {
        console.log(`JOB (${this.jobName}): Processing Material Master Data started...`);
        try {
            this.db = await cds.connect.to('db');

            // Initialize last IDs from DB
            await this.initializeLastIds();

            // Collect material master data
            await this.collectMaterialMasterData();

            // Process product pack hierarchy (main + country + SKU)
            const { processedIDs, failedIDs } = await this.processProductPackHierarchy();

            // Finalize statuses
            const allFailedSet = new Set(failedIDs);
            const successfulIDs = processedIDs.filter(id => !allFailedSet.has(id));

            if (successfulIDs.length > 0) {
                await this.updateInterimStatusForMaterials(successfulIDs, 'Processed');
                await this.clearFASTCoreMaterial();
            }

            console.log(`JOB (${this.jobName}): Finished Material Master Data process. 
                Processed: ${successfulIDs.length}, Failed: ${failedIDs.length}`);
        } catch (error) {
            console.error(`JOB (${this.jobName}): Error processing Material Master Data:`, error);
        }
        console.log(`JOB (${this.jobName}): Processing Material Master Data finished.`);
    }

    async initializeLastIds() {
        const { PT_TMPRDPCK, PT_TMCTPRDPCK, PT_TMSKUPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");

        const maxProductPack = await SELECT.one.from(PT_TMPRDPCK).columns(['max(PRODUCTPACKID) as maxId']);
        const maxCountryPack = await SELECT.one.from(PT_TMCTPRDPCK).columns(['max(COUNTRYPRODUCTPACKID) as maxId']);
        const maxSkuPack = await SELECT.one.from(PT_TMSKUPRDPCK).columns(['max(COUNTRYSKUID) as maxId']);

        this.lastIds.ProductPack = maxProductPack?.maxId || 0;
        this.lastIds.CountryProductPack = maxCountryPack?.maxId || 0;
        this.lastIds.SkuProductPack = maxSkuPack?.maxId || 0;
    }

    async clearFASTCoreMaterial() {
        const { FASTCoreMaterial } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        const { INTERIM_SPAINMATERIALS } = this.db.entities("com.bayer.SXTENDER.MasterData");
        console.log(`JOB (${this.jobName}): Clearing processed materials from ${FASTCoreMaterial.name} table...`);

        const processedMaterials = await SELECT.from(INTERIM_SPAINMATERIALS).columns('MaterialNumber').where({ Status: 'Processed' });
        const processedMaterialIDs = processedMaterials.map(m => m.FASTCoreMaterialID);

        if (processedMaterialIDs.length > 0) {
            await DELETE.from(FASTCoreMaterial).where({ ID: { in: processedMaterialIDs } });
            console.log(`JOB (${this.jobName}): Processed materials cleared from ${FASTCoreMaterial.name} table.`);
        } else {
            console.log(`JOB (${this.jobName}): No processed materials to clear from ${FASTCoreMaterial.name} table.`);
        }
    }

    async updateInterimStatusForMaterials(ids, status, comment = null) {
        const { INTERIM_SPAINMATERIALS } = this.db.entities("com.bayer.SXTENDER.MasterData");
        if (ids && ids.length > 0) {
            await UPDATE(INTERIM_SPAINMATERIALS)
                .set({ Status: status, Comments: comment })
                .where({ ID: { in: ids } });
        }
    }

    async collectMaterialMasterData() {
        const { FASTCoreMaterialView } = this.db.entities("com.bayer.SXTENDER.MasterDataViews");
        const { INTERIM_SPAINMATERIALS } = this.db.entities("com.bayer.SXTENDER.MasterData");

        console.log(`JOB (${this.jobName}): Collecting material master data...`);
        const materials = await SELECT.from(FASTCoreMaterialView);
        if (!materials || materials.length === 0) {
            console.log(`JOB (${this.jobName}): No material master data found.`);
            return;
        }

        // Deduplicate by MaterialNumber
        const uniqueMaterials = [...new Map(materials.map(m => [m.MaterialNumber, m])).values()];
        const existingMaterials = await SELECT.from(INTERIM_SPAINMATERIALS)
            .where({ Status: 'New' })
            .columns(['ID', 'MaterialNumber']);
        const existingMaterialMap = new Map(existingMaterials.map(m => [m.MaterialNumber, m.ID]));

        const processedIDs = [];
        const failedIDs = [];

        for (const material of uniqueMaterials) {
            try {
                const mapped = this.mappedMaterialsToInterimTable(material);

                if (existingMaterialMap.has(Number(material.MaterialNumber))) {
                    const existingID = existingMaterialMap.get(Number(material.MaterialNumber));
                    const updateResult = await UPDATE(INTERIM_SPAINMATERIALS).set(mapped).where({ ID: existingID });
                    if (updateResult === 0) throw new Error('Update affected 0 rows');
                    processedIDs.push(existingID);
                } else {
                    const insertResult = await INSERT.into(INTERIM_SPAINMATERIALS).entries(mapped);
                    if (!insertResult || insertResult.length === 0) throw new Error('Insert failed');
                    processedIDs.push(material.MaterialNumber);
                }
            } catch (err) {
                failedIDs.push(material.MaterialNumber);
                await this.updateInterimStatusForMaterials([material.MaterialNumber], 'Failed', `Mapping/upsert failed: ${err.message}`);
                console.error(`Mapping/upsert failed for MaterialNumber ${material.MaterialNumber}:`, err.message);
            }
        }

        console.log(`JOB (${this.jobName}): Collecting material master data finished. Processed: ${processedIDs.length}, Failed: ${failedIDs.length}`);
    }

    async processProductPackHierarchy() {
        console.log(`JOB (${this.jobName}): Processing Product Pack Hierarchy started...`);
        const { INTERIM_SPAINMATERIALS, PT_TMPRDPCK, PT_TMCTPRDPCK, PT_TMSKUPRDPCK } =
            this.db.entities("com.bayer.SXTENDER.MasterData");

        const interimMaterials = await SELECT.from(INTERIM_SPAINMATERIALS).where({ Status: 'New' });
        if (!interimMaterials || interimMaterials.length === 0) {
            console.log(`JOB (${this.jobName}): No new interim materials to process.`);
            return { processedIDs: [], failedIDs: [] };
        }

        const processedIDs = [];
        const failedIDs = [];

        for (const material of interimMaterials) {
            try {
                const isProductProcessed = await this.upsertProductPack(material, PT_TMPRDPCK, PT_TMCTPRDPCK, PT_TMSKUPRDPCK, failedIDs);
                if (!isProductProcessed) continue;
                processedIDs.push(material.ID);
                await this.updateInterimStatusForMaterials([material.ID], "Processed");
            } catch (err) {
                failedIDs.push(material.ID);
                await this.updateInterimStatusForMaterials(
                    [material.ID],
                    "Failed",
                    `Product Pack processing failed: ${err.message}`
                );
                console.error(`Product Pack processing failed for ID ${material.ID}:`, err.message);
            }
        }

        console.log(
            `JOB (${this.jobName}): Product Pack Hierarchy finished. Processed: ${processedIDs.length}, Failed: ${failedIDs.length}`
        );
        return { processedIDs, failedIDs };
    }


    async upsertProductPack(material, PT_TMPRDPCK, PT_TMCTPRDPCK, PT_TMSKUPRDPCK, failedIDs) {
        const countryCode = 'ES'; 
        const EAN_UPC_BUFFER = !material.EAN_UPC ? `${countryCode}-${material.CommercialName}` : material.EAN_UPC;
        // Check existing records
        const countryProductPacks = await SELECT.from(PT_TMCTPRDPCK).columns("*", "ProductPack.PRODUCTPACKNAME").where({ COUNTRYCODE: countryCode });
        let existingCountryPack = countryProductPacks.find(pr => pr.EAN === EAN_UPC_BUFFER);
        if (!existingCountryPack) existingCountryPack = countryProductPacks.find(pr => pr.ProductPack_PRODUCTPACKNAME === material.CommercialName);
        const existingProductPack = existingCountryPack ? await SELECT.one.from(PT_TMPRDPCK).where({ PRODUCTPACKID: existingCountryPack.PRODUCTPACKID }) : null;
        const existingSKU = existingCountryPack ? await SELECT.one.from(PT_TMSKUPRDPCK).where({ ProductPackID: existingCountryPack.PRODUCTPACKID, SKUCode: material.MaterialNumber, CountryCode: 'ES' }) : null;

        //mapping of records

        //PT_TMPRDPCK
        const productPackId = existingProductPack ? existingProductPack.PRODUCTPACKID : ++this.lastIds.ProductPack;
        const mappedPrdpck = existingProductPack ? this.mapToProductPack(material) : { ...this.mapToProductPack(material), PRODUCTPACKID: productPackId };
        const isPrdpckValid = await this.validateFields(["PRODUCTPACKNAME", "UOM", "HLEVEL6_CODE", "PACKFACTOR"], "PT_TMPRDPCK", failedIDs, mappedPrdpck, material.ID);

        //PT_TMCTPRDPCK
        const countryProductPackId = existingCountryPack ? existingCountryPack.COUNTRYPRODUCTPACKID : ++this.lastIds.CountryProductPack;
        const mappedProductPack = existingCountryPack ? this.mapToCountryProductPack(material, countryCode, EAN_UPC_BUFFER) : { ...this.mapToCountryProductPack(material, countryCode), COUNTRYPRODUCTPACKID: countryProductPackId, PRODUCTPACKID: productPackId, EAN: EAN_UPC_BUFFER };
        const isCtPrdpckValid = await this.validateFields(["EAN"], "PT_TMCTPRDPCK", failedIDs, mappedProductPack, material.ID);

        //PT_TMSKUPRDPCK
        const skuId = existingSKU ? existingSKU.SKUCode : ++this.lastIds.SkuProductPack;
        const mappedSKU = existingSKU ? this.mapToSkuProductPack(material, productPackId, countryCode) : { ...this.mapToSkuProductPack(material, productPackId, countryCode), COUNTRYSKUID: skuId };
        const isSkuPrdpckValid = await this.validateFields(["SKUCode"], "PT_TMSKUPRDPCK", failedIDs, mappedSKU, material.ID);
        
        if (!isPrdpckValid || !isCtPrdpckValid || !isSkuPrdpckValid) return false;

        // ProductPack
        
        if (!existingProductPack) {
            const insertResult = await INSERT.into(PT_TMPRDPCK).entries(mappedPrdpck);
            if (!insertResult || insertResult.length === 0) throw new Error('Failed to insert ProductPack');
        } else {
            const updateResult = await UPDATE(PT_TMPRDPCK).set(mappedPrdpck).where({ PRODUCTPACKID: productPackId });
            if (updateResult === 0) throw new Error('No ProductPack updated');
        }

        // CountryProductPack
        if (!existingCountryPack) {
            const insertResult = await INSERT.into(PT_TMCTPRDPCK).entries(mappedProductPack);
            if (!insertResult || insertResult.length === 0) throw new Error('Failed to insert CountryProductPack');
        } else {
            const updateResult = await UPDATE(PT_TMCTPRDPCK).set(mappedProductPack).where({ COUNTRYCODE: countryCode, PRODUCTPACKID: existingCountryPack.PRODUCTPACKID});
            if (updateResult === 0) throw new Error('No CountryProductPack updated');
        }

        // SKU ProductPack
        if (!existingSKU) {
            const insertResult = await INSERT.into(PT_TMSKUPRDPCK).entries(mappedSKU);
            if (!insertResult || insertResult.length === 0) throw new Error('Failed to insert SkuProductPack');
        } else {
            const updateResult = await UPDATE(PT_TMSKUPRDPCK).set(mappedSKU).where({ PRODUCTPACKID: existingSKU.PRODUCTPACKID, SKUCODE: existingSKU.SKUCODE });
            if (updateResult === 0) throw new Error('No SkuProductPack updated');
        }
        return true;
    }

    // ---------- Mapping helpers ----------

    mappedMaterialsToInterimTable(material) {
        const formattedProductHierarchyFields = this.formatFieldsFromProductHierarchy(material.ProductHierarchyInternalID);

        return {
            EAN_UPC: material.EAN_UPC,
            MaterialNumber: material.MaterialNumber,
            SAPName: material.SAPName || "",
            CommercialName: material?.CommercialName || "",
            ProductType: 'Other',
            PackFactor: material.PackFactor,
            Presentation: null,
            Strength: 0,
            UOM: 'NA',
            SalesUnitOfMeasure: material.SalesMeasureUnitCode,
            ProductHierarchy: material.ProductHierarchyInternalID || "",
            DivisionCode: formattedProductHierarchyFields.DivisionCode,
            Division: formattedProductHierarchyFields.Division,
            BrandID: formattedProductHierarchyFields.BrandID,
            MaterialGroup1: material.FirstSalesSpecificationProductGroupCode || "",
            MaterialGroup4: material.FourthSalesSpecificationProductGroupCode || "",
            MaterialGroup5: material.FifthSalesSpecificationProductGroupCode || "",
            ItemCategoryGroup: material.ItemCategoryGroupCode || "",
            MaterialStatus: this.materialStatuses(material.MaterialStatus),
            Status: "New",
            FASTCoreMaterialID: material.ID
        };
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
            NUCLEUS: 'NA',
            PRODUCTGENERICNAME: material.SAPName,
            BUNDLE: null,
            OUTERCARTON: null,
            CALCULATIONFACTORIRP: null
        };
    }

    mapToCountryProductPack(material, countryCode) {
        return {
            COUNTRYCODE: countryCode,
            COUNTRYOFORIGIN: 'NA',
            SHELFLIFE: 1,
            REGISTERED: 2,
            ACTIVERECORD: 'Yes',
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
            PRODUCTSCOPE: "All",
            PRODUCTGROUP: null,
            OUTSOURCEDSTATUS: null
        };
    }

    mapToSkuProductPack(material, productPackId, countryCode) {
        return {
            CountryCode: countryCode,
            ActiveRecord: 'Yes',
            ProductPackID: productPackId,
            SKUCode: material.MaterialNumber
        };
    }

    formatFieldsFromProductHierarchy(productHierarchyInternalID) {
        const divisions = { '08': 'Pharma', '16': 'Consumer Health', '65': 'Radiology' };
        if (!productHierarchyInternalID) return { DivisionCode: '', Division: '', BrandID: '' };

        const divisionCode = productHierarchyInternalID.substring(0, 2);
        const brandID = productHierarchyInternalID.substring(0, 10);

        return { DivisionCode: divisionCode, Division: divisions[divisionCode], BrandID: brandID };
    }

    materialStatuses(statusCode) {
        const statuses = { '2': 'Inactive', '3': 'Active', '4': 'Active', '7': 'Inactive', '8': 'Inactive', '9': 'Active' };
        return statuses[statusCode] || "";
    }

    async validateFields(requiredFields, tableName, failedIDs, materialPayload, materialID) {
        if (Array.isArray(requiredFields) && requiredFields.length === 0) return true;
        const missing = requiredFields.filter(rf => {
            const currentField = materialPayload[rf];
            return currentField === null || currentField === undefined || (typeof currentField === 'string' && currentField.trim() === '');
        });

        if (missing.length > 0) {
            const msg = `Missing required ${tableName} fields: ${missing.join(', ')}`;
            // mark failed and continue with next record
            failedIDs.push(materialID);
            await this.updateInterimStatusForMaterials(
                [materialID],
                "Failed",
                `${tableName} processing failed: ${msg}`
            )
            return false;
        }

        return true;
    }
};
