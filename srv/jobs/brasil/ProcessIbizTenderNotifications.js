const cds = require('@sap/cds');
const BaseJob = require('../BaseJob');
const Handlebars = require("handlebars");
const cfenv = require("cfenv");
const { tryCatch } = require('ramda');


module.exports = class NewIBIZTenderNotifications extends BaseJob {

    constructor(jobName,jobTime) {
        super(jobName,jobTime);
    }

    /**
     * Triggered when job has started
     */
    //override
    async onTick() {

        console.log('Processing IBIZ notification mails started ...');
        
        let date = new Date(); //get current datetime
        date.setHours(date.getHours() - 1) //only consider records created in the past hour

        try {
            this.db = await cds.connect.to('db'); 

            // get mail Template - direct tenders
            const templateNameDirect = 'IbizNotificationDirectTenders';
            const mailTemplateDirect = await this.getMailTemplate(templateNameDirect);

            // get mail Template - indirect tenders
            const templateNameIndirect = 'IbizNotificationIndirectTenders';
            const mailTemplateIndirect = await this.getMailTemplate(templateNameIndirect);

            //fetch data from db
            let directTenders = await this.getIbizDirectTenders(date);
            let indirectTenders = await this.getIbizIndirectTenders(date);

            //process direct tenders
            if (directTenders && directTenders.length > 0) {
                let mail = this.mapDataToMail(mailTemplateDirect,templateNameDirect, date)(directTenders);
                if(mail){
                    await this.addMailsToOutbox(mail, date);
                } else{
                    console.log(`No mail to add to outbox for template ${templateNameDirect}`);
                }
             } else {
                 console.log(`No notification mail to be send on ${date.toDateString()}`);
             }

             //process indirect tenders
            if (indirectTenders && indirectTenders.length > 0) {
                let mail = this.mapDataToMail(mailTemplateIndirect,templateNameIndirect, date)(indirectTenders);
                if(mail){
                    await this.addMailsToOutbox(mail, date);
                } else{
                    console.log(`No mail to add to outbox for template ${templateNameIndirect}`);
                }
             } else {
                 console.log(`No notification mail to be send on ${date.toDateString()}`);
             }
        } catch (error) {
            console.log(error);
        }

        // when the job has finished, call the stop()
        // this will trigger onComplete method
        // this.stop();
        console.log('Processing IBIZ notification mails finished.');
    }

    async getIbizDirectTenders(date) {
        console.log(`Fetching IBIZ direct tenders`);

        const { PT_TMINST, PT_TMDIST } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const { PT_TMTEND, PT_TMOFRS } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
        const tx = this.db.tx();
        return await tx.run(
            SELECT.from(`${PT_TMTEND.name} as tender`)
            .join(`${PT_TMOFRS.name} as offer`)
            .on({ 
                'offer.TenderID': { '=': 'tender.TenderID' } 
            })
            .join(`${PT_TMINST.name} as institute`)
            .on({ 
                'institute.InstituteID': { '=': 'tender.InstituteID' } 
            })
            .join(`${PT_TMDIST.name} as distributor`)
            .on({ 
                'distributor.DistributorID': { '=': 'offer.DistributorID' } 
            })
            .where({ 
                    'tender.CountryCode': 'BR', 
                    'tender.createdAt': { '>=': `${date.toJSON().substring(0,10)} ${date.getHours()}:${date.getMinutes()}:00.000000000` }, // only consider records created in the past hour
                    'distributor.DistributorName': 'Bayer Brazil'
            })
        ); 
    }

    async getIbizIndirectTenders(date) {
        console.log(`Fetching IBIZ indirect tenders`);

        const { PT_TMINST, PT_TMDIST } = this.db.entities("com.bayer.SXTENDER.MasterData");
        const { PT_TMTEND, PT_TMOFRS } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
        const tx = this.db.tx();
        return await tx.run(
            SELECT.from(`${PT_TMTEND.name} as tender`)
            .join(`${PT_TMOFRS.name} as offer`)
            .on({ 
                'offer.TenderID': { '=': 'tender.TenderID' } 
            })
            .join(`${PT_TMINST.name} as institute`)
            .on({ 
                'institute.InstituteID': { '=': 'tender.InstituteID' } 
            })
            .join(`${PT_TMDIST.name} as distributor`)
            .on({ 
                'distributor.DistributorID': { '=': 'offer.DistributorID' } 
            })
            .where({ 
                    'tender.CountryCode': 'BR', 
                    'tender.createdAt': { '>=': `${date.toJSON().substring(0,10)} ${date.getHours()}:${date.getMinutes()}:00.000000000` }, // only consider records created in the past hour
                    'distributor.DistributorName': { '!=': `Bayer Brazil` }
            })
        ); 
    }

    mapDataToMail = (template,mail,syncDate) => data => {
        const appEnv = cfenv.getAppEnv();
        const fastUIAppHost = appEnv.url.replace('fast-srv','fastui-app');
        
        // add/change some fields in the data array
        data.forEach(d => {
            d.BidDueDate = new Date(d.BidDueDate).toJSON().substring(0,10),
            d.PublicationDate = new Date(d.PublicationDate).toJSON().substring(0,10),
            d.URL = `${fastUIAppHost}/app/index.html#/tender&/t/detail/${d.CountryCode}/${d.TenderID}/${d.OfferID}/__component0---tenderManagementDetailId--basicInformationId//TwoColumnsMidExpanded`
        })
        const outbox = {
            CountryCode: data[0].CountryCode,
            TenderID: data[0].TenderID,
            OfferID: data[0].OfferID,
            Sender: 'FAST-Admin@bayer.com',
            Recipients: undefined,
            Subject: template.title,
            MailBody: this.generateMailBody(template, { 
                data: {
                    Tender: data 
                }
            }),
            Sent: false
        }
        if(!outbox.MailBody || outbox.MailBody === 'undefined') {
            console.log(`No template found for Customer Price of tender ${outbox.TenderID} with countrycode ${outbox.CountryCode}`);
            return;
        }
        return outbox;
    }

    async addMailsToOutbox(mail, syncDate) {
        console.log(`Adding notification mail for IBIZ contracts synchronised with SAP on: ${syncDate.toDateString()}`);
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
        console.log(`Get mail templates for IBIZ notification ${templateId}`);
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