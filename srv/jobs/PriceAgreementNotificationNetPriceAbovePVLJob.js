const cds = require('@sap/cds');
const BaseJob = require('./BaseJob');
const Handlebars = require("handlebars");
const cfenv = require("cfenv");
const { tryCatch } = require('ramda');
const ServiceHelper = require('../utils/ServiceHelper');


module.exports = class PriceAgreementNotificationNetPriceAbovePVLJob extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
    }

    /**
     * Triggered when job has started
     */
    //override
    async onTick() {
        const syncDate = new Date();
        console.log(`Processing notification mail for Net Price Above PVL on ${syncDate.toDateString()} STARTED ... `);

        try {
            this.db = await cds.connect.to('db');

            // get mail Template
            const templateName = 'PriceAgreementNotificationAbovePVLMail';
            const mailTemplate = await this.getMailTemplate(templateName);

            //get customer prices
            const PriceAgreementService = await cds.connect.to ('PriceAgreementService');
            let synchronizedAggregatedData = await PriceAgreementService.run(this.getAggregatedDataQuery());

            if (synchronizedAggregatedData && synchronizedAggregatedData.length > 0) {
                let mail = this.mapDataToMail(mailTemplate,templateName, syncDate)(synchronizedAggregatedData);
                if(mail){
                    await this.addMailsToOutbox(mail, syncDate);
                } else{
                    console.log(`No mail to add to outbox for template ${templateName}`);
                }
             } else {
                 console.log(`No notification mail to be send on ${syncDate.toDateString()}`);
             }
        } catch (error) {
            console.error(error);
        }

        console.log(`Processing notification mail for Net Price Above PVL on ${syncDate.toDateString()} FINISHED`);
    }

    /**
     * Fetch Customer Prices which are synchronized but not yet notified.
     * Price Agreement and Tender data is aggregated.
     * @param {Date} date 
     * @returns {Array<Objects>}  A list of aggregated data
     */
    getAggregatedDataQuery() {
        console.log(`Build query for Aggregated Data for net prices below floor prices`);

        const {
            PriceAgreementsMasterView
        } = cds.entities('PriceAgreementService');

        return SELECT.from(PriceAgreementsMasterView, pa => {
            pa('*'),
            pa.Tender(tender => {
                tender('*'),
                tender.User('*')
            }),
            pa.Product(product => {
                product('*'),
                product.ProductPack('*')
            }),
            pa.Institute('*'),
            pa.Materials('*'),
            pa.CustomerPrices('*'),
            pa.ConsumerPrice('*'),
            pa.OfferProduct('*'),
            pa.Deliveries('*'),
            pa.FOC('*'),
            pa.MaterialsFOC('*'),
            pa.Candidates('*'),
            pa.PriceConditions(pc => {
                pc('*'),
                pc.PriceConditionClassification('*'),
                pc.DiscountCondition('*'),
                pc.FreeGoodsOther('*'),
                pc.RoyalDecreePercentage('*'),
                pc.Settlement('*')
            }),
            pa.SettlementDates('*'),
            pa.MasterPrices('*'),
            pa.User('*')
        }).where({CountryCode: 'ES', hasNewYLAP: 3, hasNewYLLP: 3, isCancelled: false});
    }

    mapDataToMail = (template,mail,syncDate) => data => {
        const appEnv = cfenv.getAppEnv();
        const fastUIAppHost = appEnv.url.replace('fast-srv','fastui-app');
        let outbox = [];
        // add/change some fields in the data array
        data = data.filter(d => d.isCancelled === false && d.Expired === false);
        data.forEach(d => {
            let priceConditions = d.PriceConditions?.filter(pc => pc.PriceConditionClassification.ConditionType === 'Precio Neto'); //we should only get precio neto conditions for net price above pvl

            if(priceConditions && priceConditions.length > 0){
                d.PvlOld = d.PriceConditions[0]?.PVL,
                d.PvlNew = d.MasterPrices.YLLP,
                d.NetPrice = priceConditions[0]?.NetPriceWithoutTaxBeforeDeductionRD,
                d.ConditionType = priceConditions[0]?.PriceConditionClassification.ConditionType,
                d.CustomerID = d.Institute.CustomerID,
                d.InstituteName = d.Institute.InstituteName,
                d.MaterialNumber = d.Materials[0].SKUCode,
                d.PRODUCTPACKNAME = d.Product.ProductPack.PRODUCTPACKNAME,
                d.URL = `${fastUIAppHost}/app/index.html#/priceagreements&/pa/PriceAgreements/${d.ID}`,
                d.include = true
            } else {
                d.include = false
            }
        })

        //get unique created by users, this can be used to filter pa/cp data per user from the data array
        const uniqueUsers = [...new Set(data.map(item => item.Tender.User.CWID))];

        for (let user of uniqueUsers) {
            let dataFilteredByUser = data.filter(d => d.Tender.User.CWID === user && d.include === true);
            if(dataFilteredByUser && dataFilteredByUser.length > 0){
                outbox.push({
                    CountryCode: dataFilteredByUser[0].CountryCode,
                    TenderID: dataFilteredByUser[0].TenderId,
                    OfferID: dataFilteredByUser[0].OfferId,
                    Sender: 'FAST-Admin@bayer.com',
                    Recipients: dataFilteredByUser[0].Tender.User.UserEmail,
                    Subject: template.title,
                    MailBody: this.generateMailBody(template, {
                        data: { 
                            SyncDate: syncDate.toDateString(), 
                            PriceAgreements: dataFilteredByUser 
                        }
                    }),
                    Sent: false
                });
            }
        }
        
        if(!outbox || (!outbox[0].MailBody || outbox[0].MailBody === 'undefined')) {
            console.log(`No template found for Net Price Above PVL ${outbox[0].TenderID} with countrycode ${outbox[0].CountryCode}`);
            return;
        }
        return outbox;
    }

    async addMailsToOutbox(mail, syncDate) {
        console.log(`Adding notification mail for Net Price Above PVL sent on: ${syncDate.toDateString()}`);
        const { OutgoingMails } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
        const tx = this.db.tx();
        try {
            const mailsResult = await tx.run(INSERT(mail).into(OutgoingMails));
            await tx.commit();
            return mailsResult;
        } catch (error) {
            console.error(error);
            await tx.rollback();
            throw error;
        }
    }

    generateMailBody(mail, data) {
        return Handlebars.compile("" + mail.content)(data);
    }

    async getMailTemplate(templateId) {
        console.log('Get mail templates for Net Price Above PVL');
        console.table(templateId);
        const tx = cds.tx();
        const { MailTemplate } = this.db.entities("com.bayer.SXTENDER.AdminData");
        try{
            const result = await tx.run(SELECT.one.from(MailTemplate)
            .columns('*', 'MailTemplateFile.title', 'MailTemplateFile.content')
            .where({ TemplateId: templateId }));
            await tx.commit();
            return result;
        }catch(error){
            console.error("No mail template found");
            await tx.rollback();
            return [];
        }
    }
};