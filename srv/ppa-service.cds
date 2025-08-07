using { com.bayer.SXTENDER.PricingPolicyData } from '../db/PricingPolicyData';
using { com.bayer.SXTENDER.AdminData } from '../db/AdminData';
using { com.bayer.SXTENDER.MasterDataViews } from '../db/./MasterDataViews';
using { com.bayer.SXTENDER.MasterData } from '../db/MasterData';
using {User,Country,managed,cuid} from '@sap/cds/common';


service PolicyService @(path: 'ppa') @(requires:['f_tndr_cag_admin','f_tndr_cag_ppa_user','f_tndr_cag_technical_user','authenticated-user']){
    
    //OverallStatus
    @cds.persistence.exists
    entity OverallApprovalStatus as projection on PricingPolicyData.OverallApprovalStatus;

    //Brands
    @cds.persistence.exists
    entity Brands as projection on PricingPolicyData.Brands;

    @cds.persistence.exists
    entity BrandPolicies as projection on PricingPolicyData.BrandPolicies;
    @cds.persistence.exists
    entity DraftBrandPolicies as select from BrandPolicies where Status = 'Draft'; 
    @cds.persistence.exists
    entity LatestApprovedBrandPolicies as select from BrandPolicies as Policy 
        inner join PricingPolicyData.LatestApprovedBrandPoliciesSegregate as Approved 
        on Approved.BrandId = Policy.BrandId 
        and Approved.Status = Policy.Status 
        and Approved.ValidTo = Policy.ValidTo {
            key Policy.ID,
                Policy.ValidFrom,
                Policy.ValidTo,
                Policy.CountryCode,
                Policy.Division,
                Policy.BrandId,
                Policy.Status
        };

    @cds.persistence.exists
    entity AggregatedBrandPolicies as select from BrandPolicies as Policy
    left outer join DraftBrandPolicies as DraftPolicies on
         Policy.BrandId = DraftPolicies.BrandId and
         Policy.CountryCode = DraftPolicies.CountryCode and 
         Policy.Division = DraftPolicies.Division
    left outer join LatestApprovedBrandPolicies as ApprovedPolicies on
         Policy.BrandId = ApprovedPolicies.BrandId and
         Policy.CountryCode = ApprovedPolicies.CountryCode and 
         Policy.Division = ApprovedPolicies.Division {
         key Policy.BrandId,
         key Policy.CountryCode,
         key Policy.Division,
         ApprovedPolicies.ID as IDLatestApproved,
         DraftPolicies.ID as IDDraft,
    }group by Policy.BrandId,Policy.CountryCode,Policy.Division,ApprovedPolicies.ID,DraftPolicies.ID;


    //Products
    @cds.persistence.exists
    entity Products as select from PricingPolicyData.BrandProducts as BrandProduct 
    left outer join PricingPolicyData.ActiveProductPolicies as Policy on 
        BrandProduct.ProductPackId = Policy.ProductPackId and 
        BrandProduct.CountryCode = Policy.CountryCode and 
        BrandProduct.Division = Policy.Division and 
        BrandProduct.BrandId  = Policy.BrandId {
            key BrandProduct.BrandId,
            key BrandProduct.CountryCode, 
            key BrandProduct.Division,
            key BrandProduct.ProductPackId,
            Policy.ID as PolicyId, //only a check to see if a brand policy already exists
            BrandProduct.ProductName as ProductName, 
            BrandProduct.ListPrice,
            BrandProduct.Currency,
            case 
                when Policy.MspStatus is null then 'No Policy yet' 
                else Policy.MspStatus 
            end as MspStatus : String(100),
            case 
                when Policy.NspStatus is null then 'No Policy yet' 
                else Policy.NspStatus
            end as NspStatus : String(100),
    } order by ProductName;

    //Policies & Policy prices linked
    @cds.persistence.exists
    entity Policies as projection on PricingPolicyData.ProductPolicies;

    //Approvals for policies
    @cds.persistence.exists
    entity Approvals @(cds.redirection.target:true) as projection on PricingPolicyData.Approvals;

    @cds.persistence.exists
    entity Country as projection on MasterData.PT_TMCTRY;
    @cds.persistence.exists
    entity Users as projection on AdminData.PT_TMUSER;
    
    //Countries where user has accesss to
    @cds.persistence.exists
    entity UserCountry @(restrict: [
		{grant: '*', to: 'authenticated-user', where: 'User.CWID = $user.id'}
	])as projection on AdminData.PT_TMUSERCTRY {
        *,
        Country: redirected to Country,
        User: redirected to Users,
    };

    //divisions distinct 
    @cds.persistence.exists
    entity Divisions as projection on MasterDataViews.Divisions;

    
}