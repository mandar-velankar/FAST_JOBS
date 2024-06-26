namespace com.bayer.SXTENDER.MasterData.SAP;

using { Currency, User, Country, managed, cuid } from '@sap/cds/common';
using { 
	E1KNA1M, E1KNA11, E1KNB1M, E1MARAM, E1MARA1, E1MAKTM, E1MARCM, E1MARDM, E1MARMM,E1MBEWM, E1MVKEM, E1MLANM, E1MTXHM, E1MTXLM, E1KNVVM, E1KNVKM, E1KNKKM
} from './SAPTypes';


entity BrazilMaterials: cuid, managed {
	COD					: String(18);			// SAP product code - key
	NOME				: String(40);			// Product description
	CENTRO				: String(4);			// Material plant code
	APRES				: String;				// Sales text
	ORG_VENDAS			: String(4);			// Sales Org
	CANAL_DISTR			: String(2);			// Distribution channel
	SETOR_ATIV			: String(2);			// Division
	NREG				: String(13);			// Register Number
	CBAR				: String(18);			// Barcode (EAN)
	GRUPO_MAT3		    : String(3);			// Material group 3 code
	BLOQ_MATERIAL		: String(2);			// Material Block
	PROCEDENCIA			: String(3);			// Origin country
	ORIGEM				: String(1);			// Material origin
	STATUS				: String(1); 			// Material status - If the material is checked for deletion send B, else send A
	BRAND               : String;               // not in spec? String ok?
}

entity BrazilCustomers: cuid, managed {
	CODIGO			    : String(10);			// Customer code in SAP - key
	REPRES				: String(3);			// Flag if the customer is a Distributor or Institute ( X = Distributor)
	ORG_VENDAS			: String(4);			// Sales organization
    CANAL_DISTR			: String(2);			// Distribution channel
	SETOR_ATIV	        : String(2);		    // Division - key
	RAZAO				: String;			    // Customer real name  (spec mis match, it was 35 long)
	FANTASIA			: String(10);			// Customer nickname
	ENDERECO			: String(35);			// Address
	BAIRRO				: String(35);			// Neighborhood 
	CIDADE				: String(35);			// City
	CEP					: String(10);			// Zip code
	TELEFONE			: String(16);			// Phone number
	FAX					: String(31);			// Fax
	CNPJ				: String(16);			// Customer fiscal ID 1
	IE					: String(18);			// Customer fiscal ID 1
	EMAIL				: String;			    // E-mail (Spec different? this was specified as 3 long??)
	REGIAO				: String(3);			// Customer federation state
	UF					: String(3);			// Customer federation state
	BLOQ				: String(1);			// Flag if customer is blocked
	GRP_CLIENTE			: String(3);			// Customer group 4
	LISTA_PRC			: String(2);			// Customer price list
	COND_PAGTO          : String(4);			// Not in spec? String(4) ok?
	STATUS				: String(1); 			// Customer status - A = Insert / Change, D = Deletion
}

entity BrazilPrices : cuid, managed {
	CODIGO			    : String(18);			// Material code - key
	NOME				: String(40);			// Material description
	ORG_VENDAS			: String(4);			// Sales organization
	SETOR_ATV			: String(2);			// Division
	DATA_INI			: Date;					// Initial validate date
	DATA_FIM			: Date;					// End validate date
	PRC_PADRAO			: Double;				// Material price
	DESC_PADRAO			: Double;				// Material discount
	UNI_PRECO			: String(5);			// Price unit
	UNI_MEDIDA			: String(3);			// Material measure unit
	CLIENTE				: String(10);			// Customer code
	PRC_LISTA			: String(2);			// Price list
	GRP_CLIENTE			: String(3);			// Customer group 4
	REG_ORIGEM			: String(3);			// Plant federation state
	REG_DESTINO			: String(3);			// Customer federation state
    TYPE                : String(4);            // Price List Type
}

entity BrazilEmpenho : cuid, managed {
	NOTA_FISCAL			: String(9);			// Legal number
	LICITACAO			: String(10);			// SAP contract number
	EMISSAO				: Date;					// Invoice issue date
	CLIENTE				: String(10);			// Customer code
	ITEM				: String(6);			// Item number in "Nota Fiscal"
	MATERIAL			: String(18);			// Material code
	QTDE				: Integer;				// Invoice quantity
	UNITARIO			: Double;				// Item unit price
	EMPENHO				: String(15);			// PO number in sales order
	PEDIDO				: String(10);			// Sales order number
	TOTAL_UNITARIO		: Double;				// Total item value in "Nota Fiscal"
}

entity BrazilTaxes: cuid, managed {
	SHIPFROM			: String;
	SHIPTO				: String;
	TAX_GROUP			: String;
	MATERIAL			: String;
	RATE				: String;
	BASE				: String;
}

entity BrazilDeliveriesHeader: cuid, managed {
	SALES_DOCUMENT			: String(10); 			// Sales Document number
	DISTR_CHAN				: String(2);			// Canal de distribuição
	DIVISION				: String(2);			// Setor de Atividade
	CUSTOMER				: String(10);			// Customer SP
	CUSTOMER_NAME			: String(35);			// Name SP
	STATUS_REJECTION		: String(1);			// Rejection status
	STATUS					: String(1);			// Status
	CREATED_BY				: String(12);			// SO Created by
	SALES_CREATED_ON		: Date;					// Sales order Created on
	TERMS_PAY				: String(4);			// Terms of Payment
	SALES_NET				: Double;				// Sales order header net value
	CURRENCY				: String(5);			// Document Currency
	DELIVERY_DOCUMENT		: String(10);			// Delivery document number
	DELIVERY_CREATED_ON		: Date;					// Delivery created on
	DATE_REQUESTED_HEADER	: Date;					// Requested delivery date
	DATE_GOODS_ISSUE		: Date;					// Goods Issue Date
	NUMBER_BILL				: String(10);			// Number of invoice
	DATE_BILL				: Date;					// Billing date
	NET_BILL				: Double;				// Net value billing document
	ITEMS					: Association to many BrazilDeliveriesItems on ITEMS.HEADER = $self; 
}

entity BrazilDeliveriesItems: cuid, managed {
	SALES_DOCUMENT			: String(10); 			// Sales Document number reference to header
	SALES_ITEM				: Integer;				// Sales Document Item
	SALES_REJECTION			: String(2);			// Reason for rejection
	MATERIAL				: String(18);			// Material
	DESCRPTION				: String(40);			// Description                                       
	PRODUCT_HIERARCHY		: String(18);			// Product hierarchy
	SALES_QUTY				: Double;				// Order Quantity
	QUTY_CONFIRMED			: Double;				// Confirmed Quantity
	ITEM_CATEGORY			: String(4);			// Item category
	UNIT_MEASURE			: String(3);			// Unit of measure
	PRICE_UNIT				: Double;				// Pricing unit
	SALES_NET_PRICE			: Double;				// Sales order item net price
	SALES_NET_VALUE			: Double;				// Sales order item net value
	DELIVERY_QUANTITY		: Integer;				// Delivery quantity
	DATE_DELIVERY			: Date;					// Conf.Delv.Date
	DATE_REQUESTED_POSITION	: Date;					// Requested deliv.date (position)
	QUANT_BILL				: Double;				// Billed Quantity
	HEADER					: Association to BrazilDeliveriesHeader;
}

entity BrazilExemptions: cuid, managed {
	SHIP_TO 			: String(3);			// Ship from location (tax region) - Bayer location
	SHIP_FROM			: String(3);			// Ship to location (tax region)
	GROUPS				: String(2);			// Table TAX Group 
	MATNR				: String(18);			// SAP product Code
	RATE				: String(6);			// Aliquot used for exemption process
	BASE				: String(6);			// Base uses for exemption process
}

entity IbizQps: cuid, managed {
	ID_QP 								: Integer; 		//ID QP (workflow)
	ID_PRE_QP 							: Integer; 		//ID Pre QP (pre-workflow)
	ID_LIC_ATRIBUIDA 					: Integer; 		//ID BID by distributor or direct participation
	ID_LIC 								: Integer; 		//ID BID
	NU_SENT_EXT_LINK 					: Integer; 		//Determine if opportunity has already been sent (-1 = changed; 0 = never approved; 1 = yes)
	NU_DIRETO_INDIRETO 					: Integer; 		//Determine if opportunity is direct or indirect (0 = direct; 1 = indirect)
	ID_ALTERNATIVO 						: String; 		//ID Alternative (used for linking legacy bids)
	ID_LICITACAO_IBIZ_LICITA  			: Integer; 		//ID IBIZ Licita (service of IBIZ that capture bids)
	NM_BU_ABREV 						: String; 		//Business Unit
	DT_PUBLICACAO						: String;		//Publication Date
	DT_CAPTURA 							: String; 		//BID's date of capture
	DT_ABERTURA 						: String; 		//Opening date
	DT_FIM_ACOLHIMENTO 					: String; 		//Closing date
	NM_ALTERA_COTACAO					: String; 		//Comment
	NM_MODALIDADE 						: String; 		//BID's modality
	NU_LICITACAO_EDITAL 				: String; 		//BID's document number
	NM_PROCESSO 						: String; 		//Process number
	COD_LICITADOR 						: String; 		//Main Institute's CNPJ
	NM_LICITADOR 						: String; 		//Main Institute's name
	NM_FANTASIA 						: String; 		//Main Institute's secondary name
	NM_MUNICIPIO 						: String; 		//Main Institute's city
	NM_UF_ABREV 						: String; 		//Main Institute's state
	NM_PAIS 							: String; 		//Main Institute's country
	NM_DONO_QP 							: String; 		//Distributor's name (for direct it will be Bayer's name)
	COD_DONO_QP 						: String; 		//Distributor's CNPJ (for direct it will be Bayer's CNPJ)
	NM_FINALIDADE_LIC 					: String; 		//Item's purpose
	NM_LIC_TIPO_PARTICIPACAO 			: String; 		//Participation's type
	NM_CARD_ATUAL 						: String; 		//Current workflow step
	NU_2D_NOTIF_APPLIED_NO_DN_RESPONDED : Integer; 		//Determine if the opportunity wasn't interesting for any DN and was switched automaticly to direct 2 days before the opening date (0 = no; 1 = yes)
	DT_FINALIZADO 						: String; 		//Determine if a workflow was ended by setting a date its end (if it is null, than the workflow is still on going)
	NM_MOTIVO_FINALIZADO 				: String; 		//Determine the motive for ending a workflow
	CCS_QPS								: Composition of many IbizCcsQpsItems on CCS_QPS.parent = $self;	//List of batch and items by products
	DOCS								: Composition of many IbizDocs on DOCS.Qps = $self;	//List of opportunities documents
}

entity IbizCcsQpsItems: cuid {
	ID_CC_QP  						: Integer; 		//ID QP item
	ID_QP 							: Integer; 		//ID QP (workflow)
	NU_LOTE 						: Integer; 		//Batch number
	NU_ITEM 						: Integer; 		//Item number
	ID_CONTEUDO_CATALOGO 			: Integer; 		//ID product
	COD_REFERENCIA 					: String; 		//SAP code
	NU_QTDE_UNITARIA 				: Integer;  	//Unit quantity
	NU_QTDE_EMBALAGEM 				: Integer;  	//Package quantity
	VLR_BASE_CALCULO_UNITARIO 		: Double;  		//Unit price for distributor -> institute sale (with taxes and without discounts)
	VLR_BASE_CALCULO 				: Double; 		//Package price for distributor -> institute sale (with taxes and without discounts)
	VLR_UNITARIO 					: Double;  		//Unit price for bayer -> distributor sale (with taxes and with discounts)
	VLR_EMBALAGEM 					: Double; 		//Package price for bayer -> distributor sale (with taxes and with discounts)
	NU_TIPO 						: Integer; 		//Item type (0=direct sales; 1=sample FOC; 2=lending; 3=consigned; 4=location; 5=service; 6=testing; 7=bonus FOC)
	NU_UF_ICMS 						: String; 		//State
	NU_PORCENTAGEM_ICMS 			: Double; 		//ICMS Tax
	NU_CAP 							: Integer; 		//Determines if CAP is applied (0=no; 1=yes)
	NU_PORCENTAGEM_CAP 				: Double; 		//CAP discount
	NU_PORCENTAGEM_DESCONTO 		: Double; 		//Total discount
	NU_PORCENTAGEM_DESCONTO_INICIAL : Double; 		//Initial discount
	NU_PORCENTAGEM_DESCONTO_ADD 	: Double; 		//Additional discount
	parent							: Association to IbizQps;
}

entity IbizDocs: cuid {
	ID_DOC 				: Integer; 				//ID Document
	CREATED_AT 			: String;  				//Doc's criation date
	NM_TAG 				: String; 				//Doc's label
	NM_DOC 				: String; 				//File name
	FILE_URL 			: String;  				//Signed file url to be requested as GET (expires in 5 minutes)
	Contratos			: Association to IbizContratos;	
	Qps					: Association to IbizQps;	
	Empenhos			: Association to IbizEmpenhos;	
	Resultados			: Association to IbizResultados;	
}

entity IbizResultados: cuid, managed {
	ID_CC_QP 					: Integer; 		// ID QP Item
	ID_QP 						: Integer; 		// ID QP (workflow)
	ID_RESULTADO				: Integer;
	ID_LIC_ATRIBUIDA			: Integer;
	ID_LIC 						: Integer; 		// ID Lic (BID)
	NU_SENT_EXT_LINK 			: Integer; 		// Determine if result has already been sent (-1 = changed; 0 = never approved; 1 = yes)
	NU_GANHEI 					: Integer; 		// Determine if item was won by distributor (-3 = Did not participate; -2 = No result registered; -1 = Result not published by institute; 0 = Lost; 1 = Won; 2 = There are no winners; 3 = Homologated but without a winner)
	CREATED_AT 					: String; 		// Result's date of creation
	NM_SITUACAO 				: String; 		// Result's situation
	NM_MOTIVO_RESULTADO 		: String; 		// Result's reason
	NM_DESC_MOTIVO_RESULTADO 	: String; 		// Result's reason description
	DT_HOMOLOGACAO 				: String; 		// Result's date of homologation
	POSICOES_RESULTADOS			: Composition of many IbizResultadosItems on POSICOES_RESULTADOS.parent = $self; // List of result items
	DOCS						: Composition of many IbizDocs on DOCS.Resultados = $self;	//List of opportunities documents
}

entity IbizResultadosItems: cuid {
	NU_POSICAO					: Integer;		// Position
	NM_PARTICIPANTE				: String;		// Position's participant
	COD_PARTICIPANTE			: String;		// Position's participant CNPJ
	NM_PRODUTO					: String;		// Position's product
	NM_FABRICANTE				: String;		// Position's product manufacturer
	NU_QTDE						: Integer;		// Position's unit quantity
	VLR_UNITARIO				: Double;		// Position's unit price
	VLR_TOTAL					: Double;		// Position's total price
	parent						: Association to IbizResultados;
}

entity IbizContratos: cuid, managed {
	ID_QP						: Integer;		// 
	ID_QP_CONTRATO				: String;		// 
	ID_CONTRATO					: Integer;		// ID Contract
	ID_LIC_ATRIBUIDA			: Integer;		// ID BID by distributor or direct participation
	ID_LIC						: Integer;		// ID BID
	NU_SENT_EXT_LINK			: Integer;		// Determine if contract has already been sent (-1 = changed; 0 = never approved; 1 = yes)
	NM_COMPRADOR				: String;		// Buyer's name
	COD_COMPRADOR				: String;		// Buyer's CNPJ
	NM_VENDEDOR					: String;		// Seller's name
	COD_VENDEDOR				: String;		// Seller's CNPJ
	NM_PROCESSO					: String;		// Process number
	NU_CONTRATO					: String;		// Contract number
	DT_ASSINATURA				: String;		// Contract's date of signature
	DT_INI_VIGENCIA				: String;		// Contract's date of start
	DT_FIM_VIGENCIA				: String;		// Contract's date of end
	NM_TIPO_CONTRATO			: String;		// Contract's type (ATA/Contrato; Adesao; ATA/Contrato Filho; Aditivo)
	NM_OBS						: String;		// Contract's observation
	CCS_CONTRATOS				: Composition of many IbizContratosItems on CCS_CONTRATOS.parent = $self;		// List of contract items
	DOCS						: Composition of many IbizDocs on DOCS.Contratos = $self;		// List of contracts documents
}

entity IbizContratosItems: cuid {
	ID_CC_CONTRATO				: Integer; 		// ID Contract Item
	ID_CC_QP					: Integer; 		// ID QP Item
	ID_CONTRATO					: Integer; 		// ID Contract
	NU_SENT_EXT_LINK			: Integer; 		// Determine if contract item has already been sent (-1 = changed; 0 = never approved; 1 = yes)
	ID_CONTEUDO_CATALOGO		: Integer; 		// ID product
	COD_REFERENCIA				: String; 		// SAP code
	NU_TIPO						: Integer; 		// Item type (0=direct sales; 1=sample FOC; 2=lending; 3=consigned; 4=location; 5=service; 6=testing; 7=bonus FOC)
	NU_LOTE						: Integer; 		// Batch number
	NU_ITEM						: Integer; 		// Item number
	NU_QTDE_UNITARIA			: Integer; 		// Unit quantity
	NU_QTDE_EMBALAGEM			: Integer; 		// Package quantity
	VLR_UNITARIO				: Double; 		// Unit price for distributor -> institute sale (with taxes and without discounts)
	VLR_EMBALAGEM				: Double; 		// Package price for distributor -> institute sale (with taxes and without discounts)
	parent						: Association to IbizContratos;
}


entity IbizEmpenhos: cuid, managed {
	ID_QP_EMPENHO	 : String;				//ID Opportunity and Commitment	
	ID_EMPENHO 		 : Integer;             //ID Commitment
	ID_CONTRATO 	 : Integer;           	//ID Contract
	ID_QP			 : Integer;				//ID Opportunity
	ID_LIC_ATRIBUIDA : Integer; 			//ID BID by distributor or direct participation
	ID_LIC 			 : Integer; 			//ID BID
	NU_SENT_EXT_LINK : Integer; 			//Determine if opportunity has already been sent (-1 = changed; 0 = never approved; 1 = yes)
	NM_COMPRADOR 	 : String; 				//Buyer's name
	COD_COMPRADOR 	 : String; 				//Buyer's CNPJ
	NM_VENDEDOR 	 : String; 				//Seller's name
	COD_VENDEDOR 	 : String; 				//Seller's CNPJ
	NM_PROCESSO 	 : String; 				//Process number
	NU_EMPENHO 	 	 : String; 				//Commitment number
	DT_EMPENHO 		 : String; 				//Commitment date
	DT_ENTREGA 		 : String; 				//Commitment delivery date
	CREATED_AT 		 : String; 				//Commitment creation date
	CCS_EMPENHOS	 : Composition of many IbizCcsEmpenhosItems on CCS_EMPENHOS.parent = $self;  //List of commiments items
	DOCS			 : Composition of many IbizDocs on DOCS.Empenhos = $self; //List of commiments docuemnts
}

entity IbizCcsEmpenhosItems: cuid {
	ID_CC_QP			: Integer;				//ID QP Item
	ID_CC_EMPENHO 		: Integer; 				//ID Commitment Item
	ID_CC_CONTRATO 		: Integer; 				//ID Contract Item
	ID_EMPENHO 			: Integer; 				//ID Commitment
	NU_SENT_EXT_LINK  	: Integer; 				//Determine if contract has already been sent (-1 = changed; 0 = never approved; 1 = yes)
	COD_REFERENCIA 		: String; 				//SAP code
	NU_QTDE_UNITARIA 	: Integer; 				//Unit quantity
	NU_QTDE_EMBALAGEM 	: Integer; 				//Package quantity
	VLR_UNITARIO 		: Double; 				//Unit price for distributor -> institute sale (with taxes and without discounts)
	VLR_EMBALAGEM 		: Double; 				//Package price for distributor -> institute sale (with taxes and without discounts)
	parent 				: Association to IbizEmpenhos;
}


entity ItalyMaterials: cuid, managed {
	MATNR  				: String(18);			// Material Number
	HLEVEL1_NAME    	: String(40);			// Description
	HLEVEL4_CODE    	: String(10);			// Version Number Component
	HLEVEL4_NAME    	: String(40);			// Description
	HLEVEL6_CODE   		: String(18);			// Version Number Component
	HLEVEL6_NAME   		: String(40);			// Description            Distribution channel
	UOM   				: String(3);			// Base Unit of Measure
	COUNTRYOFORIG    	: String(3);			// Country of origin of the material
	COGS    			: Double;				// Standard price
	COGS_UOM    		: String(3);			// Base Unit of Measure
	PRICE_UNIT    		: String(5);			// Price Unit
	MAKTX    			: String(40);			// Material Description
	DIVISION_DESC    	: String(20);			// Division description
	EAN11    			: String(18); 			// EAN number
}

entity ItalyCustomers: cuid, managed {
	E1KNA1M				: E1KNA1M;				// Master customer master basic data (KNA1 - SAP table)
	E1KNA11				: E1KNA11;				// Customer Master: Additional General Fields  (KNA1 - SAP table)
	E1KNB1M				: E1KNB1M;				// Master Customer Master Company Code (KNB1- SAP table )
	E1KNVVM				: E1KNVVM; 				// Master customer master sales data (KNVV- SAP table)
	E1KNVKM				: E1KNVKM;				// Master customer master contact person (KNVK - SAP table)
	E1KNKKM				: E1KNKKM;				// Master customer master credit mgmt control area data (KNKK - SAP table name)
}

entity ItalyDeliveries: cuid, managed {
	VBELN				: String(10); 			// Delivery
	POSNR				: Integer; 			// Delivery Item
	VKBUR				: String(4); 			// Sales Office
	BUKRS				: String(4); 			// Company Code
	KUNNR				: String(10); 			// Ship-to party
	KUNAG				: String(10);			// Sold-to party
	ERNAM				: String(12); 			// Name of Person who Created the Object
	ERDAT				: DateTime; 			// Date on Which Record Was Created
	XABLN				: String(10); 			// Goods Receipt/Issue Slip Number
	WADAT				: DateTime; 			// Goods Issue Date
	WADAT_IST			: DateTime; 			// Actual Goods Movement Date
	ANZPK				: Double; 				// Total number of packages in delivery
	INCO1				: String(3); 			// Incoterms (Part 1)
	INCO2				: String(28); 			// Incoterms (Part 2)
	VSTEL				: String(4); 			// Shipping Point/Receiving Point
	VSBED				: String(2); 			// Shipping Conditions
	LFART				: String(4); 			// Delivery Type
	MATNR				: String(18); 			// Material Number
	WERKS				: String(4); 			// Plant
	LGORT				: String(4); 			// Storage Location
	CHARG				: String(10); 			// Batch Number
	PSTYV				: String(4); 			// Delivery item category
	LFIMG				: Double; 				// Actual quantity delivered (in sales units)
	VRKME				: String(3); 			// Sales unit
	BWART				: String(3); 			// Movement Type (Inventory Management)
	BRGEW				: Double; 				// Gross weight
	NTGEW				: Double; 			    // Net weight
	GEWEI				: String(3); 			// Weight Unit
	VOLUM				: Double; 				// Volume
	VGBEL				: String(10); 			// Document number of the reference document
	VGPOS				: Integer; 				// Item number of the reference item
	PARTNER_ADDR		: Association to PARTNER_ADDR;		// Delivery Document Partner address
	PLANT_ADDR			: Association to PLANT_ADDR;		// Delivery Document Address of plants
}


// this is the IDOC structure
// entity SpainMaterials: cuid, managed {
// 	E1MARAM				: E1MARAM;				// Master material general data (MARA- SAP table)
//     E1MARA1				: E1MARA1;				// Additional Fields for E1MARAM segment  - MARA sap table additional fields
//     E1MAKTM				: E1MAKTM;				// Master material short texts (MAKT - SAP table) : material description
//     E1MARCM				: E1MARCM;				// Master material C segment (MARC : SAP table) :Plant Data for Material
//     E1MARDM				: E1MARDM;				// Master material warehouse/batch segment (MARD : SAP table) -Storage Location Data for Material
//     E1MARMM				: E1MARMM;				// Master material units of measure (MARM - SAP table ):Units of Measure for Material
//     E1MBEWM				: E1MBEWM;				// Master material material valuation (MBEW : SAP table) :Material Valuation
//     E1MVKEM				: E1MVKEM;				// Master material sales data (MVKE : SAP table) Sales Data for Material
//     E1MLANM				: E1MLANM;				// Master material tax classification (MLAN : SAP table)
//     E1MTXHM				: E1MTXHM;				// Master material long text header
//     E1MTXLM				: E1MTXLM;				// Master material long text line item
// }

entity SpainMaterials: cuid, managed {
	MATNR  				: String(18);			// Material Number
	HLEVEL1_NAME    	: String(40);			// Description
	HLEVEL4_CODE    	: String(10);			// Version Number Component
	HLEVEL4_NAME    	: String(40);			// Description
	HLEVEL6_CODE   		: String(18);			// Version Number Component
	HLEVEL6_NAME   		: String(40);			// Description            Distribution channel
	UOM   				: String(3);			// Base Unit of Measure
	COUNTRYOFORIG    	: String(3);			// Country of origin of the material
	COGS    			: Double;				// Standard price
	COGS_UOM    		: String(3);			// Base Unit of Measure
	PRICE_UNIT    		: String(5);			// Price Unit
	MAKTX    			: String(40);			// Material Description
	DIVISION_DESC    	: String(20);			// Division description
	EAN11    			: String(18); 			// EAN number
}

entity SpainCustomers: cuid, managed {
	E1KNA1M				: E1KNA1M;				// Master customer master basic data (KNA1 - SAP table)
    E1KNA11				: E1KNA11;				// Customer Master: Additional General Fields  (KNA1 - SAP table)
    E1KNB1M				: E1KNB1M;				// Master Customer Master Company Code (KNB1- SAP table )
}


entity SpainDeliveries: cuid, managed {
	VBELN				: String(10); 			// Delivery
	POSNR				: Integer; 			// Delivery Item
	VKBUR				: String(4); 			// Sales Office
	BUKRS				: String(4); 			// Company Code
	KUNNR				: String(10); 			// Ship-to party
	ERNAM				: String(12); 			// Name of Person who Created the Object
	ERDAT				: DateTime; 			// Date on Which Record Was Created
	XABLN				: String(10); 			// Goods Receipt/Issue Slip Number
	WADAT				: DateTime; 			// Goods Issue Date
	WADAT_IST			: DateTime; 			// Actual Goods Movement Date
	ANZPK				: Double; 				// Total number of packages in delivery
	INCO1				: String(3); 			// Incoterms (Part 1)
	INCO2				: String(28); 			// Incoterms (Part 2)
	VSTEL				: String(4); 			// Shipping Point/Receiving Point
	VSBED				: String(2); 			// Shipping Conditions
	LFART				: String(4); 			// Delivery Type
	MATNR				: String(18); 			// Material Number
	WERKS				: String(4); 			// Plant
	LGORT				: String(4); 			// Storage Location
	CHARG				: String(10); 			// Batch Number
	PSTYV				: String(4); 			// Delivery item category
	LFIMG				: Double; 				// Actual quantity delivered (in sales units)
	VRKME				: String(3); 			// Sales unit
	BWART				: String(3); 			// Movement Type (Inventory Management)
	BRGEW				: Double; 				// Gross weight
	NTGEW				: Double; 			    // Net weight
	GEWEI				: String(3); 			// Weight Unit
	VOLUM				: Double; 				// Volume
	VGBEL				: String(10); 			// Document number of the reference document
	VGPOS				: Integer;	 			// Item number of the reference item
	PARTNER_ADDR		: Association to PARTNER_ADDR;		// Delivery Document Partner address
	PLANT_ADDR			: Association to PLANT_ADDR;		// Delivery Document Address of plants
}


entity PARTNER_ADDR : cuid {
	TYPE0				: String(1);			// Single-Character Indicator
	ADRNR				: String(10);			// Address
	NAME1				: String(35);			// Name 1
	NAME2				: String(35);			// Name 2
	STRAS				: String(35);			// House number and street
	HAUSN				: String(6);			// House number
	PSTLZ				: String(10);			// Postal code
	ORT01				: String(35);			// City
	REGIO				: String(3);			// Region (State, Province, County)
	LAND1				: String(3);			// Country Key
	XEGLD				: String(1);			// Indicator: European Union Member?
}

entity PLANT_ADDR : cuid{
	WERKS				: String(4);			// Plant
	NAME1				: String(30);			// Name
	STRAS				: String(30);			// House number and street
	PSTLZ				: String(10);			// Postal Code
	ORT01				: String(25);			// City
	LAND1				: String(3);			// Country Key
	REGIO				: String(3);			// Region (State, Province, County)
}

entity SpainRappel : cuid {
	KNUMA 				: String;	
	BONEM 				: String;	
	DATAB 				: String;				// Effective date
	DATBI 				: String;				// Expiry date
	KNUMH 				: String;				// Customer ID
	SOLD_TO 			: String;	
	MATNR 				: String(18);			// Material number
}

entity FASTCoreProduct: cuid, managed {
    ProductInternalID: String;
    UnformattedProductInternalID: String;
    ProductUUID: String;
    ReceiverProductInternalID: String;
    UnformattedReceiverProductInternalID: String;
    ReceiverProductUUID: String;
    ProductTypeCode: String;
    IndustrySectorCode: String;
    RetailProductCategoryCode: String;
    DivisionCode: String;
    DeletedIndicator: Boolean;
    LockedIndicator: Boolean;
    ANPCode: String;
    SerialNumberExplicitnessLevelCode: String;
    QualityManagementInProcurementIsActiveIndicator: Boolean;
    ProductAllocationProcedureID: String;
    ReceiverProductAllocationProcedureID: String;
    ConfigurableProductInternalID: String;
    ReceiverConfigurableProductInternalID: String;
    ProductHierarchyInternalID: String;
    ReceiverProductHierarchyInternalID: String;
    ProductGroupInternalID: String;
    ReceiverProductGroupInternalID: String;
    ExternalProductGroupInternalID: String;
    ReceiverExternalProductGroupInternalID: String;
    BaseMeasureUnitCode: String;
    ProductDiscountInKindCode: String;
    DesignOfficeCode: String;
    AuthorisationGroupCode: String;
    EnvironmentRelevanceIndicator: Boolean;
    BasicProductCode: String;
    ProductSalesProcessUsabilityProfileCode: String;
    DangerousGoodsIndicatorProfileCode: String;
    BatchManagementRequiredIndicator: Boolean;
    ComputerAidedDesignMaintainedIndicator: Boolean;
    BasicViewMaintainedIndicator: Boolean;
    ConfigurableProductDeterminedIndicator: Boolean;
    ProductSalesProcessUsabilityProfileValidityDate: String;
    ProductionText: String;
    ProductSizeText: String;
    ProductionMemoPageFormatName: String;
    PreviousName: String;
    IndustryStandardDescription: String;
    ValidityStartDate: String;
    ProductHandlingIndicatorCode: String;
    AdjustmentProfileCode: String;
    HandlingUnitTypeCode: String;
    ManufacturerPartProfileCode: String;
    SmartFormName: String;
    ItemCategoryGroupCode: String;
    WarehouseStorageConditionCode: String;
    WarehouseProductGroupCode: String;
    StandardHandlingUnitTypeCode: String;
    ProductHighlyViscousIndicator: Boolean;
    TransportInBulkIndicator: Boolean;
    ProductRelevantForHazardousSubstancesIndicator: Boolean;
    VariableTareWeightIndicator: Boolean;
    OwnInventoryManagedProductInternalID: String;
    PackingReferenceProductInternalID: String;
    ApprovedBatchRecordRequiredIndicator: Boolean;
    ProductEffectivityParameterValuesAssignmentIndicator: Boolean;
    ProductDocumentPageNumber: String;
    ProductDocumentType: String;
    GlobalTradeItemNumberVariant: String;
    ProductDocumentChangeNumber: String;
    ProductDocumentVersion: String;
    OvercapacityTolerance: Double;
    MaximumCapacity: Double;
    ProductDocumentPageCount: Integer;
    SerialIdentifierAssignmentProfileCode: String;
    ProductOriginCountryCode: String;
    CompetitorID: String;
    ProductDocumentPageFormat: String;
    ProductDocumentNumber: String;
    PilferableIndicator: Boolean;
    PackagingMaterialGroupCode: String;
    QualityInspectionGroupCode: String;
    CatalogProfileCode: String;
    QuarantinePeriod: String;
    MaximumPackagingHeight: String;
    MaximumPackagingWidth: String;
    MaximumPackagingLength: String;
    MaximumPackagingUnitCode: String;
    NetContent: String;
    ComparisonPriceQuantity: String;
    GrossContent: String;
    ProductHasEmptiesBOM: Boolean;
    HasTextilePartsWthAnimalOrigin: Boolean;
    BrandID: String;
    RetailArticleGeneral: Composition of one RetailArticleGeneral on RetailArticleGeneral.parent = $self;
	Description: Composition of one Description on Description.parent = $self;
    QuantityConversion: Composition of many QuantityConversion on QuantityConversion.parent = $self;
    QuantityCharacteristic: Composition of many QuantityCharacteristic on QuantityCharacteristic.parent = $self;
	TextCollection: Composition of one TextCollection on TextCollection.parent = $self;
	StorageSpecification: Composition of one StorageSpecification on StorageSpecification.parent = $self;
    DistributionChainIndependentSalesSpecification: Composition of one DistributionChainIndependentSalesSpecification on DistributionChainIndependentSalesSpecification.parent = $self;
    PlantIndependentProcurementSpecification: Composition of one PlantIndependentProcurementSpecification on PlantIndependentProcurementSpecification.parent = $self;
    ProductSCMAdvancedPlanning: Composition of one ProductSCMAdvancedPlanning on ProductSCMAdvancedPlanning.parent = $self;
	SalesSpecification: Composition of one SalesSpecification on SalesSpecification.parent = $self;
    SalesSpecificTaxClassification: Composition of one SalesSpecificTaxClassification on SalesSpecificTaxClassification.parent = $self;
    SubscriptionProduct: Composition of one SubscriptionProduct on SubscriptionProduct.parent = $self;
    eSPPProduct: Composition of one eSPPProduct on eSPPProduct.parent = $self;
	Plant:Composition of many Plant on Plant.parent = $self;
	ValuationArea:Composition of many ValuationArea on ValuationArea.parent = $self;
	Warehouse:Composition of many Warehouse on Warehouse.parent = $self;
}

entity Description: cuid{
    Description: String;
    parent: Association to FASTCoreProduct;
}

entity TextCollection: cuid{
    TextExistsIndicator:  Boolean;
    parent: Association to FASTCoreProduct;
}

entity StorageSpecification: cuid{
    ProductStorageRequirementsCode: String;  
    ProductStorageTemperatureRangeCode: String;  
    HazardousMaterialID: String; 
    ProductLabelTypeCode: String; 
    ProductLabelFormCode: String;  
    MinimumRemainingShelfLifeCode: Integer;
    NumberOfGoodsReceiptIssueSlipsToPrintValue: String; 
    ExpirationDateCode: String;
    ShelfLifeExpirationDatePeriod: String;  
    TotalShelfLifeStoragePercent: Integer;
    StorageBinInstructionCode: String;  
    ShelfLifeExpirationDateRoundingRuleCode: String; 
    TotalShelfLife: Integer;
    parent: Association to FASTCoreProduct;
}

entity DistributionChainIndependentSalesSpecification: cuid{
    TransportProductGroupCode: String;
    ProductSalesProcessUsabilityProfileCode: String;
    ProductSalesProcessUsabilityProfileValidityDate: Date;
    PricingReferenceProductID: String;  // Nullable field
    TaxClassificationID: String;  // Nullable field
    AllowedPackagingVolumeQuantity: String;  // Nullable field
    VolumeMaximumLevel: Integer;
    StackingFactor: Integer;
    ClosedPackagingProductIndicator: Boolean;
    ExcessWeightTolerance: Double;
    ExcessVolumeTolerance: Double;
    AllowedPackagingWeightQuantity: String;  // Nullable field
    ProductFreightGroupCode: String;  // Nullable field
    PackagingProductTypeCode: String;  // Nullable field
    VariantsPricingProfileCode: String;  // Nullable field
    IsVariantPriceAllowed: Boolean;
    parent: Association to FASTCoreProduct;
}

entity PlantIndependentProcurementSpecification: cuid{
    ManufacturerID: String;
    ProductManufacturerID: String;
    PurchasingAcknowledgmentProfileCode: String;
    OrderMeasureUnitCode: String;  // Nullable field
    VariablePurchaseOrderUnitOfMeasureActivationStatusCode: String;  // Nullable field
    parent: Association to FASTCoreProduct;
}

entity ProductSCMAdvancedPlanning: cuid{
    RequiredMaximumShelfLife:Integer;
    MaturationTime:String;
    parent: Association to FASTCoreProduct;
}

entity SalesSpecification: cuid{
    AccountDeterminationProductGroupCode: String; // Nullable field
    MinimumOrderQuantity: Decimal;
    MinimumOrderQuantityUnitCode: String; // for unitCode attribute
    SalesOrganizationID: String;
    ReceiverSalesOrganizationID: String; // Nullable field
    DistributionChannelCode: String;
    SupplyingPlantID: String; // Nullable field
    ReceiverSupplyingPlantID: String; // Nullable field
    StandardProductCategoryInternalID: String;
    CustomerTransactionDocumentItemProcessingTypeDeterminationProductGroupCode: String;
    SalesMeasureUnitCode: String; // Nullable field
    PriceSpecificationProductGroupCode: String; // Nullable field
    FirstSalesSpecificationProductGroupCode: String; // Nullable field
    SecondSalesSpecificationProductGroupCode: String; // Nullable field
    DeliveryNoteProcessingMinimumDeliveryQuantity: Decimal;
    DeliveryNoteProcessingMinimumDeliveryQuantityUnitCode: String; // for unitCode attribute
    ThirdSalesSpecificationProductGroupCode: String; // Nullable field
    FourthSalesSpecificationProductGroupCode: String; // Nullable field
    FifthSalesSpecificationProductGroupCode: String; // Nullable field
    ProductSalesProcessUsabilityProfileCode: String; // Nullable field
    DeletedIndicator: Boolean;
    DeliveryQuantity: Decimal;
    DeliveryQuantityUnitCode: String; // for unitCode attribute
    DeliveryQuantityMeasureUnitCode: String; // Nullable field
    MinimumMakeToOrderOrderQuantity: Decimal;
    MinimumMakeToOrderOrderQuantityUnitCode: String; // for unitCode attribute
    ProductSalesProcessUsabilityProfileValidityDate: Date; // Nullable field
    ProductExternalAssortmentPriorityTypeCode: String; // Nullable field
    VolumeRebateGroupCode: String; // Nullable field
    StoreOrderProcessingMaximumDeliveryQuantity: Decimal;
    StoreOrderProcessingMaximumDeliveryQuantityUnitCode: String; // for unitCode attribute
    CompetitionCharacterizationTypeCode: String; // Nullable field
    ProductUnitGroupCode: String; // Nullable field
    PriceFixingControlCategoryCode: String; // Nullable field
    PricingReferenceProductID: String; // Nullable field
    ProductHasAttributeID01Indicator: Boolean;
    ProductHasAttributeID02Indicator: Boolean;
    ProductHasAttributeID03Indicator: Boolean;
    ProductHasAttributeID04Indicator: Boolean;
    ProductHasAttributeID05Indicator: Boolean;
    ProductHasAttributeID06Indicator: Boolean;
    ProductHasAttributeID07Indicator: Boolean;
    ProductHasAttributeID08Indicator: Boolean;
    ProductHasAttributeID09Indicator: Boolean;
    ProductHasAttributeID10Indicator: Boolean;
    ProductCommissionGroupCode: String; // Nullable field
    RoundingProfileCode: String; // Nullable field
    CashDiscountIndicator: Boolean;
    VariableSalesUnitNotAllowedIndicator: Boolean;
    ProductStatisticsGroupCode: String; // Nullable field
    StoreSaleStartDate: Date; // Nullable field
    StoreSaleEndDate: Date; // Nullable field
    DistributionCenterSaleStartDate: Date; // Nullable field
    DistributionCenterSaleEndDate: Date; // Nullable field
    AssortmentGrade: String; // Nullable field
    StoreListingProcedure: String; // Nullable field
    DistributionCenterListingProcedure: String; // Nullable field
    StoreListingStartDate: Date; // Nullable field
    StoreListingEndDate: Date; // Nullable field
    DistributionCenterListingStartDate: Date; // Nullable field
    DistributionCenterListingEndDate: Date; // Nullable field
    ProductEntitlementRelevantIndicator: Boolean;
    SubscriptionProductSalesData: Composition of one SubscriptionProductSalesData on SubscriptionProductSalesData.parentSalesSpecification = $self;
    parent: Association to FASTCoreProduct;
}

entity SubscriptionProductSalesData: cuid{
	DefaultContractTerm: Integer; // Nullable field
    AltContractTerm1: Integer; // Nullable field
    AltContractTerm2: Integer; // Nullable field
    ContractTermUnit: String; // Nullable field
    DefaultExtensionPeriod: Integer; // Nullable field
    AltExtensionPeriod1: Integer; // Nullable field
    AltExtensionPeriod2: Integer; // Nullable field
    ExtensionPeriodUnit: String; // Nullable field
    parentSalesSpecification: Association to SalesSpecification;
}

entity SalesSpecificTaxClassification: cuid{
    CountryCode: String;
    TaxTypeCode: String;
    TaxRateTypeCode: String;
    parent: Association to FASTCoreProduct;
}

entity SubscriptionProduct: cuid{
    BillingCycle                        : String; // nullable
    BillingCycleDeterminationRuleId     : String; // nullable
    ContractAutoRenewalIndicator        : String; // nullable
    parent: Association to FASTCoreProduct;
}

entity eSPPProduct: cuid{
    ProductIsForKitToOrder                     : Boolean;
    ProductIsForProcureToOrder                 : Boolean;
    ProdIsForPushDplntFromSupplier             : Boolean;
    InventoryBalancingIsNotAllowed             : Boolean;
    ProdIsForGlobalStockOnEntryLoc             : Boolean;
    ProdIsExclFromExpressShipment              : Boolean;
    SrvcPartsProductIsNew                      : Boolean;
    SrvcPartsProdProdnStartDate                : DateTime; // nullable
    SrvcPartsProdProdnEndDate                  : DateTime; // nullable
    SrvcPartsInvtryPlngMode                    : String;   // nullable
    parent: Association to FASTCoreProduct;
}

entity RetailArticleGeneral: cuid{
	ServiceAgreementTypeCode: String;
    ProductRequirementsPlanningABCClassificationCode: String;
    GoodsIssueUnitCode: String;
    ProductOriginCountryCode: String;
    ProductOriginRegionCode: String;
    AssortmentGradeTypeCode: String;
    StoreListingProcedureTypeCode: String;
    DistributionCenterListingProcedureTypeCode: String;
    StoreListingStartDate: String;
    StoreListingEndDate: String;
    DistributionCenterListingStartDate: String;
    DistributionCenterListingEndDate: String;
    StoreSaleStartDate: String;
    StoreSaleEndDate: String;
    DistributionCenterSaleStartDate: String;
    DistributionCenterSaleEndDate: String;
    AccountDeterminationProductValuationDataGroupCode: String;
    CustomsCommodityClassificationCode: String;
    ValuationMarginValue: String;
    CustomsCommodityClassificationCodeUnitCode: String;
    SalesUnitCode: String;
    PurchasingGroupID: String;
    LoadingGroupCode: String;
    ProductExternalAssortmentPriorityTypeCode: String;
    parent: Association to FASTCoreProduct;
}

entity QuantityConversion: cuid {
	Quantity: Double;
	CorrespondingQuantity: Double;
	parent: Association to FASTCoreProduct;
}

entity QuantityCharacteristic: cuid{
	Quantity: Double;
	CharacteristicQuantity: Double;
	CharacteristicQuantityTypeCode: String;
	parent: Association to FASTCoreProduct;
}

entity Warehouse: cuid {
    CapacityConsumptionUnitCode                             : String; // nullable
    ProductBulkStorageMethod                                : String; // nullable
    WarehouseManagementSpecialMovementTypeCode               : String; // nullable
    WarehouseManagementMessageToInventoryManagementRequiredIndicator: Boolean;
    AdditionToExistingStockAllowedIndicator                 : Boolean;
    ProductIsRelevantForTwoStepPicking                      : String; // nullable
    FirstProductStorageUnitTypeCode                         : String; // nullable
    SecondProductStorageUnitTypeCode                        : String; // nullable
    ThirdProductStorageUnitTypeCode                         : String; // nullable
    ProductStorageSectionMethod                             : String; // nullable
    WarehouseNumber                                         : String;
    ProductWarehouseFirstLoadingEquipmentQuantityUnitCode    : String; // nullable
    ProductWarehouseSecondLoadingEquipmentQuantityUnitCode   : String; // nullable
    ProductWarehouseThirdLoadingEquipmentQuantityUnitCode    : String; // nullable
    ProductWarehouseFirstLoadingEquipmentQuantity            : String; // nullable
    ProductWarehouseSecondLoadingEquipmentQuantity           : String; // nullable
    ProductWarehouseThirdLoadingEquipmentQuantity            : String; // nullable
    ProductWarehouseStockRemovalStorageTypeCode              : String; // nullable
    ProductWarehouseStockPlacementStorageTypeCode            : String; // nullable
    DeletedIndicator                                        : Boolean;
    ProductWarehouseManagementUnitCode                      : String; // nullable
    CapacityUsage                                           : String; // nullable
    ProductWarehousePickingStorageTypeCode                  : String; // nullable
    ProductWarehouseMaterialMasterDefaultUnitTypeCode       : String; // nullable
	parent: Association to FASTCoreProduct;
}

entity ValuationArea: cuid {
    ValuationAreaID                          : String;
    InventoryValuationTypeCode               : String; // nullable
    DeletedIndicator                         : Boolean;
    AccountDeterminationProductValuationDataGroupCode: String;
    ProductPriceDeterminationApproachCode    : String; // nullable
    InventoryValuationCategoryCode           : String; // nullable
    ProductUsageTypeCode                     : String; // nullable
    ProductOriginTypeCode                    : String; // nullable
    ProductProducedInhouseIndicator          : Boolean;
    SalesOrderStockAccountDeterminationProductValuationDataGroupCode: String; // nullable
    ProjectStockAccountDeterminationProductValuationDataGroupCode: String; // nullable
    FirstFuturePlannedPriceAmountValue       : String; // nullable
    SecondFuturePlannedPriceAmountValue      : String; // nullable
    ThirdFuturePlannedPriceAmountValue       : String; // nullable
    FirstFuturePlannedPriceValidityDate      : String; // nullable
    SecondFuturePlannedPriceValidityDate     : String; // nullable
    ThirdFuturePlannedPriceValidityDate      : String; // nullable
    ValuationMargin                         : String; // nullable
    PriceLastChangeDate                     : String; // nullable
    PreviousInventoryPriceInCompanyCodeCurrency: String; // nullable
    ValuationAccount: Composition of one ValuationAccount on ValuationAccount.parentValuationArea = $self;
    LedgerAccount: Composition of one LedgerAccount on LedgerAccount.parentValuationArea = $self;
    FuturePrice:Composition of one FuturePrice on FuturePrice.parentValuationArea = $self;
    ValuationCosting: Composition of one ValuationCosting on ValuationCosting.parentValuationArea = $self;
	parent: Association to FASTCoreProduct;
}

entity ValuationAccount: cuid{
    CommercialLawLevelOneEvaluatedAmountValue  : String; // nullable
	CommercialLawLevelTwoEvaluatedAmountValue  : String; // nullable
	CommercialLawLevelThreeEvaluatedAmountValue: String; // nullable
	DevaluationMeasureNumberValue             : String; // nullable
	LIFOValuationRelevanceIndicator           : Boolean;
	LIFOValuationPoolTypeCode                 : String; // nullable
	TaxLawLevelOneEvaluatedAmountValue        : String; // nullable
	TaxLawLevelTwoEvaluatedAmountValue        : String; // nullable
	TaxLawLevelThreeEvaluatedAmountValue      : String; // nullable
	ValuationPriceUnitNumberValue             : String;
    parentValuationArea : Association to ValuationArea;
}

entity LedgerAccount: cuid{
    CurrencyRoleCode                        : String;
	CurrencyCode                            : String;
	InventoryValuationProcedureCode         : String;
	PriceUnitNumberValue                    : String;
	PriceAmountValue                        : String; // nullable
    parentValuationArea : Association to ValuationArea;
}

entity FuturePrice: cuid{
    CurrencyRoleCode                        : String;
	FuturePriceAmountValue                  : String; // nullable
	FuturePriceValidityStartDate            : String; // nullable
    parentValuationArea : Association to ValuationArea;
}

entity ValuationCosting: cuid{
    MaterialCostedWithQuantityStructureIndicator: Boolean;
	MaterialRelatedOriginIndicator          : Boolean;
	CostOriginGroupCode                     : String; // nullable
	CostingOverheadGroupCode                : String; // nullable
	PlannedPrice                            : String; // nullable
    parentValuationArea : Association to ValuationArea;
}

entity Plant: cuid {
    PlantID                     : String; 
    ProfileCode                 : String; // nullable
    ProfileValidityStartDate    : String; // nullable
    DeletedIndicator            : String; 
    BatchManagementRequiredIndicator : String; 
    SerialIdentifierAssignmentProfileCode : String; // nullable
    ProfitCenterID              : String; 
    GoodsIssueUnitCode          : String; // nullable
    NegativeStockAllowedIndicator : String; 
    StockDeterminationGroupCode : String; // nullable
    ProductExciseTaxRelevanceIndicator : String; 
    ConfigurableProductID       : String; // nullable
    ProductCFOPCategoryCode     : String; // nullable
    ProductCriticalPartIndicator : String; 
    ProductLogisticsHandlingGroupCode : String; // nullable
    ProductFreightGroupCode     : String; // nullable
    ProductDistributionProfileCode : String; // nullable
    OriginalBatchManagementRequiredIndicator : String; 
    OriginalBatchReferenceProductID : String; // nullable
	Costing: Composition of one Costing on Costing.parentPlant = $self;
	SupplyPlanning: Composition of one SupplyPlanning on SupplyPlanning.parentPlant = $self;
	Sales: Composition of one Sales on Sales.parentPlant = $self;
	QualityManagement: Composition of one QualityManagement on QualityManagement.parentPlant = $self;
    PlantText: String;
	Forecasting: Composition of one Forecasting on Forecasting.parentPlant = $self;
	InternationalTrade: Composition of one InternationalTrade on InternationalTrade.parentPlant = $self;
	Storage:Composition of one Storage on Storage.parentPlant = $self;
	StorageLocation:Composition of many StorageLocation on StorageLocation.parentPlant = $self;
	Purchasing:Composition of one Purchasing on Purchasing.parentPlant = $self;
	WorkScheduling:Composition of one WorkScheduling on WorkScheduling.parentPlant = $self;
	PlantSCMAdvancedPlanning:Composition of one PlantSCMAdvancedPlanning on PlantSCMAdvancedPlanning.parentPlant = $self;
	Planning:Composition of one Planning on Planning.parentPlant = $self;
	ForecastParameters:Composition of one ForecastParameters on ForecastParameters.parentPlant = $self;
	ProductionResourceTool:Composition of one ProductionResourceTool on ProductionResourceTool.parentPlant = $self;
	PlantSCMDemandPenalty:Composition of many PlantSCMDemandPenalty on PlantSCMDemandPenalty.parentPlant = $self;
    ProductMinControlTemperatureQuantity: String; // nullable
	ProductMaxControlTemperatureQuantity: String; // nullable
	ProductControlTemperatureUnitCode: String; // nullable
	PlanteSPPProduct:Composition of one PlanteSPPProduct on PlanteSPPProduct.parentPlant = $self;
	eSPPLocProd:Composition of one eSPPLocProd on eSPPLocProd.parentPlant = $self;
	parent: Association to FASTCoreProduct;
}

entity Costing: cuid{
    CoProductIndicator                          : String; // CoProductIndicator
    ProductBillOfMaterialUsageCategoryCode       : String; // nullable
    AlternativeBillOfMaterial                   : String; // nullable
    VarianceKeyCode                             : String; // nullable
    CostingProductionVersionCode                : String; // nullable
    FixedPriceCoProductIndicator                : String; // FixedPriceCoProductIndicator
    CostingLotSizeQuantity                      : String; // CostingLotSizeQuantity (unitCode="KGM")
    ProductIsNotCostingRelevantIndicator        : String; // ProductIsNotCostingRelevantIndicator
    TaskListGroupCode                           : String; // nullable
    TaskListTypeCode                            : String; // nullable
    CostingSpecialProcurementTypeCode           : String; // nullable
    TaskListGroupCounter                       : String; // nullable
	parentPlant: Association to Plant;
}

entity SupplyPlanning: cuid {
    ProductRequirementsPlanningTypeCode                : String; // ProductRequirementsPlanningTypeCode
    ProductRequirementsPlanningResponsibleCode         : String; // ProductRequirementsPlanningResponsibleCode
    AvailabilityCheckGroupCode                        : String; // nullable
    LotSizeProcedureCode                              : String; // LotSizeProcedureCode
    FixedLotSizeQuantity                              : String; // FixedLotSizeQuantity (unitCode="KGM")
    MaximumLotSizeQuantity                            : String; // MaximumLotSizeQuantity (unitCode="KGM")
    MinimumLotSizeQuantity                            : String; // MinimumLotSizeQuantity (unitCode="KGM")
    LotSizeRoundingQuantity                           : String; // LotSizeRoundingQuantity (unitCode="KGM")
    SafetyStockQuantity                               : String; // SafetyStockQuantity (unitCode="KGM")
    SafetyDaysOfSupplyDuration                        : String; // SafetyDaysOfSupplyDuration
    MinimumSafetyStockQuantity                        : String; // MinimumSafetyStockQuantity (unitCode="KGM")
    MasterPlanAutomaticChangeRestrictedDuration       : String; // MasterPlanAutomaticChangeRestrictedDuration
    ProductRequirementsPlanningABCClassificationCode   : String; // nullable
    MaximumStockQuantity                              : String; // MaximumStockQuantity (unitCode="KGM")
    ReorderThresholdQuantity                          : String; // ReorderThresholdQuantity (unitCode="KGM")
    PlannedDeliveryDuration                           : String; // PlannedDeliveryDuration
    ProductRequirementsPlanningStrategyGroupCode      : String; // ProductRequirementsPlanningStrategyGroupCode
    TotalReplinishmentLeadTimeDuration                : String; // TotalReplinishmentLeadTimeDuration
    ProcurementTypeCode                               : String; // ProcurementTypeCode
    ProcurementSubTypeCode                            : String; // nullable
    AssemblyProductScrapPercent                        : String; // nullable
    ProcurementInventoryManagedLocationInternalID     : String; // nullable
    GoodsReceiptDuration                              : String; // GoodsReceiptDuration
    ProductRequirementsPlanningGroupCode              : String; // nullable
    ProductRequirementsPlanningStorageCostDeterminationProfileCode : String; // nullable
    PlanningCalendarCode                              : String; // nullable
    DynamicSafetyStockCalculationProfileCode          : String; // nullable
    SafetyDaysOfSupplyRelevanceCode                   : String; // nullable
    SafetyDaysOfSupplyDurationProfileCode             : String; // nullable
    MRPDependentRequirementCode                       : String; // nullable
    LotSizeOrderAmountValue                           : String; // nullable (currencyCode="   ")
    LotSizeTaktTimeOffsetDuration                     : String; // LotSizeTaktTimeOffsetDuration
    ServiceLevelPercent                               : String; // nullable
    ProductionDuration                                : String; // ProductionDuration
    ProposedProductSupplyAreaCode                     : String; // nullable
    ProductRequirementsConsumptionModeTypeCode        : String; // ProductRequirementsConsumptionModeTypeCode
    ForecastRequirementsSplitCategoryCode             : String; // nullable
    ConsignmentControlCode                            : String; // nullable
    MRPProfileCode                                    : String; // nullable
    SchedulingMarginCode                              : String; // nullable
    ProductRequirementsConsolidationCode              : String; // nullable
    PlanAndOrderDayDeterminationCode                  : String; // nullable
    MRPAvailabilityTypeCode                           : String; // nullable
    RoundingProfileCode                               : String; // nullable
    RepetitiveManufacturingAllowedIndicator           : String; // RepetitiveManufacturingAllowedIndicator
    CrossProjectProductIndicatorCode                  : String; // nullable
    BulkProductComponentIndicator                     : String; // BulkProductComponentIndicator
    DependentRequirementsTypeCode                     : String; // nullable
    RepetitiveManufacturingProfileCode                : String; // nullable
    FollowUpProductInternalID                         : String; // nullable
    EffectiveOutDate                                  : String; // nullable
    GoodsIssueProcessingDuration                      : String; // GoodsIssueProcessingDuration
    ComponentScrapPercent                             : String; // nullable
    BackwardConsumptionPeriodDuration                : String; // BackwardConsumptionPeriodDuration
    ForwardConsumptionPeriodDuration                 : String; // ForwardConsumptionPeriodDuration
    ProductDiscontinuationTypeCode                    : String; // nullable
    PlannedOrderActionControlCode                     : String; // nullable
    ProductUnitGroupCode                              : String; // nullable
    JITProdnConfProfileCode                          : String; // nullable
	parentPlant: Association to Plant;
}

entity Sales: cuid {
    LoadingGroupCode                          : String; // LoadingGroupCode
    ReplacementPartTypeCode                   : String; // nullable
    WorkCentersShippingSetupDuration          : String; // nullable
    ProductShippingProcessingDuration         : String; // nullable
    CapacityPlanningQuantity                  : String; // CapacityPlanningQuantity (unitCode="KGM")
	parentPlant: Association to Plant;
}

entity QualityManagement: cuid {
    InspectionStockIndicator                        : String; // InspectionStockIndicator
    QualityManagementControlKeyCode                 : String; // nullable
    ProductQualityAuthorizationGroupCode             : String; // nullable
    ProductQualityCertificateTypeCode               : String; // nullable
    InspectionLotDocumentationRequiredIndicator     : String; // InspectionLotDocumentationRequiredIndicator
    RecurringInspectionIntervalDuration             : String; // RecurringInspectionIntervalDuration
    SupplierQualityManagementSystemCode             : String; // nullable
	parentPlant: Association to Plant;
}

entity Forecasting: cuid {
    ConsumptionReferenceUsageEndDate                : String; // nullable
    ConsumptionReferenceProductQuantityMultiplier   : String; // nullable
    ConsumptionReferenceProductID                   : String; // nullable
    ConsumptionReferencePlantID                     : String; // nullable
    FiscalYearVariantCode                           : String; // nullable
    ProductConsumptionPeriodTypeCode                : String; // ProductConsumptionPeriodTypeCode
    ForecastModelResetIndicator                     : String; // ForecastModelResetIndicator
    CorrectionFactorRequiredIndicator              : String; // CorrectionFactorRequiredIndicator
	parentPlant: Association to Plant;
}

entity InternationalTrade: cuid {
    ProductOriginCountryCode                        : String; // nullable
    ProductOriginRegionCode                         : String; // nullable
    ConsumptionTaxControlCode                       : String; // nullable
    ExportAndImportProductGroupCode                 : String; // nullable
    ProductInternationalTradeClassificationNumber   : String; // nullable
    ProductCASNumber                                : String; // nullable
	parentPlant: Association to Plant;
}

entity Storage: cuid {
    PhysicalInventoryCycleCountingProfileCode      : String; // nullable
    WarehouseManagementPutawayAndStockRemovalStrategyCode : String; // nullable
    ProvisioningServiceLevelCode                   : String; // nullable
    ProductMaximumStoragePeriodUnitCode            : String; // nullable
    MaximumStoragePeriodDuration                   : String; // MaximumStoragePeriodDuration
    CycleCountingCategoryIsFixedIndicator          : String; // CycleCountingCategoryIsFixedIndicator
	parentPlant: Association to Plant;
}

entity StorageLocation: cuid {
    StorageLocationID                       : String; // StorageLocationID
    StorageBinID                            : String; // nullable
    DeletedIndicator                        : String; // DeletedIndicator
    LeanWarehouseManagementPickingAreaCode  : String; // nullable
	parentPlant: Association to Plant;
}

entity Purchasing: cuid {
    AutomaticPurchaseOrderAllowedIndicator        : String; // AutomaticPurchaseOrderAllowedIndicator
    SourceListRequirementIndicator                : String; // SourceListRequirementIndicator
    PurchasingGroupID                             : String; // PurchasingGroupID
    SourceOfSupplyCategoryCode                    : String; // nullable
    PurchasingAcrossPurchasingGroupIndicator      : String; // PurchasingAcrossPurchasingGroupIndicator
    JITDeliverySchedulesRelevantIndicator         : String; // JITDeliverySchedulesRelevantIndicator
    TaxIndicator                                  : String; // nullable
	parentPlant: Association to Plant;
}

entity WorkScheduling: cuid {
    ProductBaseQuantity                               : String; // nullable
    OverDeliveryToleranceLimit                        : String; // nullable
    UnderDeliveryToleranceLimit                       : String; // nullable
    UnlimitedOverDeliveryIsAllowedIndicator           : String; // UnlimitedOverDeliveryIsAllowedIndicator
    ProductionInventoryManagedLocationInternalID      : String; // nullable
    ProductionSupervisorCode                          : String; // nullable
    ProductionOrderBatchEntryDeterminationCode        : String; // nullable
    OrderChangeManagementProfileCode                  : String; // nullable
    BackflushIndicatorCode                            : String; // nullable
    ProductionSchedulingProfileCode                   : String; // nullable
    ProductWithdrawnFromProductionBinIndicator        : String; // ProductWithdrawnFromProductionBinIndicator
    ProductProductionQuantityUnitCode                 : String; // nullable
    ProductProcessingDuration                         : String; // nullable
    SetupAndTeardownTimeDuration                     : String; // SetupAndTeardownTimeDuration
    TransitionMatrixProductsGroupID                   : String; // nullable
    TransitionDuration                                : String; // nullable
	parentPlant: Association to Plant;
}

entity PlantSCMAdvancedPlanning: cuid {
    ConsumptionOfStorageCapacity                : String; // ConsumptionOfStorageCapacity
    GoodsIssueHandlingCost                      : String; // GoodsIssueHandlingCost
    GoodsReceiptHandlingCost                    : String; // GoodsReceiptHandlingCost
    ProductProcurementCostsVal                  : String; // ProductProcurementCostsVal
    ProductPriority                             : String; // nullable
    PeggingStrategy                             : String; // nullable
    LotSizeUnit                                 : String; // nullable
    BOMTypeExplosionUsed                        : String; // nullable
    PlngCalendarPerdcLotSizing                  : String; // nullable
    TargetDaysSupplyInWorkDays                  : String; // TargetDaysSupplyInWorkDays
    RequirementStrategy                         : String; // nullable
    SftyStkVioltnPnltyCostValue                : String; // SftyStkVioltnPnltyCostValue
    RqdMinShelfLifeLocDepdnt                   : String; // RqdMinShelfLifeLocDepdnt
    RqdMaxShelfLifeLocDepdnt                   : String; // RqdMaxShelfLifeLocDepdnt
    IsLocDependentShelfLifeUsed                 : String; // IsLocDependentShelfLifeUsed
    ShelfLifeLocDependent                       : String; // ShelfLifeLocDependent
    LocProdStorageCostValue                     : String; // LocProdStorageCostValue
    PPPlanningProcedure                         : String; // nullable
    ProductPlanningGroup                        : String; // nullable
    ResourceNetworkName                         : String; // nullable
    ReorderDaysSupplyInWorkDays                 : String; // ReorderDaysSupplyInWorkDays
    ReplenishmentLeadTimeDays                   : String; // ReplenishmentLeadTimeDays
    ConversionRule                              : String; // nullable
    IsAlertsInPeggingAvoided                    : String; // IsAlertsInPeggingAvoided
    AlertThldForDlydRcptDurn                   : String; // AlertThldForDlydRcptDurn
    AlertThldForEarlyRcptDurn                  : String; // AlertThldForEarlyRcptDurn
    ProductPlanningPackage                      : String; // nullable
    MinPassingAmtContinuousPegging              : String; // nullable
    MaturationDurnLocDependent                  : String; // MaturationDurnLocDependent
    InteractiveSourcingProfile                  : String; // nullable
    ProdnPlngHeuristic                          : String; // nullable
    LocProdGoodsReceiptProcHours                : String; // LocProdGoodsReceiptProcHours
    LocProdGoodsIssueProcHours                  : String; // LocProdGoodsIssueProcHours
    ProductAlertRelevanceCode                   : String; // nullable
    IsTotalQtyReceiptElement                    : String; // IsTotalQtyReceiptElement
    IsTotalQtyStockElement                      : String; // IsTotalQtyStockElement
    IsFixedPeggingForProdRetained               : String; // nullable
    GIHandlingCapacity                          : String; // nullable
    GRHandlingCapacity                          : String; // nullable
    MaxDaysOfSupplyIsActive                     : String; // MaxDaysOfSupplyIsActive
    MaxDaysOfSupplyPenaltyAmount                : String; // MaxDaysOfSupplyPenaltyAmount
    AdvncdPlngTgtStkLvlMeth                     : String; // nullable
    SftyStkMethIsAutomlyDtmnd                  : String; // SftyStkMethIsAutomlyDtmnd
    AdvncdPlngSftyStkMeth                      : String; // nullable
    PeriodFactorIsUsed                          : String; // PeriodFactorIsUsed
    AdvncdPlngPeriodFactorValue                 : String; // nullable
    TimeDepdntStkLvlPerdFactorVal              : String; // nullable
	parentPlant: Association to Plant;
}

entity Planning: cuid {
    PlanningMaterialID                              : String; // nullable
    PlanningPlantID                                 : String; // nullable
    ProductPlantPlanningMaterialConversionFactor    : String; // nullable
	parentPlant: Association to Plant;
}

entity ForecastParameters: cuid {
    ForecastBasicValueAlphaFactor                    : String; // nullable
    NumberOfForecastPeriod                          : String; // nullable
    ForecastTrendValueBetaFactor                    : String; // nullable
    MeanAbsoluteDeviationDeltaFactor                : String; // nullable
    ForecastNumberOfFixedPeriod                     : String; // nullable
    ForecastSeasonalIndexGammaFactor                : String; // nullable
    ForecastWeightingGroupCode                      : String; // nullable
    ForecastModelInitializationIndicator            : String; // nullable
    ForecastParameterIsOptimizedIndicator           : Boolean;
    ForecastModelSelectionProcedureCode             : String; // nullable
    ForecastModelSelectionMethod                    : String; // nullable
    OptimizationLevel                               : String; // nullable
    HistoricalPeriodCountForForecast                : String; // nullable
    PeriodsCountForForecastInitialization          : String; // nullable
    ForecastPeriodCountPerSeasonCycle               : String; // nullable
    LastForecastDate                                : String; // nullable
    ForecastModel                                   : String; // nullable
    ForecastValueTrackingLimit                      : String; // nullable
	parentPlant: Association to Plant;
}

entity ProductionResourceTool: cuid {
    ControlProfileCode                                    : String; // nullable
    ControlProfileReferencedIndicator                    : Boolean;
    Group1                                                : String; // nullable
    Group2                                                : String; // nullable
    ProductionResourceUsageCode                           : String; // nullable
    StandardTextCode                                      : String; // nullable
    StandardTextCodeReferencedIndicator                   : Boolean;
    StartDateOffsetReferenceCode                          : String; // nullable
    StartDateOffsetReferenceCodeReferencedIndicator       : Boolean;
    StartDateOffset                                       : String; // nullable
    StartDateOffsetReferencedIndicator                    : Boolean;
    EndDateOffsetReferenceCode                            : String; // nullable
    EndDateOffsetReferenceCodeReferencedIndicator         : Boolean;
    EndDateOffset                                         : String; // nullable
    EndDateOffsetReferencedIndicator                      : Boolean;
    TotalQuantityCalculationFormula                       : String; // nullable
    TotalQuantityCalculationFormulaReferencedIndicator    : Boolean;
    UsageQuantityCalculationFormula                       : String; // nullable
    UsageQuantityCalculationFormulaReferencedIndicator    : Boolean;
	parentPlant: Association to Plant;
}

entity PlantSCMDemandPenalty: cuid {
    DemandType                    : String;
    DelayPenaltyAmount                : Double;
    MaximumDelayInDays                : Integer;
    NonDeliveryPenaltyAmount          : Double;
	parentPlant: Association to Plant;
}

entity PlanteSPPProduct: cuid {
    ESPPIsUsed                              : String; // nullable
    ProductAlertRelevanceCode               : String; // nullable
    LocProdGoodsReceiptProcHours            : Integer;
    LocProdGoodsIssueProcHours              : Integer;
    ParLocSafetyStockQuantity              : Double; // nullable
    RepairSafetyStockQuantity              : Double;// nullable
    VCLSafetyStockQuantity                 : Double;// nullable
    VCLParLocSafetyStockQuantity           : Double;// nullable
    VCLRepairSafetyStockQuantity           : Double;// nullable
    VCLReorderPointQuantity                : Double;// nullable
    VCLMaximumStockQuantity                : Double;// nullable
    ProductProcurementCostsVal             : Double;
    GoodsReceiptHandlingCost               : Double;
    GoodsIssueHandlingCost                 : Double;
    CostFactorForStockHoldingVal           : Double;
    ThirdPartyOrderProcessing              : String; // nullable
    SrvcPartsThroughputTimeDurn            : Integer;
	parentPlant: Association to Plant;
}

entity eSPPLocProd: cuid {
    ReplenishmentStatusCode                 : String; // nullable
    SrvcPartsProductProcureToOrder          : String; // nullable
    ReplenishmentIndIsLocked                : Boolean;
    SrvcPartsLocationExclusionRsn           : String; // nullable
    SrvcPartsStkngStbltyDurnInHrs          : Double; // nullable
    SrvcPartsDstkngStbltyDurnInHrs         : Double; // nullable
    SrvcPartsCustInfoStkDcsnIsUsd           : Boolean;
    SrvcPartsOEMMngdInvtryIsRlvt            : Boolean;
    SrvcPartsVCLDstkngStbltyPerd            : Double; // nullable
    SrvcPartsVCLStkngStabilityPerd          : Double; // nullable
    SrvcPartsSftyStkEOQLockRsn              : String; // nullable
    SrvcPartsStstclCalcEOQSfty              : String; // nullable
    SrvcPartsNrOfDaysEOQPlngDurn            : String; // nullable
    SrvcPartsEconomicOrderQty               : String; // nullable
    SrvcPartsPlngLockEOQEndDate             : String; // nullable
    SrvcPartsPlngLockEOQStrtDate            : String; // nullable
    SrvcPartsSftyStkCalcMethod              : String; // nullable
    SrvcPartsVCLSftyStkEOQLockRsn           : String; // nullable
    SrvcPartsVCLStstclCalcEOQSfty           : String; // nullable
    SrvcPartsVrtlChildLocEOQPerd            : String; // nullable
    SrvcPartsEOQFixPeriod                   : String; // nullable
    SrvcPartsVrtlChildLocEOQQty             : String; // nullable
    SrvcPartsNrOfMaxDaysEOQ                : String; // nullable
    SrvcPartsNrOfMaxDaysEOQParent          : String; // nullable
    SrvcPartsNrOfMaxDaysReorderPt          : String; // nullable
    SrvcPartsNrOfMinDaysEOQPeriod          : String; // nullable
    SrvcPartsVCLPlngLockEOQEndDte          : String; // nullable
    SrvcPartsVCLPlngLockEOQStrtDte         : String; // nullable
    SrvcPartsNrOfOrdDepdntPortion          : String; // nullable
    SrvcPartsVCLSftyStkCalcMethod          : String; // nullable
    SrvcPartsFixOrdgCostPullAmtVal         : String; // nullable
    SrvcPartsFixOrdgCostPushAmtVal         : String; // nullable
    SrvcPartsMinPurOrderQty                : String; // nullable
    SrvcPartsSupplyChainAnalyst            : String; // nullable
    SrvcPartsDRPPlanner                    : String; // nullable
    SrvcPartsInventoryPlanner              : String; // nullable
    SrvcPartsForecastPlanner               : String; // nullable
    SrvcPartsPlanningBuyer                 : String; // nullable
    SrvcPartsSCMAnalystIsLocked            : Boolean;
    SrvcPartsDRPLockRsn                    : String; // nullable
    SrvcPartsDRPPlngMode                   : String; // nullable
    SrvcPartsPseasnIsExcluded              : Boolean;
    SrvcPartsVCLPseasnIsExcluded           : Boolean;
    SrvcPartsMinNetDemandQty               : String; // nullable
    SrvcPartsVCLMinNetDemandQty            : String; // nullable
    SrvcPartsManFreezeHrznDteTme           : String; // nullable
    SrvcPartsDRPMaxCostRndngAmtVal         : String; // nullable
    SrvcPartsDRPMinCostRndngAmtVal         : String; // nullable
    SrvcPartsDRPNrOfMonthsRndng            : String; // nullable
    SrvcPartsDRPPlanningRunDurn            : String; // nullable
    SrvcPartsDRPPlngLockEndDteTme          : String; // nullable
    SrvcPartsDRPPlngLockStrtDteTme         : String; // nullable
    SrvcPartsHrznFixedDmndIsTaken          : Boolean;
    SrvcPartsProcmtLeadTimeDetn            : String; // nullable
    SrvcPartsNmbrOfDaysForHorizon          : String; // nullable
    NoSubOrdRemnftdIsAllwd                 : Boolean;
    NoSubOrdSupersessionIsAllwd            : Boolean;
    SrvcPartsDRPReviewTimeDurn             : String; // nullable
    SrvcPartsAntcptdDemandCoverage         : String; // nullable
    SrvcPartsVCLAntcptdDemandCvrg          : String; // nullable
    SrvcPartsStabilityRuleDRP              : String; // nullable
    SrvcPartsSupplierShutdown              : String; // nullable
    SrvcPartsCnsldtdOrdering               : String; // nullable
    SrvcPartsVCLCnsldtdOrdering            : String; // nullable
    SrvcPartsDRPPlngModeTrggrIsSet         : Boolean;
    SrvcPartsRndngMaxStockIsSet            : Boolean;
    SrvcPartsPrflMaxValApprvlRules         : String; // nullable
    SrvcPartsManRevLFHStartDteTme          : String; // nullable
    SrvcPartsManRevLFHEndDteTme            : String; // nullable
    SrvcPartsPostpnRevStrtDteTme           : String; // nullable
    SrvcPartsPostpnRevEndDteTme            : String; // nullable
    SrvcPartsProdPromnStartDate            : String; // nullable
    SrvcPartsProdPromnEndDate              : String; // nullable
    SrvcPartsStockIsInaccurate             : String; // nullable
    SrvcPartsProductKitToOrder             : String; // nullable
    SrvcPartsSaleIsRestricted              : Boolean;
    SrvcPartsReprBuyOrKitStkSwitch         : String; // nullable
    SrvcPartsReprBuyOrKitStkType           : String; // nullable
    SrvcPartsReprRetsForecastType          : String; // nullable
    SrvcPartsRetProdPctGoodQty             : String; // nullable
    SrvcPartsReprblProdPctRetVal           : String; // nullable
    SrvcPartsProductRepairTimeInt          : String; // nullable
    SrvcPartsProdRepairTimeBuffer          : String; // nullable
    SrvcPartsLateRqmtCvrgAmtVal            : String; // nullable
    SrvcPartsReprReturnsForecast           : String; // nullable
    SrvcPartsKitToStkShutdown              : String; // nullable
    SrvcPartsKitStkReprPlngHrznVal         : String; // nullable
    SrvcPartsDeploymentPlng                : String; // nullable
    SrvcPartsDplntPlngStbltyDteTme         : String; // nullable
    SrvcPartsPushDplntFromSupplier         : String; // nullable
    SrvcPartsMltplrExprShptVal             : String; // nullable
    SrvcPartsDplntReviewTimeDurn           : String; // nullable
    SrvcPartsDplntPlanningRunDurn          : String; // nullable
    SrvcPartsCustApprvlReplnmtOrd          : String; // nullable
    SrvcPartsDeploymentVCL                 : String; // nullable
    SrvcPartsParLocRmngQtyIsKept           : Boolean;
    SrvcPartsAddlGrossDemandVal            : String; // nullable
    SrvcPartsMaximumGrossDemandVal         : String; // nullable
    SrvcPartsLockStartDteTme               : String; // nullable
    SrvcPartsLockEndDteTme                 : String; // nullable
    SrvcPartsDeploymentLockRsn             : String; // nullable
    SrvcPartsLocLockStrtDteTme             : String; // nullable
    SrvcPartsLocLockEndDteTme              : String; // nullable
    SrvcPartsLocationLockRsn               : String; // nullable
    SrvcPartsWrhsSpaceSvngStorType         : String; // nullable
    SrvcPartsSvngPreventedLossVal          : String; // nullable
    SrvcPartsAvgQtyStorBinQty              : String; // nullable
    SrvcPartsInventoryBalancing            : String; // nullable
    SrvcPartsLongEOQSftyMod                : String; // nullable
    SrvcPartsLongEOQSftyModVCL             : String; // nullable
    SrvcPartsEOQCalculationType            : String; // nullable
    SrvcPartsEOQSftyStkHasTimeSers         : Boolean;
    SrvcPartsVCLSftyStkIsTimeSers          : Boolean;
    SrvcPartsLocationIsStockedRgnl         : Boolean;
    SrvcPartsRecmddStorQuantity            : String; // nullable
    SrvcPartProdRepairCostsAmtVal          : String; // nullable
    SrvcPartsUnsrvcblRetTimeVal            : String; // nullable
	parentPlant: Association to Plant;
}

entity FASTCoreBusinessPartner: cuid, managed{
	UUID: UUID;
	InternalID                                                    : String; // Adjust length if necessary
    CategoryCode                                                  : String; // Adjust length if necessary
    NumberRangeIntervalBusinessPartnerGroupCode                   : String;
	Customer: Association to Customer on Customer.parent = $self;
    Supplier: Association to Supplier on Supplier.parent = $self;
	AddressInformation: Association to AddressInformation on AddressInformation.parent = $self;
	AddressIndependentCommInfo: Association to AddressIndependentCommInfo on AddressIndependentCommInfo.parent = $self;
	Common: Association to Common on Common.parent = $self;
	Role: Composition of many Role on Role.parent = $self;
	TaxNumber: Association to TaxNumber on TaxNumber.parent = $self;
	FinancialServicesCommon: Association to FinancialServicesCommon on FinancialServicesCommon.parent = $self;
	CreditManagementProfile: Association to CreditManagementProfile on CreditManagementProfile.parent = $self;
	CreditManagementCreditWorthiness: Association to CreditManagementCreditWorthiness on CreditManagementCreditWorthiness.parent = $self;
}

entity Customer: cuid {  
    InternalID                                     : String;
    MaintenanceProfileCode                         : String;
    AuthorisationGroupCode                         : String;
    ExpressTrainStationLocationName                : String;
    TrainStationLocationName                       : String;
    CustomerPartyWithFiscalAddressInternalID       : String;
    ReceiverCustomerPartyWithFiscalAddressInternalID : String;
    AlternativePayeePartyInternalID                : String;
    ReceiverAlternativePayeePartyInternalID        : String;
    AlternativePayeeAllowedIndicator               : Boolean;
    CorporateGroupName                             : String;
    StandardPointLocationCode                      : String;
    DeletionBlockedIndicator                       : Boolean;
    DeletedIndicator                               : Boolean;
    CountyCode                                     : String;
    CityCode                                       : String;
    PostingBlockedIndicator                        : Boolean;
    EqualizationTaxRelevanceIndicator              : Boolean;
    ValueAddedTaxRelevanceIndicator                : Boolean;
    TradingPartnerCompanyID                        : String;
    TaxGroupCode                                   : String;
    ICMSExemptionIndicator                         : Boolean;
    IPIExemptionIndicator                          : Boolean;
    TaxSubstitutionGroupCode                       : String;
    CFOPCategoryCode                               : String;
    RepresentativeName                             : String; 
    BusinessTypeName                               : String; 
    IndustryTypeName                               : String; 
    RelatedSupplierInternalID                      : String;  
    PaymentReasonCode                              : String;
    AccountingInformation: Composition of many AccountingInformation on AccountingInformation.parentCustomer = $self;
    SalesArrangement: Composition of many SalesArrangement on SalesArrangement.parentCustomer = $self;
    TaxClassification: Composition of many TaxClassification on TaxClassification.parentCustomer = $self;
    SaleSalesAndDistributionBlocks: Association to SaleSalesAndDistributionBlocks on SaleSalesAndDistributionBlocks.parent = $self;
    IndustrySector: Association to IndustrySector on IndustrySector.parent = $self;
    MarketingAttributes: Association to MarketingAttributes on MarketingAttributes.parent = $self;
    LegalControlIndicators: Association to LegalControlIndicators on LegalControlIndicators.parent = $self;
    PriceSpecifications: Association to PriceSpecifications on PriceSpecifications.parent = $self;
    parent: Association to FASTCoreBusinessPartner;
}

entity Supplier: cuid {  
    InternalID                              : String;
    CreditorInformationNumber                   : String;
    MaintenanceProfileCode                      : String;
    ProcurementTransactionBlockingCode          : String;
    DeletionBlockedIndicator                    : Boolean;
    DeletedIndicator                            : Boolean;
    PostingBlockedIndicator                     : Boolean;
    PurchasingBlockedIndicator                  : Boolean;
    TradingPartnerCompanyID                     : String;
    ManufacturerPartyID                         : String;
    AuthorisationGroupCode                      : String;
    CorporateGroupName                          : String;
    ProofOfDeliveryRequirementCode              : String;
    CreditDataLastCheckDate                     : String;
    TrainStationLocationName                    : String;
    DataMediumExchangeReportCode                : String;
    DataMediumExchangeInstructionCode           : String;
    InpaymentSlipWithReferenceNumberSubscriberID: String;
    AlternativePayeePartyInternalID             : String;
    AlternativePayeeAllowedIndicator            : Boolean;
    EqualizationTaxRelevanceIndicator           : Boolean;
    ValueAddedTaxRelevanceIndicator             : Boolean;
    FiscalAddressPartyInternalID                : String;
    SupplyingPlantID                            : String;
    SellerAssortmentProductGroupLevelRelevanceIndicator : Boolean;
    PlantLevelRelevanceIndicator                : Boolean;
    WorkingDayCalendarCode                      : String;
    CarrierPartyStandardID                      : String;
    CarrierPartyFreightGroupCode                : String;
    ServicePerformerPartyGroupCode              : String;
    StatisticsGroupCode                         : String;
    TaxAuthorityPartyID                         : String;
    TaxGroupCode                                : String;
    SocialInsuranceActivityCode                 : String;
    ForSocialInsuranceRegisteredIndicator       : Boolean;
    TaxSplitIndicator                           : Boolean;
    TaxBasePercentageCode                       : String;
    ResponsibleTaxOfficePartyInternalID         : String;
    RepresentativeName                          : String;
    BusinessTypeName                            : String;
    IndustryTypeName                            : String;
    RelatedCustomerInternalID                   : String;
    CollectiveNumberingRelevancyIndicator       : Boolean;
    StagingDuration                             : Integer;
    SchedulingProcedureCode                     : String;
    TransportationChainCode                     : String;
    AcceptanceAtOriginIndicator                 : Boolean;
    PaymentReasonCode                           : String;
    AccountingInformation : Association to AccountingInformation on AccountingInformation.parentSupplier = $self;
    ProcurementArrangement : Association to ProcurementArrangement on ProcurementArrangement.parentSupplier = $self;
    parent: Association to FASTCoreBusinessPartner;
}

entity ProcurementArrangement: cuid {
    PurchasingOrganisationID                : String;
    PurchasingGroupID                           : String;
    DeletedIndicator                            : Boolean;
    SupplierABCClassificationCode               : String;
    SellerPartyContactPersonName                : String;
    ActivityProfileCode                         : String;
    TransportationChainCode                     : String;
    StagingDuration                             : Integer;
    ValueAddedServiceDeterminationModeCode      : String;
    CharacteristicValueConversionCode           : String;
    ReturnsSupplierIndicator                    : Boolean;
    PurchasingTerms                             : Association to PurchasingTerms on PurchasingTerms.parentProcurementArrangement = $self;
    PartnerFunctions : Composition of many PartnerFunctions on PartnerFunctions.parentProcurementArrangement = $self;
    parentSupplier: Association to Supplier;
}

entity PurchasingTerms: cuid {
    CustomsOfficeInternalID                     : String;
    BuyerPartySellerID                          : String;
    PurchaseOrderCurrencyCode                   : String;
    CashDiscountTermsCode                       : String;
    ReturnItemsEvaluatedReceiptSettlementIndicator : Boolean;
    TransportModeCode                           : String;
    TransportServiceLevelCode                   : String;
    PriceSpecificationSupplierGroupCode         : String;
    PriceSpecificationDeterminationDateTypeCode : String;
    ExpectedPurchasingDocumentItemConfirmationTypeCode : String;
    MeasureUnitGroupCode                        : String;
    RoundingProfileCode                         : String;
    DeliveryCyclePlanningCalendarCode           : String;
    PlanningCyclePlanningCalendarCode           : String;
    GoodsMovementItemSortCriterionCode          : String;
    LoadBuildingRestrictionProfileCode          : String;
    DataTransferProfileCode                     : String;
    PurchasingBlockedIndicator                  : Boolean;
    DeliveryBasedInvoiceVerificationIndicator   : Boolean;
    EvaluatedReceiptSettlementIndicator         : Boolean;
    AutomaticPurchaseOrderGenerationAllowedIndicator : Boolean;
    PurchaseOrderBySupplierProvidedIndicator    : Boolean;
    DiscountInKindAllowedIndicator              : Boolean;
    IndexCompilationForSubsequentSettlementAllowedIndicator : Boolean;
    DocumentIndexAllowedIndicator               : Boolean;
    AgencyBusinessRelevanceIndicator            : Boolean;
    RevaluationAllowedIndicator                 : Boolean;
    ServiceBasedInvoiceVerificationIndicator    : Boolean;
    SubsequentSettlementApplyIndicator          : Boolean;
    BusinessVolumeComparisonRequiredIndicator   : Boolean;
    PricingRelevanceIndicator                   : Boolean;
    RackJobbingIncludedIndicator                : Boolean;
    PriceMakingAgreementTypeCode                : String;
    OrderMinimumAmount                          : Double;
    PlannedDeliveryDuration                     : Integer;
    SalesVolumeFulfillmentPercent               : Double;
    PurchaseOrderConfirmationRequirementCode    : String;
    Incoterms: Association to Incoterms on Incoterms.parentPurchasingTerms = $self;
    parentProcurementArrangement: Association to ProcurementArrangement;
}


entity TaxClassification: cuid{
    TaxCountryCode                           : String;
    TaxTypeCode                              : String;
    TaxGroupCode                             : String;
    parentCustomer: Association to Customer;
}

entity SaleSalesAndDistributionBlocks: cuid{
    OrderBlockingReasonCode                        : String; 
    BillingBlockingReasonCode                      : String; 
    DeliveryBlockingReasonCode                     : String; 
    SalesSupportBlockedIndicator                   : Boolean;
    parent: Association to Customer;
}

entity IndustrySector: cuid{
    IndustrialSectorCode                           : String; 
    FirstAdditionalIndustrialSectorCode            : String; 
    SecondAdditionalIndustrialSectorCode           : String; 
    ThirdAdditionalIndustrialSectorCode            : String; 
    FourthAdditionalIndustrialSectorCode           : String; 
    parent: Association to Customer;
}

entity MarketingAttributes: cuid{
    CustomerGroupCode                              : String; 
    CustomerNielsenRegionCode                      : String; 
    FiscalYearVariantCode                          : String;  
    AnnualSalesVolumeAmount                        : Decimal; 
    AnnualSalesVolumeAmountReportedYear            : Integer;   
    EmployeeNumberValue                            : Integer;   
    EmployeeNumberValueReportedYear                : Integer; 
    parent: Association to Customer; 
}

entity LegalControlIndicators: cuid{
    BiochemicalWarfareIndicator                    : Boolean;
    NuclearNonproliferationIndicator               : Boolean;
    NationalSecurityIndicator                      : Boolean;
    MissileTechnologyIndicator                     : Boolean;
    parent: Association to Customer; 
}

entity PriceSpecifications: cuid{
    CustomerConditionGroupCode                     : String; 
    FirstAdditionalCustomerConditionGroupCode      : String; 
    SecondAdditionalCustomerConditionGroupCode     : String; 
    ThirdAdditionalCustomerConditionGroupCode      : String; 
    FourthAdditionalCustomerConditionGroupCode     : String; 
    parent: Association to Customer; 
}

entity AccountingInformation: cuid {
    CompanyID                              : String;
    EmployeeID                                 : String;
    BlockedIndicator                           : Boolean;
    DeletedIndicator                           : Boolean;
    SortCode                                   : String;
    AccountingClerkInitialsCode                : String;
    GeneralLedgerAccountReferenceID             : String;
    AuthorisationGroupCode                     : String;
    HeadOfficeAccountInternalID                : String;
    ReceiverHeadOfficeAccountInternalID        : String;
    AlternativePayeePartyInternalID            : String;
    ReceiverAlternativePayeePartyInternalID    : String;
    PaymentNoticeCustomerClearedItemsIndicator : Boolean;
    PaymentNoticeSalesDepartmentIndicator      : Boolean;
    PaymentNoticeLegalDepartmentIndicator      : Boolean;
    PaymentNoticeAccountingIndicator           : Boolean;
    PaymentNoticeCustomerWithoutClearedItemsIndicator : Boolean;
    PaymentMethodsCode                         : String;
    CustomerSupplierClearingIndicator          : Boolean;
    PaymentBlockCode                           : String;
    CashDiscountTermsCode                      : String;
    BillOfExchangeChargesCashDiscountTermsCode : String;
    InterestCalculationInclusionCode           : String;
    LastInterestCalculationKeyDate             : String;
    InterestCalculationFrequencyCode           : String;
    DebtorPartyCreditorID                      : String;
    EmployeeResponsiblePartyName               : String;
    Note                                       : String;
    PlanningGroupCode                          : String;
    ExportCreditInsuranceInstitutionID         : String;
    InsuredAmount                              : Double;
    InsuranceLeadDuration                      : Integer;
    DeductiblePercent                          : Double;
    InsuranceID                                : String;
    InsuranceValidityDate                      : String;
    CollectiveInvoiceVariantID                 : String;
    LocalProcessingIndicator                   : Boolean;
    PeriodicAccountStatementsCode              : String;
    BillOfExchangeLimitAmount                  : Double;
    NextPayeeInternalID                        : String;
    ReceiverNextPayeeInternalID                : String;
    LastInterestCalculationRunDate             : String;
    RecordPaymentHistoryIndicator              : Boolean;
    BusinessPartnerToleranceGroupCode          : String;
    ProbableCheckPaidDuration                  : Integer;
    HouseBankInternalID                        : String;
    PayItemsSeparatelyIndicator                : Boolean;
    ReductionRatesDeterminationCode            : String;
    PreviousCustomerInternalID                 : String;
    PaymentGroupingCode                        : String;
    LeaveReasonCode                            : String;
    DunningNoticeGroupingCode                  : String;
    LockboxCode                                : String;
    PaymentMethodSupplementCode                : String;
    BuyingGroupInternalID                      : String;
    ReceiverBuyingGroupInternalID              : String;
    PaymentAdvicesSelectionRuleCode            : String;
    PaymentAdvicesByEDIIndicator               : Boolean;
    ReleaseApprovalGroupCode                   : String;
    ConversionVersionReasonCode                : String;
    EmployeeResponsiblePartyTelephoneFormattedNumberDescription : String;
    EmployeeResponsiblePartyFaxFormattedNumberDescription : String;
    EmployeeResponsiblePartyWebAddress         : String;
    CreditMemosPaymentTermsCode                : String;
    ValueAdjustmentCode                        : String;
    DeletionBlockedIndicator                   : Boolean;
    AccountsReceivablePledgingCode             : String;
    PaymentReasonCode                          : String;
    DoubleEntriesCheckIndicator                : Boolean;
    WithholdingTaxExemptionCertificateID       : String;
    WithholdingTaxExemptionCertificateValidityDate : String;
    WithholdingTaxTypeCode                     : String;
    WithholdingTaxExemptionReasonCode          : String;
    WithholdingTaxCountryCode                  : String;
    VendorRecipientTypeCode                    : String;
    MinorityIndicatorsCode                     : String;
    PreviousSupplierInternalID                 : String;
    InvoiceVerificationToleranceGroupCode      : String;
    CertificationDate                          : String;
    AssignmentTestGroupCode                    : String;
    PrePaymentRelevancyCode                    : String;
    WithholdingTax: Composition of many WithholdingTax on WithholdingTax.parentAccountingInformation = $self;
    parentCustomer: Association to Customer;
    parentSupplier: Association to Supplier;
}

entity WithholdingTax: cuid {
    WithholdingTaxTypeCode                     : String;
    SubjectToWithholdingTaxIndicator           : Boolean;
    VendorRecipientTypeCode                    : String;
    WithholdingTaxIdentificationNumber         : String;
    WithholdingTaxCode                         : String;
    WithholdingTaxExemptionCertificateID       : String;
    WithholdingTaxExemptionRate                : Double;
    WithholdingTaxExemptionValidityPeriod : Association to one WithholdingTaxExemptionValidityPeriod on WithholdingTaxExemptionValidityPeriod.parentWithholdingTax = $self;
    parentAccountingInformation: Association to AccountingInformation;
}

entity WithholdingTaxExemptionValidityPeriod: cuid{
    StartDate                                 : Date;
    EndDate                                   : Date;
    parentWithholdingTax: Association to WithholdingTax;
}


entity SalesArrangement: cuid {
    SalesOrganisationID                   : String;
    DistributionChannelCode                   : String;
    DivisionCode                              : String;
    AuthorisationGroupCode                    : String;
    DeletedIndicator                          : Boolean;
    StatisticsGroupCode                       : String;
    OrderBlockingReasonCode                   : String;
    PricingProcedureDeterminationCode         : String;
    PricingProcedureDeterminationCodeLong     : String;
    GroupCode                                 : String;
    SalesDistrictCode                         : String;
    PriceGroupCode                            : String;
    PriceListTypeCode                         : String;
    ItemOrderProbabilityNumberValue           : Double;
    DeliveryBlockingReasonCode                : String;
    BatchSplitAllowedIndicator                : Boolean;
    SellerPartyBuyerID                        : String;
    TransportServiceLevelCode                 : String;
    BillingBlockingReasonCode                 : String;
    ManualInvoiceMaintenanceIndicator         : Boolean;
    InvoiceDatesCalendarCode                  : String;
    IncoiceListScheduleCalendarCode           : String;
    CurrencyCode                              : String;
    ABCClassificationCode                     : String;
    AccountAssignmentGroupCode                : String;
    CashDiscountTermsCode                     : String;
    DeliveringPlantID                         : String;
    SalesGroupCode                            : String;
    SalesOfficeCode                           : String;
    ProductProposalID                         : String;
    CustomerDefinedGroupCode                  : String;
    FirstAdditionalCustomerDefinedGroupCode   : String;
    SecondAdditionalCustomerDefinedGroupCode  : String;
    ThirdAdditionalCustomerDefinedGroupCode   : String;
    FourthAdditionalCustomerDefinedGroupCode  : String;
    RebateRelevantIndicator                   : Boolean;
    ExchangeRateTypeCode                      : String;
    PricingRelevanceIndicator                 : Boolean;
    PaymentGuaranteeProcedureCode             : String;
    CreditControlAreaCode                     : String;
    SalesSupportBlockedIndicator              : Boolean;
    RoundingSwitchOffIndicator                : Boolean;
    AgencyBusinessRelevanceIndicator          : Boolean;
    MeasureUnitGroupCode                      : String;
    ProductProposalCustomerProcedureCode      : String;
    PODRelevanceIndicator                     : Boolean;
    PODConfirmationTimeframeDuration          : Integer;
    DocumentIndexAllowedIndicator             : Boolean;
    FifthAdditionalCustomerDefinedGroupCode   : String;
    SixthAdditionalCustomerDefinedGroupCode   : String;
    SeventhAdditionalCustomerDefinedGroupCode : String;
    EighthAdditionalCustomerDefinedGroupCode  : String;
    NinthAdditionalCustomerDefinedGroupCode   : String;
    ValueAddedServiceDeterminationModeCode    : String;
    ValueAddedServiceCustomerGroupCode        : String;
    CharacteristicValueConversionCode         : String;
    OrderSchedulingStrategyCode               : String;
    OrderSchedulingStrategyFillRatePercent    : Double;
    OrderSchedulingStratgeyAggregationLevelCode : String;
    MultiShiptoOrderCustomerDistributionCenterID : String;
    MultiShiptoOrderCustomerName              : String;
    PSSTGroupingRuleCode                      : String;
    PSSTGroupingRuleExcludeIndicator          : Boolean;
    DeliveryTerms: Association to DeliveryTerms on DeliveryTerms.parentSalesArrangement = $self;
    PartnerFunctions : Composition of many PartnerFunctions on PartnerFunctions.parentSalesArrangement = $self;
    parentCustomer: Association to Customer;
}

entity PartnerFunctions: cuid {
    PartyRoleCode                        : String;
    PartyInternalID                          : String;
    ReceiverPartyInternalID                  : String;
    DefaultIndicator                         : Boolean;
    parentSalesArrangement : Association to SalesArrangement;
    parentProcurementArrangement: Association to ProcurementArrangement;
}

entity DeliveryTerms: cuid{
    DeliveryPriorityCode                      : String;
    Incoterms: Association to Incoterms on Incoterms.parentDeliveryTerms = $self;
    SalesOrderCompleteDeliveryIndicator       : Boolean;
    OrderCombinationAllowedIndicator          : Boolean;
    PartialDeliveryControlCode                : String;
    PartialDeliveryMaximumNumberValue         : Integer;
    QuantityTolerance: Association to QuantityTolerance on QuantityTolerance.parent = $self;
    parentSalesArrangement: Association to SalesArrangement;
}

entity Incoterms: cuid{
    ClassificationCode                      : String;
    TransferLocationName                    : String;
    TransferLocationNameLong                : String;
    TransferLocationInternalID              : String;
    DestinationLocationName                 : String;
    DestinationLocationInternalID           : String;
    DeviatingDestinationLocationInternalID  : String;
    Version                                 : String;
    parentDeliveryTerms: Association to DeliveryTerms;
    parentPurchasingTerms: Association to PurchasingTerms;

}

entity QuantityTolerance: cuid{
    OverPercent                              : Double;
    OverPercentUnlimitedIndicator            : Boolean;
    UnderPercent                             : Double;
    parent: Association to DeliveryTerms;
}

entity AddressInformation: cuid {
    UUID                                       : String;
    MoveDestinationAddressUUID                     : String;
    MoveDate                                       : Date;
    ValidityPeriod: Association to ValidityPeriod on ValidityPeriod.parentAddressInformation = $self;
    AddressUsage : Association to AddressUsage on AddressUsage.parentAddressInformation = $self;
    Address: Association to Address on Address.parentAddressInformation = $self;
    parent: Association to FASTCoreBusinessPartner;
}

entity ValidityPeriod : cuid {
    StartDate                                  : Date;
    EndDate                                    : Date;
    parentAddressInformation: Association to AddressInformation;
    parentAddressUsage: Association to AddressUsage;
    parentRole: Association to Role;
}

entity AddressUsage : cuid {
    AddressUsageCode: String;
    ValidityPeriod : Association to ValidityPeriod on ValidityPeriod.parentAddressUsage = $self;
    DefaultIndicator: Boolean;
    parentAddressInformation: Association to AddressInformation;
}

entity Address : cuid {
    CommunicationPreference : Association to CommunicationPreference on CommunicationPreference.parentAddress = $self;
    PostalAddress : Association to PostalAddress on PostalAddress.parentAddress = $self;
    parentAddressInformation: Association to AddressInformation;
}

entity CommunicationPreference: cuid{
    CorrespondenceLanguageCode                : String;
    PreferredCommunicationMediumTypeCode      : String;
    parentAddress: Association to Address;
}

entity PostalAddress: cuid{
    CountryCode                                : String;
    RegionCode                                 : String;
    CityName                                   : String;
    AdditionalCityName                         : String;
    DistrictName                               : String;
    StreetPostalCode                           : String;
    POBoxPostalCode                            : String;
    CompanyPostalCode                          : String;
    StreetPrefixName                           : String;
    AdditionalStreetPrefixName                 : String;
    StreetName                                 : String;
    StreetSuffixName                           : String;
    AdditionalStreetSuffixName                 : String;
    HouseID                                    : String;
    AdditionalHouseID                          : String;
    BuildingID                                 : String;
    RoomID                                     : String;
    FloorID                                    : String;
    CareOfName                                 : String;
    StreetAddressMailNonDeliveryReasonCode     : String;
    POBoxDeviatingCountryCode                  : String;
    POBoxDeviatingRegionCode                   : String;
    POBoxDeviatingCityName                     : String;
    POBoxLobbyName                             : String;
    POBoxID                                    : String;
    POBoxAddressMailNonDeliveryReasonCode      : String;
    POBoxIDVisibleIndicator                    : Boolean;
    POBoxDeliveryServiceID                     : String;
    POBoxDeliveryServiceTypeCode               : String;
    TaxJurisdictionCode                        : String;
    TimeZoneCode                               : String;
    TransportationZoneID                       : String;
    RegionalStructureElementGroupCode          : String;
    RegionalStructureAddressConsistencyStatusCode : String;
    RegionalStructureCityCode                  : String;
    AdditionalRegionalStructureCityCode        : String;
    POBoxDeviatingRegionalStructureCityCode   : String;
    RegionalStructureDistrictCode             : String;
    RegionalStructureStreetCode               : String;
    ExtendedBuildingID                        : String;
    LegacyAddressID                           : String;
    CountyName                                : String;
    RegionalStructureCountyCode               : String;
    TownshipName                              : String;
    RegionalStructureTownshipCode             : String;
    parentAddress: Association to Address;
}

entity AddressIndependentCommInfo: cuid{
    CommunicationPreference: String;
    parent: Association to FASTCoreBusinessPartner;
}

entity Common: cuid{
    LocationStandardID                             : String;
    BusinessPartnerGroupCode                       : String;
    DeletedIndicator                               : Boolean;
    ReleasedIndicator                              : Boolean;
    BlockedIndicator                               : Boolean;
    BusinessPartnerAuthorisationGroupCode          : String;
    KeyWordsText                                   : String;
    AdditionalKeyWordsText                         : String;
    VerbalCommunicationLanguageCode                : String;
    SalutationText                                 : String;
    CorrespondenceBrailleRequiredIndicator         : Boolean;
    CorrespondenceLargePrintRequiredIndicator      : Boolean;
    NaturalPersonIndicator                         : Boolean;
    ContactAllowedCode                             : String;
    LegacyBusinessPartnerID                        : String;
    DataOriginTypeCode                             : String;
    Person: Association to Person on Person.parentCommon = $self;
    Organisation:Association to Organisation on Organisation.parentCommon = $self;
    Group: Association to Group on Group.parentCommon = $self;
    parent: Association to FASTCoreBusinessPartner;
}

entity Person: cuid{
    Name: Association to Name on Name.parentPerson = $self;
    GenderCode                                 : String;
    GenderValueCode                            : String;
    BirthPlaceName                             : String;
    BirthDate                                  : String;
    BirthdateStatusCode                        : String;
    DeathDate                                  : String;
    MaritalStatusCode                          : String;
    NonVerbalCommunicationLanguageCode         : String;
    OccupationCode                             : String;
    Employer                                   : String;
    NationalityCountryCode                     : String;
    OriginCountryCode                          : String;
    parentCommon: Association to Common;
}

entity Organisation: cuid{
    Name: Association to Name on Name.parentOrganisation = $self;
    CompanyLegalFormCode                       : String;
    LegalEntityTypeCode                        : String;
    FoundationDate                             : String;
    LiquidationDate                            : String;
    parentCommon: Association to Common;
}

entity Group: cuid{
    FormOfAddressCode: String;
    Name:String;
    AdditionalName:String;
    PartnerGroupTypeCode: String;
    parentCommon: Association to Common;
}

entity Name: cuid{
    FormOfAddressCode                      : String;
    FirstLineName                          : String;
    SecondLineName                         : String;
    ThirdLineName                          : String;
    FourthLineName                         : String;
    GivenName                              : String;
    MiddleName                             : String;
    FamilyName                             : String;
    AdditionalFamilyName                   : String;
    BirthName                              : String;
    NickName                               : String;
    InitialsName                           : String;
    AcademicTitleCode                      : String;
    AdditionalAcademicTitleCode            : String;
    NamePrefixCode                         : String;
    AdditionalNamePrefixCode               : String;
    NameSupplementCode                     : String;
    DeviatingFullName                      : String;
    NameFormatCountryCode                  : String;
    NameFormatCode                         : String;
    parentPerson: Association to Person;
    parentOrganisation: Association to Organisation;
}

entity Role: cuid{
    RoleCode: String;
    ValidityPeriod : Association to ValidityPeriod on ValidityPeriod.parentRole = $self;
    parent: Association to FASTCoreBusinessPartner;
}

entity TaxNumber: cuid {
    CountryCode                                : String;
    TaxIdentificationNumberTypeCode                : Integer;
    LongTaxIdentificationNumberTypeCode            : String;
    PartyTaxID                                      : String;
    LongPartyTaxID                                 : String;
    parent: Association to FASTCoreBusinessPartner;
}

entity CreditManagementProfile: cuid {
    CreditLimitAndScoreCalculatingRuleCode : String;
    Score                                  : Integer;
    CreditRiskClassCode                    : String;
    CreditRiskClassChangeDate              : Date;
    CreditGroupCode                        : String;
    parent: Association to FASTCoreBusinessPartner;
}

entity CreditManagementCreditWorthiness: cuid {
    AffidavitForAssetsMadeIndicator           : Boolean;
    AffidavitForAssetsMadeDate                : Date;
    BankruptcyProceedingsInitiatedIndicator   : Boolean;
    BankruptcyProceedingsInitiatedDate        : Date;
    ForeclosureProceedingsInitiatedIndicator  : Boolean;
    ForeclosureProceedingsInitiatedDate       : Date;
    parent: Association to FASTCoreBusinessPartner;
}

entity FinancialServicesCommon: cuid {
    SalutationCode                         : String;
    VIPIndicator                           : Boolean;
    CustomerUndesirableIndicator           : Boolean;
    CustomerUndesirableReasonCode          : String;
    CustomerUndesirableReasonNote          : String;
    LastContactDate                        : Date;
    BusinessRelationshipEndDate            : Date;
    TargetMarketGroupCode                  : String;
    AffiliatedCompanyID                    : String;
    AffiliatedCompanyGroupID               : String;
    ReportingCountryCode                   : String;
    Person                                 : Association to FinancialServicesCommonPerson on Person.parentFinancialServicesCommon = $self;
    Organisation                           : Association to FinancialServicesCommonOrganisation on Organisation.parentFinancialServicesCommon = $self;
    parent: Association to FASTCoreBusinessPartner;
}

entity FinancialServicesCommonPerson: cuid {
    PrimaryCitizenshipCountryCode          : String;
    MaritalPropertyRegimeCode              : String;
    ChildrenNumberValue                    : Integer;
    HouseholdMembersNumberValue            : Integer;
    AnnualNetIncomeAmount                  : Decimal;
    AnnualNetIncomeYear                    : Integer;
    MonthlyNetIncomeAmount                 : Decimal;
    MonthlyNetIncomeMonth                  : Integer;
    MonthlyNetIncomeYear                   : Integer;
    NetIncomeCurrencyCode                  : String;
    DeathPlaceName                         : String;
    EmployeeIndicator                      : Boolean;
    EmployeeID                             : String;
    EmployeeCustomGroupCode                : String;
    EmployeeIDExistenceCheckIndicator      : Boolean;
    UserAccountID                          : String;
    parentFinancialServicesCommon: Association to FinancialServicesCommon;
}

entity FinancialServicesCommonOrganisation {
    CompanyWorkingDayCalendarCode          : String;
    RegisteredOfficeCountryCode            : String;
    RegisteredOfficeRegionCode             : String;
    RegisteredOfficeCityName               : String;
    BalanceSheetDisclosureFormCode         : String;
    EquityCapitalIncreaseAmount            : Decimal;
    EquityCapitalIncreaseFiscalYearID      : Integer;
    MaxSizeOfOrderingFile                  : Integer;
    parentFinancialServicesCommon: Association to FinancialServicesCommon;
}

























