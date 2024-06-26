namespace com.bayer.SXTENDER.TransactionalDataConversion;

using { User, Country, managed } from '@sap/cds/common';
using { com.bayer.SXTENDER.AdminData } from './AdminData';
using { com.bayer.SXTENDER.MasterData } from './MasterData';
using { com.bayer.SXTENDER.MasterDataViews } from './MasterDataViews';
using { com.bayer.SXTENDER.TransactionalData } from './TransactionalData';
using { com.bayer.SXTENDER.MasterDataLatestValues } from './MasterDataLatestValues';
using { com.bayer.SXTENDER.PricingAppData } from './PricingAppData';

//converting the Offers
entity PT_TMOFRS as select from TransactionalData.PT_TMOFRS as offer {
        //key fields must stay the same for projected ()
        offer.Active as Active,

        //converted names & values
        offer.CountryCode as CountryCode,
        key offer.OfferID as ContractNumber,
        'Tender' as ChannelName : String,
        offer.CreationDate as createdAt,
        offer.SubmittedBy as modifiedBy,
        offer.SubmissionDate as modifiedAt,
        offer.SubmissionDate as ContractDate,
        case when offer.Active = 1 then true else false end as Enabled:Boolean,
        offer.Tender.InstituteID as InstituteId,
        offer.DistributorID as DistributorId,
        offer.SellingCompany as SellingCompanyCode,
        offer.Currency as Currency,
        offer.Comment as Comment,
        offer.OfferValue.VALUE as OfferValue,
        offer.Product as Products,
        offer.Distributor as Distributor,
        offer.SellingCompanyDetails as SellingCompany,
        offer.TenderID,
        // offer.Tender.Institute as Institute,
        // offer.Tender.InstituteID as InstituteId,
        offer.Tender.Institute:redirected to MasterData.PT_TMINST
                              on Institute.InstituteID = InstituteId,
        offer.Tender.GroupPurchasing as GroupPurchasing,
    
}where offer.Active = 1;

//converting the Products 
entity PT_TMOFPR as select from TransactionalData.PT_TMOFPR as product {
    *,
    case when product.Active = 1 then true else false end as Enabled:Boolean
};

//converting the deliveries
entity PT_TMDLVTR as select from TransactionalData.PT_TMDLVTR as delivery {
        *,
        delivery.SubmittedOn as CreatedAt,
        delivery.SubmittedBy as CreatedBy,
        delivery.CountryCode as CountryCode,
        delivery.SKUCode as SkuCode,
        delivery.InstituteID as InstituteId,
        //delivery.Active as Active, //keep beceause its a key
        case when delivery.Active = 1 then true else false end as Enabled:Boolean,
        delivery.LocalOrDirectDelivery as LocalOrDirect,
        delivery.PlannedInAPO as PlannedInAPO,
        delivery.RequestedDeliveryDate as RequestedDeliveryDate,
        delivery.RequestedQuantity as RequestedDeliveryQuantity,
        delivery.ActualDeliveryDate as ActualDeliveryDate,
        delivery.ActualDeliveryQuantity as ActualDeliveryQuantity,
        null as UoM : String(255), //only existing in new table.. but add it here to have same structure 
        case delivery.Penalty 
                when 'Yes' then true 
                else false end as Penalty : Boolean,
        delivery.PenaltyValue as PenaltyValue,
        delivery.Currency as PenaltyCurrency,
        delivery.PenaltyReason as PenaltyReason,
        delivery.UndertakingLetters as UndertakingLetters,
        delivery.Compensated as Compensated,
        delivery.CompensationComment as CompensationComment,
        delivery.ProductCode as ProductCode, //keep beceause its a key
        delivery.PaidOrFree as PaidOrFree,
        delivery.PO as PO,
        delivery.InvoiceNo as InvoiceNo,
        delivery.SNo as SNo, //keep beceause its a key
        delivery.OfferID as OfferID, //keep beceause its a key
        delivery.Contract as Contract,
        delivery.PoDate as PoDate
        
}excluding {SKUCode,InstituteID,RequestedQuantity};

//converting letters
entity PT_TMUDLTRS as select from TransactionalData.PT_TMUDLTRS as letter {
        *,
        letter.COUNTRYCODE as CountryCode,
        letter.INSTITUTEID as InstituteId,
        letter.SKUCODE as SkuCode,
        letter.SUBMITTEDON  as CreatedAt,
        letter.SUBMITTEDBY as CreatedBy,
        case when letter.ACTIVE = 1 then true else false end as Enabled:Boolean,
        letter.REASONFORLETTER as ReasonForLetter,
        letter.QUANTITY as Quantity,
        letter.BATCH as Batch,
        letter.MANUFACTURINGDATE as ManufacturingDate,
        letter.EXPIRYDATE as ExpiryDate,
        letter.RETURNDATE as ReturnDate,
        letter.RETURNEDQTY as ReturnedQuantity,
        letter.UOM as UoM,
        letter.SNO as SNo,
        letter.OFFERID as OfferID,  //keep beceause its a key
        letter.TENDERID as TenderID //keep beceause its a key
        //ACTIVE as Active //keep beceause its a key
}excluding {
        TENDERID, OFFERID,
        COUNTRYCODE,INSTITUTEID,SKUCODE,SUBMITTEDON,SUBMITTEDBY,
        REASONFORLETTER,QUANTITY,BATCH,MANUFACTURINGDATE,EXPIRYDATE,RETURNDATE,RETURNEDQTY,UOM, SNO, ACTIVE
};