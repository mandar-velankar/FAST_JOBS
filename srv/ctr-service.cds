namespace com.bayer.SXTENDER.ContractService;

using { com.bayer.SXTENDER.ContractsAppData } from '../db/ContractsAppData';
using { com.bayer.SXTENDER.MasterData } from '../db/./MasterData';
using { com.bayer.SXTENDER.MasterDataViews } from '../db/./MasterDataViews';
using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using { com.bayer.SXTENDER.TransactionalDataConversion} from '../db/TransactionalDataConversion';
using { com.bayer.SXTENDER.AdminData } from '../db/AdminData';

service ContractService @(path: 'ctr') @(requires:['f_tndr_cag_admin','f_tndr_cag_ctr_user','f_tndr_cag_technical_user']){
//service ContractService @(path: 'ctr') @(requires:['all','ctr_user']){ //previously, before CAP integration

    //entity Deliveries as projection on ContractsAppData.Deliveries;
    //entity Letters as projection on ContractsAppData.Letters;

    @cds.persistence.exists
    entity ProductHierarchy as projection on MasterData.PT_TMPRDHIER;
    @cds.persistence.exists
    entity Product as projection on MasterData.PT_TMPRDPCK {
        *,
        Product: redirected to ProductHierarchy
    };
    @cds.persistence.exists
    entity PenaltyReasons as projection on MasterData.PT_TMPNLTYRS;
    @cds.persistence.exists
    entity CountryCurrency @readonly as projection on MasterDataViews.CountryCurrency;
    //EHQUT-192851-Add OTC customer group for "Contract Management" app
    @cds.persistence.exists
    entity CountryChannels as projection on MasterData.MASTER_COUNTRY_CHANNELS ;
    @cds.persistence.exists
    entity Products as select from ContractsAppData.Products {
        *,
        /*sum(
            OfferPrice *
            case when FocType = 'FOC 1'
                then
                    case when FocAbsPct = 'PCT'
                        then RequestedVolume * (1 - Foc)
                        else RequestedVolume - Foc
                    end
                else RequestedVolume
            end
        ) as OfferValue:Double,*/
        //Deliveries: redirected to Deliveries,
        //Letters: redirected to Letters,
        Product: redirected to Product
    }where Enabled = true 
    group by 
        ID,
        ProductPackId,
        CountryCode,
        Unit,
        Quantity,
        MspPerUnit,
        MspApprovedByName,
        MspApprovedByRole,
        FocDiscount,
        NspPerUnit,
        NspApprovedByName,
        NspApprovedByRole,
        Comment,
        FOC,
        FOCType,
        FOC_ABS_PCT,
        FOC_Bundled_1,
        FOC_ABS_PCT_Bundled_1,
        FOCProduct_Bundled_1,
        Enabled,
        /*Reference,
        AlternateOffer,
        RequestedVolume,
        UoM,
        Samples,
        DocumentsRequired,
        FirstShipment,
        NoofLots,
        IntervalBetweenShipments,
        PaymentTerms,
        Comment,
        IncoTerms,
        Sorter,
        RegisteredPrice,
        WholesalePrice,
        OfferPrice,
        Foc,
        FocType,
        FocAbsPct,
        NetOfferPrice,
        CommissionRate,
        NetPrice,
        Cogs,
        FocBrandProductId,
        FocBrand,
        FocBrandAbsPct,
        CogsBrand,
        BudgetRate,
        SpotRate,*/
        createdAt,
        createdBy,
        modifiedAt,
        modifiedBy,
        Contract;
        
    @cds.persistence.exists
    entity MspApprovers as select from ContractsAppData.Products {
        key CountryCode,
        key MspApprovedByName
    }group by CountryCode, MspApprovedByName;

    @cds.persistence.exists
    entity NspApprovers as select from ContractsAppData.Products {
        key CountryCode,
        key NspApprovedByName
    }group by CountryCode, NspApprovedByName;

    @cds.persistence.exists
    entity ContractInstitutes as projection on ContractsAppData.ContractInstitutes;

    @cds.persistence.exists
    entity Contracts as select from ContractsAppData.Contracts{
        *,
        null as OfferValue: Double,
        Products: redirected to Products,
        Institutes: redirected to ContractInstitutes
    };

    @cds.persistence.exists
    entity CountryContractBrands as select from Contracts {
        key CountryCode,
        key Products.Product.Product.HLEVEL4_CODE as BrandID,
        Products.Product.Product.HLEVEL4_NAME as BrandName
    }
    where Enabled = true
    and Products.Enabled = true
    and Products.Product.ACTIVERECORD = 'Yes'
    and Products.Product.Product.HLEVEL4_CODE is not null
    group by CountryCode, Products.Product.Product.HLEVEL4_CODE, Products.Product.Product.HLEVEL4_NAME
    union
    select from MasterData.PT_TMCTRY as country{
        country.CountryCode,
        'All_Brands' as BrandID,
        ' All' as BrandName
    };

    @cds.persistence.exists
    entity TenderDistributor as projection on MasterData.PT_TMDIST;

    //TenderDeliveries
    //entity TenderDeliveries as projection on TransactionalDataConversion.PT_TMDLVTR;
    //entity PT_TMDLVTR as projection on TransactionalData.PT_TMDLVTR; //we need this for saving TODO make 1 saving 

    //TenderLetters
    //entity TenderLetters as projection on TransactionalDataConversion.PT_TMUDLTRS;
    //entity PT_TMUDLTRS as projection on TransactionalData.PT_TMUDLTRS; //we need this for saving TODO make 1 saving 

    @cds.persistence.exists
    entity CountryLegalentity as projection on MasterData.PT_TMCTLE;
    @cds.persistence.exists
    entity CountryProductPack as projection on MasterData.PT_TMCTPRDPCK;
    @cds.persistence.exists
    entity UserCountry as projection on AdminData.PT_TMUSERCTRY;
    @cds.persistence.exists
	entity TenderCountriesUser @(restrict: [
		{grant: '*', to: 'authenticated-user', where: 'User.CWID = $user.id'}
	]) as projection on MasterData.PT_TMCTRY{
		*,
		LegalEntities: redirected to CountryLegalentity,
		CountryPacks: redirected to CountryProductPack,
		User: redirected to UserCountry
	};
    @cds.persistence.exists
    entity TenderSellingCompany as projection on MasterData.PT_TMLE;

    @cds.persistence.exists
    entity TenderChildren as projection on MasterData.PT_TMINSHIER;

    @cds.persistence.exists
    entity TenderInstitute as projection on MasterData.PT_TMINST{
        *,
        Children: redirected to TenderChildren
    }

    @cds.persistence.exists
    entity TenderPrice as projection on TransactionalData.PT_TMBDPR;
    @cds.persistence.exists
    entity TenderGroupPurchasing as projection on TransactionalData.PT_OFGRPUR;
    @cds.persistence.exists
    entity TenderResults as projection on TransactionalData.PT_TMTRRES;
    
    @cds.persistence.exists
    entity TenderProducts as projection on TransactionalDataConversion.PT_TMOFPR {
        *,
        SORTER as Sorter,
        SampleQuantity as Samples,
        UnitPerPack as UoM,
        INCOTerms as IncoTerms,
        SKU as Product,
        Results: redirected to TenderResults,
        Price: redirected to TenderPrice,
        GroupPurchasing: redirected to TenderGroupPurchasing,
        Price.RegPrice as RegisteredPrice,
        Price.OfferPrice as OfferPrice,
        Price.FOC as Foc,
        Price.FOCType as FocType,
        Price.FOC_ABS_PCT as FocAbsPct,
        Price.NetofferPrice as NetOfferPrice,
        Price.Deductions as CommissionRate
    }excluding{INCOTerms, SampleQuantity, SORTER};

    @cds.persistence.exists
    entity TenderContracts as projection on TransactionalDataConversion.PT_TMOFRS {
        *,
        Products: redirected to TenderProducts,
        Distributor: redirected to TenderDistributor,
        SellingCompany: redirected to TenderSellingCompany,
        Institute: redirected to TenderInstitute //TODO: fix this ASAP - split app
    };

}