const cds = require('@sap/cds');
const BaseJob = require('./BaseJob');
const Handlebars = require("handlebars");
const cfenv = require("cfenv");

class PriceAgreementExpiredMailJob extends BaseJob {

    constructor(jobName, jobTime) {
        super(jobName, jobTime);
    }

        //EHQUT-CR6
    async onTick() {

        console.log('Processing mails for Cancelled Price Agreements started ...');

        try {
            this.db = await cds.connect.to('db');
            const mailRuns = [{
                expiryDate: this.getExpiredDate(),
                template: 'PriceAgreementExpiredMail'
            },];
                        
            const mailTemplates = await this.getMailTemplates(mailRuns.map(mailRun=>mailRun.template));
            for (let mailRun of mailRuns) {
                let pas = await this.getPriceAgreementsExpired(mailRun.expiryDate);
                               
                if (pas && pas.length > 0) {
                    let mails = this.mapPriceAgreementsToMails(mailTemplates,mailRun.template)(pas);
                    
                    if(mails && mails.length > 0){
                        await this.addMailsToOutbox(mails, mailRun.expiryDate);
                    } else{
                        console.log(`No mails Need to send ${mailRun.template}`);
                    }
                } else {
                    console.log(`No expired mails to be send for expiry date: ${mailRun.expiryDate}`);
                }
            }
        } catch (error) {
            console.error(error);
        }

        console.log('Processing cancelled mails for Price Agreements Completed');
    }

    async getPriceAgreementsExpired(expiryDate) {
        console.log(`Fetching Cancelled Price Agreements with expiry date: ${expiryDate}`);
        const { PriceAgreements } = this.db.entities("com.bayer.SXTENDER.PriceAgreementData");
        const appEnv = cfenv.getAppEnv();
        const fastUIAppHost = appEnv.url.replace('fast-srv','fastui-app');
        // const { PT_TMUSER,PT_TMTEND } = this.db.entities("com.bayer.SXTENDER.AdminData");
        const tx = this.db.tx();
            let pas = await tx.run(SELECT.from(PriceAgreements,pa => {          
                pa.ID, pa.CountryCode, 
                pa.ExpiryDate,
                pa.Status,
                pa.TenderId,
                pa.OfferId,
                pa.Materials.SKUCode,
                pa.Institute.CustomerID,
                pa.Tender.User.UserEmail,
                pa.Tender.User.UserName,
                pa.Product.ProductPack.PRODUCTPACKNAME,
                pa.PriceConditions.PriceConditionCode,
                pa.Institute.InstituteName
          
        }).where({ ExpiryDate : expiryDate, CountryCode: 'ES' , Status: 'Cancelled', EmailNotificationSent: false }));
             
           return pas.map(pa => {
              
              pa.FormatedExpiryDate = this.dateToDDMMYYYY(pa.ExpiryDate);
              pa.URL = `${fastUIAppHost}/app/index.html#/priceagreements&/pa/PriceAgreements/${pa.ID}`
              this.updatePriceAgreementsNotification(pa.ID);
               return pa;
        })

    }

    async updatePriceAgreementsNotification(priceAgreementID){
        
        if(!priceAgreementID) return false;
        const { PriceAgreements } = this.db.entities("com.bayer.SXTENDER.PriceAgreementData");
        return UPDATE(PriceAgreements).with({EmailNotificationSent: true}).where({ ID: priceAgreementID });
    };

    mapPriceAgreementsToMails = (templates,mail) => data => {

        let outbox = [];
        const uniqueUsers = [...new Set(data.map(item => item.OfferId))];
        
         for (let user of uniqueUsers) {
            let dataFilteredByUser = data.filter(d => d.OfferId === user);
            
            if(dataFilteredByUser && dataFilteredByUser.length > 0){
                outbox.push({
                    CountryCode: dataFilteredByUser[0].CountryCode,
                    TenderID: dataFilteredByUser[0].TenderId,
                    OfferID: dataFilteredByUser[0].OfferId,
                    Sender: 'FAST-Admin@bayer.com',
                    Recipients:dataFilteredByUser[0].UserEmail,
                    Subject: this.findTemplate(templates,mail,dataFilteredByUser[0]).title,
                    MailBody: this.generateMailBody(this.findTemplate(templates,mail,dataFilteredByUser[0]), {
                        data: {
                            FormatedExpiryDate :this.dateToDDMMYYYY(dataFilteredByUser[0].ExpiryDate),
                            PriceAgreements: dataFilteredByUser 
                        }
                    }),
                      Sent: false
                });
                
            }
        }
        if(!outbox || (!outbox[0].MailBody || outbox[0].MailBody === 'undefined')) {
            console.log(`No template found for Cancelled Price Agreement ${outbox[0].TenderID} with countrycode ${outbox[0].CountryCode}`);
            return;
        }
        return outbox;
      
    }

    findTemplate = (templates,templateid,pa) => templates.find(template => 
        template.CountryCode === 'ES' && 
        template.Language === 'ES' && 
        template.TemplateId === templateid);

    async addMailsToOutbox(mails, expiryDate) {
        console.log(`Adding Cancelled mails for Price Agreements to outbox for expiry date: ${expiryDate}`);
        console.table(mails,['CountryCode','TenderID','OfferID','Sender','Recipients','Subject','Sent']);
        const { OutgoingMails } = this.db.entities("com.bayer.SXTENDER.TransactionalData");
        const tx = this.db.tx();
        try {
            const mailsResult = await tx.run(INSERT(mails).into(OutgoingMails));
            await tx.commit();
             return mailsResult;
        } catch (error) {
            console.error(error);
            await tx.rollback();
            throw error;
        }
    }
    generateMailBody(mail, data) {
        //CountryCode: language, Language: language, 
        return Handlebars.compile("" + mail.content)(data);
    }
    async getMailTemplates(templateIds) {
        console.log('Get mail templates for Cancelled price agreements');
        console.table(templateIds);
        const tx = cds.tx();
        // const language = "ES";

        const { MailTemplate } = this.db.entities("com.bayer.SXTENDER.AdminData");
        try{
            const result = await tx.run(SELECT.from(MailTemplate)
                .columns('*', 'MailTemplateFile.title', 'MailTemplateFile.content')
                .where({ TemplateId: { in: templateIds } }));
            await tx.commit();
            return result;
        }catch(error){
            console.error("No mail template found");
            await tx.rollback();
            return [];
        }
            // return tx.run(SELECT.from(MailTemplate)
            //     .columns('*', 'MailTemplateFile.title', 'MailTemplateFile.content')
            //     .where({ TemplateId: { in: templateIds } }));
    }
   
    getExpiredDate() {
        let date = new Date();
        date.setDate(date.getDate());
        return this.formatDate(date);
    }
   
    formatDate(date) {
        let month = '' + (date.getMonth() + 1);
        let day = date.getDate();
        month = month.length < 2 ? `0${month}` : month;
        day = day.length < 2 ? `0${day}` : day;
        return `${date.getFullYear()}-${month}-${day} 00:00:00`;
    }
    dateToDDMMYYYY(dateStr) {
        var d = dateStr.substr(0,4);
        var m = dateStr.substr(5,2);
        var y = dateStr.substr(8,2);
        return `${d}-${m}-${y}`;
      }
};

module.exports = PriceAgreementExpiredMailJob;