const cds = require('@sap/cds');
const BaseJob = require('./BaseJob');
const moment = require('moment');
const Handlebars = require("handlebars");
const cfenv = require("cfenv");

module.exports = class ProcessHematologyResultsRecordReminderMail extends BaseJob {
    constructor(jobName,jobTime) {
        super(jobName,jobTime);
    }
    
    /**
     * Triggered when job has started
     */
    //override
    async onTick() {

        console.log(`JOB (${this.jobName }): Processing Hematology Results Record status reminder started...`);

        try {
            this.db = await cds.connect.to('db'); 

            const tx = this.db.tx()
            await this.processSendReminder(tx);
            await tx.commit();
        } catch (error) {
            await tx.rollback();
            console.log(`JOB (${this.jobName }): ERROR - Process of sending notifications failed.`)
            console.log(error);
        }

        // when the job has finished, call the stop()
        // this will trigger onComplete method
        // this.stop();
        console.log(`JOB (${this.jobName }): Processing Hematology Results Record status reminder finished.`);
    }

    async processSendReminder (tx) {
        const offers = await this.getOffers(tx);
        const users = await this.getUsers(tx);
        const template = await this.getNotificationMailTemplate(tx, "HematologyResultRecordedOfferStatusReminder");

        const today = moment().startOf('day'); // Strip time part
        const mails = [];

        if (offers.length === 0) {
            throw `JOB (${this.jobName }): Offers not found.`;
        }

        if (!template || !template.content) {
            throw `JOB (${this.jobName }): Notification template not found.`;
        }

        console.log(`JOB (${this.jobName }): Mapping mails`);
        for (const offer of offers) {
            const { Custom_Date_3, SubmittedBy } = offer;
            const recipient = users.find(user => user.UserID === SubmittedBy);
            const awardDate = moment(Custom_Date_3).startOf('day');
            const firstReminderDate = awardDate.clone().add(1, 'day');

            if (today.isSameOrAfter(firstReminderDate) && recipient) {
                const daysSinceFirstReminder = today.diff(firstReminderDate, 'days');
                if (daysSinceFirstReminder % 3 === 0) {
                    mails.push(this.mapDataToMail(template, {
                        recipient,
                        offer
                    }));
                }
            }

        }
        console.log(`JOB (${this.jobName }): Mapping process finished`);

        if (mails.length > 0) {
            await this.addMailsToOutbox(tx, mails);
            console.log(`JOB (${this.jobName }): Mails successfully saved`);
        }else {
            console.log(`JOB (${this.jobName }): No mapped mails found`);
        }
    }

    /**
    * fetches all existing hematology offers which result is not recorded yet
    * @returns - A list of offers
    */

    async getOffers(tx) {
        const { PT_TMOFRS } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
        console.log(`JOB (${this.jobName }): Fetching offers from ${PT_TMOFRS.name} ...`);
        try {
            return tx.run(SELECT.from(PT_TMOFRS)
                .columns('*', 'Tender.Institute.InstituteName')
                .where({
                    CountryCode: { 
                        like: '%-HM%'
                    },
                    'OfferStatus.STATUS': 'Quotation Submitted' 
            }));
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching data from ${PT_TMOFRS.name} failed`);
            console.error(error);
            throw error;
        }
    }

    /**
    * fetches users list to identify who is the recipient
    * @returns - A list of users
    */

    async getUsers(tx) {
        const { PT_TMUSER } = this.db.entities("com.bayer.SXTENDER.AdminData");
        console.log(`JOB (${this.jobName }): Fetching users data from ${PT_TMUSER.name} ...`);
        try {
            return tx.run(SELECT.from(PT_TMUSER));
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching users data from ${PT_TMUSER.name} failed`);
            console.error(error);
            throw error;
        }
    }

     /**
    * fetches notification mail template
    */

    async getNotificationMailTemplate(tx, templateId) {
        const { MailTemplate } = this.db.entities("com.bayer.SXTENDER.AdminData");
        console.log(`JOB (${this.jobName }): Fetching notification mail template from ${MailTemplate.name} ...`);
        try {
            return tx.run(SELECT.one.from(MailTemplate)
			.columns('*', 'MailTemplateFile.title', 'MailTemplateFile.content')
			.where({ TemplateId: templateId }));
        }catch (error) {
            console.error(`JOB (${this.jobName }): ERROR - Fetching data from ${MailTemplate.name} failed`);
            console.error(error);
            throw error;
        }
    }

    async addMailsToOutbox(tx, mails) {
        const { OutgoingMails } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
        console.log(`JOB (${this.jobName }): Saving mails into ${OutgoingMails.name}`);
        try {
            return tx.run(INSERT(mails).into(OutgoingMails));
        } catch (error) {
            console.error(error);
            throw `JOB (${this.jobName }): ERROR - Failed to save data into ${OutgoingMails.name}`;
        }
    };

    mapDataToMail = function (template, data) {
        const appEnv = cfenv.getAppEnv();
        const fastUIAppHost = appEnv.url.replace('fast-srv','fastui-app');
        const CountryCode = data.offer.CountryCode;
        const TenderID = data.offer.TenderID;
        const OfferID = data.offer.OfferID;
        
        return {
            CountryCode: CountryCode,
            TenderID: TenderID,
            OfferID: OfferID,
            Sender: 'FAST-Admin@bayer.com',
            Recipients: data.recipient.UserEmail,
            Subject: `Pending awards record on Offer ${OfferID}`,
            MailBody: this.generateMailBody(template, {
                data: { 
                    Offer: data.offer,
                    ReceipientName: data.recipient.UserName,
                    OfferLink: `${fastUIAppHost}/app/index.html#/standardtender&/stdt/detail/${CountryCode}/All/${TenderID}/${OfferID}/Awards`
                }
            }),
            Sent: false
        };
    }
   
    generateMailBody = function (mail, data) {
        return Handlebars.compile("" + mail.content)(data);
    }
}