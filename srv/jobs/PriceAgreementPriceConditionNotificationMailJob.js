const cds = require('@sap/cds');
const BaseJob = require('./BaseJob');
const Handlebars = require("handlebars");
const cfenv = require("cfenv");
const { tryCatch } = require('ramda');

module.exports = class PriceAgreementPriceConditionNotificationMailJob extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
    }

    /**
     * Triggered when job has started
     */
    //override
    async onTick() {

        const syncDate = new Date();
        console.log(`Processing notification mail for Price Conditions synchronised with SAP on ${syncDate.toDateString()} STARTED ... `);

        try {
            this.db = await cds.connect.to('db');

            // get mail Template
            const templateName = 'PriceAgreementPriceConditionNotificationMail';
            const mailTemplate = await this.getMailTemplate(templateName);

            //get customer prices
            const synchronizedAggregatedData = await this.getSynchronizedCustomerPricesAggregatedData(syncDate);

            // console.dir(pas,{ depth: null });
            if (synchronizedAggregatedData && synchronizedAggregatedData.length > 0) {
                let mail = this.mapDataToMail(mailTemplate,templateName, syncDate)(synchronizedAggregatedData);
                // console.log(mails);
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

        console.log(`Processing notification mail for Price Conditions synchronised with SAP on ${syncDate.toDateString()} FINISHED`);
    }

    /**
     * Fetch Customer Prices which are synchronized but not yet notified.
     * Price Agreement and Tender data is aggregated.
     * @param {Date} date 
     * @returns {Array<Objects>}  A list of aggregated data
     */
    async getSynchronizedCustomerPricesAggregatedData(date) {
        console.log(`Fetching Customer Prices synchronized on ${date.toDateString()}`);
        const {PriceAgreementPriceConditionNotificationMailJobView} = this.db.entities("com.bayer.SXTENDER.PriceAgreementDataViews");
        const tx = this.db.tx();
        return await tx.run(
            SELECT.from(PriceAgreementPriceConditionNotificationMailJobView)
            .where({ 
                     ModifiedAt: { '>=': date.toJSON().substring(0,10)}  // only consider records synced on the day this job runs        
            })
        );    
    }

    mapDataToMail = (template,mail,syncDate) => data => {
        const appEnv = cfenv.getAppEnv();
        const fastUIAppHost = appEnv.url.replace('fast-srv','fastui-app');
        let outbox = [];
        // add/change some fields in the data array
        data.forEach(d => {
            d.EffectiveDate = new Date(d.EffectiveDate).toJSON().substring(0,10),
            d.ExpiryDate = new Date(d.ExpiryDate).toJSON().substring(0,10),
            d.URL = `${fastUIAppHost}/app/index.html#/priceagreements&/pa/PriceAgreements/${d.PriceAgreementId}`
        })

        //get unique created by users, this can be used to filter pa/cp data per user from the data array
        const uniqueUsers = [...new Set(data.map(item => item.CWID))];

        for (let user of uniqueUsers) {
            let dataFilteredByUser = data.filter(d => d.CWID === user);
            if(dataFilteredByUser && dataFilteredByUser.length > 0){
                outbox.push({
                    CountryCode: dataFilteredByUser[0].CountryCode,
                    TenderID: dataFilteredByUser[0].TenderId,
                    OfferID: dataFilteredByUser[0].OfferId,
                    Sender: 'FAST-Admin@bayer.com',
                    Recipients: dataFilteredByUser[0].UserEmail,
                    Subject: template.title,
                    MailBody: this.generateMailBody(template, { 
                        data: { 
                            SyncDate: syncDate.toDateString(), 
                            CustomerPrices: dataFilteredByUser 
                        }
                    }),
                    Sent: false
                });
            }
        }
        outbox.push({
            CountryCode: data[0].CountryCode,
            TenderID: data[0].TenderId,
            OfferID: data[0].OfferId,
            Sender: 'FAST-Admin@bayer.com',
            Recipients: undefined,
            Subject: template.title,
            MailBody: this.generateMailBody(template, { 
                data: { 
                    SyncDate: syncDate.toDateString(), 
                    CustomerPrices: data 
                }
            }),
            Sent: false
        });
        
        if(!outbox || (!outbox[0].MailBody || outbox[0].MailBody === 'undefined')) {
            console.log(`No template found for Customer Price of tender ${outbox[0].TenderID} with countrycode ${outbox[0].CountryCode}`);
            return;
        }
        return outbox;
    }

    async addMailsToOutbox(mail, syncDate) {
        console.log(`Adding notification mail for Price Conditions synchronised with SAP on: ${syncDate.toDateString()}`);
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
        console.log('Get mail templates for price agreements');
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
        // return tx.run(SELECT.one.from(MailTemplate)
        //     .columns('*', 'MailTemplateFile.title', 'MailTemplateFile.content')
        //     .where({ TemplateId: templateId }));
    }
};
