const cds = require('@sap/cds');
const BaseJob = require('../BaseJob');

module.exports = class ProcessCustomers extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
        this.jobName = jobName.toUpperCase();
    }

    /**
    * Triggered when job has started
    */
    //override
    async onTick() {
        console.log(`JOB (${this.jobName }): Processing Brazil customers ...`);
        const start = new Date().getTime();
        this.db = await cds.connect.to('db');
        const tx = this.db.tx();

        try {
            // Fetch data
            const allSAPCustomers = await this.getSAPCustomers(tx);
            const distributors = allSAPCustomers.filter(cust => cust.REPRES === 'X');
            const institutes = allSAPCustomers.filter(cust => cust.REPRES !== 'X');

            // Process data
            await this.processDistributors(distributors, tx);
            await this.processInstitutes(institutes, tx);

            // Commit All
            await tx.commit();
            console.log(`JOB (${this.jobName }): Processing of Brazil customers successfully completed.`);
            const end = new Date().getTime();
            const time = end - start;
            console.log(`JOB (${this.jobName }): SUCCESS --> Execution time: ${time}ms`);

        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Processing of Brazil customers failed.`);
            console.error(error);
            // Rollback All
            await tx.rollback();
            //throw error;
        }
    }


    /**
     * This method fetches all the customers from COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILCUSTOMERS
     * @returns - A list of Customers
     */
    async getSAPCustomers(tx) {
        try {
            console.log(`JOB (${this.jobName }): Fetching Brazil customers from COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILCUSTOMERS ...`);
            const { BrazilCustomers } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const result = await tx.run(SELECT.from(BrazilCustomers));
            console.log(`JOB (${this.jobName }): Fetching of Brazil customers from COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILCUSTOMERS successfully completed`);
            return result;
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching of Brazil customers from COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILCUSTOMERS failed`);
            console.error(error);
            throw error;
        }
    }

    /**
     * This method will process a list of Distributors by Creating/Updating PT_TMDIST and DistributorDivision entities
     * from COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILCUSTOMERS. 
     * After successful processing, the COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILCUSTOMERS records will be deleted.
     * @param {*} distributors 
     * @returns 
     */
    async processDistributors(distributors, tx) {
        console.log(`JOB (${this.jobName }): Processing Brazil distrubutors ...`);
        try {
            // 1. Distributors - PT_TMDIST
            // distributors list now contains the same distributor per division, we must not process the same distributor more than ones
            const uniqueDistributors = Array.from(new Set(distributors.map(d => d.CODIGO)))
                                    .map(codigo => {
                                        return distributors.find(d => d.CODIGO === codigo)
                                    });
            const mappedDistributors = this.mapSAPDistributorsToFAST(uniqueDistributors);
            await this.upsertFASTDistributors(mappedDistributors, tx);

            // 2. Divisions - DistributorDivision
            const mappedDivisions = this.mapSAPDivisionsToFAST(distributors, "distributor");
            await this.upsertFASTDistributorDivision(mappedDivisions, tx);

            console.log(`JOB (${this.jobName }): Processing of Brazil distrubutors successfully completed.`);

        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Processing of Brazil distrubutors failed.`);
            console.error(error);
            throw error;
        }
    }

     /**
     * This method will process a list of Institutes by Creating/Updating PT_TMINST and InstituteDivision entities
     * from COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILCUSTOMERS. 
     * After successful processing, the COM_BAYER_SXTENDER_MASTERDATA_SAP_BRAZILCUSTOMERS records will be deleted.
     * @param {*} institutes 
     * @returns 
     */
      async processInstitutes(institutes, tx) {
        console.log(`JOB (${this.jobName }): Processing Brazil institutes ...`);
        try {
            // 1. Institutes - PT_TMINST
            // Institutes list now contains the same institute per division, we must not process the same institute more than ones
            const uniqueInstitutes = Array.from(new Set(institutes.map(d => d.CODIGO)))
                                    .map(codigo => {
                                        return institutes.find(d => d.CODIGO === codigo)
                                    });
            const mappedInstitutes = this.mapSAPInstitutesToFAST(uniqueInstitutes);
            await this.upsertFASTInstitutes(mappedInstitutes, tx);

            // 2. Divisions - InstituteDivision
            const mappedDivisions = this.mapSAPDivisionsToFAST(institutes, "institute");
            await this.upsertFASTInstituteDivision(mappedDivisions, tx);

            console.log(`JOB (${this.jobName }): Processing of Brazil institutes successfully completed.`);

        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Processing of Brazil institutes failed.`);
            console.error(error);
            throw error;
        }
    }

    /**
     * Maps Customer fields from SAP to FAST Distributors
     * @param {*} distributors 
     * @returns 
     */
    mapSAPDistributorsToFAST(distributors) {
        console.log(`JOB (${this.jobName }): Mapping of Brazil distributors ...`);
        distributors = distributors.reduce((prev, curr, idx, distributors) => {
            const numberOfDivisions = (distributors.filter(distr => distr.CODIGO ===  curr.CODIGO)).length;

            let fastDistributor = {
                CountryCode: "BR",
                DistributorID: null,
                DistributorName: curr.RAZAO,
                Address: `${curr.ENDERECO} ${curr.BAIRRO} ${curr.CEP} ${curr.CIDADE}`,
                ContactNo: curr.TELEFONE,
                Fax: curr.FAX,
                ContactPerson: null,
                ActiveRecord: (!curr.BLOQ && curr.STATUS === 'A') ? 'Yes' : 'No',
                CONTACT_EMAIL: curr.EMAIL,
                City: curr.CIDADE,
                State: curr.REGIAO,
                TaxCode: curr.IE,
                CNPJ: curr.CNPJ,
                CustomerID: curr.CODIGO,
                Shortname: curr.FANTASIA,
                CommissionRate: 0.0,
                INCOTerms: null,
                PaymentTerms: null,
                ForAllBrands: (numberOfDivisions > 2),
            };

            prev.push(fastDistributor);
            return prev;
        }, []);
        console.log(`JOB (${this.jobName }): Mapping of Brazil distributors finished.`);
        return distributors;
    }

    /**
     * Maps Customer fields from SAP to FAST Institutes
     * @param {*} institutes 
     * @returns 
     */
     mapSAPInstitutesToFAST(institutes) {
        console.log(`JOB (${this.jobName }): Mapping of Brazil institutes ...`);
        institutes = institutes.reduce((prev, curr, idx, institutes) => {
            const numberOfDivisions = (institutes.filter(distr => distr.CODIGO ===  curr.CODIGO)).length;

            let fastInstitute = {
                CountryCode: "BR",
                InstituteID: "",
                CustomerID: curr.CODIGO,
                InstituteName: curr.RAZAO,
                InstituteType: "Public Institute",
                Address: `${curr.ENDERECO} ${curr.BAIRRO} ${curr.CEP} ${curr.CIDADE}`,
                ContactNo: curr.TELEFONE,
                Fax: curr.FAX,
                ContactPerson: null,
                ActiveRecord: (!curr.BLOQ && curr.STATUS === 'A') ? 'Yes' : 'No',
                Comment: null,
                City: curr.CIDADE,
                INSTITUTE_HIERARCHY_ID: 1,
                State: curr.REGIAO,
                MercadoPublicoIssuer: null,
                RegionID: null,
                ProvinceID: null,
                CifCode: null,
                RegionalHealthSystem: null,
                VatCode: null,
                TaxCode: "IE",
                CustomerGroup: null,
                ApplicableTaxRate: null,
                INCOTerms: null,
                PaymentTerms: null,
                ForAllBrands: (numberOfDivisions > 2),
                DirectTender: "",
                ContactEmail: curr.EMAIL,
                CNPJ: curr.CNPJ,
                Shortname: curr.FANTASIA,
            };

            prev.push(fastInstitute);
            return prev;
        }, []);
        console.log(`JOB (${this.jobName }): Mapping of Brazil institutes finished.`);
        return institutes;
    }

    /**
     * Maps Customer fields from SAP to FAST DistributorDivision or InstituteDivision 
     * based on type.
     * @param {array} divisions
     * @param {string} type - 'distributor' or 'institue'
     * @returns {array}
     */
     mapSAPDivisionsToFAST(divisions, type) {
        console.log(`JOB (${this.jobName }): Mapping of Brazil divisions ...`);
        divisions = divisions.reduce((prev, curr, idx, divisions) => {
            let fastDivision = {
                DivisionCode: curr.SETOR_ATIV,
                CustomerID: curr.CODIGO,
                DivisionName: this.getDivisionName(curr.SETOR_ATIV),
                CustomerGroup: curr.GRP_CLIENTE,
                PriceList: curr.LISTA_PRC,
            };
            if(type === "distributor"){
                fastDivision.DistributorID = "";
                fastDivision.DistributorType = "Distributor";
            }else if(type === "institute"){
                fastDivision.InstituteID = "";
                fastDivision.InstituteType = "Public Institute";
            }
            prev.push(fastDivision);
            return prev;
        }, []);
        console.log(`JOB (${this.jobName }): Mapping of Brazil divisions finished.`);
        return divisions;
    }


    /**
     * Creates or Updates distributors in FAST
     * @param {*} distributors 
     * @returns 
     */
    async upsertFASTDistributors(distributors, tx) {
        const { PT_TMDIST } = this.db.entities("com.bayer.SXTENDER.MasterData");
        let nextDistributorID = await this.getNextValue(PT_TMDIST, "DistributorID", tx);

        // 1. get a list of existing Distributors from FAST
        const distributorsExistingInFAST = await this.getFASTDistributors(distributors, tx);
        // 2. devide mappedDistributors into New or Changed distributors
        const FASTNewDistributors = [];
        const FASTChangedDistributors = [];
        for (const distributor of distributors) {
            let FASTDistributorIdx = distributorsExistingInFAST.findIndex(FASTDistributor => Number(FASTDistributor.CustomerID) === Number(distributor.CustomerID));
            if (FASTDistributorIdx > -1) {
                // copy over the DistributorID from existing distributor
                distributor.DistributorID = distributorsExistingInFAST[FASTDistributorIdx].DistributorID;
                FASTChangedDistributors.push(distributor);
            } else {
                // generate new DistributorID
                distributor.DistributorID = nextDistributorID++;
                FASTNewDistributors.push(distributor);
            }
        }
        // 3. Upsert records into PT_TMDIST
        //Update is one by one: https://answers.sap.com/questions/13676137/bulk-update-in-cap-nodejs.html
        console.log(`JOB (${this.jobName }): Upserting Brazil customers into FAST table ...`);
        try {
            for (const FASTDistributor of FASTChangedDistributors) {
                await tx.run(UPDATE(PT_TMDIST, {CountryCode:FASTDistributor.CountryCode, DistributorID:FASTDistributor.DistributorID}).with(FASTDistributor));
            }
            FASTNewDistributors && FASTNewDistributors.length > 0 && await tx.run(INSERT(FASTNewDistributors).into(PT_TMDIST));
            console.log(`JOB (${this.jobName }): Upserting of Brazil customers into FAST table successfully completed.`);
            return true;
        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Upserting of Brazil customers into FAST table failed`);
            console.error(error);
            throw error;
        }
    }

    /**
     * Creates or Updates Institutes in FAST
     * @param {*} institutes 
     * @returns 
     */
     async upsertFASTInstitutes(institutes, tx) {
        const { PT_TMINST } = this.db.entities("com.bayer.SXTENDER.MasterData");
        let nextInsituteID = await this.getNextValue(PT_TMINST, "InstituteID", tx);

        // 1. get a list of existing Institutes from FAST
        const insitutesExistingInFAST = await this.getFASTInstitutes(institutes, tx);
        // 2. devide mappedDistributors into New or Changed institutes
        const FASTNewInstitutes = [];
        const FASTChangedInstitutes = [];
        for (const institute of institutes) {
            let FASTInstituteIdx = insitutesExistingInFAST.findIndex(FASTInstitute => Number(FASTInstitute.CustomerID) === Number(institute.CustomerID));
            if (FASTInstituteIdx > -1) {
                // copy over the DistributorID from existing distributor
                institute.InstituteID = insitutesExistingInFAST[FASTInstituteIdx].InstituteID;
                FASTChangedInstitutes.push(institute);
            } else {
                // generate new DistributorID
                institute.InstituteID = nextInsituteID++;
                FASTNewInstitutes.push(institute);
            }
        }
        // 3. Upsert records into PT_TMDIST
        console.log(`JOB (${this.jobName }): Upserting Brazil Institutes into FAST table ...`);
        try {
            for (const FASTInstitute of FASTChangedInstitutes) {
                await tx.run(UPDATE(PT_TMINST, {CountryCode:FASTInstitute.CountryCode, InstituteID:FASTInstitute.InstituteID}).with(FASTInstitute));
            }
            FASTNewInstitutes && FASTNewInstitutes.length > 0 && await tx.run(INSERT(FASTNewInstitutes).into(PT_TMINST));
            console.log(`JOB (${this.jobName }): Upserting of Brazil Institutes into FAST table successfully completed.`);
            return true;
        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Upserting of Brazil Institutes into FAST table failed`);
            console.error(error);
            throw error;
        }
    }

    
    /**
     * Creates or Updates divisions in FAST
     * After successful processing, the processed customers will be removed from BrazilCustomers
     * @param {*} divisions 
     * @returns 
     */
     async upsertFASTDistributorDivision(divisions, tx) {
        const { DistributorDivision } = this.db.entities("com.bayer.SXTENDER.MasterData");

        // 1. get a list of existing Distributors from FAST
        const distributorsExistingInFAST = await this.getFASTDistributors(divisions, tx);
        const divisionsExistingInFAST = await this.getFASTDivisions(divisions, "distributor", tx);

        // 2. devide mapped Divisions into New or Changed divisions
        const FASTNewDivisions = [];
        const FASTChangedDivisions = [];
        for (const division of divisions) {
            let FASTDistributor = distributorsExistingInFAST.find(FASTDistributor => Number(FASTDistributor.CustomerID) === Number(division.CustomerID));
            // copy over the DistributorID from existing distributor
            division.DistributorID = FASTDistributor.DistributorID;
            let FASTDivisionIdx = divisionsExistingInFAST.findIndex(FASTDivision => Number(FASTDivision.CustomerID) === Number(division.CustomerID));
            if (FASTDivisionIdx > -1) {
                FASTChangedDivisions.push(division);
            } else {
                FASTNewDivisions.push(division);
            }
        }

        // 3. Upsert records into DistributorDivision
        console.log(`JOB (${this.jobName }): Upserting DistributorDivisions into FAST table ...`);
        try {
            for (const FASTDivision of FASTChangedDivisions) {
                await tx.run(UPDATE(DistributorDivision, {DistributorID:FASTDivision.DistributorID, DivisionCode:FASTDivision.DivisionCode}).with(FASTDivision));
            }
            FASTNewDivisions && FASTNewDivisions.length > 0 && await tx.run(INSERT(FASTNewDivisions).into(DistributorDivision));
            console.log(`JOB (${this.jobName }): Upserting of DistributorDivision into FAST table successfully completed.`);
            console.log(`JOB (${this.jobName }): Deleting processed Customers from BrazilCustomers table`);
            const { BrazilCustomers } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            await tx.run(DELETE.from(BrazilCustomers).where ({REPRES: 'X'}));
            return true;
        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Upserting of DistributorDivisions into FAST table failed`);
            console.error(error);
            throw error;
        }
    }

    
    /**
     * Creates or Updates divisions in FAST
     * After successful processing, the processed customers will be removed from BrazilCustomers
     * @param {*} divisions 
     * @returns 
     */
     async upsertFASTInstituteDivision(divisions, tx) {
        const { InstituteDivision } = this.db.entities("com.bayer.SXTENDER.MasterData");

        // 1. get a list of existing Institutes from FAST
        const institutesExistingInFAST = await this.getFASTInstitutes(divisions, tx);
        const divisionsExistingInFAST = await this.getFASTDivisions(divisions, "insitute", tx);

        // 2. devide mapped Divisions into New or Changed divisions
        const FASTNewDivisions = [];
        const FASTChangedDivisions = [];
        for (const division of divisions) {
            let FASTInstitute = institutesExistingInFAST.find(FASTInstitute => Number(FASTInstitute.CustomerID) === Number(division.CustomerID));
            // copy over the InstituteID from existing distributor
            division.InstituteID = FASTInstitute.InstituteID;
            let FASTDivisionIdx = divisionsExistingInFAST.findIndex(FASTDivision => Number(FASTDivision.CustomerID) === Number(division.CustomerID));
            if (FASTDivisionIdx > -1) {
                FASTChangedDivisions.push(division);
            } else {
                FASTNewDivisions.push(division);
            }
        }

        // 3. Upsert records into InstituteDivision
        console.log(`JOB (${this.jobName }): Upserting InstituteDivisions into FAST table ...`);
        try {
            for (const FASTDivision of FASTChangedDivisions) {
                await tx.run(UPDATE(InstituteDivision, {InstituteID:FASTDivision.InstituteID, DivisionCode:FASTDivision.DivisionCode}).with(FASTDivision));
            }
            FASTNewDivisions && FASTNewDivisions.length > 0 && await tx.run(INSERT(FASTNewDivisions).into(InstituteDivision));
            console.log(`JOB (${this.jobName }): Upserting of InstituteDivisions into FAST table successfully completed.`);
            console.log(`JOB (${this.jobName }): Deleting processed Customers from BrazilCustomers table`);
            const { BrazilCustomers } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            await tx.run(DELETE.from(BrazilCustomers).where ({REPRES: null}));
            return true;
        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Upserting of InstituteDivisions into FAST table failed`);
            console.error(error);
            throw error;
        }
    }

    /**
     * Gets a list of existing Distributors from FAST where CustomerIDs (CODIGO) are equal.
     * @param {Array} distributors 
     * @returns {Array<PT_TMDIST>} a list of existing distributors
     */
    async getFASTDistributors(distributors, tx) {
        if(!distributors || distributors.length === 0){
            console.log(`JOB (${this.jobName }): No Distributors were found in FAST`);
            return [];
        }
        console.log(`JOB (${this.jobName }): Prepare fetching Brazil customers from FAST table`);

        // get all the CustomerIDs from distributors
        let customerIDs = [];
        for (const distributor of distributors) {
            customerIDs.push(distributor.CustomerID);
        }
        console.log(`JOB (${this.jobName }): Start fetching Brazil customers from FAST table`);

        // get a list of distributors entities for given list of CustomerIDs
        const { PT_TMDIST } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const result = await tx.run(SELECT.from(PT_TMDIST).where({ CustomerID: { in: customerIDs}, CountryCode: 'BR' } ));
        console.log(`JOB (${this.jobName }): End fetching Brazil customers from FAST table`);
        return result;
    }

    /**
     * Gets a list of existing Institutes from FAST where CustomerIDs (CODIGO) are equal.
     * @param {Array} institutes 
     * @returns {Array<PT_TMINST>} a list of existing institutes
     */
     async getFASTInstitutes(institutes, tx) {
        if(!institutes || institutes.length === 0){
            console.log(`JOB (${this.jobName }): No Institutes were found in FAST`);
            return [];
        }
        console.log(`JOB (${this.jobName }): Prepare fetching Brazil institutes from FAST table`);

        // get all the CustomerIDs from distributors
        let customerIDs = [];
        for (const institute of institutes) {
            customerIDs.push(institute.CustomerID);
        }
        console.log(`JOB (${this.jobName }): Start fetching Brazil institutes from FAST table`);

        // get a list of distributors entities for given list of CustomerIDs
        const { PT_TMINST } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const result = await tx.run(SELECT.from(PT_TMINST).where({ CustomerID: { in: customerIDs}, CountryCode: 'BR' } ));
        console.log(`JOB (${this.jobName }): End fetching Brazil institutes from FAST table`);
        return result;
    }

    /**
     * Gets a list of existing Divisions from FAST where CustomerIDs (CODIGO) are equal.
     * @param {array} divisions 
     * @returns {array} a list of existing divisions
     */
     async getFASTDivisions(divisions, type, tx) {
        if(!divisions || divisions.length === 0){
            console.log(`JOB (${this.jobName }): No Divisions were found in FAST`);
            return [];
        }

        console.log(`JOB (${this.jobName }): Prepare fetching Brazil divisions from FAST table`);

        // get all the CustomerIDs from divisions
        let customerIDs = [];
        let divisionCodes = [];
        for (const division of divisions) {
            customerIDs.push(division.CustomerID);
            divisionCodes.push(division.DivisionCode);
        }
        console.log(`JOB (${this.jobName }): Start fetching Brazil divisions from FAST table`);

        // get a list of divisions entities for given list of CustomerIDs
        let result = "";
        if(type === 'distributor'){
            result = await this.getFASTDistributorDivisions(customerIDs, divisionCodes, tx);
        }else if(type === 'insitute'){
            result = await this.getFASTInsituteDivisions(customerIDs, divisionCodes, tx);
        }

        console.log(`JOB (${this.jobName }): End fetching Brazil divisions from FAST table`);
        return result;
    }

    async getFASTDistributorDivisions(customerIDs, divisionCodes, tx){
        const { DistributorDivision } = this.db.entities("com.bayer.SXTENDER.MasterData");
        return tx.run(SELECT.from(DistributorDivision).where({ CustomerID: { in: customerIDs}, DivisionCode: { in: divisionCodes} } ));
    }

    async getFASTInsituteDivisions(customerIDs, divisionCodes, tx){
        const { InstituteDivision } = this.db.entities("com.bayer.SXTENDER.MasterData");
        return tx.run(SELECT.from(InstituteDivision).where({ CustomerID: { in: customerIDs}, DivisionCode: { in: divisionCodes} } ));
    }
    
    /**
     * Gets the next highest value for a given field from table
     * @param {*} table 
     * @param {*} fieldname 
     * @returns - next highest value
     */
    async getNextValue (table, fieldname, tx){
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
    
};