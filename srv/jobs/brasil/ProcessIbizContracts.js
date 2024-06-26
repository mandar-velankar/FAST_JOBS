const cds = require('@sap/cds');
const BaseJob = require('../BaseJob');

module.exports = class processIbizContracts extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
        this.jobName = jobName.toUpperCase();
    }

 /**
    * Triggered when job has started
    */
    //override
    async onTick() {
        console.log(`JOB (${this.jobName }): Processing Ibiz Contracts ...`);
        const start = new Date().getTime();
        
        this.db = await cds.connect.to('db');
        const tx = this.db.tx();

        try {
            // Fetch data
            const ibizContracts = await this.getContracts(tx);
            const ibizContractsParentIDs = ibizContracts.map(ctr => ctr.ID);
            const ibizContractProducts = await this.getContractProducts(tx, ibizContractsParentIDs);
            const ibizContractDocs = await this.getContractDocs(tx, ibizContractsParentIDs); 

            // Process data
            await this.processContracts(tx, ibizContracts, ibizContractProducts, ibizContractDocs);

            // Commit All
            await tx.commit();
            console.log(`JOB (${this.jobName }): Processing Ibiz Contracts successfully completed.`);
            const end = new Date().getTime();
            const time = end - start;
            console.log(`JOB (${this.jobName }): SUCCESS --> Execution time: ${time} ms`);

        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Processing of Ibiz Contracts failed.`);
            console.error(error);
            await tx.rollback();
            //throw error;
        }
    }

      /**
     * This method fetches all the Ibiz contracts from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZCONTRATOS
     * @returns - A list of Ibiz contracts
     */
    async getContracts(tx) {
        const { IbizContratos } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        console.log(`JOB (${this.jobName }): Fetching data from ${IbizContratos.name} ...`);
        try {
            return await tx.run(SELECT.from(IbizContratos));
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching data from ${IbizContratos.name} failed`);
            console.error(error);
            throw error;
        }
    }

    /**
     * This method fetches all the Ibiz contract products from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZCONTRATOSITEMS
     * @returns {Array} - A list of Ibiz contract products
     */
     async getContractProducts(tx, parentIDs) {
        if(!parentIDs || parentIDs.length <= 0) {
            console.log(`No Products found for the following contracts: ${parentIDs}`);
            return [];
        }
        const { IbizContratosItems } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        console.log(`JOB (${this.jobName }): Fetching data from ${IbizContratosItems.name} ...`);
        try {
            return await tx.run(SELECT.from(IbizContratosItems).where({'parent_ID': { in: parentIDs }}));
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching data from ${IbizContratosItems.name} failed`);
            console.error(error);
            throw error;
        }
    }

     /**
     * This method fetches all the Ibiz Contract Documents from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZDOCS
     * @returns {Array} - A list of Ibiz Contract Documents
     */
      async getContractDocs(tx, parentIDs) {
        if(!parentIDs || parentIDs.length <= 0) {
            console.log(`No documents found for the following contracts: ${parentIDs}`);
            return [];
        }
        const { IbizDocs } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        console.log(`JOB (${this.jobName }): Fetching data from ${IbizDocs.name} ...`);
        try {
            return await tx.run(SELECT.from(IbizDocs).where({'Contratos_ID': { in: parentIDs } }));
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching data from ${IbizDocs.name} failed`);
            console.error(error);
            throw error;
        }
    }

    /**
     * This method fetches all the ContractStatuses from COM_BAYER_SXTENDER_ADMINDATA_CONTRACTSTATUS
     * @returns - 
     */
     async getContractStatuses(tx) {
         const { ContractStatus } = this.db.entities("com.bayer.SXTENDER.AdminData");
         console.log(`JOB (${this.jobName }): Fetching data from ${ContractStatus.name} ...`);
        try {
            return await tx.run(SELECT.from(ContractStatus));
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching data from ${ContractStatus.name} failed`);
            console.error(error);
            throw error;
        }
    }


/**
 * This method will process a list of Ibiz Contracts by Creating/Updating the following entities
 *  - Contracts
 *  - ContractProducts
 *  - DocumentsDownload
 * After successful processing, all the Ibiz records will be deleted.
 */
 async processContracts(tx, ibizContracts, ibizContractProducts, ibizContractDocs) {
     try {
        console.log(`JOB (${this.jobName }): Processing Ibiz Contracts ...`);

        // 0. Fetch existing data from FAST
        const contractStatuses = await this.getContractStatuses(tx);
        const existingInstitutesInFAST = await this.getFASTInstitutes(tx);
        const existingDistributorsInFAST = await this.getFASTDistributors(tx);
        const existingOfferFAST = await this.getFASTOffers(tx);
        const existingOfferProductsInFAST = await this.getFASTOfferProducts(tx);

        // 1. Mapping - Map IBIZ Contracts to FAST
        const mappedContracts = this.mapIbizContractsToFASTContracts(ibizContracts,contractStatuses,existingInstitutesInFAST,existingDistributorsInFAST,existingOfferFAST);
        const mappedContractProducts = this.mapIbizContractProductsToFASTContractProducts(ibizContractProducts,existingOfferProductsInFAST,mappedContracts);
        const mappedDocs = this.mapIbizContractDocsToFASTDocumentsDownload(ibizContractDocs);

        // 2. Create Contracts
        await this.insertFASTContracts(tx, mappedContracts);

        // 3. Create ContractProducts
        await this.insertFASTContractProducts(tx, mappedContractProducts);

        // 4. Create entries in DocumentsDownload
        await this.upsertFASTDocumentsDownload(tx, mappedDocs, mappedContracts);  

        // 5. Delete all records from IbizContratos, IbizContratosItems and IbizDocs after successful processing.
        const { IbizContratos, IbizContratosItems,IbizDocs } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        await tx.run(DELETE.from(IbizContratos));
        await tx.run(DELETE.from(IbizContratosItems));

        const docParentIDs = mappedDocs.map(pr => pr.parent_ID);
        Array.isArray(docParentIDs) && docParentIDs.length > 0 && await tx.run(DELETE.from(IbizDocs).where({Contratos_ID: {in: docParentIDs}}));

    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Processing of Ibiz Contracts failed.`);
        console.error(error);
        throw error;
    }
}

/**
 * Creates Contracts in FAST
 * @param {Array.Object} Mapped Contracts 
 * @returns 
 */
 async insertFASTContracts(tx, mappedContracts) {
    const { Contracts } = this.db.entities("com.bayer.SXTENDER.BrazilContractingData");
    console.log(`JOB (${this.jobName }): Creating records in ${Contracts.name} ...`);
    try {
        mappedContracts && mappedContracts.length > 0 && await tx.run(INSERT(mappedContracts).into(Contracts));
        console.log(`JOB (${this.jobName }): ${mappedContracts.length} record(s) successfully created in ${Contracts.name}`);
        return true;
    } catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Creating records in ${Contracts.name} failed`);
        console.error(error);
        throw error;
    }
}


/**
 * Creates ContractProducts in FAST
 * @param {Array.Object} Mapped ContractProducts
 * @returns 
 */
async insertFASTContractProducts(tx, mappedContractProducts) {
    const { ContractProducts } = this.db.entities("com.bayer.SXTENDER.BrazilContractingData");
    console.log(`JOB (${this.jobName }): Creating records in ${ContractProducts.name} ...`);
    try {
        mappedContractProducts && mappedContractProducts.length > 0 && await tx.run(INSERT(mappedContractProducts).into(ContractProducts));
        console.log(`JOB (${this.jobName }): ${mappedContractProducts.length} record(s) successfully created in ${ContractProducts.name}`);
        return true;
    } catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Creating records in ${ContractProducts.name} failed`);
        console.error(error);
        throw error;
    }
}



/**
 * Creates Contract Documents in FAST
 * DocumentsDownload
 * @returns 
 */
 async upsertFASTDocumentsDownload(tx, mappedDocs, mappedContracts) {
    const { DocumentsDownload } = this.db.entities("com.bayer.SXTENDER.TransactionalData");

    // 1. link existing Tenders and Offer with Documents
    for (const docs of mappedDocs) {
        let parentContract = mappedContracts.find(ctr => ctr.ID === docs.parent_ID);
        docs.TenderID = parentContract.TenderID;
        docs.OfferID = parentContract.OfferID;
    } 

    // 2. delete Contract ParentId before saving to DB
    const docsWithoutID = mappedDocs.map(doc => { 
        const copy = {...doc}; 
        delete copy.parent_ID; 
        return copy;
    }); 

    // 3. Insert records into DocumentsDownload
    console.log(`JOB (${this.jobName }): Creating records in ${DocumentsDownload.name} ...`);
    try {
        docsWithoutID && docsWithoutID.length > 0 && await tx.run(INSERT(docsWithoutID).into(DocumentsDownload));
        console.log(`JOB (${this.jobName }): ${docsWithoutID.length} record(s) successfully created in ${DocumentsDownload.name}`);
        return true;
    } catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Creating records in ${DocumentsDownload.name} failed`);
        console.error(error);
        throw error;
    }
}


 /**
 * This method fetches all the Institutes from COM_BAYER_SXTENDER_MASTERDATA_PT_TMINST where CNPJ is not null
 * @returns - 
 */
 async getFASTInstitutes(tx) {
    const { PT_TMINST } = this.db.entities("com.bayer.SXTENDER.MasterData");
    console.log(`JOB (${this.jobName }): Fetching data from ${PT_TMINST.name} ...`);
    try {
        return await tx.run(SELECT.from(PT_TMINST).where({'CNPJ': {"!=": null}, CountryCode: 'BR', ActiveRecord: 'Yes' }));
    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Fetching data from ${PT_TMINST.name} failed`);
        console.error(error);
        throw error;
    }
}


/**
 * Gets a list of existing Distributors from FAST
 * @param {Array} distributors 
 * @returns {Array<PT_TMDIST>} a list of existing distributors
 */
 async getFASTDistributors(tx) {
    const { PT_TMDIST } = this.db.entities("com.bayer.SXTENDER.MasterData");
    console.log(`JOB (${this.jobName }): Fetching data from ${PT_TMDIST.name} ...`);
    try {
        return await tx.run(SELECT.from(PT_TMDIST).where({ CountryCode: 'BR' } ));
    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Fetching data from ${PT_TMDIST.name} failed`);
        console.error(error);
        throw error;
    }
}

 /**
 * This method fetches all Offers from COM_BAYER_SXTENDER_TRANSACTIONALDATA_PT_TMOFRS where IbizWorkflowID is not null
 * @returns - 
 */
 async getFASTOffers(tx) {
    const { PT_TMOFRS } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
    console.log(`JOB (${this.jobName }): Fetching data from ${PT_TMOFRS.name} ...`);
    try {
        return await tx.run(SELECT.from(PT_TMOFRS).where({'IbizWorkflowID': {"!=": null}, CountryCode: 'BR', ActiveOffer: 1 }));
    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Fetching data from ${PT_TMOFRS.name} failed`);
        console.error(error);
        throw error;
    }
}

/**
 * This method fetches all the OfferProducts from COM_BAYER_SXTENDER_TRANSACTIONALDATA_PT_TMOFPR where WorkflowProductID is not null
 * @returns - 
 */
async getFASTOfferProducts(tx) {
    const { PT_TMOFPR } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
    console.log(`JOB (${this.jobName }): Fetching data from ${PT_TMOFPR.name} ...`);
    try {
        return await tx.run(SELECT.from(PT_TMOFPR).where({'WorkflowProductID': {"!=": null}, CountryCode: 'BR', Active: 1 }));
    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Fetching data from ${PT_TMOFPR.name} failed`);
        console.error(error);
        throw error;
    }
}


/**
 * Map fields from om.bayer.SXTENDER.MasterData.SAP.IbizContratos to FAST com.bayer.SXTENDER.BrazilContractingData.Contracts
 * @param {[Objects]} ibizContracts 
 * @returns {[Objects]} contracts
 */
mapIbizContractsToFASTContracts(ibizContracts,contractStatuses, existingInstitutesInFAST, existingDistributorsFAST, existingOfferFAST) {
    console.log(`JOB (${this.jobName }): Mapping IBIZ Contracts to FAST ...`);
    const contractStatus = contractStatuses.find(cs => cs.Status.toLowerCase() === "new ibiz");
    ibizContracts = ibizContracts.reduce((prev, curr, idx, ibizContracts) => {
        const offer = existingOfferFAST.find(ofr => ofr.IbizWorkflowID === curr.ID_QP);
        const institute = existingInstitutesInFAST.find(inst => inst.CNPJ === curr.COD_COMPRADOR.replace(/\D/g,''));
        const instituteID = institute && institute.InstituteID || 0;
        const cnpj = curr.COD_VENDEDOR && curr.COD_VENDEDOR.replace(/\D/g,'');
        const distributor = offer && offer.isDirectIbizOpportunity ? existingDistributorsFAST.find(dist => dist.DistributorName === "Bayer Brazil") : existingDistributorsFAST.find(dist => dist.CNPJ === cnpj);
        const distributorID = distributor && distributor.DistributorID || 0;
        prev.push(
            {
                ID                   : curr.ID,
                TenderID             : offer && offer.TenderID || "", 
                OfferID              : offer && offer.OfferID || "",
                InstituteID          : instituteID, 
                DistributorID        : distributorID,
                ContractNumber       : null,
                IbizProcessNumber    : curr.NM_PROCESSO,
                ContractType         : this.getContractType(curr.NM_TIPO_CONTRATO),
                OBS                  : curr.NM_OBS,
                IbizContractID       : curr.ID_CONTRATO,
                IbizContractNumber   : curr.NU_CONTRATO,
                IbizContractSignDate : curr.DT_ASSINATURA,
                StartDate            : curr.DT_INI_VIGENCIA,
                EndDate              : curr.DT_FIM_VIGENCIA,
                StatusID             : contractStatus.ID,
                modifiedBy           : "IBIZ",
                createdBy            : "IBIZ"

            }
        );
        return prev;
    }, []);
    return ibizContracts;
}

getContractType(type){
    const contractTypes = {
        "ATA/Contrato": "From Offer",
        "Adesao": "Adhesion Contract",
        "ATA/Contrato Filho": "From Offer",
        "Aditivo": "Additional Customer",
    };
    return contractTypes[type];
}

getIbizItemType(type){
    const itemTypes = [
        "Direct Sales",
        "Sample FOC",
        "Lending",
        "Consigned",
        "Location",
        "Service",
        "Testing",
        "Bonus FOC"
    ];
    return itemTypes[type];
}

/**
 * Maps from IbizContratosItems to ContractProducts
 * @param {[Objects]} ibizContractProducts 
 * @returns {[Objects]} ContractProducts
 */
mapIbizContractProductsToFASTContractProducts(ibizContractProducts,existingOfferProductsInFAST,mappedContracts) {
    console.log(`JOB (${this.jobName }): Mapping IbizContratosItems to ContractProducts ...`);
    ibizContractProducts = ibizContractProducts.reduce((prev, curr, idx, ibizContractProducts) => {
        const offerProduct = existingOfferProductsInFAST.find(pr => pr.WorkflowProductID === curr.ID_CC_QP);
        const parentContract = mappedContracts.find(cr => cr.ID == curr.parent_ID);
        prev.push(
            {
                ProductPackID           : offerProduct && offerProduct.ProductCode || 0, // TODO: should the job fail in case no ProductPackID was found?
                OfferID                 : parentContract && parentContract.OfferID || "", // TODO: should the job fail in case no OfferID was found?
                IbizContractProductID   : curr.ID_CC_CONTRATO,
                RequestedVolume         : curr.NU_QTDE_UNITARIA,
                IbizItemType            : this.getIbizItemType(curr.NU_TIPO),
                LotID                   : curr.NU_LOTE,
                ContractPrice           : curr.VLR_UNITARIO,
                Contract_ID             : parentContract.ID,
                modifiedBy              : "IBIZ",
                createdBy               : "IBIZ"
            }
        );
        return prev;
    }, []);
    return ibizContractProducts;

}

/**
 * Maps Ibiz Contract Documents from IbizDocs to FAST DocumentsDownload
 * @param {*} ibizContractDocs 
 * @returns {[Objects]} documentsDownload
 */
mapIbizContractDocsToFASTDocumentsDownload(ibizContractDocs){

    console.log(`JOB (${this.jobName }): Mapping IBIZ Contract documents to DocumentsDownload ...`);
    ibizContractDocs = ibizContractDocs.reduce((prev, curr, idx, ibizContractDocs) => {
        prev.push(
            {
                parent_ID             : curr.Contratos_ID,
                DocID                 : curr.ID_DOC,
                DocCreatedAt          : curr.CREATED_AT,
                NameTag               : curr.NM_TAG,
                CountryCode           : "BR",
                TenderID              : "",
                OfferID               : "",
                IbizAPIName           : "Contracts",
                URL                   : curr.FILE_URL,
                Name                  : curr.NM_DOC,
                Downloaded            : false
            }
        );
        return prev;
    }, []);
    return ibizContractDocs;
}


};