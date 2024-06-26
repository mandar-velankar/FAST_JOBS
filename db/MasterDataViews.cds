namespace com.bayer.SXTENDER.MasterDataViews;

using { User, Country, managed } from '@sap/cds/common';
using { com.bayer.SXTENDER.MasterData } from './MasterData';
using { com.bayer.SXTENDER.MasterData.SAP } from './SAP';
using { com.bayer.SXTENDER.MasterDataLatestValues } from './MasterDataLatestValues';

entity MostRecentSkuCodeForProductPack as select from MasterData.PT_TMSKUPRDPCK as sku {
	sku.ProductPackID,
	sku.CountryCode,
	max(sku.SKUCode) as SKU
}where sku.ActiveRecord='Yes'  group by sku.ProductPackID, sku.CountryCode;


entity ProductPackSKUs as select from MasterData.PT_TMSKUPRDPCK;
entity ProductPack as projection on MasterData.PT_TMPRDPCK;

entity CountryBrandProducts as select from MasterData.PT_TMCTPRDPCK as Product left outer join
MostRecentSkuCodeForProductPack as sku on Product.PRODUCTPACKID = sku.ProductPackID and Product.COUNTRYCODE = sku.CountryCode {
	key Product.COUNTRYCODE as COUNTRY_CODE,
	Product.COUNTRYCODE,
	Product.ACTIVERECORD,
	Product.ProductPack.Product.HLEVEL1_NAME as DIVISION,
	Product.ProductPack.Product.HLEVEL4_CODE as BRAND_ID,
	Product.ProductPack.Product.HLEVEL4_NAME as BRAND_NAME,
	Product.ProductPack.Product.HLEVEL6_CODE as PRODUCT_UNIT_ID,
	Product.ProductPack.Product.HLEVEL6_NAME as PRODUCT_UNIT_NAME, //thailand
	//sku.SKU, //thailand
	key Product.PRODUCTPACKID as PRODUCT_ID,
	Product.PRODUCTPACKID,
	Product.ProductPack.PRODUCTPACKNAME as PRODUCT_NAME,
	Product.ProductPack.PACKFACTOR as PACK_SIZE,
	Product.ProductPack.CONCENTRATION as DOSAGE,
	Product.ProductPack.UOM as UOM,
	Product.COUNTRYOFORIGIN as COUNTRY_OF_ORIGIN,
	Product.MANUFACTURER as MANUFACTURER,
	Product.SHELFLIFE as SHELFLIFE,
	Product.ProductPack.PRESENTATION as PRESENTATION,
	Product.VTATax as VAT,
	case when Product.REGISTERED=0 then 0 else 1 end as REGISTERED:Integer,
	Product.REGISTERED as REGISTERED_VALUE:Integer,
	Product.COMMENT as COMMENT,
	Product.COGS.COGS,
	Product.GOV_CODE,
	Product.CODE1,
	Product.CODE2,
	Product.CODE3,
	Product.QTY_THRESHOLD,
	Product.BU,
	Product.RegistrationDate,
	Product.RegistrationValidUntil,
	Product.ProductPackSKU: redirected to ProductPackSKUs,
	Product.ProductPack: redirected to ProductPack
}where Product.ACTIVERECORD = 'Yes'
and Product.ProductPack.ACTIVERECORD = 'Yes'
order by Product.COUNTRYCODE, Product.ProductPack.Product.HLEVEL4_NAME, Product.ProductPack.PRODUCTPACKNAME;

entity CountryBrands as select from CountryBrandProducts as Product{
	key Product.COUNTRY_CODE,
	key Product.BRAND_ID,
	min(Product.BRAND_NAME) as BRAND_NAME:String(500),
	min(Product.DIVISION) as DIVISION:String(500),
}where Product.BRAND_ID is not null
group by Product.COUNTRY_CODE, Product.BRAND_ID;

entity CountryProductUnits as select from CountryBrandProducts as Product{
	key Product.COUNTRY_CODE,
	key Product.PRODUCT_UNIT_ID,
	min(Product.PRODUCT_UNIT_NAME) as PRODUCT_UNIT_NAME:String(500),
	min(Product.BRAND_ID) as BRAND_ID:String(500), 
	min(Product.BRAND_NAME) as BRAND_NAME:String(500)
}where Product.PRODUCT_UNIT_ID is not null
group by Product.COUNTRY_CODE, Product.PRODUCT_UNIT_ID;

//TODO no need to do a select here... there could be just a projection... but if we do this.. we need to rename the places where SORTER instead of Sorter & COUNTRY_CODE instead of CountryCode & CURRENCY instead of Currency
entity CountryCurrency as select from MasterData.CountryCurrency as Country{
	key Country.CountryCode as COUNTRY_CODE,
	key Country.Currency as CURRENCY:String(3),
	Country.Sorter as SORTER:Integer
};

entity CountryLegalEntity as select from MasterData.PT_TMCTLE as Country{
	key Country.CountryCode,
	key Country.LegalEntity.LegalEntityCode,
	Country.LegalEntity.LegalEntityName
}where Country.LegalEntity.LegalEntityCode is not null;

entity LegalEntityBrand as select from MasterData.PT_TMCTLEBR as leb
inner join CountryBrands as cb on leb.CountryCode = cb.COUNTRY_CODE and leb.HLevel4_Code = cb.BRAND_ID{
	key leb.CountryCode as COUNTRY_CODE,
	key leb.HLevel4_Code as BRAND_ID,
	key leb.Entity.LegalEntityCode as LEGAL_ENTITY_CODE,
	cb.BRAND_NAME as BRAND_NAME
}where leb.Entity.LegalEntityCode is not null
union
select from CountryBrands as cb
inner join MasterData.PT_TMCTLE as cle on cb.COUNTRY_CODE = cle.CountryCode{
	cb.COUNTRY_CODE as COUNTRY_CODE,
	cb.BRAND_ID as BRAND_ID,
	cle.LegalEntity.LegalEntityCode as LEGAL_ENTITY_CODE,
	cb.BRAND_NAME as BRAND_NAME
}where cle.ForAllBrands = true
and cle.LegalEntity.LegalEntityCode is not null;

entity DirectBrand as select from MasterData.PT_TMINSBRTR as itr
inner join MasterData.PT_TMINDSBR as idst on itr.InstituteID = idst.InstituteID and itr.HLevel4_Code = idst.HLevel4_Code
inner join CountryBrands as cb on itr.CountryCode = cb.COUNTRY_CODE and itr.HLevel4_Code = cb.BRAND_ID{
	key itr.CountryCode as COUNTRY_CODE,
	key itr.InstituteID as INSTITUTE_ID,
	itr.Institute.InstituteName as INSTITUTE_NAME,
	key idst.DistributorID as DISTRIBUTOR_ID,
	idst.Distributor.DistributorName as DISTRIBUTOR_NAME,
	key cb.BRAND_ID as BRAND_ID,
	cb.BRAND_NAME as BRAND_NAME,
	'Direct' as CHANNEL:String(11),
	itr.INCOTerms as INCO_TERMS,
	itr.PaymentTerms as PAYMENT_TERMS,
	idst.Commissionrate as COMMISSION_RATE
}where itr.ActiveRecord = 'Yes'
and idst.ActiveRecord = 'Yes'
and itr.Institute.ActiveRecord = 'Yes'
and idst.Distributor.ActiveRecord = 'Yes'
union 
select from CountryBrands as cb 
inner join MasterData.PT_TMINST as inst on cb.COUNTRY_CODE = inst.CountryCode
inner join MasterData.PT_TMDIST as dst on cb.COUNTRY_CODE = dst.CountryCode
{
    key cb.COUNTRY_CODE as COUNTRY_CODE,
    key inst.InstituteID as INSTITUTE_ID,
    inst.InstituteName as INSTITUTE_NAME,
    key dst.DistributorID as DISTRIBUTOR_ID,
    dst.DistributorName as DISTRIBUTOR_NAME,
    key cb.BRAND_ID as BRAND_ID,
    cb.BRAND_NAME as BRAND_NAME,
    'Direct' as CHANNEL:String(11),
    inst.INCOTerms as INCO_TERMS,
    inst.PaymentTerms as PAYMENT_TERMS,
    dst.CommissionRate as COMMISSION_RATE
}where inst.ActiveRecord = 'Yes'
and dst.ActiveRecord = 'Yes'
and inst.ForAllBrands = true;

entity DistributorBrand as select from MasterData.PT_TMDISBRD as dstbr
inner join CountryBrands as cb on dstbr.CountryCode = cb.COUNTRY_CODE and dstbr.HLevel4_Code = cb.BRAND_ID
inner join MasterData.PT_TMDIST as dst on cb.COUNTRY_CODE = dst.CountryCode{
	key dstbr.CountryCode as COUNTRY_CODE,
	key dstbr.DistributorID as DISTRIBUTOR_ID,
	dstbr.Distributor.DistributorName as DISTRIBUTOR_NAME,
	key cb.BRAND_ID as BRAND_ID,
	cb.BRAND_NAME as BRAND_NAME,
	'Distributor' as CHANNEL:String(11),
	//TODO: check what we need to keep
	dstbr.INCOTerms as INCO_TERMS,
	dstbr.PaymentTerms as PAYMENT_TERMS,
	dstbr.CommissionRate as COMMISSION_RATE,
	dstbr.ActiveRecord as ACTIVE_RECORD
} where dstbr.ActiveRecord = 'Yes' and dstbr.Distributor.ActiveRecord = 'Yes' and dstbr.Distributor.ForAllBrands = false
union
select from CountryBrands as cb 
inner join MasterData.PT_TMDIST as dst on cb.COUNTRY_CODE = dst.CountryCode{
	dst.CountryCode as COUNTRY_CODE,
	dst.DistributorID as DISTRIBUTOR_ID,
	dst.DistributorName as DISTRIBUTOR_NAME,
	cb.BRAND_ID as BRAND_ID,
	cb.BRAND_NAME as BRAND_NAME,
	'Distributor' as CHANNEL:String(11),
	dst.INCOTerms as INCO_TERMS,
	dst.PaymentTerms as PAYMENT_TERMS,
	dst.CommissionRate as COMMISSION_RATE,
	'Yes' as ACTIVE_RECORD
}where dst.ForAllBrands = true and dst.ActiveRecord = 'Yes'
union
select from MasterData.DistributorDivision as bdd
inner join MasterData.PT_TMDIST as dst on bdd.DistributorID = dst.DistributorID and bdd.CustomerID = dst.CustomerID
inner join CountryBrands as cb on dst.CountryCode = cb.COUNTRY_CODE and bdd.DivisionName = cb.DIVISION

{
	key dst.CountryCode as COUNTRY_CODE,
	key dst.DistributorID as DISTRIBUTOR_ID,
	dst.DistributorName as DISTRIBUTOR_NAME,
	key cb.BRAND_ID as BRAND_ID,
	cb.BRAND_NAME as BRAND_NAME,
	'Distributor' as CHANNEL:String(11),
	dst.INCOTerms as INCO_TERMS,
	dst.PaymentTerms as PAYMENT_TERMS,
	dst.CommissionRate as COMMISSION_RATE,
	dst.ActiveRecord as ACTIVE_RECORD
} where dst.ForAllBrands = false and dst.ActiveRecord = 'Yes';

//Distributor brand policy with aggregated data for front-end
entity AggregatedDistributorBrandPolicies as SELECT from MasterData.PT_TMDISBRD as DistributorBrands
left outer join MasterDataLatestValues.LatestDistributorBrandPolicies as LatestDistributorBrandPolicies 
	on DistributorBrands.CountryCode = LatestDistributorBrandPolicies.CountryCode
	and DistributorBrands.HLevel4_Code = LatestDistributorBrandPolicies.BrandId
	and DistributorBrands.DistributorID = LatestDistributorBrandPolicies.DistributorId
left outer join MasterDataLatestValues.LatestBrandPolicies as LatestBrandPolicies
	on DistributorBrands.CountryCode = LatestBrandPolicies.CountryCode
	and DistributorBrands.HLevel4_Code = LatestBrandPolicies.BrandId{
		key DistributorBrands.CountryCode,
		key DistributorBrands.DistributorID as DistributorId,
		key DistributorBrands.HLevel4_Code as BrandId,
		ifnull(LatestDistributorBrandPolicies.StandardDiscount, ifnull(LatestBrandPolicies.StandardDiscount, 0)) as StandardDiscount:Double
}group by DistributorBrands.CountryCode, DistributorBrands.DistributorID, DistributorBrands.HLevel4_Code, LatestDistributorBrandPolicies.StandardDiscount, LatestBrandPolicies.StandardDiscount;

//Distinct list of divisions
entity Divisions as select from MasterData.PT_TMPRDHIER as ProductHierarchy{
	key ProductHierarchy.HLEVEL1_CODE as DivisionId,
	ProductHierarchy.HLEVEL1_NAME as DivisionName
} group by ProductHierarchy.HLEVEL1_CODE, ProductHierarchy.HLEVEL1_NAME;

//DONE
entity ExchangeRates @readonly as projection on MasterDataLatestValues.ExchangeRates;
//EHQUT-CR8
//italy
entity MostRecentConsumerPricesView as select from MasterData.ConsumerPrices {
	key CountryCode,
	key ProductPackId,
	Currency,
	ValidFrom,
	ValidTo,
	ConsumerPriceExclPP,
	ConsumerPriceInclPP,
	ConsumerPriceExclPU,
	ConsumerPriceInclPU,
	VatPerPack,
	MandatoryDiscount,
	ExfPriceExclPP,
	ConfidentialDiscount1,
	ConfidentialDiscount2,
	TotalDiscount,
	MaxPriceNhsPP,
	MaxPriceNhsPU,
	FloorPrice
}where ValidTo = '9999-12-31 00:00:00.000000000';

entity MostRecentMasterPricesView as projection on MasterData.MasterPrices 
where ValidTo = '9999-12-31 00:00:00.000000000';

entity MostRecentCapView as projection on MasterData.BrazilCap 
where ValidTo = '9999-12-31 00:00:00.000000000';

entity MostRecentBrazilMasterPricesView as projection on MasterData.BrazilMasterPrices 
where ValidTo = '9999-12-31';

/**
 * This view is created for the processing of ItalyCustomer job
 */
entity ItalyCustomerUpdateInstituteEntriesView as select from SAP.ItalyCustomers as customer 
inner join MasterData.CountryProvinces as province 
    on customer.E1KNA1M.REGIO = province.Name
	and province.CountryCode = 'IT'
inner join MasterData.PT_TMINST as institute 
    on customer.E1KNA1M.KUNNR = institute.CustomerID 
	left outer join MasterData.PaymentTerms as PaymentTerms
   on PaymentTerms.E1KNVVM_ZTERM = customer.E1KNVVM.ZTERM{
	customer.E1KNA1M.LAND1 as E1KNA1M_LAND1,
	customer.E1KNA1M.KUNNR as E1KNA1M_KUNNR,
	customer.E1KNA1M.NAME1 as E1KNA1M_NAME1,
	customer.E1KNA1M.ANRED as E1KNA1M_ANRED,
	customer.E1KNA1M.STRAS as E1KNA1M_STRAS,
	customer.E1KNA1M.PSTLZ as E1KNA1M_PSTLZ,
	customer.E1KNA1M.STCEG as E1KNA1M_STCEG,
	customer.E1KNA1M.STCD1 as E1KNA1M_STCD1,
	customer.E1KNA1M.TELF1 as E1KNA1M_TELF1,
	customer.E1KNA1M.TELFX as E1KNA1M_TELFX,
	customer.E1KNA1M.STKZN as E1KNA1M_STKZN,
	customer.E1KNVVM.KVGR3 as E1KNVVM_KVGR3,
	customer.E1KNA1M.ORT01 as E1KNA1M_ORT01,
	customer.E1KNA1M.KTOKD as E1KNA1M_KTOKD,
	PaymentTerms.Description as PaymentTerms,
	province.RegionID,
	institute.InstituteID,
	institute.CountryCode,
}where customer.E1KNA1M.LAND1 = 'IT' and customer.E1KNA1M.KTOKD<> '0002'
group by customer.E1KNA1M.LAND1,
	customer.E1KNA1M.KUNNR,
	customer.E1KNA1M.NAME1,
	customer.E1KNA1M.ANRED,
	customer.E1KNA1M.STRAS,
	customer.E1KNA1M.PSTLZ,
	customer.E1KNA1M.STCEG,
	customer.E1KNA1M.STCD1,
	customer.E1KNA1M.TELF1,
	customer.E1KNA1M.TELFX,
	customer.E1KNA1M.STKZN,
	customer.E1KNVVM.KVGR3,
	customer.E1KNA1M.ORT01,
	customer.E1KNA1M.KTOKD,
	PaymentTerms.Description,
	province.RegionID,
	institute.InstituteID,
	institute.CountryCode;

/**
 * This view is created for the processing of ItalyCustomer job
 */
entity ItalyCustomerInstituteBrandTermCompoundKeyView as select from MasterData.PT_TMINSBRTR {
	CountryCode || InstituteID || HLevel4_Code || ActiveRecord as CompoundKey
}where CountryCode = 'IT';

/**
 * This view is created for the processing of ItalyCustomer job
 */
entity ItalyCustomerCreateInstituteBrandView as SELECT from MasterData.PT_TMINST as i
inner join MasterData.PT_TMCTPRDPCK as cp 
	on i.CountryCode = cp.COUNTRYCODE 
inner join MasterData.PT_TMPRDPCK as p
	on cp.PRODUCTPACKID = p.PRODUCTPACKID
inner join MasterData.PT_TMPRDHIER as h
	on p.HLEVEL6_CODE = h.HLEVEL6_CODE {
	i.CountryCode, 
	i.InstituteID, 
	h.HLEVEL4_CODE 
}where i.CountryCode = 'IT' and (i.CountryCode || i.InstituteID || h.HLEVEL4_CODE || 'Yes') not in (Select CompoundKey from MasterDataViews.ItalyCustomerInstituteBrandTermCompoundKeyView)
GROUP BY i.CountryCode,i.InstituteID,h.HLEVEL4_CODE
ORDER BY i.InstituteID,h.HLEVEL4_CODE;

/**
 * This view is created for the processing of ItalyCustomer job
 */
entity ItalyCustomerInstituteDistributorBrandCompoundKeyView as select from MasterData.PT_TMINDSBR {
	CountryCode || InstituteID || DistributorID || HLevel4_Code || ActiveRecord as CompoundKey
}where CountryCode = 'IT';

/**
 * This view is created for the processing of ItalyCustomer job
 */
entity ItalyCustomerCreateInstituteDistributorBrandView as SELECT from MasterData.PT_TMINST as i
inner join MasterData.PT_TMDIST as d
	on i.CountryCode = d.CountryCode
inner join MasterData.PT_TMCTPRDPCK as cp 
	on i.CountryCode = cp.COUNTRYCODE 
inner join MasterData.PT_TMPRDPCK as p
	on cp.PRODUCTPACKID = p.PRODUCTPACKID
inner join MasterData.PT_TMPRDHIER as h
	on p.HLEVEL6_CODE = h.HLEVEL6_CODE {
	i.CountryCode, 
	i.InstituteID, 
	d.DistributorID,
	h.HLEVEL4_CODE 
}where i.CountryCode = 'IT' and (i.CountryCode || i.InstituteID || d.DistributorID || h.HLEVEL4_CODE || 'Yes') not in (Select CompoundKey from MasterDataViews.ItalyCustomerInstituteDistributorBrandCompoundKeyView)
GROUP BY i.CountryCode,i.InstituteID,h.HLEVEL4_CODE, d.DistributorID
ORDER BY i.InstituteID,h.HLEVEL4_CODE, d.DistributorID;


entity InstituteDistributorBrandProduct {
        key COUNTRY_CODE      : String not null;
        key INSTITUTE_ID      : Integer not null;
            INSTITUTE_NAME    : String(500);
        key DISTRIBUTOR_ID    : Integer not null;
            DISTRIBUTOR_NAME  : String(500);
        key BRAND_ID          : String(50) not null;
            BRAND_NAME        : String(100);
        key PRODUCT_ID        : Integer not null;
            PRODUCT_NAME      : String(100);
            INCO_TERMS        : String(500);
            PAYMENT_TERMS     : String(500);
            COMMISSION_RATE   : Double;
        key LEGAL_ENTITY_CODE : String(3) not null;
        key CHANNEL           : String(11) not null;
            COUNTRY_OF_ORIGIN : String(120);
            COGS              : Double;
            PACKFACTOR        : Integer;
            DIVISION          : String;
            SKUS              : String;
    };


entity PricingPolicyView as select from MasterData.PricingPolicy as policy 
left outer join MasterData.PT_TMPRDHIER as hr 
	on policy.DivisionCode = hr.HLEVEL1_CODE 
	or policy.Brand = hr.HLEVEL4_CODE
left outer join MasterData.PT_TMCTPRDPCK as prd 
	on policy.ProductPackID = prd.PRODUCTPACKID
	and policy.CountryCode = prd.COUNTRYCODE
left outer join MasterData.InstituteDivision as cg
	on policy.CustomerGroup = cg.CustomerGroup
left outer join MasterData.PT_TMINST as inst
	on policy.CountryCode=inst.CountryCode 
	and (policy.InstituteType=inst.InstituteType or policy.InstituteID=inst.InstituteID)
{
	policy.CountryCode,
	policy.InstituteID,
	policy.DistributorID,
	policy.ProductPackID,
	policy.Type,
	policy.AbsOrPct,
	policy.Value,
	policy.Currency
};