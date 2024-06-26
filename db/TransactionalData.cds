namespace com.bayer.SXTENDER.TransactionalData;

using {
    User,
    Country,
    cuid,
    managed
} from '@sap/cds/common';
using { 
	Custom
} from './FASTTypes';
using {com.bayer.SXTENDER.MasterData} from './MasterData';
using {com.bayer.SXTENDER.AdminData} from './AdminData';
//using { com.bayer.SXTENDER.MasterDataViews } from './MasterDataViews';
using {com.bayer.SXTENDER.MasterDataLatestValues} from './MasterDataLatestValues';
using {com.bayer.SXTENDER.TransactionalDataViews} from './TransactionalDataViews';
using {com.bayer.SXTENDER.MasterDataViews} from './MasterDataViews';
using {com.bayer.SXTENDER.BankGuaranteeData} from './BankGuaranteeData';
using {com.bayer.SXTENDER.PriceAgreementData} from './PriceAgreementData';

entity CandidatePrices as projection on PriceAgreementData.CandidatePrices;
entity PT_TMOFRS { //Offers
        TenderID              : String(50) not null;
    key OfferID               : String(30) not null;
        CountryCode           : String not null;
        TenderOfferNo         : Integer;
        RevisedOfferNo        : Integer;
        ActiveOffer           : Integer;
        CloneOfferID          : String(255);
        CreationDate          : Date;
        SubmissionDate        : Date;
        SubmittedOn           : Date;
        SubmittedBy           : String(255);
        Active                : Integer;
        DistributorID         : Integer;
        InternalBidDueDate    : Date;
        SellingCompany        : String(3);
        ProductCount          : Integer;
        Currency              : String(255);
        ManualSaveStatus      : String(3);
        WholesaleOffer        : String(3);
        Comment               : String(500);
        OfferRevisionSplitNo  : Integer;
        NewOfferDueDate       : Date;
        ContinuationOfferNo   : Integer;
        APPROVALS_SENT        : Integer;
        FOCType               : String(255);
        DEFAULT_FOC_ABS_PCT   : String(4);
        Division              : String;
        ProfitabilityStartMnth: Integer;
        ProfitabilityAgrDur   : Integer;
        ProfitabilityYrlyMntCost: Double;
        ProfitabilityDiscRate : Double;
        ProfitabilityGrowthRate: Double;
        IbizWorkflowID         : Integer;
        isDirectIbizOpportunity: Boolean;
        PreviousIbizWorkflowID : Integer;
        TenderDistributorID    : Integer;
        BusinessUnit           : String;
        Responded              : Integer;
        DistributorDeadline    : Date;
        DistributorComments    : String;
        ChannelSwitched        : Boolean default false;
        DecisionSharedWithIBIZ : Boolean default false;
        isIBIZNotified         : Boolean default false; 
        AffiliateOffer         : Boolean default false; 
        QuotationInstituteID   : Integer;
        DifferentAwardPriceParentOfferID : String(30); // Is applicable for Taiwan Different award price Copying option
        Custom                 : Custom; // Custom attributes for templates usage
        //Associations
        Tender                : Association to PT_TMTEND
                                    on Tender.TenderID = TenderID;
        Distributor           : Association to MasterData.PT_TMDIST
                                    on Distributor.DistributorID = DistributorID;
        Product               : Association to many PT_TMOFPR
                                    on Product.OfferID = OfferID and Product.Active = Active;
        OfferStatusTable      : Association to PT_TMTNOFST
                                    on OfferStatusTable.OfferID = OfferID
                                    and OfferStatusTable.Active = Active;
        OfferStatus:Association to TransactionalDataViews.OfferStatus on OfferStatus.OFFER_ID = OfferID;
        SellingCompanyDetails : Association to MasterData.PT_TMLE
                                    on SellingCompanyDetails.LegalEntityCode = SellingCompany;
        Quotation             : Association to PT_TMQUTO
                                    on Quotation.OfferID = OfferID
                                    and Quotation.Active = Active;
        Revision              : Association to TransactionalDataViews.OfferRevisions
                                    on  Revision.TENDERID       = TenderID
                                    and Revision.TENDEROFFERNO  = TenderOfferNo;
        OfferValue            : Association to TransactionalDataViews.OfferValues
                                    on OfferValue.OFFER_ID = OfferID;
        PfiNumber             : Association to PT_TMPFIOM
                                    on PfiNumber.OfferID = OfferID;
        Signatories           : Association to many MasterData.COUNTRY_LEGAL_ENTITY_SIGNATORIES
                                    on  Signatories.COUNTRY_CODE     = CountryCode
                                    and Signatories.LEGAL_ENTITY_CODE = SellingCompany;
        Country               : Association to MasterData.PT_TMCTRY
                                    on Country.CountryCode = CountryCode;
        ProductTypeProfitability: Association to ProductTypeProfitability
                                    on ProductTypeProfitability.OfferId = OfferID;
        Lots                  : Association to many Lots
                                    on Lots.OfferID = OfferID;
}

entity OfferView as
    select from PT_TMOFRS as offer {
        *,
        OfferStatus
    };

entity PT_OFGRPUR {
        TenderID      : String(50);
    key OfferID       : String(30) not null;
        RegionCode    : String(2);
        CountryCode   : String;
        SubmittedOn   : Date;
        SubmittedBy   : String(255);
    key Active        : Integer not null;
    key ProductCode   : Integer not null;
    key InstituteID   : Integer not null;
        DistributorID : Integer;
        Requested     : Integer;
        KeyForRestore : String(255);
        //Associations
        Institute     : Association to MasterData.PT_TMINST
                            on Institute.InstituteID = InstituteID;
}

entity PT_SCENARIOPLAN {
        TenderID              : String(50);
    key OfferID               : String(30) not null;
        CountryCode           : String;
    key ProductCode           : Integer not null;
        SubmittedOn           : Date;
        SubmitedBy            : String(255);
    key Active                : Integer not null;
    key Scenario              : Integer not null;
        Name                  : String(255);
        Description           : String(255);
        Volume                : Integer;
        OfferPrice            : Double;
        FOC_ABS_PCT           : String(10);
        FOC                   : Double;
        FOCType               : String(10);
        FOC_ABS_PCT_Bundled_1 : String(10);
        FOC_Bundled_1         : Double;
        FOCProduct_Bundled_1  : String(30);
}

entity PT_TENDGRPPUR {
        TenderID      : String(50);
    key OfferID       : String(30);
        CountryCode   : String;
    key ProductCode   : Integer;
    key InstituteID   : Integer;
        SubmittedOn   : Date;
        SubmittedBy   : String(255);
    key Active        : Integer;
        AwardedQty    : String(15);
        KeyForRestore : String(255);
}

entity PT_TMAPPRST {
        TenderID            : String(50);
    key OfferId             : String(30) not null;
        CountryCode         : String;
    key productcode         : Integer not null;
        ApprovalContent     : String(100);
        ApproverTypeSection : Integer;
        ApprovalStatus      : String(100);
        ApproverName        : String(100);
    key ApproverEmailID     : String(100) not null;
        SenderComment       : String(500);
        ApproverComment     : String(500);
    key Active              : Integer not null;
        Hierarchy           : Integer;
        AP_ID               : String(10);
        RestoreKey          : String(100);
    key Statustime          : DateTime not null;
        Submittedby         : String(100);
        ApproverDate        : Date;
    key ApproverType        : String(200) not null;
        FLOW_ID             : String(255);
        REQUIRED_ACTION     : String(12);
    key LotID               : Integer default 1;
        //Associations
        OfferProduct        : Association to PT_TMOFPR
                                  on  OfferProduct.OfferID     = OfferId
                                  and OfferProduct.ProductCode = productcode
                                  and OfferProduct.Active = Active
                                  and OfferProduct.LotID = LotID
}

entity PT_TMAWRDCR {
    key TENDERID      : String(50) not null;
        COUNTRYCODE   : String;
        SUBMITTEDON   : Date;
        Submittedby   : String(100);
    key Active        : Integer not null;
    key AwardCriteria : String(100) not null;
        Weight        : Double;
        //Associations
        Tender        : Association to PT_TMTEND
                            on Tender.TenderID = TENDERID;
}

entity Specifications : cuid, managed {
    key TenderID    : String(50) not null;
        CountryCode	: String;   
        Name		: String(50);
        Tender      : Association to PT_TMTEND on Tender.TenderID = TenderID;
}
//EHQUT-196575- Thailand - Change Request - INC16653808 
//EHQUT-197393-MEA – change display in Offer Summary in Financial Offer tab
entity PT_TMBDPR {
        TenderID              : String(50) not null;
    key OfferID               : String(30) not null;
        CountryCode           : String not null;
    key ProductCode           : Integer not null;
        SubmittedOn           : Date;
        SubmittedBy           : String(255);
    key Active                : Integer not null;
        Tier                  : Integer;
        VolumeFrom            : Integer;
        VolumeTo              : Integer;
        RegPrice              : Double;
        FOC                   : Double;
        FOCStep               : Double; 
        FOCType               : String(255);
        Discount              : Double;
        OfferPrice            : Double;
        Deductions            : Double;
        StandardDiscount      : Double;
        AdditionalDiscount    : Double;
        NetofferPrice         : Double;
        BusinessCasePrice     : Double;
        WholesalePrice        : String(50);
        COGS                  : Double;
        SpotRate              : Double;
        BudgetRate            : Double;
        Scenario              : Integer;
        FOC_ABS_PCT           : String(4);
        FOC_Bundled_1         : Double;
        FOC_ABS_PCT_Bundled_1 : String(4);
        FOCProduct_Bundled_1  : Integer;
    key ActiveTier            : Integer not null;
        NetPrice              : Double;
        NetPrice_OfPaid       : Double;
        PRICE_UPDATE          : Integer;
    key LotID                 : Integer default 1;
        Deductions_ABS_PCT     : String(4);
        //Associations
        Product               : Association to PT_TMOFPR
                                    on  Product.OfferID     = OfferID
                                    and Product.ProductCode = ProductCode
                                    and Product.LotID       = LotID;
        Bundled_1_Cogs        : Association to MasterDataLatestValues.CountryCogs
                                    on  Bundled_1_Cogs.COUNTRY_CODE = CountryCode
                                    and Bundled_1_Cogs.PRODUCT_ID   = FOCProduct_Bundled_1;
        Bundled_1_SKU         : Association to MasterData.PT_TMPRDPCK
                                    on Bundled_1_SKU.PRODUCTPACKID = FOCProduct_Bundled_1;
        Profitability         :  Association to MasterData.BUDGETEDPROFITABILITY on Profitability.PRODUCTPACKID = ProductCode  and Profitability.COUNTRYCODE =CountryCode and SubmittedOn >= Profitability.EFFECTIVEDATE and SubmittedOn <= Profitability.ENDDATE;
}


entity PT_TMDLVTR {
        TenderID               : String(50);
    key OfferID                : String(30) not null;
        CountryCode            : String;
        InstituteID            : Integer;
        SKUCode                : Integer;
        SubmittedOn            : Date;
        SubmittedBy            : String(255);
        Active                 : Integer not null;
        LocalOrDirectDelivery  : String(255);
        PlannedInAPO           : String(255);
        RequestedDeliveryDate  : Date;
        RequestedQuantity      : Double;
        ActualDeliveryDate     : Date;
        ActualDeliveryQuantity : Double;
        Penalty                : String(255);
        PenaltyValue           : Double;
        Currency               : String(4);
        PenaltyReason          : String(255);
        UndertakingLetters     : String(4);
        Compensated            : String(4);
        CompensationComment    : String(255);
    key ProductCode            : Integer not null;
        PaidOrFree             : String(255);
        PO                     : String(255);
        InvoiceNo              : String(255);
    key SNo                    : Integer not null;
        Contract               : String;
        PoDate                 : Date;
        //EHEEX-OTT - 105262-Adding new 3 fields for delivery tracking tab
        ActualDeliveredProduct :String(100);
        ActualDeliveredProductQty : Double;
        LocalDeliveryNoteNo :String(255);
        //EHEEX-OTT - 105262-Adding new 3 fields for delivery tracking tab
    key LotID                  : Integer default 1;
        Custom                 : Custom; // Custom attributes for templates usage
    //Associations
        Institute              : Association to MasterData.PT_TMINST on Institute.InstituteID = InstituteID;
}


entity PT_TMOFPR {
        TenderID                 : String(50) not null;
    key OfferID                  : String(30) not null;
        CountryCode              : String;
        SubmittedOn              : Date;
        SubmittedBy              : String(255);
    key Active                   : Integer not null;
    key ProductCode              : Integer not null;
        Reference                : String(255);
        AlternateOfferYN         : String(255);
        RequestedVolume          : Integer;
        UnitPerPack              : String(255);
        SampleYN                 : String(255);
        SampleQuantity           : Integer;
        DocumentsRequired        : String(255);
        FirstShipment            : String(255);
        NoofLots                 : Integer;
        IntervalBetweenShipments : Integer;
        NoOfTier                 : Integer;
        DiscOrOffer              : String(255);
        PaymentTerms             : String(255);
        DistributorID            : Integer;
        SNo                      : Integer;
        ActiveProduct            : Integer;
        Comment                  : String(500);
        INCOTerms                : String(500);
        SORTER                   : Integer;
        DEFAULT_COMMISSION_RATE  : Double;
        SUPPLY_UPDATE            : Integer;
        PAYMENT_UPDATE           : Integer;
        Line                     : String;
        DeliveryConditions       : String;
        MinInvoiceAmount         : Double;
        PricingPolicyCluster     : String;
        OfferType                : String;
        AnticipatedRequestedQuantity: String(25);
        MaxPrice                 : Double;
        Channel                  : String;
    key LotID                    : Integer default 1;
        WorkflowProductID        : Integer;
        IbizWorkflowID           : Integer;
        Custom                   : Custom; // Custom attributes for templates usage
        //Associations
        Offer                    : Association to PT_TMOFRS
                                       on Offer.OfferID = OfferID;
        SKU                      : Association to MasterData.PT_TMPRDPCK
                                       on SKU.PRODUCTPACKID = ProductCode;
        SKUCountry               : Association to MasterData.PT_TMCTPRDPCK
                                       on  SKUCountry.PRODUCTPACKID = ProductCode
                                       and SKUCountry.COUNTRYCODE   = CountryCode;
        Price                    : Association to PT_TMBDPR
                                       on  Price.ProductCode = ProductCode
                                       and Price.OfferID     = OfferID
                                       and Price.Active = Active
                                       and Price.LotID = LotID;
        RegisteredPrice          : Association to many MasterDataLatestValues.CountryRegisteredPrice
                                       on  RegisteredPrice.COUNTRY_CODE = CountryCode
                                       and RegisteredPrice.PRODUCT_ID   = ProductCode;
        Cogs                     : Association to MasterDataLatestValues.CountryCogs
                                       on  Cogs.COUNTRY_CODE = CountryCode
                                       and Cogs.PRODUCT_ID   = ProductCode;
        Results                  : Association to many PT_TMTRRES
                                       on  Results.OfferID     = OfferID
                                       and Results.ProductCode = ProductCode
                                       and Results.Active = Active;
        ApprovalStatus           : Association to TransactionalDataViews.ApprovalRequests
                                       on ApprovalStatus.OfferId = OfferID;
        PreviousApproval         : Association to TransactionalDataViews.PreviousApproval
                                       on  PreviousApproval.OFFER_ID   = OfferID
                                       and PreviousApproval.PRODUCT_ID = ProductCode;
        Deliveries               : Association to many PT_TMDLVTR
                                       on  Deliveries.OfferID     = OfferID
                                       and Deliveries.ProductCode = ProductCode
                                       and Deliveries.LotID       = LotID;
        Letters                  : Association to many PT_TMUDLTRS
                                       on  Letters.OFFERID = OfferID
                                       and Letters.SKUCODE = ProductCode
                                       and Letters.LOTID   = LotID;
        Scenario                 : Association to many PT_SCENARIOPLAN
                                       on  Scenario.OfferID     = OfferID
                                       and Scenario.ProductCode = ProductCode;
        GroupPurchasing          : Association to many PT_OFGRPUR
                                       on  GroupPurchasing.OfferID     = OfferID
                                       and GroupPurchasing.ProductCode = ProductCode
                                       and GroupPurchasing.Active = Active;
        ProductPricing           : Association to ProductPricing
                                       on ProductPricing.OfferID = OfferID
                                       and ProductPricing.ProductCode = ProductCode
                                       and ProductPricing.CountryCode = CountryCode
                                       and ProductPricing.LotID = LotID;
        PriceAgreement           : Association to PriceAgreementData.PriceAgreements
                                        on PriceAgreement.OfferId = OfferID
                                        and PriceAgreement.ProductPackId = ProductCode
                                        and PriceAgreement.LotID = LotID;
        PriceCondition           : Composition of many PriceCondition 
                                        on PriceCondition.OfferID = OfferID
                                        and PriceCondition.ProductCode = ProductCode
                                        and PriceCondition.CountryCode = CountryCode
                                        and PriceCondition.LotID = LotID;
        //Brazil
        LotProduct               : Association to LotProduct
                                        on LotProduct.OfferID = OfferID
                                        and LotProduct.ProductCode = ProductCode
                                        and LotProduct.LotID = LotID;
        BudgetedProfitability    : Association to MasterDataLatestValues.VWBUDGETEDPROFITABILITY
                                        on BudgetedProfitability.COUNTRYCODE = CountryCode
                                        and BudgetedProfitability.PRODUCTPACKID = ProductCode;
                                        //and BudgetedProfitability.HLEVEL4_CODE = SKU.Product.HLEVEL4_CODE
        PricingPolicy            : Association to MasterData.PricingPolicy
                                        on PricingPolicy.CountryCode = CountryCode
                                        and PricingPolicy.ProductPackID = ProductCode;
        ContractInfomation       :  Association to many ContractInfomation 
                                        on ContractInfomation.OfferID = OfferID
                                        and ContractInfomation.ProductCode = ProductCode;                                
                                        
}

//brazil

entity Lots: managed {
    key LotID: Integer;
    key OfferID: String;
    LotProducts: Association to many LotProduct
                    on LotProducts.LotID = LotID
                    and LotProducts.OfferID = OfferID
}

entity LotProduct: managed { 
    key LotID: Integer;
    key OfferID: String;
    key ProductCode: Integer;
}

//italy
entity ProductPricing: cuid, managed {
    key OfferID: String;
    key ProductCode: Integer;
    key CountryCode: String;
    Warranty: Integer;
    AgreementDuration: Integer;
    MonthlyRent: Double;
    MonthsPerInvoice: Integer;
    ContractStartDate: String;
    ValueOfDevices: Double;
    StatusOfDevice: String;
    MinContractual: Double;
    MinAnnPurch: Double;
    key LotID : Integer default 1;
    FreeGoodsOther: Composition of many FreeGoodsOther on FreeGoodsOther.ProductPricing = $self;
}

entity FreeGoodsOther: cuid, managed {
    ProductPackId: Integer;
    FreeGoodsOther: Double;
    FreeGoodsOther_Step: Double;
    FreeGoodsOther_ABS_PCT: String(4);
    VAT: Double; // We store this to keep track of the VAT the moment we save FreeGoodsOther to the ProductPricing
    ProductPricing: Association to ProductPricing;
    ProductPack: Association to many MasterData.PT_TMPRDPCK on ProductPack.PRODUCTPACKID = ProductPackId;
    Materials: Association to many MasterData.PT_TMSKUPRDPCK
                                on Materials.CountryCode = 'IT'
                                and Materials.ProductPackID = ProductPackId;
    FOCMinAmount                        : Integer;
    FOCBonus                            : Decimal;
    PotentialGeneratedSavings           : Decimal;
    RoyalDecree                         : String;
    ADD_INCLUDE                         : String;
    PriceCondition                      : Association to PriceCondition;
}

entity PriceCondition: cuid, managed {
    CountryCode                         : String;
    OfferID                             : String;
    ProductCode                         : Integer;
    PVL                                 : Decimal;
    ConfidentialPrice                   : Decimal;
    Discount                            : Decimal;
    RoyalDecree                         : String;
    RoyalDecreeValue                    : Decimal;
    RoyalDecreeIncl                     : Boolean default false;
    StandardDiscount                    : Decimal;
    AdditionalDiscount                  : Decimal;
    NetPriceWithoutTaxBeforeDeductionRD : Decimal;
    NetPriceWithoutTaxAfterDeductionRD  : Decimal;
    NetPriceWithTaxAfterDeductionRD     : Decimal;
    NetPriceWithoutTax                  : Decimal;
    NetPriceWithTax                     : Decimal;
    MaximumPrice                        : Decimal;
    Tax                                 : Decimal;
    Liquidation                         : String;
    RefundDate                          : Date;
    PriceConditionCode                  : String;
    MonthlyRentPerUnit                  : Double;
    AnnualValue                         : Double;
    ReferencePriceAgreement             : UUID; // reference to an existing price agreement related to a "Tender" **classification Tender** which is not expiring before tomorrow for the same product and customer
    LotID                               : Integer default 1;
    PriceList                           : Decimal; //PriceList from MasterData SAP
    ICMSTax                             : Decimal;
    TaxExemption                        : String;
    PriceAfterTaxExemtion               : Decimal;
    CAP                                 : String;
    PriceAfterCap                       : Decimal;
    CommercialProposal                  : Decimal;
    TaxEqualization                     : Decimal; //will come from SAP simulation
    Invoive                             : Decimal; //will come from SAP simulation
    ICMS                                : Decimal; //will come from SAP simulation
    NetPrice                            : Decimal; //will come from SAP simulation
    Price0                              : Decimal;
    Level1Discount1                     : Double;
    Level1Discount2                     : Double;
    Level1Discount3                     : Double;
    Price1                              : Decimal;
    Level2Discount1                     : Double;
    Level2Discount2                     : Double;
    Level2Discount3                     : Double;
    Price2                              : Decimal;
    Level3Discount1                     : Double;
    Level3Discount2                     : Double;
    Level3Discount3                     : Double;
    Price3                              : Decimal;
    OfferPrice                          : Decimal;
    NetOfferPrice                       : Decimal;
    Last12MonthsVolumeMainCustomer      : Integer;
    Last12MonthsVolumeBranch            : Integer;
    AnticipatedYearlyVolumeMainCustomer : Integer;
    AnticipatedYearlyVolumeBranch       : Integer;
    TotalDiscountNHI                    : Double;
    TotalDiscountInvoice                : Double;
    TotalYearlyValueMainCustomer        : Double;
    TotalYearlyValueBranch              : Double;
    AnnualDiscountForBranch             : Double;
    NegotiationPrice                    : Double;
    GeneralDiscount_Amount              : Double;
    SecondDiscount_Amount               : Double;
    AnnualDiscount_Percentage           : Double;
    FreeGoods_Amount                    : Double;
    FreeGoods_Percentage                : Double;
    DiscountCondition                   : Composition of many DiscountCondition on DiscountCondition.PriceCondition = $self;
    PriceConditionClassification        : Association to PriceConditionClassification;
    FreeGoodsOther                      : Composition of many FreeGoodsOther on FreeGoodsOther.PriceCondition = $self;
    PriceAgreement                      : Association to PriceAgreementData.PriceAgreements;
    Settlement                          : Association to MasterData.Settlements;
    IsPricingUnlocked                   : Boolean default false;
    NLPriceConditionType                : Array of NLConditions;
    RoyalDecreePercentage               : Association to MasterData.RoyalDecree on  RoyalDecreePercentage.ProductPackID = ProductCode
                                                                                and RoyalDecreePercentage.ValidTo = '9999-12-31 00:00:00.000000000';
    CapBrazil                           : Association to MasterDataViews.MostRecentCapView on CapBrazil.ValidTo = '9999-12-31 00:00:00.000000000';
    NLPriceConditions                   : Association to many NLPriceConditions on NLPriceConditions.PriceCondition = $self;
}

//EHQUT-INC18178128-FAST - Error decimals discounts
entity DiscountCondition: cuid, managed {
    Volume              : Integer;
    Discount            : Double;
    NetPriceWithoutTax  : Decimal;
    NetPriceWithTax     : Decimal;
    PriceCondition      : Association to PriceCondition;
}


entity PriceConditionClassification: cuid {
    CountryCode     : String;
    ConditionType   : String;
    Classification  : String;
    Division        : String;
    ProductType     : String;
    isMain          : Boolean;
}

entity ProductTypeProfitability: cuid {
    CountryCode     : String;
    OfferId         : String;
    ProductType     : String;
    NPV_GrossMargin : Double;
    NPV_NetSales    : Double;
    NPV_Cogs        : Double;
    Profitability   : Double;
}


entity PT_TMPFIOM {
    key OfferID : String(255) not null;
        PFINo   : String(255);
}

//Qoutation Submitted
entity PT_TMQUTO {
        TenderID          : String(50);
    key OfferID           : String(30) not null;
        CountryCode       : String;
        DistributorID     : Integer;
        SubmittedOn       : Date;
        SubmittedBy       : String(255);
    key Active            : Integer not null;
        OfferValidity     : Date;
        DelayInSubmission : String(50);
        AS1               : String(255);
        AS2               : String(255);
    key OfferDate         : Date not null; //removed key
        DeliveryTerms     : String(5000);
        I_Q_1             : String(255);
        I_Q_2             : String(255);
        I_Q_3             : String(255);
        Comment           : String(500);
        UPDATED           : Integer;
        EffectiveDate     : Date;
        ExpiryDate        : Date;
        Custom            : Custom; // Custom attributes for templates usage
        //Associations
        Offer             : Association to PT_TMOFRS
                                on Offer.OfferID = OfferID;
        Signatory1        : Association to MasterData.COUNTRY_LEGAL_ENTITY_SIGNATORIES
                                on Signatory1.AUTHORIZED_SIGNATORY = AS1 and Signatory1.COUNTRY_CODE = CountryCode and Signatory1.LEGAL_ENTITY_CODE = 'BIT';
        Signatory2        : Association to MasterData.COUNTRY_LEGAL_ENTITY_SIGNATORIES
                                on Signatory2.AUTHORIZED_SIGNATORY = AS2 and Signatory2.COUNTRY_CODE = CountryCode and Signatory2.LEGAL_ENTITY_CODE = 'BIT';
}

//EFRCL-217931-Italy - Tender expiry date field
//CR1
entity PT_TMTEND: managed {
    key TenderID             : String(50) not null;
        CountryCode          : String not null;
        ToolID               : Integer;
        TenderNo             : Integer;
        CloneTenderID        : String(50);
        SubmittedOn          : Date;
        SubmittedBy          : String(50);
        Active               : Integer;
        Classification       : String(50);
        BiddingTypeLevel1    : String(50);
        BiddingTypeLevel2    : String(50);
        BiddingTypeLevel3    : String(50);
        HighValue            : Boolean;
        OfferStartDate       : Date;
        IbizID               : String(50);
        PublicNotice         : String;
        TenderName           : String(250);
        InstituteID          : Integer not null;
        TenderChannel        : String(255);
        GroupPurchasing      : Integer;
        PublicationDate      : Date;
        BidDueDate           : Date;
        AwardDate            : Date;
        NextPublicationDye   : Date;
        ContractLength       : Integer;
        ContractExtenseion   : Integer;
        TenderStatus         : String(255);
        ManualSaveStatus     : String(50);
        FoldersCreated       : Integer;
        TENDER_TYPE_ID       : Integer;
        CONTRACT_TYPE_ID     : Integer;
        SALES_TYPE_ID        : Integer;
        TENDER_ORIGIN_ID     : Integer;
        PROCUREMENT_METHOD_ID: String;
        PROCUREMENT_REASON   : String;

        CONTENT              : String(500);
        PORTAL               : LargeString;
        TENDER_TYPE_2_ID     : Integer;
        SAPID                : String;
        ExternalID           : String;
        AlternativeID        : Integer;
        IbizLicitaID         : Integer;
        Liciedital           : String;
        Purpose              : String;
        ParticiationType     : String;
        ParticipationIntention : String;
        TerminationDate      : Date;
        EffectiveDate     : Date;
        ExpiryDate        : Date;
        OfferValidity      :Date;

        Custom               : Custom; // Custom attributes for templates usage
        //Associations
        Institute           : Association to MasterData.PT_TMINST
                                  on Institute.InstituteID = InstituteID
                                  and Institute.CountryCode = CountryCode; //OK
        Offer               : Association to many PT_TMOFRS
                                  on Offer.TenderID = TenderID
                                  and Offer.Active = Active;
        OfferView               : Association to many OfferView
                                  on OfferView.TenderID = TenderID;
        // OfferStatus               : Association to many TransactionalDataViews.OfferStatus
        //                           on OfferStatus.TENDER_ID = TenderID;
        Criteria            : Association to many PT_TMAWRDCR
                                  on Criteria.TENDERID = TenderID;
        Specifications      : Association to many Specifications on Specifications.TenderID = TenderID;
        Brands              : Association to many TransactionalDataViews.BrandsInTender
                                  on Brands.TENDERID = TenderID;
        NextOfferId         : Association to TransactionalDataViews.TenderOffers
                                  on NextOfferId.TENDERID = TenderID; //OK
        TenderValue         : Association to TransactionalDataViews.TenderOffers
                                  on TenderValue.TENDERID = TenderID; //Fake - we don't use this any more - remove from expand in UI5 to remove
        Origin              : Association to MasterData.MASTER_TENDER_ORIGIN
                                  on Origin.ID = TENDER_ORIGIN_ID; //OK
        CommercialAgreement : Association to many MasterData.MASTER_COMMERCIAL_AGREEMENT
                                  on  CommercialAgreement.COUNTRY_CODE   = CountryCode
                                  and CommercialAgreement.TENDER_TYPE_ID = TENDER_TYPE_ID; //OK
        Country               : Association to MasterData.PT_TMCTRY
                                    on Country.CountryCode = CountryCode;
        CountrySpecificInformation : Association to CountrySpecificTenderInfo
                                        on CountrySpecificInformation.TenderID = TenderID
                                        and CountrySpecificInformation.CountryCode = CountryCode;
        BankGuarantees: Association to BankGuaranteeData.BankGuarantees
                                        on BankGuarantees.TenderID = TenderID;
        PriceAgreements: Association to PriceAgreementData.PriceAgreements
                                         on PriceAgreements.TenderId  = TenderID;
        User: Association to AdminData.PT_TMUSER
                                         on User.UserID = SubmittedBy;
        TenderType1: Association to MasterData.MASTER_TENDER_TYPE
                                on TenderType1.ID = TENDER_TYPE_ID;
        TenderType2: Association to MasterData.MASTER_TENDER_TYPE
                                on TenderType2.ID = TENDER_TYPE_2_ID;
        ContractType: Association to MasterData.MASTER_CONTRACT_TYPE
                                on ContractType.ID = CONTRACT_TYPE_ID;
        SalesType: Association to MasterData.MASTER_SALES_TYPE
                                on SalesType.ID = SALES_TYPE_ID;
}

entity PT_TMTNOFST {
    key TenderID    : String(50) not null;
    key OfferID     : String(30) not null;
        CountryCode : String;
    key Active      : Integer not null;
        STATUS      : String(255);
        TableStatus : String(255);
        Date        : Date;
}

entity PT_TMTRRES {
        TenderID          : String(50);
    key OfferID           : String(30) not null;
        CountryCode       : String;
        InstituteID       : Integer;
    key ProductCode       : Integer not null;
        ContractNo        : String(50);
        SubmittedOn       : Date;
        SubmittedBy       : String(255);
        Active            : Integer;
        ErrorInSubmission : String(255);
        Outcome           : String(255);
        AwardedCompany    : String(255);
        AwardedProduct    : String(255);
        AwardedPrice      : Double;
        Currency          : String(255);
        AwardedQty        : Integer;
        UoM               : String(255);
        Reason            : String(255);
        Comment           : String(255);
        AwardedTier       : Integer;
        //new fields italy
        ExtensionDate     : Date;
        ExtensionNotes    : String;
        AwardLetterNo     : String;
        AwardDelibNo      : String;
        DeliveryDate      : Date;
        ResultDate        : Date;
        AwardDate         : Date;
        AwardActing       : String;
        Appeal            : String;
        InfoNeeded        : String;
        TotalAwardedValue : Double;
        ContractStartDate : Date;
        ContractEndDate   : Date;
        Custom            : Custom; // Custom attributes for templates usage
    key LotID             : Integer default 1;
        //Associations
        CompetitorResult  : Association to many TransCompetitorResult
                                on  CompetitorResult.OFFERID     = OfferID
                                and CompetitorResult.PRODUCTCODE = ProductCode
                                and CompetitorResult.LOTID       = LotID;
}

entity PT_TMUDLTRS {
        TENDERID          : String(50);
    key OFFERID           : String(30) not null;
        COUNTRYCODE       : String;
        INSTITUTEID       : Integer;
    key SKUCODE           : Integer not null;
        SUBMITTEDON       : Date;
        SUBMITTEDBY       : String(100);
        ACTIVE            : Integer not null;
        REASONFORLETTER   : String(500);
        QUANTITY          : Integer;
        BATCH             : String(100);
        MANUFACTURINGDATE : Date;
        EXPIRYDATE        : Date;
        RETURNDATE        : Date;
        RETURNEDQTY       : Integer;
        UOM               : String(40);
    key SNO               : Integer not null;
    key LOTID             : Integer default 1;
}
//EHQUT modified the entity for extending the key field.
//EHQUT-218727-Requested Volume Field for competitor result
entity TransCompetitorResult {
    key OFFERID        : String(30) not null;
    key PRODUCTCODE    : Integer not null;
    key LOTID          : Integer default 1;
        OUTCOME        : String(255);
    key AWARDEDCOMPANY : String(255) not null;
    key AWARDEDPRODUCT : String(255) not null;
        REQUESTEDVOLUME: Integer;
        AWARDEDPRICE   : Double;
        CURRENCY       : String(3);
        AWARDEDQTY     : Integer;
        UOM            : String(255);
        REASON         : String(255);
        COMMENT        : String(255);
        LASTUPDATE     : Date;
        UPDATEDBY      : String(255);
        DELETED        : Integer;
        TOTALAWARDEDVALUE: Double;
        Custom         : Custom; // Custom attributes for templates usage
}

entity OutgoingMails : managed, cuid {
    CountryCode: String;
    TenderID: String(50);
    OfferID: String(30);
    Sender: LargeString;
    Recipients: LargeString;
    Subject: LargeString;
    MailBody: LargeString;
    Sent: Boolean;
}

entity CountrySpecificTenderInfo: managed {
    key TenderID             : String(50);
    key CountryCode          : String;
        Institute            : String(255);
        TenderReference      : String(255); 
        PublicationDate      : Date;
        ClosingDate          : Date;
        MercadoPublicoIssuer : Integer;
}

entity DocumentsDownload: cuid, managed {
    DocID 				: Integer; // id_doc
    DocCreatedAt        : String;  // created_at
    NameTag             : String;  // nm_tag
    CountryCode         : String;
    TenderID            : String(50) not null;
    OfferID             : String(30) not null;
    IbizAPIName         : String; // to store from which API the DOC are receiving, like from CONTRATOS,RESULTADOS or from QPS
    URL                 : String; // file_url
    Name                : String; // nm_doc
    Downloaded          : Boolean default false;
}

entity SpainRappelData: cuid, managed {
    KNUMA       : String;
    BONEM       : String;
    DATAB       : Date;
    DATBI       : Date;
    KUNNR       : String;
    MATNR       : String;
}

entity OfferProductOfferStatus {
            TenderID            : String(50) not null;
        key OfferId             : String(30) not null;
            CountryCode         : String not null;
            ApprovalContent     : String(13);
            ApproverTypeSection : Integer;
            REQUIRED_ACTION     : String(12);
            ApprovalStatus      : String(100) not null;
            ApproverName        : String(100);
            ApproverEmailID     : String(100);
            SenderComment       : String(500);
            ApproverComment     : String(500);
            Active              : Integer not null;
            Hierarchy           : Integer;
            AP_ID               : String(10);
            RestoreKey          : String(100);
            Statustime          : DateTime;
            Submittedby         : String(100);
            ApproverDate        : Date;
        key ApproverType        : String(200) not null;
            Division            : String(200) not null;
            FLOW_ID             : String(255);
            CountryName         : String(255);
            UserName            : String(255);
            UserEmail           : String(255);
            send                : String(3);
            //Associations
            ApproverList        : Association to many MasterData.CountryApprovers
                                      on  ApproverList.CountryCode  = CountryCode
                                      and ApproverList.ApproverType = ApproverType
                                      and ApproverList.Division     = Division;
            ApproverTypes       : Association to many MasterData.ApproverTypes
                                      on  ApproverTypes.CountryCode  = CountryCode
                                      and ApproverTypes.ApproverType = ApproverType;
};

entity ExcelUpload:cuid {
    @Core.MediaType     : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    content             : LargeBinary;
};

entity NLPriceConditions: cuid {
    ContractDuration: Double;
    OfferPrice: Double;
    Discount: Double;
    NetPrice: Double;
    PriceCondition: Association to PriceCondition;
}

type NLConditions {
    ContractDuration: Double;
    OfferPrice: Double;
    Discount: Double;
    NetPrice: Double;
};

entity NLOfferDistributors: cuid {
    OfferID: String;
    DistributorName: String;
    DistributorID: Integer;
    ProductPackName: String;
    ProductPackID: Integer;
}

entity ContractInfomation : cuid, managed {
    OfferID: String;
    ProductCode: Integer;
    InstituteID: Integer;
    InstituteName: String;
    ContractDuration: Double;
    ContractStartDate: Date;
    ContractEndDate: Date;
    Active: Boolean;
    OfferProduct: Association to PT_TMOFPR
        on OfferProduct.OfferID = OfferID
        and OfferProduct.ProductCode = ProductCode;
}