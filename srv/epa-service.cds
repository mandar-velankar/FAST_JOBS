using { com.bayer.SXTENDER.MasterData, sap.common } from '../db/MasterData';
using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using { com.bayer.SXTENDER.MasterDataViews } from '../db/MasterDataViews';
using { com.bayer.SXTENDER.MasterDataLatestValues } from '../db/MasterDataLatestValues';
using { com.bayer.SXTENDER.TransactionalDataViews } from '../db/TransactionalDataViews';
using { com.bayer.SXTENDER.AdminData } from '../db/AdminData';
using { com.bayer.SXTENDER.AdminDataViews } from '../db/AdminDataViews';
using { com.bayer.SXTENDER.PricingAppData } from '../db/PricingAppData';

service EpaService @(path: 'epa') @(requires:['f_tndr_cag_admin','f_tndr_cag_epa_user']){
    //EPA: Electronic Pricing Approval
    @cds.persistence.exists
    entity PT_TMINST as projection on MasterData.PT_TMINST;
    @cds.persistence.exists
    entity InstituteGroup as projection on PricingAppData.InstituteGroup;
    @cds.persistence.exists
    entity InstituteGroupInstitute as projection on PricingAppData.InstituteGroupInstitute;
    @cds.persistence.exists
    entity InstituteGroupPrice as projection on PricingAppData.InstituteGroupPrice;
    @cds.persistence.exists
    entity InstituteGroupPriceLatest @readonly as projection on PricingAppData.InstituteGroupPriceLatest;
    @cds.persistence.exists
    entity CountryApprovers @readonly as projection on PricingAppData.CountryApprovers;
    @cds.persistence.exists
    entity Countries @(cds.redirection.target:true) as projection on MasterData.PT_TMCTRY;

    @cds.persistence.exists
    entity CountryLegalentity as projection on MasterData.PT_TMCTLE;
    @cds.persistence.exists
    entity CountryProductPack as projection on MasterData.PT_TMCTPRDPCK;
    @cds.persistence.exists
    entity UserCountry as projection on AdminData.PT_TMUSERCTRY;
    @cds.persistence.exists
    entity CountriesUser @(restrict: [
        {grant: '*', to: 'authenticated-user', where: 'User.CWID = $user.id'}
    ]) @(cds.redirection.target:false) as projection on MasterData.PT_TMCTRY{
        *,
        LegalEntities: redirected to CountryLegalentity,
        CountryPacks: redirected to CountryProductPack,
        User: redirected to UserCountry
    };

    @cds.persistence.exists
    entity LatestApprovals as projection on PricingAppData.ApprovalRequests;

    // entity LatestApprovalRequests{
    // 	key CountryCode         : String(2);
    // 	key InstituteGroupId    : Integer;
    // 	key ProductPackId       : Integer;
    // 	key ApproverEmailId     : String(100);
    // 	key ApproverType        : String(30);
    // 	key StatusTime          : DateTime;
    // 	key Division            : String(200);
    // 		ApproverTypeSection : Integer;
    // 		ApprovalStatus      : String(100);
    // 		SenderComment       : String(500);
    // 		ApproverComment     : String(500);
    // 		SentBy              : String(100);
    // 		ApprovalDate        : Date;
    // 		FlowId              : String(255);
    // 		RequiredAction      : String(12);
    // 		//Associations
    // 		CountryApprover     : Association to many CountryApprovers
    // 								on CountryApprover.CountryCode = CountryCode
    // 								and CountryApprover.ApproverType = ApproverType
    // 								and CountryApprover.ApproverEmailId = ApproverEmailId
    // 								and CountryApprover.Division = Division;
    // }

    @cds.persistence.exists
    entity ChannelsForCountry{
        key CountryCode:String;
        key Channel:String(50);
        //Associations
        InstituteGroups:Association[*] to InstituteGroup on InstituteGroups.Channel = Channel;
    }

    @cds.persistence.exists
    entity DivisionsForCountry{
        key CountryCode:String;
        key Division:String(200);
        //Associations
        Brands:Association[*] to BrandsForDivision on Brands.Division = Division; 
    }

    @cds.persistence.exists
    entity BrandsForDivision{
        key Division:String(200);
        key BrandId:String(50);
        Brand:String(100);
        //Association
        Products:Association[*] to ProductsForBrand on Products.BrandId = BrandId;
    }

    @cds.persistence.exists
    entity ProductsForBrand{
        key BrandId:String(50);
        key ProductId:Integer;
        Product:String(100);
        PackFactor:Integer;
        //Associations
        Prices:Association[1] to ProductPricingData;
    }

    @cds.persistence.exists
    entity ProductPricingModel{
        key Currency:String(3);
        key UoM:String(50);
        Price:Double;
    }

    @cds.persistence.exists
    entity ProductPricingData{
        key Currency:String(3);
        RegisteredPrice: Association[1] to ProductPricingModel on RegisteredPrice.Currency = Currency;
        MaxMarketSalesPrice: Association[1] to ProductPricingModel on MaxMarketSalesPrice.Currency = Currency;
        MinMarketSalesPrice: Association[1] to ProductPricingModel on MinMarketSalesPrice.Currency = Currency;
        FloorPrice: Association[1] to ProductPricingModel on FloorPrice.Currency = Currency;
        MaxWonOfferPrice: Association[1] to ProductPricingModel on MaxWonOfferPrice.Currency = Currency;
        MinLostOfferPrice: Association[1] to ProductPricingModel on MinLostOfferPrice.Currency = Currency;
    }

    type User{
        name: String;
    };
    function getCurrentUser() returns User;
}
