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
using { com.bayer.SXTENDER.ClaimsData} from '../db/ClaimsData';
using { com.bayer.SXTENDER.ClaimsViews } from '../db/ClaimsViews';


using {
    User,
    Country,
    managed,
    cuid
} from '@sap/cds/common';


service StandardAppService @(path : 'sta_tender')@(requires : [
    'authenticated-user',
    'f_tndr_cag_admin',
    'f_tndr_cag_technical_user',
    'f_tndr_cag_standardtender_user'
]) {
    

    @readonly 
    //@cds.persistence.exists
    entity BrandsInTender  as projection on TransactionalDataViews.BrandsInTender;
    @cds.redirection.target
    //@cds.persistence.exists
    entity TenderFormView as projection on TransactionalData.PT_TMTEND {
        *,
        Institute.InstituteType,
        Institute.InstituteName,
        Institute.DirectTender,
        Institute.State,
        Institute.InstituteID as ParentInstituteID,
        Institute.External_InstituteId,
        Institute.Address,
        Institute.CustomerID,
        Institute.Province.Name as ProvinceName,
        Institute.City,
        Institute.CifCode,
        Institute.RegionalHealthSystem,
        Country.Region
    }; 
    //@cds.persistence.exists
    entity CountryRegionsTableView as projection on MasterData.CountryRegions;
    //@cds.persistence.exists
    entity PT_TMAWRDCR as projection on TransactionalData.PT_TMAWRDCR;
    //@cds.persistence.exists
    entity AppConfig @readonly as projection on AdminData.AppConfig;
    //@cds.persistence.exists
    entity AwardCriteriaTableView as select from TransactionalData.PT_TMTEND as tend
    left outer join TransactionalData.PT_TMAWRDCR as cr on tend.TenderID = cr.TENDERID
    left outer join MasterData.AwardCriteriaValueHelp as ac ON cr.AwardCriteria is null and ac.Criteria is not null and ac.CountryCode = tend.CountryCode
    {
        key tend.CountryCode,
        key tend.TenderID,
	    // COALESCE( cr.AwardCriteria, ac.Criteria ) AS Criteria:String,
        key case when cr.AwardCriteria is not null
            then cr.AwardCriteria
            else ifnull(ac.Criteria, 'NotDefined')
        end as Criteria:String,
        case when cr.Weight is not null
            then cr.Weight
            else 0
        end as Weight:Double
    };
    //@cds.persistence.exists
    entity TenderMasterView as select from TransactionalData.PT_TMTEND as tender
        inner join AdminData.PT_TMUSER as CreatedByUser on CreatedByUser.UserID = tender.createdBy 
        inner join AdminData.PT_TMUSER as ModifyedByUser on ModifyedByUser.UserID = tender.modifiedBy
        left join TransactionalData.PT_TMOFRS as offer on offer.TenderID = tender.TenderID
        left join TransactionalDataViews.BrandsInTender as brands on brands.OFFERID = offer.OfferID
        left join TransactionalData.PT_TMQUTO as quotation on quotation.OfferID = offer.OfferID and quotation.Active = 1 {
        tender.CountryCode,
        key tender.TenderID,
        tender.Classification,
        tender.TenderName,
        tender.createdBy,
        offer.Distributor.DistributorName,
        tender.Institute.InstituteName,
        tender.Institute.InstituteID,
        key offer.OfferID,
        offer.OfferValue.VALUE,
        case 
            when offer.OfferStatus.STATUS = 'Results Recorded' and offer.OfferStatusTable.TableStatus <> ''
                then offer.OfferStatusTable.TableStatus
            else offer.OfferStatus.STATUS
        end as STATUS:String(255),
        ifnull(offer.OfferStatusTable.TableStatus, offer.OfferStatus.STATUS) as TableStatus:String(255),                 
        tender.PublicationDate,
        offer.InternalBidDueDate,
        tender.BidDueDate,
        max(brands.BRANDID) as BrandID:String,
        tender.createdAt,
        tender.modifiedBy,
        tender.modifiedAt, 
        CreatedByUser.UserName as createdByName,
        ModifyedByUser.UserName as modifiedByName,
        tender.Country.Region,
        tender.Custom.Integer_1 as Custom_Integer_1,
        tender.Custom.Integer_2 as Custom_Integer_2,
        tender.Custom.Integer_3 as Custom_Integer_3,
        ifnull(quotation.EffectiveDate, ADD_DAYS(CURRENT_DATE,1)) as EffectiveDate:Date,
        ifnull(quotation.ExpiryDate, ADD_DAYS(ADD_YEARS(CURRENT_DATE, 1), 1)) as ExpiryDate:Date,
        tender.Custom.String_1 as Custom_String_1,
        tender.Custom.Date_1 as Custom_Date_1,
        offer.Custom.String_1 as Offer_Custom_String_1
    }where tender.Active = 1 and ifnull(offer.Active, 1) = 1
    group By tender.CountryCode,
        tender.TenderID,
        tender.Classification,
        tender.TenderName,
        tender.createdBy,
        offer.Distributor.DistributorName,
        tender.Institute.InstituteName,
        tender.Institute.InstituteID,
        offer.OfferID,
        offer.OfferValue.VALUE,
        offer.OfferStatus.STATUS,     
        offer.OfferStatusTable.TableStatus,    
        tender.PublicationDate,
        offer.InternalBidDueDate,
        tender.BidDueDate,
        tender.createdAt,
        tender.modifiedBy,
        tender.modifiedAt,
        CreatedByUser.UserName,
        ModifyedByUser.UserName,
        tender.Country.Region,
        tender.Custom.Integer_1,
        tender.Custom.Integer_2,
        tender.Custom.Integer_3,
        quotation.EffectiveDate,
        quotation.ExpiryDate,
        tender.Custom.String_1,
        tender.Custom.Date_1,
        offer.Custom.String_1;

    @cds.redirection.target
    //@cds.persistence.exists
    entity InstitutesView as select from MasterData.PT_TMINST as inst
        left join MasterData.PT_TMINSHIER as hier on hier.InstituteID = inst.InstituteID {
        *,
        key inst.CountryCode,
        key inst.InstituteID,
        inst.ActiveRecord,
        hier.ParentInstituteID as HieraryParentInstituteID,
        hier.InstituteID as HierarchyInstituteID,
        case when hier.ParentInstituteID is null
            then null
            else hier.ParentInstituteID
        end as ParentInstituteID: Integer,
        CustomerID as CustomerID: String,
        inst.InstituteTerritory.Territory,
        inst.InstituteTerritory.IsKAM
    }where inst.ActiveRecord = 'Yes'
    order by CountryCode, InstituteName;
    //@cds.persistence.exists
    entity ClassifiactionsView as projection on MasterData.MASTER_COUNTRY_CLASSIFICATION as classification {
        *,
        classification.COUNTRY_CODE as CountryCode: String
    }order by CLASSIFICATION;
    //@cds.persistence.exists
    entity CountryInstituteTypeView as projection on MasterData.MASTER_COUNTRY_CHANNELS as instType {
        *,
        instType.ChannelCountry as CountryCode: String
    }order by ChannelName;
    //@cds.persistence.exists
    entity CountryTenderNo as projection on TransactionalDataViews.CountryTenderNo;
    //@cds.persistence.exists
    entity TenderOffers as projection on TransactionalDataViews.TenderOffers;
    //@cds.persistence.exists
    entity PT_TMOFRS as projection on TransactionalData.PT_TMOFRS;
    //@cds.persistence.exists
    entity PT_TMTNOFST as projection on TransactionalData.PT_TMTNOFST;
    //@cds.persistence.exists
    entity PT_TMINST   as projection on MasterData.PT_TMINST;
    //@cds.persistence.exists
    entity PT_TMTEND as projection on TransactionalData.PT_TMTEND;
    //@cds.persistence.exists
    entity PT_TMDIST as projection on MasterData.PT_TMDIST;
    //@cds.persistence.exists
    entity PT_TMOFPR as projection on TransactionalData.PT_TMOFPR;
    //@cds.persistence.exists
    entity PT_TMQUTO as projection on TransactionalData.PT_TMQUTO;
    //@cds.persistence.exists
    entity PT_TMBDPR as projection on TransactionalData.PT_TMBDPR {
        *,
        Product: redirected to TransactionalData.PT_TMOFPR
    };

    @cds.redirection.target
    //@cds.persistence.exists
    entity OfferFormView as select from TransactionalData.PT_TMOFRS{
        *,
        @Core.Computed: false
        ifnull(NewOfferDueDate, Tender.BidDueDate) as OfferDueDate: Date,
        Tender.InstituteID as InstituteID,
        Tender.TenderChannel as Channel,
        Tender.TenderName,
        OfferStatus.STATUS as OfferStatus
    };
    //inner join TransactionalData.PT_TMTEND as tender on tender.TenderID = offer.TenderID ;
    /*{
        key offer.OfferID,
        key offer.TenderID,
        offer.InternalBidDueDate,
        offer.WholesaleOffer,
        offer.Division,
        tender.BidDueDate,
        offer.Distributor.DistributorName,
        offer.Distributor.DistributorID,
        offer.SellingCompanyDetails.LegalEntityName,
        offer.SellingCompanyDetails.LegalEntityID
    };*/ // Form used in the Offer tab
    //@cds.persistence.exists
    entity CountryProductPackView as select from MasterData.PT_TMCTPRDPCK{
        *
    };
    //@cds.persistence.exists
    entity DistinctProductScopeView as select from CountryProductPackView {
        COUNTRYCODE as CountryCode,
        key ProductScope
    } group by ProductScope, COUNTRYCODE;

    //@cds.persistence.exists
    entity OfferProductsTableView as select from TransactionalData.PT_TMOFPR {
        *,
        key ProductCode,
        key OfferID,
        key TenderID,
        Active,
        SKU.PRODUCTPACKNAME as ProductPackName,
        UnitPerPack as UoM,
        Price.NetPrice as NetPrice,
        RequestedVolume,
        Price.OfferPrice * (1 - Price.Deductions) *
        case 
        when Price.FOCType = 'FOC 1'
            then 
                case 
                    when Price.FOC_ABS_PCT = 'PCT'
                        then RequestedVolume - round(RequestedVolume * Price.FOC)
                            when Price.FOC_ABS_PCT = 'STP'
                            then RequestedVolume - floor(RequestedVolume / Price.FOCStep) * Price.FOC
                        else RequestedVolume - Price.FOC
                end
            else RequestedVolume        
        end as TotalAmount:Double,
        Offer.Currency as Currency,
        Offer.Tender.Country.Region,
        SKUCountry.RegistrationValidUntil,
        Offer.Tender.Custom.Integer_1 as ContractDuration_1,
        NLContractDurationOfferPrices.OfferPrice_1,
        Offer.Tender.Custom.Integer_2 as ContractDuration_2,
        NLContractDurationOfferPrices.OfferPrice_2,
        Offer.Tender.Custom.Integer_3 as ContractDuration_3,
        NLContractDurationOfferPrices.OfferPrice_3,
        case   
            when (Price.NetofferPrice is not null and Price.NetofferPrice <> 0) 
            and (RequestedVolume is not null and RequestedVolume <> 0) 
            and (RequestedVolume <> Price.FOC)
                then 
                    round(Price.NetofferPrice * ( 
                        (
                            case 
                                when Offer.FOCType = 'FOC 1'
                                    then RequestedVolume - (
                                        case
                                            when Price.FOC_ABS_PCT = 'ABS'
                                                then Price.FOC
                                            else Price.FOC * RequestedVolume
                                        end
                                    ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                                else RequestedVolume 
                            end
                        ) //=$self.paidVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                        
                    / 
                    
                    (
                        case 
                            when Offer.FOCType = 'FOC 2'
                                then RequestedVolume + (
                                    case
                                        when Price.FOC_ABS_PCT = 'ABS'
                                            then Price.FOC
                                        else Price.FOC * RequestedVolume
                                    end
                                ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                            else RequestedVolume 
                        end
                    ) //=$self.totalVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                    
                    ),2)
            else null
        end as NetPriceFOC:Double,
        case   
            when UnitPerPack = 'Pack'
                then Cogs.COGS
            else round(Cogs.COGS / SKU.PACKFACTOR,2)
        end as cogsUoM :Double,
        case   
            when Price.NetofferPrice is not null
                then 
                    Price.NetofferPrice * (
                        case 
                            when Offer.FOCType = 'FOC 1'
                                then RequestedVolume - (
                                    case
                                        when Price.FOC_ABS_PCT = 'ABS'
                                            then Price.FOC
                                        else Price.FOC * RequestedVolume
                                    end
                                ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                            else RequestedVolume 
                        end
                    ) //=$self.paidVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
            else null
        end as GrossSales:Double,
        case   
            when Price.NetofferPrice is not null
                then 
                    (Price.NetofferPrice * 
                        (
                            case 
                                when Offer.FOCType = 'FOC 1'
                                    then RequestedVolume - (
                                        case
                                            when Price.FOC_ABS_PCT = 'ABS'
                                                then Price.FOC
                                            else Price.FOC * RequestedVolume
                                        end
                                    ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                                else RequestedVolume 
                            end
                        ) //=$self.paidVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                    ) - (
                        (
                            case   
                                when UnitPerPack = 'Pack'
                                    then Cogs.COGS
                                else round(Cogs.COGS / SKU.PACKFACTOR,2)
                            end
                        ) //=$self.cogsUoM but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future) 
                    * 
                        (
                            case 
                                when Offer.FOCType = 'FOC 2'
                                    then RequestedVolume + (
                                        case
                                            when Price.FOC_ABS_PCT = 'ABS'
                                                then Price.FOC
                                            else Price.FOC * RequestedVolume
                                        end
                                    ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                                else RequestedVolume 
                            end
                        ) //=$self.totalVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                    )
            else null
        end as GrossProfit:Double,
        case   
            when (Price.NetofferPrice is not null and Price.NetofferPrice <> 0) 
            and (RequestedVolume is not null and RequestedVolume <> 0) 
            and (RequestedVolume <> Price.FOC)
                then 
                    round(1 - ((
                        (
                            case   
                                when UnitPerPack = 'Pack'
                                    then Cogs.COGS
                                else round(Cogs.COGS / SKU.PACKFACTOR,2)
                            end
                        ) //=$self.cogsUoM but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                    * 
                        (
                            case 
                                when Offer.FOCType = 'FOC 2'
                                    then RequestedVolume + (
                                        case
                                            when Price.FOC_ABS_PCT = 'ABS'
                                                then Price.FOC
                                            else Price.FOC * RequestedVolume
                                        end
                                    ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                                else RequestedVolume 
                            end
                        ) //=$self.totalVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                    ) / (Price.NetofferPrice * 
                        (
                            case 
                                when Offer.FOCType = 'FOC 1'
                                    then RequestedVolume - (
                                        case
                                            when Price.FOC_ABS_PCT = 'ABS'
                                                then Price.FOC
                                            else Price.FOC * RequestedVolume
                                        end
                                    ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                                else RequestedVolume 
                            end
                        ) //=$self.paidVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                    ) ),2) 
            else null
        end as GrossMargin:Double,
        SKU.ProductType
    } order by SORTER asc; // Form used in the Offer tab - offer products

    action copyOffer(offerID:String, type: String, QuotationInstituteID: Integer) returns String;
    action sendHematologyNotificationMailTemplate(offerID:String,tenderId: String, CountryCode: String, url: String) returns String;
    action softDeleteOffer(offerID:String) returns String;
    function getNotificationMailTemplate(offerID:String, templateId: String, url: String) returns String;

   /* entity OfferProductsDetailView as select from TransactionalData.PT_TMOFPR as pr
        left join MasterData.PT_TMCTPRDPCK as ctprdck on ctprdck.PRODUCTPACKID = pr.ProductCode
                                                       and ctprdck.COUNTRYCODE = pr.CountryCode
        left join ProductBrand as prbrand on prbrand.PRODUCTPACKID = pr.ProductCode
        left join TransactionalData.PT_TMOFRS as offer on offer.OfferID = pr.OfferID
        left join PakistanMasterDistributors as pkdist on pkdist.BU = ctprdck.BU 
                                                       and pkdist.InstituteID = offer.QuotationInstituteID 
        left join MasterData.PT_TMINST as inst on offer.QuotationInstituteID = inst.InstituteID{
            pr.TenderID,
        key pr.OfferID,
            pr.SubmittedOn,
            pr.SubmittedBy,
        key pr.Active,
        key pr.ProductCode,
            pr.Reference,
            pr.AlternateOfferYN,
            pr.RequestedVolume,
            pr.UnitPerPack,
            pr.SampleYN,
            pr.SampleQuantity,
            pr.DocumentsRequired,
            pr.FirstShipment,
            pr.NoofLots,
            pr.IntervalBetweenShipments,
            pr.NoOfTier,
            pr.DiscOrOffer,
            pr.PaymentTerms,
            pr.SNo,
            pr.ActiveProduct,
            pr.Comment,
            pr.INCOTerms,
            pr.SORTER,
            pr.DEFAULT_COMMISSION_RATE,
            pr.SUPPLY_UPDATE,
            pr.PAYMENT_UPDATE,
            pr.Line,
            pr.DeliveryConditions,
            pr.MinInvoiceAmount,
            pr.PricingPolicyCluster,
            pr.OfferType,
            pr.AnticipatedRequestedQuantity,
            pr.MaxPrice,
            pr.Channel,
        key pr.LotID,
            pr.WorkflowProductID,
            pr.IbizWorkflowID,
            pr.CountryCode,
            pr.DistributorID,
            pr.Custom.String_1 as Custom_String_1,
            pr.Custom.Integer_1 as Custom_Integer_1,
            pkdist.DistributorID as PakistanDistributorID,
            pkdist.DistributorName as PakistanDistributorName,
            SKU.MoleculeName as MoleculeName,
            SKUCountry.CODE1 as Code1,
            SKUCountry.CODE2 as Code2,
            SKUCountry.CODE3 as Code3,
            SKU.ProductGenericName as ProductGenericName,
            SKU.PRODUCTPACKNAME,
            SKUCountry.GOV_CODE as Gov_Code,
            ctprdck.BU,
            ctprdck.RegistrationValidUntil,
            prbrand.HLEVEL4_NAME as BrandName,
            inst.INCOTerms as IncoTerm,
            @Core.Computed: false
            ifnull(PricingPolicy.Value, 0) as VwBudgetedProfitability:Double
    };*/
    //@cds.persistence.exists
    entity OfferProductsDetailView as select from TransactionalData.PT_TMOFPR {
        *,
        key OfferID,
        key Active,
        key ProductCode,
        key LotID,
        CountryCode,
        SKU.MoleculeName as MoleculeName,
        SKUCountry.CODE1 as Code1,
        SKUCountry.CODE2 as Code2,
        SKUCountry.CODE3 as Code3,
        SKU.ProductGenericName as ProductGenericName,
        SKUCountry.GOV_CODE as Gov_Code,
        SKU.PRODUCTPACKNAME,
        SKUCountry.BU,
        SKUCountry.RegistrationValidUntil,
        SKU.Product.HLEVEL4_NAME as BrandName,
        SKU.PACKFACTOR,
        Offer.Tender.Institute.INCOTerms,
        Offer.Tender.Institute.InstituteName,
        Offer.Tender.Classification as TenderClassification,
        @Core.Computed: false
        ProductActiveSKUs.ACTIVE_MATERIAL_NUMBERS,
        @Core.Computed: false
        ProductInActiveSKUs.INACTIVE_MATERIAL_NUMBERS,
        @Core.Computed: false
        case when PricingPolicy.Type = 'BudgetedProfitability'
            then PricingPolicy.Value 
            else 0
        end as VwBudgetedProfitability:Double,
        SKU.ProductType
    };
    //@cds.persistence.exists
    entity OfferProductsTotalForOffer as select from TransactionalData.PT_TMOFRS as offer
        inner join OfferProductsTableView as product on product.OfferID = offer.OfferID {
        key offer.OfferID,
        sum(product.TotalAmount) as OfferTotal:Double,
        offer.Currency as Currency:String(3),
        offer.Tender.Country.Region
    } group by offer.OfferID,
               offer.Currency,
               offer.Tender.Country.Region;
    //@cds.persistence.exists
    entity Country as projection on MasterData.PT_TMCTRY;
    //@cds.persistence.exists
    entity Users as projection on AdminData.PT_TMUSER;
    //@cds.persistence.exists
    entity UserCountries @readonly @(restrict: [
		{grant: '*', to: 'authenticated-user', where: 'User.CWID = $user.id'}
	])as projection on AdminData.PT_TMUSERCTRY {
        *,
        Country: redirected to Country,
        User: redirected to Users,
        User.UserName,
        User.UserEmail
    };
    //@cds.persistence.exists
    entity UsersPerCountry @readonly @(cds.redirection.target:false) as projection on AdminData.PT_TMUSERCTRY {
        *,
        User.UserName as UserName,
        Country: redirected to Country,
        User: redirected to Users,
    };
    //@cds.persistence.exists
    entity UsersHavingOneCountry @(cds.redirection.target:false) as select from UsersPerCountry {
        key CWID,
        max(CountryCode) as CountryCode: String,
        count(CountryCode) as numberOfCountries: Integer,
        max(UserName) as UserName: String
    }
    group by CWID
    having count(CountryCode) = 1;
    //@cds.persistence.exists
    entity CountryTenderBrands @readonly as projection on TransactionalDataViews.CountryTenderBrands;
    //@cds.persistence.exists
    entity CountryStatusses @readonly as projection on MasterData.MASTER_COUNTRY_STATUS;
    //@cds.persistence.exists
    entity Divisions @readonly @(cds.redirection.target:false)    as projection on MasterDataViews.Divisions;
    //@cds.persistence.exists
    entity CountryLegalEntity @readonly @(cds.redirection.target:false) as projection on MasterDataViews.CountryLegalEntity;
    @cds.redirection.target
    //@cds.persistence.exists
    entity PT_TMAPPRST as projection on TransactionalData.PT_TMAPPRST{
        *,
        OfferProduct: redirected to TransactionalData.PT_TMOFPR on OfferProduct.OfferID     = OfferId
                                  and OfferProduct.ProductCode = productcode
                                  and OfferProduct.Active = Active
                                  and OfferProduct.LotID = LotID
    };
    //@cds.persistence.exists
    entity StandardTenderPriceConditionView as select from TransactionalDataViews.StandardTenderPriceConditionView;
    //@cds.persistence.exists
    entity PriceConditionSpecialPriceView as projection on TransactionalDataViews.StandardTenderPriceConditionView {
        *,
        @Core.Computed: false
        ifnull(Level2Discount2, (SpecialPrice - COGS) / SpecialPrice) as Margin: Double
    } where CountryCode = 'PL';
    //@cds.persistence.exists
    entity PriceConditionWithMaximumPriceView as projection on TransactionalDataViews.StandardTenderPriceConditionView {
        *,
        @Core.Computed: false
        ifnull(Level2Discount2, (SpecialPrice - COGS) / SpecialPrice) as Margin: Double
    } where CountryCode = 'PL';
    //@cds.persistence.exists
    entity PriceConditionPriceView as projection on TransactionalDataViews.StandardTenderPriceConditionView {
        CountryCode,
        Region,
        TenderID,
        OfferID,
        ProductCode,
        RequestedVolume,
        hasPriceCondition,
        PriceConditionID,
        ClassificationID,
        Classification,
        ConditionType,
        Division,
        isMain,
        CurrentBasePrice,
        BasePrice,
        OfferPrice,
        Discount,
        Tax,
        Currency,
        Price3 as NetPrice,
        Level3Discount1 as Deductions,
        NetOfferPrice
    };
    //@cds.persistence.exists
    entity PriceConditionDiscountView as projection on TransactionalDataViews.StandardTenderPriceConditionView{
        CountryCode,
        Region,
        TenderID,
        OfferID,
        ProductCode,
        RequestedVolume,
        hasPriceCondition,
        PriceConditionID,
        ClassificationID,
        Classification,
        ConditionType,
        Division,
        isMain,
        CurrentBasePrice,
        BasePrice,
        OfferPrice,
        Discount,
        Tax,
        Currency,
        Price3 as NetPrice,
        Level3Discount1 as Deductions,
        NetOfferPrice
    };
    //@cds.persistence.exists
    entity PriceConditionTaiwanPriceView as projection on TransactionalDataViews.StandardTenderPriceConditionView;
    //@cds.persistence.exists
    entity PriceConditionTaiwanDiscountView as projection on TransactionalDataViews.StandardTenderPriceConditionView;
    //@cds.persistence.exists
    entity PriceConditionNLPriceView as projection on TransactionalDataViews.StandardTenderPriceConditionView;
    //@cds.persistence.exists
    entity PriceConditionNLDiscountView as projection on TransactionalDataViews.StandardTenderPriceConditionView;
    //@cds.persistence.exists
    entity PriceConditionPriceWithFOCView as projection on TransactionalDataViews.StandardTenderPriceConditionView {
            CountryCode,
            Region,
            TenderID,
            OfferID,
            ProductCode,
            RequestedVolume,
            hasPriceCondition,
            PriceConditionID,
            ClassificationID,
            Classification,
            ConditionType,
            Division,
            isMain,
            CurrentBasePrice,
            BasePrice,
            OfferPrice,
            Discount,
            Tax,
            Currency,
            Price3 as NetPrice,
            Level3Discount1 as Deductions,
            NetPrice as NetOfferPrice
    }where ConditionType = 'PriceWithFOC';
    //@cds.persistence.exists
    entity PriceConditionDiscountWithFOCView as projection on TransactionalDataViews.StandardTenderPriceConditionView {
            CountryCode,
            Region,
            TenderID,
            OfferID,
            ProductCode,
            RequestedVolume,
            hasPriceCondition,
            PriceConditionID,
            ClassificationID,
            Classification,
            ConditionType,
            Division,
            isMain,
            CurrentBasePrice,
            BasePrice,
            OfferPrice,
            Discount,
            Tax,
            Currency,
            Price3 as NetPrice,
            Level3Discount1 as Deductions,
            NetPrice as NetOfferPrice
    };
    //@cds.persistence.exists
    entity PriceConditionClassification as select from TransactionalData.PriceConditionClassification;
    //@cds.persistence.exists
    entity FreeGoodsOther as select from TransactionalData.FreeGoodsOther {
        *,
       ProductPack.PRODUCTPACKNAME as ProductPackName: String
    };
    //@cds.persistence.exists
    entity InstituteDistributorBrandProduct as projection on MasterDataViews.InstituteDistributorBrandProduct;
    //@cds.persistence.exists
    entity TenderChannel as projection on MasterData.TenderChannel;
    //@cds.persistence.exists
    entity OfferValidation as projection on TransactionalDataViews.OfferValidation;
    //@cds.persistence.exists
    entity OfferProductValidation as projection on TransactionalDataViews.OfferProductValidation;
    //@cds.persistence.exists
    entity CountryLegalEntitySignatories as projection on MasterData.COUNTRY_LEGAL_ENTITY_SIGNATORIES as signatory {
        *,
        signatory.COUNTRY_CODE as CountryCode
    };
    //@cds.persistence.exists
    entity ApproverList as projection on MasterData.CountryApprovers;
    //@cds.persistence.exists
    entity ApproverTypes as projection on MasterData.ApproverTypes;
    //@cds.persistence.exists
    entity OfferProductOfferStatus as projection on TransactionalData.OfferProductOfferStatus{
        *,
        ApproverList: redirected to ApproverList,
        ApproverTypes: redirected to ApproverTypes
    };

    @cds.redirection.target
    //@cds.persistence.exists
    entity ProductPricesCheckView as select from TransactionalData.PT_TMOFPR as product{
        key product.OfferID,
        product.Active,
        case 
                    when count(product.PriceCondition.ProductCode) = count(product.ProductCode)
                        theN true
            			else false 
        end as allProductPricesSet:Boolean
    }where product.Offer.OfferStatus.STATUS = 'Offer Created' and product.ActiveProduct = 1
    group by product.OfferID, product.Active, product.Offer.OfferStatus.STATUS, product.ActiveProduct;

    //@cds.persistence.exists
    entity AwardedProducts as select from TransactionalData.PT_TMTRRES as result
        inner join OfferProducts as product on result.OfferID = product.OfferID
                                                          and result.ProductCode = product.ProductCode
                                                          and result.LotID = product.LotID
    {
        *,
        result.TenderID,        
    key result.OfferID,        
        result.CountryCode,       
    key result.ProductCode, 
        result.Active,
        result.LotID,
        product.SORTER
    };
    //@cds.persistence.exists
    entity OfferProducts as projection on TransactionalData.PT_TMOFPR {
        TenderID,        
    key OfferID,        
        CountryCode,       
    key ProductCode,
    key LotID,
    key Active,
        SORTER
    };
    //@cds.persistence.exists
    entity AwardedProductFormView as select from TransactionalData.PT_TMTRRES as result
        inner join TransactionalData.PT_TMOFPR as product on result.OfferID = product.OfferID
                                                          and result.ProductCode = product.ProductCode
                                                          and result.LotID = product.LotID
        inner join TransactionalData.PriceCondition as priceCondition on result.ProductCode = priceCondition.ProductCode
                                                        and result.OfferID = priceCondition.OfferID
                                                        and result.LotID = priceCondition.LotID 
        left join TransactionalData.FreeGoodsOther as freegoods
                            on freegoods.PriceCondition.ID = priceCondition.ID
                            and freegoods.ProductPackId = priceCondition.ProductCode
    {
        result.TenderID,
        key result.OfferID,
        key result.ProductCode,
        result.CountryCode,
        result.InstituteID,
        result.ContractNo,
        result.Outcome,
        result.ErrorInSubmission,
        result.AwardedCompany,
        result.AwardedProduct,
        result.AwardedPrice,
        result.Currency,
        result.AwardedQty,
        result.UoM,
        result.Reason,
        result.Comment,
        product.Active,
        key result.LotID,
        freegoods.FreeGoodsOther,
        freegoods.FreeGoodsOther_ABS_PCT,
        freegoods.FreeGoodsOther_Step,
        freegoods.ADD_INCLUDE,
        case 
            when freegoods.FreeGoodsOther is null
                then 'NA'
            when freegoods.FreeGoodsOther_ABS_PCT = 'PCT'
                then round(100 * freegoods.FreeGoodsOther, 2) || '% (' || freegoods.ADD_INCLUDE || ')'
            when freegoods.FreeGoodsOther_ABS_PCT = 'ABS'
                then freegoods.FreeGoodsOther || ' '  || result.UoM || '(s)' || ' (' || freegoods.ADD_INCLUDE || ')'
            when freegoods.FreeGoodsOther_ABS_PCT = 'STP'
                then freegoods.FreeGoodsOther || ' '  || result.UoM || '(s)' || ' for each ' || freegoods.FreeGoodsOther_Step || ' ' || result.UoM || '(s)' || ' purchased (' || freegoods.ADD_INCLUDE || ')'
        end as FOC:String,
        product.RequestedVolume as RequestedVolume: Integer,
        result.Custom.String_1 as Custom_String_1,
        result.Custom.String_2 as Custom_String_2,
        result.Custom.String_3 as Custom_String_3,
        result.Custom.String_4 as Custom_String_4,
        result.Custom.String_5 as Custom_String_5,
        result.Custom.String_6 as Custom_String_6,
        result.Custom.String_7 as Custom_String_7,
        result.Custom.String_8 as Custom_String_8,
        result.Custom.String_9 as Custom_String_9,
        result.Custom.String_10 as Custom_String_10,
        result.Custom.Integer_1 as Custom_Integer_1,
        result.Custom.Integer_2 as Custom_Integer_2,
        result.Custom.Integer_3 as Custom_Integer_3,
        result.Custom.Integer_4 as Custom_Integer_4,
        result.Custom.Integer_5 as Custom_Integer_5,
        result.Custom.Integer_6 as Custom_Integer_6,
        result.Custom.Integer_7 as Custom_Integer_7,
        result.Custom.Integer_8 as Custom_Integer_8,
        result.Custom.Integer_9 as Custom_Integer_9,
        result.Custom.Integer_10 as Custom_Integer_10,
        result.Custom.Double_1 as Custom_Double_1,
        result.Custom.Double_2 as Custom_Double_2,
        result.Custom.Double_3 as Custom_Double_3,
        result.Custom.Double_4 as Custom_Double_4,
        result.Custom.Double_5 as Custom_Double_5,
        result.Custom.Double_6 as Custom_Double_6,
        result.Custom.Double_7 as Custom_Double_7,
        result.Custom.Double_8 as Custom_Double_8,
        result.Custom.Double_9 as Custom_Double_9,
        result.Custom.Double_10 as Custom_Double_10,
        result.Custom.Date_1 as Custom_Date_1,
        result.Custom.Date_2 as Custom_Date_2,
        result.Custom.Date_3 as Custom_Date_3,
        result.Custom.Date_4 as Custom_Date_4,
        result.Custom.Date_5 as Custom_Date_5,
        result.Custom.Date_6 as Custom_Date_6,
        result.Custom.Date_7 as Custom_Date_7,
        result.Custom.Date_8 as Custom_Date_8,
        result.Custom.Date_9 as Custom_Date_9,
        result.Custom.Date_10 as Custom_Date_10,
        result.TotalAwardedValue,
        priceCondition.ID as priceconditionID : UUID

    };
    //@cds.persistence.exists
    entity MasterCountryOutComes as select from MasterData.MASTER_COUNTRY_OUTCOMES;
    //@cds.persistence.exists
    entity MasterOutComeReasons as select from MasterData.PT_TMOUTRS;
    //@cds.persistence.exists
    entity MasterCountryCurrencies as select from MasterData.CountryCurrency;
    //@cds.persistence.exists
    entity StandardDivisions as projection on MasterData.StandardDivisions;
    //@cds.persistence.exists
    entity OfferStatus as projection on TransactionalDataViews.OfferStatus;
    //@cds.persistence.exists
    entity ProductPack as projection on MasterData.PT_TMPRDPCK;
    //@cds.persistence.exists
    entity PriceCondition as projection on TransactionalData.PriceCondition;
    //@cds.persistence.exists
    entity CountryBrands as select from CountryBrandProducts as Product{
        key Product.COUNTRY_CODE,
        key Product.BRAND_ID,
        min(Product.BRAND_NAME) as BRAND_NAME:String(500),
        min(Product.DIVISION) as DIVISION:String(500),
        Product.BU
    }where Product.BRAND_ID is not null
    group by Product.COUNTRY_CODE, Product.BRAND_ID, Product.BU;
    //@cds.persistence.exists
    entity CountryBrandProducts @readonly as projection on MasterDataViews.CountryBrandProducts;
    //@cds.persistence.exists
    entity CompetitorResultsTableView as select from TransactionalData.TransCompetitorResult;
    //@cds.persistence.exists
    entity MasterCompetitors as select from MasterData.MasterCompetitors;
    //@cds.persistence.exists
    entity MasterCompetitorProducts as select from MasterData.MasterCompetitors;
    //@cds.persistence.exists
    entity WordTemplate as projection on AdminData.WordTemplate;
    //@cds.persistence.exists
    entity WordTemplateCountry as projection on AdminData.WordTemplateCountry{
        *,
        WordTemplates.name,
        WordTemplates.filename,
        WordTemplates: Redirected to WordTemplate on WordTemplates.templateId = templateId
    };

    //@cds.persistence.exists
    entity WordAttachments {
        key offerId    : String(50);
        key templateId : Integer;
            content    : LargeBinary @Core.MediaType : mediaType; //'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            mediaType  : String      @Core.IsMediaType;
    }
    //@cds.persistence.exists
    entity ExcelTemplate as projection on AdminData.ExcelTemplate;
    //@cds.persistence.exists
    entity ExcelTemplateCountry as projection on AdminData.ExcelTemplateCountry{
        *,
        ExcelTemplates.name,
        ExcelTemplates.filename,
        ExcelTemplates: Redirected to ExcelTemplate on ExcelTemplates.templateId = templateId
    };
    //@cds.persistence.exists
    entity ExcelAttachments {
        key offerId    : String(50);
        key templateId : Integer;
            content    : LargeBinary @Core.MediaType : mediaType; //'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            mediaType  : String      @Core.IsMediaType;
    }
    //@cds.persistence.exists
    entity DeliveryProductTableView as select from TransactionalData.PT_TMOFPR as product
        inner join TransactionalData.PT_TMTRRES as result 
            on result.OfferID = product.OfferID and result.ProductCode = product.ProductCode
        left join TransactionalData.PT_TMDLVTR as deliveries 
            on deliveries.OfferID = product.OfferID and deliveries.ProductCode = product.ProductCode
    {
        product.TenderID,
        key product.OfferID,
        key product.ProductCode,
        product.CountryCode,
        result.AwardedProduct,
        result.AwardedQty,
        sum(ifnull(deliveries.ActualDeliveryQuantity,0)) as SumOfDeliveredAmount:Double,
        case 
            when result.AwardedQty = 0 OR sum(deliveries.ActualDeliveryQuantity) is NULL then 0
            else sum(deliveries.ActualDeliveryQuantity)/ result.AwardedQty
        end as DeliveredPercentage:Double,
        product.Offer.Country.Region
    }
    where result.Outcome = 'Won'
    group by product.TenderID, product.OfferID, product.ProductCode, product.CountryCode, result.AwardedProduct, result.AwardedQty, product.Offer.Country.Region;

    // entity DeliveryTrackingDetailView as select from TransactionalData.PT_TMDLVTR
    // {
    //     TenderID,
    // key OfferID,        
    //     CountryCode,
    //     InstituteID,
    //     SKUCode,
    //     SubmittedOn,
    //     SubmittedBy,
    //     Active,
    //     RequestedDeliveryDate,
    //     RequestedQuantity,
    //     ActualDeliveryDate,
    //     ActualDeliveryQuantity,
    // key ProductCode,
    //     PaidOrFree,
    //     PO,
    //     InvoiceNo,
    // key SNo,
    //     LotID,
    //     Institute.InstituteName
    // };
    //@cds.persistence.exists
    entity DeliveryTrackingDetailView as projection on TransactionalData.PT_TMDLVTR;
    //@cds.persistence.exists
    entity PdfEmail: cuid, managed {
        URL : String;
        TenderID: String(50);
        OfferID: String(30);
        TenderInstitute: String(500);
        OfferInstitute: String(500);
        UserEmail: String(255); 
        UserName: String(100);      
        Sent: Boolean;
    };

    //@cds.persistence.exists
    entity ChildInstitutes as select from MasterData.PT_TMINST as inst
        inner join MasterData.PT_TMINSHIER as hier on inst.InstituteID = hier.InstituteID {
        key hier.ParentInstituteID,
        key hier.InstituteID,
        key CountryCode,
            hier.InstituteID as QuotationInstituteID: String,
            inst.InstituteName,
            inst.PaymentTerms
    }
    union select from MasterData.PT_TMINST {
        key InstituteID as ParentInstituteID,
        key InstituteID,
        key CountryCode,
            InstituteID as QuotationInstituteID: String,
            InstituteName,
            PaymentTerms
    };
    //@cds.persistence.exists
    entity ChildInstitutesView as select from ChildInstitutes{
        *,
    }order by InstituteName;
    //@cds.persistence.exists
    entity PakistanMasterDistributors as select from MasterData.DistributorAssignment as pkdist
        inner join MasterData.PT_TMDIST as dist on dist.DistributorID = pkdist.DistributorID{
            key pkdist.InstituteID,
            key pkdist.BU,
            pkdist.DistributorID,
            dist.DistributorName,
            key dist.CountryCode
    }group by pkdist.InstituteID,pkdist.BU,pkdist.DistributorID,dist.DistributorName,dist.CountryCode;
    //@cds.persistence.exists
    entity ProductBrand as select from MasterData.PT_TMPRDHIER as prdhier
        inner join MasterData.PT_TMPRDPCK as prdpck on prdpck.HLEVEL6_CODE = prdhier.HLEVEL6_CODE {
            key prdpck.PRODUCTPACKID,
                prdhier.HLEVEL6_CODE,
                prdhier.HLEVEL4_NAME
    };
    //@cds.persistence.exists
    entity InstitutesInBranchWithParent as select from MasterData.PT_TMINSHIER as h
        inner join MasterData.PT_TMINST as i on h.InstituteID = i.InstituteID {
            i.InstituteID,
            h.ParentInstituteID
    }where h.ActiveRecord = 'Yes' and
    i.ActiveRecord = 'Yes' and
    i.CountryCode = 'TW'
    union select from MasterData.PT_TMINSHIER as h 
        inner join MasterData.PT_TMINST as i on h.ParentInstituteID = i.InstituteID {
            i.InstituteID,
            h.ParentInstituteID
    }where h.ActiveRecord = 'Yes' and
    i.ActiveRecord = 'Yes' and
    i.CountryCode = 'TW';
    //@cds.persistence.exists
    entity InstituteInBranchView as select from InstitutesInBranchWithParent as p
        inner join MasterData.PT_TMINSHIER as h on p.ParentInstituteID = h.ParentInstituteID
        inner join MasterData.PT_TMINST as i on h.InstituteID = i.InstituteID {
            p.ParentInstituteID,
        key p.InstituteID,
        key i.InstituteName,
            i.PaymentTerms
    }where p.ParentInstituteID <> h.InstituteID 
    and i.InstituteType <> 'Branch' 
    and i.ActiveRecord = 'Yes';
    //@cds.persistence.exists
    entity StandardTenderHistory as projection on TransactionalDataViews.StandardTenderHistory;
    //@cds.persistence.exists
    entity StandardTenderHistorySpain as projection on TransactionalDataViews.StandardTenderHistorySpain;
    //@cds.persistence.exists
    entity PriceConditionCurrentSectionTaiwanView as projection on TransactionalDataViews.PriceConditionCurrentSectionTaiwanView;
    //@cds.persistence.exists
    entity CSVAttachment {
        key Zuellig: Boolean default false;
        content    : LargeBinary @Core.MediaType : 'text/csv';
    }
    //@cds.persistence.exists
    entity TaiwanFASTData {
       content    : LargeBinary @Core.MediaType : 'application/json';
    };
    //@cds.persistence.exists
    entity PT_TMSKUPRDPCK as projection on MasterData.PT_TMSKUPRDPCK;
    //@cds.persistence.exists
    entity ContractInfomation as projection on TransactionalData.ContractInfomation{
        OfferProduct: redirected to PT_TMOFPR,
        *
    };
    //@cds.persistence.exists
    entity MailTemplates                                as projection on AdminData.MailTemplate;
    //@cds.persistence.exists
    entity MailTemplateFiles                            as projection on AdminData.MailTemplateFile;
    //@cds.persistence.exists
    entity Outbox                                       as projection on TransactionalData.OutgoingMails;
    //@cds.persistence.exists
    entity StandardTenderFOCInformation                 as projection on TransactionalDataViews.StandardTenderFOCInformation;   
    @cds.redirection.target
    entity NotificationUserList as select from AdminData.PT_TMUSERCTRY{
        key CountryCode,
        key CWID,
        User: redirected to Users,
        ActiveRecord,
        User.Role,
        User.UserName,
        User.UserEmail
    }where CountryCode = 'NL' and User.Role = 'Hospital Manager';
    //@cds.persistence.exists
    entity InstitutesInGroup as select from PT_TMINST as inst
    inner join MasterData.PT_TMINSHIER as hier 
        on hier.InstituteID = inst.InstituteID {
        inst.CountryCode,
        inst.InstituteType,
        inst.InstituteName,
	    hier.ParentInstituteID,
	    key hier.InstituteID,
    }where inst.CountryCode = 'NL' 
        and inst.ActiveRecord = 'Yes' 
        and hier.ActiveRecord = 'Yes';
    //@cds.persistence.exists
    entity ZagisUploadFile {
        key OfferID   : String(50) default '';
        @Core.MediaType     : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        content    : LargeBinary;
    }
    //@cds.persistence.exists
    entity AwardedOfferDistributors as projection on TransactionalData.AwardedOfferDistributors;
     entity ExtractNLHistoricalInformation {
        key templateId : Integer;
            content    : LargeBinary @Core.MediaType : mediaType; //'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            mediaType  : String      @Core.IsMediaType;
    }
    //@cds.persistence.exists
   entity MaxHierarchy as select from TransactionalData.PT_TMAPPRST{	
        key OfferId,
        key productcode,
        max(Hierarchy) as MaxHierarchy: Integer,
        ApproverName,
        ApprovalStatus
    }where ApprovalStatus = 'Waiting'
    group by OfferId, productcode, ApproverName, ApprovalStatus;
    //@cds.persistence.exists
   entity NLDistributorsView as select from TransactionalData.AwardedOfferDistributors{
        key OfferID,
        key ProductPackID,
        case
           	when count(*) = count(CASE WHEN DistributorName = 'Bayer BV' then 1 END) then 'Direct'
	        when count(CASE when DistributorName = 'Bayer BV' then 1 END) > 0 then 'Mixed'
            else 'Wholesaler'
        end as DistributionType: String
    }group by OfferID, ProductPackID;
    //@cds.persistence.exists
    entity SelectedContractDuration as select from  ContractInfomation{
        key OfferID,
        key ProductCode,
        max(ContractDuration) as ContractDuration: Double,
        max(ContractStartDate) as ContractStartDate : Date,
        max(ContractEndDate) as ContractEndDate : Date,
    }group by OfferID, ProductCode;
    //@cds.persistence.exists
    entity NLExtractOffers as select from TransactionalData.PT_TMTEND as tender
        inner join TransactionalData.PT_TMOFRS as offer
            on offer.TenderID = tender.TenderID
        inner join MasterData.PT_TMINST as inst
            on inst.CountryCode = tender.CountryCode
            and inst.InstituteID = tender.InstituteID
        left join TransactionalData.PT_TMQUTO as qoutation
            on qoutation.OfferID = offer.OfferID
            and qoutation.Active = 1
        left join TransactionalDataViews.OfferStatus as offerStatus
            on offerStatus.OFFER_ID = offer.OfferID
        left join TransactionalData.PT_TMOFPR as product
            on product.OfferID = offer.OfferID
            and product.Active = 1
        inner join MasterData.PT_TMCTPRDPCK as ctprdpck
            on ctprdpck.PRODUCTPACKID = product.ProductCode
            and ctprdpck.COUNTRYCODE = tender.CountryCode
        inner join MasterData.PT_TMPRDPCK as productpack
            on productpack.PRODUCTPACKID = product.ProductCode
        left join TransactionalData.PriceCondition as pc
            on pc.CountryCode = tender.CountryCode
            and pc.OfferID = offer.OfferID
            and pc.ProductCode = product.ProductCode
        left join TransactionalData.PT_TMTRRES as res
            on res.OfferID = offer.OfferID
            and res.ProductCode = product.ProductCode
        left join TransactionalData.PT_TMBDPR as PT_TMBDPR
            on PT_TMBDPR.OfferID = offer.OfferID
            and PT_TMBDPR.ProductCode = product.ProductCode
            and PT_TMBDPR.Active = 1
        left join TransactionalDataViews.NLContractDurationsView as contractdur
            on contractdur.OfferID = offer.OfferID
            and contractdur.PriceCondition_ID = pc.ID
        left join NLDistributorsView as nldist
            on nldist.OfferID = offer.OfferID
            and nldist.ProductPackID = product.ProductCode
        left join SelectedContractDuration as selectedcontractduration
            on selectedcontractduration.OfferID = offer.OfferID
            and selectedcontractduration.ProductCode = product.ProductCode
            {
            key tender.TenderID,
            key offer.OfferID,
            offer.Custom.String_1 as Source : String,
            case when inst.InstituteType = 'Buying Group'
                then 'Purchasing Group'
                else 'BILATERAAL'
            end as Inkoopgroep: String,
            inst.InstituteName,
            tender.TenderName,
            selectedcontractduration.ContractStartDate as EffectiveDate : Date,
            selectedcontractduration.ContractEndDate as ExpiryDate : Date,
            tender.BidDueDate,
            offerStatus.STATUS,
            tender.Custom.String_1 as ManagedBy : String,
            tender.PublicationDate,
            ctprdpck.GOV_CODE,
            productpack.PRODUCTPACKNAME,
            tender.InstituteID,
            round(contractdur.MaxOfferPrice, 2) as OfferPrice_3: Double,
            round(contractdur.AvgOfferPrice, 2) as OfferPrice_2: Double,
            round(contractdur.MinOfferPrice, 2) as OfferPrice_1: Double,
            contractdur.MaxContractDuration as maxContrDur: Double,
            contractdur.AvgContractDuration as secContrDur: Double,
            contractdur.MinContractDuration as minContrDur: Double,
            PT_TMBDPR.NetPrice,
            res.Outcome,
            ifnull(inst.InstituteName, '') as childInstituteName: String,
            nldist.DistributionType,
            selectedcontractduration.ContractDuration,
        }where(tender.CountryCode = 'NL' and tender.Active = 1 and offer.Active = 1 and tender.Custom.String_3 <> '' and inst.InstituteType <> 'Buying Group')
    union select from TransactionalData.PT_TMTEND as tender
        inner join TransactionalData.PT_TMOFRS as offer
            on offer.TenderID = tender.TenderID
        inner join MasterData.PT_TMINST as inst
            on inst.CountryCode = tender.CountryCode
            and inst.InstituteID = tender.InstituteID
        left join TransactionalData.PT_TMQUTO as qoutation
            on qoutation.OfferID = offer.OfferID
            and qoutation.Active = 1
        left join TransactionalDataViews.OfferStatus as offerStatus
            on offerStatus.OFFER_ID = offer.OfferID
        left join TransactionalData.PT_TMOFPR as product
            on product.OfferID = offer.OfferID
            and product.Active = 1
        inner join MasterData.PT_TMCTPRDPCK as ctprdpck
            on ctprdpck.PRODUCTPACKID = product.ProductCode
            and ctprdpck.COUNTRYCODE = tender.CountryCode
        inner join MasterData.PT_TMPRDPCK as productpack
            on productpack.PRODUCTPACKID = product.ProductCode
        left join TransactionalData.PriceCondition as pc
            on pc.CountryCode = tender.CountryCode
            and pc.OfferID = offer.OfferID
            and pc.ProductCode = product.ProductCode
        left join TransactionalData.PT_TMTRRES as res
            on res.OfferID = offer.OfferID
            and res.ProductCode = product.ProductCode
        left join TransactionalData.PT_TMBDPR as PT_TMBDPR
            on PT_TMBDPR.OfferID = offer.OfferID
            and PT_TMBDPR.ProductCode = product.ProductCode
            and PT_TMBDPR.Active = 1
        left join TransactionalDataViews.NLContractDurationsView as contractdur
            on contractdur.OfferID = offer.OfferID
            and contractdur.PriceCondition_ID = pc.ID
        left join NLDistributorsView as nldist
            on nldist.OfferID = offer.OfferID
            and nldist.ProductPackID = product.ProductCode
        left join SelectedContractDuration as selectedcontractduration
            on selectedcontractduration.OfferID = offer.OfferID
            and selectedcontractduration.ProductCode = product.ProductCode
        left join TransactionalData.ContractInfomation as contractinfo
            on contractinfo.OfferID = offer.OfferID
            and contractinfo.ProductCode = product.ProductCode
            {
            key tender.TenderID,
            key offer.OfferID,
            offer.Custom.String_1 as Source : String,
            case when inst.InstituteType = 'Buying Group'
                then 'Purchasing Group'
                else 'BILATERAAL'
            end as Inkoopgroep: String,
            inst.InstituteName,
            tender.TenderName,
            contractinfo.ContractStartDate as EffectiveDate : Date,
            contractinfo.ContractEndDate as ExpiryDate : Date,
            tender.BidDueDate,
            offerStatus.STATUS,
            tender.Custom.String_1 as ManagedBy : String,
            tender.PublicationDate,
            ctprdpck.GOV_CODE,
            productpack.PRODUCTPACKNAME,
            tender.InstituteID,
            round(contractdur.MaxOfferPrice, 2) as OfferPrice_3: Double,
            round(contractdur.AvgOfferPrice, 2) as OfferPrice_2: Double,
            round(contractdur.MinOfferPrice, 2) as OfferPrice_1: Double,
            contractdur.MaxContractDuration as maxContrDur: Double,
            contractdur.AvgContractDuration as secContrDur: Double,
            contractdur.MinContractDuration as minContrDur: Double,
            PT_TMBDPR.NetPrice,
            res.Outcome,
            case
                when tender.Custom.String_3 = ''
                    then ''
                else contractinfo.InstituteName
            end as childInstituteName: String,
            nldist.DistributionType,
            selectedcontractduration.ContractDuration,
        }where(tender.CountryCode = 'NL' and tender.Active = 1 and offer.Active = 1);
    @cds.redirection.target
    //@cds.persistence.exists
    entity NLPriceConditions as projection on TransactionalData.NLPriceConditions; 
    //@cds.persistence.exists
    entity ComplianceOfficerView @(cds.redirection.target:false) as select from TransactionalData.PT_TMOFRS; 
    //@cds.persistence.exists
    entity GlobalStrategicMarketingView @(cds.redirection.target:false) as select from TransactionalData.PT_TMOFRS;   
    //@cds.persistence.exists
    entity SupplyManagementView @(cds.redirection.target:false) as select from TransactionalData.PT_TMOFRS;     
    //@cds.persistence.exists
    entity PLOwnerNameView  @(cds.redirection.target:false) as select from AdminData.PT_TMUSER{
        key UserID,
            UserName,
            CWID,
            UserEmail,
            Role,
            BU,
            Countries.CountryCode
    } where Countries.CountryCode = 'PL' and Role = 'KAM';
    //@cds.persistence.exists
    entity SalesReportsView as select from ClaimsData.ClaimFiles as cf 
        inner join ClaimsData.ClaimData as cd         
            on cd.ClaimFiles.ID = cf.ID
        left join MasterData.PT_TMINST as inst 
            on inst.InstituteID = cd.MainInstituteID 
            and inst.CountryCode = cd.CountryCode
        left join TransactionalData.PT_TMOFRS as offer
            on cd.OfferID = offer.OfferID
        left join ClaimsViews.CountryCurrencyView as CountryCurrency
            on cf.CountryCode = CountryCurrency.CountryCode
        {
            key cd.ID,
            cf.DateFrom,
            cf.DateTo,
            cd.OfferID,
            cf.DistributorID,
            cf.DistributorName,
            cd.MainInstituteID,
            cd.MainInstituteName,
            cd.External_InstituteId,
            cf.FilePeriod,
            cd.BrandId,
            cd.BrandName,
            cd.ProductPackID,
            cd.PRODUCTPACKNAME,
            cd.EANNumber,
            cd.Quantity,
            cd.Quantity * cd.SKU.CONCENTRATION * cd.SKU.PACKFACTOR as QuantityMl: Double,
            cd.WholesalerPurchasePrice,
            cd.WholesalerContractPrice,
            cf.WholesalerPurchaseAmount,
            sum(cd.WholesalerContractPrice * cd.Quantity) as TotalSales: Double,
            cd.Product.RequestedVolume,
            cd.BrandContractVolume,
            cd.BrandUsedVolume,
            cf.CountryCode,
            inst.InstituteType,
            inst.KAM_Territory,
            offer.TenderID,
	        CountryCurrency.Currency,
            CASE 
                WHEN cd.BrandContractCalculatedVolume != 0 
                    THEN cd.Product.RequestedVolume 
                        / 
                    cd.BrandContractCalculatedVolume
                ELSE 0 
            END as ContractBrandUsage : Double,
            ((cd.WholesalerContractPrice * cd.Quantity) / (cd.Quantity * cd.SKU.CONCENTRATION * cd.SKU.PACKFACTOR)) as PricePerMl: Double
        } where cf.CountryCode = 'PL'
        group by 
            cd.ID,
            cf.DateFrom,
            cf.DateTo,
            cd.OfferID,
            cd.DistributorID,
            cf.DistributorName,
            cf.DistributorID,
            cd.MainInstituteName,
            cd.MainInstituteID,
            cd.External_InstituteId,
            cf.FilePeriod,
            cd.BrandId,
            cd.BrandName,
            cd.ProductPackID,
            cd.PRODUCTPACKNAME,
            cd.EANNumber,
            cd.Quantity,
            cd.SKU.CONCENTRATION,
            cd.SKU.PACKFACTOR,
            cd.WholesalerPurchasePrice,
            cd.WholesalerContractPrice,
            cf.WholesalerPurchaseAmount,
            cd.Product.RequestedVolume,
            cd.BrandContractVolume,
            cd.BrandUsedVolume,
            cf.CountryCode,
            inst.InstituteType,
            inst.KAM_Territory,
            offer.TenderID,
	        CountryCurrency.Currency,
            cd.BrandId,
            cd.BrandContractCalculatedVolume;
    //@cds.persistence.exists
    entity OverviewSectionsView as select from SalesReportsView as ow{
            key ow.ID,
            ow.TenderID,
            ow.OfferID,
            ow.CountryCode,
            ow.DistributorID,
            ow.MainInstituteName,
            ow.MainInstituteID,
            ow.ProductPackID,
            ow.InstituteType,
            ow.KAM_Territory,
            ow.Currency,
            ow.DateFrom,
            ow.DateTo,
            ow.QuantityMl AS QuantitySold : Double,
            ow.TotalSales,
            ow.PricePerMl AS MinPrice : Double,
            ow.PricePerMl AS MaxPrice : Double,
            ow.PricePerMl AS AvgPrice : Double,
            ow.BrandId,
            ow.BrandName,
        } where ow.BrandName IS NOT NULL;
           @cds.redirection.target
        entity SalesReportInstitutesView as select from MasterData.PT_TMINST as inst {
            *,
            inst.InstituteTerritory.Territory,
            inst.InstituteTerritory.IsKAM
        }order by CountryCode, InstituteName;
    //@cds.persistence.exists
    entity ExtractPolandSalesReport {
        key templateId    : String;
        key TenderID      : String;
        key CountryCode   : String;
        key DistributorID : String;
        key BrandID       : String;
        key ProductPackID : String;
        key KAM_Territory : String;
        key InstituteType : String;
        key InstituteID   : String;
        key DateFrom      : String;
        key DateTo        : String;
            content       : LargeBinary @Core.MediaType : mediaType; //'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            mediaType     : String      @Core.IsMediaType;
    };
    //@cds.persistence.exists
    entity SalesReportTenderView as Select from TransactionalData.PT_TMTEND as tender
        inner join MasterData.PT_TMINST as inst 
            on inst.InstituteID = tender.InstituteID 
            and inst.CountryCode = tender.CountryCode
        left outer join TransactionalData.PT_TMOFRS as offer 
            on offer.TenderID = tender.TenderID 
            and offer.CountryCode = tender.CountryCode 
            and offer.Active = 1
            and offer.ActiveOffer = 1
        left outer join ClaimsData.ClaimData as cd 
            on cd.OfferID = offer.OfferID 
            and cd.CountryCode = tender.CountryCode{
        tender.createdBy,
        tender.modifiedBy,
        case when cd.OfferID is null 
            then 'No related tender'
            else offer.TenderID
        end as TenderID: String,
        cd.OfferID,
        tender.CountryCode,
        tender.SubmittedBy,
        tender.Active,
        tender.InstituteID,
        inst.InstituteType,
        cd.ProductPackID,
        cd.BrandId
    }    
    where tender.CountryCode = 'PL' and tender.Active = 1
    group by 
        tender.createdBy,
        tender.modifiedBy,
        case when cd.OfferID is null 
            then 'No related tender'
            else offer.TenderID
        end,
        cd.OfferID,
        tender.CountryCode,
        tender.SubmittedBy,
        tender.Active,
        tender.InstituteID,
        inst.InstituteType,
        cd.ProductPackID,
        cd.BrandId;
    //@cds.persistence.exists
    entity ProfitabilityCalcParamView @(cds.redirection.target:false) as select from TransactionalData.PT_TMOFRS;
    //@cds.persistence.exists
    entity Settlements                                  as projection on MasterData.Settlements;
    //@cds.persistence.exists
    entity DiscountCondition @(cds.redirection.target:false) as projection on TransactionalData.DiscountCondition;
    //@cds.persistence.exists
    entity DiscountConditionView as Select from TransactionalData.DiscountCondition as dc
        inner join TransactionalDataViews.StandardTenderPriceConditionView as pc on dc.PriceCondition.ID = pc.PriceConditionID{
            key dc.ID,
            pc.CountryCode,
            pc.Region,
            pc.Currency,
            pc.OfferID,
            pc.ProductCode,
            pc.PriceConditionID,
            dc.Volume,
            dc.Discount,
            dc.NetPriceWithoutTax,
            dc.NetPriceWithTax, 
            pc.Tax
    }where pc.ConditionType = 'Rappel';
    //@cds.persistence.exists
    entity PriceConditionRappelView as Select from TransactionalDataViews.StandardTenderPriceConditionView as std
        left outer join TransactionalDataViews.StandardTenderPriceConditionView as main
            on std.CountryCode = main.CountryCode
            and std.OfferID = main.OfferID
            and std.ProductCode = main.ProductCode
            and main.isMain = true
            and main.PriceConditionID is not null{
                key std.TenderID,
                key std.OfferID,
                key std.ProductCode,
                std.RequestedVolume,
                std.hasPriceCondition,
                std.PriceConditionID,
                std.ClassificationID,
                std.Classification,
                key std.ConditionType,
                std.Division,
                std.isMain,
                main.ConfidentialPrice,
                main.PVL,
                main.RoyalDecree,
                main.Tax,
                std.Liquidation,
                std.RefundDate,
                std.Settlement_ID,
                std.PriceConditionCode,
                std.ESDiscount,
                std.RoyalDecreeValue,
                std.RoyalDecreeIncl,
                std.StandardDiscount,
                std.AdditionalDiscount,
                std.NetPriceWithoutTaxBeforeDeductionRD,
                std.NetPriceWithoutTaxAfterDeductionRD,
                std.NetPriceWithTaxAfterDeductionRD,
                std.NetPriceWithoutTax,
                std.NetPriceWithTax,
                std.MaximumPrice,
                std.ConfidentialDiscount,
                std.RoyalDecreePercentage_1,
                std.MonthlyRentPerUnit,
                std.AnnualValue,
                std.MarketIncentiveID
            };
    //@cds.persistence.exists
    entity CCMPriceConditionView                   as select from TransactionalData.CCMPriceCondition{
        CountryCode,
        key OfferID,
        key TenderID,
        key ProductCode,
        MaterialNumber,
        InstituteID,
        CustomerID,
        Currency,
        YP00,
        YP04,
        YP10,
        YD75,
        YD06,
        YD02,
        YD30,
        SAPBaseGrossPrice,  
        SAPTAX,
        SAPPriceWithTax,
        RoyalDecree,
        RoyalDecreeValue,
        RoyalDecreeIncl,
        ConfidentialPrice,
        NETPRICEWITHOUTTAXAFTERDEDUCTIONRD,
        NETPRICEWITHTAXAFTERDEDUCTIONRD,
        NETPRICEWITHOUTTAX,
        NETPRICEWITHTAX,
        key ConditionType
    };
    //@cds.persistence.exists
    entity PriceConditionDescuentoComercialView         as projection on TransactionalDataViews.StandardTenderPriceConditionView;
    //@cds.persistence.exists
    entity PriceConditionPVLView                        as projection on TransactionalDataViews.StandardTenderPriceConditionView;
    //@cds.persistence.exists
    entity PriceConditionPrecioNetoView                 as projection on TransactionalDataViews.StandardTenderPriceConditionView;
    //@cds.persistence.exists
    entity PriceConditionDescuentoEspecialView          as projection on TransactionalDataViews.StandardTenderPriceConditionView;
    //@cds.persistence.exists
    entity PriceConditionRentalView                     as projection on TransactionalDataViews.StandardTenderPriceConditionView;
    //@cds.persistence.exists
    entity FastConditionContractsView as select from TransactionalData.PT_TMTEND as tender
        inner join TransactionalData.PT_TMOFRS as offer 
            on offer.TenderID = tender.TenderID
            and offer.Active = 1
        inner join TransactionalData.PT_TMOFPR as product 
            on product.OfferID = offer.OfferID
            and product.Active = 1
            and product.ActiveProduct = 1 
        inner join MasterData.PT_TMINST as institute 
            on tender.InstituteID = institute.InstituteID
    {
        tender.TenderID,
        key offer.OfferID,
        product.CountryCode,
        institute.InstituteID,
        institute.InstituteName,
        institute.External_InstituteId,
        offer.Division,
        offer.DistributorID,
        institute.CustomerID,
        tender.User.UserName as Owner:String,
        tender.TenderName as Reference:String,
        tender.Classification as ContractType:String,
        tender.SAPID,
        tender.ExternalID
    }where tender.CountryCode = 'ES' 
    group by tender.TenderID, offer.OfferID, product.CountryCode, institute.InstituteID, institute.InstituteName, institute.External_InstituteId, offer.Division, offer.DistributorID, institute.CustomerID, tender.User.UserName, tender.TenderName, tender.Classification, tender.SAPID, tender.ExternalID;
    //@cds.persistence.exists
    entity ConditionContractsView as select from TransactionalData.PT_TMTEND as tender
        inner join TransactionalData.PT_TMOFRS as offer 
            on offer.TenderID = tender.TenderID
            and offer.Active = 1
        inner join TransactionalData.PT_TMOFPR as product 
            on product.OfferID = offer.OfferID
            and product.Active = 1
            and product.ActiveProduct = 1 
        inner join MasterData.PT_TMINST as institute 
            on tender.InstituteID = institute.InstituteID
        left join TransactionalDataViews.BrandsInTender as brands 
            on brands.OFFERID = offer.OfferID
    {
        tender.TenderID,
        key offer.OfferID,
        product.CountryCode,
        key product.ProductCode,
        product.Price.OfferPrice,
        product.SKU.PRODUCTPACKNAME as ProductPackName:String,
        product.SKU.UOM as UoM:String,
        max(brands.BRANDID) as BrandID:String,
        max(brands.BRANDNAME) as BrandName:String,
        institute.InstituteID,
        institute.InstituteName,
        institute.CustomerID,
        institute.InstituteType
    }where tender.CountryCode = 'ES'
    group by tender.TenderID, offer.OfferID, product.CountryCode, product.ProductCode, product.Price.OfferPrice, product.SKU.PRODUCTPACKNAME, product.SKU.UOM, institute.InstituteID, institute.InstituteName, institute.CustomerID, institute.InstituteType;
    //@cds.persistence.exists
    entity CCMMaterilsView as select from TransactionalData.PT_TMOFPR as product 
        inner join MasterData.PT_TMSKUPRDPCK as skuprdpck 
            on skuprdpck.ProductPackID = product.ProductCode
    {
        key product.ProductCode,
        skuprdpck.SKUCode,
        skuprdpck.ActiveRecord,
        product.CountryCode
    }where product.CountryCode = 'ES'
    group by product.ProductCode, skuprdpck.SKUCode, skuprdpck.ActiveRecord, product.CountryCode; 
    //@cds.persistence.exists
   entity PriceConditionInvoiceView as select from TransactionalData.PT_TMTEND as tender 
    inner join TransactionalData.PT_TMOFRS as offer 
        on offer.TenderID = tender.TenderID
        and offer.Active = 1
    inner join TransactionalData.PT_TMOFPR as product 
        on product.OfferID = offer.OfferID
        and product.Active = 1
    inner join MasterData.PT_TMPRDPCK as productPacks
        on productPacks.PRODUCTPACKID = product.ProductCode
        and productPacks.ACTIVERECORD = 'Yes' 
    inner join TransactionalData.PriceConditionClassification as priceConditionClassification  
        on priceConditionClassification.CountryCode = product.CountryCode
        and priceConditionClassification.Classification = tender.Classification
        and priceConditionClassification.Division = offer.Division 
        and (priceConditionClassification.ProductType = 'All' or priceConditionClassification.ProductType = productPacks.ProductType)
        and priceConditionClassification.isMain = true
    inner join TransactionalData.PriceCondition as priceCondition 
        on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
        and product.OfferID = priceCondition.OfferID
        and product.ProductCode = priceCondition.ProductCode{
            tender.CountryCode,
            tender.Country.Region,
            product.TenderID,
            key offer.OfferID,
            key product.ProductCode,
            product.RequestedVolume,
            case   
                when priceCondition.ID is not null then True
                else False
            end as hasPriceCondition:Boolean,
            priceCondition.ID as PriceConditionID: UUID,
            priceConditionClassification.ID as ClassificationID: UUID,
            priceConditionClassification.Classification,
            priceConditionClassification.ConditionType,
            priceConditionClassification.Division,
            priceConditionClassification.isMain,
            offer.Currency,
            priceCondition.ConfidentialPrice,
            priceCondition.PVL as YP00: Double,
            priceCondition.RoyalDecree,
            priceCondition.PriceConditionCode,
            priceCondition.Discount as YD02: Double,
            priceCondition.RoyalDecreeValue,
            priceCondition.RoyalDecreeIncl,
            priceCondition.StandardDiscount,
            priceCondition.AdditionalDiscount as YD75: Double,
            priceCondition.NetPriceWithoutTaxBeforeDeductionRD as YP10: Double,
            priceCondition.NetPriceWithoutTaxAfterDeductionRD,
            priceCondition.NetPriceWithTaxAfterDeductionRD,
            priceCondition.NetPriceWithoutTax,
            priceCondition.NetPriceWithTax,
            product.MaxPrice as MaximumPrice: Double,
            priceCondition.ConfidentialDiscount as YP04: Double,
            priceCondition.RoyalDecreePercentage_1 as YD06: Double,
            priceCondition.MonthlyRentPerUnit,
            priceCondition.AnnualValue,
            priceCondition.Tax
        }where tender.Active = 1 and tender.CountryCode = 'ES'
        group by 
            tender.CountryCode,
            tender.Country.Region,
            product.TenderID,
            offer.OfferID,
            product.ProductCode,
            product.RequestedVolume,
            priceCondition.ID,
            priceConditionClassification.ID,
            priceConditionClassification.Classification,
            priceConditionClassification.ConditionType,
            priceConditionClassification.Division,
            priceConditionClassification.isMain,
            offer.Currency,
            priceCondition.ConfidentialPrice,
            priceCondition.PVL,
            priceCondition.RoyalDecree,
            priceCondition.PriceConditionCode,
            priceCondition.Discount,
            priceCondition.RoyalDecreeValue,
            priceCondition.RoyalDecreeIncl,
            priceCondition.StandardDiscount,
            priceCondition.AdditionalDiscount,
            priceCondition.NetPriceWithoutTaxBeforeDeductionRD,
            priceCondition.NetPriceWithoutTaxAfterDeductionRD,
            priceCondition.NetPriceWithTaxAfterDeductionRD,
            priceCondition.NetPriceWithoutTax,
            priceCondition.NetPriceWithTax,
            product.MaxPrice, 
            priceCondition.ConfidentialDiscount, 
            priceCondition.RoyalDecreePercentage_1, 
            priceCondition.MonthlyRentPerUnit, 
            priceCondition.AnnualValue, 
            priceCondition.Tax; 
            
    //@cds.persistence.exists
    entity PriceConditionRebateView as select from TransactionalData.PT_TMTEND as tender 
    inner join TransactionalData.PT_TMOFRS as offer 
        on offer.TenderID = tender.TenderID
        and offer.Active = 1
    inner join TransactionalData.PT_TMOFPR as product 
        on product.OfferID = offer.OfferID
        and product.Active = 1
    inner join MasterData.PT_TMPRDPCK as productPacks
        on productPacks.PRODUCTPACKID = product.ProductCode
        and productPacks.ACTIVERECORD = 'Yes' 
    inner join TransactionalData.PriceConditionClassification as priceConditionClassification  
        on priceConditionClassification.CountryCode = product.CountryCode
        and priceConditionClassification.Classification = tender.Classification
        and priceConditionClassification.Division = offer.Division 
        and (priceConditionClassification.ProductType = 'All' or priceConditionClassification.ProductType = productPacks.ProductType)
        and priceConditionClassification.isMain = false and priceConditionClassification.ConditionType = 'Rappel'
    inner join TransactionalData.PriceCondition as priceCondition 
        on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
        and product.OfferID = priceCondition.OfferID
        and product.ProductCode = priceCondition.ProductCode
        {
            tender.CountryCode,
            tender.Country.Region,
            product.TenderID,
            key offer.OfferID,
            key product.ProductCode,
            product.RequestedVolume,
            case   
                when priceCondition.ID is not null then True
                else False
            end as hasPriceCondition:Boolean,
            priceCondition.ID as PriceConditionID: UUID,
            priceConditionClassification.ID as ClassificationID: UUID,
            priceConditionClassification.Classification,
            priceConditionClassification.ConditionType,
            priceConditionClassification.Division,
            priceConditionClassification.isMain,
            offer.Currency,
            priceCondition.ConfidentialPrice,
            priceCondition.PVL as YP00: Double,
            priceCondition.RoyalDecree,
            priceCondition.PriceConditionCode,
            priceCondition.RoyalDecreeValue,
            priceCondition.RoyalDecreeIncl,
            priceCondition.Liquidation,
            priceCondition.RefundDate,
            priceCondition.Settlement.ID as Settlement_ID: UUID,
            priceCondition.Settlement.Description,
            priceCondition.Tax,
            priceCondition.MarketIncentiveID
        }where tender.Active = 1 and tender.CountryCode = 'ES'
        group by 
            tender.CountryCode,
            tender.Country.Region,
            product.TenderID,
            offer.OfferID,
            product.ProductCode,
            product.RequestedVolume,
            priceCondition.ID,
            priceConditionClassification.ID,
            priceConditionClassification.Classification,
            priceConditionClassification.ConditionType,
            priceConditionClassification.Division,
            priceConditionClassification.isMain,
            offer.Currency,
            priceCondition.ConfidentialPrice,
            priceCondition.PVL,
            priceCondition.RoyalDecree,
            priceCondition.PriceConditionCode,
            priceCondition.RoyalDecreeValue,
            priceCondition.RoyalDecreeIncl,
            priceCondition.Liquidation,
            priceCondition.RefundDate,
            priceCondition.Settlement.ID,
            priceCondition.Settlement.Description,
            priceCondition.Tax,
            priceCondition.MarketIncentiveID; 

//@cds.persistence.exists
entity PriceConditionDiscountConditionsView as select from TransactionalData.PT_TMTEND as tender 
    inner join TransactionalData.PT_TMOFRS as offer 
        on offer.TenderID = tender.TenderID
        and offer.Active = 1
    inner join TransactionalData.PT_TMOFPR as product 
        on product.OfferID = offer.OfferID
        and product.Active = 1
    inner join MasterData.PT_TMPRDPCK as productPacks
        on productPacks.PRODUCTPACKID = product.ProductCode
        and productPacks.ACTIVERECORD = 'Yes' 
    inner join TransactionalData.PriceConditionClassification as priceConditionClassification  
        on priceConditionClassification.CountryCode = product.CountryCode
        and priceConditionClassification.Classification = tender.Classification
        and priceConditionClassification.Division = offer.Division 
        and (priceConditionClassification.ProductType = 'All' or priceConditionClassification.ProductType = productPacks.ProductType)
        and priceConditionClassification.isMain = false and priceConditionClassification.ConditionType = 'Rappel'
    inner join TransactionalData.PriceCondition as priceCondition 
        on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
        and product.OfferID = priceCondition.OfferID
        and product.ProductCode = priceCondition.ProductCode
    inner join TransactionalData.DiscountCondition as discountCondition 
        on discountCondition.PriceCondition.ID = priceCondition.ID
        {
            tender.CountryCode,
            tender.Country.Region,
            product.TenderID,
            key offer.OfferID,
            key product.ProductCode,
            product.RequestedVolume,
            case   
                when priceCondition.ID is not null then True
                else False
            end as hasPriceCondition:Boolean,
            key discountCondition.PriceCondition.ID as PriceConditionID: UUID,
            priceConditionClassification.ID as ClassificationID: UUID,
            priceConditionClassification.Classification,
            priceConditionClassification.ConditionType,
            priceConditionClassification.Division,
            priceConditionClassification.isMain,
            offer.Currency,
            discountCondition.Volume,
            discountCondition.Discount,
            discountCondition.NetPriceWithoutTax,
            discountCondition.NetPriceWithTax,
            priceCondition.Tax
        }where tender.Active = 1 and tender.CountryCode = 'ES'
        group by 
            tender.CountryCode,
            tender.Country.Region,
            product.TenderID,
            offer.OfferID,
            product.ProductCode,
            product.RequestedVolume,
            priceCondition.ID,
            discountCondition.PriceCondition.ID,
            priceConditionClassification.ID,
            priceConditionClassification.Classification,
            priceConditionClassification.ConditionType,
            priceConditionClassification.Division,
            priceConditionClassification.isMain,
            offer.Currency,
            discountCondition.Volume,
            discountCondition.Discount,
            discountCondition.NetPriceWithoutTax,
            discountCondition.NetPriceWithTax,
            priceCondition.Tax; 

    //@cds.persistence.exists        
    entity PriceConditionFOCView as select from TransactionalData.PT_TMTEND as tender 
    inner join TransactionalData.PT_TMOFRS as offer 
        on offer.TenderID = tender.TenderID
        and offer.Active = 1
    inner join TransactionalData.PT_TMOFPR as product 
        on product.OfferID = offer.OfferID
        and product.Active = 1
    inner join MasterData.PT_TMPRDPCK as productPacks
        on productPacks.PRODUCTPACKID = product.ProductCode
        and productPacks.ACTIVERECORD = 'Yes' 
    inner join TransactionalData.PriceConditionClassification as priceConditionClassification  
        on priceConditionClassification.CountryCode = product.CountryCode
        and priceConditionClassification.Classification = tender.Classification
        and priceConditionClassification.Division = offer.Division 
        and (priceConditionClassification.ProductType = 'All' or priceConditionClassification.ProductType = productPacks.ProductType)
        and priceConditionClassification.isMain = true
    inner join TransactionalData.PriceCondition as priceCondition 
        on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
        and product.OfferID = priceCondition.OfferID
        and product.ProductCode = priceCondition.ProductCode
    inner join TransactionalData.FreeGoodsOther as foc
        on foc.PriceCondition.ID = priceCondition.ID{
            tender.CountryCode,
            tender.Country.Region,
            product.TenderID,
            key offer.OfferID,
            key product.ProductCode,
            product.RequestedVolume,
            case   
                when priceCondition.ID is not null then True
                else False
            end as hasPriceCondition:Boolean,
            key foc.PriceCondition.ID as PriceConditionID: UUID,
            priceConditionClassification.ID as ClassificationID: UUID,
            priceConditionClassification.Classification,
            priceConditionClassification.ConditionType,
            priceConditionClassification.Division,
            priceConditionClassification.isMain,
            offer.Currency,
            foc.FreeGoodsOther,
            case
                when foc.FreeGoodsOther_ABS_PCT = 'PCT'
                    then round(100 * foc.FreeGoodsOther, 2) || '%'
                when foc.FreeGoodsOther_ABS_PCT = 'ABS'
                    then foc.FreeGoodsOther || ' '  || product.UnitPerPack
                when foc.FreeGoodsOther_ABS_PCT = 'STP'
                    then foc.FreeGoodsOther || ' '  || product.UnitPerPack
            end as Bonus:String,
            foc.FreeGoodsOther_Step,
            foc.FreeGoodsOther_ABS_PCT,
            foc.VAT,
            foc.FOCMinAmount,
            foc.FOCBonus,
            foc.PotentialGeneratedSavings,
            foc.RoyalDecree,
            foc.ADD_INCLUDE
    }where tender.Active = 1 and tender.CountryCode = 'ES'
        group by 
            tender.CountryCode,
            tender.Country.Region,
            product.TenderID,
            product.UnitPerPack,
            offer.OfferID,
            product.ProductCode,
            product.RequestedVolume,
            priceCondition.ID,
            foc.PriceCondition.ID,
            priceConditionClassification.ID,
            priceConditionClassification.Classification,
            priceConditionClassification.ConditionType,
            priceConditionClassification.Division,
            priceConditionClassification.isMain,
            offer.Currency,
            foc.FreeGoodsOther,
            foc.FreeGoodsOther_Step,
            foc.FreeGoodsOther_ABS_PCT,
            foc.VAT,
            foc.FOCMinAmount,
            foc.FOCBonus,
            foc.PotentialGeneratedSavings,
            foc.RoyalDecree,
            foc.ADD_INCLUDE;

    action getSAPSalesOrderSimulation(offerID: String, tenderID: String, productCode: Integer, instituteID: Integer, customerID: String, materialNumber: String, countryCode: String) returns String;
    action updateFinalContractStartEndDate(OfferID: String, ContractStartDate: Date, ContractEndDate: Date) returns String;
    action createAllFastConditionContracts(OfferID: String) returns String;
    //@cds.persistence.exists
    entity BankGuarantees                               as projection on BankGuaranteeData.BankGuarantees;
    //@cds.persistence.exists
    entity MarketIncentive                              as projection on MasterData.MarketIncentive;  
}
