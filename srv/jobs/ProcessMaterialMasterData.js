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
        }
        console.log(`JOB (${this.jobName}): Processing Material Master Data finished.`);
    }

    async processMaterialMasterData() {
        await this.collectMaterialMasterData();

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
            m.PrdDesc(pd => {
                pd.Description
            }),
            m.SalesSpec(ss => {
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
        const descriptionParts = [];
        // Collect unique descriptions from the PrdDesc association.
        if (material.PrdDesc && material.PrdDesc.length > 0) {
            const descriptions = new Set(material.PrdDesc.map(d => d.Description));
            descriptionParts.push(...descriptions);
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
                descriptionParts.push(salesSpecText);
            }
        }

        return {
            EAN_UPC: null,
            MaterialNumber: material.ProductInternalID,
            SAPName: material.PrdDesc[0]?.Description || '',
            CommercialName: material.PrdDesc[0]?.SalesSpecTxtSAPScrptLn || '',
            ProductType: null,
            PackFactor: null,
            Presentation: null,
            Strength: null,
            UOM: null,
            SalesUnitOfMeasure: material.PrdDesc[0]?.SalesMeasureUnitCode,
            ProductHierarchy: material.PrdDesc[8]?.Description || '',
            DivisionCode: material.DivisionCode || '',
            Division: material.Division || '',
            BrandID: material.BrandID || '',
            MaterialGroup1: material.MaterialGroup1 || '',
            MaterialGroup4: material.MaterialGroup4 || '',
            MaterialGroup5: material.MaterialGroup5 || '',
            ItemCategoryGroup: material.ItemCategoryGroup || '',
            MaterialStatus: material.MaterialStatus || '',
            Status: material.Status || '',
            Comments: material.Comments || ''
        };
    }
};
