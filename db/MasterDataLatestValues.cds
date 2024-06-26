namespace com.bayer.SXTENDER.MasterDataLatestValues;

using { User, Country, managed } from '@sap/cds/common';
using { com.bayer.SXTENDER.MasterData } from './MasterData';

entity MostRecentRegisteredPrice as SELECT from MasterData.PT_TMREGPR as RegisteredPrice
{
    key RegisteredPrice.CountryCode,
    key RegisteredPrice.ProductPackID,
    max(RegisteredPrice.EffDate) as MaxEffectiveDate:Date
}where RegisteredPrice.ActiveRecord = 'Yes'
group by RegisteredPrice.CountryCode, RegisteredPrice.ProductPackID;

entity CountryRegisteredPrice as SELECT from MasterData.PT_TMREGPR as RegisteredPrice
INNER JOIN MostRecentRegisteredPrice as l on RegisteredPrice.CountryCode=l.CountryCode and RegisteredPrice.ProductPackID=l.ProductPackID and RegisteredPrice.EffDate=l.MaxEffectiveDate
{
    key RegisteredPrice.CountryCode as COUNTRY_CODE,
    key RegisteredPrice.ProductPackID as PRODUCT_ID,
    RegisteredPrice.UOM,
    key RegisteredPrice.Currency as CURRENCY,
    RegisteredPrice.RegisteredPrice as REGISTERED_PRICE,
    RegisteredPrice.EffDate,
    RegisteredPrice.ActiveRecord,
    RegisteredPrice.EndDate,
    RegisteredPrice.RegisteredPriceSource,
    RegisteredPrice.RegisteredPriceID
}where RegisteredPrice.ActiveRecord = 'Yes';

entity MostRecentCogs as SELECT from MasterData.PT_TMCOGS as Cogs
{
    key Cogs.CountryCode,
    key Cogs.ProductPackID,
    max(Cogs.EffectiveDate) as MaxEffectiveDate:Date
}where Cogs.ActiveRecord = 'Yes'
group by Cogs.CountryCode, Cogs.ProductPackID;

entity CountryCogs as SELECT from MasterData.PT_TMCOGS as Cogs
INNER JOIN MostRecentCogs as l on Cogs.CountryCode=l.CountryCode and Cogs.ProductPackID=l.ProductPackID and Cogs.EffectiveDate=l.MaxEffectiveDate
{
    key Cogs.CountryCode as COUNTRY_CODE,
    key Cogs.ProductPackID as PRODUCT_ID,
    key Cogs.COGSType as COGS_TYPE,
    'Pack' as UOM:String(10),
    Cogs.Currency as CURRENCY,
    Cogs.COGS as COGS,
    Cogs.COGSID,
    Cogs.EffectiveDate,
    Cogs.EndDate,
    Cogs.COGSType,
    Cogs.ActiveRecord
}where Cogs.ActiveRecord = 'Yes';

entity MostRecentExchangeRates as SELECT from MasterData.PT_TMFXRTS as XRates
{
    key XRates.CurrencyFrom,
    key XRates.CurrencyTo,
    key XRates.ExchangeType,
    max(XRates.EffDate) as MaxEffectiveDate:Date
}where XRates.ActiveRecord = 'Yes'
group by XRates.CurrencyFrom, XRates.CurrencyTo, XRates.ExchangeType;

entity ExchangeRates as SELECT from MasterData.PT_TMFXRTS as XRates
INNER JOIN MostRecentExchangeRates as l on XRates.CurrencyFrom=l.CurrencyFrom and XRates.CurrencyTo=l.CurrencyTo and XRates.ExchangeType=l.ExchangeType and XRates.EffDate=l.MaxEffectiveDate
{
    key XRates.CurrencyFrom as CURRENCY_FROM,
    key XRates.CurrencyTo as CURRENCY_TO,
    key XRates.ExchangeType as X_TYPE,
    XRates.ExchangeRate as X_RATE
}where XRates.ActiveRecord = 'Yes';

entity MostRecentApprovedPrice as SELECT from MasterData.MASTER_APPROVED_PRICE as ApprovedPrice
{
    key ApprovedPrice.COUNTRY_CODE,
    key ApprovedPrice.PRODUCT_ID,
    max(ApprovedPrice.EFFECTIVE_DATE) as MaxEffectiveDate:Date
}
group by ApprovedPrice.COUNTRY_CODE, ApprovedPrice.PRODUCT_ID;

entity VW_MASTER_APPROVED_PRICE as SELECT from MasterData.MASTER_APPROVED_PRICE as ApprovedPrice
INNER JOIN MostRecentApprovedPrice as l on ApprovedPrice.COUNTRY_CODE=l.COUNTRY_CODE and ApprovedPrice.PRODUCT_ID=l.PRODUCT_ID and ApprovedPrice.EFFECTIVE_DATE=l.MaxEffectiveDate
{
    key ApprovedPrice.COUNTRY_CODE,
    key ApprovedPrice.PRODUCT_ID,
    ApprovedPrice.UOM,
    key ApprovedPrice.CURRENCY,
    ApprovedPrice.APPROVED_PRICE
};
//EITOG-215125-MEA - budgeted profitability for 2023 to be maintained at the product pack level
entity MostRecentBudgetedProfitability as SELECT from MasterData.BUDGETEDPROFITABILITY as BudgetedProfitability
{
    key BudgetedProfitability.COUNTRYCODE,
    key BudgetedProfitability.HLEVEL4_CODE,
     key BudgetedProfitability.PRODUCTPACKID,
     BudgetedProfitability.PRODUCTPACKNAME,
    max(BudgetedProfitability.EFFECTIVEDATE) as MaxEffectiveDate:Date
}group by BudgetedProfitability.COUNTRYCODE, BudgetedProfitability.HLEVEL4_CODE,BudgetedProfitability.PRODUCTPACKID,BudgetedProfitability.PRODUCTPACKNAME;

//EITOG-215125-MEA - budgeted profitability for 2023 to be maintained at the product pack level
entity VWBUDGETEDPROFITABILITY AS SELECT from MasterData.BUDGETEDPROFITABILITY as BudgetedProfitability
INNER JOIN MostRecentBudgetedProfitability as l on BudgetedProfitability.COUNTRYCODE = l.COUNTRYCODE and BudgetedProfitability.HLEVEL4_CODE = l.HLEVEL4_CODE and BudgetedProfitability.EFFECTIVEDATE = l.MaxEffectiveDate  and BudgetedProfitability.PRODUCTPACKID= l.PRODUCTPACKID
{
    key BudgetedProfitability.COUNTRYCODE,
    key BudgetedProfitability.HLEVEL4_CODE,
    key BudgetedProfitability.PRODUCTPACKID,
    BudgetedProfitability.PRODUCTPACKNAME,
    BudgetedProfitability.PROFITABILITY
};

//only the active (is not the same as approved) BrandPolicies
entity ActiveBrandPolicies as select from MasterData.BrandPolicies where ValidTo = '9999-12-31 00:00:00.000000000'; 

//only the active ChannelProductPolicies
entity ActiveChannelProductPolicies as select from MasterData.ChannelProductPolicies where ValidTo = '9999-12-31 00:00:00.000000000'; 

//What is the most recent BrandPolicy
entity MostRecentBrandPolicies as SELECT from ActiveBrandPolicies as BrandPolicies
{
    key BrandPolicies.CountryCode,
    key BrandPolicies.BrandId,
    max(BrandPolicies.ValidFrom) as MaxValidFrom:Date
}group by BrandPolicies.CountryCode, BrandPolicies.BrandId;

entity LatestBrandPolicies as SELECT from MasterData.BrandPolicies as BrandPolicies
inner join MostRecentBrandPolicies  
    on BrandPolicies.CountryCode = MostRecentBrandPolicies.CountryCode 
    and BrandPolicies.BrandId = MostRecentBrandPolicies.BrandId
{
    key BrandPolicies.CountryCode,
    key BrandPolicies.BrandId,
    BrandPolicies.StandardDiscount
};

//only the active (is not the same as approved) BrandPolicies
entity ActiveDistributorBrandPolicies as select from MasterData.DistributorBrandPolicies where ValidTo = '9999-12-31 00:00:00.000000000'; 

entity MostRecentDistributorBrandPolicies as SELECT from ActiveDistributorBrandPolicies as DistributorBrandPolicies
{
    key DistributorBrandPolicies.CountryCode,
    key DistributorBrandPolicies.DistributorId,
    key DistributorBrandPolicies.BrandId,
    max(DistributorBrandPolicies.ValidFrom) as MaxValidFrom:Date
}group by DistributorBrandPolicies.CountryCode, DistributorBrandPolicies.BrandId, DistributorBrandPolicies.DistributorId;

entity LatestDistributorBrandPolicies as SELECT from MasterData.DistributorBrandPolicies as DistributorBrandPolicies
inner join MostRecentDistributorBrandPolicies  
    on DistributorBrandPolicies.CountryCode = MostRecentDistributorBrandPolicies.CountryCode
    and DistributorBrandPolicies.DistributorId = MostRecentDistributorBrandPolicies.DistributorId
    and DistributorBrandPolicies.BrandId = MostRecentDistributorBrandPolicies.BrandId
{
    key DistributorBrandPolicies.CountryCode,
    key DistributorBrandPolicies.DistributorId,
    key DistributorBrandPolicies.BrandId,
    DistributorBrandPolicies.StandardDiscount
};