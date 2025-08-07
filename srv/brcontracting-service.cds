using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using { com.bayer.SXTENDER.BrazilContractingData } from '../db/BrazilContractingData';
using { com.bayer.SXTENDER.MasterData } from '../db/MasterData';
using { com.bayer.SXTENDER.MasterDataViews } from '../db/MasterDataViews';
using { com.bayer.SXTENDER.BrazilContractingViews } from '../db/BrazilContractingViews';
using { com.bayer.SXTENDER.AdminData } from '../db/AdminData';

service BrazilContractingService @(path: 'brazilcontracting') @(requires:['f_tndr_cag_admin','f_tndr_cag_brcontracting_user','f_tndr_cag_technical_user','authenticated-user']){
    @cds.persistence.exists
    entity Contracts @(cds.redirection.target:true) as projection on BrazilContractingData.Contracts;
    @cds.persistence.exists
    entity ContractProducts @(cds.redirection.target:true) as projection on BrazilContractingData.ContractProducts;
    @cds.persistence.exists
    entity SalesOrders @(cds.redirection.target:true) as projection on BrazilContractingData.SalesOrders;
    @cds.persistence.exists
    entity SalesOrderProducts @(cds.redirection.target:true) as projection on BrazilContractingData.SalesOrderProducts;
    @cds.persistence.exists
    entity PT_TMINST as projection on MasterData.PT_TMINST;
    @cds.persistence.exists
    entity PT_TMDIST as projection on MasterData.PT_TMDIST;
    @cds.persistence.exists
    entity PT_TMCTPRDPCK as projection on MasterData.PT_TMCTPRDPCK;
    @cds.persistence.exists
    entity PT_TMTEND @(cds.redirection.target:true) as projection on TransactionalData.PT_TMTEND;
    @cds.persistence.exists
    entity PT_TMPRDPCK as projection on MasterData.PT_TMPRDPCK;
    @cds.persistence.exists
    entity ContractsView as projection on BrazilContractingViews.ContractsView;
    @cds.persistence.exists
    entity ContractProductsView as projection on BrazilContractingViews.ContractProductsView;
    @cds.persistence.exists
    entity SalesOrdersView as projection on BrazilContractingViews.SalesOrdersView;
    @cds.persistence.exists
    entity SalesOrderProductsView as projection on BrazilContractingViews.SalesOrderProductsView;
    @cds.persistence.exists
    entity ContractStatus as projection on AdminData.ContractStatus;
    @cds.persistence.exists
    entity SalesOrderStatus as projection on AdminData.SalesOrderStatus;
    @cds.persistence.exists
    entity AppConfig @readonly as projection on AdminData.AppConfig;
    @cds.persistence.exists
    entity PriceCondition as projection on TransactionalData.PriceCondition;

    @cds.persistence.exists
    entity PT_TMOFPR as projection on TransactionalData.PT_TMOFPR;
    @cds.persistence.exists
    entity PT_TMOFRS as projection on TransactionalData.PT_TMOFRS;

    action createSalesOrder(salesOrderID: String) returns String;
    action createContract(contractID: String) returns String;
    action approveRejectContract(sContractStatus: String, contractID: String) returns String;
    action approveRejectSalesOrder(sSalesOrderStatus: String, salesOrderID: String) returns String;
    action checkSAPDeliveries(salesOrderID: String) returns String;
}