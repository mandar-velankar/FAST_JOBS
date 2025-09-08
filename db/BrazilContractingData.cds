namespace com.bayer.SXTENDER.BrazilContractingData;

using { User, Country, managed, cuid } from '@sap/cds/common';
using { com.bayer.SXTENDER.MasterData } from './MasterData';
using { com.bayer.SXTENDER.AdminData } from './AdminData';
using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';

@cds.persistence.exists
entity Contracts : managed, cuid {
        TenderID                : String(50) not null;     
        OfferID                 : String(30) not null;     
        InstituteID             : Integer not null;         
        DistributorID           : Integer not null;         
        ContractNumber          : String;
        IbizProcessNumber       : String;
        ContractType            : String;
        OBS                     : String;
        IbizContractID          : Integer;
        IbizContractNumber      : String;
        IbizContractSignDate    : Date;
        StartDate               : Date;
        EndDate                 : Date;
        StatusID                : UUID;                              
        //Associations
        Offer                   : Association to TransactionalData.PT_TMOFRS
                                    on Offer.OfferID = OfferID;
        OfferProducts           : Association to many TransactionalData.PT_TMOFPR
                                    on OfferProducts.OfferID = OfferID;
        Tender                  : Association to TransactionalData.PT_TMTEND
                                    on Tender.TenderID = TenderID;
        Institute               : Association to MasterData.PT_TMINST
                                    on Institute.InstituteID = InstituteID;
        Distributor             : Association to MasterData.PT_TMDIST
                                    on Distributor.DistributorID = DistributorID;
        Status                  : Association to AdminData.ContractStatus            
                                    on Status.ID = StatusID;
        ContractProducts        : Association to many ContractProducts 
                                    on ContractProducts.Contract = $self;
        SalesOrders             : Association to many SalesOrders 
                                    on SalesOrders.Contract = $self;
}

@cds.persistence.exists
entity ContractProducts: managed, cuid {
        ProductPackID               : Integer not null;   
        IbizContractProductID       : Integer;                          
        OfferID                     : String(30) not null;                          
        RequestedVolume             : Integer;
        IbizItemType                : String;
        LotID                       : Integer;
        ContractPrice               : Decimal;
        //Associations
        OfferProduct                : Association to TransactionalData.PT_TMOFPR
                                        on OfferProduct.ProductCode = ProductPackID
                                        and OfferProduct.OfferID = OfferID
                                        and OfferProduct.LotID = LotID;
        Contract                    : Association to Contracts;    
        SalesOrderProducts          : Association to SalesOrderProducts 
                                        on SalesOrderProducts.OfferID = OfferID
                                        and SalesOrderProducts.ProductPackID = ProductPackID
                                        and SalesOrderProducts.LotID = LotID       
}

@cds.persistence.exists
entity SalesOrders: managed, cuid {
        EmpenhoID               : Integer;
        InstituteID             : Integer not null;                                 
        DistributorID           : Integer not null;                                 
        EmpenhoNumber           : String;
        SalesOrderNumber        : String(20);
        IbizProcessNumber       : String(5000);
        CommitmentDate          : Date;
        CommitmentDeliveryDate  : Date;
        CommitmentCreationDate  : Date;
        StatusID                : UUID;                                             
        //Associations
        Contract                : Association to Contracts;
        Institute               : Association to MasterData.PT_TMINST
                                    on Institute.InstituteID = InstituteID;
        Distributor             : Association to MasterData.PT_TMDIST
                                    on Distributor.DistributorID = DistributorID;
        Status                  : Association to AdminData.SalesOrderStatus         
                                    on Status.ID = StatusID;
        SalesOrderProducts      : Association to many SalesOrderProducts on SalesOrderProducts.SalesOrder = $self;
}

@cds.persistence.exists
entity SalesOrderProducts: managed, cuid {
        ProductPackID           : Integer not null;
        OfferID                 : String(30) not null; 
        RequestedQty            : Double;
        RequestedDeliveryDate   : Date;
        IbizEmpenhoProductID    : Integer;
        IbizContractProductID   : Integer;
        SalesOrderPrice         : Double;
        LotID                   : Integer;
        Comment                 : String;
        //Associations
        SalesOrder              : Association to SalesOrders;
        OfferProduct            : Association to TransactionalData.PT_TMOFPR
                                     on OfferProduct.ProductCode = ProductPackID
                                     and OfferProduct.OfferID = OfferID
                                     and OfferProduct.LotID = LotID;
}