using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using { com.bayer.SXTENDER.PriceAgreementData } from '../db/PriceAgreementData';
using { com.bayer.SXTENDER.MasterData } from '../db/MasterData';
using { com.bayer.SXTENDER.MasterDataViews } from '../db/MasterDataViews';
using { com.bayer.SXTENDER.PriceAgreementDataViews } from '../db/PriceAgreementDataViews';
using { com.bayer.SXTENDER.AdminData } from '../db/AdminData';

service PriceAgreementService @(path: 'priceagreement') @(requires:['f_tndr_cag_admin','f_tndr_cag_priceagreements_user','f_tndr_cag_technical_user','authenticated-user']){

    @cds.persistence.exists
    entity PriceAgreements @(cds.redirection.target:true) as projection on PriceAgreementData.PriceAgreements;

    //EHQUT-383702-Spain search Division filter
    //EHQUT-383697-Spain - visual mark to notify that the offer is canceled in FAST
    @cds.persistence.exists
    entity PriceAgreementsMasterView @(cds.redirection.target:true) as select from PriceAgreementData.PriceAgreements as pa
    inner join MaterialsConcatList as list on list.CountryCode = pa.CountryCode and list.ProductPackID = pa.ProductPackId and list.ActiveRecord = 'Yes'
    left outer join PriceAgreementDataViews.PriceAgreementNewMaterialsView as panm on panm.ID = pa.ID
    left outer join PriceAgreementDataViews.PriceAgreementNewAgreements as pana on pana.ID = pa.ID
    left outer join PriceAgreementDataViews.PriceAgreementActiveAgreements as paaa on paaa.ID = pa.ID
    left outer join PriceAgreementDataViews.PriceAgreementUpdatedRetailPrice as paurp on paurp.ID = pa.ID
    left outer join PriceAgreementDataViews.PriceAgreementNewYLLPorYLAP as panmpr on panmpr.ID = pa.ID{
        key pa.ID,
            pa.createdAt,
            pa.createdBy,
            pa.modifiedAt,
            pa.modifiedBy,
            pa.ExpiryDate,
            pa.EffectiveDate,
            pa.OriginalEffectiveDate,
            pa.ListPrice,
            pa.RetailPrice,
            pa.Price,
            pa.Currency,
            pa.UoM,
            pa.Discount,
            pa.DeliveredVolume,
            pa.AwardedVolume,
            pa.CountryCode,
            pa.InstituteId,
            pa.TenderId,
            pa.ProductPackId,
            ifnull(paaa.Synchronized, false) as Synchronized: Boolean,
            pa.SynchronizationStatus,
            ifnull(panm.hasNewMaterials, false) as hasNewMaterials: Boolean,
            case when (panmpr.YLLP = 0 or panmpr.YLAP = 0) then 0 else 1 end as hasEitherNewYLLPorYLAP: Integer,
            case when (paurp.ListPriceEqual = 0 or paurp.RetailPriceEqual = 0) then true else false end as hasNewPrice: Boolean,
            pa.hasNewYLLP,
            pa.hasNewYLAP,
            pa.hasProductPackId,
            pa.IgnorePVLPriceChange,
            pa.IgnoreConfPriceChange,
            Case when pa.ExpiryDate IS NOT NULL 
                then 
                    CASE when (DATS_ADD_MONTHS(REPLACE(CURRENT_DATE, '-', ''), 3) >= to_date(pa.ExpiryDate) and to_date(pa.ExpiryDate) >= CURRENT_DATE)
                    then true 
                    else false 
                    end 
                else false 
            end AS ExpiringSoon: Boolean,
            case when( (to_date(pa.ExpiryDate) < CURRENT_DATE ) and pa.isCancelled = false ) then true else false end as Expired: Boolean,
            ifnull(pana.isNewPriceAgreement, false) as isNewPriceAgreement: Boolean,
            case when pana.isNewPriceAgreement = false then 1 else 0 end as AppliedCount: Integer,
            case when pa.Status = 'Cancelled' then true else false end as isCancelled: Boolean,
            pa.OfferId,
            pa.ExtendPriceAgreement,
            pa.ExpiryExtensionPeriod,
            pa.ExpiryExtensionAcknowledged,
            pa.Status,
            pa.CancellationComment,
            pa.Product,
            pa.Institute,
            pa.Tender,
            pa.Candidates,
            pa.Materials,
            pa.CustomerPrices,
            pa.ConsumerPrice,
            pa.OfferProduct,
            pa.Deliveries,
            pa.FOC,
            pa.MaterialsFOC,
            pa.PriceConditions,
            pa.SettlementDates,
            pa.MasterPrices,
            pa.User,
            pa.OfferProduct.Offer.Division as Division,
            list.MaterialsList
    };
    @cds.persistence.exists
    entity Candidates as projection on PriceAgreementData.CandidatesView;
    @cds.persistence.exists
    entity CandidatePrices as projection on PriceAgreementData.CandidatePrices;
    @cds.persistence.exists
    entity CustomerPrices as select from PriceAgreementData.CustomerPrices;
    @cds.persistence.exists
    entity ConsumerPrices as select from MasterDataViews.MostRecentConsumerPricesView;
    @cds.persistence.exists
    entity PriceCondition as projection on TransactionalData.PriceCondition;
    @cds.persistence.exists
    entity PriceConditionClassification as projection on TransactionalData.PriceConditionClassification;
    @cds.persistence.exists
    entity RoyalDecree as projection on MasterData.RoyalDecree;
    //entity Materials as projection on PriceAgreementData.MaterialsView;
    @cds.persistence.exists
    entity NewMaterialsView as projection on PriceAgreementData.NewMaterialsView;
    @cds.persistence.exists
    entity NewFOCMaterialsView as projection on PriceAgreementData.NewFOCMaterialsView;
    @cds.persistence.exists
    entity PT_TMINST as projection on MasterData.PT_TMINST;
    @cds.persistence.exists
    entity PT_TMCTPRDPCK as projection on MasterData.PT_TMCTPRDPCK;
    @cds.persistence.exists
    entity PT_TMTEND @(cds.redirection.target:true) as projection on TransactionalData.PT_TMTEND;
    @cds.persistence.exists
    entity PT_TMPRDPCK as projection on MasterData.PT_TMPRDPCK;
    @cds.persistence.exists
    entity PriceAgreementProductNames as projection on PriceAgreementData.PriceAgreementProductNames;
    @cds.persistence.exists
    entity PriceAgreementFOC as projection on PriceAgreementDataViews.PriceAgreementFOC;
    @cds.persistence.exists
    entity Deliveries as projection on PriceAgreementDataViews.Deliveries;
    @cds.persistence.exists
    entity MaterialsFOC as projection on TransactionalData.ProductPricing;
    @cds.persistence.exists
    entity PT_TMSKUPRDPCK @(cds.redirection.target:true) as projection on MasterData.PT_TMSKUPRDPCK;
    @cds.persistence.exists
    entity FreeGoodsOther as projection on TransactionalData.FreeGoodsOther;
    @cds.persistence.exists
    entity PaMainFOCView as projection on PriceAgreementDataViews.PaMainFOCView;
    @cds.persistence.exists
    entity Settlements as projection on MasterData.Settlements;
    @cds.persistence.exists
    entity SettlementDates as projection on PriceAgreementData.SettlementDates;
    @cds.persistence.exists
    entity MasterPrices as projection on MasterDataViews.MostRecentMasterPricesView;
    @cds.persistence.exists
    entity PriceAgreement_APPRST as projection on PriceAgreementData.PriceAgreement_APPRST; //EJUVE-CR3
    //Brazil
    @cds.persistence.exists
    entity LotProducts as projection on TransactionalData.LotProduct;

    @cds.persistence.exists
    entity PT_TMOFPR as projection on TransactionalData.PT_TMOFPR;
    @cds.persistence.exists
    entity PT_TMOFRS as projection on TransactionalData.PT_TMOFRS;
    @cds.persistence.exists
    entity Country as projection on MasterData.PT_TMCTRY;
    @cds.persistence.exists
    entity Users as projection on AdminData.PT_TMUSER;
    @cds.persistence.exists
    entity MaterialsConcatList as projection on PriceAgreementDataViews.MaterialsConcatList;
    @cds.persistence.exists
    entity User @(cds.redirection.target:true) as projection on AdminData.PT_TMUSER;
    
    //Countries where user has accesss to
    @cds.persistence.exists
    entity UserCountry @(restrict: [
		{grant: '*', to: 'authenticated-user', where: 'User.CWID = $user.id'}
	])as projection on AdminData.PT_TMUSERCTRY {
        *,
        Country: redirected to Country,
        User: redirected to Users,
    };

    action syncPriceAgreements(ids : array of String);
    // action syncFocCustPrices(ids : array of String);
     //EJUVE-CR3 START
     @cds.persistence.exists
      entity PriceagreementOffers {
          PriceagreementID: UUID;
		  TenderID: String;
		  OfferID: String;
		  InstituteID: Integer;
		  InstituteName: String;
		  CustomerID: Integer;
		  ProductPackID: Integer;
		  ProductPackNAME: String;
          Status : String;
          ID : UUID;
		  EffectiveDate: Date;
		  ExpiryDate: Date;
		  OldExpiryDate: Date;
          UserEmail : String;
          
} 
//EJUVE-CR3 END
@cds.persistence.exists
entity PriceAgreementNewYLLPorYLAP as Select from PriceAgreementService.PriceAgreementsMasterView as pa
inner join TransactionalData.PriceCondition as pc on pa.OfferId=pc.OfferID and pa.ProductPackId=pc.ProductCode
inner join TransactionalData.PriceConditionClassification as pcc on pc.PriceConditionClassification.ID=pcc.ID and pcc.isMain=true
inner join MasterDataViews.MostRecentMasterPricesView as mp on pa.ProductPackId=mp.ProductPackId and pa.CountryCode=mp.CountryCode
inner join MasterData.PT_TMINST as i on pa.InstituteId=i.InstituteID
inner join MasterData.PT_TMPRDPCK as p on p.PRODUCTPACKID=pa.ProductPackId{
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
}where pa.CountryCode = 'ES' and pa.Expired=false and pa.isCancelled=false and pa.Synchronized=true and pa.IgnorePVLPriceChange<>true and pa.IgnoreConfPriceChange<>true;
}