using {
    com.bayer.SXTENDER.MasterData,
    sap.common
} from '../db/MasterData';
using {com.bayer.SXTENDER.MasterDataViews} from '../db/MasterDataViews';
using { com.bayer.SXTENDER.MasterDataLatestValues } from '../db/MasterDataLatestValues';
using {com.bayer.SXTENDER.ExternalDataViews} from '../db/ExternalDataViews';
using {com.bayer.SXTENDER.TransactionalData} from '../db/TransactionalData';
using {com.bayer.SXTENDER.AdminData} from '../db/AdminData';
using {
    User,
    Country,
    managed,
    cuid
} from '@sap/cds/common';

service MasterDataManagementService @(path : 'mdm')@(requires : ['authenticated-user','f_tndr_cag_admin','f_tndr_cag_mdm_user','f_tndr_cag_technical_user']) {

    @cds.persistence.exists
    entity PT_TMLE                  as projection on MasterData.PT_TMLE;
    @cds.persistence.exists
    entity PT_TMCTLE                as projection on MasterData.PT_TMCTLE;
    @cds.persistence.exists
    entity PT_TMCTLEBR              as projection on MasterData.PT_TMCTLEBR;
    @cds.persistence.exists
    entity CountryBrands @readonly  as projection on MasterDataViews.CountryBrands;
    @cds.persistence.exists
    entity CountryProductUnits @readonly  as projection on MasterDataViews.CountryProductUnits;
    @cds.persistence.exists
    entity PT_TMINSHIER             as projection on MasterData.PT_TMINSHIER;
    @cds.persistence.exists
    entity PT_TMINSBRTR @readonly   as projection on MasterData.PT_TMINSBRTR;
    @cds.persistence.exists
    entity PT_TMDISBRD              as projection on MasterData.PT_TMDISBRD;
    @cds.persistence.exists
    entity PT_TMPRDPCK @(cds.redirection.target:false) as projection on MasterData.PT_TMPRDPCK;
    @cds.persistence.exists
    entity PT_TMCTPRDPCK            as projection on MasterData.PT_TMCTPRDPCK;
    @cds.persistence.exists
    entity PT_TMSKUPRDPCK @(cds.redirection.target:false) as projection on MasterData.PT_TMSKUPRDPCK;
    @cds.persistence.exists
    entity CountryRegions           as projection on MasterData.CountryRegions;
    @cds.persistence.exists
    entity CountryProvinces         as projection on MasterData.CountryProvinces;
    @cds.persistence.exists
    entity InstituteDivision        as projection on MasterData.InstituteDivision;
    @cds.persistence.exists
    entity DistributorDivision      as projection on MasterData.DistributorDivision;
    
    @cds.persistence.exists
    entity PT_TMINST                as select from MasterData.PT_TMINST{
        *,
        Region: redirected to CountryRegions,
        Province: redirected to CountryProvinces,
        InstituteDivision: redirected to InstituteDivision
    };
    @cds.persistence.exists
    entity PT_TMDIST                as select from MasterData.PT_TMDIST{
        *,
        DistributorDivision: redirected to DistributorDivision
    };

    @cds.persistence.exists
    entity CountryCurrency @readonly as projection on MasterDataViews.CountryCurrency;

    @cds.persistence.exists
    entity ProductPackSKUs as projection on MasterDataViews.ProductPackSKUs;
    @cds.persistence.exists
    entity ProductPack @(cds.redirection.target:false) as projection on MasterDataViews.ProductPack;
    @cds.persistence.exists
    entity CountryBrandProducts    as select from MasterDataViews.CountryBrandProducts {
        *,
        ProductPackSKU: redirected to ProductPackSKUs,
        ProductPack: redirected to ProductPack
    };
    @cds.persistence.exists
    entity Divisions @readonly @(cds.redirection.target:false)    as projection on MasterDataViews.Divisions;

    @cds.persistence.exists
    entity PT_TMREGPR      as projection on MasterData.PT_TMREGPR;
    /*entity ConsumerPricesMasterView as select from MasterData.ConsumerPrices as cs
    inner join CountryBrandProducts as bp on cs.ProductPackId = bp.PRODUCT_ID{
        key cs.ID,
        key cs.CountryCode,
        key cs.ProductPackId,
        cs.Currency,
        cs.ValidFrom,
        cs.ValidTo,
        cs.ConsumerPriceExclPP,
        cs.ConsumerPriceInclPP,
        cs.ConsumerPriceExclPU,
        cs.ConsumerPriceInclPU,
        cs.VatPerPack,
        cs.MandatoryDiscount,
        cs.ExfPriceExclPP,
        cs.ConfidentialDiscount1,
        cs.ConfidentialDiscount2,
        cs.TotalDiscount,
        cs.MaxPriceNhsPP,
        cs.MaxPriceNhsPU,
        bp.BRAND_ID,
        bp.BRAND_NAME,
        bp.PRODUCT_NAME,
        cs.ProductPack: redirected to PT_TMPRDPCK
    };*/

    @cds.persistence.exists
    entity ConsumerPricesMasterView as select from PT_TMCTPRDPCK as bp
    left outer join MasterData.ConsumerPrices as cs on bp.PRODUCTPACKID = cs.ProductPackId {
        cs.ID,
        bp.COUNTRYCODE as CountryCode,
        key bp.PRODUCTPACKID,
        cs.Currency,
        cs.ValidFrom,
        cs.ValidTo,
        cs.ConsumerPriceExclPP,
        cs.ConsumerPriceInclPP,
        cs.ConsumerPriceExclPU,
        cs.ConsumerPriceInclPU,
        cs.VatPerPack,
        cs.MandatoryDiscount,
        cs.ExfPriceExclPP,
        cs.ConfidentialDiscount1,
        cs.ConfidentialDiscount2,
        cs.TotalDiscount,
        cs.MaxPriceNhsPP,
        cs.MaxPriceNhsPU,
        //bp.BRAND_ID,
        //bp.BRAND_NAME,
        //bp.PRODUCT_NAME,
        //cs.ProductPackId,
        bp.ProductPack: redirected to PT_TMPRDPCK
    };

    @cds.persistence.exists
    entity ConsumerPrices as projection on MasterData.ConsumerPrices;

    @cds.persistence.exists
    entity CountryRegisteredPrice as SELECT from MasterData.PT_TMPRDPCK as ProductPack
    inner join MasterData.PT_TMCTPRDPCK AS CountryProductPack
    ON CountryProductPack.PRODUCTPACKID = ProductPack.PRODUCTPACKID and ProductPack.ACTIVERECORD = 'Yes'
    left join MasterDataLatestValues.CountryRegisteredPrice as l
    on CountryProductPack.COUNTRYCODE=l.COUNTRY_CODE and ProductPack.PRODUCTPACKID =l.PRODUCT_ID
    left join MasterDataLatestValues.CountryCogs as Cogs
    on  CountryProductPack.COUNTRYCODE = Cogs.COUNTRY_CODE
    and ProductPack.PRODUCTPACKID =Cogs.PRODUCT_ID
    {
        key CountryProductPack.COUNTRYCODE as CountryCode,
        key ProductPack.PRODUCTPACKID as ProductPackID,
        ifnull(l.UOM, '') as UOM: String,
        ifnull(l.CURRENCY,'')  as PriceCurrency: String(3),
        ifnull(l.REGISTERED_PRICE,0) as RegisteredPrice: Double,
        l.EffDate as PriceEffDate,
        l.EndDate as PriceEndDate,
        l.RegisteredPriceSource,
        l.RegisteredPriceID,
        l.ActiveRecord as PriceActiveRecord, 
        Cogs.COGSID,
        ifnull(Cogs.COGS, 0) as CogsPrice: Double,
        ifnull(Cogs.CURRENCY, l.CURRENCY)  as CogsCurrency: String(3),
        //Cogs.UOM as CogsUom,
        Cogs.EffectiveDate as CogsEffDate,
        Cogs.EndDate as CogsEndDate,
        Cogs.COGSType,
        Cogs.ActiveRecord as CogsActiveRecord,
        ProductPack.PRODUCTPACKNAME as ProductPackName
    }where CountryProductPack.ACTIVERECORD = 'Yes';

    @cds.persistence.exists
    entity PT_TMCOGS       as projection on MasterData.PT_TMCOGS;
    @cds.persistence.exists
    entity PT_TMPRDHIER @readonly as projection on MasterData.PT_TMPRDHIER;
    @cds.persistence.exists
    entity COUNTRY_APPROVERS  as projection on MasterData.CountryApprovers;
    @cds.persistence.exists
    entity APPROVERTYPES  as projection on MasterData.ApproverTypes;
    @cds.persistence.exists
    entity PT_TMCTRY @readonly @(cds.redirection.target:false) as projection on MasterData.PT_TMCTRY;
    @cds.persistence.exists
    entity CountryChannels                   as projection on MasterData.MASTER_COUNTRY_CHANNELS;

    @cds.persistence.exists
    entity NextValueCountrySKUID @(cds.redirection.target:false) as select from PT_TMSKUPRDPCK {
        max(CountrySKUID) as nextCountrySkuID:Integer
    };

    @cds.persistence.exists
    entity InstitutesView @(cds.redirection.target:false) as projection on MasterData.PT_TMINST {
        *,
        CustomerID as CustomerID: String
    };
    @cds.persistence.exists
    entity ClassifiactionsView as projection on MasterData.MASTER_COUNTRY_CLASSIFICATION as classification {
        *,
        classification.COUNTRY_CODE as CountryCode: String
    };
    @cds.persistence.exists
    entity CountryInstituteTypeView as projection on MasterData.MASTER_COUNTRY_CHANNELS as instType {
        *,
        instType.ChannelCountry as CountryCode: String
    };
    @cds.persistence.exists
    entity TenderChannel as projection on MasterData.TenderChannel;
    @cds.persistence.exists
    entity StandardDivisions as projection on MasterData.StandardDivisions {
        *,
        DivisionName as Division
    };
    @cds.persistence.exists
    entity MasterDistributors @readonly @(cds.redirection.target:false) as projection on ExternalDataViews.MasterDistributors;
    @cds.persistence.exists
    entity MasterCountryCurrencies as select from MasterData.CountryCurrency;
    
    @cds.persistence.exists
    entity DistinctProductScopeView @(cds.redirection.target:false) as select from MasterData.PT_TMCTPRDPCK {
        COUNTRYCODE as CountryCode,
        key ProductScope
    } group by ProductScope, COUNTRYCODE;

    @cds.persistence.exists
    entity MasterCountryOutComes as select from MasterData.MASTER_COUNTRY_OUTCOMES;
    @cds.persistence.exists
    entity MasterOutComeReasons as select from MasterData.PT_TMOUTRS;
    @cds.persistence.exists
    entity CountryPacks @(cds.redirection.target:false) as projection on MasterData.PT_TMCTPRDPCK;
    @cds.persistence.exists
    entity Country as projection on MasterData.PT_TMCTRY {
        *,
        CountryPacks: redirected to CountryPacks
    };
    @cds.persistence.exists
    entity Users as projection on AdminData.PT_TMUSER;

    @cds.persistence.exists
    entity UsersPerCountry @readonly @(cds.redirection.target:false) as projection on AdminData.PT_TMUSERCTRY {
        *,
        User.UserName as UserName,
        Country: redirected to Country,
        User: redirected to Users
    };
    @cds.persistence.exists
    entity UsersHavingOneCountry @(cds.redirection.target:false) as select from UsersPerCountry {
        key CWID,
        max(CountryCode) as CountryCode: String,
        count(CountryCode) as numberOfCountries: Integer,
        max(UserName) as UserName: String
    }
    group by CWID
    having count(CountryCode) = 1;

    @cds.persistence.exists
    entity UserCountries @readonly @(restrict: [
        {grant: '*', to: 'authenticated-user', where: 'User.CWID = $user.id'}
    ])as projection on AdminData.PT_TMUSERCTRY {
        *,
        Country: redirected to Country,
        User: redirected to Users,
        User.UserName,
        User.UserEmail,
        Country.CountryName
    };
    
    @cds.persistence.exists
    entity CountryRegionsTableView @(cds.redirection.target:false) as projection on MasterData.CountryRegions;
    @cds.persistence.exists
    entity CountryLegalEntitySignatories as projection on MasterData.COUNTRY_LEGAL_ENTITY_SIGNATORIES as signatory {
        *,
        signatory.COUNTRY_CODE as CountryCode
    };

    @cds.persistence.exists
    entity ExcelUploadView as projection on TransactionalData.ExcelUpload;
    @cds.persistence.exists
    entity SalesDataUpload as projection on TransactionalData.ExcelUpload;

    @cds.persistence.exists
    entity DistributorAssignment as projection on MasterData.DistributorAssignment;
    @cds.persistence.exists
    entity DistinctProductBUs as select from PT_TMCTPRDPCK {
        COUNTRYCODE,
        key BU
    }where COUNTRYCODE = 'PK'
    group by COUNTRYCODE, BU;
    
    @cds.persistence.exists
    entity DistributionAgreementsView as projection on MasterDataViews.DistributionAgreementsView;
    @cds.persistence.exists
    entity DistributionAgreements as projection on MasterData.DistributionAgreements;
    @cds.persistence.exists
    entity DistributionAgreement as projection on MasterDataViews.DistributionAgreementsView;
    @cds.persistence.exists
    entity CurrentDistributionAgreementView as projection on MasterDataViews.CurrentDistributionAgreementView;
    @cds.persistence.exists
    entity WholesalePurchasePriceView as projection on MasterDataViews.WholesalePurchasePriceView;
    @cds.persistence.exists
    entity WholesalePurchasePrice as projection on MasterDataViews.WholesalePurchasePriceView;
    @cds.persistence.exists
    entity WholesalePurchasePrices as projection on MasterData.WholesalePurchasePrice;
    @cds.persistence.exists
    entity WholesalePurchasePriceApprovalsView @(cds.redirection.target:false) as projection on MasterDataViews.WholesalePurchasePriceApprovals; 
    @cds.persistence.exists
    entity WholesalePurchasePriceApprovals as projection on MasterData.WholesalePurchasePriceApprovals;
    @cds.persistence.exists
    entity WholesalePurchasePriceApproverTypes as projection on MasterData.WholesalePurchasePriceApproverTypes; 
    @cds.persistence.exists
    entity WholesalePurchasePriceApprovers as projection on MasterData.WholesalePurchasePriceApprovers; 
    @cds.persistence.exists
    entity WPPApprovalsView as projection on MasterDataViews.WPPApprovalsView;
    @cds.persistence.exists
    entity NLpppView as projection on MasterDataViews.NLpppView; 
    @cds.persistence.exists
    entity NLppp as projection on MasterDataViews.NLpppView;
    @cds.persistence.exists
    entity NLppps as projection on MasterData.NLPPP;
    @cds.persistence.exists
    entity NLPPPApprovalsView @(cds.redirection.target:false) as projection on MasterDataViews.NLPPPApprovals; 
    @cds.persistence.exists
    entity NLPPPApprovals as projection on MasterData.NLPPPApprovals;
    @cds.persistence.exists
    entity NLPPPApproverTypes as projection on MasterData.NLPPPApproverTypes; 
    @cds.persistence.exists
    entity NLPPPApprovers as projection on MasterData.NLPPPApprovers; 
    @cds.persistence.exists
    entity NLPPPApprovalsNotification as projection on MasterData.NLPPPApprovalsNotification;
    @cds.persistence.exists
    entity PPPApprovalsView as projection on MasterDataViews.PPPApprovalsView;
    @cds.persistence.exists
    entity WPPApprovalDistributors @(cds.redirection.target:false) as projection on MasterData.PT_TMDIST;
    @cds.persistence.exists
    entity NLDAExcelTemplates {
        key templateId   : Integer;
        key validDate    : String;
        key distributorID       : String;
            content      : LargeBinary @Core.MediaType : mediaType; //'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            mediaType    : String      @Core.IsMediaType;
    };

    @cds.persistence.exists
    entity NLDAExcelExtract as select from DistributionAgreementsView as dav
    left join PT_TMDIST as dist on dav.DistributorID = dist.DistributorID{
        MaterialNumbers,
        GOV_CODE,
        PRODUCTPACKNAME,
        PRESENTATION,
        PACKFACTOR,
        dav.DistributorID,
        dist.DistributorName,
        Type,
        Value,
        StartDate,
        EndDate,
        PACKFACTOR || ' ' || PRESENTATION as CombinedPackSizePresentation: String
    };

    @cds.persistence.exists
    entity ExcelTemplate as projection on AdminData.ExcelTemplate;
    @cds.persistence.exists
    entity ExcelTemplateCountry as projection on AdminData.ExcelTemplateCountry;
    @cds.persistence.exists
    entity NLExcelTemplates {
        key templateId   : Integer;
        key validDate    : String;
        key status       : String;
            content      : LargeBinary @Core.MediaType : mediaType; //'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            mediaType    : String      @Core.IsMediaType;
    };
    @cds.persistence.exists
    entity WholesalePurchasePriceApprovalsNotification as projection on MasterData.WholesalePurchasePriceApprovalsNotification;
    @cds.persistence.exists
    entity NLWPPExcelTemplates {
        key templateId   : Integer;
        key validDate    : String;
        key status       : String;
        key distributorID: String;
            content      : LargeBinary @Core.MediaType : mediaType; //'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            mediaType    : String      @Core.IsMediaType;
    };
    @cds.persistence.exists
    entity NLWPPExcelExtract as select from WholesalePurchasePriceView as wpp
    left join PT_TMDIST as dist on wpp.DistributorID = dist.DistributorID
    left join MasterCountryCurrencies as ctryCurrency
        on ctryCurrency.CountryCode = wpp.CountryCode{
        MaterialNumbers,
        GOV_CODE,
        PRODUCTPACKNAME,
        PRESENTATION,
        PACKFACTOR,
        wpp.DistributorID,
        dist.DistributorName,
        Bundle,
        OuterCarton,
        PPP,
        Type,
        Margin,
        WPPWithoutTax,
        StartDate,
        EndDate,
        Status,
        ctryCurrency.Currency,
        Type as CombinedWPPMarginNetPriceValues,
        min(EndDate) as minEndDate: Date,
        PACKFACTOR || ' ' || PRESENTATION as CombinedPackSizePresentation: String,
        wpp.Comment
    }group by 
        MaterialNumbers,
        GOV_CODE,
        PRODUCTPACKNAME,
        PRESENTATION,
        PACKFACTOR,
        wpp.DistributorID,
        dist.DistributorName,
        Bundle,
        OuterCarton,
        PPP,
        Type,
        Margin,
        WPPWithoutTax,
        StartDate,
        EndDate,
        Status,
        ctryCurrency.Currency,
        wpp.Comment;

    @cds.persistence.exists
    entity LatestCOGSView as select from PT_TMCOGS {
        max(COGSID) as maxCOGSID: Integer
    };
    @cds.persistence.exists
    entity LatestPriceView as select from PT_TMREGPR {
        max(RegisteredPriceID) as maxRegisteredPriceID: Integer
    };
    action ApproveWPP(ID: String, ProductCode: Integer) returns String;
    action ApprovePPP(ID: String, ProductCode: Integer) returns String;
    action SoftDeleteProductPrices(productPackID: Integer, countryCode: String) returns String;
}
