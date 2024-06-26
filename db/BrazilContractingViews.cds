namespace com.bayer.SXTENDER.BrazilContractingViews;

using { User, Country, managed, cuid } from '@sap/cds/common';
using { com.bayer.SXTENDER.MasterData } from './MasterData';
using { com.bayer.SXTENDER.AdminData } from './AdminData';
using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using { com.bayer.SXTENDER.TransactionalDataConversion} from '../db/TransactionalDataConversion';
using { com.bayer.SXTENDER.BrazilContractingData} from '../db/BrazilContractingData';
using { com.bayer.SXTENDER.MasterData.SAP} from './SAP';

entity ContractsView as select from BrazilContractingData.Contracts as Contracts
    inner join AdminData.PT_TMUSER as ModifiedByUser on ModifiedByUser.CWID = Contracts.modifiedBy
    inner join AdminData.PT_TMUSER as CreatedByUser on CreatedByUser.CWID = Contracts.createdBy {
    key Contracts.ID,
        Contracts.TenderID,
        Contracts.OfferID,
        Contracts.InstituteID,
        Contracts.Institute.InstituteName,
        Contracts.Institute.State as InstState,
        Contracts.DistributorID,
        Contracts.Distributor.DistributorName,
        Contracts.Distributor.State as DistState,
        Contracts.ContractNumber,
        Contracts.IbizProcessNumber,
        Contracts.ContractType,
        Contracts.OBS,
        Contracts.IbizContractID,
        Contracts.IbizContractNumber,
        Contracts.IbizContractSignDate,
        Contracts.StartDate,
        Contracts.EndDate,
        Contracts.Status.Status,
        max(Contracts.SalesOrders.Status.Status) as SalesOrderStatus:String,
        sum(Contracts.ContractProducts.OfferProduct.PriceCondition.CommercialProposal * Contracts.ContractProducts.OfferProduct.RequestedVolume) as TotalValue:Decimal,
        Contracts.modifiedBy,
        Contracts.modifiedAt,
        Contracts.createdBy,
        ModifiedByUser.UserName as modifiedByName,
        CreatedByUser.UserName as createdByName,
        Contracts.Tender.TenderName
}group by Contracts.ID,
        Contracts.TenderID,
        Contracts.OfferID,
        Contracts.InstituteID,
        Contracts.Institute.InstituteName,
        Contracts.Institute.State,
        Contracts.DistributorID,
        Contracts.Distributor.DistributorName,
        Contracts.Distributor.State,
        Contracts.ContractNumber,
        Contracts.IbizProcessNumber,
        Contracts.ContractType,
        Contracts.OBS,
        Contracts.IbizContractID,
        Contracts.IbizContractNumber,
        Contracts.IbizContractSignDate,
        Contracts.StartDate,
        Contracts.EndDate,
        Contracts.Status.Status,
        Contracts.modifiedBy,
        Contracts.modifiedAt,
        Contracts.createdBy,
        ModifiedByUser.UserName,
        CreatedByUser.UserName,
        Contracts.Tender.TenderName;

entity ContractProductsView as select from BrazilContractingData.ContractProducts as ContractProducts
left outer join BrazilContractingViews.AdhesionContractCompositionView as AdhesionContract 
    on ContractProducts.OfferID = AdhesionContract.OfferID
    and ContractProducts.ProductPackID = AdhesionContract.ProductPackID
    and ContractProducts.LotID = AdhesionContract.LotID
    {
    key ContractProducts.ID,
        ContractProducts.Contract.ID as Contract_ID,
        ContractProducts.ProductPackID,                                          
        ContractProducts.OfferID,                                      
        ContractProducts.RequestedVolume,   
        ContractProducts.IbizItemType,
        ContractProducts.LotID,
        ContractProducts.ContractPrice,        
        ContractProducts.OfferProduct.RequestedVolume as OfferProductVolume,                                       
        ContractProducts.OfferProduct.UnitPerPack as UoM,
        ContractProducts.OfferProduct.SKU.PRODUCTPACKNAME as ProductPackName,
        ContractProducts.OfferProduct.PriceCondition.CommercialProposal as CommercialPrice,
        sum(ContractProducts.SalesOrderProducts.RequestedQty) / NULLIF(ContractProducts.RequestedVolume, 0) as DeliveredVolume: Integer,
        AdhesionContract.ExistingAdhesionContractsVolume,
        AdhesionContract.RemainingAdhesionContractsVolume,
}group by ContractProducts.ID,
        ContractProducts.Contract.ID,
        ContractProducts.ProductPackID,                                          
        ContractProducts.OfferID,                                      
        ContractProducts.RequestedVolume,   
        ContractProducts.IbizItemType,
        ContractProducts.LotID,
        ContractProducts.ContractPrice,        
        ContractProducts.OfferProduct.RequestedVolume,                                       
        ContractProducts.OfferProduct.UnitPerPack,
        ContractProducts.OfferProduct.SKU.PRODUCTPACKNAME,
        ContractProducts.OfferProduct.PriceCondition.CommercialProposal,
        AdhesionContract.ExistingAdhesionContractsVolume,
        AdhesionContract.RemainingAdhesionContractsVolume;

entity AdhesionContractCompositionView as select from BrazilContractingData.ContractProducts as ContractProducts
{
    ContractProducts.ProductPackID,
    ContractProducts.OfferID,
    ContractProducts.LotID,
    sum(ContractProducts.RequestedVolume) as ExistingAdhesionContractsVolume:Integer,
    (2 * ContractProducts.OfferProduct.RequestedVolume - sum(ContractProducts.RequestedVolume)) as RemainingAdhesionContractsVolume:Integer,
}where ContractProducts.Contract.ContractType = 'Adhesion Contract'
group by ContractProducts.ProductPackID,
    ContractProducts.OfferID,
    ContractProducts.LotID,
    ContractProducts.OfferProduct.RequestedVolume;

entity SalesOrdersView as select from BrazilContractingData.SalesOrders as SalesOrders {
    key SalesOrders.ID,
        SalesOrders.Contract.ID as Contract_ID,
        SalesOrders.EmpenhoNumber,      
        SalesOrders.InstituteID,
        SalesOrders.Contract.Institute.InstituteName,                                      
        SalesOrders.DistributorID,
        SalesOrders.Contract.Distributor.DistributorName,                                      
        SalesOrders.EmpenhoID,             
        SalesOrders.SalesOrderNumber,       
        SalesOrders.IbizProcessNumber,          
        SalesOrders.CommitmentDate,         
        SalesOrders.CommitmentDeliveryDate, 
        SalesOrders.CommitmentCreationDate,
        SalesOrders.Status.Status,
        SalesOrders.createdAt,
        ifnull(sum((SalesOrders.SalesOrderProducts.OfferProduct.PriceCondition.CommercialProposal * SalesOrders.SalesOrderProducts.RequestedQty)), '0') as TotalAmount:Double
} group by SalesOrders.ID,
        SalesOrders.Contract.ID,
        SalesOrders.EmpenhoNumber,      
        SalesOrders.InstituteID,
        SalesOrders.Contract.Institute.InstituteName,                                      
        SalesOrders.DistributorID,
        SalesOrders.Contract.Distributor.DistributorName,                                      
        SalesOrders.EmpenhoID,             
        SalesOrders.SalesOrderNumber,       
        SalesOrders.IbizProcessNumber,          
        SalesOrders.CommitmentDate,         
        SalesOrders.CommitmentDeliveryDate, 
        SalesOrders.CommitmentCreationDate,
        SalesOrders.Status.Status,
        SalesOrders.createdAt;

entity OfferProductCompositionView as select from ContractProductsView as ContractProductsView
inner join TransactionalData.PT_TMOFPR as OfferProduct
    on OfferProduct.OfferID = ContractProductsView.OfferID
    and OfferProduct.ProductCode = ContractProductsView.ProductPackID
    and OfferProduct.LotID = ContractProductsView.LotID
{
    OfferProduct.OfferID,
    OfferProduct.ProductCode,
    OfferProduct.LotID,
    (OfferProduct.SORTER + 1) as SORTER: Integer
}group by OfferProduct.OfferID,
    OfferProduct.ProductCode,
    OfferProduct.LotID,
    OfferProduct.SORTER;

entity SalesOrderProductsView as select from BrazilContractingData.SalesOrderProducts as SalesOrderProducts
inner join SalesOrdersView as SalesOrdersView
    on SalesOrdersView.ID = SalesOrderProducts.SalesOrder.ID
left outer join MasterData.PT_TMSKUPRDPCK as sku
    on sku.CountryCode = 'BR'
    and sku.ProductPackID = SalesOrderProducts.ProductPackID
inner join OfferProductCompositionView as OfferProductView
    on OfferProductView.OfferID = SalesOrderProducts.OfferID
    and OfferProductView.ProductCode = SalesOrderProducts.ProductPackID
    and OfferProductView.LotID = SalesOrderProducts.LotID
left outer join SAP.BrazilDeliveriesItems as BrazilDeliveriesItems
    on OfferProductView.SORTER = BrazilDeliveriesItems.SALES_ITEM 
    and SalesOrdersView.SalesOrderNumber = BrazilDeliveriesItems.SALES_DOCUMENT
    and sku.SKUCode = BrazilDeliveriesItems.MATERIAL
{
    key SalesOrderProducts.ID,
        SalesOrderProducts.SalesOrder.ID as SalesOrder_ID,
        SalesOrderProducts.SalesOrder.Contract.ID as Contract_ID,
        SalesOrderProducts.ProductPackID,           
        SalesOrderProducts.OfferID,                
        SalesOrderProducts.RequestedQty,           
        SalesOrderProducts.RequestedDeliveryDate,
        SalesOrderProducts.IbizEmpenhoProductID,
        SalesOrderProducts.IbizContractProductID,
        SalesOrderProducts.SalesOrderPrice,
        SalesOrderProducts.LotID,
        SalesOrderProducts.Comment,
        SalesOrderProducts.OfferProduct.SKU.PRODUCTPACKNAME as ProductPackName,
        sum(BrazilDeliveriesItems.DELIVERY_QUANTITY) as DeliveryQuantity: Integer,
        max(BrazilDeliveriesItems.DATE_DELIVERY) as ActualDeliveryDate: Date,
        // SalesOrderProducts.OfferProduct.Deliveries.ActualDeliveredProductQty as ActualDeliveredProductQty,  
        // SalesOrderProducts.OfferProduct.Deliveries.ActualDeliveryDate as ActualDeliveryDate,  
        SalesOrderProducts.OfferProduct.UnitPerPack as UoM,
        SalesOrderProducts.OfferProduct.PriceCondition.CommercialProposal as Price
}group by SalesOrderProducts.ID,
        SalesOrderProducts.SalesOrder.ID,
        SalesOrderProducts.SalesOrder.Contract.ID,
        SalesOrderProducts.ProductPackID,           
        SalesOrderProducts.OfferID,                
        SalesOrderProducts.RequestedQty,           
        SalesOrderProducts.RequestedDeliveryDate,
        SalesOrderProducts.IbizEmpenhoProductID,
        SalesOrderProducts.IbizContractProductID,
        SalesOrderProducts.SalesOrderPrice,
        SalesOrderProducts.LotID,
        SalesOrderProducts.Comment,
        SalesOrderProducts.OfferProduct.SKU.PRODUCTPACKNAME,
        SalesOrderProducts.OfferProduct.UnitPerPack,
        SalesOrderProducts.OfferProduct.PriceCondition.CommercialProposal;
