const BaseJob = require('./BaseJob');

module.exports = class ProcessCustomerMasterData extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
        this.jobName = jobName.toUpperCase();

        // Track last IDs to increment properly
        this.lastIds = {
            InstituteID: 0
        };
    }

    /**
     * Triggered when job has started
     */
    //override
    async onTick() {
        console.log(`JOB (${this.jobName}): Processing Customer Master Data started...`);
        try {
            this.db = await cds.connect.to('db');

            // Initialize last IDs from DB
            await this.initializeLastIds();

            // Collect customer master data into interim table
            await this.collectCustomerMasterData();

            // Process interim customers: Regions, Provinces, Institutes per record
            const { processedIDs, failedIDs } = await this.processInterimCustomers();

            // Finalize statuses
            const allFailedSet = new Set(failedIDs);
            const successfulIDs = processedIDs.filter(id => !allFailedSet.has(id));

            if (successfulIDs.length > 0) {
                await this.updateInterimStatusForCustomers(successfulIDs, 'Processed');
            }

            console.log(`JOB (${this.jobName}): Finished Customer Master Data process. Processed: ${successfulIDs.length}, Failed: ${failedIDs.length}`);
        } catch (error) {
            console.error(`JOB (${this.jobName}): Error processing Customer Master Data:`, error);
        }
        console.log(`JOB (${this.jobName}): Processing Customer Master Data finished.`);
    }

    async initializeLastIds() {
        const { PT_TMINST } = this.db.entities("com.bayer.SXTENDER.MasterData");

        const maxInstituteID = await SELECT.one.from(PT_TMINST).columns(['max(InstituteID) as maxId']);

        this.lastIds.InstituteID = maxInstituteID?.maxId || 0;
    }

    async updateInterimStatusForCustomers(ids, status, comment = null) {
        const { INTERIM_SPAINCUSTOMERS } = this.db.entities("com.bayer.SXTENDER.MasterData");
        if (ids && ids.length > 0) {
            await UPDATE(INTERIM_SPAINCUSTOMERS)
                .set({ Status: status, Comments: comment })
                .where({ ID: { in: ids } });
        }
    }

    async clearProcessedFASTCoreCustomerMaster(ids) {
        const { FASTCoreCustomerMaster } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        console.log(`JOB (${this.jobName}): Clearing processed customers from ${FASTCoreCustomerMaster.name} table...`);
        if (ids.length > 0) {
            await DELETE.from(FASTCoreCustomerMaster).where({ ID: { in: ids } });
            console.log(`JOB (${this.jobName}): Processed customers cleared from ${FASTCoreCustomerMaster.name} table.`);
        } else {
            console.log(`JOB (${this.jobName}): No processed customers to clear from ${FASTCoreCustomerMaster.name} table.`);
        }
    }

    // Collect customer master data from MasterDataViews.FASTCoreCustomersView and store in INTERIM_SPAINCUSTOMERS
    async collectCustomerMasterData() {
        const { FASTCoreCustomersView } = this.db.entities("com.bayer.SXTENDER.MasterDataViews");
        const { INTERIM_SPAINCUSTOMERS } = this.db.entities("com.bayer.SXTENDER.MasterData");

        console.log(`JOB (${this.jobName}): Collecting customer master data...`);
        const customers = await SELECT.from(FASTCoreCustomersView);
        if (!customers || customers.length === 0) {
            console.log(`JOB (${this.jobName}): No customer master data found.`);
            return;
        }

        // Deduplicate by InternalID / CustomerID (single dedupe)
        const uniqueCustomers = [...new Map(customers.map(c => [Number(c.InternalID || c.CustomerID), c])).values()];

        // Get existing CustomerIDs in interim table (only New status)
        const existingInterim = await SELECT.from(INTERIM_SPAINCUSTOMERS)
            .where({ Status: 'New' })
            .columns(['ID', 'CustomerID']);
        const existingCustomerMap = new Map(existingInterim.map(r => [r.CustomerID, r.ID]));

        const processedIDs = [];
        const failedIDs = [];

        for (const customer of uniqueCustomers) {
            try {
                const mapped = this.mappedCustomersToInterimTable(customer);

                if (existingCustomerMap.has(mapped.CustomerID)) {
                    const existingID = existingCustomerMap.get(mapped.CustomerID);
                    const updateResult = await UPDATE(INTERIM_SPAINCUSTOMERS).set(mapped).where({ ID: existingID });
                    if (updateResult === 0) throw new Error('Update affected 0 rows');
                    processedIDs.push(existingID);
                } else {
                    const insertResult = await INSERT.into(INTERIM_SPAINCUSTOMERS).entries(mapped);
                    if (!insertResult || insertResult.results.length === 0) throw new Error('Insert failed');
                    processedIDs.push(mapped.CustomerID);
                }
            } catch (err) {
                const id = customer.InternalID || customer.CustomerID || null;
                failedIDs.push(id);
                await this.updateInterimStatusForCustomers([id], 'Failed', `Mapping/upsert failed: ${err.message}`);
                console.error(`JOB (${this.jobName}): Mapping/upsert failed for CustomerID ${id}:`, err.message || err);
            }
        }
        await this.clearProcessedFASTCoreCustomerMaster(customers.map(c => c.ID));
        console.log(`JOB (${this.jobName}): Collecting customer master data finished. Processed: ${processedIDs.length}, Failed: ${failedIDs.length}`);
    }

    // Iterate interim customers (Status = 'New') and for each ensure Region/Province/Institute exist using the interim CountryCode
    async processInterimCustomers() {
        const { INTERIM_SPAINCUSTOMERS, CountryRegions, CountryProvinces, PT_TMINST } = this.db.entities("com.bayer.SXTENDER.MasterData");
        console.log(`JOB (${this.jobName}): Processing buffer ${INTERIM_SPAINCUSTOMERS.name} started...`);

        const interimCustomers = await SELECT.from(INTERIM_SPAINCUSTOMERS).where({ Status: 'New' });
        if (!interimCustomers || interimCustomers.length === 0) {
            console.log(`JOB (${this.jobName}): No new records in ${INTERIM_SPAINCUSTOMERS.name} to process.`);
            return { processedIDs: [], failedIDs: [] };
        }

        const processedIDs = [];
        const failedIDs = [];

        for (const customer of interimCustomers) {
            // Basic validation
            if (!customer.CustomerID) {
                console.error(`JOB (${this.jobName}): Record ${customer.ID} in ${INTERIM_SPAINCUSTOMERS.name} missing CustomerID`);
                failedIDs.push(customer.ID);
                await this.updateInterimStatusForCustomers([customer.ID], 'Failed', 'Missing CustomerID');
                continue;
            }

            // determine country from interim record
            const country = customer.CountryCode;
            if (!country) {
                console.error(`JOB (${this.jobName}): Record ${customer.ID} in ${INTERIM_SPAINCUSTOMERS.name} missing CountryCode`);
                failedIDs.push(customer.ID);
                await this.updateInterimStatusForCustomers([customer.ID], 'Failed', 'Missing CountryCode');
                continue;
            }

            try {
                // --- Country Region upsert ---
                let regionRecord = null;
                if (customer.Region) {
                    regionRecord = await SELECT.one.from(CountryRegions).where({ CountryCode: country, RegionCode: customer.Region });
                    if (!regionRecord) {
                        const insertRegion = await INSERT.into(CountryRegions).entries({ CountryCode: country, Name: customer.Region, RegionCode: customer.Region });
                        if (!insertRegion) throw new Error('Failed to insert CountryRegion');
                        regionRecord = await SELECT.one.from(CountryRegions).where({ CountryCode: country, RegionCode: customer.Region });
                    }
                }

                // --- Country Province upsert ---
                let provinceRecord = null;
                if (customer.Province) {
                    provinceRecord = await SELECT.one.from(CountryProvinces).where({ CountryCode: country, RegionID: customer.Province });
                }

                // --- Institute upsert ---
                const existingInstitute = await SELECT.one.from(PT_TMINST).where({ CountryCode: country, CustomerID: customer.CustomerID });
                const institutePayload = this.mapToInstitute(customer, regionRecord ? regionRecord.ID : null, provinceRecord ? provinceRecord.ID : null);

                // Ensure InstituteID is present for validation (set for update or assign new id for insert)
                if (existingInstitute) {
                    institutePayload.InstituteID = existingInstitute.InstituteID;
                } else {
                    institutePayload.InstituteID = ++this.lastIds.InstituteID;
                }
                institutePayload.CountryCode = country;

                // Validate mandatory fields
                const requiredFields = ['CountryCode','InstituteID','CustomerID','InstituteName','InstituteType','RegionID','ProvinceID','CG1_Description','CG2_Description','CG1_Code','CG2_Code'];
                const missing = requiredFields.filter(rf => {
                    const currentField = institutePayload[rf];
                    return currentField === null || currentField === undefined || (typeof currentField === 'string' && currentField.trim() === '');
                });

                if (missing.length > 0) {
                    const msg = `Missing required institute fields: ${missing.join(', ')}`;
                    // mark failed and continue with next record
                    failedIDs.push(customer.ID);
                    await this.updateInterimStatusForCustomers([customer.ID], 'Failed', msg);
                    console.error(`JOB (${this.jobName}): ${msg} for record ${customer.ID} in ${INTERIM_SPAINCUSTOMERS.name}`);
                    continue;
                }

                if (!existingInstitute) {
                    // insert
                    const insertResult = await INSERT.into(PT_TMINST).entries(institutePayload);
                    if (!insertResult || insertResult.length === 0) throw new Error('Failed to insert Institute');
                } else {
                    // update
                    const updatePayload = Object.assign({}, institutePayload);
                    delete updatePayload.InstituteID;
                    const updateResult = await UPDATE(PT_TMINST).set(updatePayload).where({ InstituteID: existingInstitute.InstituteID });
                    if (updateResult === 0) throw new Error('No Institute updated');
                }

                // success for this buffer record: mark processed
                processedIDs.push(customer.ID);
                await this.updateInterimStatusForCustomers([customer.ID], 'Processed');
            } catch (err) {
                // per-record failure should not stop job
                failedIDs.push(customer.ID);
                await this.updateInterimStatusForCustomers([customer.ID], 'Failed', `Processing failed: ${err.message || err}`);
                console.error(`JOB (${this.jobName}): Processing failed for record ${customer.ID} in ${INTERIM_SPAINCUSTOMERS.name}:`, err.message || err);
            }
        }

        console.log(`JOB (${this.jobName}): Processing buffer ${INTERIM_SPAINCUSTOMERS.name} finished. Processed: ${processedIDs.length}, Failed: ${failedIDs.length}`);
        return { processedIDs, failedIDs };
    }

    mapToInstitute(customer, regionId, provinceId) {
        return {
            CountryCode: customer.CountryCode || null,
            CustomerID: Number(customer.CustomerID),
            InstituteName: customer.CustomerName || '',
            InstituteType: customer.FastInstituteType || null,
            Address: customer.Address || '',
            ContactNo: null,
            Fax: null,
            ContactPerson: null,
            ActiveRecord: 'Yes',
            Comment: null,
            City: null,
            INSTITUTE_HIERARCHY_ID: null,
            State: null,
            MercadoPublicoIssuer: null,
            RegionID: regionId || null,
            ProvinceID: provinceId || null,
            CifCode: 'NA',
            RegionalHealthSystem: 'NA',
            VatCode: 'NA',
            TaxCode: customer.Taxcode || null,
            CustomerGroup: customer.CG1_Code || null,
            ApplicableTaxRate: null,
            INCOTerms: null,
            PaymentTerms: customer.PaymentTerm || null,
            ForAllBrands: true,
            DirectTender: true,
            ContactEmail: null,
            CNPJ: null,
            Shortname: null,
            KAM_Territory: null,
            External_InstituteId: null,
            Class: null,
            SAPGroupId: null,
            CG1_Description: customer.CG1_Description || null,
            CG2_Description: customer.CG2_Description || null,
            CG1_Code: customer.CG1_Code || null,
            CG2_Code: customer.CG2_Code || null
        };
    }

    mappedCustomersToInterimTable(customer) {
        return {
            CustomerID: customer.InternalID,
            CustomerName: customer.FirstLineName || "",
            CG1_Code: customer.CG1_Code || "",
            CG1_Description: customer.CG1_Description || "",
            CG2_Code: customer.CG2_Code || "",
            CG2_Description: customer.CG2_Description || "",
            CustomerType: customer.FastInstituteType || "",
            Address: customer.Address || "",
            Region: customer.RegionCode || "",
            Province: customer.RegionCode || "",
            Taxcode: customer.CashDiscountTermsCode || "",
            PaymentTerm: customer.CreditMemosPaymentTermsCode || "",
            CountryCode: customer.CountryCode || "",
            Status: "New"
        };
    }
};
