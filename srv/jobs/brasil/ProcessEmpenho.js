const cds = require('@sap/cds');
const BaseJob = require('../BaseJob');

module.exports = class processEmpenho extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
        this.jobName = jobName.toUpperCase();
    }


    /**
    * Triggered when job has started
    */
    //override
    async onTick() {
        console.log(`JOB (${this.jobName }): Processing Ibiz Empenhos ...`);
        const start = new Date().getTime();
        
        this.db = await cds.connect.to('db');
        const tx = this.db.tx();

        try {
            // Fetch data
            const empenhos = await this.getEmpenhos(tx);
            const existingContractsInFAST = await this.getContracts(tx);
            const salesOrderStatuses = await this.getSalesOrderStatuses(tx);

            const empenhoParentIDs = empenhos.map(empenho => empenho.ID);
            const empenhoItems = await this.getEmpenhoItems(tx, empenhoParentIDs);
            const empenhoDocs = await this.getEmpenhoDocs(tx, empenhoParentIDs); 

            // Process data
            if(empenhos.length > 0){
                await this.processEmpenhos(tx, empenhos, empenhoItems, empenhoDocs, existingContractsInFAST, salesOrderStatuses);
            }

            // Commit All
            await tx.commit();
            console.log(`JOB (${this.jobName }): Processing Ibiz Empenhos successfully completed.`);
            const end = new Date().getTime();
            const time = end - start;
            console.log(`JOB (${this.jobName }): SUCCESS --> Execution time: ${time} ms`);

        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Processing of Ibiz Empenhos failed.`);
            console.error(error);
            await tx.rollback();
            //throw error;
        }
    }

        /**
     * This method fetches all the Ibiz empenhos from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZEMPENHOS
     * @returns - A list of Ibiz empenhos
     */
         async getEmpenhos(tx) {
            try {
                console.log(`JOB (${this.jobName }): Fetching Ibiz empenhos from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZEMPENHOS ...`);
                const { IbizEmpenhos } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
                const result = await tx.run(SELECT.from(IbizEmpenhos));
                return result;
            }catch (error) {
                console.error(`JOB (${this.jobName }): ERROR - Fetching of Ibiz empenhos from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZEMPENHOS failed`);
                console.error(error);
                throw error;
            }
        }

        /**
     * This method fetches all the Ibiz empenho items from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZCCSEMPENHOSITEMS
     * @returns - A list of Ibiz empenho items
     */
     async getEmpenhoItems(tx, parentIDs) {
        if(!parentIDs || parentIDs.length <= 0) {
            console.log("No Parent Itmes found");
            return [];
        }
        try {
            console.log(`JOB (${this.jobName }): Fetching Ibiz empenho items from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZCCSEMPENHOSITEMS ...`);
            const { IbizCcsEmpenhosItems } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const result = await tx.run(SELECT.from(IbizCcsEmpenhosItems).where({'parent_ID': { in: parentIDs }}));
            return result;
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching of Ibiz empenho items from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZCCSEMPENHOSITEMS failed`);
            console.error(error);
            throw error;
        }
    }

     /**
     * This method fetches all the Ibiz empenho Documents from COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZDOCS
     * @returns - A list of Ibiz empenho Documents
     */
      async getEmpenhoDocs(tx, parentIDs) {
        if(!parentIDs || parentIDs.length <= 0) {
            console.log("No Parent Itmes found");
            return [];
        }
        try {
            console.log(`JOB (${this.jobName }): Fetching Ibiz empenho Documents from COM_BAYER_SXTENDER_MASTERDATA_SAP_IbizDocs ...`);
            const { IbizDocs } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const result = await tx.run(SELECT.from(IbizDocs).where({'Empenhos_ID': { in: parentIDs } }));
            return result;
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching of Ibiz empenho Documents from COM_BAYER_SXTENDER_MASTERDATA_SAP_IbizDocs failed`);
            console.error(error);
            throw error;
        }
    }

    /**
     * This method fetches all the existing Contracts from COM_BAYER_SXTENDER_BRAZILCONTRACTINGDATA_CONTRACTS
     * @returns - 
     */
     async getContracts(tx) {
        try {
            console.log(`JOB (${this.jobName }): Fetching Contracts from COM_BAYER_SXTENDER_BRAZILCONTRACTINGDATA_CONTRACTS ...`);
            const { Contracts } = this.db.entities("com.bayer.SXTENDER.BrazilContractingData");
            const result = await tx.run(SELECT.from(Contracts));
            return result;
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching of Contracts from COM_BAYER_SXTENDER_BRAZILCONTRACTINGDATA_CONTRACTS failed`);
            console.error(error);
            throw error;
        }
    }

/**
     * This method fetches all the existing Contract Products from COM_BAYER_SXTENDER_BRAZILCONTRACTINGDATA_CONTRACTPRODUCTS
     * @returns - 
     */
 async getContractProducts(tx) {
    try {
        console.log(`JOB (${this.jobName }): Fetching Contract Products from COM_BAYER_SXTENDER_BRAZILCONTRACTINGDATA_CONTRACTPRODUCTS ...`);
        const { ContractProducts } = this.db.entities("com.bayer.SXTENDER.BrazilContractingData");
        const result = await tx.run(SELECT.from(ContractProducts));
        return result;
    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Fetching of Contract Products from COM_BAYER_SXTENDER_BRAZILCONTRACTINGDATA_CONTRACTPRODUCTS failed`);
        console.error(error);
        throw error;
    }
}

/**
     * This method fetches all the SalesOrderStatus from COM_BAYER_SXTENDER_ADMINDATA_SALESORDERSTATUS
     * @returns -
     */

 async getSalesOrderStatuses(tx) {

    const { SalesOrderStatus } = this.db.entities("com.bayer.SXTENDER.AdminData");
    console.log(`JOB (${this.jobName }): Fetching data from ${SalesOrderStatus.name} ...`);

    try {
        return await tx.run(SELECT.from(SalesOrderStatus));
    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Fetching data from ${SalesOrderStatus.name} failed`);
        console.error(error);
        throw error;
    }
}

/**
     * This method will process a list of Ibiz Empenhos by Creating/Updating the following entities
     *  - SalesOrders
     *  - SalesOrderProducts
     *  - DocumentsDownload
     * After successful processing, the records will be deleted from the following buffer tables
     *  - COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZEMPENHOS
     *  - COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZCCSEMPENHOSITEMS
     *  - COM_BAYER_SXTENDER_MASTERDATA_SAP_IBIZDOCS
     * @param {[Object]} empenhos 
     */
 async processEmpenhos(tx, empenhos, empenhoItems, empenhoDocs, existingContractsInFAST, salesOrderStatuses) {
    console.log(`JOB (${this.jobName }): Processing Ibiz Empenhos ...`);
    try {

        // 0. Mapping - Map IBIZ Empehnos to FAST
        const mappedSalesOrders = this.mapIbizEmpenhostoFASTSalesOrders(empenhos, existingContractsInFAST, salesOrderStatuses);
        const mappedSalesOrderProducts = this.mapIbizEmpenhostoFASTSalesOrderProducts(empenhoItems);
        const mappedDocs = this.mapIbizEmpenhoDocstoFASTDocumentsDownload(empenhoDocs);

        // 1. Create/update entries in SalesOrders
        await this.insertFASTSalesOrders(tx, mappedSalesOrders);

        // 2. Create/update entries in SalesOrderProducts
        await this.insertFASTSalesOrderProducts(tx, mappedSalesOrders, mappedSalesOrderProducts);

        // 3. Create/update entries in DocumentsDownload
        await this.insertFASTDocumentsDownload(tx, mappedDocs, mappedSalesOrders);  

        // 4. Delete all records from IbizEmpenhos, IbizCcsEmpenhosItems and IbizDocs after successful processing.
        const { IbizEmpenhos } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        await tx.run(DELETE.from(IbizEmpenhos));
        const { IbizCcsEmpenhosItems } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        const parentIDs = mappedSalesOrderProducts.map(pr => pr.parent_ID);
        Array.isArray(parentIDs) && parentIDs.length > 0 && await tx.run(DELETE.from(IbizCcsEmpenhosItems).where({parent_ID: {in: parentIDs}}));
        const { IbizDocs } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        const docParentIDs = mappedDocs.map(pr => pr.parent_ID);
        Array.isArray(docParentIDs) && docParentIDs.length > 0 && await tx.run(DELETE.from(IbizDocs).where({Empenhos_ID: {in: docParentIDs}}));

        console.log(`JOB (${this.jobName }): Processing of Ibiz Empenhos successfully completed.`);

    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Processing of Ibiz Empenhos failed.`);
        console.error(error);
        throw error;
    }
}

/**
     * Maps Ibiz Empenhos fields from Ibiz Empenhos to FAST SalesOrders
     * @param {[Objects]} ibizEmpenhos 
     * @returns {[Objects]} mapped sales orders
     */
 mapIbizEmpenhostoFASTSalesOrders(empenhos, existingContractsInFAST, salesOrderStatuses) {

    console.log(`JOB (${this.jobName }): Mapping IBIZ Empenhos to SalesOrders ...`);
    empenhos = empenhos.reduce((prev, curr, idx, empenhos) => {
        const salesOrderStatus = salesOrderStatuses.find(cs => cs.Status.toLowerCase() === "new ibiz");
        const contracts = (existingContractsInFAST.find(cntrct => cntrct.IbizContractID === curr.ID_CONTRATO && cntrct.ContractNumber !== null));
        const instituteID = contracts && contracts.InstituteID || null;
        const tenderID = contracts && contracts.TenderID || null;
        const offerID = contracts && contracts.OfferID || null;
        const distributorID = contracts && contracts.DistributorID || null;
        prev.push(
            {
                TenderID                : tenderID, // this ID will be used to create relationship with the items and will be deleted afterwards
                OfferID                 : offerID, // this ID will be used to create relationship with the items and will be deleted afterwards
                ID                      : curr.ID,
                EmpenhoID               : curr.ID_EMPENHO,
                InstituteID             : instituteID,                               
                DistributorID           : distributorID,                                 
                EmpenhoNumber           : curr.NU_EMPENHO,
                SalesOrderNumber        : null,
                IbizProcessNumber       : curr.NM_PROCESSO,
                CommitmentDate          : curr.DT_EMPENHO,
                CommitmentDeliveryDate  : curr.DT_ENTREGA,
                CommitmentCreationDate  : curr.CREATED_AT,
                StatusID                : salesOrderStatus.ID, 
                createdBy               : "IBIZ",
                modifiedBy              : "IBIZ",
                Contract_ID             : contracts.ID
            }
        );
        return prev;
    }, []);
    return empenhos;
}

/**
     * Maps Ibiz EmpenhoItems fields from Ibiz EmpenhosItems to FAST SalesOrderProducts
     * @param {[Objects]} ibizEmpenhoItems 
     * @returns {[Objects]} mapped salesorder products
     */
 mapIbizEmpenhostoFASTSalesOrderProducts(empenhoItems) {

    console.log(`JOB (${this.jobName }): Mapping IBIZ Empenho Items to SalesOrderProducts ...`);
    empenhoItems = empenhoItems.reduce((prev, curr, idx, empenhoItems) => {
     
        prev.push(
            {
                parent_ID                : curr.parent_ID,
                ProductPackID            : "",                      //map the field during upsert
                OfferID                  : "",                      //map the field during upsert
                RequestedQty             : curr.NU_QTDE_UNITARIA,
                RequestedDeliveryDate    : "",                      //map the field during upsert
                IbizEmpenhoProductID     : curr.ID_CC_EMPENHO,
                IbizContractProductID    : curr.ID_CC_CONTRATO,
                SalesOrderPrice          : curr.VLR_UNITARIO,
                LotID                    : "",                      //map the filed during upsert
                createdBy                : "IBIZ",
                modifiedBy               : "IBIZ",
                SalesOrder_ID            : ""                       //map the field during upsert
            }
        );
        return prev;
    }, []);
    return empenhoItems;

}

/**
 * Maps Ibiz Empenhos Documents from Ibiz Empenhos to FAST DocumentsDownload
 * @param {*} IbizEmpenhoDocuments 
 * @returns {[Objects]} documentsDownload
 */
 mapIbizEmpenhoDocstoFASTDocumentsDownload(empenhoDocs){

    console.log(`JOB (${this.jobName }): Mapping IBIZ Empenhos Documents to DocumentsDownload ...`);
    empenhoDocs = empenhoDocs.reduce((prev, curr, idx, empenhoDocs) => {
        prev.push(
            {
                parent_ID             : curr.Empenhos_ID,
                DocID                 : curr.ID_DOC,
                DocCreatedAt          : curr.CREATED_AT,
                NameTag               : curr.NM_TAG,
                CountryCode           : "BR",
                TenderID              : "",
                OfferID               : "",
                IbizAPIName           : "Sales Order",
                URL                   : curr.FILE_URL,
                Name                  : curr.NM_DOC,
                Downloaded            : false
            }
        );
        return prev;
    }, []);
    return empenhoDocs;
}

/**
 * Creates or Updates SalesOrders in FAST
 * @param {Array.Object} Mapped SalesOrders 
 * @returns 
 */
 async insertFASTSalesOrders(tx, mappedSalesOrders) {
    const { SalesOrders } = this.db.entities("com.bayer.SXTENDER.BrazilContractingData");

    // 1. delete Ids before saving to DB
    const salesOrdersWithoutID = mappedSalesOrders.map(so => { 
        const copy = {...so}; 
        delete copy.TenderID;
        delete copy.OfferID;
        return copy;
    }); 

    // 2. Insert records into SalesOrders
    console.log(`JOB (${this.jobName }): Inserting IBIZ Empenho into FAST table (SalesOrders) ...`);
    try {
        salesOrdersWithoutID && salesOrdersWithoutID.length > 0 && await tx.run(INSERT(salesOrdersWithoutID).into(SalesOrders));
        console.log(`JOB (${this.jobName }): Inserting of IBIZ Empenho into FAST table (SalesOrders) successfully completed.`);
        console.log(`JOB (${this.jobName }): SalesOrders -> created: ${salesOrdersWithoutID.length}`);
        return true;
    } catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Inserting of IBIZ Empenho into FAST table (SalesOrders) failed`);
        console.error(error);
        throw error;
    }
}

/**
 * Creates or Updates SalesOrderProducts in FAST
 * @param {Array.Object} Mapped SalesOrderProducts
 * @returns 
 */
 async insertFASTSalesOrderProducts(tx, mappedSalesOrders, mappedSalesOrderProducts) {
    const { SalesOrderProducts } = this.db.entities("com.bayer.SXTENDER.BrazilContractingData");
    const existingContractProductsInFAST = await this.getContractProducts(tx);
    
    // 1. link parentSalesOrder and existing contract with SalesOrderProducts
    for (const soprd of mappedSalesOrderProducts) {
        let parentSalesOrder = mappedSalesOrders.find(so => so.ID === soprd.parent_ID);
        const contractProducts = (existingContractProductsInFAST.find(ctrtprd => ctrtprd.IbizContractProductID === soprd.IbizContractProductID));
        soprd.OfferID = parentSalesOrder.OfferID;
        soprd.RequestedDeliveryDate = parentSalesOrder.CommitmentDeliveryDate;
        soprd.ProductPackID = contractProducts.ProductPackID;
        soprd.SalesOrder_ID = parentSalesOrder.ID;
        soprd.LotID = contractProducts.LotID;
    }

    // 2. delete Ids before saving to DB
    const salesOrderProductsWithoutID = mappedSalesOrderProducts.map(soprd => { 
        const copy = {...soprd}; 
        delete copy.parent_ID;
        return copy;
    }); 

    // 3. Insert records into SalesOrderProducts
    console.log(`JOB (${this.jobName }): Inserting IBIZ EmpenhoItems into FAST table (SalesOrderProducts) ...`);
    try {
        salesOrderProductsWithoutID && salesOrderProductsWithoutID.length > 0 && await tx.run(INSERT(salesOrderProductsWithoutID).into(SalesOrderProducts));
        console.log(`JOB (${this.jobName }): Inserting of IBIZ EmpenhoItems into FAST table (SalesOrderProducts) successfully completed.`);
        console.log(`JOB (${this.jobName }): SalesOrderProducts -> created: ${salesOrderProductsWithoutID.length}`);
        return true;
    } catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Inserting of IBIZ EmpenhoItems into FAST table (SalesOrderProducts) failed`);
        console.error(error);
        throw error;
    }
}

/**
 * Creates Opportunity Documents in FAST
 * DocumentsDownload
 * @returns 
 */
 async insertFASTDocumentsDownload(tx, mappedDocs, mappedSalesOrders) {
    const { DocumentsDownload } = this.db.entities("com.bayer.SXTENDER.TransactionalData");

    // 1. link existing Tenders and Offer with Documents
    for (const docs of mappedDocs) {
        let parentSalesOrder = mappedSalesOrders.find(ofr => ofr.ID === docs.parent_ID);
        docs.TenderID = parentSalesOrder.TenderID;
        docs.OfferID = parentSalesOrder.OfferID;
    }

    // 2. delete Empenho ParentId before saving to DB
    const docsWithoutID = mappedDocs.map(doc => { 
        const copy = {...doc}; 
        delete copy.parent_ID; 
        return copy;
    });  

    // 3. Insert records into DocumentsDownload
    console.log(`JOB (${this.jobName }): Inserting IBIZ Empenho Documents into FAST table (DocumentsDownload) ...`);
    try {
        docsWithoutID && docsWithoutID.length > 0 && await tx.run(INSERT(docsWithoutID).into(DocumentsDownload));
        console.log(`JOB (${this.jobName }): Inserting of IBIZ Empenho Documents into FAST table (DocumentsDownload) successfully completed.`);
        console.log(`JOB (${this.jobName }): DocumentsDownload -> created: ${docsWithoutID.length}`);
        return true;
    } catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Inserting of IBIZ Empenho Documents into FAST table (DocumentsDownload) failed`);
        console.error(error);
        throw error;
    }
}

};