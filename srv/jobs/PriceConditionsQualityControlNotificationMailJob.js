const cds = require('@sap/cds');
const BaseJob = require('./BaseJob');
const core = require('@sap-cloud-sdk/core');
const ServiceHelper = require('../utils/ServiceHelper');
const Handlebars = require("handlebars");
const cfenv = require("cfenv");

module.exports = class PriceConditionsQualityControlNotificationMail extends BaseJob {

    constructor(jobName,jobTime) {
        super(jobName,jobTime);
        this.jobName = jobName.toUpperCase();
        this.startTime = 0;
        this.numberOfRecords = 0;
    }

     /**
     * Triggered when job has started
     */
    //override
    async onTick() {

        console.log(`JOB (${this.jobName }): Processing started ...`);
        this.startTime = new Date().getTime();
        this.db = await cds.connect.to('db');

        try {

            // Fetch data
            const failedCustomerPricesQC = await this.getCustomerPricesQC();
            this.numberOfRecords = failedCustomerPricesQC.length;

            // split data
            const customerPricesQC_ES = failedCustomerPricesQC.filter(c => c.CountryCode === "ES");
            const customerPricesQC_IT = failedCustomerPricesQC.filter(c => c.CountryCode === "IT");

            // Process data
            await this.processCustomerPricesQC(customerPricesQC_ES, "ES");
            await this.processCustomerPricesQC(customerPricesQC_IT, "IT");

            // log finish
            this._finishMessage(this.numberOfRecords);

        } catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Processing failed. \n\nCause: ${error}`);
            //throw error;
        }
    }

    _finishMessage(processed){
        const end = new Date().getTime();
        const time = end - this.startTime;
        console.log(`JOB (${this.jobName }): Processing completed. - Processed: ${processed} - Execution time: ${time} ms`);
    }

    /**
     * Gets CustomerPricesQC records with status 'Failed' and notification e-mail not yet sent
     * @returns {Promise}
     */
    getCustomerPricesQC() {
        const { CustomerPricesQC } = this.db.entities("com.bayer.SXTENDER.PriceAgreementData");
        return SELECT.from(CustomerPricesQC)
                .columns(
                    'ID',
                    'CountryCode',
                    `LTRIM(KUNNR, '0') as InstituteID`, 
                    'Institute.InstituteName', 
                    `LTRIM(MATNR, '0') as MaterialNumber`,
                    'CustomerPrice.ProductPack.PRODUCTPACKNAME as ProductPackName', 
                    'CustomerPrice.PriceAgreement.OfferId',
                    'CustomerPrice.PriceAgreement.TenderId',
                    'KSCHL as PriceCondition',
                    'DATAB as EffectiveDate',
                    'DATBI as ExpiryDate',
                    'KBETR as PriceInFAST',
                    'SAP_KBETR as PriceInSAP',
                    'CustomerPrice.PriceAgreement.ID as Link',
                    'CustomerPrice.PriceAgreement.User.UserEmail as PriceAgreementOwnerEmail'
                )
                .where({Status: ['Failed','NotInSAP'], emailNotificationSent: false})
                .groupBy(
                    'ID',
                    'CountryCode',
                    `LTRIM(KUNNR, '0')`, 
                    `LTRIM(MATNR, '0')`,
                    'CustomerPrice.ProductPack.PRODUCTPACKNAME', 
                    'CustomerPrice.PriceAgreement.OfferId',
                    'CustomerPrice.PriceAgreement.TenderId',
                    'KSCHL',
                    'DATAB',
                    'DATBI',
                    'KBETR',
                    'SAP_KBETR',
                    'CustomerPrice.PriceAgreement.ID',
                    'CustomerPrice.PriceAgreement.User.UserEmail',
                    'KUNNR',
                    'MATNR',
                    'Institute.InstituteName'
                );
    }


    /**
     * Updates CustomerPricesQC emailNotificationSent
     * @param {*} customerPriceQC 
     * @returns {Promise}
     */
    async updateCustomerPriceQCNotification(customerPriceQCId){
        if(!customerPriceQCId) return false;
        const { CustomerPricesQC } = this.db.entities("com.bayer.SXTENDER.PriceAgreementData");
        return UPDATE(CustomerPricesQC).with({emailNotificationSent: true}).where({ ID: customerPriceQCId });
    };


    
    async processCustomerPricesQC(customerPricesQC, countryCode){

        if(!customerPricesQC || customerPricesQC.length <= 0) return;

        // get mail Template
        const templateId = `PriceConditionsQualityControlNotificationMail_${countryCode}`;
        const mailTemplate = await this.getMailTemplate(templateId);

        let mail = this.mapDataToMail(mailTemplate,templateId)(customerPricesQC);
        // console.log(mails);
        if(mail){
            await this.addMailsToOutbox(mail);
            // update QC with notification sent 
            customerPricesQC.forEach(cp => this.updateCustomerPriceQCNotification(cp.ID));
        } else{
            console.log(`No mail to add to outbox for template ${templateId}`);
        }

    }

    async getMailTemplate(templateId) {
        console.log('Fetching mail template ...');
        console.table(templateId);
        const { MailTemplate } = this.db.entities("com.bayer.SXTENDER.AdminData");
        try{
            const result = await SELECT.one.from(MailTemplate)
            .columns('*', 'MailTemplateFile.title', 'MailTemplateFile.content')
            .where({ TemplateId: templateId });
            return result;
        }catch(error){
            console.error(`No mail template found for ${templateId} `, `Cause: ${error}`);
        }
    }


    mapDataToMail = (template,templateId) => data => {
        const appEnv = cfenv.getAppEnv();
        const fastUIAppHost = appEnv.url.replace('fast-srv','fastui-app');
        let outbox = [];
        const recipients = new Set();

        // update the Link with correct path
        data.forEach(d => {
            d.Link = `${fastUIAppHost}/app/index.html#/priceagreements&/pa/PriceAgreements/${d.Link}`;
            recipients.add(d.PriceAgreementOwnerEmail);
        })

        // additional recipients per country
        if(data[0].CountryCode === "IT"){
            recipients.add("andrea.duranti@bayer.com");
            recipients.add("massimo.bettinelli@bayer.com");
        }else if(data[0].CountryCode === "ES"){
            recipients.add("commercialagreements.es@bayer.com");
        }

        outbox.push({
            CountryCode: data[0].CountryCode,
            TenderID: data[0].TenderId,
            OfferID: data[0].OfferId,
            Sender: 'FAST-Admin@bayer.com',
            Recipients: Array.from(recipients).join(";"),
            Subject: template.title,
            MailBody: this.generateMailBody(template, { 
                data: { 
                    CustomerPricesQC: data 
                }
            }),
            Sent: false
        });
        
        if(!outbox || (!outbox[0].MailBody || outbox[0].MailBody === 'undefined')) {
            console.log(`No template found for Customer Price QC of offer ${outbox[0].OfferID} with countrycode ${outbox[0].CountryCode}`);
            return;
        }
        return outbox;
    }

    async addMailsToOutbox(mail, syncDate) {
        console.log(`Adding notification mail for Price Conditions QC ... `);
        const { OutgoingMails } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
        try {
            return await INSERT(mail).into(OutgoingMails);
        } catch (error) {
            console.error(error);
            throw error;
        }
    }

    generateMailBody(mail, data) {
        return Handlebars.compile("" + mail.content)(data);
    }

    



};