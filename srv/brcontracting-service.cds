using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using { com.bayer.SXTENDER.BrazilContractingData } from '../db/BrazilContractingData';
using { com.bayer.SXTENDER.MasterData } from '../db/MasterData';
using { com.bayer.SXTENDER.MasterDataViews } from '../db/MasterDataViews';
using { com.bayer.SXTENDER.AdminData } from '../db/AdminData';

service BrazilContractingService @(path: 'brazilcontracting') @(requires:['f_tndr_cag_admin','f_tndr_cag_brcontracting_user','f_tndr_cag_technical_user','authenticated-user']){
     
    entity Contracts @(cds.redirection.target:true) as projection on BrazilContractingData.Contracts;
     
    entity ContractProducts @(cds.redirection.target:true) as projection on BrazilContractingData.ContractProducts;
     
    entity SalesOrders @(cds.redirection.target:true) as projection on BrazilContractingData.SalesOrders;
     
    entity SalesOrderProducts @(cds.redirection.target:true) as projection on BrazilContractingData.SalesOrderProducts;
     
    entity PT_TMINST as projection on MasterData.PT_TMINST;
     
    entity PT_TMDIST as projection on MasterData.PT_TMDIST;
     
    entity PT_TMCTPRDPCK as projection on MasterData.PT_TMCTPRDPCK;
     
    entity PT_TMTEND @(cds.redirection.target:true) as projection on TransactionalData.PT_TMTEND;
     
    entity PT_TMPRDPCK as projection on MasterData.PT_TMPRDPCK;
     
    entity ContractStatus as projection on AdminData.ContractStatus;
     
    entity SalesOrderStatus as projection on AdminData.SalesOrderStatus;
     
    entity AppConfig @readonly as projection on AdminData.AppConfig;

    entity PriceCondition as projection on TransactionalData.PriceCondition;

     
    entity PT_TMOFPR as projection on TransactionalData.PT_TMOFPR;
     
    entity PT_TMOFRS as projection on TransactionalData.PT_TMOFRS;

    action createSalesOrder(salesOrderID: String) returns String;
    action createContract(contractID: String) returns String;
    action approveRejectContract(sContractStatus: String, contractID: String) returns String;
    action approveRejectSalesOrder(sSalesOrderStatus: String, salesOrderID: String) returns String;
    action checkSAPDeliveries(salesOrderID: String) returns String;
}