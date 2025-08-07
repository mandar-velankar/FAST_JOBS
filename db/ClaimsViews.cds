namespace com.bayer.SXTENDER.ClaimsViews;

using { User, Country, managed, cuid } from '@sap/cds/common';
using { com.bayer.SXTENDER.MasterData } from './MasterData';
using { com.bayer.SXTENDER.AdminData } from './AdminData';
using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using {com.bayer.SXTENDER.TransactionalDataViews} from '../db/TransactionalDataViews';
using { com.bayer.SXTENDER.ClaimsData} from '../db/ClaimsData';
@cds.persistence.exists
entity ClaimFilesView as select from ClaimsData.ClaimFiles as cf
	left join ClaimFilesApprovalsCount as approvalscount
		on approvalscount.ClaimFiles_ID = cf.ID
	left join CountryCurrencyView as ctryCurrency
	    on ctryCurrency.CountryCode = cf.CountryCode
	left join AdminData.PT_TMUSER as user 
		on cf.createdBy = user.UserID{
	key cf.ID,
	key cf.CountryCode,
	cf.createdAt,
	cf.ClaimFileFormat,
    cf.FileName,
    cf.DateFrom,
    cf.DateTo,
    cf.FilePeriod,
    cf.DistributorID,
    cf.DistributorName,
    cf.WholesalerPurchaseAmount,
    cf.NetSales,
    cf.TotalClaimAmount,
    cf.Status,
	ctryCurrency.Currency,
	user.UserName,
    case
		when approvalscount.TotalApprovalsCount > 0
			then cf.ApprovalsCount || '/' || approvalscount.TotalApprovalsCount
		else '0'
	end as ApprovalsCount : String,
	cf.ApprovalsCount as CountApprovalRequest : Integer
};
@cds.persistence.exists
entity ClaimDataView as select from ClaimsData.ClaimData as cd 
	left join CountryCurrencyView as ctryCurrency
	    on ctryCurrency.CountryCode = cd.CountryCode{
	*,
	key cd.ID,
	cd.CountryCode,
	ctryCurrency.Currency
};
@cds.persistence.exists
entity CalculatedBrandVolumes as select from ClaimsData.ClaimData as cd
{
	key cd.OfferID,
	key cd.ProductPackID,
	SUM(cd.BrandContractVolume) OVER (PARTITION BY cd.OfferID, cd.MainInstituteID, cd.BrandId ORDER BY cd.OfferID, cd.MainInstituteID, cd.BrandId) as BrandContractCalculatedVolume : Double,
	SUM(cd.BrandUsedVolume) OVER (PARTITION BY cd.OfferID, cd.MainInstituteID, cd.BrandId ORDER BY cd.OfferID, cd.MainInstituteID, cd.BrandId) as BrandUsedCalculatedVolume : Double
	
};
@cds.persistence.exists
entity ClaimDataCalculatedView as select from ClaimsData.ClaimData as cd
	left join ClaimsMaterialNumbers as materialNumbers
		on materialNumbers.ProductPackID = cd.ProductPackID
	left join MasterData.CountryCurrency as ctryCurrency
	    on ctryCurrency.CountryCode = cd.CountryCode{
    *,
	key cd.ID,
	ctryCurrency.Currency,
	cd.createdAt,
    cd.createdBy,
    cd.modifiedAt,
	cd.modifiedBy,
	cd.OfferID,
	cd.ProductPackID,
	cd.CountryCode,
	cd.UsedVolume,
	ctryCurrency.CountryCode as CurrencyCountry,
    cd.SKU.PRODUCTPACKNAME,
    cd.SKUCountry.GOV_CODE,
	cd.FASTDistributionAgreementType,
    materialNumbers.MaterialNumbers,
	cd.BrandUsedCalculatedVolume,
	cd.BrandContractCalculatedVolume,
	CASE 
        WHEN cd.BrandContractCalculatedVolume != 0 
        THEN cd.BrandUsedCalculatedVolume 
              / 
             cd.BrandContractCalculatedVolume
        ELSE 0 
    END as CalculatedUsage : Double
};
//To get the list of material numbers for each ProductCode
@cds.persistence.exists
entity ClaimsMaterialNumbers as select from MasterData.PT_TMSKUPRDPCK {
	CountryCode,
	ProductPackID,
	STRING_AGG(SKUCode, ',') as MaterialNumbers: String
}where (CountryCode = 'NL' or CountryCode = 'PL') and ActiveRecord = 'Yes'
group by 
	CountryCode,
	ProductPackID;
@cds.persistence.exists
entity ExtractCalculatedBrandVolumes as select from ClaimsData.ClaimData as cd
{
	key cd.OfferID,
	key cd.ProductPackID,
	SUM(cd.BrandContractVolume) OVER (PARTITION BY cd.BrandId ORDER BY cd.BrandId) as BrandContractCalculatedVolume : Double,
	SUM(cd.BrandUsedVolume) OVER (PARTITION BY cd.OfferID, cd.BrandId ORDER BY cd.OfferID, cd.BrandId) as BrandUsedCalculatedVolume : Double
	
};
@cds.persistence.exists
entity ClaimFileOverAllApprovedDateView as select from ClaimsData.ClaimFiles as cf
	inner join ClaimsData.ClaimApprovals as ca
		on ca.ClaimFiles.ID = cf.ID {
	key cf.ID as ClaimFile_ID,
	max(ca.Hierarchy) as Hierarchy: Integer,
	max(ca.modifiedAt) as ClaimApprovalModifiedAt: DateTime
}where (cf.Status <> 'Pending' and cf.Status <> 'Rejected') and ca.Status = 'Approved'
group by cf.ID;
@cds.persistence.exists
entity PLExtractClaimFilesView as select from ClaimsData.ClaimFiles as clmf
	left join ClaimsData.ClaimData as clmd 		
            on clmd.ClaimFiles.ID = clmf.ID 
	inner join MasterData.PT_TMDIST as distributor
    		on clmf.DistributorID = distributor.DistributorID{
		clmf.ID as ClaimFileID,
		clmd.ID as ClaimDataID,
		clmd.OfferID,
		distributor.DistributorID,
		distributor.DistributorName,
		clmd.MainInstituteName,
		clmd.External_InstituteId,
		clmd.Date,
		clmd.Status,
		clmd.Type,
		clmd.Comment,
		clmd.BrandName,
		clmd.PRODUCTPACKNAME,
		clmd.EANNumber,
		clmd.Quantity,
		clmd.BrandUsedVolume as QuantityML: Double,
		clmd.WholesalerPurchasePrice,
		clmd.WholesalerContractPrice,
		clmd.Quantity * clmd.WholesalerPurchasePrice as WholesalerPurchasedAmount: Double, 
		clmd.Quantity * clmd.WholesalerContractPrice as NetSales: Double,
		clmd.BrandContractCalculatedVolume,
		clmd.BrandUsedCalculatedVolume,
		CASE 
			WHEN clmd.BrandContractCalculatedVolume != 0 
			THEN clmd.BrandUsedCalculatedVolume 
				/ 
				clmd.BrandContractCalculatedVolume
			ELSE 0 
		END as ContractBrandUsage : Double,
		clmf.DateFrom,
		clmf.DateTo,
		clmf.CountryCode,
		clmf.Status as ClaimFileStatus : String,
		clmd.BrandId,
		clmd.FASTContractPrice,
		clmd.FASTContractClaim,
		clmd.TotalWholesalerClaim,
		clmd.FASTWholesalerPurchasePrice,
		clmd.NrFaktury,
		clmd.RoznicaCenaZakupuPNM,
		clmd.WartoscPNM,
		clmd.IloscSztukDoWyrownania,
		clmd.NrFakturyZakupu,
		clmd.RowOrder
	}where clmf.CountryCode = 'PL'
	group by
		clmf.ID,
		clmd.ID,
		clmd.OfferID,
		distributor.DistributorID,
		distributor.DistributorName,
		clmd.MainInstituteName,
		clmd.External_InstituteId,
		clmd.Date,
		clmd.Status,
		clmd.Type,
		clmd.Comment,
		clmd.BrandName,
		clmd.PRODUCTPACKNAME,
		clmd.EANNumber,
		clmd.BrandUsedVolume,
		clmd.WholesalerPurchasePrice,
		clmd.WholesalerContractPrice,
		clmd.Quantity,
		clmd.BrandContractCalculatedVolume,
		clmd.BrandUsedCalculatedVolume,
		clmf.DateFrom,
		clmf.DateTo,
		clmf.CountryCode,
		clmf.Status,
		clmd.BrandId,
		clmd.FASTContractPrice,
		clmd.FASTContractClaim,
		clmd.TotalWholesalerClaim,
		clmd.FASTWholesalerPurchasePrice,
		clmd.NrFaktury,
		clmd.RoznicaCenaZakupuPNM,
		clmd.WartoscPNM,
		clmd.IloscSztukDoWyrownania,
		clmd.NrFakturyZakupu,
		clmd.RowOrder;
@cds.persistence.exists
entity NLExtractClaimFilesView as select from ClaimsData.ClaimFiles as cf
	left join ClaimsData.ClaimData as cd 		
            on cd.ClaimFiles.ID = cf.ID
	left join ClaimFileOverAllApprovedDateView as ca
		on ca.ClaimFile_ID = cf.ID{
	cf.ID as ClaimFileID,
	cf.DistributorName,
	cf.DistributorID,
	cf.DateFrom,
	cf.DateTo,
	cf.CountryCode,
	cf.Status as ClaimFileStatus,
	cd.Status as ClaimDataStatus,
	cd.OfferID,
	cd.ID as ClaimDataID,
	cd.MainInstituteName,
	cd.ChildInstituteName,
	cd.Date,
	cd.PRODUCTPACKNAME,
	cd.ProductPackID,
	cd.FASTDistributionArrangement,
	cd.Quantity,
	cd.WholesalerContractPrice,
	cd.FASTContractPrice as OfferPrice: Double,
	cd.WholesalerPurchasePrice,
	cd.FASTWholesalerPurchasePrice,
	cd.WholesalerClaim1,
	cd.FASTClaim1,
	cd.WholesalerClaim2,
	cd.FASTClaim2,
	cd.TotalWholesalerClaim,
	cd.TotalFASTClaim,
	cd.Comment,
	cd.BrandId,
	cd.Type,
	cd.FASTDistributionAgreementType,
	cd.WholesalerDistributionArrangement,
	cd.AppliedWholesalerCorrection,
	cd.FASTPendingCorrection,
	cd.BrandContractVolume,
	cd.UsedVolume,
	cd.PercentageUsage,
	cd.QC1Passed,
	cd.QC2Passed,
	cd.Balance,
	cf.WholesalerPurchaseAmount,
	cf.NetSales,
	cd.EANNumber as GOV_CODE: String,
	cd.BrandName as HLEVEL4_NAME: String,
	cd.SKUCode,
	ca.ClaimApprovalModifiedAt
} where cf.CountryCode = 'NL'
group by cf.ID,
	cf.DistributorName,
	cf.DistributorID,
	cf.DateFrom,
	cf.DateTo,
	cf.CountryCode,
	cf.Status,
	cd.Status,
	cd.OfferID,
	cd.ID,
	cd.MainInstituteName,
	cd.ChildInstituteName,
	cd.Date,
	cd.PRODUCTPACKNAME,
	cd.ProductPackID,
	cd.FASTDistributionArrangement,
	cd.Quantity,
	cd.WholesalerContractPrice,
	cd.FASTContractPrice,
	cd.WholesalerPurchasePrice,
	cd.FASTWholesalerPurchasePrice,
	cd.WholesalerClaim1,
	cd.FASTClaim1,
	cd.WholesalerClaim2,
	cd.FASTClaim2,
	cd.TotalWholesalerClaim,
	cd.TotalFASTClaim,
	cd.Comment,
	cd.BrandId,
	cd.Type,
	cd.FASTDistributionAgreementType,
	cd.FASTWholesalerPurchasePrice,
	cd.FASTContractPrice,
	cd.Product.PriceCondition.OfferPrice,
	cd.Product.SKUCountry.GOV_CODE,
	cd.WholesalerDistributionArrangement,
	cd.AppliedWholesalerCorrection,
	cd.FASTPendingCorrection,
	cd.BrandContractVolume,
	cd.UsedVolume,
	cd.PercentageUsage,
	cd.QC1Passed,
	cd.QC2Passed,
	cd.Balance,
	cf.WholesalerPurchaseAmount,
	cf.NetSales,
	cd.EANNumber,
	cd.BrandName,
	cd.SKUCode,
	ca.ClaimApprovalModifiedAt;
@cds.persistence.exists
entity NLExtractClaimDataView as select from NLExtractClaimFilesView as cd{
	*,
}where cd.ClaimFileStatus = 'Approved (All QC passed)' or cd.ClaimFileStatus = 'Approved (Some QC failed)';
@cds.persistence.exists
entity ClaimFileStatusView as select from ClaimsData.ClaimFiles {
	key ID as CLAIMFILES_ID,
	case
	    when max(case when ClaimApprovals.Status = 'Rejected' then 1 else 0 end) = 1 then 'Rejected'
	    when 
	    	min(case when ClaimApprovals.Status = 'Approved' then 1 else 0 end) = 1 and min(case when ClaimData.Status = 'Passed' then 1 else 0 end) = 1
	    then 'Approved (All QC Passed)'
	    when 
	    	min(case when ClaimApprovals.Status = 'Approved' then 1 else 0 end) = 1 and max(case when ClaimData.Status != 'Passed' then 1 else 0 end) = 1
	    then 'Approved (Some QC Failed)'
	    else 'Pending'
	end as STATUS: String
}group by ID;
@cds.persistence.exists
entity ClaimDataBrandsView as select from ClaimsData.ClaimData{
    key BrandId as BRANDID,
    CountryCode as COUNTRYCODE,
    ID as ClaimData_ID,
    ClaimFiles.ID as ClaimFiles_ID
};

@cds.persistence.exists
entity ExtractClaimDataView  as select from ClaimsData.ClaimFiles as clmf
	left join ClaimsData.ClaimData as clmd 		
            on clmd.ClaimFiles.ID = clmf.ID 
	inner join MasterData.PT_TMPRDPCK as productPack
    		on productPack.PRODUCTPACKID = clmd.ProductPackID
			and productPack.ACTIVERECORD = 'Yes'
	left join MasterData.PT_TMINST as inst 
			on inst.InstituteID = clmd.MainInstituteID 
			and inst.CountryCode = clmd.CountryCode{
			clmf.ID as ClaimFileID,
			clmd.ID as ClaimDataID,
			productPack.PRODUCTPACKNAME,
			clmd.SKUCountry.GOV_CODE,
			clmd.Quantity,
			clmd.WholesalerPurchasePrice,
			clmd.WholesalerContractPrice,
			inst.External_InstituteId,
			clmd.MainInstituteName,
			clmf.ContrastAgentSalesData.NrFaktury,
			clmd.Date,
			clmf.ContrastAgentSalesData.RoznicaCenaZakupuPNM,
			clmf.ContrastAgentSalesData.WartoscPNM,
			clmd.TotalWholesalerClaim,
			clmf.ContrastAgentSalesData.IloscSztukDoWyrownania,
			clmf.ContrastAgentSalesData.NrFakturyZakupu,
			clmd.Product.PriceCondition.Price0,
			clmd.FASTContractPrice,
			clmd.FASTContractClaim,
			clmd.Comment,
			clmd.Status,
			clmd.Type,
			clmd.BrandId,
}
	group by clmf.ID,
			clmd.ID,
			productPack.PRODUCTPACKNAME,
			clmd.SKUCountry.GOV_CODE,
			clmd.Quantity,
			clmd.WholesalerPurchasePrice,
			clmd.WholesalerContractPrice,
			inst.External_InstituteId,
			clmd.MainInstituteName,
			clmf.ContrastAgentSalesData.NrFaktury,
			clmd.Date,
			clmf.ContrastAgentSalesData.RoznicaCenaZakupuPNM,
			clmf.ContrastAgentSalesData.WartoscPNM,
			clmd.TotalWholesalerClaim,
			clmf.ContrastAgentSalesData.IloscSztukDoWyrownania,
			clmf.ContrastAgentSalesData.NrFakturyZakupu,
			clmd.Product.PriceCondition.Price0,
			clmd.FASTContractPrice,
			clmd.FASTContractClaim,
			clmd.Comment,
			clmd.Status,
			clmd.Type,
			clmd.BrandId;

@cds.persistence.exists
entity ClaimFilesApprovalsCount as select from ClaimsData.ClaimApprovals{
	key ClaimFiles.ID as ClaimFiles_ID,
    count(*) as TotalApprovalsCount: Integer
}group by ClaimFiles.ID;
@cds.persistence.exists
entity CountryCurrencyView as select from MasterData.CountryCurrency {
	key CountryCode,
	Currency
};