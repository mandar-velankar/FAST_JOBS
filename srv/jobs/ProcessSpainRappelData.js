const cds = require('@sap/cds');
const BaseJob = require('./BaseJob');

module.exports = class processSpainRappelData extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
        this.jobName = jobName.toUpperCase();
    }

 /**
    * Triggered when job has started
    */
    //override
    async onTick() {
        console.log(`JOB (${this.jobName }): Processing Spain Rappel Data ...`);
        const start = new Date().getTime();
        
        this.db = await cds.connect.to('db');
        const tx = this.db.tx();

        try {
            // Fetch data
            const rappelData = await this.getRappelData(tx);

            // Process data
            await this.processRappelData(tx, rappelData);

            // Commit All
            await tx.commit();
            console.log(`JOB (${this.jobName }): Processing Spain RappelData successfully completed.`);
            const end = new Date().getTime();
            const time = end - start;
            console.log(`JOB (${this.jobName }): SUCCESS --> Execution time: ${time} ms`);

        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Processing of Spain RappelData failed.`);
            console.error(error);
            await tx.rollback();
           // throw error;
        }
    }

      /**
     * This method fetches all the Spain Rappel Data from COM_BAYER_SXTENDER_MASTERDATA_SAP_SPAINRAPPEL
     * @returns - A list of rappel data
     */
       async getRappelData(tx) {
        try {
            console.log(`JOB (${this.jobName }): Fetching the Spain Rappel Data from COM_BAYER_SXTENDER_MASTERDATA_SAP_SPAINRAPPEL ...`);
            const { SpainRappel } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
            const result = await tx.run(SELECT.from(SpainRappel));
            return result;
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching of the Spain Rappel Data from COM_BAYER_SXTENDER_MASTERDATA_SAP_SPAINRAPPEL failed`);
            console.error(error);
            throw error;
        }
    }

    
/**
     * This method will process a list of Rappel data by Creating/Updating the following entities
     *  - SpainRappelData
     * After successful processing, the COM_BAYER_SXTENDER_MASTERDATA_SAP_SPAINRAPPEL records will be deleted.
     * @param {[Object]} rappelData 
     */
 async processRappelData(tx, rappelData) {
    console.log(`JOB (${this.jobName }): Processing RappelData ...`);
    try {

        // 0. Mapping - Map RappelData to FAST
        const mappedRappelData = this.mapRappelData(rappelData);

        // 1. Create/update entries in SpainRappelData
        await this.upsertFASTSpainRappelData(tx, mappedRappelData);

        // 2. Delete all records from SpainRappel after successful processing.
        const { SpainRappel } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        await tx.run(DELETE.from(SpainRappel));
        

        console.log(`JOB (${this.jobName }): Processing of RappelData successfully completed.`);

    }catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Processing of RappelData failed.`);
        console.error(error);
        throw error;
    }
}


/**
 * Creates/Updates SpainRappelData in FAST
 * SpainRappelData
 * @returns 
 */
 async upsertFASTSpainRappelData(tx, mappedRappelData) {
    const { SpainRappelData } = this.db.entities("com.bayer.SXTENDER.TransactionalData");

    // 1. get a list of existing RappelData from FAST
    const existingRappelData = await this.getFASTRappelData(tx, mappedRappelData);

    // 2. devide mappedRappelData into New or Changed RappelData
    const FASTNewRappelData = [];
    const FASTChangedRappelData = [];
    for (const rappel of mappedRappelData) {
        let FASTRappelIdx = existingRappelData.findIndex(FASTRappel => FASTRappel.KNUMA === rappel.KNUMA);
        if (FASTRappelIdx > -1) {
            FASTChangedRappelData.push(rappel);
        } else {
            FASTNewRappelData.push(rappel);
        }
    }
    // 3. Upsert records into SpainRappelData
    //Update is one by one: https://answers.sap.com/questions/13676137/bulk-update-in-cap-nodejs.html
    console.log(`JOB (${this.jobName }): Upserting Spain RappelData into FAST table (SpainRappelData) ...`);
    try {
        for (const FASTRappel of FASTChangedRappelData) {
            await tx.run(UPDATE(SpainRappelData, {KNUMA:FASTRappel.KNUMA}).with(FASTRappel));
        }
        FASTNewRappelData && FASTNewRappelData.length > 0 && await tx.run(INSERT(FASTNewRappelData).into(SpainRappelData));
        console.log(`JOB (${this.jobName }): Upserting of Spain RappelData into FAST table (SpainRappelData) successfully completed.`);
        console.log(`JOB (${this.jobName }): SpainRappelData -> created: ${FASTNewRappelData.length}, updated: ${FASTChangedRappelData.length}`);
        return true;
    } catch (error) {
        console.error(`JOB (${this.jobName }): ERROR - Upserting of Spain RappelData into FAST table (SpainRappelData) failed`);
        console.error(error);
        throw error;
    }
}

/**
 * Maps Spain RappelData from SpainRappel to FAST SpainRappelData
 * @param {*} SpainRappel 
 * @returns {[Objects]} SpainRappelData
 */
 mapRappelData(rappelData){

    console.log(`JOB (${this.jobName }): Mapping RappelData to SpainRappelData ...`);
    rappelData = rappelData.reduce((prev, curr, idx, rappelData) => {
        prev.push(
            {
                KNUMA               : curr.KNUMA,
                BONEM               : curr.BONEM,
                DATAB               : curr.DATAB,
                DATBI               : curr.DATBI,
                KUNNR               : curr.SOLD_TO,
                MATNR               : curr.MATNR
            }
        );
        return prev;
    }, []);
    return rappelData;
}

/**
     * Gets a list of existing RappelData from FAST.
     * @param {Array} RappelData 
     * @returns {Array<SpainRappelData>} a list of existing RappelData
     */
 async getFASTRappelData(tx, mappedRappelData) {
    if(!mappedRappelData || mappedRappelData.length === 0){
        console.log(`JOB (${this.jobName }): No RappelData were found in FAST (SpainRappelData)`);
        return [];
    }
    console.log(`JOB (${this.jobName }): Prepare fetching Spain RappelData from SpainRappelData`);

    // get all the KNUMAs from mappedRappelData
    let aKNUMAs = [];
    for (const rappel of mappedRappelData) {
        aKNUMAs.push(rappel.KNUMA);
    }
    console.log(`JOB (${this.jobName }): Fetching RappelData from SpainRappelData ...`);

    // get a list of rappel data entities for given list of KNUMAs
    const { SpainRappelData } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
    const result = await tx.run(SELECT.from(SpainRappelData).where({ KNUMA: { in: aKNUMAs } } ));
    return result;
}

};