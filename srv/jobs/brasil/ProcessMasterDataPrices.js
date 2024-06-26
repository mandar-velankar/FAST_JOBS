const cds = require('@sap/cds');
const BaseJob = require('../BaseJob');

module.exports = class ProcessMasterDataPrices extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
    }
    /**
    * Triggered when job has started
    */
    //override
    async onTick() {
        console.log('Processing Brazil MasterData prices ...');
        this.db = await cds.connect.to('db');
        try {
            const prices = this.mapSAPPricesToFAST((await this.getSAPPrices()));//todo:only keep prices, just for testing iwth one
            await this.updateFASTPrices(prices);
        } catch (error) {
            console.error(`ERROR: Error when processing BrazilPrices, more info on the next lines`);
            console.error(error);
        }
        console.log('Finished processing Brazil MasterData prices ...');
    }
    async getSAPPrices() {
        const tx = this.db.tx();
        console.log(`Start fetching BrazilPrices from SAP table`);
        const { BrazilPrices } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        const result = await tx.run(SELECT.from(BrazilPrices)); //Q: Select everything or specific product? Delete when processing sucessful?
        await tx.commit();
        console.log(`End fetching BrazilPrices from SAP table`);
        return result;
    }
    mapSAPPricesToFAST(prices) {
        console.log(`Start processing BrazilPrices`);
        //filter duplicates
        //convert to the FAST format
        //both in one loop using a set
        let seen = new Set();
        prices = prices.reduce((prev, price, idx, prices) => {
            let k = JSON.stringify(price);
            if (seen.has(k)) {
                return prev;
            }
            seen.add(k);
            let priceZWP0 = {
                CustomerID: price.CLIENTE,
                ProductID: price.CODIGO !== null ? parseInt(price.CODIGO) : null,
                ValidFrom: price.DATA_INI,
                ValidTo: price.DATA_FIM
            };
            let priceZWD4 = { ...priceZWP0 };
            let priceIBRX = { ...priceZWP0 };
            if (price.PRC_PADRAO !== null) {
                priceZWP0.Type = "ZWP0";
                priceZWP0.Value = price.PRC_PADRAO;
                prev.push(priceZWP0);
            }
            if (price.DESC_PADRAO !== null) {    //Q: would this be enough to know if we need to create it in our db?
                priceZWD4.Type = "ZWD4";
                priceZWD4.Value = price.DESC_PADRAO;
                prev.push(priceZWD4);
                priceIBRX.Type = "IBRX";
                priceIBRX.Value = price.DESC_PADRAO;
                prev.push(priceIBRX);
            }
            return prev;
        }, []);
        console.log(`End processing BrazilPrices`);
        return prices;
    }
    async updateFASTPrices(prices) {
        const FASTPrices = await this.getFASTPrices(prices);
        const FASTNewPrices = [];
        const FASTChangedPrices = [];
        console.log(`Prepare update BrazilPrices in FAST table`);
        for (const price of prices) {
            let FASTPriceIdx = FASTPrices.findIndex(FASTPrice =>
                FASTPrice.CustomerID === price.CustomerID &&
                FASTPrice.ProductID === price.ProductID &&
                FASTPrice.ValidFrom === price.ValidFrom &&
                FASTPrice.ValidTo === price.ValidTo &&
                FASTPrice.Type === price.Type);
            if (FASTPriceIdx > -1) {
                FASTChangedPrices.push(price);
            } else {
                FASTNewPrices.push(price);
            }
        }
        //Update is one by one: https://answers.sap.com/questions/13676137/bulk-update-in-cap-nodejs.html

        console.log(`Start update BrazilMasterPrices in FAST table`);
        const { BrazilMasterPrices } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const { BrazilPrices } = this.db.entities("com.bayer.SXTENDER.MasterData.SAP");
        const tx = this.db.tx();
        try {
            for (const FASTPrice of FASTChangedPrices) {
                await tx.run(UPDATE(BrazilMasterPrices).with(FASTPrice).where({
                    CustomerID: FASTPrice.CustomerID,
                    ProductID: FASTPrice.ProductID,
                    ValidFrom: FASTPrice.ValidFrom,
                    ValidTo: FASTPrice.ValidTo,
                    Type: FASTPrice.Type
                }));
            }
            FASTNewPrices && FASTNewPrices.length > 0 && await tx.run(INSERT(FASTNewPrices).into(BrazilMasterPrices));
            console.log(`Updated ${FASTChangedPrices.length} and inserted ${FASTNewPrices.length} rows`);
            console.log(`End update BrazilMasterPrices in FAST table`);
            console.log(`Delete from BrazilPrices in FAST table`);
            await tx.run(DELETE.from(BrazilPrices));
            console.log(`Commit all!`);
            await tx.commit();
            return true;
        } catch (error) {
            console.error(`ERROR: during update BrazilPrices in FAST table`);
            console.error(error);
            console.log(`Rollback all!`);
            await tx.rollback();
            throw error;
        }
    }
    async getFASTPrices(prices) {
        if (!prices || prices.length === 0) {
            console.log(`No SAP Prices to be updated -> No FAST Prices to be fetched`);
            return [];
        }
        const tx = this.db.tx();
        console.log(`Prepare fetching BrazilPrices from FAST table`);
        let custIDs = [];
        let productIDs = [];
        let custHasNull = false;
        let prodHasNull = false;
        for (const price of prices) {
            if (price.CustomerID === null) {
                custHasNull = true;
            }else if(custIDs.findIndex(id => id ===price.CustomerID) === -1){
                custIDs.push(price.CustomerID);
            }
            if (price.ProductID === null) {
                prodHasNull = true;
            }else if(productIDs.findIndex(id => id ===price.ProductID) === -1){
                productIDs.push(price.ProductID);
            }
        }
        let where = [];
        // where += ``;
        if (custIDs && custIDs.length > 0) {
            where.push('(');
            // where.CustomerID = {in: custIDs};
            where.push({ref:['CustomerID']});
            where.push('in');
            where.push({val:custIDs});
        }
        if (custHasNull) {
            if (where.length > 0) {
                where.push('OR');
            }else{
                where.push('(');
            }
            where.push({ref:['CustomerID']});
            where.push('is');
            where.push('null');
        }
        if (where.length > 0) {
            where.push(')');
        }
        if (productIDs && productIDs.length > 0) {
            if (where.length > 0) {
                where.push('AND');
                where.push('(');
            }
            where.push({ref:['ProductID']});
            where.push('in');
            where.push({val:productIDs});
        }
        if (prodHasNull) {
            if (productIDs && productIDs.length > 0) {
                where.push('OR');
            }else{
                where.push('(');
            }
            where.push({ref:['ProductID']});
            where.push('is');
            where.push('null');
        }
        if ((productIDs && productIDs.length > 0) || prodHasNull) {
            where.push(')');
        }
        console.log(`Start fetching BrazilPrices from FAST table`);
        const { BrazilMasterPrices } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const result = await tx.run(SELECT.from(BrazilMasterPrices).where(where));
        await tx.commit();
        console.log(`End fetching BrazilPrices from FAST table`);
        return result;
    }
};