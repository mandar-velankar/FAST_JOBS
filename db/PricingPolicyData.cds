namespace com.bayer.SXTENDER.PricingPolicyData;

using {
    User,
    Country,
    managed,
    cuid
} from '@sap/cds/common';
using {com.bayer.SXTENDER.MasterData} from './MasterData';
using {com.bayer.SXTENDER.MasterDataViews} from './MasterDataViews';
using {com.bayer.SXTENDER.MasterDataLatestValues} from './MasterDataLatestValues';


entity CountryBrandProducts as select from MasterData.PT_TMCTPRDPCK as Product 
left outer join MasterDataLatestValues.CountryRegisteredPrice as RegisteredPrice on 
    Product.COUNTRYCODE = RegisteredPrice.COUNTRY_CODE and 
    Product.PRODUCTPACKID = RegisteredPrice.PRODUCT_ID {
	key Product.COUNTRYCODE as COUNTRY_CODE,
	Product.ProductPack.Product.HLEVEL1_NAME as DIVISION,
	Product.ProductPack.Product.HLEVEL4_CODE as BRAND_ID,
	Product.ProductPack.Product.HLEVEL4_NAME as BRAND_NAME,
	key Product.PRODUCTPACKID as PRODUCT_ID,
	Product.ProductPack.PRODUCTPACKNAME as PRODUCT_NAME,
	Product.ProductPack.PACKFACTOR as PACK_SIZE,
	Product.ProductPack.CONCENTRATION as DOSAGE,
	RegisteredPrice.REGISTERED_PRICE as REGISTERED_PRICE,
    RegisteredPrice.CURRENCY as CURRENCY
}where Product.ACTIVERECORD = 'Yes'
and Product.ProductPack.ACTIVERECORD = 'Yes'
order by Product.COUNTRYCODE, Product.ProductPack.Product.HLEVEL4_NAME, Product.ProductPack.PRODUCTPACKNAME;


entity BrandPolicies: cuid, managed {
    ValidFrom       : Timestamp; //EffectiveDate
    ValidTo         : Timestamp;
    CountryCode     : String;
    Division        : String(200);
    BrandId         : String(50);
    Status          : String(100);
    ProductPolicies : Composition of many ProductPolicies on ProductPolicies.BrandPolicy = $self;
    Approvals       : Composition of many Approvals on Approvals.BrandPolicy = $self;
}; 


entity LatestApprovedBrandPoliciesSegregate as select from PricingPolicyData.BrandPolicies {
    key BrandId,
    Status,
    max(ValidTo) as ValidTo : Timestamp,
}  where Status = 'Approved'
    group by BrandId, Status;

//only the active (is not the same as approved) BrandPolicies
entity ActiveBrandPolicies as select from BrandPolicies where ValidTo = '9999-12-31 00:00:00.000000000'; //only the lastest effective date will be visible

entity Brands as select from CountryBrandProducts as Brand 
    left outer join ActiveBrandPolicies as Policies on 
        Brand.COUNTRY_CODE = Policies.CountryCode and
        Brand.BRAND_ID = Policies.BrandId and
        Brand.DIVISION = Policies.Division {
        key Brand.COUNTRY_CODE as CountryCode,
        key Brand.BRAND_ID     as BrandId,
        key Brand.DIVISION     as Division,
        MIN(Brand.BRAND_NAME)   as BrandName : String(500), //we need to use a agregation function here beceause we have different names for same brands(only in test)
        Policies.ValidFrom as ValidFrom,
        Policies.Status as Status
}where
    Brand.BRAND_ID is not null
group by
    Brand.COUNTRY_CODE,
    Brand.BRAND_ID,
    Brand.DIVISION,
    Policies.ValidFrom,
    Policies.Status; 


entity BrandProducts as select from CountryBrandProducts as Product {
        key Product.COUNTRY_CODE as CountryCode,
        Product.BRAND_ID     as BrandId,
        Product.DIVISION     as Division,
        key Product.PRODUCT_ID   as ProductPackId : Integer,
        Product.PRODUCT_NAME as ProductName   : String(100),
        Product.REGISTERED_PRICE as ListPrice : Double,
        Product.CURRENCY as Currency : String(3)
}order by ProductPackId;

entity ActiveProductPolicies as select from ProductPolicies where BrandPolicy.ValidTo = '9999-12-31 00:00:00.000000000'; //only the lastest effective date will be visible

entity ProductPolicies: cuid, managed {
    CountryCode  : String;
    Division : String(200);
    BrandId : String(50);
    ProductPackId : Integer;
    Currency : String(3);
    MspStatus : String(100);
    NspStatus : String(100);
    BrandPolicy: Composition of BrandPolicies;
    PolicyPrices : Composition of many PolicyPrices on PolicyPrices.ProductPolicy = $self;
}

entity PolicyPrices: cuid, managed {
    PricingPolicyName : String(3);
    Role : String(50);
    Channel : Association to Channels;
    Price : Double;
    ProductPolicy: Association to ProductPolicies;
}

@cds.autoexpose
entity Channels as projection on MasterData.MASTER_COUNTRY_CHANNELS; //as select from MasterData.MASTER_COUNTRY_CHANNELS;

entity Approvals: cuid, managed {
        CountryCode         : String;
        BrandId             : String(50);
        Division            : String(200);
        ApprovalStatus      : String(100);
        SenderComment       : String(500);
        ApproverComment     : String(500);
        SentBy              : String(100);
        ApprovalDate        : Date;
        FlowId              : String(255);
        RequiredAction      : String(12);
        //Associations
        CountryApprover     : Association to CountryApprovers;
        BrandPolicy         : Composition of BrandPolicies;
}


entity OverallApprovalStatus as select from Approvals {
    key BrandId,
    ApprovalStatus
};
@cds.autoexpose
entity CountryApprovers: cuid, managed{
	    CountryCode         : String;
	    Division            : String(200);
        ApproverEmailId     : String(200);
	    ApproverName        : String(200);
        ApproverType        : Association to ApproverTypes;
}

@cds.autoexpose
entity ApproverTypes: cuid, managed {
    ApproverType            : String(200);
    CountryCode             : String;
    Mandatory               : Boolean;
    CountryApprovers        : Association to many CountryApprovers on CountryApprovers.ApproverType = $self;
}
