namespace com.bayer.SXTENDER.MasterData.SAP;

using { Currency, User, Country, managed, cuid } from '@sap/cds/common';
using { 
	E1KNA1M, E1KNA11, E1KNB1M, E1MARAM, E1MARA1, E1MAKTM, E1MARCM, E1MARDM, E1MARMM,E1MBEWM, E1MVKEM, E1MLANM, E1MTXHM, E1MTXLM, E1KNVVM, E1KNVKM, E1KNKKM
} from './SAPTypes';


@cds.persistence.exists
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

@cds.persistence.exists
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

@cds.persistence.exists
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

@cds.persistence.exists
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

@cds.persistence.exists
entity BrazilTaxes: cuid, managed {
	SHIPFROM			: String;
	SHIPTO				: String;
	TAX_GROUP			: String;
	MATERIAL			: String;
	RATE				: String;
	BASE				: String;
}

@cds.persistence.exists
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

@cds.persistence.exists
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

@cds.persistence.exists
entity BrazilExemptions: cuid, managed {
	SHIP_TO 			: String(3);			// Ship from location (tax region) - Bayer location
	SHIP_FROM			: String(3);			// Ship to location (tax region)
	GROUPS				: String(2);			// Table TAX Group 
	MATNR				: String(18);			// SAP product Code
	RATE				: String(6);			// Aliquot used for exemption process
	BASE				: String(6);			// Base uses for exemption process
}

@cds.persistence.exists
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

@cds.persistence.exists
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

@cds.persistence.exists
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

@cds.persistence.exists
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

@cds.persistence.exists
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

@cds.persistence.exists
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

@cds.persistence.exists
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


@cds.persistence.exists
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

@cds.persistence.exists
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


@cds.persistence.exists
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

@cds.persistence.exists
entity ItalyCustomers: cuid, managed {
	E1KNA1M				: E1KNA1M;				// Master customer master basic data (KNA1 - SAP table)
	E1KNA11				: E1KNA11;				// Customer Master: Additional General Fields  (KNA1 - SAP table)
	E1KNB1M				: E1KNB1M;				// Master Customer Master Company Code (KNB1- SAP table )
	E1KNVVM				: E1KNVVM; 				// Master customer master sales data (KNVV- SAP table)
	E1KNVKM				: E1KNVKM;				// Master customer master contact person (KNVK - SAP table)
	E1KNKKM				: E1KNKKM;				// Master customer master credit mgmt control area data (KNKK - SAP table name)
}

@cds.persistence.exists
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

@cds.persistence.exists
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

@cds.persistence.exists
entity SpainCustomers: cuid, managed {
	E1KNA1M				: E1KNA1M;				// Master customer master basic data (KNA1 - SAP table)
    E1KNA11				: E1KNA11;				// Customer Master: Additional General Fields  (KNA1 - SAP table)
    E1KNB1M				: E1KNB1M;				// Master Customer Master Company Code (KNB1- SAP table )
}


@cds.persistence.exists
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


@cds.persistence.exists
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

@cds.persistence.exists
entity PLANT_ADDR : cuid{
	WERKS				: String(4);			// Plant
	NAME1				: String(30);			// Name
	STRAS				: String(30);			// House number and street
	PSTLZ				: String(10);			// Postal Code
	ORT01				: String(25);			// City
	LAND1				: String(3);			// Country Key
	REGIO				: String(3);			// Region (State, Province, County)
}

@cds.persistence.exists
entity SpainRappel : cuid {
	KNUMA 				: String;	
	BONEM 				: String;	
	DATAB 				: String;				// Effective date
	DATBI 				: String;				// Expiry date
	KNUMH 				: String;				// Customer ID
	SOLD_TO 			: String;	
	MATNR 				: String(18);			// Material number
}

@cds.persistence.exists
entity FASTCoreMaterial: cuid, managed {
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
    RetailArticle: Composition of many RetailArticle on RetailArticle.parent = $self;
    RetailSeason: Composition of many RetailSeason on RetailSeason.parent = $self;
    RetailHierarchy: Composition of many RetailHierarchy on RetailHierarchy.parent = $self;
    GTIN: Composition of many GTIN on GTIN.parent = $self;
	PrdDesc: Composition of many PrdDesc on PrdDesc.parent = $self;
    QtyConversion: Composition of many QtyConversion on QtyConversion.parent = $self;
    QtyCharacteristic: Composition of many QtyCharacteristic on QtyCharacteristic.parent = $self;
    MatlClassification: Composition of many MatlClassification on MatlClassification.parent = $self;
    IntlTrade: Composition of many IntlTrade on IntlTrade.parent = $self;
    VariantConfig: Composition of many VariantConfig on VariantConfig.parent = $self;
	TxtColl: Composition of many TxtColl on TxtColl.parent = $self;
	StorageSpec: Composition of many StorageSpec on StorageSpec.parent = $self;
    DistChainIndependentSalesSpec: Composition of many DistChainIndependentSalesSpec on DistChainIndependentSalesSpec.parent = $self;
    PlantIndependentProcSpec: Composition of many PlantIndependentProcSpec on PlantIndependentProcSpec.parent = $self;
    PrdSCMAdvPlan: Composition of many PrdSCMAdvPlan on PrdSCMAdvPlan.parent = $self;
	SalesSpec: Composition of many SalesSpec on SalesSpec.parent = $self;
    SalesTaxClass: Composition of many SalesTaxClass on SalesTaxClass.parent = $self;
    PrdPlant:Composition of many PrdPlant on PrdPlant.parent = $self;
    ValuatnArea:Composition of many ValuatnArea on ValuatnArea.parent = $self;
	WHS:Composition of many WHS on WHS.parent = $self;
    SubscrPrd: Composition of many SubscrPrd on SubscrPrd.parent = $self;
    PrdBOM:Composition of many PrdBOM on PrdBOM.parent = $self;
    EWMWHS:Composition of many EWMWHS on EWMWHS.parent = $self;
    SCMPrdGrps: Composition of many SCMPrdGrps on SCMPrdGrps.parent = $self;
    eSPPPrd: Composition of many eSPPPrd on eSPPPrd.parent = $self;
}

@cds.persistence.exists
entity VariantConfig: cuid{
    VarConfignStatus: String;
    VCHCharValuat: Composition of many VCHCharValuat on VCHCharValuat.parentVariantConfig = $self;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity VCHCharValuat: cuid{
    Characteristic: String;
    CharcValue: String;
    CharcValueTo: String;
    CharcValueIntervalType: String;
    CharcValueAssignmentType: String;
    parentVariantConfig: Association to VariantConfig;
}

@cds.persistence.exists
entity IntlTrade: cuid{
    TradeClassNumScheme: Composition of many TradeClassNumScheme on TradeClassNumScheme.parentIntlTrade = $self;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity TradeClassNumScheme: cuid{
    TradeClassificationNumberingSchemeCode: String;
    TradeClass: Composition of many TradeClass on TradeClass.parentTradeClassNumScheme = $self;
    parentIntlTrade: Association to IntlTrade;
}

@cds.persistence.exists
entity TradeClass: cuid{
    TrdClassfctnNmbr: String;
    ValidityStartDate: Date;
    ValidityEndDate: Date;
    parentTradeClassNumScheme: Association to TradeClassNumScheme;
}

@cds.persistence.exists
entity MatlClassification: cuid{
    ChangeNumber: String;
    ClassAsgmtByClassTyp: Composition of many ClassAsgmtByClassTyp on ClassAsgmtByClassTyp.parentMatlClassification = $self;
    CharValByClassType: Composition of many CharValByClassType on CharValByClassType.parentMatlClassification = $self;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity ClassAsgmtByClassTyp: cuid{
    ClassType: String;
    ClassAsgmt: Composition of many ClassAsgmt on ClassAsgmt.parentClassAsgmtByClassTyp = $self;
    parentMatlClassification: Association to MatlClassification;
}

@cds.persistence.exists
entity ClassAsgmt: cuid{
    Class: String;
    ClfnStatus: String;
    StdClass: String;
    parentClassAsgmtByClassTyp: Association to ClassAsgmtByClassTyp;
}

@cds.persistence.exists
entity CharValByClassType: cuid{
    ClassType: String;
    CharacteristicValue: Composition of many CharacteristicValue on CharacteristicValue.parentCharValByClassType = $self;
    parentMatlClassification: Association to MatlClassification;
}

@cds.persistence.exists
entity CharacteristicValue: cuid{
    Characteristic: String;
    CharcValue: String;
    CharcValueDisplayUnit: String;
    CharcValueTo: String;
    CharcValueToDisplayUnit: String;
    CharcValueIntervalType: String;
    parentCharValByClassType: Association to CharValByClassType;
}

@cds.persistence.exists
entity RetailSeason: cuid{
    ProductSeasonYear: String;
    ProductSeason: String;
    ProductCollection: String;
    ProductTheme: String;
    IsProductSeasonType1: Boolean;
    IsProductSeasonType2: Boolean;
    IsProductSeasonType3: Boolean;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity RetailHierarchy: cuid{
    HierarchyID: String;
    HierarchyNode: String;
    DateFrom: Date;
    DateTo: Date;
    IsMainFlag: Boolean;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity GTIN: cuid{
    ProductStandardID: String;
    ProductStandardVariantID: String;
    MeasureUnitCode: String;
    ProductStandardMainIndicator: String;
    PrdRetailSupplierGTIN: Composition of many PrdRetailSupplierGTIN on PrdRetailSupplierGTIN.parentGTIN = $self;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity PrdRetailSupplierGTIN: cuid{
    SupplierID: String;
    SupplierProductID: String;
    parentGTIN: Association to GTIN;
}

@cds.persistence.exists
entity PrdDesc: cuid{
    Description: String;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity TxtColl: cuid{
    TextExistsIndicator:  Boolean;
    PrdTxt: Composition of many PrdTxt on PrdTxt.parentTxtColl = $self;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity PrdTxt: cuid{
    ID: String;
    TypeCode: String;
    LanguageCode: String;
    SAPScrptLn: Composition of many SAPScrptLn on SAPScrptLn.parentPrdTxt = $self;
    parentTxtColl: Association to TxtColl;
}

@cds.persistence.exists
entity SAPScrptLn: cuid{
    OrdinalNumberValue: String;
    SAPScriptLineFormatCode: String;
    SAPScriptLineText: String;
    parentPrdTxt: Association to PrdTxt;
}


@cds.persistence.exists
entity StorageSpec: cuid{
    ProductStorageRequirementsCode: String;  
    ProductStorageTemperatureRangeCode: String;  
    HazardousMaterialID: String; 
    ProductLabelTypeCode: String; 
    ProductLabelFormCode: String;  
    MinimumRemainingShelfLifeCode: Decimal;
    NumberOfGoodsReceiptIssueSlipsToPrintValue: String; 
    ExpirationDateCode: String;
    ShelfLifeExpirationDatePeriod: String;  
    TotalShelfLifeStoragePercent: Decimal;
    StorageBinInstructionCode: String;  
    ShelfLifeExpirationDateRoundingRuleCode: String; 
    TotalShelfLife: Decimal;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity DistChainIndependentSalesSpec: cuid{
    TransportProductGroupCode: String;
    ProductSalesProcessUsabilityProfileCode: String;
    ProductSalesProcessUsabilityProfileValidityDate: Date;
    PricingReferenceProductID: String;  // Nullable field
    TaxClassificationID: String;  // Nullable field
    AllowedPackagingVolumeQuantity: String;  // Nullable field
    VolumeMaximumLevel: Decimal;
    StackingFactor: Decimal;
    ClosedPackagingProductIndicator: Boolean;
    ExcessWeightTolerance: Double;
    ExcessVolumeTolerance: Double;
    AllowedPackagingWeightQuantity: String;  // Nullable field
    ProductFreightGroupCode: String;  // Nullable field
    PackagingProductTypeCode: String;  // Nullable field
    VariantsPricingProfileCode: String;  // Nullable field
    IsVariantPriceAllowed: Boolean;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity PlantIndependentProcSpec: cuid{
    ManufacturerID: String;
    ProductManufacturerID: String;
    PurchasingAcknowledgmentProfileCode: String;
    OrderMeasureUnitCode: String;  // Nullable field
    VariablePurchaseOrderUnitOfMeasureActivationStatusCode: String;  // Nullable field
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity PrdSCMAdvPlan: cuid{
    RequiredMaximumShelfLife:String;
    MaturationTime:String;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity SalesSpec: cuid{
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
    PrdRetlPOS:Composition of many PrdRetlPOS on PrdRetlPOS.parentSalesSpec = $self;
    SalesSpecTxt:Composition of many SalesSpecTxt on SalesSpecTxt.parentSalesSpec = $self;
    SubscrPrdSalesData: Composition of many SubscrPrdSalesData on SubscrPrdSalesData.parentSalesSpec = $self;
    CommodityQtyForPrcng:Composition of many CommodityQtyForPrcng on CommodityQtyForPrcng.parentSalesSpec = $self;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity PrdRetlPOS: cuid{
    Plant: String;
    StoreSaleStartDate: Date;
    StoreSaleEndDate: Date;
    ProductSalesProcessUsabilityProfileCode: String;
    DistrChainSpcfcProdStsValidityDate: Date;
    IsPointOfSalesDiscountAllowed: Boolean;
    ScalesGroup: String;
    parentSalesSpec: Association to SalesSpec;
}

@cds.persistence.exists
entity SalesSpecTxt: cuid{
    TypeCode: String;
    LanguageCode: String;
    SalesSpecTxtSAPScrptLn: Composition of many SalesSpecTxtSAPScrptLn on SalesSpecTxtSAPScrptLn.parentSalesSpecTxt = $self;
    parentSalesSpec: Association to SalesSpec;
}

@cds.persistence.exists
entity SalesSpecTxtSAPScrptLn: cuid{
    OrdinalNumberValue: String;
    SAPScriptLineFormatCode: String;
    SAPScriptLineText: String;
    parentSalesSpecTxt: Association to SalesSpecTxt;
}

@cds.persistence.exists
entity SubscrPrdSalesData: cuid{
	DefaultContractTerm: Integer; // Nullable field
    AltContractTerm1: Integer; // Nullable field
    AltContractTerm2: Integer; // Nullable field
    ContractTermUnit: String; // Nullable field
    DefaultExtensionPeriod: Integer; // Nullable field
    AltExtensionPeriod1: Integer; // Nullable field
    AltExtensionPeriod2: Integer; // Nullable field
    ExtensionPeriodUnit: String; // Nullable field
    parentSalesSpec: Association to SalesSpec;
}

@cds.persistence.exists
entity CommodityQtyForPrcng: cuid{
    Commodity: String;
    CommodityQuantity: Double;
    ReferenceQuantity: Double;
    parentSalesSpec: Association to SalesSpec;
}

@cds.persistence.exists
entity SalesTaxClass: cuid{
    CountryCode: String;
    TaxTypeCode: String;
    TaxRateTypeCode: String;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity SubscrPrd: cuid{
    BillingCycle                        : String; // nullable
    BillingCycleDeterminationRuleId     : String; // nullable
    ContractAutoRenewalIndicator        : String; // nullable
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity SCMPrdGrps: cuid{
    ProductGroupType: String;
    ProductGroupValue: String;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity PrdBOM: cuid{
    BillOfMaterial: String;
    BillOfMaterialVariantUsageCode: String;
    BillOfMaterialVariantID: String;
    Plant: String;
    MeasureUnitCode: String;
    PrdBOMItm: Composition of many PrdBOMItm on PrdBOMItm.parentPrdBOM = $self;
    parent: Association to FASTCoreMaterial; 
}

@cds.persistence.exists
entity PrdBOMItm: cuid{
    BillOfMaterialComponent: String;
    BillOfMaterialItemCategory: String;
    BillOfMaterialItemQuantity: Double;
    parentPrdBOM: Association to PrdBOM;
}

@cds.persistence.exists
entity EWMWHS: cuid{
    EWMWarehouseNumber: String;
    EWMPartyEntitledToDispose: String;
    SupplyChainUnitUUID: String;
    EWMPartyEntitledToDisposeUUID: String;
    EWMProductProcessBlockProfile: String;
    EWMWarehouseProcessType: String;
    EWMProductLoadCategory: String;
    EWMPhysInventoryCountingCycle: String;
    RequiredMinShelfLife: String;
    EWMProdBackflushWthdrwlMethod: String;
    EWMKitQuantityCorrelation: String;
    EWMIsCnsmpnRlvtForValAddedSrvc: String;
    EWMQuantityAdjustmentProfile: String;
    EWMMrchdsDistrQtyClassfctn: String;
    EWMPreferredUnit: String;
    EWMQualityInspectionGroup: String;
    EWMPtwyControlStrategy: String;
    EWMStorageBinType: String;
    EWMBulkStorageMethod: String;
    EWMStorageSectionMethod: String;
    EWMStockRemovalControlStrategy: String;
    EWMStockDeterminationGroup: String;
    EWMProdTwoStepPickingRelevant: String;
    EWMStggAreaDeterminationGroup: String;
    EWMStrgeTyp: Composition of many EWMStrgeTyp on EWMStrgeTyp.parentEWMWHS = $self;
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity EWMStrgeTyp: cuid{
    EWMStorageTypeID: String;
    EWMStorageBinType: String;
    EWMStorageSectionMethod: String;
    EWMStorageBinSearchRule: String;
    EWMMaximumNumberOfBins: String;
    EWMSpltPtwyThresholdInPercent: Double;
    EWMPtwySequence: String;
    EWMProdQuantityClassification: String;
    EWMProdPtwyQtyClassification: String;
    EWMProdIsSplitOnPtwy: String;
    EWMProdIsSkippedOnPtwy: String;
    EWMHasNoReplenishment: String;
    EWMMinReplnmtQuantity: Double;
    EWMMinimumStorageQuantity: Double;
    EWMMaximumStorageQuantity: Double;
    EWMMinStorQtyOfMaxStorQtyInPct: Double;
    parentEWMWHS: Association to EWMWHS;
}

@cds.persistence.exists
entity eSPPPrd: cuid{
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
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity RetailArticle: cuid{
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
    parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity QtyConversion: cuid {
	Quantity: Double;
	CorrespondingQuantity: Double;
	parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity QtyCharacteristic: cuid{
	Quantity: Double;
	CharacteristicQuantity: Double;
	CharacteristicQuantityTypeCode: String;
    PrdRetlUoMTxts: Composition of many PrdRetlUoMTxts on PrdRetlUoMTxts.parentQtyCharacteristic = $self;
	parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity PrdRetlUoMTxts: cuid{
    ProductUoMDescription: String;
    ProductUnitTextSeqNum: String;
    parentQtyCharacteristic: Association to QtyCharacteristic;
}

@cds.persistence.exists
entity WHS: cuid {
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
    StrgeTyp: Composition of many StrgeTyp on StrgeTyp.parentWHS = $self;
	parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity StrgeTyp: cuid{
    WarehouseNumber: String;
    LeanWarehouseManagementPickingAreaCode: String;
    StorageBin: String;
    StorageType: String;
    ProductWarehouseMaximumStorageBinQuantity: Double;
    ProductWarehouseMinimumStorageBinQuantity: Double;
    DeletedIndicator: String;
    ProductWarehouseStorageTypeControlQuantity: Double;
    ProductWarehouseStorageTypeReplenishmentQuantity: Double;
    ProductWarehouseStorageTypeRoundingQuantity: Double;
    parentWHS: Association to WHS;
}

@cds.persistence.exists
entity ValuatnArea: cuid {
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
    ValuatnAcnt: Composition of many ValuatnAcnt on ValuatnAcnt.parentValuatnArea = $self;
    LedgerAcnt: Composition of many LedgerAcnt on LedgerAcnt.parentValuatnArea = $self;
    FuturePrce:Composition of many FuturePrce on FuturePrce.parentValuatnArea = $self;
    ValuatnCost: Composition of many ValuatnCost on ValuatnCost.parentValuatnArea = $self;
	parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity ValuatnAcnt: cuid{
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
    parentValuatnArea : Association to ValuatnArea;
}

@cds.persistence.exists
entity LedgerAcnt: cuid{
    CurrencyRoleCode                        : String;
	CurrencyCode                            : String;
	InventoryValuationProcedureCode         : String;
	PriceUnitNumberValue                    : String;
	PriceAmountValue                        : String; // nullable
    parentValuatnArea : Association to ValuatnArea;
}

@cds.persistence.exists
entity FuturePrce: cuid{
    CurrencyRoleCode                        : String;
	FuturePriceAmountValue                  : String; // nullable
	FuturePriceValidityStartDate            : String; // nullable
    parentValuatnArea : Association to ValuatnArea;
}

@cds.persistence.exists
entity ValuatnCost: cuid{
    MaterialCostedWithQuantityStructureIndicator: Boolean;
	MaterialRelatedOriginIndicator          : Boolean;
	CostOriginGroupCode                     : String; // nullable
	CostingOverheadGroupCode                : String; // nullable
	PlannedPrice                            : String; // nullable
    parentValuatnArea : Association to ValuatnArea;
}

@cds.persistence.exists
entity PrdPlant: cuid {
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
    PrdMinCntrlTempQty: String; // nullable
	PrdMaxCntrlTempQty: String; // nullable
	PrdCntrlTempUntCde: String; // nullable
	PlntCosting: Composition of many PlntCosting on PlntCosting.parentPrdPlant = $self;
	PlntSuplyPlan: Composition of many PlntSuplyPlan on PlntSuplyPlan.parentPrdPlant = $self;
    PlntMRPArea:Composition of many PlntMRPArea on PlntMRPArea.parentPrdPlant = $self;
	PlntSales: Composition of many PlntSales on PlntSales.parentPrdPlant = $self;
	QtyMgmt: Composition of many QtyMgmt on QtyMgmt.parentPrdPlant = $self;
    PrdPlntTxt: Composition of many PrdPlntTxt on PrdPlntTxt.parentPrdPlant = $self;
	Forcastng: Composition of many Forcastng on Forcastng.parentPrdPlant = $self;
	PrdMDMRplctReqPlntIntlTrade: Composition of many PrdMDMRplctReqPlntIntlTrade on PrdMDMRplctReqPlntIntlTrade.parentPrdPlant = $self;
	PlntStorage:Composition of many PlntStorage on PlntStorage.parentPrdPlant = $self;
	PlntStrageLoc:Composition of many PlntStrageLoc on PlntStrageLoc.parentPrdPlant = $self;
	PlntPurchasing:Composition of many PlntPurchasing on PlntPurchasing.parentPrdPlant = $self;
	PlntWrkSchedulng:Composition of many PlntWrkSchedulng on PlntWrkSchedulng.parentPrdPlant = $self;
	PlntSCMAdvPlan:Composition of many PlntSCMAdvPlan on PlntSCMAdvPlan.parentPrdPlant = $self;
	PlntPlanning:Composition of many PlntPlanning on PlntPlanning.parentPrdPlant = $self;
	ForcastParams:Composition of many ForcastParams on ForcastParams.parentPrdPlant = $self;
	PrdnResTool:Composition of many PrdnResTool on PrdnResTool.parentPrdPlant = $self;
	PlntSCMDmndPenlty:Composition of many PlntSCMDmndPenlty on PlntSCMDmndPenlty.parentPrdPlant = $self;
    PlntCmdtyQtyForPrcng:Composition of many PlntCmdtyQtyForPrcng on PlntCmdtyQtyForPrcng.parentPrdPlant = $self;
    EmbeddedCmdtyQty:Composition of many EmbeddedCmdtyQty on EmbeddedCmdtyQty.parentPrdPlant = $self;
	PlntSPPPrd:Composition of many PlntSPPPrd on PlntSPPPrd.parentPrdPlant = $self;
	PlnteSPPLocPrd:Composition of many PlnteSPPLocPrd on PlnteSPPLocPrd.parentPrdPlant = $self;
	parent: Association to FASTCoreMaterial;
}

@cds.persistence.exists
entity PlntCosting: cuid{
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
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlntSuplyPlan: cuid {
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
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlntMRPArea: cuid{
    MRPAreaID: String;
    ProductRequirementsPlanningTypeCode: String;
    ProductRequirementsPlanningResponsibleCode: String;
    LotSizeProcedureCode: String;
    FixedLotSizeQuantity:Double;
    MaximumLotSizeQuantity:Double;
    MinimumLotSizeQuantity:Double;
    LotSizeRoundingQuantity:Double;
    SafetyStockQuantity:Double;
    SafetyDaysOfSupplyDuration: String;
    MasterPlanAutomaticChangeRestrictedDuration: String;
    MaximumStockQuantity:Double;
    ReorderThresholdQuantity:Double;
    PlannedDeliveryDuration: String;
    ProcurementSubTypeCode: String;
    AssemblyProductScrapPercent:Double;
    ProcurementInventoryManagedLocationInternalID: String;
    ProductRequirementsPlanningGroupCode: String;
    ProductRequirementsPlanningStorageCostDeterminationProfileCode: String;
    PlanningCalendarCode: String;
    DynamicSafetyStockCalculationProfileCode: String;
    SafetyDaysOfSupplyRelevanceCode: String;
    SafetyDaysOfSupplyDurationProfileCode: String;
    MRPDependentRequirementCode: String;
    LotSizeOrderAmountValue:Double;
    LotSizeTaktTimeOffsetDuration: String;
    ServiceLevelPercent:Double;
    DeletedIndicator: String;
    PlannedDeliveryDurationIndicator: String;
    PlanAndOrderDayDeterminationCode: String;
    RoudingProfileCode: String;
    ProductionInventoryManagedLocationInternalID: String;
    MRPAreaSCMAdvancedPlanning: String;
    MRPAreaeSPP: String;
    eSPPLocProdMRP: String;
    parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlntSales: cuid {
    LoadingGroupCode                          : String; // LoadingGroupCode
    ReplacementPartTypeCode                   : String; // nullable
    WorkCentersShippingSetupDuration          : String; // nullable
    ProductShippingProcessingDuration         : String; // nullable
    CapacityPlanningQuantity                  : String; // CapacityPlanningQuantity (unitCode="KGM")
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity QtyMgmt: cuid {
    InspectionStockIndicator                        : String; // InspectionStockIndicator
    QualityManagementControlKeyCode                 : String; // nullable
    ProductQualityAuthorizationGroupCode             : String; // nullable
    ProductQualityCertificateTypeCode               : String; // nullable
    InspectionLotDocumentationRequiredIndicator     : String; // InspectionLotDocumentationRequiredIndicator
    RecurringInspectionIntervalDuration             : String; // RecurringInspectionIntervalDuration
    SupplierQualityManagementSystemCode             : String; // nullable
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PrdPlntTxt: cuid{
    PrdPlntTxtSAPScrptLn: Composition of many PrdPlntTxtSAPScrptLn on PrdPlntTxtSAPScrptLn.parentPrdPlntTxt = $self;
    parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PrdPlntTxtSAPScrptLn: cuid{
    OrdinalNumberValue: String;
    SAPScriptLineFormatCode: String;
    SAPScriptLineText: String;
    parentPrdPlntTxt: Association to PrdPlntTxt;
}

@cds.persistence.exists
entity Forcastng: cuid {
    ConsumptionReferenceUsageEndDate                : String; // nullable
    ConsumptionReferenceProductQuantityMultiplier   : String; // nullable
    ConsumptionReferenceProductID                   : String; // nullable
    ConsumptionReferencePlantID                     : String; // nullable
    FiscalYearVariantCode                           : String; // nullable
    ProductConsumptionPeriodTypeCode                : String; // ProductConsumptionPeriodTypeCode
    ForecastModelResetIndicator                     : String; // ForecastModelResetIndicator
    CorrectionFactorRequiredIndicator              : String; // CorrectionFactorRequiredIndicator
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PrdMDMRplctReqPlntIntlTrade: cuid {
    ProductOriginCountryCode                        : String; // nullable
    ProductOriginRegionCode                         : String; // nullable
    ConsumptionTaxControlCode                       : String; // nullable
    ExportAndImportProductGroupCode                 : String; // nullable
    ProductInternationalTradeClassificationNumber   : String; // nullable
    ProductCASNumber                                : String; // nullable
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlntStorage: cuid {
    PhysicalInventoryCycleCountingProfileCode      : String; // nullable
    WarehouseManagementPutawayAndStockRemovalStrategyCode : String; // nullable
    ProvisioningServiceLevelCode                   : String; // nullable
    ProductMaximumStoragePeriodUnitCode            : String; // nullable
    MaximumStoragePeriodDuration                   : String; // MaximumStoragePeriodDuration
    CycleCountingCategoryIsFixedIndicator          : String; // CycleCountingCategoryIsFixedIndicator
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlntStrageLoc: cuid {
    StorageLocationID                       : String; // StorageLocationID
    StorageBinID                            : String; // nullable
    DeletedIndicator                        : String; // DeletedIndicator
    LeanWarehouseManagementPickingAreaCode  : String; // nullable
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlntPurchasing: cuid {
    AutomaticPurchaseOrderAllowedIndicator        : String; // AutomaticPurchaseOrderAllowedIndicator
    SourceListRequirementIndicator                : String; // SourceListRequirementIndicator
    PurchasingGroupID                             : String; // PurchasingGroupID
    SourceOfSupplyCategoryCode                    : String; // nullable
    PurchasingAcrossPurchasingGroupIndicator      : String; // PurchasingAcrossPurchasingGroupIndicator
    JITDeliverySchedulesRelevantIndicator         : String; // JITDeliverySchedulesRelevantIndicator
    TaxIndicator                                  : String; // nullable
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlntWrkSchedulng: cuid {
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
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlntSCMAdvPlan: cuid {
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
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlntPlanning: cuid {
    PlanningMaterialID                              : String; // nullable
    PlanningPlantID                                 : String; // nullable
    ProductPlantPlanningMaterialConversionFactor    : String; // nullable
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity ForcastParams: cuid {
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
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PrdnResTool: cuid {
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
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlntSCMDmndPenlty: cuid {
    DemandType                    : String;
    DelayPenaltyAmount                : Double;
    MaximumDelayInDays                : String;
    NonDeliveryPenaltyAmount          : Double;
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlntCmdtyQtyForPrcng: cuid{
    Commodity: String;
    CommodityQuantity: Double;
    ReferenceQuantity: Double;
    parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity EmbeddedCmdtyQty: cuid{
    Commodity: String;
    CommodityQuantity: Double;
    ReferenceQuantity: Double;
    parentPrdPlant: Association to PrdPlant; 
}

@cds.persistence.exists
entity PlntSPPPrd: cuid {
    ESPPIsUsed                              : String; // nullable
    ProductAlertRelevanceCode               : String; // nullable
    LocProdGoodsReceiptProcHours            : String;
    LocProdGoodsIssueProcHours              : String;
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
    SrvcPartsThroughputTimeDurn            : String;
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity PlnteSPPLocPrd: cuid {
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
	parentPrdPlant: Association to PrdPlant;
}

@cds.persistence.exists
entity FASTCoreCustomerMaster: cuid, managed{
    UUID: UUID;
	InternalID: String; 
    ReceiverUUID: String;
    ReceiverInternalID: String;
    CategoryCode: String; 
    ExternalID: String;
    NumberRangeIntervalBusinessPartnerGroupCode: String;
    CustData: Composition of many CustData on CustData.parent = $self;
    SupplierData: Composition of many SupplierData on SupplierData.parent = $self;
    MultipleAssignment: Composition of many MultipleAssignment on MultipleAssignment.parent = $self;
	AddrnfoData: Composition of many AddrnfoData on AddrnfoData.parent = $self;
	AddrIndepndntCommInfo: Composition of many AddrIndepndntCommInfo on AddrIndepndntCommInfo.parent = $self;
    BankDetails: Composition of many BankDetails on BankDetails.parent = $self;
    PaymentCardDetails: Composition of many PaymentCardDetails on PaymentCardDetails.parent = $self;
	CommonInfo: Composition of many CommonInfo on CommonInfo.parent = $self;
	RoleInfo: Composition of many RoleInfo on RoleInfo.parent = $self;
    Identification: Composition of many Identification on Identification.parent = $self;
    IndSector: Composition of many IndSector on IndSector.parent = $self;
	TaxNum: Composition of many TaxNum on TaxNum.parent = $self;
    AddrDepTaxNum: Composition of many AddrDepTaxNum on AddrDepTaxNum.parent = $self;
	FinServComm: Composition of many FinServComm on FinServComm.parent = $self;
    Employment: Composition of many Employment on Employment.parent = $self;
    Rating:Composition of many Rating on Rating.parent = $self;
    CreditWorthiness:Composition of many CreditWorthiness on CreditWorthiness.parent = $self;
    FiscalYear:Composition of many FiscalYear on FiscalYear.parent = $self;
    FinancialServicesReporting:Composition of many FinancialServicesReporting on FinancialServicesReporting.parent = $self;
    TaxCompliance:Composition of many TaxCompliance on TaxCompliance.parent = $self;
    PartnerIsBank:Composition of many PartnerIsBank on PartnerIsBank.parent = $self;
    Alias:Composition of many Alias on Alias.parent = $self;
    FinancialServicesCompanyCodeInformation:Composition of many FinancialServicesCompanyCodeInformation on FinancialServicesCompanyCodeInformation.parent = $self;
    FinancialServicesControlData:Composition of many FinancialServicesControlData on FinancialServicesControlData.parent = $self;
    CreditManagementCustomInformation:Composition of many CreditManagementCustomInformation on CreditManagementCustomInformation.parent = $self;
	CredMgmtProf: Composition of many CredMgmtProf on CredMgmtProf.parent = $self;
    CreditManagementExternalCreditInformation:Composition of many CreditManagementExternalCreditInformation on CreditManagementExternalCreditInformation.parent = $self;
	CredMgmtCredWorth: Composition of many CredMgmtCredWorth on CredMgmtCredWorth.parent = $self;
    DataController:Composition of many DataController on DataController.parent = $self;
    Document:Composition of many Document on Document.parent = $self;
}

@cds.persistence.exists
entity CustData: cuid{
    InternalID: String;
    ReceiverInternalID: String;
    MaintenanceProfileCode: String;
    AuthorisationGroupCode: String;
    ExpressTrainStationLocationName: String;
    TrainStationLocationName: String;
    CustomerPartyWithFiscalAddressInternalID: String;
    ReceiverCustomerPartyWithFiscalAddressInternalID: String;
    AlternativePayeePartyInternalID: String;
    ReceiverAlternativePayeePartyInternalID: String;
    AlternativePayeeAllowedIndicator: Boolean;
    CorporateGroupName: String;
    StandardPointLocationCode: String;
    DeletionBlockedIndicator: Boolean;
    DeletedIndicator: Boolean;
    CountyCode: String;
    CityCode: String;
    PostingBlockedIndicator: Boolean;
    EqualizationTaxRelevanceIndicator: Boolean;
    ValueAddedTaxRelevanceIndicator: Boolean;
    TradingPartnerCompanyID: String;
    TaxGroupCode: String;
    ICMSExemptionIndicator: Boolean;
    IPIExemptionIndicator: Boolean;
    TaxSubstitutionGroupCode: String;
    CFOPCategoryCode: String;
    CustomerExtensionCode: String;
    FirstAdditionalCustomerExtensionCode: String;
    SecondAdditionalCustomerExtensionCode: String;
    ThirdAdditionalCustomerExtensionCode: String;
    FourthAdditionalCustomerExtensionCode: String;
    FifthAdditionalCustomerExtensionCode: String;
    SixthAdditionalCustomerExtensionCode: String;
    SeventhAdditionalCustomerExtensionCode: String;
    EighthAdditionalCustomerExtensionCode: String;
    NinthAdditionalCustomerExtensionCode: String;
    DataMediumExchangeReportCode: String;
    DataMediumExchangeInstructionCode: String;
    CivilUseIndicator: Boolean;
    MilitaryUseIndicator: Boolean;
    RepresentativeName: String;
    BusinessTypeName: String;
    IndustryTypeName: String;
    RelatedSupplierInternalID: String;
    ReceiverRelatedSupplierInternalID: String;
    PaymentReasonCode: String;
    PermittedPayer :Composition of many PermittedPayer on PermittedPayer.parentCustData = $self;
    CustLegalCtrlIndicator: Composition of many CustLegalCtrlIndicator on CustLegalCtrlIndicator.parentCustData = $self;
    CustPriceSpecs: Composition of many CustPriceSpecs on CustPriceSpecs.parentCustData = $self;
    CustSalesDistrbtnBlocks:Composition of many CustSalesDistrbtnBlocks on CustSalesDistrbtnBlocks.parentCustData = $self;
    CustIndSec:Composition of many CustIndSec on CustIndSec.parentCustData = $self;
    CustMktgAttrs: Composition of many CustMktgAttrs on CustMktgAttrs.parentCustData = $self;
    CustAcctInfo: Composition of many CustAcctInfo on CustAcctInfo.parentCustData = $self;
    CustSalesArrgmnt: Composition of many CustSalesArrgmnt on CustSalesArrgmnt.parentCustData = $self;
    UnldgPoints: Composition of many UnldgPoints on UnldgPoints.parentCustData = $self;
    AddrDepdntUnldgPoints:Composition of many AddrDepdntUnldgPoints on AddrDepdntUnldgPoints.parentCustData = $self;
    CustTaxClass: Composition of many CustTaxClass on CustTaxClass.parentCustData = $self;
    AddrDepdntTaxClass: Composition of many AddrDepdntTaxClass on AddrDepdntTaxClass.parentCustData = $self;
    TaxGroupng: Composition of many TaxGroupng on TaxGroupng.parentCustData = $self;
    CustText: Composition of many CustText on CustText.parentCustData = $self;
    CustDoc: Composition of many CustDoc on CustDoc.parentCustData = $self;
    ProptyList: Composition of many ProptyList on ProptyList.parentCustData = $self;
    ProptyValuatn: Composition of many ProptyValuatn on ProptyValuatn.parentCustData = $self;
    AddrDepdntCustInfo: Composition of many AddrDepdntCustInfo on AddrDepdntCustInfo.parentCustData = $self;
    AddrDepdntExtRef: Composition of many AddrDepdntExtRef on AddrDepdntExtRef.parentCustData = $self;
    parentMultipleAssignment: Association to MultipleAssignment;
    parent:Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity CustSalesDistrbtnBlocks: cuid{
    OrderBlockingReasonCode                        : String; 
    BillingBlockingReasonCode                      : String; 
    DeliveryBlockingReasonCode                     : String; 
    SalesSupportBlockedIndicator                   : Boolean;
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity CustIndSec: cuid{
    IndustrialSectorCode                           : String; 
    FirstAdditionalIndustrialSectorCode            : String; 
    SecondAdditionalIndustrialSectorCode           : String; 
    ThirdAdditionalIndustrialSectorCode            : String; 
    FourthAdditionalIndustrialSectorCode           : String; 
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity CustMktgAttrs: cuid{
    CustomerGroupCode                              : String; 
    CustomerNielsenRegionCode                      : String; 
    FiscalYearVariantCode                          : String;  
    AnnualSalesVolumeAmount                        : Decimal; 
    AnnualSalesVolumeAmountReportedYear            : String;   
    EmployeeNumberValue                            : Integer;   
    EmployeeNumberValueReportedYear                : String; 
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity CustLegalCtrlIndicator: cuid{
    BiochemicalWarfareIndicator                    : Boolean;
    NuclearNonproliferationIndicator               : Boolean;
    NationalSecurityIndicator                      : Boolean;
    MissileTechnologyIndicator                     : Boolean;
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity CustPriceSpecs: cuid{
    CustomerConditionGroupCode                     : String; 
    FirstAdditionalCustomerConditionGroupCode      : String; 
    SecondAdditionalCustomerConditionGroupCode     : String; 
    ThirdAdditionalCustomerConditionGroupCode      : String; 
    FourthAdditionalCustomerConditionGroupCode     : String; 
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity CustAcctInfo: cuid{
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
    InsuranceLeadDuration                      : String;
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
    ProbableCheckPaidDuration                  : String;
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
    DunnInfo: Composition of many DunnInfo on DunnInfo.parentCustAcctInfo = $self;
    CustWithTax: Composition of many CustWithTax on CustWithTax.parentCustAcctInfo = $self;
    AccountingTxt: Composition of many AccountingTxt on AccountingTxt.parentCustAcctInfo = $self;
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity DunnInfo: cuid{
    DunningAreaID: String;
    DunningProcedureCode: String;
    DunningBlockCode: String;
    LastDunningNoticeDate: Date;
    DunningLevelCode: String;
    DunningRecipientID: String;
    ReceiverDunningRecipientID: String;
    LegalDunningProceedingsDate: Date;
    DunningClerkInitialsCode: String;
    parentCustAcctInfo: Association to CustAcctInfo;
    parentAcctInfo: Association to AcctInfo;
}

@cds.persistence.exists
entity CustWithTax: cuid{
    WithholdingTaxTypeCode                     : String;
    WithholdingTaxIdentificationNumber         : String;
    WithholdingTaxCode                         : String;
    WithholdingTaxAgentIndicator: String;
    WithholdingTaxObligationPeriod: String;
    WithholdingTaxExemptionCertificateID       : String;
    WithholdingTaxExemptionRate                : Double;
    WithholdingTaxExemptionReasonCode           : String;
    CustWithTaxExmValPeriod : Composition of many CustWithTaxExmValPeriod on CustWithTaxExmValPeriod.parentCustWithTax = $self;
    parentCustAcctInfo: Association to CustAcctInfo;
}

@cds.persistence.exists
entity CustWithTaxExmValPeriod: cuid{
    StartDate                                 : Date;
    EndDate                                   : Date;
    parentCustWithTax: Association to CustWithTax;
}

@cds.persistence.exists
entity AccountingTxt: cuid{
    TextTypeCode: String;
    LanguageCode: String;
    TxtSAPScrptLn: Composition of many TxtSAPScrptLn on TxtSAPScrptLn.parentAccountingTxt = $self;
    parentAcctInfo: Association to AcctInfo;
    parentCustAcctInfo: Association to CustAcctInfo;
}

@cds.persistence.exists
entity TxtSAPScrptLn: cuid{
    OrdinalNumberValue: String;
    SAPScriptLineFormatCode: String;
    SAPScriptLineText: String;
    parentAccountingTxt: Association to AccountingTxt;
    parentSalesArrgmntTxt: Association to SalesArrgmntTxt;
    parentCustText: Association to CustText;
    parentPurchasingText: Association to PurchasingText;
    parentSupplierText: Association to SupplierText;
}

@cds.persistence.exists
entity CustSalesArrgmnt: cuid{
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
    PODConfirmationTimeframeDuration          : String;
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
    CustDelvryTerms: Composition of many CustDelvryTerms on CustDelvryTerms.parentCustSalesArrgmnt = $self;
    CustPartnrFuncs : Composition of many CustPartnrFuncs on CustPartnrFuncs.parentCustSalesArrgmnt = $self;
    SalesArrgmntTxt: Composition of many SalesArrgmntTxt on SalesArrgmntTxt.parentCustSalesArrgmnt = $self;
    AddrDepdntSalesArrgmnt: Composition of many AddrDepdntSalesArrgmnt on AddrDepdntSalesArrgmnt.parentCustSalesArrgmnt = $self;
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity CustDelvryTerms: cuid{
    DeliveryPriorityCode                      : String;
    SalesOrderCompleteDeliveryIndicator       : Boolean;
    OrderCombinationAllowedIndicator          : Boolean;
    PartialDeliveryControlCode                : String;
    PartialDeliveryMaximumNumberValue         : Integer;
    CusIncoTerm: Composition of many CusIncoTerm on CusIncoTerm.parentCustDelvryTerms = $self;
    CustQtyTolerance: Composition of many CustQtyTolerance on CustQtyTolerance.parentCustDelvryTerms = $self;
    parentCustSalesArrgmnt: Association to CustSalesArrgmnt;
}

@cds.persistence.exists
entity CusIncoTerm: cuid{
    ClassificationCode                      : String;
    TransferLocationName                    : String;
    TransferLocationNameLong                : String;
    TransferLocationInternalID              : String;
    DestinationLocationName                 : String;
    DestinationLocationInternalID           : String;
    DeviatingDestinationLocationInternalID  : String;
    Version                                 : String;
    parentCustDelvryTerms: Association to CustDelvryTerms;
    parentAddrDepdntDeliveryTerms: Association to AddrDepdntDeliveryTerms;
}

@cds.persistence.exists
entity CustQtyTolerance: cuid{
    OverPercent                              : Double;
    OverPercentUnlimitedIndicator            : Boolean;
    UnderPercent                             : Double;
    parentCustDelvryTerms: Association to CustDelvryTerms;
}

@cds.persistence.exists
entity CustPartnrFuncs: cuid{
    PartyRoleCode                        : String;
    PartyInternalID                          : String;
    ReceiverPartyInternalID                  : String;
    DefaultIndicator                         : Boolean;
    PartnerDescription: String;
    AddrKey : Composition of many AddrKey on AddrKey.parentCustPartnrFuncs = $self;
    parentCustSalesArrgmnt: Association to CustSalesArrgmnt;
} 

@cds.persistence.exists
entity AddrKey: cuid{
    ReceiverUUID: UUID;
    UUID: UUID;
    ExternalAddressID: String;
    parentCustPartnrFuncs: Association to CustPartnrFuncs;
    parentAddrDepdntSalesArrgmnt: Association to AddrDepdntSalesArrgmnt;
    parentAddrDepdntUnldgPoints: Association to AddrDepdntUnldgPoints;
    parentAddrDepdntTaxClass: Association to AddrDepdntTaxClass;
    parentAddrDepdntCustInfo: Association to AddrDepdntCustInfo;
    parentAddrDepdntExtRef: Association to AddrDepdntExtRef;
    parentAddrDepTaxNum: Association to AddrDepTaxNum;
}

@cds.persistence.exists
entity SalesArrgmntTxt: cuid{
    TextTypeCode: String;
    LanguageCode: String;
    TxtSAPScrptLn: Composition of many TxtSAPScrptLn on TxtSAPScrptLn.parentSalesArrgmntTxt = $self;
    parentCustSalesArrgmnt: Association to CustSalesArrgmnt;
} 

@cds.persistence.exists
entity AddrDepdntSalesArrgmnt: cuid{
    DeliveryBlockingReasonCode: String;
    TransportServiceLevelCode: String;
    DeliveringPlantID: String;
    SalesGroupCode: String;
    SalesOfficeCode: String;
    AddrKey: Composition of many AddrKey on AddrKey.parentAddrDepdntSalesArrgmnt = $self;
    AddrDepdntDeliveryTerms: Composition of many AddrDepdntDeliveryTerms on AddrDepdntDeliveryTerms.parentAddrDepdntSalesArrgmnt = $self;
    parentCustSalesArrgmnt: Association to CustSalesArrgmnt;
} 

@cds.persistence.exists
entity AddrDepdntDeliveryTerms: cuid{
    CusIncoTerm: Composition of many CusIncoTerm on CusIncoTerm.parentAddrDepdntDeliveryTerms = $self;
    parentAddrDepdntSalesArrgmnt: Association to AddrDepdntSalesArrgmnt;
}

@cds.persistence.exists
entity UnldgPoints: cuid{
    UnloadingPointName: String;
    GoodsReceivingHoursID: String;
    DefaultIndicator: Boolean;
    BizHours: Composition of many BizHours on BizHours.parentUnldgPoints = $self;
    parentCustData: Association to CustData;
} 

@cds.persistence.exists
entity BizHours: cuid{
    FactoryCalenderCode: String;
    TimeZoneCode: String;
    MondayAMStartTime: String;
    MondayAMEndTime: String;
    MondayPMStartTime: String;
    MondayPMEndTime: String;
    TuesdayAMStartTime: String;
    TuesdayAMEndTime: String;
    TuesdayPMStartTime: String;
    TuesdayPMEndTime: String;
    WednesdayAMStartTime: String;
    WednesdayAMEndTime: String;
    WednesdayPMStartTime: String;
    WednesdayPMEndTime: String;
    ThursdayAMStartTime: String;
    ThursdayAMEndTime: String;
    ThursdayPMStartTime: String;
    ThursdayPMEndTime: String;
    FridayAMStartTime: String;
    FridayAMEndTime: String;
    FridayPMStartTime: String;
    FridayPMEndTime: String;
    SaturdayAMStartTime: String;
    SaturdayAMEndTime: String;
    SaturdayPMStartTime: String;
    SaturdayPMEndTime: String;
    SundayAMStartTime: String;
    SundayAMEndTime: String;
    SundayPMStartTime: String;
    SundayPMEndTime: String;
    parentUnldgPoints: Association to UnldgPoints;
    parentAddrDepdntUnldgPoints: Association to AddrDepdntUnldgPoints;
}

@cds.persistence.exists
entity AddrDepdntUnldgPoints: cuid{
    UnloadingPointName: String;
    GoodsReceivingHoursID: String;
    DefaultIndicator: String;
    AddrKey: Composition of many AddrKey on AddrKey.parentAddrDepdntUnldgPoints = $self;
    BizHours: Composition of many BizHours on BizHours.parentAddrDepdntUnldgPoints = $self;
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity CustTaxClass: cuid{
    TaxCountryCode                           : String;
    TaxTypeCode                              : String;
    TaxGroupCode                             : String;
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity AddrDepdntTaxClass: cuid{
    TaxCountryCode: String;
    TaxTypeCode: String;
    TaxGroupCode: String;
    AddrKey: Composition of many AddrKey on AddrKey.parentAddrDepdntTaxClass = $self;
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity TaxGroupng: cuid{
    TaxCodeCategoryIndicator: Boolean;
    CusValdtyPeriod: Composition of many CusValdtyPeriod on CusValdtyPeriod.parentTaxGroupng = $self;
    TaxExmptn: Composition of many TaxExmptn on TaxExmptn.parentTaxGroupng = $self;
    parentCustData: Association to CustData;
    parentSupplierData: Association to SupplierData;
}

@cds.persistence.exists
entity TaxExmptn: cuid{
    CertificateID: String;
    Percent: Double;
    CusValdtyPeriod: Composition of many CusValdtyPeriod on CusValdtyPeriod.parentTaxExmptn = $self;
    parentTaxGroupng: Association to TaxGroupng;
}

@cds.persistence.exists
entity CusValdtyPeriod: cuid{
    StartDate                                 : Date;
    EndDate                                   : Date;
    parentTaxGroupng: Association to TaxGroupng;
    parentTaxExmptn: Association to TaxExmptn;
}

@cds.persistence.exists
entity CustText: cuid{
    TextTypeCode: String;
    LanguageCode: String;
    TxtSAPScrptLn: Composition of many TxtSAPScrptLn on TxtSAPScrptLn.parentCustText = $self;
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity CustDoc: cuid{
    DocumentTypeCode: String;
    DocumentID: String;
    AlternativeDocumentID: String;
    DocumentVersionID: String;
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity ProptyList: cuid{
    ID: String;
    TypeCode: String;
    DefaultIndicator: Boolean;
    AssignmentStatusCode: String;
    parentCustData: Association to CustData;
    parentSupplierData: Association to SupplierData;
}

@cds.persistence.exists
entity ProptyValuatn: cuid{
    PropertyID: String;
    PropertyListTypeCode: String;
    PropVal: Composition of many PropVal on PropVal.parentProptyValuatn = $self;
    parentCustData: Association to CustData;
    parentSupplierData: Association to SupplierData;
}

@cds.persistence.exists
entity PropVal: cuid{
    IntervalBoundaryTypeCode: String;
    LowrBoundryObjPropertyVal: Composition of many LowrBoundryObjPropertyVal on LowrBoundryObjPropertyVal.parentPropVal = $self;
    UpprBoundryObjPropertyVal: Composition of many UpprBoundryObjPropertyVal on UpprBoundryObjPropertyVal.parentPropVal = $self;
    parentProptyValuatn: Association to ProptyValuatn;
}

@cds.persistence.exists
entity LowrBoundryObjPropertyVal: cuid{
    Amount: Double;
    Quantity: Double;
    DecimalValue: Decimal;
    FloatValue: Double;
    IntegerValue: Integer;
    Date: Date;
    Time: String;
    DateTime: DateTime;
    Name: String;
    Indicator: Boolean;
    Measure: String;
    Code: String;
    Identifier: String;
    URI: String;
    BinaryObject: String;
    Duration: String;
    Percent: Double;
    Ratio: String;
    Text: String;
    parentPropVal:  Association to PropVal;
}

@cds.persistence.exists
entity UpprBoundryObjPropertyVal: cuid{
    Amount: Double; 
    Quantity: Double;  
    DecimalValue: Decimal;  
    FloatValue: Double;  
    IntegerValue: Integer;  
    Date: Date;
    Time: String;  
    DateTime: DateTime;  
    Measure: String;  
    Duration: String;  
    Percent: Double;  
    Ratio: String;
    parentPropVal:  Association to PropVal;
}

@cds.persistence.exists
entity AddrDepdntCustInfo: cuid{
    ExpressTrainStationLocationName: String;
    TrainStationLocationName: String;
    CountyCode: String;
    CityCode: String;
    AddrKey: Composition of many AddrKey on AddrKey.parentAddrDepdntCustInfo = $self;
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity AddrDepdntExtRef: cuid{
    ExternalReferenceID: String;
    AddrKey: Composition of many AddrKey on AddrKey.parentAddrDepdntExtRef = $self;
    parentCustData: Association to CustData;
}

@cds.persistence.exists
entity SupplierData: cuid {  
    InternalID                              : String;
    ReceiverInternalID                      : String;
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
    ReceiverAlternativePayeePartyInternalID             : String;
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
    StagingDuration                             : String;
    SchedulingProcedureCode                     : String;
    TransportationChainCode                     : String;
    AcceptanceAtOriginIndicator                 : Boolean;
    PaymentReasonCode                           : String;
    PermittedPayer :Composition of many PermittedPayer on PermittedPayer.parentSupplierData = $self;
    AcctInfo : Composition of many AcctInfo on AcctInfo.parentSupplierData = $self;
    BiddingCharacteristic: Composition of many BiddingCharacteristic on BiddingCharacteristic.parentSupplierData = $self;
    ProcurementCardIssuingInstitutes: Composition of many ProcurementCardIssuingInstitutes on ProcurementCardIssuingInstitutes.parentSupplierData = $self;
    QultyMgmt: Composition of many QultyMgmt on QultyMgmt.parentSupplierData = $self;
    ProcuremntArrgmnt : Composition of many ProcuremntArrgmnt on ProcuremntArrgmnt.parentSupplierData = $self;
    SubRange: Composition of many SubRange on SubRange.parentSupplierData = $self;
    TaxGroupng: Composition of many TaxGroupng on TaxGroupng.parentSupplierData = $self;
    SupplierText: Composition of many SupplierText on SupplierText.parentSupplierData = $self;
    SupplierDocument: Composition of many SupplierDocument on SupplierDocument.parentSupplierData = $self;
    ProptyList: Composition of many ProptyList on ProptyList.parentSupplierData = $self;
    ProptyValuatn: Composition of many ProptyValuatn on ProptyValuatn.parentSupplierData = $self;
    parentMultipleAssignment: Association to MultipleAssignment;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity MultipleAssignment: cuid{
    AssignmentCategoryCode: String;
    ObjectID: String;
    AssignmentReasonCode: String;
    DefaultIndicator: Boolean;
    AddressReceiverUUID: String;
    AddressUUID: String;
    CustData: Composition of many CustData on CustData.parentMultipleAssignment = $self;
    SupplierData: Composition of many SupplierData on SupplierData.parentMultipleAssignment = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity SupplierDocument: cuid{
    DocumentTypeCode: String;
    DocumentID: String;
    AlternativeDocumentID: String;
    DocumentVersionID: String;
    parentSupplierData: Association to SupplierData;
}
@cds.persistence.exists
entity SupplierText: cuid{
    TextTypeCode: String;
    LanguageCode: String;
    TxtSAPScrptLn: Composition of many TxtSAPScrptLn on TxtSAPScrptLn.parentSupplierText = $self;
    parentSupplierData: Association to SupplierData;
}

@cds.persistence.exists
entity SubRange: cuid{
    VendorSubrangeCode: String;
    SubrangeDescription: String;
    parentSupplierData: Association to SupplierData;
}
@cds.persistence.exists
entity QultyMgmt: cuid{
    SystemStandardCode: String;
    SystemStandardCodeExpirationDate: Date;
    DefaultIndicator: String;
    parentSupplierData: Association to SupplierData;
}

@cds.persistence.exists
entity ProcurementCardIssuingInstitutes: cuid{
    PaymentCardIssuerPartyInternalID: String;
    parentSupplierData: Association to SupplierData;
}
@cds.persistence.exists
entity BiddingCharacteristic: cuid{
    MinorityOwnedIndicator: String;
    MinorityOwnedCertificateExpirationDate: Date;
    WomenOwnedIndicator: String;
    WomenOwnedCertificateExpirationDate: Date;
    SurrogateBiddingAllowedIndicator: String;
    OfflineBiddingIndicator: String;
    parentSupplierData: Association to SupplierData;
}

@cds.persistence.exists
entity PermittedPayer: cuid{
    InternalID                              : String;
    ReceiverInternalID                      : String;
    parentCustData: Association to CustData;
    parentSupplierData: Association to SupplierData;
    parentAcctInfo: Association to AcctInfo;
}

@cds.persistence.exists
entity ProcuremntArrgmnt: cuid {
    ReceiverPurchasingOrganisationID    : String;
    ReceiverOrganisationalCentreID: String;
    PurchasingOrganisationID                : String;
    OrganisationalCentreID: String;
    VendorSubrangeCode: String;
    SupplyingPlantID: String;
    PurchasingGroupID                           : String;
    DeletedIndicator                            : Boolean;
    MRPControllerCode: String;
    SupplierABCClassificationCode               : String;
    SellerPartyContactPersonName                : String;
    ActivityProfileCode                         : String;
    TransportationChainCode                     : String;
    StagingDuration                             : String;
    ValueAddedServiceDeterminationModeCode      : String;
    CharacteristicValueConversionCode           : String;
    AcceptanceAtOriginIndicator: Boolean;
    ReturnsSupplierIndicator                    : Boolean;
    PurchsngTerm : Composition of many PurchsngTerm on PurchsngTerm.parentProcuremntArrgmnt = $self;
    PartnrFuncs : Composition of many PartnrFuncs on PartnrFuncs.parentProcuremntArrgmnt = $self;
    PurchasingText: Composition of many PurchasingText on PurchasingText.parentProcuremntArrgmnt = $self;
    parentSupplierData: Association to SupplierData;
}

@cds.persistence.exists
entity PurchasingText:cuid{
    TextTypeCode: String;
    LanguageCode: String;
    TxtSAPScrptLn: Composition of many TxtSAPScrptLn on TxtSAPScrptLn.parentPurchasingText = $self;
    parentProcuremntArrgmnt: Association to ProcuremntArrgmnt;
}

@cds.persistence.exists
entity PurchsngTerm: cuid {
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
    PlannedDeliveryDuration                     : String;
    SalesVolumeFulfillmentPercent               : Double;
    PurchaseOrderConfirmationRequirementCode    : String;
    Inncoterms: Composition of many Inncoterms on Inncoterms.parentPurchsngTerm = $self;
    parentProcuremntArrgmnt: Association to ProcuremntArrgmnt;
}

@cds.persistence.exists
entity AcctInfo: cuid {
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
    InsuranceLeadDuration                      : String;
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
    ProbableCheckPaidDuration                  : String;
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
    PermittedPayer :Composition of many PermittedPayer on PermittedPayer.parentAcctInfo = $self;
    DunnInfo: Composition of many DunnInfo on DunnInfo.parentAcctInfo = $self;
    AccountingTxt: Composition of many AccountingTxt on AccountingTxt.parentAcctInfo = $self;
    WithTax: Composition of many WithTax on WithTax.parentAcctInfo = $self;
    parentSupplierData: Association to SupplierData;
}

@cds.persistence.exists
entity WithTax: cuid {
    WithholdingTaxTypeCode                     : String;
    SubjectToWithholdingTaxIndicator           : Boolean;
    VendorRecipientTypeCode                    : String;
    WithholdingTaxIdentificationNumber         : String;
    WithholdingTaxCode                         : String;
    WithholdingTaxExemptionCertificateID       : String;
    WithholdingTaxExemptionRate                : Double;
    WithTaxExmValPeriod : Composition of many WithTaxExmValPeriod on WithTaxExmValPeriod.parentWithTax = $self;
    parentAcctInfo: Association to AcctInfo;
}

@cds.persistence.exists
entity WithTaxExmValPeriod: cuid{
    StartDate                                 : Date;
    EndDate                                   : Date;
    parentWithTax: Association to WithTax;
}

@cds.persistence.exists
entity PartnrFuncs: cuid {
    PartyRoleCode                        : String;
    PartyInternalID                          : String;
    ReceiverPartyInternalID                  : String;
    DefaultIndicator                         : Boolean;
    parentProcuremntArrgmnt: Association to ProcuremntArrgmnt;
}

@cds.persistence.exists
entity Inncoterms: cuid{
    ClassificationCode                      : String;
    TransferLocationName                    : String;
    TransferLocationNameLong                : String;
    TransferLocationInternalID              : String;
    DestinationLocationName                 : String;
    DestinationLocationInternalID           : String;
    DeviatingDestinationLocationInternalID  : String;
    Version                                 : String;
    parentPurchsngTerm: Association to PurchsngTerm;
}

@cds.persistence.exists
entity AddrnfoData: cuid {
    ReceiverUUID: String;
    UUID                                       : String;
    ExternalAddressID: String;
    MoveDestinationAddressReceiverUUID  : String;
    MoveDestinationAddressUUID                     : String;
    MoveDate                                       : Date;
    ValdtyPerd: Composition of many ValdtyPerd on ValdtyPerd.parentAddrnfoData = $self;
    AddrUsg : Composition of many AddrUsg on AddrUsg.parentAddrnfoData = $self;
    Addr: Composition of many Addr on Addr.parentAddrnfoData = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity ValdtyPerd : cuid {
    StartDate                                  : Date;
    EndDate                                    : Date;
    parentAddrnfoData: Association to AddrnfoData;
    parentAddrUsg: Association to AddrUsg;
    parentRoleInfo: Association to RoleInfo;
    parentEmail: Association to Email;
    parentUsage: Association to Usage;
    parentFacsimile: Association to Facsimile;
    parentTelephone: Association to Telephone;
    parentWeb: Association to Web;
    parentBankDetails: Association to BankDetails;
    parentBlock: Association to Block;
    parentCommonInfo: Association to CommonInfo;
    parentIdentification: Association to Identification;
    parentRating: Association to Rating;
    parentTaxCompliance: Association to TaxCompliance;
    parentCreditManagementCustomInformation: Association to CreditManagementCustomInformation;
    parentCreditManagementExternalCreditInformation: Association to CreditManagementExternalCreditInformation;
}

@cds.persistence.exists
entity AddrUsg : cuid {
    AddressUsageCode: String;
    DefaultIndicator: Boolean;
    ValdtyPerd : Composition of many ValdtyPerd on ValdtyPerd.parentAddrUsg = $self;
    parentAddrnfoData: Association to AddrnfoData;
}

@cds.persistence.exists
entity Addr : cuid {
    LocationStandardID: String;
    AddressNote: Composition of many AddressNote on AddressNote.parentAddr = $self;
    CommunicatnPref : Composition of many CommunicatnPref on CommunicatnPref.parentAddr = $self;
    Email: Composition of many Email on Email.parentAddr = $self;
    Facsimile: Composition of many Facsimile on Facsimile.parentAddr = $self;
    OrganisationName: Composition of many OrganisationName on OrganisationName.parentAddr = $self;
    PersonName:Composition of many PersonName on PersonName.parentAddr = $self;
    PostalAddr : Composition of many PostalAddr on PostalAddr.parentAddr = $self;
    Telephone:Composition of many Telephone on Telephone.parentAddr = $self;
    Web:Composition of many Web on Web.parentAddr = $self;
    parentAddrnfoData: Association to AddrnfoData;
}

@cds.persistence.exists
entity Web: cuid{
    URI: String;
    URITypeCode: String;
    UsageDeniedIndicator: Boolean;
    ValdtyPerd : Composition of many ValdtyPerd on ValdtyPerd.parentWeb = $self;
    WebNote: Composition of many WebNote on WebNote.parentWeb = $self;
    WebUsage: Composition of many WebUsage on WebUsage.parentWeb = $self;
    parentAddr: Association to Addr;
    parentAddrIndepndntCommInfo: Association to AddrIndepndntCommInfo;
}

@cds.persistence.exists
entity WebNote: cuid{
    Note: String;
    parentWeb: Association to Web;
}

@cds.persistence.exists
entity WebUsage: cuid{
    DefaultIndicator: Boolean;
    Usage: Composition of many Usage on Usage.parentWebUsage = $self;
    parentWeb: Association to Web;
}

@cds.persistence.exists
entity Telephone: cuid{
    FormattedNumberDescription: String;
    UsageDeniedIndicator: Boolean;
    MobilePhoneNumberIndicator: Boolean;
    SMSEnabledIndicator: Boolean;
    Number: Composition of many Number on Number.parentTelephone = $self;
    ValdtyPerd : Composition of many ValdtyPerd on ValdtyPerd.parentTelephone = $self;
    TelephoneNote: Composition of many TelephoneNote on TelephoneNote.parentTelephone = $self;
    TelephoneUsage: Composition of many TelephoneUsage on TelephoneUsage.parentTelephone = $self;
    parentAddr: Association to Addr;
    parentAddrIndepndntCommInfo: Association to AddrIndepndntCommInfo;
}

@cds.persistence.exists
entity TelephoneNote: cuid{
    Note: String;
    parentTelephone: Association to Telephone;
}

@cds.persistence.exists
entity TelephoneUsage: cuid{
    DefaultIndicator: Boolean;
    Usage: Composition of many Usage on Usage.parentTelephoneUsage = $self;
    parentTelephone: Association to Telephone;
}

@cds.persistence.exists
entity PersonName: cuid{
    AddressRepresentationCode: String;
    KeyWordsText: String;
    AdditionalKeyWordsText: String;
    FormattedName: String;
    CustName: Composition of many CustName on CustName.parentPersonName = $self;
    parentAddr: Association to Addr;
}

@cds.persistence.exists
entity OrganisationName: cuid{
    AddressRepresentationCode: String;
    KeyWordsText: String;
    AdditionalKeyWordsText: String;
    CustName: Composition of many CustName on CustName.parentOrganisationName = $self;
    parentAddr: Association to Addr;
}

@cds.persistence.exists
entity Facsimile: cuid{
    FormattedNumberDescription: String;
    UsageDeniedIndicator: Boolean;
    Number: Composition of many Number on Number.parentFacsimile = $self;
    ValdtyPerd : Composition of many ValdtyPerd on ValdtyPerd.parentFacsimile = $self;
    FacsimileNote: Composition of many FacsimileNote on FacsimileNote.parentFacsimile = $self;
    FacsimileUsage: Composition of many FacsimileUsage on FacsimileUsage.parentFacsimile = $self;
    parentAddr: Association to Addr;
    parentAddrIndepndntCommInfo: Association to AddrIndepndntCommInfo;
}

@cds.persistence.exists
entity Number: cuid{
    AreaID: String;
    SubscriberID: String;
    ExtensionID: String;
    CountryCode: String;
    CountryDiallingCode: String;
    CountryName: String;
    parentFacsimile: Association to Facsimile;
    parentTelephone: Association to Telephone;
}

@cds.persistence.exists
entity FacsimileNote: cuid{
    Note: String;
    parentFacsimile: Association to Facsimile;
}

@cds.persistence.exists
entity FacsimileUsage: cuid{
    DefaultIndicator: Boolean;
    Usage: Composition of many Usage on Usage.parentFacsimileUsage = $self;
    parentFacsimile: Association to Facsimile;
}

@cds.persistence.exists
entity Email: cuid{
    URI: String;
    UsageDeniedIndicator: Boolean;
    TransportNeutralEncapsulationFormatEnabledIndicator: Boolean;
    ValdtyPerd : Composition of many ValdtyPerd on ValdtyPerd.parentEmail = $self;
    EmailNote: Composition of many EmailNote on EmailNote.parentEmail = $self;
    EmailUsage: Composition of many EmailUsage on EmailUsage.parentEmail = $self;
    parentAddr: Association to Addr;
    parentAddrIndepndntCommInfo: Association to AddrIndepndntCommInfo;
}

@cds.persistence.exists
entity EmailNote: cuid{
    Note: String;
    parentEmail: Association to Email;
}

@cds.persistence.exists
entity EmailUsage: cuid{
    DefaultIndicator: Boolean;
    Usage: Composition of many Usage on Usage.parentEmailUsage = $self;
    parentEmail: Association to Email;
}

@cds.persistence.exists
entity Usage: cuid{
    Code: String;
    Name: String;
    ValdtyPerd: Composition of many ValdtyPerd on ValdtyPerd.parentUsage = $self;
    parentEmailUsage: Association to EmailUsage;
    parentFacsimileUsage: Association to FacsimileUsage;
    parentTelephoneUsage: Association to TelephoneUsage;
    parentWebUsage: Association to WebUsage;
}

@cds.persistence.exists
entity AddressNote: cuid{
    Note: String;
    parentAddr: Association to Addr;
}

@cds.persistence.exists
entity CommunicatnPref: cuid{
    CorrespondenceLanguageCode                : String;
    PreferredCommunicationMediumTypeCode      : String;
    parentAddr: Association to Addr;
}

@cds.persistence.exists
entity PostalAddr: cuid{
    AddressRepresentationCode: String;
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
    parentAddr: Association to Addr;
}

@cds.persistence.exists
entity AddrIndepndntCommInfo: cuid{
    CommunicationPreference: String;
    Email: Composition of many Email on Email.parentAddrIndepndntCommInfo = $self;
    Facsimile: Composition of many Facsimile on Facsimile.parentAddrIndepndntCommInfo = $self;
    Telephone:Composition of many Telephone on Telephone.parentAddrIndepndntCommInfo = $self;
    Web:Composition of many Web on Web.parentAddrIndepndntCommInfo = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity BankDetails: cuid{
    ID: String;
    BankAccountHolderName: String;
    Name: String;
    BankAccountID: String;
    BankAccountIDLong: String;
    BankAccountStandardID: String;
    SubstituteBusinessPartnerBankDetailsID: String;
    SubstituteDate: Date;
    CollectionAuthorisationIndicator: Boolean;
    BankControlKey: String;
    SpecificationsDescription: String;
    BankAccountExternalID: String;
    ValdtyPerd: Composition of many ValdtyPerd on ValdtyPerd.parentBankDetails = $self;
    BankDirectoryReference: Composition of many BankDirectoryReference on BankDirectoryReference.parentBankDetails = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity BankDirectoryReference: cuid{
    BankStandardID:String;
    BankCountryCode:String;
    BankInternalID:String;
    parentBankDetails: Association to BankDetails;
}

@cds.persistence.exists
entity PaymentCardDetails: cuid{
    ID: String;
    DefaultIndicator: Boolean;
    PaymentCard: Composition of many PaymentCard on PaymentCard.parentPaymentCardDetails = $self;
    Block: Composition of many Block on Block.parentPaymentCardDetails = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity PaymentCard: cuid{
    ID: String;
    CategoryCode: String;
    TypeCode: String;
    ReferenceID: String;
    SequenceID: String;
    HolderName: String;
    ValidFromDate: Date;
    ExpirationDate: Date;
    Description: String;
    NickName: String;
    IssuerName: String;
    IssueDateTime: DateTime;
    MaskedID: String;
    parentPaymentCardDetails: Association to PaymentCardDetails;
}

@cds.persistence.exists
entity Block: cuid{
    BlockingReasonCode: String;
    ValdtyPerd: Composition of many ValdtyPerd on ValdtyPerd.parentBlock = $self;
    parentPaymentCardDetails: Association to PaymentCardDetails;
}

@cds.persistence.exists
entity CommonInfo: cuid{
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
    ValdtyPerd: Composition of many ValdtyPerd on ValdtyPerd.parentCommonInfo = $self;
    CustPerson: Composition of many CustPerson on CustPerson.parentCommonInfo = $self;
    CustOrgnstn:Composition of many CustOrgnstn on CustOrgnstn.parentCommonInfo = $self;
    CustGrp: Composition of many CustGrp on CustGrp.parentCommonInfo = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity CustPerson: cuid{
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
    CustName: Composition of many CustName on CustName.parentCustPerson = $self;
    parentCommonInfo: Association to CommonInfo;
}

@cds.persistence.exists
entity CustOrgnstn: cuid{
    CompanyLegalFormCode                       : String;
    LegalEntityTypeCode                        : String;
    FoundationDate                             : String;
    LiquidationDate                            : String;
    DataControllerIsNotRequiredIndicator: Boolean;
    CustName: Composition of many CustName on CustName.parentCustOrgnstn = $self;
    parentCommonInfo: Association to CommonInfo;
}

@cds.persistence.exists
entity CustGrp: cuid{
    FormOfAddressCode: String;
    Name:String;
    AdditionalName:String;
    PartnerGroupTypeCode: String;
    parentCommonInfo: Association to CommonInfo;
}

@cds.persistence.exists
entity CustName: cuid{
    FormOfAddressCode                      : String;
    FormOfAddressName                      : String;
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
    AcademicTitleName                      : String;
    AdditionalAcademicTitleCode            : String;
    AdditionalAcademicTitleName            : String;
    NamePrefixCode                         : String;
    NamePrefixName                         : String;
    AdditionalNamePrefixCode               : String;
    NameSupplementCode                     : String;
    AdditionalNamePrefixName               : String;
    NameSupplementName                     : String;
    DeviatingFullName                      : String;
    NameFormatCountryCode                  : String;
    NameFormatCode                         : String;
    parentCustPerson: Association to CustPerson;
    parentCustOrgnstn: Association to CustOrgnstn;
    parentOrganisationName: Association to OrganisationName;
    parentPersonName: Association to PersonName;
}

@cds.persistence.exists
entity RoleInfo: cuid{
    RoleCode: String;
    ValdtyPerd : Composition of many ValdtyPerd on ValdtyPerd.parentRoleInfo = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity Identification: cuid{
    PartyIdentifierTypeCode:String;
    BusinessPartnerID:String;
    IdentifierIssuingAgencyName:String;
    EntryDate:Date;
    AreaOfValidityCountryCode:String;
    AreaOfValidityRegionCode:String;
    ValdtyPerd : Composition of many ValdtyPerd on ValdtyPerd.parentIdentification = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity IndSector: cuid{
    IndustryClassificationSystemCode: String;
    IndustrySectorCode: String;
    DefaultIndicator: Boolean;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity TaxNum: cuid {
    CountryCode                                : String;
    TaxIdentificationNumberTypeCode                : String;
    LongTaxIdentificationNumberTypeCode            : String;
    PartyTaxID                                      : String;
    LongPartyTaxID                                 : String;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity AddrDepTaxNum: cuid{
    CountryCode                                : String;
    TaxIdentificationNumberTypeCode                : String;
    LongTaxIdentificationNumberTypeCode            : String;
    PartyTaxID                                      : String;
    LongPartyTaxID                                 : String;
    AddrKey: Composition of many AddrKey on AddrKey.parentAddrDepTaxNum = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity CredMgmtProf: cuid {
    CreditLimitAndScoreCalculatingRuleCode : String;
    Score                                  : String;
    CalculatedScore                        : String;
    ScoreValidityEndDate                    : Date;
    ScoreChangeDate: Date;
    CreditRiskClassCode                    : String;
    CalculatedCreditRiskClassCode: String;
    CreditRiskClassChangeDate              : Date;
    CreditLimitCheckRuleCode: String;
    CreditGroupCode                        : String;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity CreditManagementExternalCreditInformation: cuid {
    CreditRatingProcedureCode: String;
    CreditRatingAllowedIndicator: Boolean;
    CreditRatingCode: String;
    CreditRatingTrendCode: String;
    CreditRatingEntryDate: Date;
    StandardCreditRatingProcedureIndicator: Boolean;
    Text: String;
    ValdtyPerd : Composition of many ValdtyPerd on ValdtyPerd.parentCreditManagementExternalCreditInformation = $self;
    parent: Association to FASTCoreCustomerMaster;
}


@cds.persistence.exists
entity CredMgmtCredWorth: cuid {
    AffidavitForAssetsMadeIndicator           : Boolean;
    AffidavitForAssetsMadeDate                : Date;
    BankruptcyProceedingsInitiatedIndicator   : Boolean;
    BankruptcyProceedingsInitiatedDate        : Date;
    ForeclosureProceedingsInitiatedIndicator  : Boolean;
    ForeclosureProceedingsInitiatedDate       : Date;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity FinServComm: cuid {
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
    FinServCommPerson       : Composition of many FinServCommPerson on FinServCommPerson.parentFinServComm = $self;
    FinServCommOrganisation : Composition of many FinServCommOrganisation on FinServCommOrganisation.parentFinServComm = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity FinServCommPerson: cuid {
    PrimaryCitizenshipCountryCode          : String;
    MaritalPropertyRegimeCode              : String;
    ChildrenNumberValue                    : Integer;
    HouseholdMembersNumberValue            : Integer;
    AnnualNetIncomeAmount                  : Decimal;
    AnnualNetIncomeYear                    : String;
    MonthlyNetIncomeAmount                 : Decimal;
    MonthlyNetIncomeMonth                  : String;
    MonthlyNetIncomeYear                   : String;
    NetIncomeCurrencyCode                  : String;
    DeathPlaceName                         : String;
    EmployeeIndicator                      : Boolean;
    EmployeeID                             : String;
    EmployeeCustomGroupCode                : String;
    EmployeeIDExistenceCheckIndicator      : Boolean;
    UserAccountID                          : String;
    parentFinServComm: Association to FinServComm;
}

@cds.persistence.exists
entity FinServCommOrganisation {
    CompanyWorkingDayCalendarCode          : String;
    RegisteredOfficeCountryCode            : String;
    RegisteredOfficeRegionCode             : String;
    RegisteredOfficeCityName               : String;
    BalanceSheetDisclosureFormCode         : String;
    EquityCapitalIncreaseAmount            : Decimal;
    EquityCapitalIncreaseFiscalYearID      : String;
    MaxSizeOfOrderingFile                  : Integer;
    parentFinServComm: Association to FinServComm;
}

@cds.persistence.exists
entity Employment: cuid{
    Code: String;
    StatusCode: String;
    IndustrialSectorCode: String;
    EmployerName: String;
    Period: Composition of many Period on Period.parentEmployment = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity Period: cuid{
    StartDate:Date;
    EndDate: Date;
    parentEmployment: Association to Employment;
}

@cds.persistence.exists
entity Rating: cuid{
    ProcedureCode: String;
    Code: String;
    DeterminationDate: Date;
    AllowedIndicator: Boolean;
    TrendCode: String;
    Note: String;
    ValdtyPerd : Composition of many ValdtyPerd on ValdtyPerd.parentRating = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity CreditWorthiness: cuid{
    Code: String;
    RequestLifeCycleStatusCode: String;
    AffidavitSubmittedIndicator: Boolean;
    AffidavitDate: Date;
    InsolvencyProceedingsStartedIndicator: Boolean;
    InsolvencyProceedingsDate: Date;
    ForeclosureStartedIndicator: Boolean;
    ForeclosureDate: Date;
    LegalProceedingsStatusCode: String;
    LegalProceedingsDate: Date;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity FiscalYear: cuid{
    FiscalYearID: String;
    FiscalYearPeriod: Composition of many FiscalYearPeriod on FiscalYearPeriod.parentFiscalYear = $self;
    BalanceSheet:Composition of many BalanceSheet on BalanceSheet.parentFiscalYear = $self; 
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity FiscalYearPeriod: cuid{
    StartDate: Date;
    EndDate: Date;
    parentFiscalYear: Association to FiscalYear;
}

@cds.persistence.exists
entity BalanceSheet: cuid {
    CurrencyCode: String;
    AnnualFinancialStatementsPreparedIndicator: Boolean;
    AnnualFinancialStatementsPreparedDate: Date;
    AnnualConsolidatedFinancialStatementsPreparedDate: Date;
    AnnualStockholderMeetingDate: Date;
    OutstandingParticipationCertificatesAmount: Double;
    EquityCapitalAmount: Double;
    IssuedShareCapitalAmount: Double;
    AuthorisedShareCapitalAmount: Double;
    GrossContributionAmount: Double;
    NetContributionAmount: Double;
    RevenueAmount: Double;
    AnnualNetProfitAmount: Double;
    ProfitDistributionAmount: Double;
    DebtCashFlowRatio: Double;
    AnnualProfitAmount: Double;
    TotalAmount: Double;
    CapitalReserveAmount: Double;
    LegalRevenueReserveAmount: Double;
    OwnStockRevenueReserveAmount: Double;
    StatutoryRevenueReserveAmount: Double;
    OtherRevenueReserveAmount: Double;
    ProfitLossCarriedForwardAmount: Double;
    SubordinatedLiabilitiesAmount: Double;
    ReturnOnTotalCapitalEmployedPercent: Double;
    DebtClearancePeriodDecimalValue: Double;
    EmployeeNumberValue: String;
    FinancingCoefficientPercent: Double;
    EquityRatioPercent: Double;
    parentFiscalYear: Association to FiscalYear;
}

@cds.persistence.exists
entity FinancialServicesReporting: cuid{
    Austria: Composition of many Austria on Austria.parentFinancialServicesReporting = $self;
    BankingGermany: Composition of many BankingGermany on BankingGermany.parentFinancialServicesReporting = $self;
    InsuranceGermany:  Composition of many InsuranceGermany on InsuranceGermany.parentFinancialServicesReporting = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity Austria: cuid {
    OENBIdentNumber: String;
    OENBTargetGroupCode: String;
    OENBankIdentNumberAssigned: String;
    OENBBankIdentNumber: String;
    RegulatoryReportingIndicator: Boolean;
    GroupID: String;
    GroupAssignmentCategoryCode: String;
    GroupName: String;
    parentFinancialServicesReporting: Association to FinancialServicesReporting;
}

@cds.persistence.exists
entity BankingGermany: cuid {
    AWGNonResidentIndicator: Boolean;
    AWGNonResidencyStartDate: Date;
    KWGMillionBorrowerIndicator: Boolean;
    KWGBorrowerID: String;
    KWGBorrowerEntityID: String;
    KWGCreditStandingReviewCode: String;
    KWGCreditStandingReviewDate: Date;
    KWGLoanToManagerCode: String;
    CompanyRelationshipCode: String;
    RiskGroupCode: String;
    ClassificationDate: Date;
    GroupAffiliationIndicator: Boolean;
    MonetaryFinancialInstitutionIndicator: Boolean;
    KWGCreditStandingReviewObligationIndicator: Boolean;
    KWGLargeScaleLoanMonitoringIndicator: Boolean;
    KWGCreditingReliefIndicator: Boolean;
    LZBCountryCode: String;
    KWGCreditorID: String;
    parentFinancialServicesReporting: Association to FinancialServicesReporting;
}

@cds.persistence.exists
entity InsuranceGermany: cuid {
    LegalEntityCode: String;
    AnLVRestrictedAssetQuotaBusinessPartnerCode: String;
    BerVersVDebtorGroupCode: String;
    BusinessPurposeCode: String;
    AnLVRestrictedAssetInvestmentAuthorizedIndicator: Boolean;
    parentFinancialServicesReporting: Association to FinancialServicesReporting;
}

@cds.persistence.exists
entity TaxCompliance: cuid {
    ID: String;
    UUID: String;
    RelevanceStatusCode: String;
    RelevanceReasonCode: String;
    DeterminationDate: Date;
    AgreementCode: String;
    AgreementDate: Date;
    ValdtyPerd : Composition of many ValdtyPerd on ValdtyPerd.parentTaxCompliance = $self;
    Regulation: Composition of many Regulation on Regulation.parentTaxCompliance = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity Regulation: cuid{
    Code:String;
    CountryCode:String;
    RegionCode: String;
    parentTaxCompliance: Association to TaxCompliance;
}

@cds.persistence.exists
entity PartnerIsBank: cuid{
    CountryCode:String;
    BankInternalID: String;
    MinimumReserveRequirementCode: String;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity Alias: cuid{
    Name:String;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity FinancialServicesCompanyCodeInformation: cuid{
    CompanyCodeID: String;
    StandingInstructionsAuthorization: Composition of many StandingInstructionsAuthorization on StandingInstructionsAuthorization.parentFinancialServicesCompanyCodeInformation = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity StandingInstructionsAuthorization: cuid {
    ContractTypeCode: String;
    ProductCategoryCode: String;
    ProductTypeCode: String;
    FinancialTransactionTypeCode: String;
    parentFinancialServicesCompanyCodeInformation: Association to FinancialServicesCompanyCodeInformation;
}

@cds.persistence.exists
entity FinancialServicesControlData: cuid{
    AllocatedCompanyCode:String;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity CreditManagementCustomInformation: cuid{
    CategoryCode: String;
    TypeCode: String;
    CounterValue: String;
    SubTypeCode: String;
    Indicator: Boolean;
    Text: String;
    Amount: Double;
    Date: Date;
    ValdtyPerd : Composition of many ValdtyPerd on ValdtyPerd.parentCreditManagementCustomInformation = $self;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity DataController: cuid {
    DataControllerName: String;
    DataPurposeName: String;
    DataControlAssignmentStatusCode: String;
    parent: Association to FASTCoreCustomerMaster;
}

@cds.persistence.exists
entity Document: cuid {
    DocumentTypeCode: String;
    DocumentID: String;
    AlternativeDocumentID: String;
    DocumentVersionID: String;
    parent: Association to FASTCoreCustomerMaster;
}
