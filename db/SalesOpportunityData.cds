namespace com.bayer.SXTENDER.SalesOpportunityData;

using { User, Country, managed, cuid } from '@sap/cds/common';
using { com.bayer.SXTENDER.MasterData } from './MasterData';
using { com.bayer.SXTENDER.MasterDataViews } from './MasterDataViews';
using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using { com.bayer.SXTENDER.TransactionalDataViews } from '../db/TransactionalDataViews';
using { com.bayer.SXTENDER.TransactionalDataConversion} from '../db/TransactionalDataConversion';
using { com.bayer.SXTENDER.IntegrationDataConversion } from './IntegrationDataConversion';

entity PublicMarketTenders as projection on IntegrationDataConversion.PublicMarketTenders;
entity PublicMarketBuyers as projection on IntegrationDataConversion.PublicMarketBuyers;
entity PublicMarketProducts as projection on IntegrationDataConversion.PublicMarketProducts;
//entity CountryCurrency @readonly as projection on MasterDataViews.CountryCurrency;

entity SalesOpportunities: cuid, managed {
    CountryCode: String;
    TenderReference: String;
    Classification: String;
    TenderChannel: String;
    PublicationDate: DateTime;
    OfferDueDate: DateTime;
    NextPublicationDate: DateTime;
    ExpectedAwardDate: DateTime;
    ContractLength: Integer;
    ExtensionPeriod: Integer;
    TenderMatchingStatus: String;
    Description: String;
    FoldersCreated: Boolean;
    Currency: String;
    OpportunityValue: Double;
    Division: String(100);
    Institute: association to MasterData.PT_TMINST;
    Products: Composition of many SalesOpportunityProducts on Products.Opportunity = $self;
}

entity SalesOpportunityProducts: cuid, managed {
    BrandID: Integer;
    BrandName: String;
    Division: String(100);
    ProductPackName: String;
    ProductPackId: Integer;
    Comment: String;
    RecommendedPrice: Double;
    RequestedQuantity: Integer;
    Uom: String;
    Opportunity: Association to SalesOpportunities;
}

//entity SalesOpportunityInstitute as projection on MasterData.PT_TMINST;