const BaseJob = require('./BaseJob');

module.exports = class ProcessCustomerMasterData extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
        this.jobName = jobName.toUpperCase();
    }

    /**
    * Triggered when job has started
    */
    //override
    async onTick() {
        console.log(`JOB (${this.jobName}): Processing Customer Master Data started...`);
        try {
            this.db = await cds.connect.to('db');
            // Call the method to process Customer Master Data
            await this.processCustomerMasterData();
        } catch (error) {
            console.error(`JOB (${this.jobName}): Error processing Customer Master Data:`, error);
            // await this.updateInterimStatus('Failed', error.message);
        }
        console.log(`JOB (${this.jobName}): Processing Customer Master Data finished.`);
    }

    async processCustomerMasterData() {
        await this.collectCustomerMasterData();
        await this.processCountryRegions();
        await this.processCountryProvinces();
        await this.processInstituteData();
        await this.clearFASTCoreCustomerMaster();
    }

    async clearFASTCoreCustomerMaster() {
        const { FASTCoreCustomerMaster } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        const { INTERIM_SPAINCUSTOMERS } = this.db.entities("com.bayer.SXTENDER.MasterData");
        console.log(`JOB (${this.jobName}): Clearing processed customers from ${FASTCoreCustomerMaster.name} table...`);
        // Get processed CustomerIDs from interim table
        const processedCustomers = await SELECT.from(INTERIM_SPAINCUSTOMERS).columns('CustomerID').where({ Status: 'Processed' });
        const processedIDs = processedCustomers.map(c => c.CustomerID);
        if (processedIDs.length > 0) {
            await DELETE.from(FASTCoreCustomerMaster).where({ InternalID: { in: processedIDs } });
            console.log(`JOB (${this.jobName}): Processed customers cleared from ${FASTCoreCustomerMaster.name} table.`);
        } else {
            console.log(`JOB (${this.jobName}): No processed customers to clear from ${FASTCoreCustomerMaster.name} table.`);
        }
    }

    async updateInterimStatus(status, comment = null) {
        const { INTERIM_SPAINCUSTOMERS } = this.db.entities("com.bayer.SXTENDER.MasterData");
        await UPDATE(INTERIM_SPAINCUSTOMERS).set({ Status: status, Comments: comment }).where({ Status: 'New' });
    }

    async updateInterimStatusForCustomers(ids, status, comment = null) {
        const { INTERIM_SPAINCUSTOMERS } = this.db.entities("com.bayer.SXTENDER.MasterData");
        if (ids && ids.length > 0) {
            await UPDATE(INTERIM_SPAINCUSTOMERS)
                .set({ Status: status, Comments: comment })
                .where({ ID: { in: ids } });
        }
    }

    async processWithStatus(records, processFn, statusField = 'CustomerID', failMsg = 'Processing failed') {
        let failedIds = [];
        for (const record of records) {
            try {
                await processFn(record);
            } catch (err) {
                failedIds.push(record[statusField]);
                console.error(`${failMsg} for ${statusField} ${record[statusField]}:`, err.message);
            }
        }
        if (failedIds.length > 0) {
            await this.updateInterimStatusForCustomers(failedIds, 'Failed', failMsg);
        }
    }

    async collectCustomerMasterData() {
        const { FASTCoreCustomerMaster } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        const { INTERIM_SPAINCUSTOMERS } = this.db.entities("com.bayer.SXTENDER.MasterData");

        // Logic to collect customer master data
        console.log(`JOB (${this.jobName}): Collecting customer master data...`);
        const customers = await SELECT.from(FASTCoreCustomerMaster).columns(c => {
            c.InternalID,
            c.CommonInfo(ci => {
                ci.CustOrgnstn(co => {
                    co.CustName(cn => {
                        cn.FirstLineName
                    })
                })
            }),
            c.CustData(cd => {
                cd.CustAcctInfo(cai => {
                    cai.CashDiscountTermsCode,
                    cai.CreditMemosPaymentTermsCode
                }),
                cd.CustSalesArrgmnt(csa => {
                    csa.CustomerDefinedGroupCode,
                    csa.FirstAdditionalCustomerDefinedGroupCode
                })
            }),
            c.AddrnfoData(ad => {
                ad.Addr(addr => {
                    addr.PostalAddr(pa => {
                        pa.RegionCode,
                        pa.StreetName,
                        pa.HouseID,
                        pa.CityName,
                        pa.CountryCode,
                        pa.StreetPostalCode
                    })
                })
            })
        });

        // Filter for Spain records only
        const spainCustomers = customers.filter(customer => {
            const custData = customer.AddrnfoData?.[0]?.Addr?.[0]?.PostalAddr?.[0];
            return custData?.CountryCode === 'ES';
        });

        if (!spainCustomers || spainCustomers.length === 0) {
            console.log(`JOB (${this.jobName}): No Spain customer master data found.`);
            return;
        }

        // Get existing CustomerIDs in interim table
        const existingInterim = await SELECT.from(INTERIM_SPAINCUSTOMERS).columns('CustomerID');
        const existingCustomerIDs = new Set(existingInterim.map(r => r.CustomerID));

        // Only insert records that do not already exist
        let mappedCustomers = [];
        let failedCustomerIds = [];
        for (const customer of spainCustomers) {
            if (existingCustomerIDs.has(customer.InternalID)) continue;
            try {
                mappedCustomers.push(this.mappedCustomersToInterimTable(customer));
            } catch (err) {
                failedCustomerIds.push(customer.InternalID);
                console.error(`Mapping failed for CustomerID ${customer.InternalID}:`, err.message);
            }
        }
        // Deduplicate mappedCustomers by CustomerID
        const uniqueCustomersMap = new Map();
        for (const cust of mappedCustomers) {
            if (!uniqueCustomersMap.has(cust.CustomerID)) {
                uniqueCustomersMap.set(cust.CustomerID, cust);
            }
        }
        const uniqueMappedCustomers = Array.from(uniqueCustomersMap.values());
        console.log(`JOB (${this.jobName}): Mapping of Spain customer master data completed.`);
        if (!uniqueMappedCustomers || uniqueMappedCustomers.length === 0) {
            console.log(`JOB (${this.jobName}): No mapped Spain customer master data to save.`);
            if (failedCustomerIds.length > 0) {
                await this.updateInterimStatusForCustomers(failedCustomerIds, 'Failed', 'Mapping failed');
            }
            return;
        }
        try {
            console.log(`JOB (${this.jobName}): Saving Spain customer master data to the ${INTERIM_SPAINCUSTOMERS.name} table.`);
            await INSERT.into(INTERIM_SPAINCUSTOMERS).entries(uniqueMappedCustomers);
            console.log(`JOB (${this.jobName}): Saving of Spain customer master data completed.`);
        } catch (err) {
            const failedIds = uniqueMappedCustomers.map(c => c.CustomerID);
            await this.updateInterimStatusForCustomers(failedIds, 'Failed', 'Insert failed');
            console.error(`Insert failed for CustomerIDs ${failedIds.join(', ')}:`, err.message);
        }
    }

    /**
     * Returns the description for a given CG1 or CG2 code using the mapping table from the screenshot.
     */
    getCustomerGroupDescription(code) {
        const descriptionMap = {
            'H': 'Private Health Systems',
            'P': 'Public Health System',
            'B': 'Bayer affiliates/group',
            'A': 'Pharmacy',
            'C': 'End user',
            'R': 'Retailer/Dealer',
            'W': 'Wholesaler/Distributor',
            'D': 'Distributor (HealthCare ONLY)',
            'E': 'Enabling Partner',
            'X': 'Health Care Professional'
        };
        return descriptionMap[code] || code || '';
    }

    getCustomerSubGroupDescription(code) {
        const subDescriptionMap = {
            'H04': 'Priv. Clinic',
            'H01': 'Priv. Hospital',
            'H03': 'Priv. Hosp. w Gov. Sub.',
            'P01': 'Public Hospital',
            'B04': 'Bayer Employee',
            'A04': 'Pmcy-Specialties',
            'C01': 'Patient of healthcar',
            'A01': 'Pmcy-National/Chain',
            'R03': 'R/D-eCommerce',
            'R04': 'R/D-Parapharmacy',
            'A03': 'Pmcy-Local/Independent',
            'R02': 'R/D-Grocery',
            'W04': 'Whol./Dist.eCommerce',
            'W01': 'Whol./Dist.National',
            'D04': 'Distributor-Specialties(HealthCare ONLY)',
            'E08': 'Industry',
            'E09': 'OEM',
            'E99': 'Ad-hoc/Short-term part.',
            'B01': 'Bayer Internal',
            'W03': 'Whol./Dist.Local',
            'X01': 'Physician',
            'D03': 'Distributor-Local(HealthCare ONLY)',
            'B03': 'Bayer Sales Representative'
        };
        return subDescriptionMap[code] || code || '';
    }

    mappedCustomersToInterimTable(customer) {
        const custSalesArrgmnt = customer.CustData?.[0]?.CustSalesArrgmnt?.[0];
        const postalAddr = customer.AddrnfoData?.[0]?.Addr?.[0]?.PostalAddr?.[0];

        const addressParts = [
            postalAddr?.HouseID,
            postalAddr?.StreetName,
            postalAddr?.CityName,
            postalAddr?.RegionCode,
        ].filter(part => part).join(', ');

        const CG1_Code = custSalesArrgmnt?.CustomerDefinedGroupCode || "";
        const CG2_Code = custSalesArrgmnt?.FirstAdditionalCustomerDefinedGroupCode || "";

        return {
            CustomerID: customer.InternalID,
            CustomerName: customer.CommonInfo?.[0]?.CustOrgnstn?.[0]?.FirstLineName || "",
            CG1_Code,
            CG1_Description: this.getCustomerGroupDescription(CG1_Code?.charAt(0)),
            CG2_Code,
            CG2_Description: this.getCustomerSubGroupDescription(CG2_Code),
            CustomerType: CG1_Code, // Still using code for type, as before
            Address: addressParts,
            Region: postalAddr?.RegionCode || "",
            Province: postalAddr?.RegionCode || "", // As per mapping, Province is same as Region
            Taxcode: customer.CustData?.[0]?.CustAcctInfo?.[0]?.CashDiscountTermsCode || "",
            PaymentTerm: customer.CustData?.[0]?.CustAcctInfo?.[0]?.CreditMemosPaymentTermsCode || "",
            Status: "New"
        };
    }

    async processCountryRegions() {
        console.log(`JOB (${this.jobName}): Processing Country Regions started...`);
        const { INTERIM_SPAINCUSTOMERS, CountryRegions } = this.db.entities("com.bayer.SXTENDER.MasterData");

        const interimCustomers = await SELECT.distinct.from(INTERIM_SPAINCUSTOMERS).columns('Region', 'CustomerID').where({ Status: 'New' });
        if (!interimCustomers || interimCustomers.length === 0) {
            console.log(`JOB (${this.jobName}): No new customers to process for regions.`);
            return;
        }

        const existingRegions = await SELECT.from(CountryRegions).columns('RegionCode').where({ CountryCode: 'ES' });
        const existingRegionCodes = new Set(existingRegions.map(r => r.RegionCode));

        const newRegions = [];
        for (const customer of interimCustomers) {
            if (customer.Region && !existingRegionCodes.has(customer.Region)) {
                newRegions.push({
                    CountryCode: 'ES',
                    Name: customer.Region,
                    RegionCode: customer.Region
                });
                existingRegionCodes.add(customer.Region); // Avoid duplicates in the same run
            }
        }

        await this.processWithStatus(newRegions, async (region) => {
            await INSERT.into(CountryRegions).entries(region);
        }, 'RegionCode', 'Region insert failed');
        console.log(`JOB (${this.jobName}): Processing Country Regions finished.`);
    }

    async processCountryProvinces() {
        console.log(`JOB (${this.jobName}): Processing Country Provinces started...`);
        const { INTERIM_SPAINCUSTOMERS, CountryRegions, CountryProvinces } = this.db.entities("com.bayer.SXTENDER.MasterData");

        const interimCustomers = await SELECT.distinct.from(INTERIM_SPAINCUSTOMERS).columns('Province', 'Region', 'CustomerID').where({ Status: 'New' });
        if (!interimCustomers || interimCustomers.length === 0) {
            console.log(`JOB (${this.jobName}): No new customers to process for provinces.`);
            return;
        }

        const existingProvinces = await SELECT.from(CountryProvinces).columns('Name').where({ CountryCode: 'ES' });
        const existingProvinceNames = new Set(existingProvinces.map(p => p.Name));

        const regions = await SELECT.from(CountryRegions).columns('ID', 'RegionCode').where({ CountryCode: 'ES' });
        const regionMap = new Map(regions.map(r => [r.RegionCode, r.ID]));

        const newProvinces = [];
        for (const customer of interimCustomers) {
            if (customer.Province && !existingProvinceNames.has(customer.Province)) {
                const regionId = regionMap.get(customer.Region);
                if (regionId) {
                    newProvinces.push({
                        CountryCode: 'ES',
                        RegionID: regionId,
                        Name: customer.Province,
                    });
                    existingProvinceNames.add(customer.Province); // Avoid duplicates
                } else {
                    console.log(`JOB (${this.jobName}): Could not find region for province ${customer.Province} (region code: ${customer.Region})`);
                }
            }
        }

        await this.processWithStatus(newProvinces, async (province) => {
            await INSERT.into(CountryProvinces).entries(province);
        }, 'Name', 'Province insert failed');
        console.log(`JOB (${this.jobName}): Processing Country Provinces finished.`);
    }

    // async processPaymentTerms() {
    //     console.log(`JOB (${this.jobName}): Processing Payment Terms started...`);
    //     const { INTERIM_SPAINCUSTOMERS, PaymentTerms } = this.db.entities("com.bayer.SXTENDER.MasterData");

    //     const interimCustomers = await SELECT.distinct.from(INTERIM_SPAINCUSTOMERS).columns('PaymentTerm', 'CustomerID').where({ Status: 'New' });
    //     if (!interimCustomers || interimCustomers.length === 0) {
    //         console.log(`JOB (${this.jobName}): No new customers to process for payment terms.`);
    //         return;
    //     }

    //     const existingPaymentTerms = await SELECT.from(PaymentTerms).columns('E1KNVVM_ZTERM').where({ CountryCode: 'ES' });
    //     const existingPaymentTermCodes = new Set(existingPaymentTerms.map(pt => pt.E1KNVVM_ZTERM));

    //     const newPaymentTerms = [];
    //     for (const customer of interimCustomers) {
    //         if (customer.PaymentTerm && !existingPaymentTermCodes.has(customer.PaymentTerm)) {
    //             newPaymentTerms.push({
    //                 CountryCode: 'ES',
    //                 E1KNVVM_ZTERM: customer.PaymentTerm,
    //                 Description: customer.PaymentTerm,
    //                 CustomerID: customer.CustomerID
    //             });
    //             existingPaymentTermCodes.add(customer.PaymentTerm); // Avoid duplicates
    //         }
    //     }

    //     await this.processWithStatus(newPaymentTerms, async (pt) => {
    //         await INSERT.into(PaymentTerms).entries(pt);
    //     }, 'E1KNVVM_ZTERM', 'Payment term insert failed');
    //     console.log(`JOB (${this.jobName}): Processing Payment Terms finished.`);
    // }

    async processInstituteData() {
        console.log(`JOB (${this.jobName}): Processing Institute Data started...`);
        const { INTERIM_SPAINCUSTOMERS, PT_TMINST, CountryRegions, CountryProvinces } = this.db.entities("com.bayer.SXTENDER.MasterData");

        const interimCustomers = await SELECT.from(INTERIM_SPAINCUSTOMERS).where({ Status: 'New' });

        if (!interimCustomers || interimCustomers.length === 0) {
            console.log(`JOB (${this.jobName}): No data found in ${INTERIM_SPAINCUSTOMERS.name}.`);
            return;
        }

        const regions = await SELECT.from(CountryRegions).columns('ID', 'NAME').where({ CountryCode: 'ES' });
        const regionMap = new Map(regions.map(r => [r.NAME, r.ID]));

        const provinces = await SELECT.from(CountryProvinces).columns('ID', 'NAME').where({ CountryCode: 'ES' });
        const provinceMap = new Map(provinces.map(p => [p.NAME, p.ID]));

        // Get all existing institutes by CustomerID
        const existingInstitutes = await SELECT.from(PT_TMINST).columns('InstituteID', 'CustomerID').where({ CountryCode: 'ES' });
        const existingInstituteByCustomerID = new Map(existingInstitutes.map(i => [i.CustomerID, i.InstituteID]));

        let maxInstituteIdResult = await SELECT.one.from(PT_TMINST).columns(['max(InstituteID) as maxId']);
        let maxInstituteId = maxInstituteIdResult ? maxInstituteIdResult.maxId : 0;

        const institutesToUpdate = [];
        const institutesToInsert = [];
        const processedIDs = [];
        const failedIDs = [];
        for (const customer of interimCustomers) {
            try {
                const regionId = regionMap.get(customer.Region);
                const provinceId = provinceMap.get(customer.Province);
                const instituteData = this.mapToInstitute(customer, regionId, provinceId);

                const existingInstituteId = existingInstituteByCustomerID.get(customer.CustomerID);
                if (existingInstituteId) {
                    instituteData.InstituteID = existingInstituteId;
                    institutesToUpdate.push(instituteData);
                } else {
                    maxInstituteId++;
                    instituteData.InstituteID = maxInstituteId;
                    institutesToInsert.push(instituteData);
                }
                processedIDs.push(customer.ID);
            } catch (err) {
                failedIDs.push(customer.ID);
                await this.updateInterimStatusForCustomers([customer.ID], 'Failed', 'Institute mapping failed');
                console.error(`Institute mapping failed for ID ${customer.ID}:`, err.message);
            }
        }
        await this.processWithStatus(institutesToInsert, async (inst) => {
            await INSERT.into(PT_TMINST).entries(inst);
        }, 'CustomerID', 'Institute insert failed');
        await this.processWithStatus(institutesToUpdate, async (inst) => {
            await UPDATE(PT_TMINST).set(inst).where({ InstituteID: inst.InstituteID });
        }, 'CustomerID', 'Institute update failed');
        // Set status to 'Processed' for all successfully processed customers (excluding failed ones)
        const successfulIDs = processedIDs.filter(id => !failedIDs.includes(id));
        if (successfulIDs.length > 0) {
            await this.updateInterimStatusForCustomers(successfulIDs, 'Processed', null);
        }
        console.log(`JOB (${this.jobName}): Processing Institute Data finished.`);
    }

    /**
     * Maps CG1_Code and CG2_Code to the correct FAST Institute Type using the provided mapping table.
     */
    getInstituteType(CG1_Code, CG2_Code) {
        // Mapping table from image
        const mapping = {
            'H04': 'Private Account',
            'H01': 'Private Account',
            'H03': 'Private Account',
            'P01': 'Public Account',
            'B04': 'Bayer affiliates/group',
            'A04': 'Pharmacy',
            'C01': 'End user',
            'A01': 'Pharmacy',
            'R03': 'Retailer/Dealer',
            'R04': 'Retailer/Dealer',
            'A03': 'Pharmacy',
            'R02': 'Retailer/Dealer',
            'W04': 'Wholesaler/Distributor',
            'W01': 'Wholesaler/Distributor',
            'D04': 'Distributor (HealthCare ONLY)',
            'E08': 'Enabling Partner',
            'E09': 'Enabling Partner',
            'E99': 'Enabling Partner',
            'B01': 'Bayer affiliates/group',
            'W03': 'Wholesaler/Distributor',
            'X01': 'Health Care Professional',
            'D03': 'Distributor (HealthCare ONLY)',
            'B03': 'Bayer affiliates/group'
        };
        // Try CG2_Code first, fallback to CG1_Code if not found
        return mapping[CG2_Code] || mapping[CG1_Code] || 'Unknown';
    }

    mapToInstitute(customer, regionId, provinceId) {
        return {
            CountryCode: 'ES',
            CustomerID: customer.CustomerID,
            InstituteName: customer.CustomerName,
            InstituteType: this.getInstituteType(customer.CG1_Code, customer.CG2_Code),
            Address: customer.Address,
            ContactNo: null,
            Fax: null,
            ContactPerson: null,
            ActiveRecord: 'Yes',
            Comment: null,
            City: null,
            INSTITUTE_HIERARCHY_ID: null,
            State: null,
            MercadoPublicoIssuer: null,
            RegionID: regionId,
            ProvinceID: provinceId,
            CifCode: 'NA',
            RegionalHealthSystem: 'NA',
            VatCode: 'NA',
            TaxCode: customer.Taxcode,
            CustomerGroup: customer.CG1_Code,
            ApplicableTaxRate: null,
            INCOTerms: null,
            PaymentTerms: customer.PaymentTerm,
            ForAllBrands: true,
            DirectTender: true,
            ContactEmail: null,
            CNPJ: null,
            Shortname: null,
            KAM_Territory: null,
            External_InstituteId: null,
            Class: null,
            SAPGroupId: null,
            CG1_Description: customer.CG1_Description,
            CG2_Description: customer.CG2_Description,
            CG1_Code: customer.CG1_Code,
            CG2_Code: customer.CG2_Code
        };
    }
};
