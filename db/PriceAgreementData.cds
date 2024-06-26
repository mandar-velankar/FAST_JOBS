namespace com.bayer.SXTENDER.PriceAgreementData;

using {
    User,
    Country,
    managed, 
    cuid
} from '@sap/cds/common';
using {com.bayer.SXTENDER.TransactionalData} from './TransactionalData';
using {com.bayer.SXTENDER.AdminDataViews} from './AdminDataViews';
using {com.bayer.SXTENDER.AdminData} from './AdminData';
using {com.bayer.SXTENDER.MasterData} from './MasterData';
using {com.bayer.SXTENDER.MasterDataViews} from './MasterDataViews';
using {com.bayer.SXTENDER.PriceAgreementDataViews} from './PriceAgreementDataViews';



entity PriceAgreements: cuid, managed {
    ExpiryDate:  DateTime;
    EffectiveDate: DateTime;
    OriginalEffectiveDate: DateTime;
    ListPrice: Double;
    RetailPrice: Double;
    Price: Double;
    Currency: String;
    UoM: String;
    Discount: Double;
    DeliveredVolume: Integer;
    AwardedVolume: Integer;
    CountryCode: String not null;
    InstituteId: Integer not null;
    TenderId: String not null;
    ProductPackId: Integer not null;
    Synchronized: Boolean;
    SynchronizationStatus: String;//RUNNING/FAILED/DONE
    hasNewMaterials: Boolean default false; // calculated from NodeJS
    hasNewPrice: Boolean default false; // calculated from NodeJS
    hasNewYLLP: Integer default 0;
    hasNewYLAP: Integer default 0;
    hasProductPackId: Integer;
    IgnorePVLPriceChange: Boolean default false;
    IgnoreConfPriceChange: Boolean default false;
    ExpiringSoon: Boolean default false; // calculated from NodeJS
    Expired: Boolean default false; //calculated from NodeJS
    isNewPriceAgreement: Boolean default true; // calculated from NodeJS
    AppliedCount: Integer default 0; // calculated from NodeJS
    isCancelled: Boolean default false; //calculated from NodeJs
    OfferId: String;
    ExtendPriceAgreement: Boolean default false;
    ExpiryExtensionPeriod: Integer;
    ExpiryExtensionAcknowledged: Boolean default false;
    Status: String;
    CancellationComment: String;
    LotID: Integer default 1;
    OldExpiryDate:DateTime; //EJUVE-CR3
    EmailNotificationSent: Boolean default false;//EHQUT-CR6
    Institute: Association to MasterData.PT_TMINST on Institute.InstituteID = InstituteId and Institute.CountryCode = CountryCode;
    Tender: Association to TransactionalData.PT_TMTEND on Tender.TenderID = TenderId;
    Product: Association to MasterData.PT_TMCTPRDPCK on Product.PRODUCTPACKID = ProductPackId
                                                     and Product.COUNTRYCODE = CountryCode
                                                     and Product.ACTIVERECORD = 'Yes';
    Candidates: Association to many CandidatesView on Candidates.PriceAgreementId = ID;
    Materials: Association to many MasterData.PT_TMSKUPRDPCK on Materials.CountryCode = CountryCode 
                                                            and Materials.ProductPackID = ProductPackId
                                                            and Materials.ActiveRecord = 'Yes';
    /*NewMaterials: Association to many NewMaterialsView on NewMaterials.CountryCode = CountryCode // not unique to price agreement? As we could have multiple price agreements on the same productPackId
                                    and NewMaterials.ProductPackId = ProductPackId
                                    and NewMaterials.PriceAgreementId = ID;*/
    CustomerPrices: Association to many CustomerPrices on CustomerPrices.PriceAgreementId = ID;
    ConsumerPrice: Association to MasterDataViews.MostRecentConsumerPricesView on ConsumerPrice.CountryCode = CountryCode 
                                                                                     and ConsumerPrice.ProductPackId = ProductPackId;
    OfferProduct: Association to TransactionalData.PT_TMOFPR on OfferProduct.OfferID = OfferId
                                                             and OfferProduct.ProductCode = ProductPackId;
    Deliveries: Association to many PriceAgreementDataViews.Deliveries on Deliveries.PriceAgreementId = ID;
    FOC: Association to many PriceAgreementDataViews.PriceAgreementFOC on FOC.CountryCode = CountryCode
                                                                        and FOC.OfferID = OfferId
                                                                        and FOC.ProductCode = ProductPackId;
    MaterialsFOC: Association to TransactionalData.ProductPricing on MaterialsFOC.CountryCode = CountryCode
                                                                           and MaterialsFOC.OfferID = OfferId
                                                                           and MaterialsFOC.ProductCode = ProductPackId;
    PriceConditions: Association to many TransactionalData.PriceCondition 
                                        on PriceConditions.OfferID = OfferId
                                        and PriceConditions.ProductCode = ProductPackId
                                        and PriceConditions.CountryCode = CountryCode;
    SettlementDates: Composition of many SettlementDates on SettlementDates.PriceAgreementId = ID;
    MasterPrices: Association to MasterDataViews.MostRecentMasterPricesView on MasterPrices.ProductPackId = ProductPackId
                                                                            and MasterPrices.CountryCode = CountryCode  ;
    User: Association to AdminData.PT_TMUSER on User.CWID = createdBy;
}

entity PriceAgreementAcknowledgementHistory: cuid, managed {
    PriceAgreementID: UUID;
    ExpiryDate:  DateTime;
    ExpiryExtensionPeriod: Integer;
    Acknowledged: Boolean;
}

entity CustomerPrices: cuid, managed {
    // @cds.api.ignore
    @assert.notNull: false
    ValidFrom: Timestamp not null;
    // @cds.api.ignore
    @assert.notNull: false
    ValidTo: Timestamp not null;
    EffectiveDate: DateTime;
    ExpiryDate: DateTime;
    PriceAgreementId: UUID not null;
    PriceAgreement: Association to PriceAgreements on PriceAgreement.ID = PriceAgreementId;
    InstituteId: Integer;
    Institute: Association to MasterData.PT_TMINST on Institute.InstituteID = InstituteId;
    CountryCode: String not null;
    ProductPackId: Integer not null;
    FOCproductPackID: Integer;
    MaterialNumber: String not null;
    FOCmaterialNumber: String;
    Synchronized: Boolean;
    Price: Double;
    PriceCondition: String;
    Applied: Boolean; 
    RefIdocNumber: String;
    Notified: Boolean default false;
    ProductPack: Association to MasterData.PT_TMPRDPCK on ProductPack.PRODUCTPACKID = ProductPackId;
}

entity SettlementDates: managed {
    key PriceAgreementId: String not null;
    key FromDate: Date;
    ToDate: Date;
}
entity CustomerPrices_History: managed {
    ID: UUID;
    ValidFrom: Timestamp;
    ValidTo: Timestamp;
    EffectiveDate: DateTime;
    ExpiryDate: DateTime;
    PriceAgreementId: UUID not null;
    PriceAgreement: Association to PriceAgreements on PriceAgreement.ID = PriceAgreementId;
    InstituteId: Integer;
    CountryCode: String not null;
    ProductPackId: Integer not null;
    FOCproductPackID: Integer;
    MaterialNumber: String not null;
    FOCmaterialNumber: String;
    Synchronized: Boolean;
    Price: Double;
    PriceCondition: String;
    Applied: Boolean; 
    RefIdocNumber: String;
    Notified: Boolean default false;
   
}

/**
 * This view lists candidate institutes that can participate in a price agreement 
 * but don't have a CustomerPrices set yet
 */
 //EHQUT-396133-Italy- INC20664196 - Private customers in price agreements for regional tenders
entity CandidatesView as select from PriceAgreements as pa 
left outer join MasterData.Tenders_in_Regions AS tr on pa.TenderId = tr.TenderID
inner join MasterData.PT_TMINST AS inst on pa.CountryCode = inst.CountryCode
       and tr.RegionID = inst.RegionID
       and inst.InstituteType = 'Public Account' and inst.InstituteID not in (select InstituteID from MasterData.PT_TMINST where CountryCode = 'IT' and (right(Comment,7)= 'Ship To' or right(Comment,4) in ('0003','0004','0005','0006','0007')))
       
{
    pa.ID as PriceAgreementId,
    key pa.TenderId,
    key inst.InstituteID as CandidateID,
    inst.InstituteName as CandidateName,
    tr.Region.ID as RegionId
}
union
select from PriceAgreements as pa
inner join MasterData.PT_TMINST AS inst on pa.CountryCode = inst.CountryCode and pa.InstituteId = inst.InstituteID
{
    pa.ID as PriceAgreementId,
    pa.TenderId,
    inst.InstituteID as CandidateID,
    inst.InstituteName as CandidateName,
    inst.Region.ID as RegionId
}where inst.InstituteType <> 'Region(s)'
// Add children institutes as price agreement candidates
union
select from PriceAgreements as pa
inner join MasterData.PT_TMINSHIER as hier on pa.InstituteId = hier.ParentInstituteID
inner join MasterData.PT_TMINST AS inst on hier.InstituteID = inst.InstituteID
{
    pa.ID as PriceAgreementId,
    pa.TenderId,
    inst.InstituteID as CandidateID,
    inst.InstituteName as CandidateName,
    inst.RegionID as RegionId
}where inst.ActiveRecord = 'Yes'
and hier.ActiveRecord = 'Yes'
// Add all public institutes in Spain as candidates for price agreement when tender institute is of type "National"
union
select from PriceAgreements as pa
inner join MasterData.PT_TMINST AS inst on pa.InstituteId = inst.InstituteID 
inner join MasterData.PT_TMINST AS inst2 on (inst2.InstituteType = 'Public Account' or inst2.InstituteType = 'Governmental Account') and pa.CountryCode = inst2.CountryCode
{
    pa.ID as PriceAgreementId,
    pa.TenderId,
    inst2.InstituteID as CandidateID,
    inst2.InstituteName as CandidateName,
    inst2.RegionID as RegionId
}where inst.InstituteType = 'National'
and inst.ActiveRecord = 'Yes';


/**
 * This view tells us if a new SKU has been added from SAP to the master data automatically through interfacing.
 * Indicated with the "isNew" field
 */
entity NewMaterialsView as select from MasterData.PT_TMSKUPRDPCK  as sku

inner join PriceAgreements as pa on pa.CountryCode = sku.CountryCode and pa.ProductPackId = sku.ProductPackID

left outer join CustomerPrices as cp 
  on cp.MaterialNumber = sku.SKUCode
  and cp.CountryCode = sku.CountryCode 
  and cp.ProductPackId = sku.ProductPackID
  and cp.PriceAgreementId = pa.ID

   {
        key sku.CountryCode,
        key sku.ProductPackID as ProductPackId:String,
        key sku.SKUCode as MaterialNumber:Integer,
        case
            when  min(cp.Price) is null then true else false 
        end as isNew: Boolean,
        pa.ID as PriceAgreementId:String
} where sku.ActiveRecord = 'Yes' 
group by sku.CountryCode, sku.ProductPackID, sku.SKUCode,pa.ID;

/**
 * This view tells us if a new SKU has been added from SAP to the master data automatically through interfacing.
 * Indicated with the "isNew" field
 */

entity NewFOCMaterialsView as select from MasterData.PT_TMSKUPRDPCK as sku
inner join PriceAgreementDataViews.PaMainFOCView on PaMainFOCView.CountryCode = sku.CountryCode and PaMainFOCView.FOCproductId = sku.ProductPackID
left outer join CustomerPrices as cp 
  on  cp.FOCmaterialNumber = sku.SKUCode 
  and cp.CountryCode = sku.CountryCode 
  and cp.FOCproductPackID = sku.ProductPackID {
        key sku.CountryCode,
        key sku.ProductPackID as FOCProductPackId:String,
        key sku.SKUCode as FOCMaterialNumber:Integer,
        case
            when min(cp.Price) is null then true else false 
        end as isNew: Boolean,
        PaMainFOCView.PriceAgreementId
} group by sku.CountryCode, sku.ProductPackID, sku.SKUCode,PaMainFOCView.PriceAgreementId;


//CR2
//EHQUT-INC20664196 - Private customers in price agreements for regional tenders
entity CandidatePrices as select from PriceAgreements AS pa
inner join CandidatesView AS ca on ca.PriceAgreementId = pa.ID 
//inner join MaterialsView ma on ma.ProductPackId = pa.ProductPackId and pa.CountryCode = ma.CountryCode 
inner join MasterData.PT_TMSKUPRDPCK AS ma on pa.CountryCode = ma.CountryCode and ma.ProductPackID = pa.ProductPackId and ma.ActiveRecord = (case when ma.CountryCode = 'ES' then ma.ActiveRecord else 'Yes' end)
inner join MasterData.PT_TMINST AS ins on pa.CountryCode = ins.CountryCode and ca.CandidateID = ins.InstituteID and ins.ActiveRecord ='Yes'
left outer join CustomerPrices AS cp on pa.ID = cp.PriceAgreementId 
    and cp.MaterialNumber = ma.SKUCode 
    and cp.InstituteId = ca.CandidateID 
    and cp.PriceCondition <> 'YA03' // Italy FOC
    and cp.PriceCondition <> 'YA01' // Spain FOC
    and cp.PriceCondition <> 'YAW1'
    and cp.PriceCondition <> 'YAW2'
    { // Spain Rappel
        key pa.ID as PriceAgreementId,
        key ca.TenderId,
        key ca.CandidateID as InstituteId,
        ca.CandidateName as InstituteName,
        ins.InstituteType as InstituteType,
        pa.CountryCode,
        pa.ProductPackId, 
        key ma.SKUCode as MaterialNumber,
        cp.ID as CustomerPriceId,
        case
            when cp.Price is null then false 
            when cp.Price is not null and cp.Applied is not null then cp.Applied
            else true 
        end as Applied:Boolean,
        ifnull(cp.Synchronized, false) as Synchronized:Boolean,
        ifnull(cp.Price, pa.Price) as Price:Double,
        ifnull(cp.EffectiveDate, pa.EffectiveDate) as EffectiveDate:DateTime,
        ifnull(cp.ExpiryDate, pa.ExpiryDate) as ExpiryDate:DateTime,
        ins.CustomerID, //by candidate
        cp.PriceCondition
        // pa.Institute.CustomerID //by price agreement
}where (case when ma.ActiveRecord = 'No' and (cp.Synchronized is null or cp.Synchronized = false) then 0 else 1 end)= 1;

//EHQUT-199066-Italy – Brand filter in Price Agreements
//Distinct list of Products
// entity PriceAgreementProductNames as select from PriceAgreements {
// 	key ProductPackId,
//     CountryCode,
//     Product.ProductPack.PRODUCTPACKNAME as ProductName
// } group by ProductPackId, CountryCode, Product.ProductPack.PRODUCTPACKNAME;
entity PriceAgreementProductNames as select from PriceAgreements as pa
inner join MasterDataViews.CountryBrandProducts as ca on pa.ProductPackId= ca.PRODUCT_ID{
	key pa.ProductPackId,
    pa.CountryCode,
    Product.ProductPack.PRODUCTPACKNAME as ProductName,
    ca.BRAND_ID,
    ca.BRAND_NAME
} group by pa.ProductPackId, pa.CountryCode, Product.ProductPack.PRODUCTPACKNAME,ca.BRAND_ID,ca.BRAND_NAME;


entity CustomerPricesQC: cuid, managed {
    CustomerPriceId             : UUID;
    CountryCode                 : String;
    VKORG                       : String;   // Sales Organisation
    KSCHL                       : String;   // Condition Type
    KUNNR                       : String;   // Customer Number
    MATNR                       : String;   // Material Number
    YCIG                        : String;   // Contract Reference
    KBETR                       : String;   // Condition Value
    KPEIN                       : String;   // Unit for price
    DATAB                       : String;   // Effective Date
    DATBI                       : String;   // Expiry Date
    KRECH                       : String;   // 
    KONMS                       : String;   // 
    MEINS                       : String;   // 
    BOMAT                       : String;   // 
    KSTBM                       : String;   // 
    MIKBAS                      : String;   // 
    MXBAS                       : String;   // 
    SAP_VKORG                   : String;   // Sales Organisation
    SAP_KSCHL                   : String;   // Condition Type
    SAP_KUNNR                   : String;   // Customer Number
    SAP_MATNR                   : String;   // Material Number
    SAP_YCIG                    : String;   // Contract Reference
    SAP_KBETR                   : String;   // Condition Value
    SAP_KPEIN                   : String;   // Unit for price
    SAP_KONWA                   : String;   // To be checked
    SAP_DATAB                   : String;   // Effective Date
    SAP_DATBI                   : String;   // Expiry Date
    SAP_VTWEG                   : String;   // To be checked
    SAP_MAKTX                   : String;
    SAP_DISPKNRMM               : String;   // Minimum quantity
    SAP_DISPKNRNM               : String;   // Maximum quantity
    SAP_KNRME                   : String;
    SAP_DISPKNRZM               : String;   // Free goods quantity
    SAP_KNREZ                   : String;
    SAP_KNRDD                   : String;
    SAP_KPMEIN                  : String;
    SAP_KNRMAT                  : String;   // Free goods product
    Status                      : String enum {
        ToCheck;
        Failed;
        OK;
        NotInSAP;
    } default 'ToCheck'; 
    CountChecks                 : Integer; // Number of 
    emailNotificationSent       : Boolean default false; // Owners have been notified in case QC failed
    // Associations
    CustomerPrice               : Association to CustomerPrices on CustomerPrice.PriceAgreementId = CustomerPriceId;
    Institute                   : Association to MasterData.PT_TMINST on Institute.CustomerID = LTRIM(KUNNR, '0') and Institute.CountryCode = CountryCode;
}
//EJUVE-CR3 START
entity PriceAgreement_APPRST : cuid, managed {
        CountryCode      : String;
    key PriceAgreementID : UUID;
        ApprovalStatus   : String(30)  null;
        OfferId          : String;
        ProductPackID    : Integer  null;
        InstituteID      : Integer  null;
        EffectiveDate    : Date  null;
        ExpiryDate       : Date  null;
        PriceAgreements  : Association to PriceAgreements
                               on PriceAgreements.ID = PriceAgreementID;

}
//EJUVE-CR3 END