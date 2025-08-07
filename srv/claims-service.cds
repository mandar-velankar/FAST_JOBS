using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using {com.bayer.SXTENDER.TransactionalDataViews} from '../db/TransactionalDataViews';
using { com.bayer.SXTENDER.ClaimsData } from '../db/ClaimsData';
using { com.bayer.SXTENDER.MasterData } from '../db/MasterData';
using { com.bayer.SXTENDER.MasterDataViews } from '../db/MasterDataViews';
using { com.bayer.SXTENDER.ClaimsViews } from '../db/ClaimsViews';
using { com.bayer.SXTENDER.AdminData } from '../db/AdminData';

service ClaimsService @(path: 'claims') @(requires:['f_tndr_cag_admin','f_tndr_cag_claims_user','f_tndr_cag_technical_user','authenticated-user']){

    @cds.persistence.exists
    entity PT_TMOFRS as projection on TransactionalData.PT_TMOFRS;
    @cds.persistence.exists
    entity PT_TMDIST as projection on MasterData.PT_TMDIST;
    @cds.persistence.exists
    entity Country as projection on MasterData.PT_TMCTRY;
    @cds.persistence.exists
    entity Users as projection on AdminData.PT_TMUSER;
    @cds.persistence.exists
    entity CountryTenderBrands @readonly as projection on TransactionalDataViews.CountryTenderBrands;

    @cds.persistence.exists
    entity ClaimFiles @(cds.redirection.target:true) as projection on ClaimsData.ClaimFiles;
    @cds.persistence.exists
    entity ClaimData @(cds.redirection.target:true) as projection on ClaimsData.ClaimData;
    @cds.persistence.exists
    entity ClaimFilesView as projection on ClaimsViews.ClaimFilesView;
    @cds.persistence.exists
    entity ClaimDataView as projection on ClaimsViews.ClaimDataView;
    @cds.persistence.exists
    entity ClaimDataCalculatedView as projection on ClaimsViews.ClaimDataCalculatedView;
    @cds.persistence.exists
    entity ExcelTemplate as projection on AdminData.ExcelTemplate;

    @cds.persistence.exists
    entity ContrastAgentSalesData as projection on ClaimsData.ContrastAgentSalesData;
    @cds.persistence.exists
    entity ContrastAgentSalesDataNL as projection on ClaimsData.ContrastAgentSalesDataNL;
    @cds.persistence.exists
    entity SalesReportFile as projection on ClaimsData.SalesReportFile;
    @cds.persistence.exists
    entity SalesReportFileFieldMetaData as projection on ClaimsData.SalesReportFileFieldMetaData;

    @cds.persistence.exists
    entity UserCountries @readonly @(restrict: [
		{grant: '*', to: 'authenticated-user', where: 'User.CWID = $user.id'}
	])as projection on AdminData.PT_TMUSERCTRY {
        *,
        Country: redirected to Country,
        User: redirected to Users,
        User.UserName,
        User.UserEmail
    };

    @cds.persistence.exists
    entity ClaimDataBrandsView as projection on ClaimsViews.ClaimDataBrandsView;

    @cds.persistence.exists
    entity ExtractApprovedClaim{
        key templateId    : String;
        key CountryCode   : String;
        key ClaimFileID   : String;
        key Brand         : String;
        key Status        : String;
        key Type          : String;
            content       : LargeBinary @Core.MediaType : mediaType; //'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            mediaType     : String      @Core.IsMediaType;
    }
    @cds.persistence.exists
    entity ExtractClaimsSales {
        key templateId    : String;
        key CountryCode   : String;
        key DistributorID : String;
        key BrandId       : String;
        key templateName  : String;
        key DateFrom      : String;
        key DateTo        : String;
            content       : LargeBinary @Core.MediaType : mediaType; //'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
            mediaType     : String      @Core.IsMediaType;
    }
    
    @cds.persistence.exists
    entity PLExtractClaimFilesView as projection on ClaimsViews.PLExtractClaimFilesView;
    @cds.persistence.exists
    entity NLExtractClaimFilesView as projection on ClaimsViews.NLExtractClaimFilesView;
    @cds.persistence.exists
    entity ExtractClaimDataView as projection on ClaimsViews.ExtractClaimDataView;

    @cds.persistence.exists
    entity ExtractFASTOffer as select from TransactionalData.PT_TMTEND as tender 
        inner join TransactionalData.PT_TMOFRS as offer 
            on offer.TenderID = tender.TenderID
            and offer.Active = 1
        inner join TransactionalData.PT_TMOFPR as product 
            on product.OfferID = offer.OfferID
            and product.Active = 1 
        inner join TransactionalData.ContractInfomation as contract
            on contract.OfferID = offer.OfferID
            and contract.ProductCode = product.ProductCode
            and contract.Active = true
        inner join MasterData.PT_TMINST as institute 
            on tender.InstituteID = institute.InstituteID{
    	tender.TenderID,
        institute.InstituteID,
        offer.OfferID,
        product.ProductCode,
        tender.CountryCode,
        product.RequestedVolume,
        product.Results.Outcome,
        contract.ContractStartDate,
        contract.ContractEndDate,
        offer.Quotation.EffectiveDate,
        offer.Quotation.ExpiryDate,
        product.Price.OfferPrice,
        product.Price.RegPrice,
        product.SKU.CONCENTRATION,
        product.SKU.Product.HLEVEL4_CODE as BrandId:String,
        product.SKU.Product.HLEVEL4_NAME as BrandName:String
    }
    where product.Results.Outcome = 'Won' and tender.Active = 1 and offer.Active = 1
    group by 
        tender.TenderID,
        institute.InstituteID,
        offer.OfferID,
        product.ProductCode,
        product.RequestedVolume,
        tender.CountryCode,
        product.Results.Outcome,
        contract.ContractStartDate,
        contract.ContractEndDate,
        offer.Quotation.EffectiveDate,
        offer.Quotation.ExpiryDate,
        product.Price.OfferPrice,
        product.Price.RegPrice,
        product.SKU.Product.HLEVEL4_NAME,
        product.SKU.Product.HLEVEL4_CODE,
        product.SKU.CONCENTRATION;

    @cds.persistence.exists
    entity ClaimApproverTypes as projection on ClaimsData.ClaimApproverTypes;
    @cds.persistence.exists
    entity ClaimApprovals @(cds.redirection.target:true) as projection on ClaimsData.ClaimApprovals;
    @cds.persistence.exists
    entity UserClaimApprovals @(restrict: [
		{grant: '*', to: 'authenticated-user', where: 'ApproverCWID = $user.id'}
	])as projection on ClaimsData.ClaimApprovals;
    @cds.persistence.exists
    entity ClaimFileStatusView as projection on ClaimsViews.ClaimFileStatusView;

    @cds.persistence.exists
    entity ExtractFASTOfferNL as select from TransactionalData.PT_TMTEND as tender 
        inner join TransactionalData.PT_TMOFRS as offer 
            on offer.TenderID = tender.TenderID
            and offer.Active = 1
            and offer.ActiveOffer = 1
        inner join TransactionalData.PT_TMOFPR as product 
            on product.OfferID = offer.OfferID
            and product.Active = 1
            and product.ActiveProduct = 1
        inner join TransactionalData.ContractInfomation as contract
            on contract.OfferID = offer.OfferID
            and contract.ProductCode = product.ProductCode
            and contract.Active = true
        inner join TransactionalData.PriceCondition as pc
	        on tender.CountryCode = pc.CountryCode
	    	and product.ProductCode = pc.ProductCode
	    	and offer.OfferID = pc.OfferID
        inner join TransactionalData.NLPriceConditions as nlprice
        	on contract.ContractDuration = nlprice.ContractDuration
        	and pc.ID = nlprice.PriceCondition.ID{
    	tender.TenderID,
        contract.InstituteID,
        contract.ContractStartDate,
        contract.ContractEndDate,
        contract.ContractDuration,
        offer.OfferID,
        product.ProductCode,
        tender.CountryCode,
        product.RequestedVolume,
        product.Results.Outcome,
        offer.Quotation.EffectiveDate,
        offer.Quotation.ExpiryDate,
        nlprice.OfferPrice,
        nlprice.NetPrice,
        nlprice.Discount,
        product.Price.RegPrice,
        product.SKU.CONCENTRATION,
        product.SKU.Product.HLEVEL4_CODE as BrandId:String,
        product.SKU.Product.HLEVEL4_NAME as BrandName:String
    }
    where product.Results.Outcome = 'Won' and tender.Active = 1 and offer.Active = 1
    group by 
        tender.TenderID,
        contract.InstituteID,
        contract.ContractStartDate,
        contract.ContractEndDate,
        contract.ContractDuration,
        offer.OfferID,
        product.ProductCode,
        product.RequestedVolume,
        tender.CountryCode,
        product.Results.Outcome,
        offer.Quotation.EffectiveDate,
        offer.Quotation.ExpiryDate,
        nlprice.OfferPrice,
        nlprice.NetPrice,
        nlprice.Discount,
        product.Price.RegPrice,
        product.SKU.Product.HLEVEL4_NAME,
        product.SKU.Product.HLEVEL4_CODE,
        product.SKU.CONCENTRATION;

    @cds.persistence.exists
    entity ExcelClaimFileSalesReportTemplate as projection on ClaimsData.ExcelClaimFileSalesReportTemplate;
    @cds.persistence.exists
    entity NLExtractClaimDataView as projection on ClaimsViews.NLExtractClaimDataView;

    action approveRejectClaimFiles(claimFile_ID: String, countryCode: String, status: String, claimFileDetailPageURL: String) returns String;
    action deleteClaimFile(claimFile_ID: String) returns String;
}
