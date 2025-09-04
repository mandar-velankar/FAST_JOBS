namespace com.bayer.SXTENDER.TransactionalDataViews;

using { User, Country, managed } from '@sap/cds/common';
using { com.bayer.SXTENDER.AdminData } from './AdminData';
using { com.bayer.SXTENDER.MasterData } from './MasterData';
using { com.bayer.SXTENDER.MasterDataViews } from './MasterDataViews';
using { com.bayer.SXTENDER.TransactionalData } from './TransactionalData';
using { com.bayer.SXTENDER.BrazilContractingData } from './BrazilContractingData';

@cds.persistence.exists
entity LatestApprovalRequests as select from TransactionalData.PT_TMAPPRST as approvals{
    key approvals.OfferId,
    key approvals.ApproverEmailID,
    key approvals.ApproverType,
    max(approvals.Statustime) as MaxStatusTime:DateTime
}where approvals.Active = 1
group by approvals.OfferId,
    approvals.ApproverEmailID,
    approvals.ApproverType;

@cds.persistence.exists
entity ApprovalRequests as select from TransactionalData.PT_TMAPPRST as approvals
inner join LatestApprovalRequests as latestApprovals
    on approvals.OfferId = latestApprovals.OfferId 
    and approvals.Statustime = latestApprovals.MaxStatusTime 
    and approvals.ApproverType = latestApprovals.ApproverType
    and approvals.ApproverEmailID = latestApprovals.ApproverEmailID
    and approvals.Active = 1
inner join MasterData.PT_TMCTRY as country
    on country.CountryCode = approvals.CountryCode
inner join AdminData.PT_TMUSER as user
    on approvals.Submittedby = user.CWID
{
    key approvals.TenderID,
	key approvals.OfferId,
	key approvals.CountryCode,
	 approvals.ApprovalContent,
	 approvals.ApproverTypeSection,
	 approvals.ApprovalStatus,
	 approvals.ApproverName,
	 approvals.ApproverEmailID,
	 approvals.SenderComment,
	 approvals.ApproverComment,
	 approvals.Active,
     approvals.Hierarchy,
	 approvals.AP_ID,
	 approvals.RestoreKey,
	 approvals.Statustime,
	 approvals.Submittedby,
	 approvals.ApproverDate,
	 approvals.ApproverType,
	 approvals.FLOW_ID,
	 approvals.REQUIRED_ACTION,
     country.CountryName,
     user.UserName,
     user.UserEmail
} where approvals.ApprovalStatus <> 'Cancelled';

/* Nils: can be deleted later on... This is changed beceause when you delete an offer, the newly created offer is getting same nextofferid (only active offers are taken into account)
entity TenderOffers as select from TransactionalData.PT_TMTEND as tender{
    key tender.TenderID as TENDERID,
    max(tender.Offer.TenderOfferNo) + 1 as NEXTOFFERID:Integer
}group by tender.TenderID;
*/

@cds.persistence.exists
entity TenderOffers as select from TransactionalData.PT_TMTEND as tender 
inner join TransactionalData.PT_TMOFRS as ActiveInactiveOffers
    on ActiveInactiveOffers.TenderID = tender.TenderID {
    key tender.TenderID as TENDERID,
    max(ActiveInactiveOffers.TenderOfferNo) + 1 as NEXTOFFERID:Integer
}group by tender.TenderID;

@cds.persistence.exists
entity OfferRevisions as select from TransactionalData.PT_TMOFRS as offer{
    key offer.TenderID as TENDERID,
    key offer.TenderOfferNo as TENDEROFFERNO,
    max(offer.RevisedOfferNo) + 1 as NEXTREVISEDOFFERNO:Integer,
    max(offer.ContinuationOfferNo) + 1 as NEXTCONTINUEDOFFERNO:Integer
}group by offer.TenderID, offer.TenderOfferNo;

@cds.persistence.exists
entity CountryTenderBrands as select from TransactionalData.PT_TMTEND as tender{
    key tender.CountryCode as COUNTRYCODE,
    key tender.Offer.Product.SKU.Product.HLEVEL4_CODE as BRANDID,
    tender.Offer.Product.SKU.Product.HLEVEL4_NAME as BRANDNAME,
    //tender.Offer.Product.SKU.Product.HLEVEL6_NAME as PRODUCT_UNIT_NAME,
}where tender.Active = 1
and tender.Offer.Active = 1
and tender.Offer.Product.Active = 1
and tender.Offer.Product.SKU.ACTIVERECORD = 'Yes'
and tender.Offer.Product.SKU.Product.HLEVEL4_CODE is not null
group by tender.CountryCode, tender.Offer.Product.SKU.Product.HLEVEL4_CODE, tender.Offer.Product.SKU.Product.HLEVEL4_NAME
//tender.Offer.Product.SKU.Product.HLEVEL6_NAME
union
select from MasterData.PT_TMCTRY as country{
    country.CountryCode as COUNTRYCODE,
    'All_Brands' as BRANDID,
    ' All' as BRANDNAME
};

@cds.persistence.exists
entity CountryTenderNo as select from MasterData.PT_TMCTRY as country
left outer join TransactionalData.PT_TMTEND as tender on country.CountryCode = tender.CountryCode and (SUBSTRING(tender.TenderID, INSTR(tender.TenderID, '-', -1, 2) + 1, 2) = SUBSTRING(CURRENT_DATE, 3, 2)){
    key country.CountryCode as COUNTRY_CODE,
    ifnull(max(tender.TenderNo), 1000) + 1 as NEXT_TENDER_NO:Integer
}where country.CountryCode is not null
group by country.CountryCode;

//EFRCL- 289937- MEA-Kindly exclude Patient Access Programs and Bonus letters from the offer history section at the bottom of the Financial Offer Tab
@cds.persistence.exists
entity TenderResults as select from TransactionalData.PT_TMTEND as tender{
    tender.CountryCode as COUNTRY_CODE,
    tender.TenderID as TENDER_ID,
    key tender.Offer.OfferID as OFFER_ID,
    tender.TenderName as TENDER_NAME,
    tender.InstituteID as INSTITUTE_ID,
    tender.Institute.InstituteName as INSTITUTE_NAME,
    tender.Classification as CLASSIFICATION,
    tender.Offer.OfferStatus.STATUS as OFFERSTATUS,
    tender.Offer.SubmittedOn as OFFER_DATE,
    tender.Offer.Product.SKU.Product.HLEVEL4_CODE as BRAND_ID,
    tender.Offer.Product.SKU.Product.HLEVEL4_NAME as BRAND_NAME,
    key tender.Offer.Product.SKU.PRODUCTPACKID as PRODUCT_ID,
    tender.Offer.Product.SKU.PRODUCTPACKNAME as PRODUCT_NAME,
    tender.Offer.Product.Price.OfferPrice as PRICE,
    tender.Offer.Product.Price.COGS as COGS,
    tender.Offer.Product.Price.BudgetRate as BUDGET_RATE,
    tender.Offer.Currency as CURRENCY,
    tender.Offer.Product.RequestedVolume as QUANTITY,
    case when tender.Offer.Product.Price.FOC_ABS_PCT = 'PCT'
        then tender.Offer.Product.Price.FOC * tender.Offer.Product.RequestedVolume
        else tender.Offer.Product.Price.FOC
    end as FOC:Double,
    tender.Offer.Product.UnitPerPack as UOM,
    ifnull(tender.Offer.Product.Results.Outcome, 'NA') as OUTCOME:String(10),
    tender.Offer.Product.Price.OfferPrice *
    case when tender.Offer.Product.UnitPerPack = 'Unit'
        then tender.Offer.Product.SKU.PACKFACTOR
        else 1
    end as PACK_PRICE:Double,
    tender.Offer.Product.Price.OfferPrice *
    case when tender.Offer.Product.UnitPerPack = 'Unit'
        then 1
        else 1 / tender.Offer.Product.SKU.PACKFACTOR
    end as UNIT_PRICE:Double,
    tender.Offer.Product.Price.NetofferPrice *
    case when tender.Offer.Product.UnitPerPack = 'Unit'
        then tender.Offer.Product.SKU.PACKFACTOR
        else 1
    end as PACK_NET_PRICE:Double,
    tender.Offer.Product.Price.NetofferPrice *
    case when tender.Offer.Product.UnitPerPack = 'Unit'
        then 1
        else 1 / tender.Offer.Product.SKU.PACKFACTOR
    end as UNIT_NET_PRICE:Double,
    case when tender.Offer.Product.Price.FOC = 0
        then ''
        else
            case when tender.Offer.Product.Price.FOC_ABS_PCT = 'PCT'
                then round(100 * tender.Offer.Product.Price.FOC) || '%'
                //else round(100 * tender.Offer.Product.Price.FOC) || ' ' || tender.Offer.Product.UnitPerPack || ''
                // ETIEF modified the else condition to fix Historic offers FOC display
                else round(tender.Offer.Product.Price.FOC) || ' ' || tender.Offer.Product.UnitPerPack || ''
            end
            ||
            case when tender.Offer.Product.Price.FOCType = 'FOC 1'
                then ' included'
                else ' added'
            end
    end 
    as FOC_DESCRIPTION:String(255)
}where tender.Active = 1
and tender.Offer.Active = 1
//and tender.Offer.ActiveOffer = 1
and tender.Offer.Product.Active = 1
and (tender.Offer.Product.ActiveProduct = 1 or 
(tender.CountryCode in (select CountryCode from MasterData.PT_TMCTRY as ctry 
where ctry.Region = 'MEA') and tender.Offer.Product.ActiveProduct = 2 ))
and (tender.Offer.OfferStatusTable.STATUS = 'Quotation Submitted' or tender.Offer.OfferStatusTable.STATUS = 'Results Recorded' or tender.Offer.OfferStatusTable.STATUS = 'Delivery Ongoing' or (tender.CountryCode in (select CountryCode from MasterData.PT_TMCTRY as ctry where ctry.Region = 'MEA')
and tender.Offer.OfferStatus.STATUS in ('Offer Declined','Wholesale Offer') ));

//EHQUT-Restrict the Zero Min Price for sending Notification to Controlling
@cds.persistence.exists
entity CountryMinPrice as select from TenderResults as results{
    key results.COUNTRY_CODE,
    results.BRAND_ID,
    results.BRAND_NAME,
    key results.PRODUCT_ID,
    results.PRODUCT_NAME,
    key results.CURRENCY,
    min(results.PACK_PRICE) as MIN_PACK_PRICE:Double,
    min(results.UNIT_PRICE) as MIN_UNIT_PRICE:Double
}where UNIT_PRICE>0 and PACK_PRICE>0
group by results.COUNTRY_CODE,
    results.BRAND_ID,
    results.BRAND_NAME,
    results.PRODUCT_ID,
    results.PRODUCT_NAME,
    results.CURRENCY;
//EHQUT-Restrict the Zero Min Price for sending Notification to Controlling
@cds.persistence.exists
entity AccountMinPrice as select from MasterData.AccountPreApprovedPrices as a full outer join
TenderResults as results on results.COUNTRY_CODE = a.COUNTRY_CODE and results.INSTITUTE_ID = a.INSTITUTE_ID and results.PRODUCT_ID = a.PRODUCT_ID and results.CURRENCY = a.CURRENCY {
    key ifnull(results.COUNTRY_CODE, a.COUNTRY_CODE) as COUNTRY_CODE:String,
    key ifnull(results.INSTITUTE_ID, a.INSTITUTE_ID) as INSTITUTE_ID:String,
    results.BRAND_ID,
    results.BRAND_NAME,
    key ifnull(results.PRODUCT_ID, a.PRODUCT_ID) as PRODUCT_ID:String,
    results.PRODUCT_NAME,
    key ifnull(results.CURRENCY, a.CURRENCY) as CURRENCY:String,
    case
        when min(ifnull(results.PACK_PRICE, 0)) = 0 then min(ifnull(a.MIN_PACK_PRICE, 0))
        when min(ifnull(a.MIN_PACK_PRICE, 0)) = 0 then min(results.PACK_PRICE)
        when min(results.PACK_PRICE) < min(a.MIN_PACK_PRICE) then min(results.PACK_PRICE) else min(a.MIN_PACK_PRICE)
    end as MIN_PACK_PRICE:Double,
    case
        when min(ifnull(results.UNIT_PRICE, 0)) = 0 then min(ifnull(a.MIN_UNIT_PRICE, 0))
        when min(ifnull(a.MIN_UNIT_PRICE, 0)) = 0 then min(results.UNIT_PRICE)
        when min(results.UNIT_PRICE) < min(a.MIN_UNIT_PRICE) then min(results.UNIT_PRICE) else min(a.MIN_UNIT_PRICE)
    end as MIN_UNIT_PRICE:Double,
    case
        when min(ifnull(results.PACK_NET_PRICE, 0)) = 0 then min(ifnull(a.MIN_PACK_NET_PRICE, 0))
        when min(ifnull(a.MIN_PACK_NET_PRICE, 0)) = 0 then min(results.PACK_NET_PRICE)
        when min(results.PACK_NET_PRICE) < min(a.MIN_PACK_NET_PRICE) then min(results.PACK_NET_PRICE) else min(a.MIN_PACK_NET_PRICE)
    end as MIN_PACK_NET_PRICE:Double,
    case
        when min(ifnull(results.UNIT_NET_PRICE, 0)) = 0 then min(ifnull(a.MIN_UNIT_NET_PRICE, 0))
        when min(ifnull(a.MIN_UNIT_NET_PRICE, 0)) = 0 then min(results.UNIT_NET_PRICE)
        when min(results.UNIT_NET_PRICE) < min(a.MIN_UNIT_NET_PRICE) then min(results.UNIT_NET_PRICE) else min(a.MIN_UNIT_NET_PRICE)
    end as MIN_UNIT_NET_PRICE:Double,
}group by results.COUNTRY_CODE,
    a.COUNTRY_CODE,
    results.INSTITUTE_ID,
    a.INSTITUTE_ID,
    results.BRAND_ID,
    results.BRAND_NAME,
    results.PRODUCT_ID,
    a.PRODUCT_ID,
    results.PRODUCT_NAME,
    results.CURRENCY,
    a.CURRENCY;

@cds.persistence.exists
entity PreviousApprovalTemp as select from TransactionalData.PT_TMAPPRST as approvals
inner join LatestApprovalRequests as latestApprovals
    on approvals.OfferId = latestApprovals.OfferId 
    and approvals.Statustime = latestApprovals.MaxStatusTime 
    and approvals.ApproverType = latestApprovals.ApproverType
    and approvals.ApproverEmailID = latestApprovals.ApproverEmailID
    and approvals.Active = 1
{
   approvals.OfferId as OFFER_ID,
   approvals.productcode as PRODUCT_ID,
   case when
    max(ifnull(approvals.OfferProduct.SUPPLY_UPDATE, 0)) < max(approvals.OfferProduct.Offer.APPROVALS_SENT) and
    max(ifnull(approvals.OfferProduct.PAYMENT_UPDATE, 0)) < max(approvals.OfferProduct.Offer.APPROVALS_SENT) and
    max(ifnull(approvals.OfferProduct.Price.PRICE_UPDATE, 0)) < max(approvals.OfferProduct.Offer.APPROVALS_SENT)
    then 0 else 1 end
   as NEW_APPROVAL:Integer,
   max(
       case when
        approvals.ApproverType = 'Supply Chain' and
        approvals.ApprovalStatus = 'Approved' and
        approvals.OfferProduct.SUPPLY_UPDATE < approvals.OfferProduct.Offer.APPROVALS_SENT
        then 1 else 0 end
   ) 
   as SUPPLY_APPROVED:Integer,
   max(
       case when
        (approvals.ApproverType = 'Country Business' or approvals.ApproverType = 'Regional Business') and
        (approvals.ApprovalStatus = 'Waiting' or approvals.ApprovalStatus = 'Processing')
        then 1 else 0 end
   ) 
   as PENDING_BUSINESS:Integer,
   max(
       case when
        (approvals.ApproverType = 'Country Business' or approvals.ApproverType = 'Regional Business') and
        approvals.ApprovalStatus = 'Approved' and
        approvals.OfferProduct.PAYMENT_UPDATE < approvals.OfferProduct.Offer.APPROVALS_SENT and
        approvals.OfferProduct.Price.PRICE_UPDATE < approvals.OfferProduct.Offer.APPROVALS_SENT
        then 1 else 0 end
   )
   as BUSINESS_APPROVED:Integer,
   max(
       case when
        approvals.ApproverType = 'Country Business' and
        approvals.ApprovalStatus = 'Approved' and
        approvals.OfferProduct.PAYMENT_UPDATE < approvals.OfferProduct.Offer.APPROVALS_SENT and
        approvals.OfferProduct.Price.PRICE_UPDATE < approvals.OfferProduct.Offer.APPROVALS_SENT
        then 1 else 0 end
   ) 
   as COUNTRY_BUSINESS_APPROVED:Integer,
   max(
       case when
        approvals.ApproverType = 'Regional Business' and
        approvals.ApprovalStatus = 'Approved' and
        approvals.OfferProduct.PAYMENT_UPDATE < approvals.OfferProduct.Offer.APPROVALS_SENT and
        approvals.OfferProduct.Price.PRICE_UPDATE < approvals.OfferProduct.Offer.APPROVALS_SENT
        then 1 else 0 end
   ) 
   as REGIONAL_BUSINESS_APPROVED:Integer,
   max(
       case when
        approvals.ApproverType = 'Legal' and
        approvals.ApprovalStatus = 'Approved' and
        approvals.OfferProduct.Price.PRICE_UPDATE < approvals.OfferProduct.Offer.APPROVALS_SENT
        then 1 else 0 end
   ) 
   as LEGAL_APPROVED:Integer,
   max(
       case when
        approvals.ApproverType = 'Regulatory' and
        approvals.ApprovalStatus = 'Approved' and
        approvals.OfferProduct.Price.PRICE_UPDATE < approvals.OfferProduct.Offer.APPROVALS_SENT
        then 1 else 0 end
   ) 
   as REGULATORY_APPROVED:Integer
}group by approvals.OfferId, approvals.productcode;

@cds.persistence.exists
entity PreviousApproval as select from PreviousApprovalTemp as temp{
    key temp.OFFER_ID,
    key temp.PRODUCT_ID,
    temp.NEW_APPROVAL,
    temp.SUPPLY_APPROVED,
    temp.REGIONAL_BUSINESS_APPROVED,
    temp.COUNTRY_BUSINESS_APPROVED,
    case when temp.PENDING_BUSINESS = 1 then 0 else temp.BUSINESS_APPROVED end as BUSINESS_APPROVED:Integer,
    temp.LEGAL_APPROVED,
    case when temp.BUSINESS_APPROVED = 1 then 1 else temp.REGULATORY_APPROVED end as REGULATORY_APPROVED:Integer
};

@cds.persistence.exists
entity InstituteMap as select from MasterData.PT_TMINST as institute{
    institute.InstituteID as PARENT_ID,
    institute.InstituteID as CHILD_ID
}where institute.ActiveRecord = 'Yes'
union
select from MasterData.PT_TMINSHIER as hierarchy{
    hierarchy.ParentInstituteID as PARENT_ID,
    hierarchy.InstituteID as CHILD_ID
}where hierarchy.ActiveRecord = 'Yes';

//EFRCL- 289937- MEA-Kindly exclude Patient Access Programs and Bonus letters from the offer history section at the bottom of the Financial Offer Tab
@cds.persistence.exists
entity TenderHistory as select from TenderResults as results
inner join InstituteMap as institute on results.INSTITUTE_ID = institute.CHILD_ID{
    results.COUNTRY_CODE,
    results.TENDER_ID,
    key results.OFFER_ID,
    results.TENDER_NAME,
    key results.INSTITUTE_ID,
    results.INSTITUTE_NAME,
    results.OFFER_DATE,
    results.BRAND_ID,
    results.BRAND_NAME,
    key results.PRODUCT_ID,
    results.PRODUCT_NAME,
    results.UNIT_PRICE,
    results.PACK_PRICE,
    results.UNIT_NET_PRICE,
    results.PACK_NET_PRICE,
    results.COGS,
    results.BUDGET_RATE,
    results.CURRENCY,
    results.QUANTITY,
    results.FOC_DESCRIPTION as FOC:String(255),
    results.UOM,
    results.OUTCOME,
    results.OFFERSTATUS,
    key max(institute.PARENT_ID) as PARENT_ID:Integer
} where results.CLASSIFICATION is null or results.CLASSIFICATION not in
(case when results.COUNTRY_CODE in (select CountryCode from MasterData.PT_TMCTRY as ctry where ctry.Region = 'MEA') and results.CLASSIFICATION in ('Patient Access Programme','Bonus Letters')then results.CLASSIFICATION else 'CLASSIFICATION' end)
group by results.COUNTRY_CODE,
           results.TENDER_ID,
           results.OFFER_ID,
           results.TENDER_NAME,
            results.INSTITUTE_ID,
            results.INSTITUTE_NAME,
            results.OFFER_DATE,
            results.BRAND_ID,
            results.BRAND_NAME,
            results.PRODUCT_ID,
            results.PRODUCT_NAME,
            results.UNIT_PRICE,
            results.PACK_PRICE,
            results.UNIT_NET_PRICE,
            results.PACK_NET_PRICE,
            results.COGS,
            results.BUDGET_RATE,
            results.CURRENCY,
            results.QUANTITY,
            results.FOC_DESCRIPTION,
            results.UOM,
            results.OUTCOME,
            results.OFFERSTATUS;

@cds.persistence.exists
entity ResultsWithNegotiation as select OfferID, ProductCode from TransactionalData.PT_TMTRRES where Active = 1 and Outcome = 'FOC negotiation';

@cds.persistence.exists
entity ResultsWithAppealInProgress as select TenderID, OfferID, ProductCode from TransactionalData.PT_TMTRRES where Active = 1 and Outcome = 'Appeal in Progress';

@cds.persistence.exists
entity OfferStatus as select from TransactionalData.PT_TMOFRS as offer{
    key offer.OfferID as OFFER_ID,
    case
        when offer.WholesaleOffer = 'Yes'
            then 'Wholesale Offer'

        when count(offer.Product.ActiveProduct)<>0 and sum(case when offer.Product.ActiveProduct <> 1 and (offer.Product.Channel = 'Decline' or offer.Product.Channel = 'Bayer' or offer.Product.Channel = 'Distributor' or offer.Product.Channel is NULL or offer.Product.Channel ='') then 1 else 0 end) = count(offer.Product.ActiveProduct)
            then 'Offer Declined'
        when offer.OfferStatusTable.STATUS = 'Offer Created'
        or offer.OfferStatusTable.STATUS = 'Awaiting Approval'
        or offer.OfferStatusTable.STATUS = 'Offer Approved'
        or offer.OfferStatusTable.STATUS = 'Offer Declined'
        or offer.OfferStatusTable.STATUS = 'Quotation Created'
            then
                case
                    when max(offer.Product.PreviousApproval.NEW_APPROVAL) <> 0 then 'Offer Created'
                    when sum(case when offer.Product.ApprovalStatus.ApprovalStatus = 'Rejected' then 1 else 0 end) <> 0 then 'Offer Rejected'
                    when sum(case when offer.Product.ApprovalStatus.ApprovalStatus = 'Waiting' or offer.Product.ApprovalStatus.ApprovalStatus = 'Processing' then 1 else 0 end) <> 0 then 'Awaiting Approval'
                    when sum(case when
                                (offer.Product.ApprovalStatus.ApprovalStatus = 'Cancelled' or offer.Product.ApprovalStatus.ApprovalStatus = 'Cancelling' or offer.Product.ApprovalStatus.ApprovalStatus = 'Not Sent')
                                and offer.Product.ApprovalStatus.ApproverTypeSection = 1
                            then 1 else 0 end) <> 0 then 'Offer Created'
                    when count(offer.Product.ApprovalStatus.ApprovalStatus) = 0 then 'Offer Created'
                    else 'Offer Approved'
                end
        when offer.OfferStatusTable.STATUS = 'Results Recorded'
            then 
                case 
                    when exists (select * from ResultsWithNegotiation where OfferID = offer.OfferID) then 'In FOC Negotiation'
                    when exists (select * from ResultsWithAppealInProgress where OfferID = offer.OfferID) then 'Appeal in Progress'
                    when (offer.OfferStatusTable.CountryCode = 'NL' or offer.OfferStatusTable.CountryCode = 'PL') and offer.OfferStatusTable.TableStatus is not null then offer.OfferStatusTable.TableStatus
                    else offer.OfferStatusTable.STATUS 
            end
        else offer.OfferStatusTable.STATUS 
    end as STATUS:String(255)
}where offer.OfferStatusTable.Active = 1
group by offer.OfferID, offer.WholesaleOffer, offer.OfferStatusTable.STATUS, offer.OfferStatusTable.CountryCode, offer.OfferStatusTable.TableStatus; //group by missing?

@cds.persistence.exists
entity OfferValues as select from TransactionalData.PT_TMOFRS as offer{
    offer.TenderID as TENDER_ID,
    key offer.OfferID as OFFER_ID,
    offer.InternalBidDueDate as INTERNAL_BID_DUE_DATE,
    offer.OfferStatusTable.STATUS,

    sum(
        offer.Product.Price.OfferPrice * (1 - ifnull(offer.Product.Price.Deductions, 0)) *
        case when offer.Product.Price.FOCType = 'FOC 1'
            then
                case when offer.Product.Price.FOC_ABS_PCT = 'PCT'
                    then round(offer.Product.RequestedVolume * (1 - offer.Product.Price.FOC))
                        when offer.Product.Price.FOC_ABS_PCT = 'STP'
                            then floor(offer.Product.RequestedVolume / offer.Product.Price.FOCStep) * offer.Product.Price.FOC
                    else offer.Product.RequestedVolume - offer.Product.Price.FOC
                end
            else offer.Product.RequestedVolume
        end
    ) as VALUE:Double,
    offer.Currency as CURRENCY,
    offer.ActiveOffer as ACTIVE_OFFER,
    offer.NewOfferDueDate as NEW_OFFER_DUE_DATE,
    case when offer.RevisedOfferNo <> 0 then 1 else 0 end as IS_REVISION:Integer,
    case when offer.OfferStatusTable.STATUS = 'Quotation Submitted' or offer.OfferStatusTable.STATUS = 'Results Recorded' or offer.OfferStatusTable.STATUS = 'Delivery Ongoing'
        then
            case when offer.SubmissionDate is null or offer.SubmissionDate = ''
                then case when offer.Quotation.SubmittedOn is null or offer.Quotation.SubmittedOn = '' then '' else offer.Quotation.SubmittedOn end
                else offer.SubmissionDate
            end
        else ''
    end as SUBMISSION_DATE:Date,
    ifnull(offer.Distributor.DistributorName, 'Not Specified') as DISTRIBUTOR:String(255)
}where offer.Active = 1
and (offer.Product.Active = 1 or offer.Product.Active is null)
and (offer.Product.Price.Active = 1 or offer.Product.Price.Active is null)
and (offer.Product.ActiveProduct = 1)
group by
    offer.TenderID, 
    offer.OfferID, 
    offer.InternalBidDueDate, 
    offer.Currency, 
    offer.WholesaleOffer,
    offer.ActiveOffer,
    offer.NewOfferDueDate,
    offer.RevisedOfferNo,
    offer.SubmissionDate,
    offer.OfferStatusTable.STATUS,
    offer.Quotation.SubmittedOn,
    offer.Distributor.DistributorName;

@cds.persistence.exists
entity BrandsInTender as select from TransactionalData.PT_TMTEND as tender{
    tender.CountryCode as COUNTRYCODE,
    key tender.TenderID as TENDERID,
    key tender.Offer.Product.SKU.Product.HLEVEL4_CODE as BRANDID,
    key tender.Offer.OfferID as OFFERID,
    tender.Offer.Product.SKU.Product.HLEVEL4_NAME as BRANDNAME
}
where tender.Active = 1
and tender.Offer.Active = 1
and tender.Offer.Product.Active = 1;
//EHQUT-397790-Italy-Search function is slow and system crashes
//EHQUT-189207-Creation Date instead of BidDueDate on main page
//EHQUT-197392-MEA - additional edit access to Tender Results and Delivery Tracking tabs
//EFRCL-283873- Italy replace Publication date with Termination date
@cds.persistence.exists
entity TenderOfferMaster as select from TransactionalData.PT_TMTEND as tender{
    tender.CountryCode as COUNTRY,
    key tender.TenderID as TENDER_ID,
    tender.Classification as CLASSIFICATION,
    tender.TenderName as TENDER_NAME,
    tender.Institute.Region.ID as REGION_ID,
    tender.Institute.InstituteName as INSTITUTE,
    tender.Brands as BRAND,
    tender.Offer.Division as DIVISION,
    key ifnull(tender.Offer.OfferID, '') as OFFER_ID:String(30),
    tender.Offer.OfferValue.VALUE as VALUE:Double,
    tender.Offer.Currency as CURRENCY,
    ifnull(tender.Offer.OfferStatus.STATUS, 'Offer Created') as STATUS:String(255),
    tender.PublicationDate as PUBLICATION_DATE,
    tender.TerminationDate as TERMINATION_DATE,
    case when tender.CountryCode = 'IT' then tender.createdAt else tender.SubmittedOn end as CREATION_DATE:Date, 
    tender.Offer.InternalBidDueDate as INTERNAL_BID_DUE_DATE,
    case when tender.Offer.RevisedOfferNo = 0 and tender.Offer.ContinuationOfferNo = 0 then tender.BidDueDate else tender.Offer.NewOfferDueDate end as CLOSING_DATE:Date,
    ifnull(tender.Offer.ActiveOffer, 1) as ACTIVE_OFFER:Integer,
    ifnull(tender.Offer.PfiNumber.PFINo, '') as PFI_NO:String(255),
    ifnull(tender.Origin.CODE, 'NA') as ORIGIN_CODE:String(10),
    tender.Offer.InternalBidDueDate as OFFER_DATE,
    tender.Offer.Distributor.DistributorName as DISTRIBUTOR,
    tender.Offer.OfferValue.SUBMISSION_DATE as SUBMISSION_DATE,
    tender.CountrySpecificInformation.TenderReference as TENDER_REFERENCE,
    tender.ExternalID as EXTERNAL_ID,
    tender.SAPID as SAP_ID,
    tender.User.UserName,
    tender.Offer.IbizWorkflowID
}where tender.Active = 1
and ifnull(Offer.Active, 1) = 1;

@cds.persistence.exists
entity OfferProductPlus as select from TransactionalData.PT_TMOFPR as offerProduct{
    *,
    offerProduct.SKU.Product.HLEVEL4_CODE as HLEVEL4_CODE,
    offerProduct.Offer.Currency as CURRENCY,
    offerProduct.Offer.Tender.TenderChannel as TENDER_CHANNEL,
    offerProduct.Offer.DistributorID as DISTRIBUTOR_ID,
    offerProduct.Offer.Tender.InstituteID as INSTITUTE_ID
};

@cds.persistence.exists
entity OfferSignatory1 as select from TransactionalData.PT_TMOFRS as offer
inner join ApprovalRequests as approvalRequest
    on  approvalRequest.TenderID = offer.TenderID
	and approvalRequest.OfferId = offer.OfferID
	and approvalRequest.CountryCode = offer.CountryCode
    and approvalRequest.ApprovalStatus <> 'Cancelling'
    and approvalRequest.ApprovalStatus <> 'Rejected'
inner join MasterData.COUNTRY_LEGAL_ENTITY_SIGNATORIES as signatory
    on offer.SellingCompany = signatory.LEGAL_ENTITY_CODE
    and offer.CountryCode = signatory.COUNTRY_CODE
    and signatory.SIGNATORY = 1
    and (signatory.DIVISION = offer.Division or signatory.DIVISION = 'Both')
    and approvalRequest.ApproverName = signatory.NAME
left outer join TransactionalData.PT_TMQUTO as quotation
    on offer.OfferID = quotation.OfferID
    and quotation.AS1 = signatory.AUTHORIZED_SIGNATORY
{
    offer.OfferID,
    ifnull(quotation.AS1, signatory.AUTHORIZED_SIGNATORY) as AUTHORIZED_SIGNATORY:String,
    ifnull(quotation.Signatory1.NAME, signatory.NAME) as NAME:String,
    ifnull(quotation.Signatory1.TITLE, signatory.TITLE) as TITLE:String
};

@cds.persistence.exists
entity OfferSignatory2 as select from TransactionalData.PT_TMOFRS as offer
inner join ApprovalRequests as approvalRequest
    on  approvalRequest.TenderID = offer.TenderID
	and approvalRequest.OfferId = offer.OfferID
	and approvalRequest.CountryCode = offer.CountryCode
    and approvalRequest.ApprovalStatus <> 'Cancelling'
    and approvalRequest.ApprovalStatus <> 'Rejected'
inner join MasterData.COUNTRY_LEGAL_ENTITY_SIGNATORIES as signatory
    on offer.SellingCompany = signatory.LEGAL_ENTITY_CODE
    and offer.CountryCode = signatory.COUNTRY_CODE
    and signatory.SIGNATORY = 2
    and (signatory.DIVISION = offer.Division or signatory.DIVISION = 'Both')
    and approvalRequest.ApproverName = signatory.NAME
left outer join TransactionalData.PT_TMQUTO as quotation
    on offer.OfferID = quotation.OfferID
    and quotation.AS2 = signatory.AUTHORIZED_SIGNATORY
{
    offer.OfferID,
    ifnull(quotation.AS2, signatory.AUTHORIZED_SIGNATORY) as AUTHORIZED_SIGNATORY:String,
    ifnull(quotation.Signatory2.NAME, signatory.NAME) as NAME:String,
    ifnull(quotation.Signatory2.TITLE, signatory.TITLE) as TITLE:String
};

//EHQUT-RITM12706398-OfferValidity for SEWA
@cds.persistence.exists
entity OfferConsolidation as select from TransactionalData.PT_TMOFRS as offer
left outer join MasterData.COUNTRY_LEGAL_ENTITY_SIGNATORIES as signatory1Default
    on offer.SellingCompany = signatory1Default.LEGAL_ENTITY_CODE
    and offer.CountryCode = signatory1Default.COUNTRY_CODE
    and signatory1Default.SORTER = 1
left outer join MasterData.COUNTRY_LEGAL_ENTITY_SIGNATORIES as signatory2Default
    on offer.SellingCompany = signatory2Default.LEGAL_ENTITY_CODE
    and offer.CountryCode = signatory2Default.COUNTRY_CODE
    and signatory2Default.SORTER = 2
left outer join OfferSignatory1 as signatory1
    on offer.OfferID = signatory1.OfferID
left outer join OfferSignatory2 as signatory2
    on offer.OfferID = signatory2.OfferID
left outer join AdminData.NextDateSettings as date_settings
    on MONTH(CURRENT_DATE) = date_settings.CurrentMonth
left outer join TransactionalDataViews.ApprovalRequests as approvalRequests
    on offer.OfferID = approvalRequests.OfferId
{	
	'PT_TMTNOFST(TENDERID=''' || offer.TenderID || ''',OFFERID=''' || offer.OfferID || ''',Active=1)' as OFFERSTATUSPATH:String(500),
	offer.TenderID as TENDERID,
    offer.Tender.InstituteID as INSTITUTE_ID,
    offer.Tender.Institute.InstituteType as INSTITUTE_TYPE,
    offer.Tender.Institute.State as INSTITUTE_STATE,
    offer.Tender.Institute.Address as INSTITUTE_ADDRESS,
    offer.Tender.Classification as CLASSIFICATION,//Added Classification (db#1)
    offer.Tender.Institute.CustomerID as CUSTOMER_CODE,
    case when offer.Tender.TenderChannel<>'Direct' then 'Distributor' else 'Direct' end as TENDER_CHANNEL:String(500),
	offer.Tender.TenderName as TENDER_REFERENCE:String(500),
	key offer.OfferID as OFFERID,
    offer.QuotationInstituteID as QUOTATIONINSTITUTEID,
    offer.Tender.Institute.InstituteName as INSTITUTENAME,
    offer.Tender.Institute.External_InstituteId as EXTERNAL_INSTITUTEID,
    offer.Tender.Institute.City as INSTITUTECITY,
    offer.Tender.Institute.VatCode as VATCODE,
    offer.Tender.Institute.TaxCode as TAXCODE,
    offer.Tender.Institute.Region.Name as REGION_NAME,
    offer.Tender.Institute.Province.Name as PROVINCE_NAME,
    offer.Tender.Institute.CifCode as CIF_CODE,
    offer.Tender.Institute.RegionalHealthSystem as REGIONAL_HEALTH_SYSTEM,
    offer.Tender.Institute.CustomerGroup as CUSTOMER_GROUP,
    offer.OfferStatus.STATUS as STATUS,
    offer.Tender.Country.ApprovalType as APPROVAL_TYPE,
	ifnull(offer.Quotation.OfferDate, CURRENT_DATE) as OFFERDATE,

	  case
        when offer.Tender.Institute.Region.Name = 'SEWA' then ADD_DAYS(CURRENT_DATE, 60)
        when (offer.CountryCode = 'ES'  and offer.Tender.Classification = 'Commercial Agreement')
          then ifnull(offer.Quotation.OfferValidity,ADD_MONTHS(CURRENT_DATE,1))
        when offer.CountryCode = 'IT'
           then ifnull(offer.Quotation.OfferValidity, ifnull(offer.Tender.OfferValidity, TO_DATE(TO_NVARCHAR(YEAR(ADD_YEARS(CURRENT_DATE, date_settings.NextYearDelta))) || '-' || TO_NVARCHAR(date_settings.NextMonth) || '-' ||TO_NVARCHAR(date_settings.NextDay))))
        when offer.CountryCode = 'TH'
            then
                case
                    when offer.Quotation.OfferValidity is null 
                        then
                            case
                                when offer.Tender.Custom.String_5 = 'Days'
                                    then  ADD_DAYS(CURRENT_DATE, offer.Tender.ContractLength)
                                when offer.Tender.Custom.String_5 = 'Months'
                                    then  ADD_MONTHS(CURRENT_DATE, offer.Tender.ContractLength)
                                when offer.Tender.Custom.String_5 = 'Years'
                                    then  ADD_YEARS(CURRENT_DATE, offer.Tender.ContractLength)
                            end
                    else offer.Quotation.OfferValidity
                end
       else ifnull(offer.Quotation.OfferValidity, TO_DATE(TO_NVARCHAR(YEAR(ADD_YEARS(CURRENT_DATE, date_settings.NextYearDelta))) || '-' || TO_NVARCHAR(date_settings.NextMonth) || '-' ||TO_NVARCHAR(date_settings.NextDay)))
    end as OFFERVALIDITY,

	case 
        when offer.CountryCode = 'TW'
            then ifnull(offer.Quotation.EffectiveDate, offer.Tender.PublicationDate)
        when offer.CountryCode NOT IN ('ES')
            then ifnull(offer.Quotation.EffectiveDate, ADD_DAYS(CURRENT_DATE,1))
        else ifnull(offer.Tender.EffectiveDate,ifnull(offer.Quotation.EffectiveDate,ADD_DAYS(CURRENT_DATE,1)))
    end as EffectiveDate,

	 case when offer.CountryCode NOT IN ('ES')


        then ifnull(offer.Quotation.ExpiryDate, ADD_DAYS(ADD_YEARS(CURRENT_DATE, 1), 1))

        else ifnull(offer.Tender.ExpiryDate,ifnull(offer.Quotation.ExpiryDate,ADD_DAYS(ADD_YEARS(CURRENT_DATE, 1), 1)))

    end as ExpiryDate,

	offer.CountryCode as COUNTRYCODE,
	offer.SellingCompanyDetails.LegalEntityName as SELLINGCOMPANY,
    offer.SellingCompanyDetails.BankDetails as SELLINGCOMPANYBANK,
    ifnull(ifnull(offer.Quotation.AS1, signatory1.AUTHORIZED_SIGNATORY), signatory1Default.AUTHORIZED_SIGNATORY) as SELLING_COMPANY_AS1:String(500),
	ifnull(ifnull(offer.Quotation.AS2, signatory2.AUTHORIZED_SIGNATORY), signatory2Default.AUTHORIZED_SIGNATORY) as SELLING_COMPANY_AS2:String(500),

    ifnull(ifnull(offer.Quotation.Signatory1.NAME, signatory1.NAME), signatory1Default.NAME) as SELLING_COMPANY_AS1_NAMEI:String(500),
	ifnull(ifnull(offer.Quotation.Signatory2.NAME, signatory2.NAME), signatory2Default.NAME) as SELLING_COMPANY_AS2_NAMEI:String(500),

    ifnull(ifnull(offer.Quotation.Signatory1.TITLE, signatory1.TITLE), signatory1Default.TITLE) as SELLING_COMPANY_AS1_TITLEI:String(500),
	ifnull(ifnull(offer.Quotation.Signatory2.TITLE, signatory2.TITLE), signatory2Default.TITLE) as SELLING_COMPANY_AS2_TITLEI:String(500),



    //ifnull(signatory1.NAME, signatory1Default.NAME) as SELLING_COMPANY_AS1_NAMEI:String(500),
    //ifnull(signatory1.TITLE, signatory1Default.TITLE) as SELLING_COMPANY_AS1_TITLEI:String(500),
    //ifnull(signatory2.NAME, signatory2Default.NAME) as SELLING_COMPANY_AS2_NAMEI:String(500),
    //ifnull(signatory2.TITLE, signatory2Default.TITLE) as SELLING_COMPANY_AS2_TITLEI:String(500),
    case 
        when signatory1.AUTHORIZED_SIGNATORY is null then false
        when signatory1.AUTHORIZED_SIGNATORY = ifnull(ifnull(offer.Quotation.AS1, signatory1.AUTHORIZED_SIGNATORY), signatory1Default.AUTHORIZED_SIGNATORY) then true
        else false
    end as E_SIGNATURE1:Boolean,
    case 
        when signatory2.AUTHORIZED_SIGNATORY is null then false 
        when signatory2.AUTHORIZED_SIGNATORY = ifnull(ifnull(offer.Quotation.AS2, signatory2.AUTHORIZED_SIGNATORY), signatory2Default.AUTHORIZED_SIGNATORY) then true
        else false
    end as E_SIGNATURE2:Boolean,
	offer.Currency as CURRENCY,
    min(offer.Product.Price.BudgetRate) as BUDGET_RATE,
    min(offer.Product.Price.SpotRate) as SPOT_RATE,
    //EITOG-SCTASK0100482/REQ11565210-Increase the size of Letterhead
    ifnull(offer.SellingCompanyDetails.Letterhead, '') as LETTERHEAD:String(700),
     //EITOG-SCTASK0100482/REQ11565210-Increase the size of Letterhead
    ifnull(offer.SellingCompanyDetails.Remarks, '') as SELLING_COMPANY_REMARKS:String(500),
    ifnull(offer.SellingCompanyDetails.FooterComment, '') as SELLING_COMPANY_FOOTER:String(500),
	case offer.Tender.TenderChannel
        when 'Direct' then offer.Tender.Institute.InstituteName
        else offer.Distributor.DistributorName
    end as DISTRIBUTORNAME,
    offer.Distributor.DistributorID as DISTRIBUTOR_ID,
	case offer.Tender.TenderChannel
        when 'Direct' then offer.Tender.Institute.Address
        else offer.Distributor.Address
    end as DISTRIBUTORADDRESS:String(500),
	case offer.Tender.TenderChannel
        when 'Direct' then offer.Tender.Institute.ContactNo
        else offer.Distributor.ContactNo
    end as DISTRIBUTORPHONE:String(500),
	case offer.Tender.TenderChannel
        when 'Direct' then offer.Tender.Institute.Fax
        else offer.Distributor.Fax
    end as DISTRIBUTORFAX:String(500),
	case offer.Tender.TenderChannel
        when 'Direct' then offer.Tender.Institute.ContactPerson
        else offer.Distributor.ContactPerson
    end as DISTRIBUTORCONTACT:String(500),
    case offer.Tender.TenderChannel
        when 'Direct' then '' // TODO: check this with Jonathan -> what field to use in case of Direct tender
        else offer.Distributor.CONTACT_EMAIL
    end as DISTRIBUTOREMAIL:String(500),
	ifnull(offer.Quotation.Comment, '') as CUSTOM_REMARKS:String(500),
    offer.FOCType as FOC_TYPE,
    ifnull(offer.Country.COMMENT, '') as COUNTRY_COMMENT,
    offer.Tender.PublicationDate as PUBLICATION_DATE,
    offer.Tender.BidDueDate as BID_DUE_DATE,
    offer.Quotation.SubmittedBy as TENDER_SUBMITTED_BY,
    offer.Custom.String_1 as PaymentTerms,
    offer.Custom.String_2 as DeliveryTerms,
    offer.Custom.String_3 as ShipmentTerms,
    offer.AffiliateOffer,
    offer.Tender.Custom.String_1 as TENDERCONTACT,
    offer.Tender.TenderChannel,
    offer.Tender.ContractLength,
    offer.Tender.ContractExtenseion,
    offer.Tender.Custom.Integer_1 as NumberOfExtension,
    offer.Comment as ClientComment,
    offer.Tender.Custom.String_2 as Regions,
    offer.Tender.Country.Region,
    offer.InternalBidDueDate,
    offer.Tender.Custom.Integer_2 as Contract_Length2,
    offer.Tender.Custom.Integer_3 as Contract_Length3
}where offer.Active = 1 and offer.Tender.Active = 1
 group by offer.TenderID,
          offer.OfferID,
          offer.QuotationInstituteID,
          offer.Tender.TenderChannel,
          offer.Tender.InstituteID,
          offer.Tender.Institute.InstituteType,
          offer.Tender.Institute.State,
          offer.Tender.Institute.Address,
          offer.Tender.Classification,
          offer.Tender.TenderChannel,
          offer.Tender.Institute.InstituteName,
          offer.Tender.Institute.External_InstituteId,
          offer.Tender.Institute.City,
          offer.Tender.Institute.VatCode,
          offer.Tender.Institute.TaxCode,
          offer.Tender.Institute.Region.Name,
          offer.Tender.Institute.Province.Name,
          offer.Tender.Institute.CifCode,
          offer.Tender.Institute.RegionalHealthSystem,
          offer.Tender.Institute.CustomerGroup,
          offer.Tender.EffectiveDate,
          offer.Tender.ExpiryDate,
          offer.Tender.OfferValidity,
          offer.Tender.Institute.CustomerID,
          offer.Tender.TenderName,
          offer.OfferStatus.STATUS,
          offer.Tender.Country.ApprovalType,
          offer.Quotation.OfferDate,
          offer.Quotation.OfferValidity,
          offer.Quotation.EffectiveDate,
          offer.Quotation.ExpiryDate,
          offer.Quotation.Signatory1.NAME,
          offer.Quotation.Signatory2.NAME,
          offer.Quotation.Signatory1.TITLE,
          offer.Quotation.Signatory2.TITLE,
          offer.CountryCode,
          offer.SellingCompanyDetails.LegalEntityName,
          offer.SellingCompanyDetails.BankDetails,
          offer.Quotation.AS1,
          signatory1.AUTHORIZED_SIGNATORY,
          signatory1.NAME,
          signatory1.TITLE,
          signatory1Default.AUTHORIZED_SIGNATORY,
          signatory1Default.NAME,
          signatory1Default.TITLE,
          offer.Quotation.AS2,
          signatory2.AUTHORIZED_SIGNATORY,
          signatory2.NAME,
          signatory2.TITLE,
          signatory2Default.AUTHORIZED_SIGNATORY,
          signatory2Default.NAME,
          signatory2Default.TITLE,
          offer.Currency,
          offer.SellingCompanyDetails.Letterhead,
          offer.SellingCompanyDetails.Remarks,
          offer.SellingCompanyDetails.FooterComment,
          offer.Distributor.DistributorName,
          offer.Distributor.DistributorID,
          offer.Tender.Institute.Address,
          offer.Distributor.Address,
          offer.Tender.Institute.ContactNo,
          offer.Distributor.ContactNo,
          offer.Tender.Institute.Fax,
          offer.Distributor.Fax,
          offer.Tender.Institute.ContactPerson,
          offer.Distributor.ContactPerson,
          offer.Distributor.CONTACT_EMAIL,
          offer.Quotation.Comment,
          offer.FOCType,
          offer.Country.COMMENT,
          offer.Tender.PublicationDate,
          offer.Tender.BidDueDate,
          offer.Quotation.SubmittedBy,
          offer.Custom.String_1,
          offer.Custom.String_2,
          offer.Custom.String_3,
          offer.Tender.Custom.String_1,
          date_settings.NextYearDelta,
          date_settings.NextDay,
          date_settings.NextMonth,
          offer.AffiliateOffer,
          offer.Tender.ContractLength,
          offer.Tender.ContractExtenseion,
          offer.Tender.Custom.Integer_1,
          offer.Tender.Custom.Integer_2,
          offer.Tender.Custom.Integer_3,
          offer.Comment,
          offer.Tender.Custom.String_2,
          offer.Tender.Country.Region,
          offer.InternalBidDueDate,
          offer.Tender.Custom.String_5;

@cds.persistence.exists
entity QuotationUpdates as select from TransactionalData.PT_TMQUTO as quotation
inner join TransactionalDataViews.OfferStatus as status on quotation.OfferID = status.OFFER_ID{
    key 'PT_TMQUTO(OfferID=''' || quotation.OfferID || ''',Active=1,OfferDate=' || quotation.OfferDate || ')' as QUOTATION_PATH:String(500),
    quotation.CountryCode as COUNTRY_CODE,
    quotation.TenderID as TENDER_ID,
    quotation.OfferID as OFFER_ID,
    quotation.OfferDate as OFFER_DATE,
    quotation.OfferValidity as OFFER_VALIDITY,
    quotation.Comment as COMMENT,
    quotation.AS1 as APPROVER1,
    quotation.AS2 as APPROVER2,
}where quotation.UPDATED <> 1
and status.STATUS='Offer Approved'
and quotation.Active = 1;

@cds.persistence.exists
entity TenderRappelView as select from TransactionalData.PT_TMTEND as tender 
inner join TransactionalData.PT_TMOFRS as offer 
    on offer.TenderID = tender.TenderID
    and offer.Active = 1
inner join TransactionalData.PT_TMOFPR as product 
    on product.OfferID = offer.OfferID
    and product.Active = 1
    and product.ActiveProduct = 1 
inner join MasterData.PT_TMPRDPCK as productPacks
    on productPacks.PRODUCTPACKID = product.ProductCode
    and productPacks.ACTIVERECORD = 'Yes' 
left outer join TransactionalData.PriceConditionClassification as priceConditionClassification  
    on priceConditionClassification.CountryCode = product.CountryCode
    and priceConditionClassification.Classification = tender.Classification
    and priceConditionClassification.Division = offer.Division 
    and (priceConditionClassification.ProductType = 'All' or priceConditionClassification.ProductType = productPacks.ProductType)    
inner join MasterData.PT_TMINST as institute 
    on tender.InstituteID = institute.InstituteID 
left outer join TransactionalData.PriceCondition as priceCondition 
    on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
    and product.OfferID = priceCondition.OfferID
    and product.ProductCode = priceCondition.ProductCode
{
key tender.TenderID,
key offer.OfferID,
key product.ProductCode,
key institute.InstituteID as INSTITUTE_ID,
case 
    when priceCondition.PriceConditionCode = 'YAW1' or priceCondition.PriceConditionCode = 'YAW2'
        then 'Yes'
        else 'No'        
end as RAPPEL:String(10)
} where priceConditionClassification.ConditionType = 'Rappel' and (offer.OfferStatusTable.STATUS = 'Quotation Submitted' or offer.OfferStatusTable.STATUS = 'Results Recorded' or offer.OfferStatusTable.STATUS = 'Delivery Ongoing')
group by tender.TenderID, 
        offer.OfferID, 
        product.ProductCode, 
        institute.InstituteID, 
        priceCondition.PriceConditionCode; 

@cds.persistence.exists
entity TenderFOCView as select from TransactionalData.PT_TMTEND as tender 
inner join TransactionalData.PT_TMOFRS as offer 
    on offer.TenderID = tender.TenderID
    and offer.Active = 1
inner join TransactionalData.PT_TMOFPR as product 
    on product.OfferID = offer.OfferID
    and product.Active = 1
    and product.ActiveProduct = 1 
inner join MasterData.PT_TMPRDPCK as productPacks
    on productPacks.PRODUCTPACKID = product.ProductCode
    and productPacks.ACTIVERECORD = 'Yes' 
left outer join TransactionalData.PriceConditionClassification as priceConditionClassification  
    on priceConditionClassification.CountryCode = product.CountryCode
    and priceConditionClassification.Classification = tender.Classification
    and priceConditionClassification.Division = offer.Division 
    and (priceConditionClassification.ProductType = 'All' or priceConditionClassification.ProductType = productPacks.ProductType)
inner join MasterData.PT_TMINST as institute 
    on tender.InstituteID = institute.InstituteID 
left outer join TransactionalData.PriceCondition as priceCondition 
    on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
    and product.OfferID = priceCondition.OfferID
    and product.ProductCode = priceCondition.ProductCode
{
key tender.TenderID,
key offer.OfferID,
key product.ProductCode,
key institute.InstituteID as INSTITUTE_ID,
case  
    when priceCondition.PriceConditionCode = 'YA01'
            then 'Yes'
            else 'No'
end as FOC:String(10)
} where priceConditionClassification.ConditionType = 'FOC' and (offer.OfferStatusTable.STATUS = 'Quotation Submitted' or offer.OfferStatusTable.STATUS = 'Results Recorded' or offer.OfferStatusTable.STATUS = 'Delivery Ongoing')
group by tender.TenderID, offer.OfferID, product.ProductCode,institute.InstituteID, priceCondition.PriceConditionCode; 

/**
 * This view contains Tender History fields used on the Spain financial offers page
 */
@cds.persistence.exists
entity TenderHistorySpain as select from TransactionalData.PT_TMTEND as tender
inner join TransactionalData.PT_TMOFRS as offer 
    on offer.TenderID = tender.TenderID
    and offer.Active = 1
inner join TransactionalData.PT_TMOFPR as product 
    on product.OfferID = offer.OfferID
    and product.Active = 1
    and product.ActiveProduct = 1 
inner join MasterData.PT_TMPRDPCK as productPacks
    on productPacks.PRODUCTPACKID = product.ProductCode
    and productPacks.ACTIVERECORD = 'Yes' 
inner join TransactionalData.PriceConditionClassification as priceConditionClassification  
    on priceConditionClassification.CountryCode = product.CountryCode
    and priceConditionClassification.Classification = tender.Classification
    and priceConditionClassification.Division = offer.Division
    and priceConditionClassification.isMain = 'true' 
    and (priceConditionClassification.ProductType = 'All' or priceConditionClassification.ProductType = productPacks.ProductType)
inner join MasterData.PT_TMINST as institute 
    on tender.InstituteID = institute.InstituteID
inner join MasterDataViews.MostRecentMasterPricesView as masterPrices 
    on product.ProductCode = masterPrices.ProductPackId
    and product.CountryCode = masterPrices.CountryCode    
inner join TransactionalData.PriceCondition as priceCondition 
    on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
    and product.OfferID = priceCondition.OfferID
    and product.ProductCode = priceCondition.ProductCode
left outer join TransactionalDataViews.TenderFOCView as tenderFOC
    on tender.TenderID = tenderFOC.TenderID
    and offer.OfferID = tenderFOC.OfferID
    and product.ProductCode = tenderFOC.ProductCode
    and institute.InstituteID = tenderFOC.INSTITUTE_ID
left outer join TransactionalDataViews.TenderRappelView as tenderRappel
    on tender.TenderID = tenderRappel.TenderID
    and offer.OfferID = tenderRappel.OfferID
    and product.ProductCode = tenderRappel.ProductCode
    and institute.InstituteID = tenderRappel.INSTITUTE_ID
{
key tender.TenderID,
key offer.OfferID,
key product.ProductCode,
tender.TenderName as TENDER_NAME,
offer.SubmittedOn as OFFER_DATE,
key institute.InstituteID as INSTITUTE_ID,
institute.InstituteName as INSTITUTE_NAME,
product.SKU.PRODUCTPACKNAME as PRODUCT_NAME,
product.Price.OfferPrice *
    case when product.UnitPerPack = 'Unit'
        then product.SKU.PACKFACTOR
        else 1
    end as PACK_PRICE:Double,
product.Price.OfferPrice *
    case when product.UnitPerPack = 'Unit'
        then 1
        else 1 / product.SKU.PACKFACTOR
    end as UNIT_PRICE:Double,
masterPrices.YLLP as PVL,
ifnull(tenderFOC.FOC, 'No') as FOC:String(10),
ifnull(tenderRappel.RAPPEL, 'No') as RAPPEL:String(10),
masterPrices.YLAP as CONFIDENTIAL_PRICE,
priceCondition.PriceConditionCode as PriceConditionCode,
priceConditionClassification.ConditionType as PRICE_CONDITION,
priceCondition.RoyalDecree as ROYALDECREE,
priceCondition.Discount as DISCOUNT,
ifnull(product.Results.Outcome, 'NA') as OUTCOME:String(10)
}
where (offer.OfferStatusTable.STATUS = 'Quotation Submitted' or offer.OfferStatusTable.STATUS = 'Results Recorded' or offer.OfferStatusTable.STATUS = 'Delivery Ongoing')
group by tender.TenderID,
    offer.OfferID,
    product.ProductCode,
    tender.TenderName,
    offer.SubmittedOn,
    institute.InstituteID,
    institute.InstituteName,
    product.SKU.PRODUCTPACKNAME,
    product.Price.OfferPrice,
    product.SKU.PACKFACTOR,
    product.UnitPerPack,
    masterPrices.YLLP,
    tenderFOC.FOC,
    tenderRappel.RAPPEL,
    masterPrices.YLAP,
    priceConditionClassification.ConditionType,
    priceCondition.RoyalDecree,
    priceCondition.PriceConditionCode,
    priceCondition.Discount,    
    product.Results.Outcome;

@cds.persistence.exists
entity TenderHistoryBrazilAdhesionContracts as select from BrazilContractingData.Contracts as contract
    inner join BrazilContractingData.ContractProducts as contractProduct
        on contractProduct.Contract.ID = contract.ID
    inner join TransactionalData.PT_TMOFPR as product
        on product.ProductCode = contractProduct.ProductPackID
        and product.LotID = contractProduct.LotID
        and product.OfferID = contractProduct.OfferID {
            key contract.TenderID,
            key contractProduct.LotID,
            key contractProduct.OfferID,
            key contractProduct.ProductPackID,
            contract.ContractType,
            (sum(contractProduct.RequestedVolume) / (product.RequestedVolume*2)) as ADHESION:Double
    } 
    where contract.ContractType = 'Adhesion Contract'
    group by contract.TenderID, 
         contractProduct.OfferID,
		 contractProduct.ProductPackID,
         contractProduct.LotID,
		 contract.ContractType,
		 product.RequestedVolume;    

@cds.persistence.exists
entity TenderHistoryBrazil as select from TransactionalData.PT_TMTEND as tender
inner join TransactionalData.PT_TMOFRS as offer 
    on offer.TenderID = tender.TenderID
    and offer.Active = 1
inner join TransactionalData.PT_TMOFPR as product 
    on product.OfferID = offer.OfferID
    and product.Active = 1
    and product.ActiveProduct = 1 
inner join MasterData.PT_TMPRDPCK as productPacks
    on productPacks.PRODUCTPACKID = product.ProductCode
    and productPacks.ACTIVERECORD = 'Yes' 
inner join TransactionalData.PriceConditionClassification as priceConditionClassification  
    on priceConditionClassification.CountryCode = product.CountryCode
    and priceConditionClassification.Classification = tender.Classification
    and priceConditionClassification.Division = offer.Division
    and priceConditionClassification.isMain = true 
    and (priceConditionClassification.ProductType = 'All' or priceConditionClassification.ProductType = productPacks.ProductType)
inner join MasterData.PT_TMINST as institute 
    on tender.InstituteID = institute.InstituteID 
inner join MasterData.PT_TMDIST as distributor
    on offer.DistributorID = distributor.DistributorID
inner join TransactionalData.PriceCondition as priceCondition 
    on priceCondition.PriceConditionClassification.ID = priceConditionClassification.ID
    and product.OfferID = priceCondition.OfferID
    and product.ProductCode = priceCondition.ProductCode
    and product.LotID = priceCondition.LotID
inner join TransactionalData.PT_TMTNOFST as offerStatus
	on offerStatus.OfferID = offer.OfferID
	and offerStatus.Active = 1
left outer join TenderHistoryBrazilAdhesionContracts as adhesionContract
    on product.ProductCode = adhesionContract.ProductPackID {
        key tender.TenderID,
        key offer.OfferID,
        key product.ProductCode,
        key product.LotID,
        tender.TenderName as TENDER_NAME,
        offer.SubmittedOn as OFFER_DATE,
        key institute.InstituteID as INSTITUTE_ID,
        institute.InstituteName as INSTITUTE_NAME,
        product.SKU.PRODUCTPACKNAME as PRODUCT_NAME,
        distributor.DistributorName as DISTRIBUTOR_NAME,
        priceCondition.PriceList as PRICE_LIST,
        priceCondition.TaxExemption as TAX_EXEMPTION,
        ifnull(priceCondition.CAP, 'No') as CAP:String(10),
        priceCondition.StandardDiscount+priceCondition.AdditionalDiscount as TOTAL_DISCOUNT:Double,
        priceCondition.CommercialProposal as COMM_PROPOSAL,
        ifnull(adhesionContract.ADHESION, 0) as ADHESION:Double,
        ifnull(product.Results.Outcome, 'NA') as OUTCOME:String(10)
}
where tender.CountryCode = 'BR' and (offerStatus.STATUS = 'Quotation Submitted' or offerStatus.STATUS = 'Results Recorded' or offerStatus.STATUS = 'Delivery Ongoing')
group by tender.TenderID,
    offer.OfferID,
    product.ProductCode,
    tender.TenderName,
    offer.SubmittedOn,
    institute.InstituteID,
    institute.InstituteName,
    distributor.DistributorID,
    distributor.DistributorName,
    product.SKU.PRODUCTPACKNAME,
    priceCondition.PriceList,
    priceCondition.TaxExemption,
    priceCondition.CAP,
    priceCondition.StandardDiscount,
    priceCondition.AdditionalDiscount,
    priceCondition.CommercialProposal,
    adhesionContract.ADHESION,
    product.Results.Outcome,
    product.LotID;

    /**
 * This view contains Brazil PriceCondition ZWP0 price fields used in the PriceConditionBrazilView
 */
@cds.persistence.exists
entity PriceConditionPriceListView as select from TransactionalData.PT_TMTEND as tender 
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
inner join DirectIndirectCustomers as customer 
    on tender.InstituteID = customer.InstituteID 
    and tender.TenderID = customer.TenderID 
    and offer.OfferID = customer.OfferID
left outer join MasterDataViews.MostRecentBrazilMasterPricesView as masterPrices 
    on product.ProductCode = masterPrices.ProductID
    and customer.CustomerID = masterPrices.CustomerID
    and masterPrices.Type = 'ZWP0'
    {
    key product.TenderID,
    key offer.OfferID,
    key product.ProductCode,
    key customer.InstituteID,
    key customer.CustomerID,
    masterPrices.Value as masterPriceList,
    masterPrices.Currency as masterPriceCurrency,
    masterPrices.UOM as UoM,
    }where tender.Active = 1 and tender.CountryCode = 'BR'
    group by product.TenderID,
    offer.OfferID,
    product.ProductCode,
    customer.InstituteID,
    customer.CustomerID,
    masterPrices.Value,
    masterPrices.Currency,
    masterPrices.UOM;

    /**
 * This view contains Brazil PriceCondition ZWD4 price fields used in the PriceConditionBrazilView
 */
@cds.persistence.exists
entity PriceConditionStandardDiscountView as select from TransactionalData.PT_TMTEND as tender 
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
inner join DirectIndirectCustomers as customer 
    on tender.InstituteID = customer.InstituteID 
    and tender.TenderID = customer.TenderID 
    and offer.OfferID = customer.OfferID
left outer join MasterDataViews.MostRecentBrazilMasterPricesView as masterPrices 
    on product.ProductCode = masterPrices.ProductID
    and customer.CustomerID = masterPrices.CustomerID
    and masterPrices.Type = 'ZWD4'
    {
    key product.TenderID,
    key offer.OfferID,
    key product.ProductCode,
    key customer.InstituteID,
    key customer.CustomerID,
    masterPrices.Value as masterStandardDiscount
    }where tender.Active = 1 and tender.CountryCode = 'BR'
    group by product.TenderID,
    offer.OfferID,
    product.ProductCode,
    customer.InstituteID,
    customer.CustomerID,
    masterPrices.Value;


    /**
 * This view contains Brazil PriceCondition IBRX price fields used in the PriceConditionBrazilView
 */
@cds.persistence.exists
entity PriceConditionICMSTaxesView as select from TransactionalData.PT_TMTEND as tender 
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
inner join DirectIndirectCustomers as customer 
    on tender.InstituteID = customer.InstituteID 
    and tender.TenderID = customer.TenderID 
    and offer.OfferID = customer.OfferID
left outer join MasterDataViews.MostRecentBrazilMasterPricesView as masterPrices 
    on product.ProductCode = masterPrices.ProductID
    and customer.CustomerID = masterPrices.CustomerID
    and masterPrices.Type = 'IBRX'
    {
    key product.TenderID,
    key offer.OfferID,
    key product.ProductCode,
    key customer.InstituteID,
    key customer.CustomerID,
    masterPrices.Value as masterICMSTaxes
    }where tender.Active = 1 and tender.CountryCode = 'BR'
    group by product.TenderID,
    offer.OfferID,
    product.ProductCode,
    customer.InstituteID,
    customer.CustomerID,
    masterPrices.Value;


@cds.persistence.exists
entity DirectIndirectDistributor as select from MasterData.PT_TMDIST {
    key DistributorID, 
    key CountryCode,
    DistributorName,
    CustomerID,
    case 
        when DistributorName = 'Bayer Brazil' then true
        else false
    end as isDirect:Boolean,
};

@cds.persistence.exists
entity DirectIndirectCustomers as select from TransactionalData.PT_TMTEND as tender 
inner join TransactionalData.PT_TMOFRS as o on o.TenderID = tender.TenderID and o.Active = 1
inner join MasterData.PT_TMINST as inst on tender.InstituteID = inst.InstituteID 
inner join DirectIndirectDistributor as dist on dist.DistributorID = o.DistributorID and dist.CountryCode = o.CountryCode
{
    key o.OfferID,
    o.TenderID,
    dist.isDirect,
    inst.InstituteID ,
    case 
        when dist.isDirect = true then inst.CustomerID
        else dist.CustomerID
    end as CustomerID:Integer
};


    /**
 * This view contains calculated fields used on the Brazil financial offers page
 * TODO: use the below join if you want to use DirectIndirectCustomers
 * inner join DirectIndirectCustomers as customer on tender.InstituteID = customer.InstituteID and tender.TenderID = customer.TenderID and tender.OfferID = customer.OfferID
 */
@cds.persistence.exists
entity PriceConditionBrazilView as select from TransactionalData.PT_TMTEND as tender 
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
inner join DirectIndirectCustomers as customer 
    on tender.InstituteID = customer.InstituteID 
    and tender.TenderID = customer.TenderID 
    and offer.OfferID = customer.OfferID
inner join TransactionalDataViews.PriceConditionPriceListView as masterPriceListPriceCondition
    on masterPriceListPriceCondition.TenderID = product.TenderID
    and masterPriceListPriceCondition.OfferID = product.OfferID
    and masterPriceListPriceCondition.ProductCode = product.ProductCode 
    and masterPriceListPriceCondition.InstituteID = tender.InstituteID
    and masterPriceListPriceCondition.CustomerID = customer.CustomerID
inner join TransactionalDataViews.PriceConditionStandardDiscountView as masterStandardDiscountPriceCondition
    on masterStandardDiscountPriceCondition.TenderID = product.TenderID
    and masterStandardDiscountPriceCondition.OfferID = product.OfferID
    and masterStandardDiscountPriceCondition.ProductCode = product.ProductCode 
    and masterStandardDiscountPriceCondition.InstituteID = tender.InstituteID
    and masterStandardDiscountPriceCondition.CustomerID = customer.CustomerID
inner join TransactionalDataViews.PriceConditionICMSTaxesView as masterICMSTaxesPriceCondition
    on masterICMSTaxesPriceCondition.TenderID = product.TenderID
    and masterICMSTaxesPriceCondition.OfferID = product.OfferID
    and masterICMSTaxesPriceCondition.ProductCode = product.ProductCode 
    and masterICMSTaxesPriceCondition.InstituteID = tender.InstituteID
    and masterICMSTaxesPriceCondition.CustomerID = customer.CustomerID    
left outer join TransactionalData.PriceCondition as priceCondition 
    on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
    and product.OfferID = priceCondition.OfferID
    and product.ProductCode = priceCondition.ProductCode
    and product.LotID = priceCondition.LotID
    {
    key product.TenderID,
    key offer.OfferID,
    key product.ProductCode,
    key product.LotID,
    customer.CustomerID,
    priceCondition.ID as ExistingPriceConditionID: UUID,
    priceCondition.PriceConditionClassification.ID as PriceConditionClassificationID:UUID,
    tender.CountryCode,
    key priceConditionClassification.ConditionType,
    priceConditionClassification.Classification,
    priceConditionClassification.Division,
    priceConditionClassification.isMain,
    case 
        when priceCondition.AdditionalDiscount is null
            then 0.0
        else
            priceCondition.AdditionalDiscount 
    end as AdditionalDiscount:Decimal,
    masterPriceListPriceCondition.masterPriceList,
    masterStandardDiscountPriceCondition.masterStandardDiscount,
    masterICMSTaxesPriceCondition.masterICMSTaxes,
    masterPriceListPriceCondition.masterPriceCurrency,
    masterPriceListPriceCondition.UoM,
    case 
        when priceCondition.PriceList is null
            then masterPriceListPriceCondition.masterPriceList
        else
            priceCondition.PriceList
    end as PriceList:Decimal,
    case 
        when priceCondition.StandardDiscount is null
            then masterStandardDiscountPriceCondition.masterStandardDiscount
        else
            priceCondition.StandardDiscount
    end as StandardDiscount:Decimal,
    case 
        when priceCondition.ICMSTax is null
            then masterICMSTaxesPriceCondition.masterICMSTaxes
        else
            priceCondition.ICMSTax
    end as ICMSTax:Decimal,
    priceCondition.TaxExemption,
    priceCondition.PriceAfterTaxExemtion, //calculated in UI based on User Input
    priceCondition.CAP,
    priceCondition.PriceAfterCap, //calculated in UI based on User Input
    priceCondition.CommercialProposal,  //User Input field for Commercial Proposal PriceCondition, calculated field in UI for Discount PriceCondition
    priceCondition.ReferencePriceAgreement,
    priceCondition.TaxEqualization,
    priceCondition.Invoive,
    priceCondition.ICMS,
    priceCondition.NetPrice,
    priceCondition.CapBrazil.CAP as CapValue,
    }where tender.Active = 1 and tender.CountryCode = 'BR';

@cds.persistence.exists
    entity OfferValidation {
            OFFERSTATUSPATH       : String(124) not null;
            TENDERID              : String(50) not null;
            CLASSIFICATION        : String(50) not null; //Added Classification (db#1)
            TENDER_REFERENCE      : String(753);
            PROCUREMENT_REASON    : String;
        key OFFERID               : String(30) not null;
            INSTITUTENAME         : String(500);
            INSTITUTE_ADDRESS     : String(500);
            INSTITUTE_TYPE        : String(50);
            INSTITUTE_STATE       : String;
            INSTITUTE_REGION      : String;
            INSTITUTE_PROVINCE    : String;
            INSTITUTE_CIFCODE     : String(50);
            INSTITUTE_REGIONALHEALTHSYSTEM: String(50);
            INSTITUTE_CUSTOMER_GROUP: String(50);
            EXTERNAL_INSTITUTEID  : String(50);
            INSTITUTECITY        : String(255);
            TENDERCONTACT           :String;
            QUOTATIONINSTITUTENAME : String(500);
            QUOTATIONINSTITUTECITY : String(255);
            QUOTATIONINSTITUTECUSTOMERID : Integer;
            TAXCODE               : String(50);
            VATCODE               : String(50);       
            CUSTOMER_CODE         : Integer;
            DIVISION              : String(100);
            OFFERDATE             : Date;
            OFFERVALIDITY         : Date not null;
            EffectiveDate         : Date;
            ExpiryDate            : Date;
            COUNTRYCODE           : String not null;
            SELLINGCOMPANY        : String(300);
            SELLINGCOMPANYBANK    : String(5000);
            SELLING_COMPANY_AS1   : String(300);
            SELLING_COMPANY_AS1_NAMEI: String(255);
            SELLING_COMPANY_AS1_TITLEI: String(255);
            SELLING_COMPANY_AS2_NAMEI: String(255);
            SELLING_COMPANY_AS2_TITLEI: String(255);
            SELLING_COMPANY_AS2   : String(300);
            E_SIGNATURE1          : Boolean;
            E_SIGNATURE2          : Boolean;
            CURRENCY              : String(255);
            AMOUNT_IN_NUMBERS     : Double;
            AMOUNT_IN_WORDS       : String(1024);
            NET_AMOUNT_IN_NUMBERS : Double;
			NET_AMOUNT_IN_WORDS   : String(1024);
			NET_OFFER_AMOUNT_IN_NUMBERS: Double;
			NET_OFFER_AMOUNT_IN_WORDS  : String(1024);
            AMOUNT_IN_NUMBERS_VAT : Double;
            AMOUNT_IN_WORDS_VAT   : String(1024);
            VAT_TOTAL             : Double;
            LETTERHEAD            : String(5000);
            //REGULATORY            : Integer;//MEA only
            //LEGAL                 : Integer not null;//MEA only
            //CONTROLLING           : Integer not null;//MEA only
            //COUNTRY_BUSINESS      : Integer;//MEA and MX
            //REGIONAL_BUSINESS     : Integer not null;//MEA only
            //SUPPLY_CHAIN          : Integer not null;//All countries
            DISTRIBUTORNAME       : String(500);
            DISTRIBUTORADDRESS    : String(5000);
            DISTRIBUTORPHONE      : String(500);
            DISTRIBUTORFAX        : String(500);
            DISTRIBUTORCONTACT    : String(500);
            DISTRIBUTOREMAIL      : String(500); // Chile
            PUBLICATION_DATE      : Date; // Chile
            BID_DUE_DATE          : Date; // Chile
            TENDER_SUBMITTED_BY   : String; // Chile
            REMARKS               : String(5000);
            CUSTOM_REMARKS        : String not null;
            DELIVERYTERMS         : String(5000);
            PAYMENTTERMS          : String(5000);
            SHIPMENTTERMS         : String(5000);
            IS_LOWEST             : Integer not null;
            IS_DEFAULT_TERMS      : Integer not null;
            NEW_APPROVAL          : Integer;
            //NSM_SM_FM             : Integer not null;//TH only
            //HBU                   : Integer not null;//TH only
            //CDH                   : Integer not null;//TH and AR
            IN_POLICY             : Boolean;
            //MACS                           : Integer not null;//AR only
            //TA                             : Integer not null;//AR only
            //FBP                            : Integer not null;//AR only
            //LPC                            : Integer not null;//AR only
            //COM_PGA                        : Integer not null;//AR only
            //International_Trade            : Integer not null;//AR only
            //Transfer_Pricing               : Integer not null;//AR only
            //SBR                            : Integer not null;//AR only
            BUDGET_RATE           : Double;
            SPOT_RATE             : Double;
            EXTERNAL_ID           : String;
			SAP_ID                : String;
            TENDER_TYPE           : String; 
            CREATED_BY_USER_EMAIL :String(500);
            CREATED_BY_USER_ROLE  : String(100);
            CREATED_BY_USER_CONTACTNUMBER :String (20);
            CONTENT               : String(500); //manual conflict solving for change of KOSAL //EHQUT-390012-Spain - commercial offer template modifications
            Submitted             : Boolean default false;
            TenderChannel          : String(255);
            ContractLength         : Integer;
            ContractExtenseion     : Integer;
            NumberOfExtension      : Integer;  //PT_TMTEND/CUSTOM_INTEGER_1
            ClientComment          : String;
            Comment                : String;
            Regions                : String;
            InternalDueDate        : Date;
            ExpectedAwardDate      : Date;
            Unitofvalidityperiod   : String;
			DeliveryDue            : Integer;
			Unitofdeliverydue      : String;
			QuotationDeliverymethod : String;
			QuotationRecipientname  : String;
			QuotationRecipientcontact : String;
			Expectdatetoreceivethedocument: Date;
            RequestorPphoneNnumber: Integer;
            BayerRepresentativeName: String;
            BayerRepresentativePhoneNumber: Integer;
            PeriodOfBankGauranteeStart: Date;
            PeriodOfBankGauranteeEnd: Date;
            BGValueBaht: Double;
            TenderAnnouncementReference: String;
            Contract_Length1       : Integer; //PT_TMTEND/CUSTOM_INTEGER_1
            Contract_Length2       : Integer; //PT_TMTEND/CUSTOM_INTEGER_2
            Contract_Length3       : Integer; //PT_TMTEND/CUSTOM_INTEGER_3
            ContractLenghtUnit: String;
            AttentionTo: String;
            QuotationDate: Date;
            InternalBidDueDate     : Date;
            Tender_Custom_Integer_1: Integer;
            Tender_Custom_Integer_2: Integer;
            Tender_Custom_Integer_3: Integer;
            Tender_Custom_Integer_4: Integer;
            Tender_Custom_Integer_5: Integer;
            Tender_Custom_Integer_6: Integer;
            Tender_Custom_Integer_7: Integer;
            Tender_Custom_Integer_8: Integer;
            Tender_Custom_Integer_9: Integer;
            Tender_Custom_Integer_10: Integer;
            Tender_Custom_String_1: String;
            Tender_Custom_String_2: String;
            Tender_Custom_String_3: String;
            Tender_Custom_String_4: String;
            Tender_Custom_String_5: String;
            Tender_Custom_String_6: String;
            Tender_Custom_String_7: String;
            Tender_Custom_String_8: String;
            Tender_Custom_String_9: String;
            Tender_Custom_String_10: String;
            Tender_Custom_String_11: String;
            Tender_Custom_String_12: String;
            Tender_Custom_String_13: String;
            Tender_Custom_String_14: String;
            Tender_Custom_String_15: String;
            Tender_Custom_String_16: String;
            Tender_Custom_String_17: String;
            Tender_Custom_String_18: String;
            Tender_Custom_String_19: String;
            Tender_Custom_String_20: String;
            Tender_Custom_Double_1: Double;
            Tender_Custom_Double_2: Double;
            Tender_Custom_Double_3: Double;
            Tender_Custom_Double_4: Double;
            Tender_Custom_Double_5: Double;
            Tender_Custom_Double_6: Double;
            Tender_Custom_Double_7: Double;
            Tender_Custom_Double_8: Double;
            Tender_Custom_Double_9: Double;
            Tender_Custom_Double_10: Double;
            Tender_Custom_Date_1: Date;
            Tender_Custom_Date_2: Date;
            Tender_Custom_Date_3: Date;
            Tender_Custom_Date_4: Date;
            Tender_Custom_Date_5: Date;
            Tender_Custom_Date_6: Date;
            Tender_Custom_Date_7: Date;
            Tender_Custom_Date_8: Date;
            Tender_Custom_Date_9: Date;
            Tender_Custom_Date_10: Date;
            Tender_Custom_Boolean_1: Boolean;
            Tender_Custom_Boolean_2: Boolean;
            Tender_Custom_Boolean_3: Boolean;
            Tender_Custom_Boolean_4: Boolean;
            Tender_Custom_Boolean_5: Boolean;
            Tender_Custom_Boolean_6: Boolean;
            Tender_Custom_Boolean_7: Boolean;
            Tender_Custom_Boolean_8: Boolean;
            Tender_Custom_Boolean_9: Boolean;
            Tender_Custom_Boolean_10: Boolean;
            Tender_Custom_Datetime_1: DateTime;
            Tender_Custom_Datetime_2: DateTime;
            Tender_Custom_Datetime_3: DateTime;
            Tender_Custom_Datetime_4: DateTime;
            Tender_Custom_Datetime_5: DateTime;
            Tender_Custom_Datetime_6: DateTime;
            Tender_Custom_Datetime_7: DateTime;
            Tender_Custom_Datetime_8: DateTime;
            Tender_Custom_Datetime_9: DateTime;
            Tender_Custom_Datetime_10: DateTime;
            Offer_Custom_Integer_1: Integer;
            Offer_Custom_Integer_2: Integer;
            Offer_Custom_Integer_3: Integer;
            Offer_Custom_Integer_4: Integer;
            Offer_Custom_Integer_5: Integer;
            Offer_Custom_Integer_6: Integer;
            Offer_Custom_Integer_7: Integer;
            Offer_Custom_Integer_8: Integer;
            Offer_Custom_Integer_9: Integer;
            Offer_Custom_Integer_10: Integer;
            Offer_Custom_String_1: String;
            Offer_Custom_String_2: String;
            Offer_Custom_String_3: String;
            Offer_Custom_String_4: String;
            Offer_Custom_String_5: String;
            Offer_Custom_String_6: String;
            Offer_Custom_String_7: String;
            Offer_Custom_String_8: String;
            Offer_Custom_String_9: String;
            Offer_Custom_String_10: String;
            Offer_Custom_String_11: String;
            Offer_Custom_String_12: String;
            Offer_Custom_String_13: String;
            Offer_Custom_String_14: String;
            Offer_Custom_String_15: String;
            Offer_Custom_String_16: String;
            Offer_Custom_String_17: String;
            Offer_Custom_String_18: String;
            Offer_Custom_String_19: String;
            Offer_Custom_String_20: String;
            Offer_Custom_Double_1: Double;
            Offer_Custom_Double_2: Double;
            Offer_Custom_Double_3: Double;
            Offer_Custom_Double_4: Double;
            Offer_Custom_Double_5: Double;
            Offer_Custom_Double_6: Double;
            Offer_Custom_Double_7: Double;
            Offer_Custom_Double_8: Double;
            Offer_Custom_Double_9: Double;
            Offer_Custom_Double_10: Double;
            Offer_Custom_Date_1: Date;
            Offer_Custom_Date_2: Date;
            Offer_Custom_Date_3: Date;
            Offer_Custom_Date_4: Date;
            Offer_Custom_Date_5: Date;
            Offer_Custom_Date_6: Date;
            Offer_Custom_Date_7: Date;
            Offer_Custom_Date_8: Date;
            Offer_Custom_Date_9: Date;
            Offer_Custom_Date_10: Date;
            Offer_Custom_Boolean_1: String;
            Offer_Custom_Boolean_2: String;
            Offer_Custom_Boolean_3: String;
            Offer_Custom_Boolean_4: String;
            Offer_Custom_Boolean_5: String;
            Offer_Custom_Boolean_6: String;
            Offer_Custom_Boolean_7: String;
            Offer_Custom_Boolean_8: String;
            Offer_Custom_Boolean_9: String;
            Offer_Custom_Boolean_10: String;
            Offer_Custom_Datetime_1: DateTime;
            Offer_Custom_Datetime_2: DateTime;
            Offer_Custom_Datetime_3: DateTime;
            Offer_Custom_Datetime_4: DateTime;
            Offer_Custom_Datetime_5: DateTime;
            Offer_Custom_Datetime_6: DateTime;
            Offer_Custom_Datetime_7: DateTime;
            Offer_Custom_Datetime_8: DateTime;
            Offer_Custom_Datetime_9: DateTime;
            Offer_Custom_Datetime_10: DateTime;
            Quotation_Custom_Integer_1: Integer;
            Quotation_Custom_Integer_2: Integer;
            Quotation_Custom_Integer_3: Integer;
            Quotation_Custom_Integer_4: Integer;
            Quotation_Custom_Integer_5: Integer;
            Quotation_Custom_Integer_6: Integer;
            Quotation_Custom_Integer_7: Integer;
            Quotation_Custom_Integer_8: Integer;
            Quotation_Custom_Integer_9: Integer;
            Quotation_Custom_Integer_10: Integer;
            Quotation_Custom_String_1: String;
            Quotation_Custom_String_2: String;
            Quotation_Custom_String_3: String;
            Quotation_Custom_String_4: String;
            Quotation_Custom_String_5: String;
            Quotation_Custom_String_6: String;
            Quotation_Custom_String_7: String;
            Quotation_Custom_String_8: String;
            Quotation_Custom_String_9: String;
            Quotation_Custom_String_10: String;
            Quotation_Custom_String_11: String;
            Quotation_Custom_String_12: String;
            Quotation_Custom_String_13: String;
            Quotation_Custom_String_14: String;
            Quotation_Custom_String_15: String;
            Quotation_Custom_String_16: String;
            Quotation_Custom_String_17: String;
            Quotation_Custom_String_18: String;
            Quotation_Custom_String_19: String;
            Quotation_Custom_String_20: String;
            Quotation_Custom_Double_1: Double;
            Quotation_Custom_Double_2: Double;
            Quotation_Custom_Double_3: Double;
            Quotation_Custom_Double_4: Double;
            Quotation_Custom_Double_5: Double;
            Quotation_Custom_Double_6: Double;
            Quotation_Custom_Double_7: Double;
            Quotation_Custom_Double_8: Double;
            Quotation_Custom_Double_9: Double;
            Quotation_Custom_Double_10: Double;
            Quotation_Custom_Date_1: Date;
            Quotation_Custom_Date_2: Date;
            Quotation_Custom_Date_3: Date;
            Quotation_Custom_Date_4: Date;
            Quotation_Custom_Date_5: Date;
            Quotation_Custom_Date_6: Date;
            Quotation_Custom_Date_7: Date;
            Quotation_Custom_Date_8: Date;
            Quotation_Custom_Date_9: Date;
            Quotation_Custom_Date_10: Date;
            Quotation_Custom_Boolean_1: Boolean;
            Quotation_Custom_Boolean_2: Boolean;
            Quotation_Custom_Boolean_3: Boolean;
            Quotation_Custom_Boolean_4: Boolean;
            Quotation_Custom_Boolean_5: Boolean;
            Quotation_Custom_Boolean_6: Boolean;
            Quotation_Custom_Boolean_7: Boolean;
            Quotation_Custom_Boolean_8: Boolean;
            Quotation_Custom_Boolean_9: Boolean;
            Quotation_Custom_Boolean_10: Boolean;
            Quotation_Custom_Datetime_1: DateTime;
            Quotation_Custom_Datetime_2: DateTime;
            Quotation_Custom_Datetime_3: DateTime;
            Quotation_Custom_Datetime_4: DateTime;
            Quotation_Custom_Datetime_5: DateTime;
            Quotation_Custom_Datetime_6: DateTime;
            Quotation_Custom_Datetime_7: DateTime;
            Quotation_Custom_Datetime_8: DateTime;
            Quotation_Custom_Datetime_9: DateTime;
            Quotation_Custom_Datetime_10: DateTime;
            NLHospitalManagerEmail: String;
            NLHospitalManagerContactNumber : String;
            TotalPNM_Value               : Double;
            ApproverTypes         : Association to many MasterData.ApproverTypes
                                        on ApproverTypes.CountryCode = $self.COUNTRYCODE;
    };


     //Transactional Data Services
    // EFRCL- 268955-Spain - correct mistakes on Commercial agreement templates
    @cds.persistence.exists
    entity OfferProductValidation {
            TENDER_ID                                   : String(30);
            COUNTRY_CODE                                : String;
        key OFFER_ID                                    : String(30) not null;
            DIVISION                                    : String(100);
            BRANDID                                     : String(50);
            BRANDNAME                                   : String(100);
            PRODUCT_UNIT_NAME                           : String(100); //thailand
            SKU                                         : Integer;
        key PRODUCTID                                   : Integer not null;
            CODE                                        : String(255);
            PRODUCTNAME                                 : String(102);
            PRODUCTGENERICNAME                          : String(500);
            PACKSIZE                                    : Double not null;
            DOSAGE                                      : Double;
            UOM                                         : String(10);
            COUNTRYOFORIGIN                             : String(120);
            MANUFACTURER                                : String(500);
            SHELFLIFE                                   : Integer;
            PRESENTATION                                : String(50);
            VAT                                         : Double; //percentage VAT (thailand)
            VAT_IN_WORDS                                : String;
            PRODUCT_COMMENT                             : String(784);
            UNIT                                        : String(255);
            PAID_VOLUME                                 : Double;
            TOTAL_VOLUME                                : Double;
            SORTER                                      : Integer;
            CURRENCY                                    : String(255);
            REQUESTED_QUANTITY                          : String(567);
            SHIPMENT_TERMS                              : String(317);
            PAYMENT_TERMS                               : String(255);
            DELIVERY_TERMS                              : String(500);
            SAMPLES                                     : Integer;
            SAMPLES_UNIT                                : Integer; //Thailand
            SAMPLES_PACK                                : Integer;
            REGISTERED_PRICE                            : Double; // Consumer price per unit
            REGISTERED_PRICE_IN_WORDS                   : String;
            OFFER_PRICE                                 : Double;
            FOC                                         : String(25);
            FOC_ABS_PCT_STP                             : String;          
            TOTAL_QUANTITY_UNITS                        : Double;
            FOC_QUANTITY_UNITS                          : Double; // FOC Unit (thailand)
            PAID_QUANTITY_UNITS                         : Double;
            REQ_PRICE_UNIT_OFFER_CURRENCY               : Double; //MSP excl VAT (thailand)
            REQ_PRICE_UNIT_OFFER_CURRENCY_VAT           : Double; //MSP incl VAT (thailand)
            REQ_PRICE_PACK_OFFER_CURRENCY               : Double;
            REQ_PRICE_UNIT_EUR_BUDGET                   : Double;
            REQ_PRICE_UNIT_EUR_SPOT                     : Double;
            NET_PRICE_UNIT_OFFER_CURRENCY               : Double; //NSP excl VAT (thailand)
            NET_PRICE_UNIT_OFFER_CURRENCY_IN_WORDS      : String;
            NET_PRICE_UNIT_OFFER_CURRENCY_VAT           : Double; //NSP incl VAT (thailand)
            NET_PRICE_UNIT_OFFER_CURRENCY_VAT_IN_WORDS  : String;
            NET_PRICE_PACK_OFFER_CURRENCY               : Double;
            NET_PRICE_PACK_OFFER_CURRENCY_IN_WORDS      : String;
            NET_PRICE_PACK_OFFER_CURRENCY_VAT           : Double;
            NET_PRICE_PACK_OFFER_CURRENCY_VAT_IN_WORDS  : String;
            NET_PRICE_UNIT_EUR_BUDGET                   : Double;
            NET_PRICE_UNIT_EUR_SPOT                     : Double;
            NET_OFFER_PRICE                             : Double;
            NET_PRICE                                   : Double;
            ADDITIONAL_DISCOUNT                         : Double;
            ADDITIONAL_DISCOUNT_IN_WORDS                : String;
            MAX_PRICE_NHS_PP                            : Double;
            MAX_PRICE_NHS_PP_IN_WORDS                   : String;
            MAX_PRICE_NHS_PU                            : Double;
            MAX_PRICE_NHS_PU_IN_WORDS                   : String;
            MAX_PRICE_NHS_PU_WITH_VAT                   : Double; //Italy change
            MAX_PRICE_NHS_PU_WITH_VAT_IN_WORDS          : String; //Italy change
            CONTRACT_START_DATE                         : String; //Italy change
            NET_OFFER_PRICE_IN_WORDS                    : String; //Italy change
            CUSTOMER_ID                                 : Integer; //Italy change
            COGS                                        : Double;
            COGS_EUR_UNIT                               : Double;
            COGS_EUR_PACK                               : Double;
            GROSS_SALES_OFFER_CURRENCY                  : Double; // Total amount for product
            GROSS_SALES_OFFER_CURRENCY_IN_WORDS         : String;
            GROSS_SALES_OFFER_CURRENCY_VAT              : Double;
            GROSS_SALES_OFFER_CURRENCY_VAT_IN_WORDS     : String;
            VAT_TOTAL                                   : Double;
            NET_SALES_OFFER_CURRENCY                    : Double;
            NET_SALES_OFFER_CURRENCY_IN_WORDS           : String;
            NET_SALES_EUR_BUDGET                        : Double;
            NET_SALES_EUR_SPOT                          : Double;
            GROSS_MARGIN_EUR_BUDGET                     : Double;
            GROSS_MARGIN_EUR_SPOT                       : Double;
            GROSS_PROFIT_EUR_BUDGET                     : Double;
            GROSS_PROFIT_EUR_SPOT                       : Double;
            //REGULATORY                                : Integer not null;//MEA only
            //LEGAL                                     : Integer not null;//MEA only
            //CONTROLLING                               : Integer not null;//MEA only
            //COUNTRY_BUSINESS                          : Integer not null;//MEA and MX
            //REGIONAL_BUSINESS                         : Integer not null;//MEA only
            //SUPPLY_CHAIN                              : Integer not null;//All countries
            IS_LOWEST                                   : Integer not null;
            IS_DEFAULT_TERMS                            : Integer not null;
            IS_REGISTERED                               : Integer not null;
            IS_ALTERNATIVE_QUOTED                       : Integer not null;
            IS_ALTERNATIVE_REQUESTED                    : Integer not null;
            NEW_APPROVAL                                : Integer;
            BUDGETED_PROFITABILITY                      : Double;
            UK_BUDGETED_PROFITABILITY                   : Double;
            CHANNEL                                     : String;
            ACT_PROFITABILITY                           : Double;
            //NSM_SM_FM                                 : Integer not null;//TH only
            //HBU                                       : Integer not null;//TH only
            //CDH                                       : Integer not null;//TH and AR
            IN_POLICY                                   : Boolean;
            //MACS                                      : Integer not null;//AR only
            //TA                                        : Integer not null;//AR only
            //FBP                                       : Integer not null;//AR only
            //LPC                                       : Integer not null;//AR only
            //COM_PGA                                   : Integer not null;//AR only
            //International_Trade                       : Integer not null;//AR only
            //Transfer_Pricing                          : Integer not null;//AR only
            //SBR                                       : Integer not null;//AR only
            MOLECULE_NAME                               : String; // Chile
            FOC_STEP                                    : Double;
            OFFER_PRICE_VAT                             : Double;
            BUDGET_RATE                                 : Double;
            SPOT_RATE                                   : Double;
            BUSINESS_CASE_PRICE                         : Double;
            WARRANTY                                    : Double;
            AGREEMENTDURATION                           : Integer;
            MONTHLYRENT                                 : Double;
            MONTHLYRENT_IN_WORDS                        : String;
            MONTHSPERINVOICE                            : Integer;  
            CONTRACTSTARTDATE                           : Timestamp;
            VALUEOFDEVICES                              : Double;
            STATUSOFDEVICE                              : String;
            MINCONTRACTUAL                              : Double;
            MINANNPURCH                                 : Double;
            OFFER_TYPE                                  : String;
            //missing SKU & SKUCountry fields
            ACTIVERECORD                                : String(10);
            HLEVEL6_CODE                                : String(50);
            PCI_NAME                                    : String(255);
            ACTIVE_SUBSTANCE                            : String(50);
            PRODUCT_TYPE                                : String(50);
            SKUCOUNTRY_ACTIVERECORD                     : String(10);
            PRESENTATION_2                              : String(1000);
            GOV_CODE                                    : String(255);
            CODE1                                       : String(255);
            CODE2                                       : String(255);
            CODE3                                       : String(255);
            QTY_THRESHOLD                               : Integer;
            ProductClass                                : String(2);
            ProductDescription                          : String(255);
            FINAL_DISCOUNT                              : Double;
            FINAL_DISCOUNT_IN_WORDS                     : String(255);
            PRODUCT_FULL_DESCRIPTION                    : String(255);
            // PERCENTAGE                                  : Decimal; // Royal Decree Percentage
            //end of missing SKU & SKUCountry fields
        key LOTID                                       : Integer default 1;
            LINE                                        : String;
            REFERENCE                                   : String(255);
            IBIZWORKFLOWID                              : Integer;
            DISTRIBUTORID                               : String;
            DistributorName                             : String(500);
	        Address                                     : String(500);
            City                                        : String;
            AwardedPrice                                : Double;
            InstituteID                                 : Integer not null;
            EARLIEST_DATE                               : Date;
            Comment                                     : String;
            PackSizeRequired                            : Integer;
            Price0                                      : Decimal;
            Price1                                      : Decimal;
            Price3                                      : Decimal;
            Level2Discount1                             : Double;
            Level2Discount2                             : Double;
            AnnualDiscount_Percentage                   : Double;
            NegotiationPrice                            : Double;
            PricingPolicyValue                          : Double;
            FreeGoodsQuantity                           : Double;
            FreeGoodsOther_Step                         : Double;
            FreeGoodsOther_ABS_PCT                      : String(4);
            FOC_PRODUCTPACKNAME                         : String;
            ADD_INCLUDE                                 : String;
            Level3Discount1                             : Double;
            Level1Discount1                             : Double;
            Region                                      : String(50);
            AlternateOfferYN                            : String(255);
            NET_OFFER_SALES_OFFER_CURRENCY              : Double;
            NET_OFFER_SALES_OFFER_CURRENCY_IN_WORDS     : String;
            FOCInfoText                                 : String;
            ContractDuration_1                          : Double;
            ContractDuration_2                          : Double;
            ContractDuration_3                          : Double;
            OfferPrice_1                                : Double;
            OfferPrice_2                                : Double;
            OfferPrice_3                                : Double;
            Discount_1                                  : Double;
            Discount_2                                  : Double;
            Discount_3                                  : Double;
            ItemNumber                                  : Integer;
            NLPriceConditionType                        : String;
            Product_Custom_Integer_1: Integer;
            Product_Custom_Integer_2: Integer;
            Product_Custom_Integer_3: Integer;
            Product_Custom_Integer_4: Integer;
            Product_Custom_Integer_5: Integer;
            Product_Custom_Integer_6: Integer;
            Product_Custom_Integer_7: Integer;
            Product_Custom_Integer_8: Integer;
            Product_Custom_Integer_9: Integer;
            Product_Custom_Integer_10: Integer;
            Product_Custom_String_1: String;
            Product_Custom_String_2: String;
            Product_Custom_String_3: String;
            Product_Custom_String_4: String;
            Product_Custom_String_5: String;
            Product_Custom_String_6: String;
            Product_Custom_String_7: String;
            Product_Custom_String_8: String;
            Product_Custom_String_9: String;
            Product_Custom_String_10: String;
            Product_Custom_String_11: String;
            Product_Custom_String_12: String;
            Product_Custom_String_13: String;
            Product_Custom_String_14: String;
            Product_Custom_String_15: String;
            Product_Custom_String_16: String;
            Product_Custom_String_17: String;
            Product_Custom_String_18: String;
            Product_Custom_String_19: String;
            Product_Custom_String_20: String;
            Product_Custom_Double_1: Double;
            Product_Custom_Double_2: Double;
            Product_Custom_Double_3: Double;
            Product_Custom_Double_4: Double;
            Product_Custom_Double_5: Double;
            Product_Custom_Double_6: Double;
            Product_Custom_Double_7: Double;
            Product_Custom_Double_8: Double;
            Product_Custom_Double_9: Double;
            Product_Custom_Double_10: Double;
            Product_Custom_Date_1: Date;
            Product_Custom_Date_2: Date;
            Product_Custom_Date_3: Date;
            Product_Custom_Date_4: Date;
            Product_Custom_Date_5: Date;
            Product_Custom_Date_6: Date;
            Product_Custom_Date_7: Date;
            Product_Custom_Date_8: Date;
            Product_Custom_Date_9: Date;
            Product_Custom_Date_10: Date;
            Product_Custom_Boolean_1: Boolean;
            Product_Custom_Boolean_2: Boolean;
            Product_Custom_Boolean_3: Boolean;
            Product_Custom_Boolean_4: Boolean;
            Product_Custom_Boolean_5: Boolean;
            Product_Custom_Boolean_6: Boolean;
            Product_Custom_Boolean_7: Boolean;
            Product_Custom_Boolean_8: Boolean;
            Product_Custom_Boolean_9: Boolean;
            Product_Custom_Boolean_10: Boolean;
            Product_Custom_Datetime_1: DateTime;
            Product_Custom_Datetime_2: DateTime;
            Product_Custom_Datetime_3: DateTime;
            Product_Custom_Datetime_4: DateTime;
            Product_Custom_Datetime_5: DateTime;
            Product_Custom_Datetime_6: DateTime;
            Product_Custom_Datetime_7: DateTime;
            Product_Custom_Datetime_8: DateTime;
            Product_Custom_Datetime_9: DateTime;
            Product_Custom_Datetime_10: DateTime;
            Delivery_Custom_Integer_1: Integer;
            Delivery_Custom_Integer_2: Integer;
            Delivery_Custom_Integer_3: Integer;
            Delivery_Custom_Integer_4: Integer;
            Delivery_Custom_Integer_5: Integer;
            Delivery_Custom_Integer_6: Integer;
            Delivery_Custom_Integer_7: Integer;
            Delivery_Custom_Integer_8: Integer;
            Delivery_Custom_Integer_9: Integer;
            Delivery_Custom_Integer_10: Integer;
            Delivery_Custom_String_1: String;
            Delivery_Custom_String_2: String;
            Delivery_Custom_String_3: String;
            Delivery_Custom_String_4: String;
            Delivery_Custom_String_5: String;
            Delivery_Custom_String_6: String;
            Delivery_Custom_String_7: String;
            Delivery_Custom_String_8: String;
            Delivery_Custom_String_9: String;
            Delivery_Custom_String_10: String;
            Delivery_Custom_String_11: String;
            Delivery_Custom_String_12: String;
            Delivery_Custom_String_13: String;
            Delivery_Custom_String_14: String;
            Delivery_Custom_String_15: String;
            Delivery_Custom_String_16: String;
            Delivery_Custom_String_17: String;
            Delivery_Custom_String_18: String;
            Delivery_Custom_String_19: String;
            Delivery_Custom_String_20: String;
            Delivery_Custom_Double_1: Double;
            Delivery_Custom_Double_2: Double;
            Delivery_Custom_Double_3: Double;
            Delivery_Custom_Double_4: Double;
            Delivery_Custom_Double_5: Double;
            Delivery_Custom_Double_6: Double;
            Delivery_Custom_Double_7: Double;
            Delivery_Custom_Double_8: Double;
            Delivery_Custom_Double_9: Double;
            Delivery_Custom_Double_10: Double;
            Delivery_Custom_Date_1: Date;
            Delivery_Custom_Date_2: Date;
            Delivery_Custom_Date_3: Date;
            Delivery_Custom_Date_4: Date;
            Delivery_Custom_Date_5: Date;
            Delivery_Custom_Date_6: Date;
            Delivery_Custom_Date_7: Date;
            Delivery_Custom_Date_8: Date;
            Delivery_Custom_Date_9: Date;
            Delivery_Custom_Date_10: Date;
            Delivery_Custom_Boolean_1: Boolean;
            Delivery_Custom_Boolean_2: Boolean;
            Delivery_Custom_Boolean_3: Boolean;
            Delivery_Custom_Boolean_4: Boolean;
            Delivery_Custom_Boolean_5: Boolean;
            Delivery_Custom_Boolean_6: Boolean;
            Delivery_Custom_Boolean_7: Boolean;
            Delivery_Custom_Boolean_8: Boolean;
            Delivery_Custom_Boolean_9: Boolean;
            Delivery_Custom_Boolean_10: Boolean;
            Delivery_Custom_Datetime_1: DateTime;
            Delivery_Custom_Datetime_2: DateTime;
            Delivery_Custom_Datetime_3: DateTime;
            Delivery_Custom_Datetime_4: DateTime;
            Delivery_Custom_Datetime_5: DateTime;
            Delivery_Custom_Datetime_6: DateTime;
            Delivery_Custom_Datetime_7: DateTime;
            Delivery_Custom_Datetime_8: DateTime;
            Delivery_Custom_Datetime_9: DateTime;
            Delivery_Custom_Datetime_10: DateTime;
            TenderResults_Custom_Integer_1: Integer;
            TenderResults_Custom_Integer_2: Integer;
            TenderResults_Custom_Integer_3: Integer;
            TenderResults_Custom_Integer_4: Integer;
            TenderResults_Custom_Integer_5: Integer;
            TenderResults_Custom_Integer_6: Integer;
            TenderResults_Custom_Integer_7: Integer;
            TenderResults_Custom_Integer_8: Integer;
            TenderResults_Custom_Integer_9: Integer;
            TenderResults_Custom_Integer_10: Integer;
            TenderResults_Custom_String_1: String;
            TenderResults_Custom_String_2: String;
            TenderResults_Custom_String_3: String;
            TenderResults_Custom_String_4: String;
            TenderResults_Custom_String_5: String;
            TenderResults_Custom_String_6: String;
            TenderResults_Custom_String_7: String;
            TenderResults_Custom_String_8: String;
            TenderResults_Custom_String_9: String;
            TenderResults_Custom_String_10: String;
            TenderResults_Custom_String_11: String;
            TenderResults_Custom_String_12: String;
            TenderResults_Custom_String_13: String;
            TenderResults_Custom_String_14: String;
            TenderResults_Custom_String_15: String;
            TenderResults_Custom_String_16: String;
            TenderResults_Custom_String_17: String;
            TenderResults_Custom_String_18: String;
            TenderResults_Custom_String_19: String;
            TenderResults_Custom_String_20: String;
            TenderResults_Custom_Double_1: Double;
            TenderResults_Custom_Double_2: Double;
            TenderResults_Custom_Double_3: Double;
            TenderResults_Custom_Double_4: Double;
            TenderResults_Custom_Double_5: Double;
            TenderResults_Custom_Double_6: Double;
            TenderResults_Custom_Double_7: Double;
            TenderResults_Custom_Double_8: Double;
            TenderResults_Custom_Double_9: Double;
            TenderResults_Custom_Double_10: Double;
            TenderResults_Custom_Date_1: Date;
            TenderResults_Custom_Date_2: Date;
            TenderResults_Custom_Date_3: Date;
            TenderResults_Custom_Date_4: Date;
            TenderResults_Custom_Date_5: Date;
            TenderResults_Custom_Date_6: Date;
            TenderResults_Custom_Date_7: Date;
            TenderResults_Custom_Date_8: Date;
            TenderResults_Custom_Date_9: Date;
            TenderResults_Custom_Date_10: Date;
            TenderResults_Custom_Boolean_1: Boolean;
            TenderResults_Custom_Boolean_2: Boolean;
            TenderResults_Custom_Boolean_3: Boolean;
            TenderResults_Custom_Boolean_4: Boolean;
            TenderResults_Custom_Boolean_5: Boolean;
            TenderResults_Custom_Boolean_6: Boolean;
            TenderResults_Custom_Boolean_7: Boolean;
            TenderResults_Custom_Boolean_8: Boolean;
            TenderResults_Custom_Boolean_9: Boolean;
            TenderResults_Custom_Boolean_10: Boolean;
            TenderResults_Custom_Datetime_1: DateTime;
            TenderResults_Custom_Datetime_2: DateTime;
            TenderResults_Custom_Datetime_3: DateTime;
            TenderResults_Custom_Datetime_4: DateTime;
            TenderResults_Custom_Datetime_5: DateTime;
            TenderResults_Custom_Datetime_6: DateTime;
            TenderResults_Custom_Datetime_7: DateTime;
            TenderResults_Custom_Datetime_8: DateTime;
            TenderResults_Custom_Datetime_9: DateTime;
            TenderResults_Custom_Datetime_10: DateTime;
            CompetitorResult_Custom_Integer_1: Integer;
            CompetitorResult_Custom_Integer_2: Integer;
            CompetitorResult_Custom_Integer_3: Integer;
            CompetitorResult_Custom_Integer_4: Integer;
            CompetitorResult_Custom_Integer_5: Integer;
            CompetitorResult_Custom_Integer_6: Integer;
            CompetitorResult_Custom_Integer_7: Integer;
            CompetitorResult_Custom_Integer_8: Integer;
            CompetitorResult_Custom_Integer_9: Integer;
            CompetitorResult_Custom_Integer_10: Integer;
            CompetitorResult_Custom_String_1: String;
            CompetitorResult_Custom_String_2: String;
            CompetitorResult_Custom_String_3: String;
            CompetitorResult_Custom_String_4: String;
            CompetitorResult_Custom_String_5: String;
            CompetitorResult_Custom_String_6: String;
            CompetitorResult_Custom_String_7: String;
            CompetitorResult_Custom_String_8: String;
            CompetitorResult_Custom_String_9: String;
            CompetitorResult_Custom_String_10: String;
            CompetitorResult_Custom_String_11: String;
            CompetitorResult_Custom_String_12: String;
            CompetitorResult_Custom_String_13: String;
            CompetitorResult_Custom_String_14: String;
            CompetitorResult_Custom_String_15: String;
            CompetitorResult_Custom_String_16: String;
            CompetitorResult_Custom_String_17: String;
            CompetitorResult_Custom_String_18: String;
            CompetitorResult_Custom_String_19: String;
            CompetitorResult_Custom_String_20: String;
            CompetitorResult_Custom_Double_1: Double;
            CompetitorResult_Custom_Double_2: Double;
            CompetitorResult_Custom_Double_3: Double;
            CompetitorResult_Custom_Double_4: Double;
            CompetitorResult_Custom_Double_5: Double;
            CompetitorResult_Custom_Double_6: Double;
            CompetitorResult_Custom_Double_7: Double;
            CompetitorResult_Custom_Double_8: Double;
            CompetitorResult_Custom_Double_9: Double;
            CompetitorResult_Custom_Double_10: Double;
            CompetitorResult_Custom_Date_1: Date;
            CompetitorResult_Custom_Date_2: Date;
            CompetitorResult_Custom_Date_3: Date;
            CompetitorResult_Custom_Date_4: Date;
            CompetitorResult_Custom_Date_5: Date;
            CompetitorResult_Custom_Date_6: Date;
            CompetitorResult_Custom_Date_7: Date;
            CompetitorResult_Custom_Date_8: Date;
            CompetitorResult_Custom_Date_9: Date;
            CompetitorResult_Custom_Date_10: Date;
            CompetitorResult_Custom_Boolean_1: Boolean;
            CompetitorResult_Custom_Boolean_2: Boolean;
            CompetitorResult_Custom_Boolean_3: Boolean;
            CompetitorResult_Custom_Boolean_4: Boolean;
            CompetitorResult_Custom_Boolean_5: Boolean;
            CompetitorResult_Custom_Boolean_6: Boolean;
            CompetitorResult_Custom_Boolean_7: Boolean;
            CompetitorResult_Custom_Boolean_8: Boolean;
            CompetitorResult_Custom_Boolean_9: Boolean;
            CompetitorResult_Custom_Boolean_10: Boolean;
            CompetitorResult_Custom_Datetime_1: DateTime;
            CompetitorResult_Custom_Datetime_2: DateTime;
            CompetitorResult_Custom_Datetime_3: DateTime;
            CompetitorResult_Custom_Datetime_4: DateTime;
            CompetitorResult_Custom_Datetime_5: DateTime;
            CompetitorResult_Custom_Datetime_6: DateTime;
            CompetitorResult_Custom_Datetime_7: DateTime;
            CompetitorResult_Custom_Datetime_8: DateTime;
            CompetitorResult_Custom_Datetime_9: DateTime;
            CompetitorResult_Custom_Datetime_10: DateTime;
            TenderAnnouncementReference                 : String;
            NLStaticField1                      : String;
            NLStaticField2                      : String;
            PL_VolumeInPacks                    : Double;
            PNM_VALUE                           : Double;
            MaxNetPricePerPack                          : Double;
            FreeGoodsOther                              : Association to many TransactionalData.FreeGoodsOther
                                                            on FreeGoodsOther.ProductPackId = $self.PRODUCTID
                                                            and FreeGoodsOther.ProductPricing.OfferID = $self.OFFER_ID;
            PriceConditionCurrentSectionTaiwan          : Association to many TransactionalDataViews.PriceConditionCurrentSectionTaiwanView
                                                            on PriceConditionCurrentSectionTaiwan.ProductCode = $self.PRODUCTID
                                                            and PriceConditionCurrentSectionTaiwan.INSTITUTE_ID = $self.InstituteID;
            ProductPricing                              : Association to TransactionalData.ProductPricing
                                                            on ProductPricing.ProductCode = $self.PRODUCTID
                                                            and ProductPricing.OfferID = $self.OFFER_ID;
            ProductPack                                 : Association to many MasterData.PT_TMPRDPCK 
                                                            on ProductPack.PRODUCTPACKID = $self.PRODUCTID;
            Materials                                   : Association to many MasterData.PT_TMSKUPRDPCK
                                                            on Materials.CountryCode = $self.COUNTRY_CODE
                                                            and Materials.ProductPackID = $self.PRODUCTID
                                                            and Materials.ActiveRecord = 'Yes';
            ApproverTypes                               : Association to many MasterData.ApproverTypes
                                                            on ApproverTypes.CountryCode = $self.COUNTRY_CODE;
            PriceCondition                              : Composition of many TransactionalData.PriceCondition 
                                                                    on PriceCondition.OfferID = $self.OFFER_ID
                                                                    and PriceCondition.ProductCode = $self.PRODUCTID
                                                                    and PriceCondition.CountryCode = $self.COUNTRY_CODE;
    };

    /**
 * This view contains Tender History fields for standard tender application
 */
 @cds.persistence.exists
    entity StandardTenderHistory as select from TransactionalData.PT_TMTEND as tender
    inner join TransactionalData.PT_TMOFRS as offer 
        on offer.TenderID = tender.TenderID
        and offer.Active = 1
    inner join TransactionalData.PT_TMOFPR as product 
        on product.OfferID = offer.OfferID
        and product.Active = 1
        and product.ActiveProduct = 1 
    inner join MasterData.PT_TMPRDPCK as productPacks
        on productPacks.PRODUCTPACKID = product.ProductCode
        and productPacks.ACTIVERECORD = 'Yes' 
    inner join TransactionalData.PriceConditionClassification as priceConditionClassification  
        on priceConditionClassification.CountryCode = product.CountryCode
        and priceConditionClassification.Classification = tender.Classification
        and priceConditionClassification.Division = offer.Division
        and priceConditionClassification.isMain = 'true' 
        and (priceConditionClassification.ProductType = 'All' or priceConditionClassification.ProductType = productPacks.ProductType)
    inner join MasterData.PT_TMINST as institute 
        on tender.InstituteID = institute.InstituteID   
    inner join TransactionalData.PriceCondition as priceCondition 
        on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
        and product.OfferID = priceCondition.OfferID
        and product.ProductCode = priceCondition.ProductCode
    left outer join TransactionalData.FreeGoodsOther as foc
        on foc.PriceCondition.ID = priceCondition.ID
    left join ProductTotalAmount as productTotal
            on productTotal.OfferID = offer.OfferID
            and productTotal.ProductCode = product.ProductCode
    {
    key tender.TenderID,
    key offer.OfferID,
    key product.ProductCode,
    key tender.CountryCode,
    tender.Country.Region,
    offer.Currency,
    offer.CreationDate,
    product.Price.NetofferPrice as NetofferPriceBDPR,
    product.Price.NetPrice as NetPriceBDPR,
    product.UnitPerPack,
    tender.TenderName as TENDER_NAME,
    offer.SubmittedOn as OFFER_DATE,
    offer.Quotation.EffectiveDate,
    offer.Quotation.ExpiryDate,
    key institute.InstituteID as INSTITUTE_ID,
    institute.InstituteName as INSTITUTE_NAME,
    product.SKU.PRODUCTPACKNAME as PRODUCT_NAME,
    product.Price.OfferPrice as OfferPriceBDPR,
    product.RequestedVolume,
    priceCondition.Tax,
    priceCondition.StandardDiscount,
    priceCondition.AdditionalDiscount,
    priceCondition.NetPrice,                        
    priceCondition.Price0,                            
    priceCondition.Level1Discount1,                
    priceCondition.Level1Discount2,                    
    priceCondition.Level1Discount3,                  
    priceCondition.Price1,                        
    priceCondition.Level2Discount1,                
    priceCondition.Level2Discount2,               
    priceCondition.Level2Discount3,             
    priceCondition.Price2,                            
    priceCondition.Level3Discount1,                    
    priceCondition.Level3Discount2,                
    priceCondition.Level3Discount3,                     
    priceCondition.Price3,                     
    priceCondition.OfferPrice,                        
    priceCondition.NetOfferPrice,
    priceCondition.AnnualDiscountForBranch,
    priceCondition.TotalYearlyValueMainCustomer,
    priceCondition.TotalYearlyValueBranch,
    priceCondition.TotalDiscountNHI,
    priceCondition.TotalDiscountInvoice,
    priceCondition.PriceConditionCode as PriceConditionCode,
    priceConditionClassification.ConditionType as PRICE_CONDITION,
    priceCondition.Discount as DISCOUNT,
    priceCondition.GeneralDiscount_Amount, 
    priceCondition.SecondDiscount_Amount,
    priceCondition.NegotiationPrice,
    product.Results.AwardedPrice,
    offer.OfferStatus.STATUS as OfferStatus,
    CASE 
        when (product.ProductCode = foc.ProductPackId) 
            then 'Yes' 
            else 'No'
    end as FOC:String(3),
    ifnull(product.Results.Outcome, 'NA') as OUTCOME:String(10),
    productTotal.TotalAmount
    }
    where (offer.OfferStatusTable.STATUS = 'Quotation Submitted' or offer.OfferStatusTable.STATUS = 'Results Recorded' or offer.OfferStatusTable.STATUS = 'Delivery Ongoing')
    group by tender.TenderID,
        offer.OfferID,
        product.ProductCode,
        tender.CountryCode,
        tender.Country.Region,
        tender.TenderName,
        offer.Currency,
        offer.CreationDate,
        offer.SubmittedOn,
        institute.InstituteID,
        institute.InstituteName,
        product.SKU.PRODUCTPACKNAME,
        product.Price.OfferPrice,
        product.UnitPerPack,
        priceConditionClassification.ConditionType,
        priceCondition.PriceConditionCode,
        priceCondition.Discount, 
        product.Results.AwardedPrice,
        product.Price.NetofferPrice,
        product.Price.NetPrice,
        product.RequestedVolume,
        offer.Quotation.EffectiveDate,
        offer.Quotation.ExpiryDate,
        priceCondition.Tax,
        priceCondition.StandardDiscount,
        priceCondition.AdditionalDiscount,
        priceCondition.NetPrice,                        
        priceCondition.Price0,                            
        priceCondition.Level1Discount1,                
        priceCondition.Level1Discount2,                    
        priceCondition.Level1Discount3,                  
        priceCondition.Price1,                        
        priceCondition.Level2Discount1,                
        priceCondition.Level2Discount2,               
        priceCondition.Level2Discount3,             
        priceCondition.Price2,                            
        priceCondition.Level3Discount1,                    
        priceCondition.Level3Discount2,                
        priceCondition.Level3Discount3,                     
        priceCondition.Price3,                     
        priceCondition.OfferPrice,                        
        priceCondition.NetOfferPrice,
        priceCondition.AnnualDiscountForBranch,
        priceCondition.TotalYearlyValueMainCustomer,
        priceCondition.TotalYearlyValueBranch,
        priceCondition.TotalDiscountNHI,
        priceCondition.TotalDiscountInvoice,
        priceCondition.GeneralDiscount_Amount, 
        priceCondition.SecondDiscount_Amount,
        priceCondition.NegotiationPrice,
        offer.OfferStatusTable.STATUS,
        product.Results.Outcome,
        offer.OfferStatus.STATUS,
        foc.ProductPackId,
        productTotal.TotalAmount;

        @cds.persistence.exists
        entity StandardTenderHistorySpain as select from TransactionalData.PT_TMTEND as tender
    inner join TransactionalData.PT_TMOFRS as offer 
        on offer.TenderID = tender.TenderID
        and offer.Active = 1
    inner join TransactionalData.PT_TMOFPR as product 
        on product.OfferID = offer.OfferID
        and product.Active = 1
        and product.ActiveProduct = 1 
    inner join MasterData.PT_TMPRDPCK as productPacks
        on productPacks.PRODUCTPACKID = product.ProductCode
        and productPacks.ACTIVERECORD = 'Yes' 
    inner join TransactionalData.PriceConditionClassification as priceConditionClassification  
        on priceConditionClassification.CountryCode = product.CountryCode
        and priceConditionClassification.Classification = tender.Classification
        and priceConditionClassification.Division = offer.Division
        and priceConditionClassification.isMain = 'true' 
        and (priceConditionClassification.ProductType = 'All' or priceConditionClassification.ProductType = productPacks.ProductType)
    inner join MasterData.PT_TMINST as institute 
        on tender.InstituteID = institute.InstituteID
    inner join MasterDataViews.MostRecentMasterPricesView as masterPrices 
        on product.ProductCode = masterPrices.ProductPackId
        and product.CountryCode = masterPrices.CountryCode    
    inner join TransactionalData.PriceCondition as priceCondition 
        on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
        and product.OfferID = priceCondition.OfferID
        and product.ProductCode = priceCondition.ProductCode
    left outer join TransactionalDataViews.TenderFOCView as tenderFOC
        on tender.TenderID = tenderFOC.TenderID
        and offer.OfferID = tenderFOC.OfferID
        and product.ProductCode = tenderFOC.ProductCode
        and institute.InstituteID = tenderFOC.INSTITUTE_ID
    left outer join TransactionalDataViews.TenderRappelView as tenderRappel
        on tender.TenderID = tenderRappel.TenderID
        and offer.OfferID = tenderRappel.OfferID
        and product.ProductCode = tenderRappel.ProductCode
        and institute.InstituteID = tenderRappel.INSTITUTE_ID
    {
        key tender.TenderID,
        key offer.OfferID,
        key product.ProductCode,
        tender.TenderName as TENDER_NAME,
        ifnull(offer.Quotation.OfferDate, CURRENT_DATE) as OFFER_DATE: Date,
        key institute.InstituteID as INSTITUTE_ID,
        institute.InstituteName as INSTITUTE_NAME,
        product.SKU.PRODUCTPACKNAME as PRODUCT_NAME,
        product.Price.OfferPrice *
            case when product.UnitPerPack = 'Unit'
                then product.SKU.PACKFACTOR
                else 1
            end as PACK_PRICE:Double,
        product.Price.OfferPrice *
            case when product.UnitPerPack = 'Unit'
                then 1
                else 1 / product.SKU.PACKFACTOR
            end as UNIT_PRICE:Double,
        priceCondition.PVL as PVL,
        ifnull(tenderFOC.FOC, 'No') as FOC:String(10),
        ifnull(tenderRappel.RAPPEL, 'No') as RAPPEL:String(10),
        priceCondition.ConfidentialPrice as CONFIDENTIAL_PRICE,
        priceCondition.PriceConditionCode as PriceConditionCode,
        priceConditionClassification.ConditionType as PRICE_CONDITION,
        priceCondition.RoyalDecree as ROYALDECREE,
        case 
            when priceConditionClassification.ConditionType = 'PrecioNeto'
                then priceCondition.AdditionalDiscount
            when priceConditionClassification.ConditionType = 'DescuentoComercial' or priceConditionClassification.ConditionType = 'DescuentoEspecial'
                then priceCondition.Discount
            when priceConditionClassification.ConditionType = 'PVL'
                then priceCondition.ConfidentialDiscount
            else priceCondition.Discount 
        end as DISCOUNT: Double,
        priceCondition.ConfidentialDiscount as CONFIDENTIAL_DISCOUNT,
        ifnull(product.Results.Outcome, 'NA') as OUTCOME:String(10)
}where (offer.OfferStatusTable.STATUS = 'Quotation Submitted' or offer.OfferStatusTable.STATUS = 'Results Recorded' or offer.OfferStatusTable.STATUS = 'Delivery Ongoing')
group by tender.TenderID,
    offer.OfferID,
    product.ProductCode,
    tender.TenderName,
    offer.Quotation.OfferDate,
    institute.InstituteID,
    institute.InstituteName,
    product.SKU.PRODUCTPACKNAME,
    product.Price.OfferPrice,
    product.SKU.PACKFACTOR,
    product.UnitPerPack,
    priceCondition.PVL,
    tenderFOC.FOC,
    tenderRappel.RAPPEL,
    priceCondition.ConfidentialPrice,
    priceConditionClassification.ConditionType,
    priceCondition.RoyalDecree,
    priceCondition.PriceConditionCode,
    priceCondition.Discount,    
    product.Results.Outcome,
    priceCondition.AdditionalDiscount,
    priceCondition.ConfidentialDiscount;

@cds.persistence.exists
entity PriceConditionCurrentSectionTaiwanView as select from TransactionalDataViews.StandardTenderHistory{
        key ProductCode,
        key INSTITUTE_ID,
        Currency,
        Price0,
        Price1,
        Level2Discount1,                
        Level2Discount2,
        Price2,
        AnnualDiscountForBranch,
        Level3Discount1,
        Price3,
        AwardedPrice,
        TotalYearlyValueMainCustomer,
        TotalYearlyValueBranch,
        TotalDiscountNHI,
        TotalDiscountInvoice,
        GeneralDiscount_Amount,
        SecondDiscount_Amount

}where OUTCOME = 'Won' and CountryCode = 'TW' and EffectiveDate <= CURRENT_DATE;

@cds.persistence.exists
entity ZuelligExtractView as select from TransactionalData.PT_TMTEND as tender  
        inner join MasterData.PT_TMINST as inst 
            on inst.InstituteID = tender.InstituteID 
            and inst.CountryCode = tender.CountryCode
        left join MasterData.PT_TMINSHIER as hier 
            on hier.InstituteID = tender.InstituteID 
            or hier.ParentInstituteID = tender.InstituteID
        inner join TransactionalData.PT_TMOFRS as offer 
            on tender.TenderID = offer.TenderID
        inner join TransactionalData.PT_TMOFPR as pr 
            on pr.OfferID = offer.OfferID
        inner join TransactionalData.PT_TMQUTO as quotation 
            on quotation.OfferID = offer.OfferID
        inner join TransactionalData.PriceCondition as pc 
            on pc.OfferID = offer.OfferID 
            and pc.ProductCode = pr.ProductCode 
        inner join AdminData.PT_TMUSER as CreatedByUser 
            on CreatedByUser.UserID = offer.SubmittedBy 
        inner join MasterData.PT_TMSKUPRDPCK as sku
             on sku.ProductPackID = pr.ProductCode 
        inner join MasterData.PT_TMPRDPCK as pck 
            on pck.PRODUCTPACKID = pr.ProductCode
        inner join MasterData.PT_TMCTPRDPCK as ctpck 
            on ctpck.COUNTRYCODE = tender.CountryCode
            and ctpck.PRODUCTPACKID = pr.ProductCode
        inner join MasterData.PT_TMREGPR as regpr 
            on regpr.CountryCode = tender.CountryCode 
            and regpr.ProductPackID = pr.ProductCode
        left join MasterData.PT_TMINST as parentInst 
            on parentInst.InstituteID = hier.ParentInstituteID 
            and parentInst.CountryCode = tender.CountryCode {
            key tender.TenderID,
            tender.createdAt,
            key offer.OfferID,
            key offer.CountryCode,
            offer.CreationDate,
            offer.SubmittedBy,
            offer.SubmittedOn,
            CreatedByUser.UserName,
            pr.ProductCode,
            inst.InstituteName,
            inst.InstituteType,
            inst.InstituteID,
            ifnull(inst.External_InstituteId, '') as External_InstituteId,
            ifnull(parentInst.External_InstituteId, '') as ParentInst_External_InstituteId,
            inst.Class,
            ifnull(inst.KAM_Territory, '') as KAM_Territory,
            ifnull(inst.CNPJ, '') as CNPJ,
            hier.ParentInstituteID,
            quotation.EffectiveDate,
            ifnull(pck.PRODUCTPACKNAME, '') as PRODUCTPACKNAME,
            pck.PACKFACTOR,
            sku.SKUCode,
            ifnull(sku.ActiveRecord , '')as Display,
            ifnull(ctpck.BU, '') as BU,
            ifnull(pc.Price0, 0) as Price0,
            ifnull(pc.Price1, 0) as Price1,
            ifnull(pc.Price2, 0) as Price2,
            ifnull(pc.Price3, 0) as Price3,
            ifnull(pc.TotalDiscountNHI, 0) as TotalDiscountNHI,
            ifnull(pc.Level2Discount1, 0) as Level2Discount1,
			ifnull(pc.Level2Discount2, 0) as Level2Discount2,
            ifnull(pc.Level3Discount1, 0) as Level3Discount1,
			ifnull(pc.GeneralDiscount_Amount, 0) as GeneralDiscount_Amount,
    		ifnull(pc.SecondDiscount_Amount, 0) as SecondDiscount_Amount,
    		ifnull(pc.FreeGoods_Amount, 0) as FreeGoods_Amount,
    		ifnull(pc.FreeGoods_Percentage, 0) as FreeGoods_Percentage,
    		ifnull(pc.AnnualDiscount_Percentage, 0) as AnnualDiscount_Percentage,
    		ifnull(pc.AnnualDiscountForBranch, 0) as AnnualDiscountForBranch,
            case when sku.ActiveRecord = 'Yes'
                then 'Active'
                else 'Suspend'
            end as Status: String,
            ifnull(regpr.RegisteredPrice, 0) as RegisteredPrice
    }where offer.OfferStatusTable.STATUS = 'Results Recorded' and quotation.EffectiveDate <= CURRENT_DATE and tender.CountryCode = 'TW' and tender.Active = 1 and offer.Active = 1
    union select from TransactionalData.PT_TMTEND as tender  
        inner join MasterData.PT_TMINST as inst 
            on inst.InstituteID = tender.InstituteID 
            and inst.CountryCode = tender.CountryCode
        left join MasterData.PT_TMINSHIER as hier 
            on hier.InstituteID = tender.InstituteID 
            or hier.ParentInstituteID = tender.InstituteID
        inner join TransactionalData.PT_TMOFRS as offer 
            on tender.TenderID = offer.TenderID
        inner join TransactionalData.PT_TMOFPR as pr 
            on pr.OfferID = offer.OfferID
        inner join TransactionalData.PT_TMQUTO as quotation 
            on quotation.OfferID = offer.OfferID
        inner join TransactionalData.PriceCondition as pc 
            on pc.OfferID = offer.OfferID 
            and pc.ProductCode = pr.ProductCode 
        inner join AdminData.PT_TMUSER as CreatedByUser 
            on CreatedByUser.UserID = offer.SubmittedBy 
        inner join MasterData.PT_TMSKUPRDPCK as sku
             on sku.ProductPackID = pr.ProductCode 
        inner join MasterData.PT_TMPRDPCK as pck 
            on pck.PRODUCTPACKID = pr.ProductCode
        inner join MasterData.PT_TMCTPRDPCK as ctpck 
            on ctpck.COUNTRYCODE = tender.CountryCode
            and ctpck.PRODUCTPACKID = pr.ProductCode
        inner join MasterData.PT_TMREGPR as regpr 
            on regpr.CountryCode = tender.CountryCode 
            and regpr.ProductPackID = pr.ProductCode
        inner join TaiwanInstituteInBranchView as branch
	        on hier.ParentInstituteID = branch.ParentInstituteID
	        and tender.InstituteID <> branch.InstituteID
            and tender.Custom.String_3 LIKE '%' || branch.InstituteName || '%'
        left join MasterData.PT_TMINST as parentInst 
            on parentInst.InstituteID = hier.ParentInstituteID 
            and parentInst.CountryCode = tender.CountryCode {
            key tender.TenderID,
            tender.createdAt,
            key offer.OfferID,
            key offer.CountryCode,
            offer.CreationDate,
            offer.SubmittedBy,
            offer.SubmittedOn,
            CreatedByUser.UserName,
            pr.ProductCode,
            branch.InstituteName,
            branch.InstituteType,
            branch.InstituteID,
            ifnull(branch.External_InstituteId, '') as External_InstituteId,
            ifnull(parentInst.External_InstituteId, '') as ParentInst_External_InstituteId,
            branch.Class,
            ifnull(branch.KAM_Territory, '') as KAM_Territory,
            ifnull(branch.CNPJ, '') as CNPJ,
            hier.ParentInstituteID,
            quotation.EffectiveDate,
            ifnull(pck.PRODUCTPACKNAME, '') as PRODUCTPACKNAME,
            pck.PACKFACTOR,
            sku.SKUCode,
            ifnull(sku.ActiveRecord , '')as Display,
            ifnull(ctpck.BU, '') as BU,
            ifnull(pc.Price0, 0) as Price0,
            ifnull(pc.Price1, 0) as Price1,
            ifnull(pc.Price2, 0) as Price2,
            ifnull(pc.Price3, 0) as Price3,
            ifnull(pc.TotalDiscountNHI, 0) as TotalDiscountNHI,
            ifnull(pc.Level2Discount1, 0) as Level2Discount1,
			ifnull(pc.Level2Discount2, 0) as Level2Discount2,
			ifnull(pc.Level3Discount1, 0) as Level3Discount1,
			ifnull(pc.GeneralDiscount_Amount, 0) as GeneralDiscount_Amount,
    		ifnull(pc.SecondDiscount_Amount, 0) as SecondDiscount_Amount,
    		ifnull(pc.FreeGoods_Amount, 0) as FreeGoods_Amount,
    		ifnull(pc.FreeGoods_Percentage, 0) as FreeGoods_Percentage,
    		ifnull(pc.AnnualDiscount_Percentage, 0) as AnnualDiscount_Percentage,
    		ifnull(pc.AnnualDiscountForBranch, 0) as AnnualDiscountForBranch,
            case when sku.ActiveRecord = 'Yes'
                then 'Active'
                else 'Suspend'
            end as Status: String,
            ifnull(regpr.RegisteredPrice, 0) as RegisteredPrice
    }
    where offer.OfferStatusTable.STATUS = 'Results Recorded' and quotation.EffectiveDate <= CURRENT_DATE and tender.CountryCode = 'TW' and tender.Active = 1 and offer.Active = 1;
@cds.persistence.exists
    entity TaiwanInstituteInBranchView as select from MasterData.PT_TMINST as inst
        inner join MasterData.PT_TMINSHIER as hier on inst.InstituteID = hier.InstituteID {
        key hier.ParentInstituteID,
        key hier.InstituteID,
        key CountryCode,
            inst.InstituteName,
            inst.PaymentTerms,
            inst.CNPJ,
            inst.KAM_Territory,
            inst.External_InstituteId,
            inst.Class,
            inst.InstituteType
    }
    where CountryCode = 'TW';

@cds.persistence.exists
    entity StandardTenderFOCInformation as select from TransactionalData.PT_TMTEND as tender
    inner join TransactionalData.PT_TMOFRS as offer 
        on offer.TenderID = tender.TenderID
        and offer.Active = 1
    inner join TransactionalData.PT_TMOFPR as product 
        on product.OfferID = offer.OfferID
        and product.Active = 1
        and product.ActiveProduct = 1
    inner join TransactionalData.PriceConditionClassification as priceConditionClassification  
        on priceConditionClassification.CountryCode = product.CountryCode
        and priceConditionClassification.Classification = tender.Classification
        and priceConditionClassification.Division = offer.Division
        and priceConditionClassification.isMain = 'true' 
        and priceConditionClassification.ProductType = 'All'
    inner join MasterData.PT_TMINST as institute 
        on tender.InstituteID = institute.InstituteID   
    inner join TransactionalData.PriceCondition as priceCondition 
        on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
        and product.OfferID = priceCondition.OfferID
        and product.ProductCode = priceCondition.ProductCode
    left outer join TransactionalData.FreeGoodsOther as foc
        on foc.PriceCondition.ID = priceCondition.ID
    inner join MasterData.PT_TMPRDPCK as productPacks
        on productPacks.PRODUCTPACKID = foc.ProductPackId
        and productPacks.ACTIVERECORD = 'Yes' 
    {
        tender.TenderID,
        key offer.OfferID,
        key tender.CountryCode,
        product.ProductCode,
        foc.ProductPackId,
        offer.Currency,
        product.SKU.PRODUCTPACKNAME as MainProductName,
        productPacks.PRODUCTPACKNAME as FOCProductName,
        case
            when foc.FreeGoodsOther_ABS_PCT = 'PCT'
                then round(100 * foc.FreeGoodsOther, 2) || '%'
            when foc.FreeGoodsOther_ABS_PCT = 'ABS'
                then foc.FreeGoodsOther || ' '  || product.UnitPerPack
            when foc.FreeGoodsOther_ABS_PCT = 'STP'
                then foc.FreeGoodsOther || ' '  || product.UnitPerPack
        end as Bonus:String,
        foc.FreeGoodsOther_Step as MinOrderQty,
        foc.FreeGoodsOther_ABS_PCT as Type,
        foc.ADD_INCLUDE
    }
    group by tender.TenderID,
        offer.OfferID,
        tender.CountryCode,
        product.ProductCode,
        product.UnitPerPack,
        foc.ProductPackId,
        offer.Currency,
        productPacks.PRODUCTPACKNAME,
        product.SKU.PRODUCTPACKNAME,
        foc.FreeGoodsOther,
        foc.FreeGoodsOther_Step,
        foc.FreeGoodsOther_ABS_PCT,
        foc.ADD_INCLUDE;

@cds.persistence.exists
    entity ContractDurationBase as select from TransactionalData.NLPriceConditions as nlpc
        inner join TransactionalData.PriceCondition as pc
             on pc.ID = nlpc.PriceCondition.ID{
        pc.OfferID,
        key nlpc.PriceCondition.ID as PriceCondition_ID: UUID,
        nlpc.ContractDuration,
        nlpc.OfferPrice,
        COUNT(nlpc.ContractDuration) OVER (PARTITION BY nlpc.PriceCondition.ID) AS CountContractDuration: Integer,
        MIN(nlpc.ContractDuration) OVER (PARTITION BY nlpc.PriceCondition.ID) AS MinContractDuration: Double,
        MAX(nlpc.ContractDuration) OVER (PARTITION BY nlpc.PriceCondition.ID) AS MaxContractDuration: Double,
        ROW_NUMBER() OVER (PARTITION BY nlpc.PriceCondition.ID ORDER BY nlpc.ContractDuration) AS RowAsc: Integer,
        ROW_NUMBER() OVER (PARTITION BY nlpc.PriceCondition.ID ORDER BY nlpc.ContractDuration DESC) AS RowDesc: Integer,
        FIRST_VALUE(nlpc.OfferPrice) OVER (PARTITION BY nlpc.PriceCondition.ID ORDER BY nlpc.ContractDuration) AS MinOfferPrice: Double,
        FIRST_VALUE(nlpc.OfferPrice) OVER (PARTITION BY nlpc.PriceCondition.ID ORDER BY nlpc.ContractDuration DESC) AS MaxOfferPrice: Double
    };
     entity NLContractDurationsView as select from ContractDurationBase as rd{
        key rd.OfferID,
        key rd.PriceCondition_ID,
        rd.MinContractDuration AS MinContractDuration: Double,
        rd.MinOfferPrice AS MinOfferPrice: Double,
        CASE
            WHEN rd.CountContractDuration = 1 THEN NULL
            WHEN rd.CountContractDuration = 2 THEN (
                SELECT cd.ContractDuration 
                FROM ContractDurationBase AS cd 
                WHERE cd.PriceCondition_ID = rd.PriceCondition_ID 
                AND cd.RowAsc = 2
            )
            ELSE (
                SELECT cd.ContractDuration 
                FROM ContractDurationBase AS cd 
                WHERE cd.PriceCondition_ID = rd.PriceCondition_ID 
                AND cd.RowAsc = 2
            )
        END AS AvgContractDuration: Double,
        CASE
            WHEN rd.CountContractDuration = 1 THEN NULL
            WHEN rd.CountContractDuration = 2 THEN (
                SELECT cd.OfferPrice 
                FROM ContractDurationBase AS cd 
                WHERE cd.PriceCondition_ID = rd.PriceCondition_ID 
                AND cd.RowAsc = 2
            )
            ELSE (
                SELECT cd.OfferPrice 
                FROM ContractDurationBase AS cd 
                WHERE cd.PriceCondition_ID = rd.PriceCondition_ID 
                AND cd.RowAsc = 2
            )
        END AS AvgOfferPrice : Double,
        CASE
            WHEN rd.CountContractDuration = 1 THEN NULL
            WHEN rd.CountContractDuration = 2 THEN NULL
            ELSE rd.MaxContractDuration
        END AS MaxContractDuration : Double,
        CASE
            WHEN rd.CountContractDuration = 1 THEN NULL
            WHEN rd.CountContractDuration = 2 THEN NULL
            ELSE rd.MaxOfferPrice
        END AS MaxOfferPrice : Double
    }GROUP BY 
    rd.OfferID,
    rd.PriceCondition_ID,
    rd.MinContractDuration,
    rd.MinOfferPrice,
    rd.CountContractDuration,
    rd.MaxContractDuration,
    rd.MaxOfferPrice;

    @cds.persistence.exists
    entity NLContractDurationOfferPrices as select from TransactionalData.PT_TMTEND as tender
        inner join TransactionalData.PT_TMOFRS as offer
            on offer.TenderID = tender.TenderID
            and offer.Active = 1
        inner join TransactionalData.PT_TMOFPR as pr
            on pr.OfferID = offer.OfferID
            and pr.Active = 1
        inner join TransactionalData.PriceCondition as pricecondition
            on pricecondition.OfferID = pr.OfferID
            and pricecondition.ProductCode = pr.ProductCode
        left join TransactionalData.NLPriceConditions as nlpc1
            on nlpc1.PriceCondition.ID = pricecondition.ID
            and nlpc1.ContractDuration= tender.Custom.Integer_1
        left join TransactionalData.NLPriceConditions as nlpc2
            on nlpc2.PriceCondition.ID = pricecondition.ID
            and nlpc2.ContractDuration = tender.Custom.Integer_2
        left join TransactionalData.NLPriceConditions as nlpc3
            on nlpc3.PriceCondition.ID = pricecondition.ID
            and nlpc3.ContractDuration = tender.Custom.Integer_3 {
                key pr.OfferID,
                key pr.ProductCode,
                tender.Custom.Integer_1 as ContractDuration_1: Double,
                nlpc1.OfferPrice as OfferPrice_1: Double,
                tender.Custom.Integer_2 as ContractDuration_2: Double,
                nlpc2.OfferPrice as OfferPrice_2: Double,
                tender.Custom.Integer_3 as ContractDuration_3: Double,
                nlpc3.OfferPrice as OfferPrice_3: Double
    }where tender.CountryCode = 'NL';


@cds.persistence.exists
    entity ProductTotalAmount as select from TransactionalData.PT_TMOFPR {
        key ProductCode,
        key OfferID,
        CountryCode,
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
        end as TotalAmount:Double
    };