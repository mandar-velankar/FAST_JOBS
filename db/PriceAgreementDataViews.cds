namespace com.bayer.SXTENDER.PriceAgreementDataViews;

using {com.bayer.SXTENDER.PriceAgreementData} from './PriceAgreementData';
using {com.bayer.SXTENDER.TransactionalData} from './TransactionalData';
using { com.bayer.SXTENDER.MasterData.SAP } from '../db/SAP';
using {com.bayer.SXTENDER.MasterData} from './MasterData';
using {com.bayer.SXTENDER.AdminData} from './AdminData';





entity PriceAgreementExpiryDate as select from PriceAgreementData.PriceAgreements as PriceAgreements {
    key PriceAgreements.TenderId,
    max(PriceAgreements.ExpiryDate) as ExpiryDate:DateTime
}group by PriceAgreements.TenderId, PriceAgreements.ExpiryDate;


entity PriceAgreementFOC as select from TransactionalData.ProductPricing as ProductPricing
left outer join  TransactionalData.PT_TMBDPR as PT_TMBDPR 
    on ProductPricing.CountryCode = PT_TMBDPR.CountryCode
    and ProductPricing.ProductCode = PT_TMBDPR.ProductCode
    and ProductPricing.OfferID = PT_TMBDPR.OfferID 
    {
    key ProductPricing.OfferID,
    key ProductPricing.ProductCode,
    key ProductPricing.CountryCode,
    PT_TMBDPR.Product.SKU.PRODUCTPACKNAME as ProductPackName,
    ProductPricing.ProductCode as ProductPackId:Integer,
    PT_TMBDPR.FOC as FreeGoods:Double,
    PT_TMBDPR.FOC_ABS_PCT as FreeGoods_ABS_PCT:String,
    ifnull(PT_TMBDPR.FOCStep,0) as FreeGoods_Step:Double
} where PT_TMBDPR.FOC is not null and PT_TMBDPR.FOC > 0 and PT_TMBDPR.FOC  != '0'
union
select from TransactionalData.ProductPricing 
{
    OfferID,
    ProductCode,
    CountryCode,
    FreeGoodsOther.ProductPack.PRODUCTPACKNAME as ProductPackName,
    FreeGoodsOther.ProductPackId,
    FreeGoodsOther.FreeGoodsOther as FreeGoods:Double,
    FreeGoodsOther.FreeGoodsOther_ABS_PCT as FreeGoods_ABS_PCT:String,
    ifnull(FreeGoodsOther.FreeGoodsOther_Step,0) as FreeGoods_Step:Double

} where FreeGoodsOther.FreeGoodsOther is not null and FreeGoodsOther.FreeGoodsOther > 0 and FreeGoodsOther.FreeGoodsOther  != '0';

// entity Deliveries as select from PriceAgreementData.CustomerPrices as materials 
// inner join SAP.ItalyDeliveries as italydeliveries on ltrim(materials.MaterialNumber,'0') = ltrim(italydeliveries.MATNR,'0')
//     //and materials.InstituteId = italydeliveries.KUNNR 
// {
//     key italydeliveries.ID,
//     italydeliveries.WADAT_IST,
//     italydeliveries.ANZPK,
//     italydeliveries.VRKME,
//     italydeliveries.LFART,
//     italydeliveries.CHARG,
//     italydeliveries.VGBEL,
//     materials.PriceAgreementId,
//     materials.Institute.InstituteName
    
// } ;

//EHTWQ-369968-Italy-Issue with doubled values in FAST dashboards
entity DistinctCustomerPrice as select from PriceAgreementData.CustomerPrices as materials{
key materials.InstituteId,
key materials.MaterialNumber,
key materials.PriceAgreementId,
key materials.EffectiveDate
}group by materials.InstituteId,materials.MaterialNumber,materials.PriceAgreementId ,
materials.EffectiveDate;
//EHTWQ-369968-Italy-Issue with doubled values in FAST dashboards


//EHQUT-202495-Italy - fix for mapping of SAP Italy deliveries
//EHTWQ-369968-Italy-Issue with doubled values in FAST dashboards
entity Deliveries as select from DistinctCustomerPrice as materials
inner join MasterData.PT_TMINST as institutes
  on materials.InstituteId=institutes.InstituteID
inner join SAP.ItalyDeliveries as italydeliveries
  on ltrim(materials.MaterialNumber,'0') = ltrim(italydeliveries.MATNR,'0')
  and institutes.CustomerID = ltrim(italydeliveries.KUNAG,'0')
  and italydeliveries.WADAT_IST >=  materials.EffectiveDate
{
    key italydeliveries.ID,//unique identifier for SAP delivery entry
    italydeliveries.WADAT_IST,//actual delivery date
    italydeliveries.LFIMG,//delivery quantity
    italydeliveries.VRKME,//meant to be sales unit
    italydeliveries.LFART,//delivery type
    italydeliveries.CHARG,//batch number
    italydeliveries.VGBEL,//document reference number
    materials.PriceAgreementId,//link to price agreement in FAST
    institutes.InstituteName//name of institute

} ;
//EHQUT-202495-Italy - fix for mapping of SAP Italy deliveries
entity PaMainFOCView as select from PriceAgreementFOC as FOC
inner join PriceAgreementData.PriceAgreements as pa on pa.CountryCode = FOC.CountryCode
                                                                        and pa.OfferId = FOC.OfferID
                                                                        and pa.ProductPackId = FOC.ProductCode

{
key pa.ID as PriceAgreementId:String,   
key FOC.CountryCode,
key FOC.OfferID,
key FOC.ProductCode as MainProductId:String,
key FOC.ProductPackId as FOCproductId:String

    
} group by pa.ID,FOC.CountryCode,FOC.OfferID,FOC.ProductCode,FOC.ProductPackId ;


entity MaterialsConcatList as select from MasterData.PT_TMSKUPRDPCK as materials{
  key materials.ProductPackID,
  key materials.CountryCode,
  key materials.ActiveRecord,
  STRING_AGG(CAST(materials.SKUCode as String), ', ') as MaterialsList:String
} group by materials.ProductPackID,
           materials.CountryCode,
           materials.ActiveRecord;


entity PriceAgreementPriceConditionNotificationMailJobView as select from PriceAgreementData.CustomerPrices as CP 
inner join PriceAgreementData.PriceAgreements as PA 
  on CP.PriceAgreementId = PA.ID
inner join TransactionalData.PT_TMTEND as TND
  on TND.TenderID = PA.TenderId
inner join AdminData.PT_TMUSER as USR
  on USR.CWID = TND.SubmittedBy
left join MasterData.PT_TMINST as INST
  on CP.InstituteId=INST.InstituteID and CP.CountryCode = INST.CountryCode
left join MasterData.PT_TMSKUPRDPCK as PRDPCK 
  on CP.MaterialNumber = PRDPCK.SKUCode
  and CP.CountryCode = PRDPCK.CountryCode
  and PRDPCK.ActiveRecord = 'Yes'
left join MasterData.PT_TMPRDPCK as PRD
  on PRDPCK.ProductPackID = PRD.PRODUCTPACKID
  and PRD.ACTIVERECORD = 'Yes'
{
  year(CP.modifiedAt) as Year,
	month(CP.modifiedAt) as Month,
	dayofmonth(CP.modifiedAt) as Day,
  CP.modifiedAt as ModifiedAt,
  TND.TenderID as TenderId,
	USR.UserName,
  USR.UserEmail,
  USR.CWID,
  CP.CountryCode,
	INST.InstituteName,
	INST.CustomerID as InstituteID,
	PRD.PRODUCTPACKNAME,
	CP.MaterialNumber as MaterialNumber,
	PA.OfferId as OfferId,
	CP.PriceCondition as PriceCondition,
	CP.EffectiveDate as EffectiveDate,
	CP.ExpiryDate as ExpiryDate,
  PA.ID as PriceAgreementId
	
} Where CP.CountryCode = 'ES' 
  and CP.Synchronized =  true 
  and CP.RefIdocNumber is not null 
  and CP.RefIdocNumber <> ''
  and TND.Classification = 'Commercial Agreement';