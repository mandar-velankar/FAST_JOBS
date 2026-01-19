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
            this.fastCCMABackend = await cds.connect.to("CONDITION_CONTRACT_API");
            this.countryCode = 'ES'; 
            this.today = new Date().toISOString().split('T')[0];

            // Initialize last IDs from DB
            await this.initializeLastIds();

            // Get product information
            await this.getProductInformation();

            // Collect material master data
            await this.collectMaterialMasterData();

            // Process product pack hierarchy (main + country + SKU)
            const { processedIDs, failedIDs } = await this.processProductPackHierarchy();

            // Finalize statuses
            const allFailedSet = new Set(failedIDs);
            const successfulIDs = processedIDs.filter(id => !allFailedSet.has(id));

            if (successfulIDs.length > 0) {
                await this.updateInterimStatusForMaterials(successfulIDs, 'Processed');
            }

            console.log(`JOB (${this.jobName}): Finished Material Master Data process. 
                Processed: ${successfulIDs.length}, Failed: ${failedIDs.length}`);
        } catch (error) {
            console.error(`JOB (${this.jobName}): Error processing Material Master Data:`, error);
        }
        console.log(`JOB (${this.jobName}): Processing Material Master Data finished.`);
    }

    async getProductInformation() {
        const { PT_TMPRDPCK, PT_TMCTPRDPCK, PT_TMSKUPRDPCK } =
            this.db.entities("com.bayer.SXTENDER.MasterData");

        const [countryProductPacks, productPacks, productSKUs, ccmContracts, ccmmaterials] = await Promise.all([
            SELECT.from(PT_TMCTPRDPCK).columns("*", "ProductPack.PRODUCTPACKNAME").where({ COUNTRYCODE: this.countryCode }),
            SELECT.from(PT_TMPRDPCK),
            SELECT.from(PT_TMSKUPRDPCK).where({ CountryCode: this.countryCode }),
            this.fastCCMABackend.send({
                method: 'GET',
                path: `/odata/v4/condition-contract/CCMContract`,
            }),
            this.fastCCMABackend.send({
                method: 'GET',
                path: `/odata/v4/condition-contract/CCMMaterial`,
            }),
        ]);

        this.countryProductPacks = countryProductPacks;
        this.productPacks = productPacks;
        this.productSKUs = productSKUs;
        this.ccmContracts = ccmContracts || [];
        this.ccmMaterials = ccmmaterials || [];
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

    async clearProcessedFASTCoreMaterials(ids) {
        const { FASTCoreMaterial } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        console.log(`JOB (${this.jobName}): Clearing processed materials from ${FASTCoreMaterial.name} table...`);

        if (ids.length > 0) {
            await DELETE.from(FASTCoreMaterial).where({ ID: { in: ids } });
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
            .where({ Status: 'Pending' })
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
        await this.clearProcessedFASTCoreMaterials(materials.map(m => m.ID));
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
        
        const EAN_UPC_BUFFER = !material.EAN_UPC ? `${this.countryCode}-${material.CommercialName}` : material.EAN_UPC;
        // Check existing records
        
        let existingCountryPack = this.countryProductPacks.find(pr => pr.EAN === EAN_UPC_BUFFER);
        if (!existingCountryPack) existingCountryPack = this.countryProductPacks.find(pr => pr.PRODUCTPACKNAME === material.CommercialName);
        const existingProductPack = existingCountryPack ? this.productPacks.find(pr => pr.PRODUCTPACKID === existingCountryPack.PRODUCTPACKID) : null;
        const existingSKU = existingCountryPack ? this.productSKUs.find(pr => pr.SKUCode === material.MaterialNumber && pr.ProductPackID === existingCountryPack.PRODUCTPACKID) : null;

        //PT_TMPRDPCK
        const productPackId = existingProductPack ? existingProductPack.PRODUCTPACKID : ++this.lastIds.ProductPack;
        const mappedPrdpck = existingProductPack ? this.mapToProductPack(material, existingProductPack, "update") : { ...this.mapToProductPack(material, existingProductPack, "create"), PRODUCTPACKID: productPackId };
        const isPrdpckValid = !existingProductPack ? await this.validateFields(["PRODUCTPACKNAME", "UOM", "HLEVEL6_CODE", "PACKFACTOR"], "PT_TMPRDPCK", failedIDs, mappedPrdpck, material.ID) : true;

        //PT_TMCTPRDPCK
        const countryProductPackId = existingCountryPack ? existingCountryPack.COUNTRYPRODUCTPACKID : ++this.lastIds.CountryProductPack;
        const mappedProductPack = existingCountryPack ? this.mapToCountryProductPack(material, this.countryCode, EAN_UPC_BUFFER, existingCountryPack, "update") : { ...this.mapToCountryProductPack(material, this.countryCode, EAN_UPC_BUFFER, existingCountryPack, "create"), COUNTRYPRODUCTPACKID: countryProductPackId, PRODUCTPACKID: productPackId, EAN: EAN_UPC_BUFFER };
        const isCtPrdpckValid = !existingCountryPack ? await this.validateFields(["EAN"], "PT_TMCTPRDPCK", failedIDs, mappedProductPack, material.ID) : true;

        //PT_TMSKUPRDPCK
        const skuId = existingSKU ? existingSKU.CountrySKUID : ++this.lastIds.SkuProductPack;
        const mappedSKU = existingSKU ? this.mapToSkuProductPack(material, productPackId, this.countryCode) : { ...this.mapToSkuProductPack(material, productPackId, this.countryCode), COUNTRYSKUID: skuId };
        const isSkuPrdpckValid = !existingSKU ? await this.validateFields(["SKUCode"], "PT_TMSKUPRDPCK", failedIDs, mappedSKU, material.ID) : true;


        //CCMContract
        let mappedFASTConditionContracts = [];
        let mappedCCMContracts = [];
        let mappedCCMMaterials = [];

        if (existingProductPack && this.ccmContracts.length > 0 && this.ccmMaterials.length > 0) {
            
            const relatedCCMContracts = this.ccmContracts?.filter(cc => cc.ProductCode == productPackId);
            console.log(`Found ${relatedCCMContracts.length} related CCMContracts for ProductPack ${productPackId}`);

            for (let cc of relatedCCMContracts) {
                const contractRelatedMaterial = this.ccmMaterials.find(ccm => ccm.CCMContract_ID == cc.ID && ccm.ProductCode == productPackId && ccm.MaterialNumber == mappedSKU.SKUCode);

                if (!contractRelatedMaterial) {
                    const { mappedFASTConditionContract, mappedCCMContract, mappedCCMMaterial } = this.mapToCCMContract(cc, mappedSKU.SKUCode, productPackId, this.countryCode);

                    mappedFASTConditionContracts.push(mappedFASTConditionContract);
                    mappedCCMContracts.push(mappedCCMContract);
                    mappedCCMMaterials.push(mappedCCMMaterial);
                }
            }
        }
        

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
            const updateResult = await UPDATE(PT_TMCTPRDPCK).set(mappedProductPack).where({ COUNTRYCODE: this.countryCode, PRODUCTPACKID: existingCountryPack.PRODUCTPACKID});
            if (updateResult === 0) throw new Error('No CountryProductPack updated');
        }

        // SKU ProductPack
        if (!existingSKU) {
            const insertResult = await INSERT.into(PT_TMSKUPRDPCK).entries(mappedSKU);
            if (!insertResult || insertResult.length === 0) throw new Error('Failed to insert SkuProductPack');
        } else {
            const updateResult = await UPDATE(PT_TMSKUPRDPCK).set(mappedSKU).where({ CountryCode: this.countryCode, PRODUCTPACKID: existingSKU.PRODUCTPACKID, SKUCODE: existingSKU.SKUCODE });
            if (updateResult === 0) throw new Error('No SkuProductPack updated');
        }

        if (
            mappedFASTConditionContracts.length > 0 &&
            mappedCCMContracts.length > 0 &&
            mappedCCMMaterials.length > 0
        ) {
            await Promise.all([
                ...mappedFASTConditionContracts.map(fastContract => {
                    return this.fastCCMABackend.send({
                        method: 'PATCH',
                        path: `/odata/v4/condition-contract/FastConditionContracts('${fastContract.ID}')`,
                        data: fastContract
                    });
                }),
                ...mappedCCMContracts.map(contract => {
                    return this.fastCCMABackend.send({
                        method: 'PATCH',
                        path: `/odata/v4/condition-contract/CCMContract('${contract.ID}')`,
                        data: contract
                    });
                }),
                ...mappedCCMMaterials.map(material => {
                    return this.fastCCMABackend.send({
                        method: 'POST',
                        path: `/odata/v4/condition-contract/CCMMaterial`,
                        data: material
                    });
                })
            ]);
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
            CommercialName: material?.CommercialName || material.SAPName || "",
            ProductType: 'Other',
            PackFactor: material.PackFactor || 1,
            Presentation: null,
            Strength: 0,
            UOM: 'NA',
            SalesUnitOfMeasure: material.SalesMeasureUnitCode,
            ProductHierarchy: material.ProductHierarchyInternalID || "",
            DivisionCode: formattedProductHierarchyFields.DivisionCode,
            Division: formattedProductHierarchyFields.Division,
            BrandID: formattedProductHierarchyFields.BrandID,
            MaterialGroup1: material.MaterialGroup1 || "",
            MaterialGroup4: material.MaterialGroup4 || "",
            MaterialGroup5: material.MaterialGroup5 || "",
            ItemCategoryGroup: material.ItemCategoryGroupCode || "",
            MaterialStatus: this.materialStatuses(material.MaterialStatus),
            Status: "Pending",
            FASTCoreMaterialID: material.ID
        };
    }

    mapToProductPack(material, existingProductPack, mode) {
        if (mode === 'create') {
            return {
                PRODUCTPACKNAME: material.CommercialName,
                PRESENTATION: material.Presentation,
                UOM: material.UOM,
                ACTIVERECORD: 'Yes',
                HLEVEL6_CODE: material.ProductHierarchy,
                CONCENTRATION: material.Strength,
                PACKFACTOR: material.PackFactor,
                PCIName: material.CommercialName,
                MoleculeName: 'NA',
                ACTIVE_SUBSTANCE: null,
                ProductType: material.ProductType,
                ProductClass: 'NA',
                ProductDescription: material.CommercialName,
                ProductFullDescription: material.CommercialName,
                Nucleus: 'NA',
                ProductGenericName: material.SAPName,
                Bundle: null,
                OuterCarton: null,
                CalculationFactorIRP: null
            };
        }else {
            const updatedFields = {};
            const fields = {
                PRODUCTPACKNAME: "CommercialName",
                PRESENTATION: "Presentation",
                UOM: "UOM",
                HLEVEL6_CODE: "ProductHierarchy",
                CONCENTRATION: "Strength",
                PACKFACTOR: "PackFactor",
                PCIName: "CommercialName",
                ProductType: "ProductType",
                ProductDescription: "CommercialName",
                ProductFullDescription: "CommercialName",
                ProductGenericName: "SAPName"
            };

            Object.keys(fields).forEach(key => {
                if (material[fields[key]] && material[fields[key]] !== "NA" && material[fields[key]] !== "Other" && existingProductPack[key] != material[fields[key]]) {
                    updatedFields[key] = material[fields[key]];
                }
            });

            return updatedFields;
        }
        
    }

    mapToCountryProductPack(material, countryCode, EAN_UPC_BUFFER, existingCountryPack, mode) {
        if (mode === 'create') {
            return {
                COUNTRYCODE: countryCode,
                COUNTRYOFORIGIN: 'NA',
                SHELFLIFE: 1,
                REGISTERED: 2,
                ACTIVERECORD: 'Yes',
                MANUFACTURER: 'NA',
                Presentation_2: 'NA',
                VTATax: 0,
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
                RegistrationDate: null,
                RegistrationValidUntil: null,
                ProductScope: "All",
                ProductGroup: null,
                OutSourcedStatus: null,
                EAN: EAN_UPC_BUFFER
            };
        } else {
            const updatedFields = {};
            const fields = {
                BU: "Division"
            };

            Object.keys(fields).forEach(key => {
                if (material[fields[key]] && material[fields[key]] !== "NA" && existingCountryPack[key] != material[fields[key]]) {
                    updatedFields[key] = material[fields[key]];
                }
            });

            return updatedFields;
        }
    }

    mapToSkuProductPack(material, productPackId, countryCode) {
        return {
            CountryCode: countryCode,
            ActiveRecord: 'Yes',
            ProductPackID: productPackId,
            SKUCode: material.MaterialNumber
        };
    }

    mapToCCMContract(contract, materialNumber, productPackId, countryCode) {
        if (!contract || !materialNumber || !productPackId) throw new Error('Invalid parameters for mapping to CCMContract');
        const splittedMaterialNumbers = contract.NewMaterialNumber ? contract.NewMaterialNumber.split(",").filter(el => el) : [];
        const newMaterialNumber = splittedMaterialNumbers.includes(`${materialNumber}`) ? splittedMaterialNumbers.join(",").trim() : splittedMaterialNumbers.concat(materialNumber).join(",").trim();

        const mappedFASTConditionContract = {
            ID: contract.FastConditionContracts_ID,
            hasNewMaterialNumber: true
        };
        const mappedCCMContract = {
            ID: contract.ID,
            NewMaterialNumber: newMaterialNumber
        };

        const mappedCCMMaterial = {
            CountryCode: countryCode,
            ProductCode: `${productPackId}`,
            MaterialNumber: `${materialNumber}`,
            ActiveRecord: 1,
            isNewMaterialNumber: true,
            CCMContract_ID: contract.ID,
            validFrom: this.today,
			validTo: "9999-12-31"
        };
        return {
            mappedFASTConditionContract,
            mappedCCMContract,
            mappedCCMMaterial
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
