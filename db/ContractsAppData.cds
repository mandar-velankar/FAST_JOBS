namespace com.bayer.SXTENDER.ContractsAppData;

using { User, Country, managed, cuid } from '@sap/cds/common';
using { com.bayer.SXTENDER.MasterData } from './MasterData';
using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using { com.bayer.SXTENDER.TransactionalDataConversion} from '../db/TransactionalDataConversion';

/*
entity TenderContracts as select from TransactionalDataConversion.PT_TMOFRS offers {
        offers.CountryCode as CountryCode,
        key offers.OfferID as ContractNumber,
        'Tender' as ChannelName : String,
        offers.CreationDate as createdAt,
        offers.SubmittedBy as modifiedBy,
        offers.SubmissionDate as modifiedAt,
        offers.SubmissionDate as ContractDate,
        offers.Active as Enabled,
        offers.Tender.InstituteID as InstituteId,
        offers.DistributorID as DistributorId,
        offers.SellingCompany as SellingCompanyCode,
        offers.Currency as Currency,
        offers.Comment as Comment,
        offers.OfferValue.VALUE as OfferValue,
        offers.Product as Products,
        offers.Distributor as Distributor,
        offers.SellingCompanyDetails as SellingCompany,
        offers.TenderID,
        offers.Tender.Institute as Institute,
        offers.Tender.GroupPurchasing as GroupPurchasing,
}where offers.Active = 1;
*/
 
@cds.autoexpose
entity Channels : cuid {
    ChannelName                 : String(50);
}
//EHQUT-215577-Thailand - I can't create a new record in "Contract Management" application
entity Contracts : managed, cuid {
        CountryCode             : String not null;
        ContractName            : String(1000);
        ContractNumber          : String(1000);
        ChannelId               : UUID;
        ContractDate            : Date;
        ContractValidUntil      : Date;
        Enabled                 : Boolean not null;
        //InstituteId             : Integer;
        DistributorId           : Integer;
        SellingCompanyCode      : String(3);
        Currency                : String(255);
        Comment                 : String(500);
        FoldersCreated          : Integer;
        //Associations
        Products                : Composition of many Products
                                    on Products.Contract = $self;
        Country                 : Association to MasterData.PT_TMCTRY
                                    on Country.CountryCode = CountryCode;
        Channel                 : Association to Channels
                                    on Channel.ID = ChannelId;
        Institutes              : Composition of many ContractInstitutes
                                    on Institutes.Contract = $self;
        Distributor             : Association to MasterData.PT_TMDIST
                                    on Distributor.DistributorID = DistributorId;
        SellingCompany          : Association to MasterData.PT_TMLE
                                    on SellingCompany.LegalEntityCode = SellingCompanyCode;
}

entity ContractInstitutes {
        key CountryCode         : String;
	key InstituteID         : Integer;    
        key Contract_ID         : UUID;  
        InstituteName           : String;
        Contract                : Association to Contracts on Contract.ID = Contract_ID;
        Institute               : Association to MasterData.PT_TMINST
                                    on Institute.InstituteID = InstituteID
                                    and Institute.CountryCode = CountryCode;
};


entity Products : managed, cuid {
        ProductPackId           : Integer;
        //ProductName             : String(255); assoc to product
        CountryCode             : String;
        Unit                    : String(255);
        Quantity                : Integer;
        //SmallestUnit            : String(255); assoc to product
        MspPerUnit              : Double;
        MspApprovedByName       : String(255);
        MspApprovedByRole       : String(255);
        FocDiscount             : String(255);
        NspPerUnit              : Double;
        NspApprovedByName       : String(255);
        NspApprovedByRole       : String(255);
        Comment                 : String(500);
        FOC                     : Double;
        FOCType                 : String(255);
        FOC_ABS_PCT             : String(5);
        FOC_Bundled_1           : Double;
        FOC_ABS_PCT_Bundled_1   : String(4);
        FOCProduct_Bundled_1    : Integer;
        Enabled                 : Boolean;
        /*Reference               : String(255);
        AlternateOffer          : String(255);
        RequestedVolume         : Integer;
        UoM                     : String(255);
        Samples                 : Integer;//No: 0; Yes: Otherwise
        DocumentsRequired       : String(255);
        FirstShipment           : String(255);
        NoofLots                : Integer;
        IntervalBetweenShipments: Integer;
        PaymentTerms            : String(255);
        Comment                 : String(500);
        IncoTerms               : String(500);
        Sorter                  : Integer;
        RegisteredPrice         : Double;
        WholesalePrice          : Double;
        OfferPrice              : Double;
        Foc                     : Double;
        FocType                 : String(5);
        FocAbsPct               : String(3);
        NetOfferPrice           : Double;
        CommissionRate          : Double;
        NetPrice                : Double;
        Cogs                    : Double;
        FocBrandProductId       : Integer;
        FocBrand                : Double;
        FocBrandAbsPct          : String(3);                
        CogsBrand               : Double;
        BudgetRate              : Double;
        SpotRate                : Double;**/
        //Associations
       /* Deliveries              : Composition of many Deliveries
                                    on Deliveries.Product = $self;
        Letters                 : Composition of many Letters
                                    on Letters.Product = $self;*/
        Contract                : Association to Contracts;
        Product                 : Association to MasterData.PT_TMPRDPCK
                                    on Product.PRODUCTPACKID = ProductPackId;
}

/*entity Deliveries : managed, cuid {
        CountryCode                 : String(2);
        SkuCode                     : String(50);
        InstituteId                 : Integer;
        Enabled                     : Boolean not null;
        LocalOrDirect               : String(6);
        PlannedInApo                : String(3);
        RequestedDeliveryDate       : Date;
        RequestedDeliveryQuantity   : Double;
        ActualDeliveryDate          : Date;
        ActualDeliveryQuantity      : Double;
        UoM                         : String(255);
        Penalty                     : Boolean not null;
        PenaltyValue                : Double;//No: 0; Yes: Otherwise
        PenaltyCurrency             : String(3);
        PenaltyReason               : String(255);
        UndertakingLetters          : String(3);
        Compensated                 : String(3);
        CompensationComment         : String(255);
        PaidOrFree                  : String(4);
        PO                          : String(255);
        InvoiceNo                   : String(255);
        //Associations
        Institute                   : Association to MasterData.PT_TMINST
                                        on Institute.InstituteID = InstituteId;
        Sku                         : Association to MasterData.PT_TMSKUPRDPCK
                                        on Sku.CountryCode = CountryCode
                                        and Sku.SKUCode = SkuCode;
        Product                     : Association to Products;
        Contract                    : Association to Contracts;

}

entity Letters : managed, cuid {
        CountryCode         : String(2);
        SkuCode             : String(50);
        InstituteId         : Integer;
        Enabled             : Boolean not null;
        ReasonForLetter     : String(500);
        Quantity            : Integer;
        Batch               : String(100);
        ManufacturingDate   : Date;
        ExpiryDate          : Date;
        ReturnDate          : Date;
        ReturnedQuantity    : Integer;
        UoM                 : String(255);
        //Associations
        Institute           : Association to MasterData.PT_TMINST
                                on Institute.InstituteID = InstituteId;
        Sku                 : Association to MasterData.PT_TMSKUPRDPCK
                                on Sku.CountryCode = CountryCode
                                and Sku.SKUCode = SkuCode;
        Product             : Association to Products;
        Contract            : Association to Contracts;
}*/