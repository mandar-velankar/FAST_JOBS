const { ProcessMaterials, ProcessCustomers } = require('./ItalyJobs');
const { ProcessMaterialsBrazil, ProcessCustomersBrazil } = require('./BrazilJobs');
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

module.exports = class JobFactory {
    static create(jobName, jobTime) {
        switch (jobName) {
            case this.jobNames.ProcessMaterialsJob:
                return new ProcessMaterials(jobName,jobTime)
                break;
            case this.jobNames.ProcessCustomersJob:
                return new ProcessCustomers(jobName,jobTime)
                break;
            case this.jobNames.ProcessMaterialsBrazilJob:
                return new ProcessMaterialsBrazil(jobName,jobTime)
                break;
            case this.jobNames.ProcessCustomersBrazilJob:
                return new ProcessCustomersBrazil(jobName,jobTime)
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
            case this.jobNames.ProcessMasterDataPrices:
                return new ProcessMasterDataPrices(jobName,jobTime)
                break;
            case this.jobNames.ProcessBrazilCustomers:
                return new ProcessBrazilCustomers(jobName,jobTime);
                break;
            case this.jobNames.ProcessBrazilMaterials:
                return new ProcessBrazilMaterials(jobName,jobTime);
                break;
            case this.jobNames.ProcessBrazilOpportunities:
                return new ProcessBrazilOpportunities(jobName,jobTime);
                break;
            case this.jobNames.ProcessEmpenho:
                return new ProcessEmpenho(jobName,jobTime);
                break;
            case this.jobNames.ProcessBrazilIbizContracts:
                return new ProcessBrazilIbizContracts(jobName,jobTime);
                break;
            case this.jobNames.NewIBIZTenderNotifications:
                return new NewIBIZTenderNotifications(jobName, jobTime);
            case this.jobNames.ProcessTenderResults:
                return new ProcessTenderResults(jobName,jobTime);
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
            ProcessMasterDataPrices:"ProcessMasterDataPrices",
            ProcessBrazilCustomers:"ProcessBrazilCustomers",
            ProcessBrazilMaterials:"ProcessBrazilMaterials",
            ProcessBrazilOpportunities:"ProcessBrazilOpportunities",
            ProcessEmpenho:"ProcessEmpenho",
            ProcessBrazilIbizContracts:"ProcessBrazilIbizContracts",
            NewIBIZTenderNotifications:"NewIBIZTenderNotifications",
            ProcessTenderResults:"ProcessTenderResults",
            ProcessSpainRappelData: "ProcessSpainRappelData",
            PriceConditionQualityControl: "PriceConditionQualityControl",
            PriceAgreementExpiredMailJob :"PriceAgreementExpiredMailJob",
            PriceConditionsQualityControlNotificationMail: "PriceConditionsQualityControlNotificationMail"
        };
    }
}