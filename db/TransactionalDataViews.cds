namespace com.bayer.SXTENDER.TransactionalDataViews;

using { User, Country, managed } from '@sap/cds/common';
using { com.bayer.SXTENDER.AdminData } from './AdminData';
using { com.bayer.SXTENDER.MasterData } from './MasterData';
using { com.bayer.SXTENDER.MasterDataViews } from './MasterDataViews';
using { com.bayer.SXTENDER.TransactionalData } from './TransactionalData';
using { com.bayer.SXTENDER.MasterDataLatestValues } from './MasterDataLatestValues';
using { com.bayer.SXTENDER.PricingAppData } from './PricingAppData';
using { com.bayer.SXTENDER.BrazilContractingData } from './BrazilContractingData';

entity LatestApprovalRequests as select from TransactionalData.PT_TMAPPRST as approvals{
    key approvals.OfferId,
    key approvals.ApproverEmailID,
    key approvals.ApproverType,
    max(approvals.Statustime) as MaxStatusTime:DateTime
}where approvals.Active = 1
group by approvals.OfferId,
    approvals.ApproverEmailID,
    approvals.ApproverType;

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

entity TenderOffers as select from TransactionalData.PT_TMTEND as tender 
inner join TransactionalData.PT_TMOFRS as ActiveInactiveOffers
    on ActiveInactiveOffers.TenderID = tender.TenderID {
    key tender.TenderID as TENDERID,
    max(ActiveInactiveOffers.TenderOfferNo) + 1 as NEXTOFFERID:Integer
}group by tender.TenderID;

entity OfferRevisions as select from TransactionalData.PT_TMOFRS as offer{
    key offer.TenderID as TENDERID,
    key offer.TenderOfferNo as TENDEROFFERNO,
    max(offer.RevisedOfferNo) + 1 as NEXTREVISEDOFFERNO:Integer,
    max(offer.ContinuationOfferNo) + 1 as NEXTCONTINUEDOFFERNO:Integer
}group by offer.TenderID, offer.TenderOfferNo;

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

entity CountryTenderNo as select from MasterData.PT_TMCTRY as country
left outer join TransactionalData.PT_TMTEND as tender on country.CountryCode = tender.CountryCode and (SUBSTRING(tender.TenderID, INSTR(tender.TenderID, '-', -1, 2) + 1, 2) = SUBSTRING(CURRENT_DATE, 3, 2)){
    key country.CountryCode as COUNTRY_CODE,
    ifnull(max(tender.TenderNo), 1000) + 1 as NEXT_TENDER_NO:Integer
}where country.CountryCode is not null
group by country.CountryCode;

//EFRCL- 289937- MEA-Kindly exclude Patient Access Programs and Bonus letters from the offer history section at the bottom of the Financial Offer Tab
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

entity ResultsWithNegotiation as select OfferID, ProductCode from TransactionalData.PT_TMTRRES where Active = 1 and Outcome = 'FOC negotiation';
entity ResultsWithAppealInProgress as select TenderID, OfferID, ProductCode from TransactionalData.PT_TMTRRES where Active = 1 and Outcome = 'Appeal in Progress';

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
                    else offer.OfferStatusTable.STATUS 
            end
        else offer.OfferStatusTable.STATUS 
    end as STATUS:String(255)
}where offer.OfferStatusTable.Active = 1
group by offer.OfferID, offer.WholesaleOffer, offer.OfferStatusTable.STATUS; //group by missing?

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

entity BrandsInTender as select from TransactionalData.PT_TMTEND as tender{
    tender.CountryCode as COUNTRYCODE,
    key tender.TenderID as TENDERID,
    key tender.Offer.Product.SKU.Product.HLEVEL4_CODE as BRANDID,
    key tender.Offer.OfferID as OFFERID
}
where tender.Active = 1
and tender.Offer.Active = 1
and tender.Offer.Product.Active = 1;
//EHQUT-397790-Italy-Search function is slow and system crashes
//EHQUT-189207-Creation Date instead of BidDueDate on main page
//EHQUT-197392-MEA - additional edit access to Tender Results and Delivery Tracking tabs
//EFRCL-283873- Italy replace Publication date with Termination date
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
    tender.SubmittedOn as CREATION_DATE, 
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

entity OfferProductPlus as select from TransactionalData.PT_TMOFPR as offerProduct{
    *,
    offerProduct.SKU.Product.HLEVEL4_CODE as HLEVEL4_CODE,
    offerProduct.Offer.Currency as CURRENCY,
    offerProduct.Offer.Tender.TenderChannel as TENDER_CHANNEL,
    offerProduct.Offer.DistributorID as DISTRIBUTOR_ID,
    offerProduct.Offer.Tender.InstituteID as INSTITUTE_ID
};
//EITOG-215125-MEA - budgeted profitability for 2023 to be maintained at the product pack level
entity OfferProductConsolidation as select from OfferProductPlus as offerProduct
left outer join MasterDataViews.DirectBrand as directBrand
    on offerProduct.INSTITUTE_ID = directBrand.INSTITUTE_ID
    and offerProduct.HLEVEL4_CODE = directBrand.BRAND_ID
    and offerProduct.DISTRIBUTOR_ID = directBrand.DISTRIBUTOR_ID
    and offerProduct.CountryCode = directBrand.COUNTRY_CODE     
left outer join MasterDataViews.DistributorBrand as distributorBrand
    on offerProduct.HLEVEL4_CODE = distributorBrand.BRAND_ID
    and offerProduct.DISTRIBUTOR_ID = distributorBrand.DISTRIBUTOR_ID
left outer join MasterDataLatestValues.VWBUDGETEDPROFITABILITY as profitability
    on offerProduct.HLEVEL4_CODE = profitability.HLEVEL4_CODE 
    and offerProduct.CountryCode = profitability.COUNTRYCODE
    and offerProduct.ProductCode =profitability.PRODUCTPACKID
left outer join MasterDataLatestValues.VW_MASTER_APPROVED_PRICE as approved 
    on offerProduct.ProductCode = approved.PRODUCT_ID
    and offerProduct.CountryCode = approved.COUNTRY_CODE
    and offerProduct.CURRENCY = approved.CURRENCY
left outer join CountryMinPrice as minPrice
    on offerProduct.ProductCode = minPrice.PRODUCT_ID
    and offerProduct.CountryCode = minPrice.COUNTRY_CODE
    and offerProduct.CURRENCY = minPrice.CURRENCY
left outer join AccountMinPrice as accountPrice
    on offerProduct.ProductCode = accountPrice.PRODUCT_ID
    and offerProduct.CountryCode = accountPrice.COUNTRY_CODE
    and offerProduct.INSTITUTE_ID = accountPrice.INSTITUTE_ID
    and offerProduct.CURRENCY = accountPrice.CURRENCY
left outer join MasterDataViews.MostRecentSkuCodeForProductPack as sku 
    on offerProduct.ProductCode = sku.ProductPackID 
    and offerProduct.CountryCode = sku.CountryCode
left outer join TransactionalData.ProductPricing as productPricing
    on offerProduct.OfferID = productPricing.OfferID
    and offerProduct.ProductCode = productPricing.ProductCode
    and offerProduct.CountryCode = productPricing.CountryCode
{
    offerProduct.TenderID as TENDERID,
    offerProduct.ProductCode,
    key offerProduct.OfferID as OFFERID,
    key offerProduct.SKU.PRODUCTPACKID as PRODUCTID,
    key offerProduct.LotID as LOTID,
    offerProduct.OfferType as OfferType,
    case offerProduct.AlternateOfferYN
        when 'Alternative to quoted products' then '**'
        when 'Alternative to requested products' then '*'
        else ''
    end || offerProduct.SKU.PRODUCTPACKNAME as PRODUCTNAME:String(500),
    offerProduct.SKU.Product.HLEVEL1_NAME as DIVISION,
	offerProduct.SKU.Product.HLEVEL4_CODE as BRANDID,
	offerProduct.SKU.Product.HLEVEL4_NAME as BRANDNAME,
    offerProduct.SKU.Product.HLEVEL6_NAME as PRODUCT_UNIT_NAME, // (thailand) add to cat-service
    sku.SKU,
    offerProduct.Reference as CODE,
    offerProduct.SKU.ProductGenericName as PRODUCTGENERICNAME,
	offerProduct.SKU.PACKFACTOR as PACKSIZE,
	offerProduct.SKU.CONCENTRATION as DOSAGE,
	offerProduct.SKU.UOM as UOM,
	offerProduct.SKUCountry.COUNTRYOFORIGIN as COUNTRYOFORIGIN,
	offerProduct.SKUCountry.MANUFACTURER as MANUFACTURER,
	offerProduct.SKUCountry.SHELFLIFE as SHELFLIFE,
	offerProduct.SKU.PRESENTATION as PRESENTATION,
    offerProduct.SKU.MoleculeName as MOLECULE_NAME,
    offerProduct.SKU.ProductFullDescription as PRODUCT_FULL_DESCRIPTION,
	offerProduct.SKUCountry.VTATax as VAT,
    ifnull(offerProduct.SKUCountry.COMMENT, '') as PRODUCT_COMMENT:String(500),

    /* Start of missing SKU & SKUCountry fields*/
    offerProduct.SKU.ACTIVERECORD as ACTIVERECORD,
    offerProduct.SKU.HLEVEL6_CODE as HLEVEL6_CODE,
    offerProduct.SKU.PCIName as PCI_NAME,
    offerProduct.SKU.ACTIVE_SUBSTANCE as ACTIVE_SUBSTANCE,
    offerProduct.SKU.ProductType as PRODUCT_TYPE,

    offerProduct.SKUCountry.COUNTRYPRODUCTPACKID as COUNTRYPRODUCTPACKID,
    offerProduct.SKUCountry.ACTIVERECORD as SKUCOUNTRY_ACTIVERECORD,
    offerProduct.SKUCountry.Presentation_2 as PRESENTATION_2,
    offerProduct.SKUCountry.GOV_CODE as GOV_CODE,
    offerProduct.SKUCountry.CODE1 as CODE1,
    offerProduct.SKUCountry.CODE2 as CODE2,
    offerProduct.SKUCountry.CODE3 as CODE3,
    /* End of missing SKU & SKUCountry fields*/

	offerProduct.UnitPerPack as UNIT,
    offerProduct.RequestedVolume as REQUESTED_VOLUME,
	offerProduct.SORTER as SORTER,
	offerProduct.Offer.Currency as CURRENCY,
	offerProduct.FirstShipment as FIRST_SHIPMENT,
    offerProduct.NoofLots as NUMBER_LOTS,
    offerProduct.IntervalBetweenShipments as INTERVAL_SHIPMENTS,
	offerProduct.PaymentTerms as PAYMENT_TERMS,
	offerProduct.INCOTerms as INCO_TERMS,
    offerProduct.Line as LINE,
    offerProduct.Reference as REFERENCE,
    offerProduct.IbizWorkflowID as IBIZWORKFLOWID,
    case when offerProduct.TENDER_CHANNEL = 'Distributor'
        then
            case when offerProduct.PaymentTerms <> distributorBrand.PAYMENT_TERMS or offerProduct.INCOTerms <> distributorBrand.INCO_TERMS then 0 else 1 end
        else
            case when offerProduct.PaymentTerms <> directBrand.PAYMENT_TERMS or offerProduct.INCOTerms <> directBrand.INCO_TERMS then 0 else 1 end
    end as IS_DEFAULT_TERMS:Integer,    
    //case when offerProduct.PAYMENT_UPDATE = 0 then 1 else 0 end as IS_DEFAULT_TERMS:Integer,

    offerProduct.SampleQuantity as SAMPLES,
	offerProduct.Price.RegPrice / (case when offerProduct.UnitPerPack = 'Unit' then offerProduct.SKU.PACKFACTOR else 1 end) as REGISTERED_PRICE:Double,
	offerProduct.Price.OfferPrice as OFFER_PRICE,
	offerProduct.Price.NetofferPrice as NET_OFFER_PRICE,
	offerProduct.Price.NetPrice as NET_PRICE,
    offerProduct.Price.FOC as FOC,
    offerProduct.Price.FOCType as FOC_TYPE,
	offerProduct.Price.FOC_ABS_PCT as FOC_ABS_PCT,
	offerProduct.Price.COGS * offerProduct.Price.SpotRate / (case when offerProduct.UnitPerPack = 'Unit' then offerProduct.SKU.PACKFACTOR else 1 end) as COGS:Double,
	offerProduct.Price.BudgetRate as BUDGET_RATE,
    offerProduct.Price.SpotRate as SPOT_RATE,
    offerProduct.Price.BusinessCasePrice as BUSINESS_CASE_PRICE,
    offerProduct.Price.Discount as DISCOUNT,
    offerProduct.Price.AdditionalDiscount as ADDITIONAL_DISCOUNT,
    offerProduct.Price.StandardDiscount as STANDARD_DISCOUNT,
    offerProduct.Price.FOCStep  as FOC_STEP,
    offerProduct.PreviousApproval.BUSINESS_APPROVED as BUSINESS_APPROVED,
    offerProduct.PreviousApproval.COUNTRY_BUSINESS_APPROVED as COUNTRY_BUSINESS_APPROVED,
    offerProduct.PreviousApproval.LEGAL_APPROVED as LEGAL_APPROVED,
    offerProduct.PreviousApproval.REGIONAL_BUSINESS_APPROVED as REGIONAL_BUSINESS_APPROVED,
    offerProduct.PreviousApproval.REGULATORY_APPROVED as REGULATORY_APPROVED,
    offerProduct.PreviousApproval.SUPPLY_APPROVED as SUPPLY_APPROVED,
    ifnull(approved.APPROVED_PRICE
    * case when approved.UOM = 'Unit' then offerProduct.SKU.PACKFACTOR else 1 end
    / case when offerProduct.UnitPerPack = 'Unit' then offerProduct.SKU.PACKFACTOR else 1 end, 0) as APPROVED_PRICE,
    ifnull(case when offerProduct.UnitPerPack = 'Unit' then minPrice.MIN_UNIT_PRICE else minPrice.MIN_PACK_PRICE end, 0) as MIN_PRICE,
    ifnull(case when offerProduct.UnitPerPack = 'Unit' then accountPrice.MIN_UNIT_PRICE else accountPrice.MIN_PACK_PRICE end, 0) as ACCOUNT_OFFER_PRICE,
    ifnull(case when offerProduct.UnitPerPack = 'Unit' then accountPrice.MIN_UNIT_NET_PRICE else accountPrice.MIN_PACK_NET_PRICE end, 0) as ACCOUNT_NET_OFFER_PRICE,
    0 as FLOOR_PRICE:Double,//Plan for Thailand
    0 as GUIDANCE_PRICE:Double,//Plan for Thailand
    0 as THRESHOLD_VOLUME:Double,//Plan for Mexico
	offerProduct.SKUCountry.REGISTERED as IS_REGISTERED,
	case when offerProduct.AlternateOfferYN = 'Alternative to quoted products' then 1 else 0 end as IS_ALTERNATIVE_QUOTED:Integer,
	case when offerProduct.AlternateOfferYN = 'Alternative to requested products' then 1 else 0 end as IS_ALTERNATIVE_REQUESTED:Integer,
	ifnull(offerProduct.PreviousApproval.NEW_APPROVAL, 1) as NEW_APPROVAL:Integer,
    ifnull(profitability.PROFITABILITY, -1) as BUDGETED_PROFITABILITY:Double,
    offerProduct.Price.FOC_Bundled_1 as FOC_BUNDLED_1,
    offerProduct.Price.FOC_ABS_PCT_Bundled_1 as FOC_BUNDLED_1_ABS_PCT,
    offerProduct.Price.Bundled_1_SKU.PRODUCTPACKNAME as FOC_BUNDLED_1_PRODUCT_NAME,
    offerProduct.Price.Bundled_1_SKU.PACKFACTOR as FOC_BUNDLED_1_PACKSIZE,
    offerProduct.Price.Bundled_1_Cogs.COGS * offerProduct.Price.SpotRate / (case when offerProduct.UnitPerPack = 'Unit' then offerProduct.Price.Bundled_1_SKU.PACKFACTOR else 1 end) as FOC_BUNDLED_1_COGS,
    offerProduct.SKUCountry.QTY_THRESHOLD * (case when offerProduct.UnitPerPack = 'Unit' then offerProduct.SKU.PACKFACTOR else 1 end) as QTY_THRESHOLD:Double,
    productPricing.Warranty as Warranty,
    productPricing.AgreementDuration as AgreementDuration,
    productPricing.MonthlyRent as MonthlyRent,
    productPricing.MonthsPerInvoice as MonthsPerInvoice,
    productPricing.ContractStartDate as ContractStartDate, 
    productPricing.ValueOfDevices as ValueOfDevices,
    productPricing.StatusOfDevice as StatusOfDevice,
    productPricing.MinContractual as MinContractual,
    productPricing.MinAnnPurch as MinAnnPurch,
    offerProduct.SKU.ProductClass as ProductClass,
    offerProduct.SKU.ProductDescription as ProductDescription,
    ifnull(offerProduct.PricingPolicy.Value,0) as UK_BUDGETED_PROFITABILITY:Double,
    case when offerProduct.Channel = '1' then 'Bayer' else 'Distributor' end as CHANNEL:String,
    offerProduct.Custom.Integer_1 as PackSizeRequired,
    offerProduct.Custom.Date_1 as EARLIEST_DATE,
    offerProduct.Comment,
    offerProduct.AlternateOfferYN
}where offerProduct.Active = 1 and offerProduct.Offer.Active = 1 and offerProduct.Offer.Tender.Active = 1 and offerProduct.ActiveProduct = 1;

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
          offer.Tender.Country.Region;

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

entity PreApprovedPrices as select from PricingAppData.InstituteGroupPriceLatest as price{
    key price.InstituteGroup.Institutes.InstituteId,
    key price.ProductPackId,
    key price.Currency,
    case when price.UoM = 'Unit' then price.MSP else price.MSP / price.ProductPack.PACKFACTOR end as PriceUnit:Double,
    case when price.UoM = 'Unit' then price.MSP * price.ProductPack.PACKFACTOR else price.MSP end as PricePack:Double
};
//EHQUT-CR8
entity ProductPricingView as select from TransactionalData.PT_TMOFRS as offer 
inner join TransactionalData.PT_TMOFPR as product on product.OfferID = offer.OfferID
left outer join TransactionalData.ProductPricing as productPricing 
    on product.CountryCode = productPricing.CountryCode
    and product.ProductCode = productPricing.ProductCode
    and product.OfferID = productPricing.OfferID
    and product.Active = 1
    and product.LotID = productPricing.LotID
left outer join MasterDataViews.MostRecentConsumerPricesView as consumerPrices 
    on product.ProductCode = consumerPrices.ProductPackId
    and product.CountryCode = consumerPrices.CountryCode
left outer join  TransactionalData.PT_TMBDPR as PT_TMBDPR 
    on product.CountryCode = PT_TMBDPR.CountryCode
    and product.ProductCode = PT_TMBDPR.ProductCode
    and product.OfferID = PT_TMBDPR.OfferID
    and product.LotID = PT_TMBDPR.LotID 
left outer join TransactionalData.PriceCondition as priceCondition 
    on product.CountryCode = priceCondition.CountryCode
    and product.ProductCode = priceCondition.ProductCode
    and product.OfferID = priceCondition.OfferID
    and product.Active = 1
    and product.LotID = priceCondition.LotID {
    key offer.OfferID,
    key product.ProductCode,
    key product.CountryCode,
    key product.LotID,
    product.SKU.PRODUCTPACKNAME as ProductPackName,
    product.SKU.PACKFACTOR,
    product.RequestedVolume,
    product.UnitPerPack as UOM,
    product.SORTER,
    product.Cogs.COGS,
    productPricing.ID,
    productPricing.Warranty,
    productPricing.AgreementDuration,
    productPricing.MonthlyRent,
    productPricing.MonthsPerInvoice,
    productPricing.ContractStartDate,
    productPricing.ValueOfDevices,
    productPricing.StatusOfDevice,
    ifnull(PT_TMBDPR.FOC, 0) as FOC:Double,
    productPricing.FreeGoodsOther,
    productPricing.MinContractual,
    productPricing.MinAnnPurch,
    PT_TMBDPR.AdditionalDiscount,
    PT_TMBDPR.NetofferPrice,
    ifnull(PT_TMBDPR.FOC_ABS_PCT, 'ABS') as FOC_ABS_PCT:String(4),
    PT_TMBDPR.FOCStep,
    offer.FOCType,
    offer.Currency,
    product.OfferType,
    product.Channel,
    consumerPrices.ProductPackId,
    consumerPrices.ValidFrom,
	consumerPrices.ValidTo,
	consumerPrices.ConsumerPriceExclPP,
	consumerPrices.ConsumerPriceInclPP,
	consumerPrices.ConsumerPriceExclPU,
	consumerPrices.ConsumerPriceInclPU,
	consumerPrices.VatPerPack,
	consumerPrices.MandatoryDiscount,
    consumerPrices.ExfPriceExclPP,
	consumerPrices.ConfidentialDiscount1,
	consumerPrices.ConfidentialDiscount2,
	consumerPrices.TotalDiscount,
	consumerPrices.MaxPriceNhsPP,
	consumerPrices.MaxPriceNhsPU,
    consumerPrices.FloorPrice,
    priceCondition.PriceConditionClassification.ConditionType as ConditionType,
    case 
        when consumerPrices.ConsumerPriceExclPP is not null
            then
                (consumerPrices.ConsumerPriceExclPP - consumerPrices.MaxPriceNhsPP * (1 - (PT_TMBDPR.AdditionalDiscount/100))) / consumerPrices.ConsumerPriceExclPP
        else null
    end as FinalDiscount: Double,
    case
        when PT_TMBDPR.FOC_ABS_PCT = 'ABS'
            then PT_TMBDPR.FOC
        else PT_TMBDPR.FOC * product.RequestedVolume
    end as focAbsolute:Double,
    case 
        when offer.FOCType = 'FOC 1'
            then product.RequestedVolume - (
                case
                    when PT_TMBDPR.FOC_ABS_PCT = 'ABS'
                        then PT_TMBDPR.FOC
                    else PT_TMBDPR.FOC * product.RequestedVolume
                end
            ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
        else product.RequestedVolume 
    end as paidVolume:Double,
    case 
        when offer.FOCType = 'FOC 2'
            then product.RequestedVolume + (
                case
                    when PT_TMBDPR.FOC_ABS_PCT = 'ABS'
                        then PT_TMBDPR.FOC
                    else PT_TMBDPR.FOC * product.RequestedVolume
                end
            ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
        else product.RequestedVolume 
    end as totalVolume:Double,
    case   
        when PT_TMBDPR.NetofferPrice is not null
            then 
                round(PT_TMBDPR.NetofferPrice * ( 
                    (
                        case 
                            when offer.FOCType = 'FOC 1'
                                then product.RequestedVolume - (
                                    case
                                        when PT_TMBDPR.FOC_ABS_PCT = 'ABS'
                                            then PT_TMBDPR.FOC
                                        else PT_TMBDPR.FOC * product.RequestedVolume
                                    end
                                ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                            else product.RequestedVolume 
                        end
                    ) //=$self.paidVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                    
                / 
                
                (
                    case 
                        when offer.FOCType = 'FOC 2'
                            then product.RequestedVolume + (
                                case
                                    when PT_TMBDPR.FOC_ABS_PCT = 'ABS'
                                        then PT_TMBDPR.FOC
                                    else PT_TMBDPR.FOC * product.RequestedVolume
                                end
                            ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                        else product.RequestedVolume 
                    end
                ) //=$self.totalVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                
                ),2)
        else null
    end as NetPriceFOC:Double,

    case   
        when PT_TMBDPR.NetofferPrice is not null
            then 
                PT_TMBDPR.NetofferPrice * (
                    case 
                        when offer.FOCType = 'FOC 1'
                            then product.RequestedVolume - (
                                case
                                    when PT_TMBDPR.FOC_ABS_PCT = 'ABS'
                                        then PT_TMBDPR.FOC
                                    else PT_TMBDPR.FOC * product.RequestedVolume
                                end
                            ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                        else product.RequestedVolume 
                    end
                ) //=$self.paidVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
        else null
    end as GrossSales:Double,
    case   
        when product.UnitPerPack = 'Pack'
            then product.Cogs.COGS
        else round(product.Cogs.COGS / product.SKU.PACKFACTOR,2)
    end as cogsUoM :Double,
    case   
        when PT_TMBDPR.NetofferPrice is not null
            then 
                (PT_TMBDPR.NetofferPrice * 
                    (
                        case 
                            when offer.FOCType = 'FOC 1'
                                then product.RequestedVolume - (
                                    case
                                        when PT_TMBDPR.FOC_ABS_PCT = 'ABS'
                                            then PT_TMBDPR.FOC
                                        else PT_TMBDPR.FOC * product.RequestedVolume
                                    end
                                ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                            else product.RequestedVolume 
                        end
                    ) //=$self.paidVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                ) - (
                    (
                        case   
                            when product.UnitPerPack = 'Pack'
                                then product.Cogs.COGS
                            else round(product.Cogs.COGS / product.SKU.PACKFACTOR,2)
                        end
                    ) //=$self.cogsUoM but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future) 
                * 
                    (
                        case 
                            when offer.FOCType = 'FOC 2'
                                then product.RequestedVolume + (
                                    case
                                        when PT_TMBDPR.FOC_ABS_PCT = 'ABS'
                                            then PT_TMBDPR.FOC
                                        else PT_TMBDPR.FOC * product.RequestedVolume
                                    end
                                ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                            else product.RequestedVolume 
                        end
                    ) //=$self.totalVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                )
        else null
    end as GrossProfit:Double,
    case   
        when PT_TMBDPR.NetofferPrice is not null
            then 
                round(1 - ((
                    (
                        case   
                            when product.UnitPerPack = 'Pack'
                                then product.Cogs.COGS
                            else round(product.Cogs.COGS / product.SKU.PACKFACTOR,2)
                        end
                    ) //=$self.cogsUoM but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                * 
                    (
                        case 
                            when offer.FOCType = 'FOC 2'
                                then product.RequestedVolume + (
                                    case
                                        when PT_TMBDPR.FOC_ABS_PCT = 'ABS'
                                            then PT_TMBDPR.FOC
                                        else PT_TMBDPR.FOC * product.RequestedVolume
                                    end
                                ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                            else product.RequestedVolume 
                        end
                    ) //=$self.totalVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                ) / (PT_TMBDPR.NetofferPrice * 
                    (
                        case 
                            when offer.FOCType = 'FOC 1'
                                then product.RequestedVolume - (
                                    case
                                        when PT_TMBDPR.FOC_ABS_PCT = 'ABS'
                                            then PT_TMBDPR.FOC
                                        else PT_TMBDPR.FOC * product.RequestedVolume
                                    end
                                ) //=$self.focAbsolute but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                            else product.RequestedVolume 
                        end
                    ) //=$self.paidVolume but this syntax gave problems during deploy thats why we copy it (maybe solve it in node.js in future)
                ) ),2) 
        else null
    end as GrossMargin:Double,
    product.ActiveProduct,
    priceCondition.CommercialProposal
}where offer.Active = 1;

/**
 * This view contains calculated fields used on the Spain financial offers page
 */
//CR2
entity PriceConditionView as select from TransactionalData.PT_TMTEND as tender 
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
inner join MasterData.PT_TMINST as institute 
    on tender.InstituteID = institute.InstituteID 
left outer join TransactionalData.PriceCondition as priceCondition 
    on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
    and product.OfferID = priceCondition.OfferID
    and product.ProductCode = priceCondition.ProductCode
left outer join MasterData.RoyalDecree as royalDecree
    on product.ProductCode = royalDecree.ProductPackID 
    and royalDecree.ValidTo > CURRENT_DATE 
left outer join MasterDataViews.MostRecentMasterPricesView as masterPrices 
    on product.ProductCode = masterPrices.ProductPackId
    and product.CountryCode = masterPrices.CountryCode
left outer join MasterDataLatestValues.ActiveChannelProductPolicies as channelproductpolicies 
    on product.ProductCode = channelproductpolicies.ProductPackID
    and product.CountryCode = channelproductpolicies.CountryCode
    and institute.InstituteType = channelproductpolicies.ChannelName
    {
    key product.TenderID,
    key offer.OfferID,
    key product.ProductCode,
    priceCondition.ID as ExistingPriceConditionID: UUID,
    priceCondition.PriceConditionClassification.ID as PriceConditionClassificationID:UUID,
    tender.CountryCode,
    priceCondition.PriceConditionCode,
    key priceConditionClassification.ConditionType,
    priceConditionClassification.Classification,
    priceConditionClassification.Division,
    priceConditionClassification.isMain,
    //product.RegisteredPrice.REGISTERED_PRICE as PVL,
    product.RegisteredPrice.CURRENCY as Currency,
    priceCondition.Discount,
    priceCondition.RoyalDecree,
    royalDecree.Percentage as RoyalDecreePercentage,
    ifnull(channelproductpolicies.StandardDiscount,0) as StandardDiscount:Double ,
    case   
        when product.RegisteredPrice.REGISTERED_PRICE is not null
            then  
                product.RegisteredPrice.REGISTERED_PRICE * (1 - channelproductpolicies.StandardDiscount)
        else null
    end as StandardPrice:Double,
    priceCondition.AdditionalDiscount, // calculated in the UI based on User Input
    priceCondition.NetPriceWithoutTaxBeforeDeductionRD,
    priceCondition.NetPriceWithoutTaxAfterDeductionRD, // calculated in the UI based on User Input
    priceCondition.NetPriceWithTaxAfterDeductionRD, // calculated in the UI based on User Input
    priceCondition.NetPriceWithoutTax,
    priceCondition.NetPriceWithTax,
    priceCondition.MaximumPrice,
    case
        when priceCondition.ConfidentialPrice is null
            then masterPrices.YLAP
        else priceCondition.ConfidentialPrice
    end as ConfidentialPrice:Decimal,
    priceCondition.Liquidation,
    priceCondition.RefundDate,
    priceCondition.RoyalDecreeValue, //calculated in UI based on User Input
    priceCondition.RoyalDecreeIncl,
    case 
        when priceCondition.PVL is null
            then masterPrices.YLLP
        else 
            priceCondition.PVL        
    end as PriceConditionPVL:Decimal,
    masterPrices.YLLP as PVL,
    masterPrices.YLAP,
    masterPrices.PRAF_Private,
    masterPrices.PRAF_Public,
    masterPrices.RentalPrice,
    masterPrices.UoM,
    masterPrices.Currency as masterPriceCurrency,
    case
        when tender.CountryCode = 'ES'
            then
                case
                    when institute.ApplicableTaxRate = 'E1'
                        then masterPrices.TaxE1
                    else 
                        masterPrices.TaxES
                end
        else
            product.SKUCountry.VTATax
    end as Tax:hana.REAL,
    priceCondition.MonthlyRentPerUnit,
    priceCondition.AnnualValue,
    priceCondition.ReferencePriceAgreement,
    priceCondition.Settlement.ID as Settlement_ID,
    priceCondition.IsPricingUnlocked
}where tender.Active = 1;

/**
 * This view contains calculated fields used in the Standard Tender application financial offers page
 * for the ConditionType 'Price
 */
entity StandardTenderPriceConditionView as select from TransactionalData.PT_TMTEND as tender 
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
left outer join TransactionalData.PriceCondition as priceCondition 
    on priceConditionClassification.ID = priceCondition.PriceConditionClassification.ID
    and product.OfferID = priceCondition.OfferID
    and product.ProductCode = priceCondition.ProductCode
{
    tender.CountryCode,
    tender.Country.Region,
    tender.Custom.Integer_1 as Custom_Integer_1,
    tender.Custom.Integer_2 as Custom_Integer_2,
    tender.Custom.Integer_3 as Custom_Integer_3,
    key product.TenderID,
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
    key priceConditionClassification.ConditionType,
    priceConditionClassification.Division,
    priceConditionClassification.isMain,
    case 
        when product.UnitPerPack = 'Unit'
            then product.RegisteredPrice.REGISTERED_PRICE / product.SKU.PACKFACTOR
        else product.RegisteredPrice.REGISTERED_PRICE
    end as CurrentBasePrice:Double,
    @Core.Computed: false
    case 
        when product.UnitPerPack = 'Unit'
            then  ifnull(priceCondition.Price0, (product.RegisteredPrice.REGISTERED_PRICE / product.SKU.PACKFACTOR))
        else ifnull(priceCondition.Price0, product.RegisteredPrice.REGISTERED_PRICE)
    end as BasePrice:Double,
    @Core.Computed: false
    case 
        when priceCondition.Price1 is null or priceCondition.Price1 = 0 and tender.CountryCode = 'TW'
            then 
                case 
                    when product.UnitPerPack = 'Unit'
                        then  ifnull(priceCondition.Price0, (product.RegisteredPrice.REGISTERED_PRICE / product.SKU.PACKFACTOR))
                        else ifnull(priceCondition.Price0, product.RegisteredPrice.REGISTERED_PRICE)
                end
        else
            ifnull(priceCondition.Price1, 0)
    end as OfferPrice:Decimal,
    @Core.Computed: false
    ifnull(priceCondition.Level1Discount1, 0) as Discount:Double,
    @Core.Computed: false
    case   
        when priceCondition.Level2Discount1 is null
            then ifnull(offer.Distributor.CommissionRate,0) / 100
        else priceCondition.Level2Discount1
    end as Deductions:Double,
    @Core.Computed: false
    ifnull(priceCondition.Price2, 0) as NetPrice:Decimal, 
    priceCondition.NetOfferPrice,
    priceCondition.Tax,
    @Core.Computed: false
    ifnull(priceCondition.Price3, 0) as Price3:Decimal,
    @Core.Computed: false
    case   
        when priceCondition.Level3Discount1 is null
            then 
                case 
                    when tender.CountryCode != 'TW' 
                        then ifnull(offer.Distributor.CommissionRate,0) / 100
                        else ifnull(priceCondition.Level3Discount1, 0)
                end
        else priceCondition.Level3Discount1
    end as Level3Discount1:Double,
    offer.Currency,
    @Core.Computed: false
    ifnull(priceCondition.Last12MonthsVolumeMainCustomer,1) as Last12MonthsVolumeMainCustomer:Integer,
    @Core.Computed: false
    ifnull(priceCondition.Last12MonthsVolumeBranch, 1) as Last12MonthsVolumeBranch:Integer,
    @Core.Computed: false
    ifnull(priceCondition.AnticipatedYearlyVolumeMainCustomer,1) as AnticipatedYearlyVolumeMainCustomer:Integer,
    @Core.Computed: false
    priceCondition.AnticipatedYearlyVolumeBranch,
    @Core.Computed: false
    ifnull(priceCondition.Level2Discount2,0) as Level2Discount2:Double,
     @Core.Computed: false
    ifnull(priceCondition.TotalDiscountNHI,0) as TotalDiscountNHI:Double,
     @Core.Computed: false
    ifnull(priceCondition.TotalDiscountInvoice,0) as TotalDiscountInvoice:Double,
     @Core.Computed: false
    ifnull(priceCondition.TotalYearlyValueMainCustomer,0) as TotalYearlyValueMainCustomer:Double,
     @Core.Computed: false
    ifnull(priceCondition.TotalYearlyValueBranch,0) as TotalYearlyValueBranch:Double,
     @Core.Computed: false 
    ifnull(priceCondition.AnnualDiscountForBranch,0) as AnnualDiscountForBranch:Double,
     @Core.Computed: false
    ifnull(priceCondition.NegotiationPrice,0) as NegotiationPrice:Double,
     @Core.Computed: false 
    ifnull(priceCondition.GeneralDiscount_Amount,0) as GeneralDiscount_Amount:Double,
     @Core.Computed: false
    ifnull(priceCondition.SecondDiscount_Amount,0) as SecondDiscount_Amount:Double,
     @Core.Computed: false
    ifnull(priceCondition.AnnualDiscount_Percentage,0) as AnnualDiscount_Percentage:Double,
     @Core.Computed: false
    ifnull(priceCondition.FreeGoods_Amount,0) as FreeGoods_Amount:Double,
     @Core.Computed: false
    ifnull(priceCondition.FreeGoods_Percentage,0) as FreeGoods_Percentage:Double,
    priceCondition.NLPriceConditionType
}where tender.Active = 1;
//CR2
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
            CUSTOM_REMARKS        : String(500) not null;
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
            ClientComment          : String(500);
            Comment                : String(500);
            Regions                : String;
            InternalDueDate        : Date;
            ExpectedAwardDate      : Date;
            Contract_Length1       : Integer; //PT_TMTEND/CUSTOM_INTEGER_1
            Contract_Length2       : Integer; //PT_TMTEND/CUSTOM_INTEGER_2
            Contract_Length3       : Integer; //PT_TMTEND/CUSTOM_INTEGER_3
            ApproverTypes         : Association to many MasterData.ApproverTypes
                                        on ApproverTypes.CountryCode = $self.COUNTRYCODE;
    };


     //Transactional Data Services
    // EFRCL- 268955-Spain - correct mistakes on Commercial agreement templates
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
            ContractDuration_1                          : Double;
            ContractDuration_2                          : Double;
            ContractDuration_3                          : Double;
            OfferPrice_1                                : Double;
            OfferPrice_2                                : Double;
            OfferPrice_3                                : Double;
            Discount_1                                  : Double;
            Discount_2                                  : Double;
            Discount_3                                  : Double;
            NLPriceConditionType                        : String;
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
    {
    key tender.TenderID,
    key offer.OfferID,
    key product.ProductCode,
    key tender.CountryCode,
    offer.Currency,
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
    product.Results.AwardedPrice,
    offer.OfferStatusTable.STATUS as OfferStatus,
    CASE 
        when (product.ProductCode = foc.ProductPackId) 
            then 'Yes' 
            else 'No'
    end as FOC:String(3),
    ifnull(product.Results.Outcome, 'NA') as OUTCOME:String(10)
    }
    where offer.OfferStatusTable.STATUS = 'Results Recorded'
    group by tender.TenderID,
        offer.OfferID,
        product.ProductCode,
        tender.CountryCode,
        tender.TenderName,
        offer.Currency,
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
        offer.OfferStatusTable.STATUS,
        product.Results.Outcome,
        foc.ProductPackId;

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