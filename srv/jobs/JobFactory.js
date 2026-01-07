const { ProcessMaterials, ProcessCustomers } = require('./ItalyJobs');
const PriceAgreementMailJob = require("./PriceAgreementMailJob");
const PriceAgreementPriceConditionNotificationMailJob = require("./PriceAgreementPriceConditionNotificationMailJob");
const PriceAgreementNotificationNetPriceAbovePVLJob = require("./PriceAgreementNotificationNetPriceAbovePVLJob");
const PriceAgreementNotificationNetPriceBelowFloorJob = require("./PriceAgreementNotificationNetPriceBelowFloorJob");
const ExtendPriceAgreements = require("./PriceAgreementJobs");
const ProcessMasterDataPrices = require("./brasil/ProcessMasterDataPrices");
const ProcessBrazilCustomers = require("./brasil/ProcessCustomers");
const ProcessBrazilMaterials = require("./brasil/ProcessMaterials");
const ProcessBrazilOpportunities = require("./brasil/ProcessOpportunities");
const ProcessEmpenho = require("./brasil/ProcessEmpenho");
const ProcessBrazilIbizContracts = require("./brasil/ProcessIbizContracts");
const NewIBIZTenderNotifications = require("./brasil/ProcessIbizTenderNotifications");
const ProcessTenderResults = require("./brasil/ProcessTenderResults");
const ProcessSpainRappelData = require("./ProcessSpainRappelData");
const PriceConditionQualityControl = require("./PriceConditionsQualityControlJob");
const PriceConditionsQualityControlNotificationMail = require("./PriceConditionsQualityControlNotificationMailJob");
const PriceAgreementExpiredMailJob = require("./PriceAgreementExpiredMailJob");
const ProcessMaterialMasterData = require("./ProcessMaterialMasterData");
const ProcessCustomerMasterData = require("./ProcessCustomerMasterData");
const ProcessHematologyResultsRecordReminderMail = require("./ProcessHematologyResultsRecordReminderMailJob");

module.exports = class JobFactory {
    static create(jobName, jobTime) {
        switch (jobName) {
            case this.jobNames.ProcessMaterialsJob:
                return new ProcessMaterials(jobName,jobTime)
                break;
            case this.jobNames.ProcessCustomersJob:
                return new ProcessCustomers(jobName,jobTime)
                break;
            case this.jobNames.PriceAgreementMailJob:
                return new PriceAgreementMailJob(jobName,jobTime)
                break;              
            case this.jobNames.PriceAgreementPriceConditionNotificationMailJob:
                return new PriceAgreementPriceConditionNotificationMailJob(jobName,jobTime)
                break;
            case this.jobNames.PriceAgreementNotificationNetPriceAbovePVLJob:
                return new PriceAgreementNotificationNetPriceAbovePVLJob(jobName,jobTime)
                break;
            case this.jobNames.PriceAgreementNotificationNetPriceBelowFloorJob:
                return new PriceAgreementNotificationNetPriceBelowFloorJob(jobName,jobTime)
                break;
            case this.jobNames.ExtendPriceAgreements:
                return new ExtendPriceAgreements(jobName,jobTime)
                break;
            case this.jobNames.ProcessSpainRappelData:
                return new ProcessSpainRappelData(jobName,jobTime)
                break;
            case this.jobNames.PriceConditionQualityControl:
                return new PriceConditionQualityControl(jobName,jobTime)
                break;
            case this.jobNames.PriceConditionsQualityControlNotificationMail:
                return new PriceConditionsQualityControlNotificationMail(jobName,jobTime)
                break;
            case this.jobNames.PriceAgreementExpiredMailJob:
                return new PriceAgreementExpiredMailJob(jobName,jobTime)
                break;
            case this.jobNames.ProcessMaterialMasterData:
                return new ProcessMaterialMasterData(jobName,jobTime)
                break;
            case this.jobNames.ProcessCustomerMasterData:
                return new ProcessCustomerMasterData(jobName,jobTime)
                break;
            case this.jobNames.ProcessHematologyResultsRecordReminderMail:
                return new ProcessHematologyResultsRecordReminderMail(jobName,jobTime)
                break;
            default:
                throw new Error('Job type not supported');
                break;
        }
    }
    static get jobNames() {
        return {
            ProcessMaterialsJob: "ProcessMaterialsJob",
            ProcessCustomersJob: "ProcessCustomersJob",
            ProcessMaterialsBrazilJob: "ProcessMaterialsBrazilJob", // TODO: are these old jobs? if yes, remove them
            ProcessCustomersBrazilJob: "ProcessCustomersBrazilJob", // TODO: are these old jobs? if yes, remove them
            PriceAgreementMailJob: "PriceAgreementMailJob",
            PriceAgreementPriceConditionNotificationMailJob: "PriceAgreementPriceConditionNotificationMailJob",
            PriceAgreementNotificationNetPriceAbovePVLJob: "PriceAgreementNotificationNetPriceAbovePVLJob",
            PriceAgreementNotificationNetPriceBelowFloorJob: "PriceAgreementNotificationNetPriceBelowFloorJob",
            ExtendPriceAgreements: "ExtendPriceAgreements",
            ProcessSpainRappelData: "ProcessSpainRappelData",
            PriceConditionQualityControl: "PriceConditionQualityControl",
            PriceAgreementExpiredMailJob :"PriceAgreementExpiredMailJob",
            PriceConditionsQualityControlNotificationMail: "PriceConditionsQualityControlNotificationMail",
            ProcessMaterialMasterData: "ProcessMaterialMasterData",
            ProcessCustomerMasterData: "ProcessCustomerMasterData",
            ProcessHematologyResultsRecordReminderMail: "ProcessHematologyResultsRecordReminderMail"
        };
    }
}