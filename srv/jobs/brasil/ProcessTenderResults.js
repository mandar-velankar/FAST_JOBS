const cds = require('@sap/cds');
const BaseJob = require('../BaseJob');

module.exports = class processTenderResults extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
        this.jobName = jobName.toUpperCase();
    }


    /**
    * Triggered when job has started
    */
    //override
    async onTick() {
        console.log(`JOB (${this.jobName }): Processing Ibiz TenderResults ...`);
        const start = new Date().getTime();
        
        this.db = await cds.connect.to('db');
        const tx = this.db.tx();

        try {
            // Fetch data
            const tenderResults = await this.getTenderResults(tx);

            const tenderResultParentIDs = tenderResults.map(trs => trs.ID);
            const tenderResultItems = await this.getTenderResultItems(tx, tenderResultParentIDs);
            const tenderResultDocs = await this.getTenderResultDocs(tx, tenderResultParentIDs); 
            const ibizWorkFlowIds = tenderResults.map(trs => trs.ID_QP);
            const existingProductsFAST = await this.getFASTProducts(tx, ibizWorkFlowIds);
            const existingTendersFAST = await this.getFASTTenders(tx);
            const existingOffersFAST = await this.getFASTOffers(tx);
            const existingDistributorsFAST = await this.getFASTDistributors(tx);

            // Process data
            if(tenderResults.length > 0){
                await this.processTenderResults(tx, tenderResults, tenderResultItems, tenderResultDocs, existingProductsFAST, existingTendersFAST, existingDistributorsFAST, existingOffersFAST);
            }

            // Commit All
            await tx.commit();
            console.log(`JOB (${this.jobName }): Processing Ibiz TenderResults successfully completed.`);
            const end = new Date().getTime();
            const time = end - start;
            console.log(`JOB (${this.jobName }): SUCCESS --> Execution time: ${time} ms`);

        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Processing of Ibiz TenderResults failed.`);
            console.error(error);
            await tx.rollback();
           // throw error;
        }
    }

    /**
     * This method fetches all the Ibiz TenderResults from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZRESULTADOS
     * @returns - A list of Ibiz TenderResults
     */
     async getTenderResults(tx) {
        try {
            console.log(`JOB (${this.jobName }): Fetching Ibiz TenderResults from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZRESULTADOS ...`);
            const { IbizResultados } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const result = await tx.run(SELECT.from(IbizResultados));
            return result;
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching of Ibiz TenderResults from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZRESULTADOS failed`);
            console.error(error);
            throw error;
        }
    }

    /**
 * This method fetches all the Ibiz TenderResult items from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZRESULTADOSITEMS
 * @returns - A list of Ibiz TenderResult items
 */
 async getTenderResultItems(tx, parentIDs) {
    if(!parentIDs || parentIDs.length <= 0) {
        console.log("No Parent Itmes found");
        return [];
    }
    try {
        console.log(`JOB (${this.jobName }): Fetching Ibiz TenderResult items from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZRESULTADOSITEMS ...`);
        const { IbizResultadosItems } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        const result = await tx.run(SELECT.from(IbizResultadosItems).where({'parent_ID': { in: parentIDs }}));
        return result;
    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Fetching of Ibiz TenderResult items from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZRESULTADOSITEMS failed`);
        console.error(error);
        throw error;
    }
}

 /**
 * This method fetches all the Ibiz TenderResult Documents from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZDOCS
 * @returns - A list of Ibiz TenderResult Documents
 */
  async getTenderResultDocs(tx, parentIDs) {
    if(!parentIDs || parentIDs.length <= 0) {
        console.log("No Parent Itmes found");
        return [];
    }
    try {
        console.log(`JOB (${this.jobName }): Fetching Ibiz TenderResult Documents from COM_BAYER_SXTENDER_MASTERDATA_SAP_IbizDocs ...`);
        const { IbizDocs } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        const result = await tx.run(SELECT.from(IbizDocs).where({'Resultados_ID': { in: parentIDs } }));
        return result;
    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Fetching of Ibiz TenderResult Documents from COM_BAYER_SXTENDER_MASTERDATA_SAP_IbizDocs failed`);
        console.error(error);
        throw error;
    }
}

/**
 * Gets a list of existing Products from FAST
 * @param {Array} products 
 * @returns {Array<PT_TMOFPR>} a list of existing Products
 */
 async getFASTProducts(tx, ibizWorkFlowIds) {
    if(!ibizWorkFlowIds || ibizWorkFlowIds.length <= 0) {
        console.log("No Parent Itmes found");
        return [];
    }
    try {
    console.log(`JOB (${this.jobName }): Fetching Product Data from com.bayer.SXTENDER.TransactionalData.PT_TMOFPR ...`);
    const { PT_TMOFPR } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
    const result = await tx.run(SELECT.from(PT_TMOFPR).where({IbizWorkflowID: {in: ibizWorkFlowIds }}));
    return result;
    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Fetching Product Data from com.bayer.SXTENDER.TransactionalData.PT_TMOFPR failed`);
        console.error(error);
        throw error;
    }
}


/**
 * Gets a list of existing Tenders from FAST
 * @param {Array} tenders 
 * @returns {Array<PT_TMTEND>} a list of existing Tenders
 */
 async getFASTTenders(tx) {
    console.log(`JOB (${this.jobName }): Start fetching Brazil Tenders from FAST table`);
    const { PT_TMTEND } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
    const result = await tx.run(SELECT.from(PT_TMTEND).where({ CountryCode: 'BR' } ));
    console.log(`JOB (${this.jobName }): End fetching Brazil Tenders from FAST table`);
    return result;
}

 /**
 * This method fetches all Offers from COM_BAYER_SXTENDER_TRANSACTIONALDATA_PT_TMOFRS where IbizWorkflowID is not null
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
 * Gets a list of existing Distributors from FAST
 * @param {Array} distributors 
 * @returns {Array<PT_TMDIST>} a list of existing distributors
 */
 async getFASTDistributors(tx) {
    console.log(`JOB (${this.jobName }): Start fetching Brazil Distributors from FAST table`);
    const { PT_TMDIST } = this.db.entities("com.bayer.SXTENDER.MasterData");
    const result = await tx.run(SELECT.from(PT_TMDIST).where({ CountryCode: 'BR' } ));
    console.log(`JOB (${this.jobName }): End fetching Brazil Distributors from FAST table`);
    return result;
}

getOutcome(code){
    const outcome = {
        "-3": "Withdrawn",
        "-2": "Decision Pending",
        "-1": "Decision Pending",
        "0": "Lost",
        "1": "Won",
        "2": "Lost",
        "3": "Decision Pending",
    };
    return outcome[code];
}


/**
     * This method will process a list of Ibiz TenderResult by Creating/Updating the following entities
     *  - PT_TMTRRES
     * After successful processing, the records will be deleted from the following buffer tables
     *  - COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZRESULTADOS
     *  - COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZRESULTADOSITEMS
     *  - COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZDOCS
     * @param {[Object]} tenderResults
     */
 async  processTenderResults(tx, tenderResults, tenderResultItems, tenderResultDocs, existingProductsFAST, existingTendersFAST, existingDistributorsFAST, existingOffersFAST) {
    console.log(`JOB (${this.jobName }): Processing Ibiz TenderResult ...`);
    try {

        // 0 Mapping
        const mappedTenderResults = this.mapIbizTenderResultstoFASTResults(tenderResults, tenderResultItems, existingProductsFAST, existingTendersFAST, existingDistributorsFAST, existingOffersFAST);
        const mappedDocs = this.mapIbizTenderResultDocstoFASTDocumentsDownload(tenderResultDocs);

         // 1. Create entries in PT_TMTRRES
         await this.insertFASTResults(tx, mappedTenderResults);

         // 2. Create entries in DocumentsDownload
        await this.insertFASTDocumentsDownload(tx, mappedDocs, mappedTenderResults);
 
         // 3. Delete all records from IbizResultados, IbizResultadosItems and IbizDocs after successful processing.
         const { IbizResultados } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
         await tx.run(DELETE.from(IbizResultados));
         const { IbizResultadosItems } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
         await tx.run(DELETE.from(IbizResultadosItems));
         const { IbizDocs } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
         const docParentIDs = mappedDocs.map(pr => pr.parent_ID);
         Array.isArray(docParentIDs) && docParentIDs.length > 0 && await tx.run(DELETE.from(IbizDocs).where({Resultados_ID: {in: docParentIDs}}));

        console.log(`JOB (${this.jobName }): Processing of Ibiz TenderResult successfully completed.`);

    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Processing of Ibiz TenderResult failed.`);
        console.error(error);
        throw error;
    }
}

/**
     * Maps Ibiz TenderResults fields from Ibiz TenderResults to FAST PT_TMTRRES
     * @param {[Objects]} tenderResults 
     * @returns {[Objects]} tenderResults
     */
 mapIbizTenderResultstoFASTResults(tenderResults, tenderResultItems, existingProductsFAST, existingTendersFAST, existingDistributorsFAST, existingOffersFAST) {

    console.log(`JOB (${this.jobName }): Mapping IBIZ TenderResults to PT_TMTRRES ...`);
    tenderResults = tenderResults.reduce((prev, curr, idx, tenderResults) => {
        const parentOffer = existingOffersFAST.find(ofr => ofr.IbizWorkflowID === curr.ID_QP);
        let product = existingProductsFAST.find(prd => prd.IbizWorkflowID === curr.ID_QP && prd.WorkflowProductID === curr.ID_CC_QP);
        if(!product){return prev;}
        const institute = existingTendersFAST.find(inst => inst.TenderID === product.TenderID);
        const resultItem = tenderResultItems.find(inst => inst.parent_ID === curr.ID);
        const instituteID = institute && institute.InstituteID || 0;
        const distributor = existingDistributorsFAST.find(dst => dst.DistributorID === product.DistributorID);
        const cnpj = resultItem.COD_PARTICIPANTE && resultItem.COD_PARTICIPANTE.replace(/\D/g,'');
        prev.push(
            {
                ID_QP             : curr.ID_QP,
                ID_CC_QP          : curr.ID_CC_QP,
                IBIZ_TECHNICAL_ID : curr.ID,
                TenderID          : product.TenderID,
                OfferID           : parentOffer.OfferID,
                CountryCode       : "BR",
                InstituteID       : instituteID,
                ProductCode       : product.ProductCode,
                ContractNo        : null,
                SubmittedOn       : new Date().toISOString(),
                SubmittedBy       : "IBIZ",
                Active            : 1,
                ErrorInSubmission : "No",
                Outcome           : this.getOutcome(curr.NU_GANHEI),
                AwardedCompany    : distributor.CNPJ == cnpj ? resultItem.NM_FABRICANTE : "Bayer",
                AwardedProduct    : distributor.CNPJ == cnpj ? resultItem.NM_PRODUTO : null,
                AwardedPrice      : distributor.CNPJ == cnpj ? resultItem.VLR_UNITARIO : null,
                Currency          : "BRL",
                AwardedQty        : distributor.CNPJ == cnpj ? resultItem.NU_QTDE : null,
                UoM               : "Unit",
                Reason            : "Not Specified",
                Comment           : curr.NM_DESC_MOTIVO_RESULTADO,
                AwardedTier       : null,
                ExtensionDate     : null,
                ExtensionNotes    : "",
                AwardLetterNo     : "",
                AwardDelibNo      : "",
                DeliveryDate      : null,
                ResultDate        : curr.CREATED_AT,
                AwardDate         : curr.DT_HOMOLOGACAO,
                AwardActing       : null,
                Appeal            : "No",
                InfoNeeded        : "No",
                TotalAwardedValue : distributor.CNPJ == cnpj ? resultItem.VLR_TOTAL : null,
                LotID             : product.LotID
            }
        );
        return prev;
    }, []);
    return tenderResults;
}

/**
 * Maps Ibiz Tender Result Documents from Ibiz to FAST DocumentsDownload
 * @param {*} IbizTenderResultDocuments 
 * @returns {[Objects]} documentsDownload
 */
 mapIbizTenderResultDocstoFASTDocumentsDownload(tenderResultDocs){

    console.log(`JOB (${this.jobName }): Mapping IBIZ Tender Result Documents to DocumentsDownload ...`);
    tenderResultDocs = tenderResultDocs.reduce((prev, curr, idx, tenderResultDocs) => {
        prev.push(
            {
                parent_ID             : curr.Resultados_ID,
                DocID                 : curr.ID_DOC,
                DocCreatedAt          : curr.CREATED_AT,
                NameTag               : curr.NM_TAG,
                CountryCode           : "BR",
                TenderID              : "",
                OfferID               : "",
                IbizAPIName           : "Results",
                URL                   : curr.FILE_URL,
                Name                  : curr.NM_DOC,
                Downloaded            : false
            }
        );
        return prev;
    }, []);
    return tenderResultDocs;
}

/**
 * Creates Tender Results in FAST
 * @param {Array.Object} mappedTenderResults 
 * @returns 
 */
 async insertFASTResults(tx, mappedTenderResults) {
    const { PT_TMTRRES } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
    const { PT_TMTNOFST } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
    const offerStatusses = [];
    
    const uniqueMappedTenderResults = [...new Map(mappedTenderResults.map(item => [item['ID_QP', 'ID_CC_QP'], item])).values()];

    for (const ofsts of uniqueMappedTenderResults){
        //add status
        offerStatusses.push({
            TenderID    : ofsts.TenderID,
            OfferID     : ofsts.OfferID,
            CountryCode : "BR",
            Active      : 1,
            STATUS      : "Results Recorded",
            Date        : new Date().toISOString().slice(0,10)
        });
    }

    // 1. delete Ids before saving to DB
    const tenderResultsWithoutID = uniqueMappedTenderResults.map(so => { 
        const copy = {...so}; 
        delete copy.IBIZ_TECHNICAL_ID;
        delete copy.ID_QP;
        delete copy.ID_CC_QP;
        return copy;
    }); 

    // 2. Insert records into PT_TMTRRES and Update records into PT_TMTNOFST
    console.log(`JOB (${this.jobName }): Inserting IBIZ Tender Result into FAST table (PT_TMTRRES) ...`);
    try {
        tenderResultsWithoutID && tenderResultsWithoutID.length > 0 && await tx.run(INSERT(tenderResultsWithoutID).into(PT_TMTRRES));
        console.log(`JOB (${this.jobName }): Inserting of IBIZ Tender Result into FAST table (PT_TMTRRES) successfully completed.`);
        console.log(`JOB (${this.jobName }): PT_TMTRRES -> created: ${tenderResultsWithoutID.length}`);
        for (const FASTOfferStatus of offerStatusses) {
            await tx.run(UPDATE(PT_TMTNOFST, {TenderID:FASTOfferStatus.TenderID, OfferID:FASTOfferStatus.OfferID, CountryCode:'BR'}).with(FASTOfferStatus));
        }
        console.log(`JOB (${this.jobName }): Updating of Offer Statuses into FAST table (PT_TMTNOFST) successfully completed.`);
        console.log(`JOB (${this.jobName }): PT_TMTNOFST -> updated: ${offerStatusses.length}`);
        return true;
    } catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Inserting of IBIZ Tender Result into FAST table (PT_TMTRRES) failed`);
        console.error(error);
        throw error;
    }
}

/**
 * Creates Opportunity Documents in FAST
 * DocumentsDownload
 * @returns 
 */
 async insertFASTDocumentsDownload(tx, mappedDocs, mappedTenderResults) {
    const { DocumentsDownload } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
    
    // 1. link existing Tenders and Offer with Documents
    for (const docs of mappedDocs) {
        let parentTenderResult = mappedTenderResults.find(tres => tres.IBIZ_TECHNICAL_ID === docs.parent_ID);
        if(!parentTenderResult){return;}
        docs.TenderID = parentTenderResult && parentTenderResult.TenderID;
        docs.OfferID = parentTenderResult && parentTenderResult.OfferID;
    }

    // 2. delete TenderResult ParentId before saving to DB
    const docsWithoutID = mappedDocs.map(doc => { 
        const copy = {...doc}; 
        delete copy.parent_ID; 
        return copy;
    });  

    // 3. Insert records into DocumentsDownload
    console.log(`JOB (${this.jobName }): Inserting IBIZ TenderResult Documents into FAST table (DocumentsDownload) ...`);
    try {
        docsWithoutID && docsWithoutID.length > 0 && await tx.run(INSERT(docsWithoutID).into(DocumentsDownload));
        console.log(`JOB (${this.jobName }): Inserting of IBIZ TenderResult Documents into FAST table (DocumentsDownload) successfully completed.`);
        console.log(`JOB (${this.jobName }): DocumentsDownload -> created: ${docsWithoutID.length}`);
        return true;
    } catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Inserting of IBIZ TenderResult Documents into FAST table (DocumentsDownload) failed`);
        console.error(error);
        throw error;
    }
}

};