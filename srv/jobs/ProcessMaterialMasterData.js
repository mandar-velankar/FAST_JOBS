const BaseJob = require('./BaseJob');

module.exports = class ProcessMaterialMasterData extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
        this.jobName = jobName.toUpperCase();
    }

    // Triggered when job has started
    async onTick() {
        console.log(`JOB (${this.jobName}): Processing Material Master Data started...`);
        try {
            this.db = await cds.connect.to('db');

            // Collect material master data
            await this.collectMaterialMasterData();

            // Process product pack hierarchy (main + country + SKU)
            const { processedIDs, failedIDs } = await this.processProductPackHierarchy();

            // Finalize statuses
            const allFailedSet = new Set(failedIDs);
            const successfulIDs = processedIDs.filter(id => !allFailedSet.has(id));

            if (successfulIDs.length > 0) {
                await this.updateInterimStatusForMaterials(successfulIDs, 'Processed', null);
            }

            console.log(`JOB (${this.jobName}): Finished Material Master Data process. 
                Processed: ${successfulIDs.length}, Failed: ${failedIDs.length}`);
        } catch (error) {
            console.error(`JOB (${this.jobName}): Error processing Material Master Data:`, error);
        }
        console.log(`JOB (${this.jobName}): Processing Material Master Data finished.`);
    }

    async clearFASTCoreMaterial() {
        const { FASTCoreMaterial } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        const { INTERIM_SPAINMATERIALS } = this.db.entities("com.bayer.SXTENDER.MasterData");
        console.log(`JOB (${this.jobName}): Clearing processed materials from ${FASTCoreMaterial.name} table...`);

        const processedMaterials = await SELECT.from(INTERIM_SPAINMATERIALS).columns('MaterialNumber').where({ Status: 'Processed' });
        const processedIDs = processedMaterials.map(m => m.MaterialNumber);

        if (processedIDs.length > 0) {
            await DELETE.from(FASTCoreMaterial).where({ ProductInternalID: { in: processedIDs } });
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

    async processWithStatus(records, processFn, statusField = 'InterimMaterialID', failMsg = 'Processing failed') {
        let failedIds = [];
        for (const record of records) {
            try {
                delete record[statusField];
                await processFn(record);
            } catch (err) {
                failedIds.push(record[statusField]);
                console.error(`${failMsg} for ${statusField} ${record[statusField]}:`, err.message);
            }
        }
        if (failedIds.length > 0) {
            await this.updateInterimStatusForMaterials(failedIds, 'Failed', failMsg);
        }
        return failedIds;
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
        const uniqueMaterialsMap = new Map();
        for (const material of materials) {
            if (!uniqueMaterialsMap.has(material.MaterialNumber)) {
                uniqueMaterialsMap.set(material.MaterialNumber, material);
            }
        }
        const uniqueMaterials = Array.from(uniqueMaterialsMap.values());

        const existingMaterials = await SELECT.from(INTERIM_SPAINMATERIALS).where({Status: 'New'}).columns(['ID', 'MaterialNumber']);
        const existingMaterialMap = new Map(existingMaterials.map(m => [m.MaterialNumber, m.ID]));

        const processedIDs = [];
        const failedIDs = [];

        for (const material of uniqueMaterials) {
            try {
                const mapped = this.mappedMaterialsToInterimTable(material);

                if (existingMaterialMap.has(Number(material.MaterialNumber))) {
                    // Update existing record
                    const existingID = existingMaterialMap.get(Number(material.MaterialNumber));
                    await UPDATE(INTERIM_SPAINMATERIALS)
                        .set(mapped)
                        .where({ ID: existingID });
                    processedIDs.push(existingID);
                } else {
                    // Insert new record
                    const insertResult = await INSERT.into(INTERIM_SPAINMATERIALS).entries(mapped);
                    processedIDs.push(insertResult.ID || material.MaterialNumber);
                }
            } catch (err) {
                failedIDs.push(material.MaterialNumber);
                console.error(`Mapping or upsert failed for MaterialNumber ${material.MaterialNumber}:`, err.message);
            }
        }

        if (failedIDs.length > 0) {
            await this.updateInterimStatusForMaterials(failedIDs, 'Failed', 'Mapping or upsert failed');
        }

        console.log(`JOB (${this.jobName}): Collecting material master data finished. Processed: ${processedIDs.length}, Failed: ${failedIDs.length}`);
    }


    

    async processProductPackHierarchy() {
        console.log(`JOB (${this.jobName}): Processing Product Pack Hierarchy started...`);
        const { INTERIM_SPAINMATERIALS, PT_TMPRDPCK, PT_TMCTPRDPCK, PT_TMSKUPRDPCK } = this.db.entities("com.bayer.SXTENDER.MasterData");

        const interimMaterials = await SELECT.from(INTERIM_SPAINMATERIALS).where({ Status: 'New' });
        if (!interimMaterials || interimMaterials.length === 0) {
            console.log(`JOB (${this.jobName}): No new interim materials to process.`);
            return { processedIDs: [], failedIDs: [] };
        }

        // Load existing entries
        const existingProductPackMap = new Map(
            (await SELECT.from(PT_TMPRDPCK).columns(['PRODUCTPACKID', 'PRODUCTPACKNAME']))
                .map(p => [p.PRODUCTPACKNAME, p.PRODUCTPACKID])
        );
        const existingCountryProductPackMap = new Map(
            (await SELECT.from(PT_TMCTPRDPCK).where({ COUNTRYCODE: 'ES' }).columns(['EAN', 'PRODUCTPACKID']))
                .map(p => [p.EAN, p.PRODUCTPACKID])
        );
        const existingSKUSet = new Set(
            (await SELECT.from(PT_TMSKUPRDPCK).where({ CountryCode: 'ES' }).columns(['PRODUCTPACKID', 'SKUCODE']))
                .map(p => `${p.PRODUCTPACKID}-${p.SKUCODE}`)
        );

        let maxProductPackId = (await SELECT.one.from(PT_TMPRDPCK).columns(['max(PRODUCTPACKID) as maxId']))?.maxId || 0;
        let maxCountryProductPackId = (await SELECT.one.from(PT_TMCTPRDPCK).columns(['max(COUNTRYPRODUCTPACKID) as maxId']))?.maxId || 0;
        let maxSkuId = (await SELECT.one.from(PT_TMSKUPRDPCK).columns(['max(COUNTRYSKUID) as maxId']))?.maxId || 0;

        const processedIDs = [];
        const failedIDs = [];
        let productPackCreated = 0, productPackUpdated = 0;
        let countryProductPackCreated = 0, countryProductPackUpdated = 0;
        let skuCreated = 0, skuUpdated = 0;

        // Transaction wrapper
        await cds.transaction(this.db).run(async tx => {
            for (const material of interimMaterials) {
                try {
                    // --- ProductPack ---
                    let productPackId = existingCountryProductPackMap.get(material.EAN_UPC);
                    if (!productPackId) {
                        maxProductPackId++;
                        productPackId = maxProductPackId;
                        await tx.run(
                            INSERT.into(PT_TMPRDPCK).entries({ ...this.mapToProductPack(material), PRODUCTPACKID: productPackId })
                        );
                        existingProductPackMap.set(material.CommercialName, productPackId);
                        productPackCreated++;
                    } else {
                        await tx.run(
                            UPDATE(PT_TMPRDPCK).set(this.mapToProductPack(material)).where({ PRODUCTPACKID: productPackId })
                        );
                        productPackUpdated++;
                    }

                    // --- CountryProductPack ---
                    let countryProductPackId = existingCountryProductPackMap.get(productPackId);
                    if (!countryProductPackId) {
                        maxCountryProductPackId++;
                        countryProductPackId = maxCountryProductPackId;
                        await tx.run(
                            INSERT.into(PT_TMCTPRDPCK).entries({
                                ...this.mapToCountryProductPack(material),
                                COUNTRYPRODUCTPACKID: countryProductPackId,
                                PRODUCTPACKID: productPackId
                            })
                        );
                        existingCountryProductPackMap.set(productPackId, countryProductPackId);
                        countryProductPackCreated++;
                    } else {
                        await tx.run(
                            UPDATE(PT_TMCTPRDPCK).set(this.mapToCountryProductPack(material))
                            .where({ COUNTRYPRODUCTPACKID: countryProductPackId })
                        );
                        countryProductPackUpdated++;
                    }

                    // --- SKU ProductPack ---
                    const skuKey = `${productPackId}-${material.MaterialNumber}`;
                    if (!existingSKUSet.has(skuKey)) {
                        maxSkuId++;
                        await tx.run(
                            INSERT.into(PT_TMSKUPRDPCK).entries({
                                ...this.mapToSkuProductPack(material, productPackId),
                                COUNTRYSKUID: maxSkuId
                            })
                        );
                        existingSKUSet.add(skuKey);
                        skuCreated++;
                    } else {
                        await tx.run(
                            UPDATE(PT_TMSKUPRDPCK).set(this.mapToSkuProductPack(material, productPackId))
                            .where({ PRODUCTPACKID: productPackId, SKUCODE: material.MaterialNumber })
                        );
                        skuUpdated++;
                    }

                    // Only mark as processed after all operations succeed
                    processedIDs.push(material.ID);

                } catch (err) {
                    failedIDs.push(material.ID);
                    await this.updateInterimStatusForMaterials([material.ID], 'Failed', 'Product Pack processing failed');
                    console.error(`Product Pack processing failed for ID ${material.ID}:`, err.message);
                }
            }
        });

        console.log(`JOB (${this.jobName}): Product Pack Hierarchy finished. 
            ProductPack: Created=${productPackCreated}, Updated=${productPackUpdated}, 
            CountryProductPack: Created=${countryProductPackCreated}, Updated=${countryProductPackUpdated}, 
            SKUProductPack: Created=${skuCreated}, Updated=${skuUpdated}, 
            Failed=${failedIDs.length}`);

        return { processedIDs, failedIDs };
    }





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
            Status: "New"
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

    mapToCountryProductPack(material) {
        return {
            COUNTRYCODE: 'ES',
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
            PRODUCTSCOPE: null,
            PRODUCTGROUP: null,
            OUTSOURCEDSTATUS: null,
            EAN: material.EAN_UPC
        };
    }

    mapToSkuProductPack(material, productPackId) {
        return {
            CountryCode: 'ES',
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
};
