namespace com.bayer.SXTENDER.PriceAgreementDataViews;

using {com.bayer.SXTENDER.PriceAgreementData} from './PriceAgreementData';
using {com.bayer.SXTENDER.TransactionalData} from './TransactionalData';
using { com.bayer.SXTENDER.MasterData.SAP } from '../db/SAP';
using {com.bayer.SXTENDER.MasterData} from './MasterData';
using {com.bayer.SXTENDER.AdminData} from './AdminData';
using {com.bayer.SXTENDER.MasterDataViews} from './MasterDataViews';

@cds.persistence.exists
entity PriceAgreementExpiryDate as select from PriceAgreementData.PriceAgreements as PriceAgreements {
    key PriceAgreements.TenderId,
    max(PriceAgreements.ExpiryDate) as ExpiryDate:DateTime
}group by PriceAgreements.TenderId, PriceAgreements.ExpiryDate;

@cds.persistence.exists
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

@cds.persistence.exists
entity DistinctCustomerPrice as select from PriceAgreementData.CustomerPrices as materials{
key materials.InstituteId,
key materials.MaterialNumber,
key materials.PriceAgreementId,
key materials.EffectiveDate
}group by materials.InstituteId,materials.MaterialNumber,materials.PriceAgreementId ,
materials.EffectiveDate;

@cds.persistence.exists
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

@cds.persistence.exists
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

@cds.persistence.exists
entity MaterialsConcatList as select from MasterData.PT_TMSKUPRDPCK as materials{
  key materials.ProductPackID,
  key materials.CountryCode,
  key materials.ActiveRecord,
  STRING_AGG(CAST(materials.SKUCode as String), ', ') as MaterialsList:String
} group by materials.ProductPackID,
           materials.CountryCode,
           materials.ActiveRecord;

@cds.persistence.exists
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

@cds.persistence.exists
entity PriceAgreementNewMaterialsView as Select from PriceAgreementData.PriceAgreements as pa 
left outer join PriceAgreementData.NewMaterialsView as nmv on pa.ID = nmv.PriceAgreementId and nmv.isNew = true
left outer join PriceAgreementData.NewFOCMaterialsView as nfocmv on pa.ID = nfocmv.PriceAgreementId and nfocmv.isNew = true
left outer join PriceAgreementData.CustomerPrices as cp on cp.PriceAgreementId = pa.ID{
pa.ID,
pa.CountryCode,
case when (count(nmv.MaterialNumber)=0 and count(nfocmv.FOCMaterialNumber)=0) or count(cp.ID) = 0
then false
else true
end as hasNewMaterials: Boolean
}group by pa.ID, pa.CountryCode;

@cds.persistence.exists
entity PriceAgreementNewAgreements as Select from PriceAgreementData.PriceAgreements as pa
left outer join PriceAgreementData.CustomerPrices as cp on cp.PriceAgreementId = pa.ID{
pa.ID,
pa.CountryCode,
CASE when count(cp.ID) = 0 then true else false end AS isNewPriceAgreement: Boolean
}group by pa.ID, pa.CountryCode;

@cds.persistence.exists
entity PriceAgreementActiveAgreements as Select from PriceAgreementData.PriceAgreements as pa
left outer join PriceAgreementData.CustomerPrices as cp on cp.PriceAgreementId = pa.ID{
pa.ID,
pa.CountryCode,
  CASE
      when cp.Synchronized = true
      then true
      else false
    end AS Synchronized: Boolean
}group by pa.ID, pa.CountryCode, cp.Synchronized;

@cds.persistence.exists
entity PriceAgreementUpdatedRetailPrice as Select from PriceAgreementData.PriceAgreements as pa
left outer join MasterDataViews.MostRecentConsumerPricesView as cp on cp.CountryCode = pa.CountryCode and cp.ProductPackId = pa.ProductPackId {
    pa.ID,
    pa.CountryCode,
      CASE
        WHEN pa.UoM = 'Pack' THEN
            CASE
                WHEN ABS(pa.ListPrice - cp.ConsumerPriceExclPP) < 0.0001 THEN 1
                ELSE 0
            END
        ELSE
            CASE
                WHEN ABS(pa.ListPrice - cp.ConsumerPriceExclPU) < 0.0001 THEN 1
                ELSE 0
            END
    END AS ListPriceEqual: Integer,
    CASE
        WHEN pa.UoM = 'Pack' THEN
            CASE
                WHEN ABS(pa.RetailPrice - cp.MaxPriceNhsPP) < 0.0001 THEN 1
                ELSE 0
            END
        ELSE
            CASE
                WHEN ABS(pa.RetailPrice - cp.MaxPriceNhsPU) < 0.0001 THEN 1
                ELSE 0
            END
    END AS RetailPriceEqual: Integer
};

@cds.persistence.exists
entity PriceAgreementNewYLLPorYLAP as Select from PriceAgreementData.PriceAgreements as pa
inner join TransactionalData.PriceCondition as pc on pa.OfferId=pc.OfferID and pa.ProductPackId=pc.ProductCode
inner join TransactionalData.PriceConditionClassification as pcc on pc.PriceConditionClassification.ID=pcc.ID and pcc.isMain=true
inner join MasterDataViews.MostRecentMasterPricesView as mp on pa.ProductPackId=mp.ProductPackId and pa.CountryCode=mp.CountryCode
inner join MasterData.PT_TMINST as i on pa.InstituteId=i.InstituteID
inner join MasterData.PT_TMPRDPCK as p on p.PRODUCTPACKID=pa.ProductPackId
left join PriceAgreementData.CustomerPrices as cp on cp.PriceAgreementId = pa.ID{
    pa.ID,
    pa.CountryCode,
    CASE
        when pa.UoM = 'Pack' and i.InstituteType ='Private Account'
          then 
              CASE
                WHEN ABS(mp.YLLP - pc.PVL) < 0.0001 THEN 1
                ELSE 0
              END  
          else 
            CASE
                WHEN ABS(mp.YLLP - (pc.PVL * p.PACKFACTOR)) < 0.0001 THEN 1
                ELSE 0
            END
    END AS YLLP: Integer,
    CASE
        when pa.UoM = 'Pack' and i.InstituteType <> 'Private Account'
          then 
              CASE
                WHEN ABS(mp.YLAP - pc.ConfidentialPrice) < 0.0001 THEN 1
                ELSE 0
              END  
          else 
            CASE
                WHEN ABS(mp.YLLP - (pc.ConfidentialPrice * p.PACKFACTOR)) < 0.0001 THEN 1
                ELSE 0
            END
    END AS YLAP: Integer
}where pa.CountryCode = 'ES' and pa.Status is NULL and cp.Synchronized = true