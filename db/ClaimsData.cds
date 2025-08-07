namespace com.bayer.SXTENDER.ClaimsData;

using { User, Country, managed, cuid } from '@sap/cds/common';
using { com.bayer.SXTENDER.MasterData } from './MasterData';
using { com.bayer.SXTENDER.AdminData } from './AdminData';
using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using {com.bayer.SXTENDER.TransactionalDataViews} from '../db/TransactionalDataViews';


@cds.persistence.exists
entity ClaimFiles : managed, cuid {
    CountryCode             : String not null;//based on selected country on UI
    ClaimFileFormat         : String not null;//not sure... possibly a conventional number that allows identify file-specific processing
    FileName                : String not null;//name of file as loaded
    DateFrom                : Date;
    DateTo                  : Date;
    FilePeriod              : Date;//as per selection by user when loading file
    DistributorID           : Integer;//as per selection by user when loading file
    DistributorName         : String;
    WholesalerPurchaseAmount: Double;
    NetSales                : Double;
    TotalClaimAmount        : Double;
    Status                  : String;//Pending upon upload, then as per status set through approvals on screen
    ApprovalsCount          : Integer;
    ClaimData               : Association to many ClaimData on ClaimData.ClaimFiles = $self;
    ContrastAgentSalesDataNL: Association to many ContrastAgentSalesDataNL on ContrastAgentSalesDataNL.ClaimFiles = $self;
    ContrastAgentSalesData  : Association to many ContrastAgentSalesData on ContrastAgentSalesData.ClaimFiles = $self;    
    ClaimApprovals          : Association to many ClaimApprovals on ClaimApprovals.ClaimFiles = $self;    
};
@cds.persistence.exists
entity ClaimData : managed, cuid {
    CountryCode                             : String;
    OfferID                                 : String;   //link to offer mapped to claim line item
    ProductPackID                           : Integer;  //link to product within offer mapped on claim line item
    PRODUCTPACKNAME                         : String;
    EANNumber                               : String;
    External_InstituteId                    : String;
    MainInstituteID                         : Integer;  //set based on customer mapping on each line of file
    ChildInstituteID                        : Integer;  //set based on customer mapping on each line of file
    MainInstituteName                       : String;
    ChildInstituteName                      : String;
    DistributorID                           : Integer;
    Date                                    : Date; //coming in the extract (date when sales is excuted)
    Type                                    : String;
    Quantity                                : Double; //coming in the extract
    WholesalerPurchasePrice                 : Double; //coming in the extract 
    WholesalerDistributionArrangement       : Double; //coming in the extract (if not calculate)
    AppliedWholesalerCorrection             : Double; //coming in the extract
    WholesalerContractPrice                 : Double; //coming in the extract
    TotalClaim                              : Double; //coming in the extract
    MainCustomerForContract                 : Integer;
    FASTPendingCorrection                   : Double;
    BrandContractVolume                     : Double;
    BrandContractCalculatedVolume           : Double;
    PercentageUsage                         : Double;
    UsedVolume                              : Double;
    BrandId                                 : String;
    BrandName                               : String;
    Balance                                 : Integer;
    BrandUsedVolume                         : Double;
    BrandUsedCalculatedVolume               : Double;
    WholesalerContractPriceClaim            : Double;
    WholesalerDistributionArrangementClaim  : Double; 
    TotalWholesalerClaim                    : Double;
    FASTContractClaim                       : Double; 
    FASTDistributionArrangementClaim        : Double;
    TotalFASTClaim                          : Double;
    PercentageDifference                    : Double;
    Status                                  : String;
    Comment                                 : String;
    FASTWholesalerPurchasePrice             : Double;
    FASTContractPrice                       : Double;
    FASTDistributionArrangement             : Double;
    FASTDistributionAgreementType           : String;
    QC1Passed                               : Boolean;
    QC2Passed                               : Boolean;
    WholesalerClaim1                        : Double;
    WholesalerClaim2                        : Double;
    FASTClaim1                              : Double;
    FASTClaim2                              : Double;
    NrFaktury                               : String;
    RoznicaCenaZakupuPNM                    : Double;
    WartoscPNM                              : Double;
    IloscSztukDoWyrownania                  : Double;
    NrFakturyZakupu                         : String;
    SKUCode                                 : Integer;
    RowOrder                                : Integer;
    ClaimFiles                              : Association to ClaimFiles;
    Product                                 : Association to TransactionalData.PT_TMOFPR 
                                                on Product.OfferID = OfferID 
                                                and Product.ProductCode = ProductPackID 
                                                and Product.Active = 1;
    SKU                                     : Association to MasterData.PT_TMPRDPCK 
                                                on SKU.PRODUCTPACKID = ProductPackID;
    SKUCountry                              : Association to MasterData.PT_TMCTPRDPCK 
                                                on  SKUCountry.PRODUCTPACKID = ProductPackID 
                                                and SKUCountry.COUNTRYCODE = CountryCode;
};
@cds.persistence.exists
entity ContrastAgentSalesDataNL: cuid, managed {
    ID                              : Integer;
    TypeRecord                      : String;
    DatumVan                        : Date;
    DatumTm                         : Date;
    IDFNummerKlant                  : String;
    EANNrKlant                      : String;
    Klantnaam                       : String;
    EANNrArtikel                    : String;
    ZINrArtikel                     : String;
    ArtnrLeverancier                : String;
    NaamArtikel                     : String;
    Eenheid1                        : String;
    Eenheid2                        : String;
    VastePrijs                      : Double;
    Kortingsperc1                   : Double;
    Kortingsperc2                   : Double;
    Inkoopprijs                     : Double;
    Claimpercentage                 : Double;
    Claimbedrag                     : Double;
    AantalGeleverd                  : Integer;
    Claim1Bedrag                    : Double;
    Claim2Bedrag                    : Double;
    ClaimTotaal                     : Double;
    ClaimPeriode                    : String;
    ClaimGrondslag                  : String;
    Klantnummer                     : Integer;
    KlantenOvidiusPharmaceutische   : String;
    IDFNummer                       : String;
    KlantenLairesseZiekenhuis       : String;
    Periode                         : String;
    ZIndexNummer                    : String;
    ArtikelNummerLeverancier        : String;
    ArtikelNaam                     : String;
    EenheidStuks                    : Integer;
    Claim1PerEenheid                : Double;
    TotaalClaim1                    : Double;
    Claim2PerEenheid                : Double;
    TotaalClaim2                    : Double;
    ClaimbedragTotaal               : Double;
    Leverancier                     : String;
    AccountcombinatieNaam           : String;
    Woonplaats                      : String;
    IDFCode                         : String;
    Uitleverdatum                   : Date;
    OrderNummer                     : String;
    RegelNr                         : Integer;
    Jaarweek                        : Integer;
    Jaar                            : Integer;
    KalenderMaand                   : Integer;
    ZINummer                        : String;
    ArtikelnrLeverancier            : String;
    ArtikelOmschrijving             : String;
    VerpakkingAantal                : Integer;
    VerpakkingsEenheid              : String;
    AIP                             : Double;
    DAPrijs                         : Double;
    LeveranciersbijdragePercentage  : Double;
    Grondslag                       : String;
    LeveranciersbijdrageBedrag      : Double;
    TotaalLeveranciersbijdrage      : Double;
    Ultimo                          : Double;
    Betaald                         : Double;
    DAClaimPerArtikel               : Double;
    TotaleClaimPerArtikel           : Double;
    TotaleClaimPerRegel             : Double;
    ContractPrice                   : Double;
    WPP                             : Double;
    Claim1                          : Double;
    Claim2                          : Double;
    Quantity                        : Double;
    TotalClaim                      : Double;
    Date                            : Date;
    ClaimFiles: Association to ClaimFiles;
};
@cds.persistence.exists
entity ContrastAgentSalesData: cuid, managed {
    NazwaArtykulu                    : String;
    KODEANArtykulu                   : String;
    IloscSztukSprzedanychKlientowi   : Integer;
    CenaZakupuNetto                  : Double;
    PodstawaNaliczeniaMarzyNettoPNM  : Double;
    KodKlientaBayer                  : String;
    KlientNazwa                      : String;
    NrFaktury                        : String;
    DataSprzedazy                    : Date;
    RoznicaCenaZakupuPNM             : Double;
    WartoscPNM                       : Double;
    WartoscDoWyrownania              : Double;
    IloscSztukDoWyrownania           : Double;
    NrFakturyZakupu                  : String;
    ClaimFiles: Association to ClaimFiles;
};
@cds.persistence.exists
entity SalesReportFile {
    key DistributorID   : String;
    key CountryCode     : String;
    key FileName        : String;
    key FileType        : String;
    key FilePeriod      : String;
    @Core.MediaType     : 'application/octet-stream'
    content    : LargeBinary;
};
@cds.persistence.exists
entity ClaimApproverTypes: cuid, managed {
    CountryCode: String;
    ApproverType: String;
    ApproverCWID: String;
    ApproverName: String;
    ApproverEmail: String;
    Hierarchy: Integer;
};
@cds.persistence.exists
entity ClaimApprovals: cuid, managed {
    ApproverName: String;
    ApproverEmail: String;
    ApproverCWID: String;
    Hierarchy: Integer;
    Status: String;
    ClaimFiles: Association to ClaimFiles;
};
@cds.persistence.exists
entity ExcelClaimFileSalesReportTemplate {
    key templateId          : String(100);
    countryCode             : String;
    section                 : String;
    title                   : String(100);
    filename                : String(250);
    content                 : LargeBinary @Core.MediaType: mediaType;//'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    mediaType               : String @Core.IsMediaType;
}
@cds.persistence.exists
entity SalesReportFileFieldMetaData {
    Wholesaler              : String;
    FieldName               : String;
    FieldLength             : Integer;
}

