using {
    com.bayer.SXTENDER.MasterData,
    sap.common
} from '../db/MasterData';
using {com.bayer.SXTENDER.TransactionalData} from '../db/TransactionalData';
using {com.bayer.SXTENDER.MasterDataViews} from '../db/MasterDataViews';
using {com.bayer.SXTENDER.MasterDataLatestValues} from '../db/MasterDataLatestValues';
using {com.bayer.SXTENDER.TransactionalDataViews} from '../db/TransactionalDataViews';
using {com.bayer.SXTENDER.IntegrationDataConversion} from '../db/IntegrationDataConversion';
using {com.bayer.SXTENDER.AdminData} from '../db/AdminData';
using {com.bayer.SXTENDER.AdminDataViews} from '../db/AdminDataViews';
using {com.bayer.SXTENDER.BankGuaranteeData} from '../db/BankGuaranteeData';
using {com.bayer.SXTENDER.PriceAgreementData} from '../db/PriceAgreementData';
using {com.bayer.SXTENDER.BrazilContractingData} from '../db/BrazilContractingData';
using {
    User,
    Country,
    managed,
    cuid
} from '@sap/cds/common';


service CatalogService @(path : 'tender')@(requires : [
    'authenticated-user',
    'f_tndr_cag_admin',
    'f_tndr_cag_tnd_user',
    'f_tndr_cag_technical_user'
]) {
    //Master Data Tables
    @cds.persistence.exists
    entity CountryLegalEntitySignatories                as projection on MasterData.COUNTRY_LEGAL_ENTITY_SIGNATORIES;
    @cds.persistence.exists
    entity MASTER_APPROVED_PRICE                        as projection on MasterData.MASTER_APPROVED_PRICE;
    @cds.persistence.exists
    entity CommercialAgreement                          as projection on MasterData.MASTER_COMMERCIAL_AGREEMENT;
    @cds.persistence.exists
    entity ContractType                                 as projection on MasterData.MASTER_CONTRACT_TYPE;
    @cds.persistence.exists
    entity CountryContractType                          as projection on MasterData.MASTER_COUNTRY_CONTRACT_TYPE;
    @cds.persistence.exists
    entity CountrySalesType                             as projection on MasterData.MASTER_COUNTRY_SALES_TYPE;
    @cds.persistence.exists
    entity CountryTenderOrigin                          as projection on MasterData.MASTER_COUNTRY_TENDER_ORIGIN;
    @cds.persistence.exists
    entity CountryTenderType                            as projection on MasterData.MASTER_COUNTRY_TENDER_TYPE;
    @cds.persistence.exists
    entity CountryTenderType2                           as projection on MasterData.MASTER_COUNTRY_TENDER_TYPE2;
    @cds.persistence.exists
    entity MASTER_INSTITUTE_HIERARCHY                   as projection on MasterData.MASTER_INSTITUTE_HIERARCHY;
    @cds.persistence.exists
    entity SalesType                                    as projection on MasterData.MASTER_SALES_TYPE;
    @cds.persistence.exists
    entity TenderOrigin                                 as projection on MasterData.MASTER_TENDER_ORIGIN;
    @cds.persistence.exists
    entity TenderType                                   as projection on MasterData.MASTER_TENDER_TYPE;
    @cds.persistence.exists
    entity MASTER_COUNTRY_STATUS                        as projection on MasterData.MASTER_COUNTRY_STATUS;
    @cds.persistence.exists
    entity MASTER_COUNTRY_OUTCOMES                      as projection on MasterData.MASTER_COUNTRY_OUTCOMES;
    @cds.persistence.exists
    entity CountryApprovers                             as projection on MasterData.CountryApprovers;
    @cds.persistence.exists
    entity AccountPreApprovedPrices                     as projection on MasterData.AccountPreApprovedPrices;
    @cds.persistence.exists
    entity ApproverTypes                                as projection on MasterData.ApproverTypes;
    @cds.persistence.exists
    entity PT_TMCOGS                                    as projection on MasterData.PT_TMCOGS;
    @cds.persistence.exists
    entity PT_TMCTLE                                    as projection on MasterData.PT_TMCTLE;
    @cds.persistence.exists
    entity PT_TMCTLEBR                                  as projection on MasterData.PT_TMCTLEBR;
    @cds.persistence.exists
    entity PT_TMCTPRDPCK                                as projection on MasterData.PT_TMCTPRDPCK;
    @cds.persistence.exists
    entity CountryClassifications                       as projection on MasterData.MASTER_COUNTRY_CLASSIFICATION;
    @cds.persistence.exists
    entity CountryChannels                              as projection on MasterData.MASTER_COUNTRY_CHANNELS;
    @cds.persistence.exists
    entity CountryProcurementMethod                     as projection on MasterData.MASTER_COUNTRY_PROCUREMENT_METHOD;
    @cds.persistence.exists
    entity CountryBiddingTypeLevel1                     as projection on MasterData.MasterCountryBiddingTypeLevel1;
    @cds.persistence.exists
    entity CountryBiddingTypeLevel2                     as projection on MasterData.MasterCountryBiddingTypeLevel2;
    @cds.persistence.exists
    entity CountryBiddingTypeLevel3                     as projection on MasterData.MasterCountryBiddingTypeLevel3;
    @cds.persistence.exists
    entity CountrySpecifications                        as projection on MasterData.MasterCountrySpecifications;
    @cds.persistence.exists
    entity MasterCompetitors                            as projection on MasterData.MasterCompetitors;
    @cds.persistence.exists
    entity BrandPolicies                                as projection on MasterData.BrandPolicies;
    @cds.persistence.exists
    entity DistributorBrandPolicies                     as projection on MasterData.DistributorBrandPolicies;
    @cds.persistence.exists
    entity CountryRegions                               as projection on MasterData.CountryRegions;
    @cds.persistence.exists
    entity TenderRegions                                as projection on MasterData.TenderRegions;
    //italy
    @cds.persistence.exists
    entity ConsumerPrices                               as projection on MasterData.ConsumerPrices;
    @cds.persistence.exists
    entity MostRecentConsumerPricesView                 as projection on MasterDataViews.MostRecentConsumerPricesView;
    @cds.persistence.exists
    entity ProductPricing                               as projection on TransactionalData.ProductPricing;
    @cds.persistence.exists
    entity PriceCondition                               as projection on TransactionalData.PriceCondition;
    @cds.persistence.exists
    entity PriceConditionClassification                 as projection on TransactionalData.PriceConditionClassification;
    @cds.persistence.exists
    entity DiscountCondition                            as projection on TransactionalData.DiscountCondition;
    @cds.persistence.exists
    entity FreeGoodsOther                               as projection on TransactionalData.FreeGoodsOther;
    @cds.persistence.exists
    entity ProductTypeProfitability                     as projection on TransactionalData.ProductTypeProfitability;
    @cds.persistence.exists
    entity ProductPricingView                           as projection on TransactionalDataViews.ProductPricingView;
    @cds.persistence.exists
    entity PriceConditionView                           as projection on TransactionalDataViews.PriceConditionView;
    //spain
    @cds.persistence.exists
    entity MasterPrices                                 as projection on MasterData.MasterPrices;
    @cds.persistence.exists
    entity MostRecentMasterPricesView                   as projection on MasterDataViews.MostRecentMasterPricesView;
    @cds.persistence.exists
    entity Settlements                                  as projection on MasterData.Settlements;
    @cds.persistence.exists
    entity RoyalDecreePercentage                        as projection on MasterData.RoyalDecree;
    //Brazil
    @cds.persistence.exists
    entity Lots                                         as projection on TransactionalData.Lots;
    @cds.persistence.exists
    entity LotProducts                                  as projection on TransactionalData.LotProduct;
    @cds.persistence.exists
    entity BrazilCap                                    as projection on MasterData.BrazilCap;
    @cds.persistence.exists
    entity BrazilMasterPrices                           as projection on MasterData.BrazilMasterPrices;
    @cds.persistence.exists
    entity DistributorDivision                          as projection on MasterData.DistributorDivision;
    @cds.persistence.exists
    entity InstituteDivision                            as projection on MasterData.InstituteDivision;
    @cds.persistence.exists
    entity PriceConditionBrazilView                     as projection on TransactionalDataViews.PriceConditionBrazilView;
    @cds.persistence.exists
    entity DocumentsDownload                            as projection on TransactionalData.DocumentsDownload;
    @cds.persistence.exists
    entity ContractStatuses                             as projection on AdminData.ContractStatus;
    @cds.persistence.exists
    entity Contracts                                    as projection on BrazilContractingData.Contracts;
    @cds.persistence.exists
    entity ContractProducts                             as projection on BrazilContractingData.ContractProducts;
    @cds.persistence.exists
    entity OfferValidation                              as projection on TransactionalDataViews.OfferValidation;
    @cds.persistence.exists
    entity OfferProductValidation                       as projection on TransactionalDataViews.OfferProductValidation;

    //general transactionalData
    @cds.persistence.exists
    entity OfferProductOfferStatus                      as projection on TransactionalData.OfferProductOfferStatus;


    @cds.persistence.exists
    entity PT_TMCTRY @(restrict : [{
        grant : '*',
        to    : 'authenticated-user',
        where : 'User.CWID = $user.id'
    }])                                                 as projection on MasterData.PT_TMCTRY {
        * , LegalEntities : redirected to PT_TMCTLE, CountryPacks : redirected to PT_TMCTPRDPCK, User : redirected to PT_TMUSERCTRY
    };

    @cds.persistence.exists
    entity PT_TMDISBRD                                  as projection on MasterData.PT_TMDISBRD;
    @cds.persistence.exists
    entity PT_TMDIST                                    as projection on MasterData.PT_TMDIST;
    @cds.persistence.exists
    entity PT_TMFXRTS                                   as projection on MasterData.PT_TMFXRTS;
    @cds.persistence.exists
    entity PT_TMINDSBR                                  as projection on MasterData.PT_TMINDSBR;
    @cds.persistence.exists
    entity PT_TMINSBRTR                                 as projection on MasterData.PT_TMINSBRTR;
    @cds.persistence.exists
    entity PT_TMINSHIER                                 as projection on MasterData.PT_TMINSHIER;
    @cds.persistence.exists
    entity PT_TMINST                                    as projection on MasterData.PT_TMINST;
    @cds.persistence.exists
    entity Province                                     as projection on MasterData.CountryProvinces;

    @cds.persistence.exists
    entity PT_TMLE                                      as projection on MasterData.PT_TMLE {
        * , Countries : redirected to PT_TMCTLE
    };

    @cds.persistence.exists
    entity PT_TMOUTRS                                   as projection on MasterData.PT_TMOUTRS;
    @cds.persistence.exists
    entity PT_TMPNLTYRS                                 as projection on MasterData.PT_TMPNLTYRS;
    @cds.persistence.exists
    entity PT_TMPRDHIER                                 as projection on MasterData.PT_TMPRDHIER;

    @cds.persistence.exists
    entity PT_TMPRDPCK                                  as projection on MasterData.PT_TMPRDPCK {
        * , CountryPacks : redirected to PT_TMCTPRDPCK
    };

    @cds.persistence.exists
    entity PT_TMRCM                                     as projection on MasterData.PT_TMRCM;
    @cds.persistence.exists
    entity PT_TMREGIONSTRUC                             as projection on MasterData.PT_TMREGIONSTRUC;
    @cds.persistence.exists
    entity PT_TMREGPR                                   as projection on MasterData.PT_TMREGPR;
    @cds.persistence.exists
    entity PT_TMSKUPRDPCK                               as projection on MasterData.PT_TMSKUPRDPCK;
    @cds.persistence.exists
    entity PT_TMTABRMP                                  as projection on MasterData.PT_TMTABRMP;
    @cds.persistence.exists
    entity BUDGETEDPROFITABILITY                        as projection on MasterData.BUDGETEDPROFITABILITY;
    //Master Data Latest Values
    @cds.persistence.exists
    entity CountryRegisteredPrice @readonly             as projection on MasterDataLatestValues.CountryRegisteredPrice;
    @cds.persistence.exists
    entity CountryCogs @readonly                        as projection on MasterDataLatestValues.CountryCogs;
    @cds.persistence.exists
    entity ExchangeRates @readonly                      as projection on MasterDataLatestValues.ExchangeRates;
    @cds.persistence.exists
    entity VWBUDGETEDPROFITABILITY @readonly            as projection on MasterDataLatestValues.VWBUDGETEDPROFITABILITY;
    @cds.persistence.exists
    entity MostRecentBrandPolicies @readonly            as projection on MasterDataLatestValues.MostRecentBrandPolicies;
    @cds.persistence.exists
    entity MostRecentDistributorBrandPolicies @readonly as projection on MasterDataLatestValues.MostRecentDistributorBrandPolicies;
    //Master Data Views
    @cds.persistence.exists
    entity CountryBrandProducts @readonly               as projection on MasterDataViews.CountryBrandProducts;
    @cds.persistence.exists
    entity CountryBrands @readonly                      as projection on MasterDataViews.CountryBrands;
    @cds.persistence.exists
    entity CountryCurrency @readonly                    as projection on MasterDataViews.CountryCurrency;
    @cds.persistence.exists
    entity CountryLegalEntity @readonly                 as projection on MasterDataViews.CountryLegalEntity;
    @cds.persistence.exists
    entity AggregatedDistributorBrandPolicies @readonly as projection on MasterDataViews.AggregatedDistributorBrandPolicies;
    @cds.persistence.exists
    entity ChannelProductPolicies @readonly             as projection on MasterDataLatestValues.ActiveChannelProductPolicies;

    //Master Data Services
    @cds.persistence.exists
    entity InstituteDistributor {
        key COUNTRY_INSTITUTE_DISTRIBUTOR_ID : String(500);
            COUNTRY_CODE                     : String not null;
            INSTITUTE_ID                     : Integer not null;
            INSTITUTE_NAME                   : String(500);
            DISTRIBUTOR_ID                   : Integer not null;
            DISTRIBUTOR_NAME                 : String(500);
            LEGAL_ENTITY_CODE                : String(3) not null;
            CHANNEL                          : String(11) not null;
    };

    @cds.persistence.exists
    entity InstituteDistributorBrandProduct as projection on MasterDataViews.InstituteDistributorBrandProduct;

    //Transactional Data Tables
    @cds.persistence.exists
    entity PT_OFGRPUR                                   as projection on TransactionalData.PT_OFGRPUR;
    @cds.persistence.exists
    entity PT_SCENARIOPLAN                              as projection on TransactionalData.PT_SCENARIOPLAN;
    @cds.persistence.exists
    entity PT_TENDGRPPUR                                as projection on TransactionalData.PT_TENDGRPPUR;

    @cds.persistence.exists
    entity PT_TMAPPRST                                  as projection on TransactionalData.PT_TMAPPRST {
        * , OfferProduct : redirected to PT_TMOFPR
    };

    @cds.persistence.exists
    entity PT_TMAWRDCR                                  as projection on TransactionalData.PT_TMAWRDCR {
        * , Tender : redirected to PT_TMTEND
    };

    @cds.persistence.exists
    entity Specifications                               as projection on TransactionalData.Specifications {
        * , Tender : redirected to PT_TMTEND
    };


    @cds.persistence.exists
    entity PT_TMBDPR                                    as projection on TransactionalData.PT_TMBDPR {
        * , Product : redirected to PT_TMOFPR
    };

    @cds.persistence.exists
    entity PT_TMDLVTR                                   as projection on TransactionalData.PT_TMDLVTR;

    @cds.persistence.exists
    entity PT_TMOFPR                                    as projection on TransactionalData.PT_TMOFPR {
        * , SKUCountry : redirected to PT_TMCTPRDPCK, Offer : redirected to PT_TMOFRS
    };

    @cds.persistence.exists
    entity PT_TMOFRS  @(cds.redirection.target:true)    as projection on TransactionalData.PT_TMOFRS {
        * , Product : redirected to PT_TMOFPR, Tender : redirected to PT_TMTEND
    };

    @cds.persistence.exists
    entity OfferView                                    as projection on TransactionalData.OfferView {
        * , Product : redirected to PT_TMOFPR, Tender : redirected to PT_TMTEND
    };

    @cds.persistence.exists
    entity CountrySpecificInformation                   as projection on TransactionalData.CountrySpecificTenderInfo {
        *
    };

    @cds.persistence.exists
    entity OfferStatus                                  as projection on TransactionalDataViews.OfferStatus;
    @cds.persistence.exists
    entity PT_TMPFIOM                                   as projection on TransactionalData.PT_TMPFIOM;

    @cds.persistence.exists
    entity PT_TMQUTO                                    as projection on TransactionalData.PT_TMQUTO {
        * , Offer : redirected to PT_TMOFRS
    };

    @cds.persistence.exists
    entity PT_TMTEND  @(cds.redirection.target:true)    as projection on TransactionalData.PT_TMTEND {
        * , Offer : redirected to PT_TMOFRS, OfferView : redirected to OfferView, CountrySpecificInformation : redirected to CountrySpecificInformation, User : redirected to PT_TMUSER,
    };

    @cds.persistence.exists
    entity PT_TMTNOFST                                  as projection on TransactionalData.PT_TMTNOFST;
    @cds.persistence.exists
    entity PT_TMTRRES                                   as projection on TransactionalData.PT_TMTRRES;
    @cds.persistence.exists
    entity PT_TMUDLTRS                                  as projection on TransactionalData.PT_TMUDLTRS;
    @cds.persistence.exists
    entity TransCompetitorResult                        as projection on TransactionalData.TransCompetitorResult;
    @cds.persistence.exists
    entity SpainRappelData                              as projection on TransactionalData.SpainRappelData;
    //Transactional Data Views
    @cds.persistence.exists
    entity TenderOffers @readonly                       as projection on TransactionalDataViews.TenderOffers;
    @cds.persistence.exists
    entity OfferRevisions @readonly                     as projection on TransactionalDataViews.OfferRevisions;
    @cds.persistence.exists
    entity CountryTenderBrands @readonly                as projection on TransactionalDataViews.CountryTenderBrands;
    @cds.persistence.exists
    entity CountryTenderNo @readonly                    as projection on TransactionalDataViews.CountryTenderNo;
    @cds.persistence.exists
    entity TenderResults @readonly                      as projection on TransactionalDataViews.TenderResults;
    @cds.persistence.exists
    entity LatestApprovalRequests @readonly             as projection on TransactionalDataViews.LatestApprovalRequests;
    @cds.persistence.exists
    entity PreviousApproval @readonly                   as projection on TransactionalDataViews.PreviousApproval;
    @cds.persistence.exists
    entity TenderHistory @readonly                      as projection on TransactionalDataViews.TenderHistory;
    @cds.persistence.exists
    entity OfferValues @readonly                        as projection on TransactionalDataViews.OfferValues;
    @cds.persistence.exists
    entity TenderOfferMaster @readonly                  as projection on TransactionalDataViews.TenderOfferMaster;
    @cds.persistence.exists
    entity BrandsInTender @readonly                     as projection on TransactionalDataViews.BrandsInTender;
    @cds.persistence.exists
    entity CountryMinPrice @readonly                    as projection on TransactionalDataViews.CountryMinPrice;
    @cds.persistence.exists
    entity PreApprovedPrices @readonly                  as projection on TransactionalDataViews.PreApprovedPrices;
    @cds.persistence.exists
    entity TenderHistorySpain @readonly                 as projection on TransactionalDataViews.TenderHistorySpain;
    @cds.persistence.exists
    entity TenderHistoryBrazil @readonly                as projection on TransactionalDataViews.TenderHistoryBrazil;

    //Admin Data Tables
    @cds.persistence.exists
    entity CONDITIONAL_ACCESS                           as projection on AdminData.CONDITIONAL_ACCESS;

    @cds.persistence.exists
    entity PT_TMUSER @(cds.redirection.target:true)     as projection on AdminData.PT_TMUSER {
        * , Countries : redirected to PT_TMUSERCTRY
    };

    @cds.persistence.exists
    entity PT_TMUSERCTRY                                as projection on AdminData.PT_TMUSERCTRY {
        * , User : redirected to PT_TMUSER
    };

    //Admin Data Views
    @cds.persistence.exists
    entity UserCountries @readonly                      as projection on AdminDataViews.UserCountries;

    @cds.persistence.exists
    entity Users @readonly                              as projection on AdminDataViews.Users {
        * , toUserCountries : redirected to UserCountries
    };

    type User {
        name  : String;
        email : String;
    };

    // entity MandatoryProductFields @readonly  as projection on AdminData.MandatoryTableFieldsCountry;

    @cds.persistence.exists
    entity CountryTablesCustomization @readonly         as projection on AdminData.CountryTablesCustomization;
    @cds.persistence.exists
    entity CountryTabsCustomization @readonly           as projection on AdminData.CountryTabsCustomization;
    @cds.persistence.exists
    entity CountryFragmentsCustomization @readonly      as projection on AdminData.CountryFragmentsCustomization;
    @cds.persistence.exists
    entity AppConfig @readonly                          as projection on AdminData.AppConfig;
    function getCurrentUser() returns User;
    //Office365 PowerAutomate Approval Workflow Views
    @cds.persistence.exists
    entity QuotationUpdates @readonly                   as projection on TransactionalDataViews.QuotationUpdates;

    //Office365 PowerAutomate Approval Workflow Service
    @cds.persistence.exists
    entity ApprovalOffers {
            OFFERSTATUSPATH       : String(500);
            COUNTRYCODE           : String;
            TENDERID              : String(50);
        key OFFERID               : String(50);
            INSTITUTENAME         : String(500);
            TAXCODE               : String(50);
            VATCODE               : String(50);
            CURRENCY              : String(3);
            AMOUNT_IN_NUMBERS     : String(1000);
            AMOUNT_IN_WORDS       : String(1000);
            AMOUNT_IN_NUMBERS_VAT : Double;
            AMOUNT_IN_WORDS_VAT   : String(1024);
            DISTRIBUTORNAME       : String(500);
            DISTRIBUTORADDRESS    : String(5000);
            DISTRIBUTORPHONE      : String(500);
            DISTRIBUTORFAX        : String(500);
            DISTRIBUTORCONTACT    : String(500);
            OFFERDATE             : String(11);
            OFFERVALIDITY         : String(11);
            SELLINGCOMPANY        : String(500);
            SELLINGCOMPANYBANK    : String(5000);
            REMARKS               : String(5000);
            APPROVER1             : String(5000);
            APPROVER2             : String(5000);
            E_SIGNATURE1          : Boolean;
            E_SIGNATURE2          : Boolean;
            SHIPMENTTERMS         : String(5000);
            PAYMENTTERMS          : String(5000);
            DELIVERYTERMS         : String(5000);
            CUSTOM_REMARKS        : String(5000);
            LETTERHEAD            : String(5000);
            CANCELLED             : String(3);
            BUDGET_RATE           : Double;
            SPOT_RATE             : Double;
            EFFECTIVEDATE         : Date;
            EXPIRYDATE            : Date;
    };

    @cds.persistence.exists
    entity ApprovalProducts {
            TENDERID                      : String(50);
        key OFFERID                       : String(50);
            COUNTRYCODE                   : String;
        key PRODUCTCODE                   : String(500);
            PRODUCT_UNIT_NAME             : String(500);
            SORTER                        : Integer;
            BRANDNAME                     : String(500);
            PRODUCTNAME                   : String(500);
            PACKSIZE                      : Double;
            DOSAGE                        : Double;
            UOM                           : String(10);
            COUNTRYOFORIGIN               : String(500);
            MANUFACTURER                  : String(500);
            SHELFLIFE                     : Integer;
            PRESENTATION                  : String(500);
            VAT                           : Double;
            CURRENCY                      : String(3);
            NETOFFERPRICE                 : String(1000);
            REQUESTEDVOLUME               : String(5000);
            PAIDVOLUME                    : Double;
            FOC                           : String(500);
            UNIT                          : String(500);
            TOTAL_QUANTITY_UNITS          : String(1000);
            FOC_QUANTITY_UNITS            : String(1000);
            PAID_QUANTITY_UNITS           : String(1000);
            REQ_PRICE_UNIT_OFFER_CURRENCY : String(1000);
            REQ_PRICE_PACK_OFFER_CURRENCY : String(1000);
            REQ_PRICE_UNIT_EUR_BUDGET     : String(1000);
            REQ_PRICE_UNIT_EUR_SPOT       : String(1000);
            NET_PRICE_UNIT_OFFER_CURRENCY : String(1000);
            NET_PRICE_PACK_OFFER_CURRENCY : String(1000);
            NET_PRICE_UNIT_EUR_BUDGET     : String(1000);
            NET_PRICE_UNIT_EUR_SPOT       : String(1000);
            COGS_EUR_UNIT                 : String(1000);
            GROSS_MARGIN_EUR_BUDGET       : String(1000);
            GROSS_MARGIN_EUR_SPOT         : String(1000);
            GROSS_SALES_OFFER_CURRENCY    : String(1000);
            NET_SALES_OFFER_CURRENCY      : String(1000);
            NET_SALES_EUR_BUDGET          : String(1000);
            NET_SALES_EUR_SPOT            : String(1000);
            GROSS_PROFIT_EUR_BUDGET       : String(1000);
            GROSS_PROFIT_EUR_SPOT         : String(1000);
            DIVISION                      : String(100);
            BUDGETEDPROFITABILITY         : String(1000);
            PROFITABILITYBUDGET           : String(1000);
            PROFITABILITYSPOT             : String(1000);
            BUDGET_RATE                   : Double;
            SPOT_RATE                     : Double;
            BUSINESS_CASE_PRICE           : String(1000);
            IS_LOWEST                     : Integer;
            REQ_PRICE_UNIT_OFFER_CURRENCY_VAT : Double; 
            NET_PRICE_UNIT_OFFER_CURRENCY_VAT : Double; 
            GROSS_SALES_OFFER_CURRENCY_VAT    : Double;

            WARRANTY                          : Double;
            AGREEMENTDURATION                 : Integer;
            MONTHLYRENT                       : Double;
            MONTHSPERINVOICE                  : Integer;  
            CONTRACTSTARTDATE                 : Timestamp;
            VALUEOFDEVICES                    : Double;
            STATUSOFDEVICE                    : String;
            MINCONTRACTUAL                    : Double;
            MINANNPURCH                       : Double;
            FOC_STEP                          : Double;
            MOLECULE_NAME                     : String(255);
            //missing SKU & SKUCountry fields
            ACTIVERECORD                      : String(10);
            HLEVEL6_CODE                      : String(50);
            PCI_NAME                          : String(255);
            ACTIVE_SUBSTANCE                  : String(50);
            PRODUCT_TYPE                      : String(50);
            SKUCOUNTRY_ACTIVERECORD           : String(10);
            PRESENTATION_2                    : String(1000);
            GOV_CODE                          : String(255);
            CODE1                             : String(255);
            CODE2                             : String(255);
            CODE3                             : String(255);
            QTY_THRESHOLD                     : Integer;
            //end of missing SKU & SKUCountry fields  
            FreeGoodsOther                    : Association to many FreeGoodsOther
                                                   on FreeGoodsOther.ProductPackId = $self.PRODUCTCODE;
    };

    @cds.persistence.exists
    entity ApprovalApprovers {
            STATUSPATH         : String(5000);
            TENDERID           : String(50);
        key OFFERID            : String(50);
            COUNTRYCODE        : String;
            SUBMITTED_BY       : String(500);
            SUBMITTED_BY_NAME  : String(500);
            SUBMITTED_BY_EMAIL : String(500);
            APPROVAL_TYPE      : String(500);
            ApprovalContent    : String(500);
            ApproverName       : String(500);
        key ApproverEmailID    : String(500);
            SenderComment      : String(500);
        key ApproverType       : String(500);
            REQUIRED_ACTION    : String(12);
            APPROVAL_STATUS    : String(100);
            FLOW_ID            : String(500);
            DIVISION           : String(500);
            COUNTRYNAME        : String(50);
            HIERARCHY          : Integer;
    };

    //SALES OPPORTUNINTY
    @cds.persistence.exists
    entity Buyers                                       as projection on IntegrationDataConversion.PublicMarketBuyers;
    @cds.persistence.exists
    entity Products                                     as projection on IntegrationDataConversion.PublicMarketProducts;

    @cds.persistence.exists
    entity PublicMarketTenders                          as projection on IntegrationDataConversion.PublicMarketTenders {
        * , Comprador : redirected to Buyers, Items : redirected to Products
    };

    //BANK GUARANTEE
    @cds.persistence.exists
    entity BankGuarantees                               as projection on BankGuaranteeData.BankGuarantees {
        * , Tender : redirected to PT_TMTEND
    };

    //PRICE AGREEMENT
    @cds.persistence.exists
    entity PriceAgreements                              as projection on PriceAgreementData.PriceAgreements {
        * , 
        Tender : redirected to PT_TMTEND,
        OfferProduct : redirected to PT_TMOFPR
    };

    @cds.persistence.exists
    entity Candidates                                   as projection on PriceAgreementData.CandidatesView;

    //OTHER
    @cds.persistence.exists
    entity Templates                                    as projection on AdminData.Template;
    @cds.persistence.exists
    entity MailTemplates                                as projection on AdminData.MailTemplate;
    @cds.persistence.exists
    entity MailTemplateFiles                            as projection on AdminData.MailTemplateFile;
    @cds.persistence.exists
    entity Outbox                                       as projection on TransactionalData.OutgoingMails;

    @cds.persistence.exists
    entity Attachment {
        key OfferId : String(50);
            content : LargeBinary @Core.MediaType : 'application/pdf';
    }
    @cds.persistence.exists
    entity ExcelAttachment// as projection on AdminData.ExcelAttachment;
    {
        key OfferId : String(50);
        content   : LargeBinary @Core.MediaType: mediaType;//'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        mediaType:String @Core.IsMediaType;
    }

    //entity ExcelAttachmentView                          as projection on AdminData.ExcelAttachment;
    // {
    //     key OfferId : String(50);
    //     content   : LargeBinary @Core.MediaType: mediaType;//'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    //     mediaType:String @Core.IsMediaType;
    // }


    @cds.persistence.exists
    entity WordTemplateCountry                          as projection on AdminData.WordTemplateCountry;
    @cds.persistence.exists
    entity WordTemplate                                 as projection on AdminData.WordTemplate;

    @cds.persistence.exists
    entity WordAttachments {
        key offerId    : String(50);
        key templateId : Integer;
            content    : LargeBinary @Core.MediaType : mediaType; //'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            mediaType  : String      @Core.IsMediaType;
    }

    @cds.persistence.exists
    entity DeliveryExcel {
        key OfferId   : String(50);
            content   : LargeBinary @Core.MediaType : mediaType; //'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            mediaType : String      @Core.IsMediaType;
    }

    //action sendMail (sRecipient:String, sBody:String) returns Boolean;
    action sendMail(sRecipient : String, sSubject : String, sTemplate : String) returns Boolean;
    function getMailTemplate(countryCode : String, language : String, offerId : String) returns LargeString;

    action notifyIbiz(ibizWorkflowID: Integer, directIndirect: Integer, lineNumbers: array of Integer) returns String; //  (0 = direct; 1 = indirect)
    action sendApprovalToIbiz(ibizWorkflowID: Integer, offerStatus: Integer, comment: String) returns String;
    action simulateTaxes(offerID: String, productCode: Integer, lotID: Integer, conditionType: String, commercialProposal: String) returns String;
    action sendTHNotificationMailTemplate(offerID:String,tenderId: String, CountryCode: String) returns String;

    @cds.persistence.exists
    entity THQuotationDelevery  as projection on TransactionalData.THQuotationDelevery
}
