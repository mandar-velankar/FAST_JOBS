using {com.bayer.SXTENDER.TransactionalData} from '../db/TransactionalData';
using {com.bayer.SXTENDER.TransactionalDataViews} from '../db/TransactionalDataViews';
using {com.bayer.SXTENDER.MasterData} from '../db/MasterData';
using {com.bayer.SXTENDER.MasterDataViews} from '../db/MasterDataViews';
using {com.bayer.SXTENDER.AdminData} from '../db/AdminData';

@protocol: 'rest'
service ConditionContractService @(path: 'conditioncontracting')@(requires: [
    'f_tndr_cag_admin',
    'f_tndr_cag_technical_user',
    'authenticated-user'
]) {

    //@cds.persistence.exists
    entity PriceCondition               as projection on TransactionalData.PriceCondition;
    //@cds.persistence.exists
    entity PriceConditionClassification as select from TransactionalData.PriceConditionClassification;
    //@cds.persistence.exists
    entity PT_TMTEND                    as projection on TransactionalData.PT_TMTEND;
    //@cds.persistence.exists
    entity PT_TMOFRS                    as projection on TransactionalData.PT_TMOFRS;
    //@cds.persistence.exists
    entity PT_TMOFPR                    as projection on TransactionalData.PT_TMOFPR;
    //@cds.persistence.exists
    entity PT_TMINST                    as projection on MasterData.PT_TMINST;
    //@cds.persistence.exists
    entity PT_TMDIST                    as projection on MasterData.PT_TMDIST;
    //@cds.persistence.exists
    entity PT_TMBDPR                    as projection on TransactionalData.PT_TMBDPR;
    //@cds.persistence.exists
    entity Country                      as projection on MasterData.PT_TMCTRY;
    //@cds.persistence.exists
    entity Users                        as projection on AdminData.PT_TMUSER;
    //@cds.persistence.exists
    entity OutgoingMails                as projection on TransactionalData.OutgoingMails;
    //@cds.persistence.exists
    entity MailTemplate                 as projection on AdminData.MailTemplate;
    //@cds.persistence.exists
    entity MailTemplateFile             as projection on AdminData.MailTemplateFile;

    @open
    type object {};

    function getBackendData(CountryCode : String) returns object;

}
