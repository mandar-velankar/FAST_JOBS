namespace com.bayer.SXTENDER.IntegrationData;

using { User, Country, cuid, managed } from '@sap/cds/common';

//Product & matching keywords (Mercado Publico - Chile)
entity MercadoPublicoClassificationProducts: managed {
    key ProductID                       : Integer;
        ProductName                     : String;
        Keywords                        : Composition of many MercadoPublicoClassificationKeywords on Keywords.Product = $self;
}

//Key words (Mercado Publico - Chile)
entity MercadoPublicoClassificationKeywords: managed {
        Keyword                         : String;
        Product                         : Association to MercadoPublicoClassificationProducts;
}

// Sales opportunities (MercadoPublico - Chile)
entity MercadoPublicoLicitacione : managed {
    key CodigoExterno                   : String;
        Nombre                          : String;
        CodigoEstado                    : Integer;
        Descripcion                     : String;
        Estado                          : String;
        DiasCierreLicitacion            : String;
        Informada                       : Integer;
        CodigoTipo                      : Integer;
        Tipo                            : String;
        TipoConvocatoria                : String;
        Moneda                          : String;
        Etapas                          : Integer;
        EstadoEtapas                    : String;
        TomaRazon                       : String;
        EstadoPublicidadOfertas         : Integer;
        JustificacionPublicidad         : String;
        Contrato                        : String;
        Obras                           : String;
        CantidadReclamos                : Integer;
        FechaCreacion                   : DateTime;
        FechaCierre                     : DateTime;
        FechaInicio                     : DateTime;
        FechaFinal                      : DateTime;
        FechaPubRespuestas              : DateTime;
        FechaActoAperturaTecnica        : DateTime;
        FechaActoAperturaEconomica      : DateTime;
        FechaPublicacion                : DateTime;
        FechaAdjudicacion               : DateTime;
        FechaEstimadaAdjudicacion       : DateTime;
        FechaSoporteFisico              : DateTime;
        FechaTiempoEvaluacion           : DateTime;
        FechaEstimadaFirma              : DateTime;
        FechasUsuario                   : DateTime;
        FechaVisitaTerreno              : DateTime;
        FechaEntregaAntecedentes        : DateTime;
        UnidadTiempoEvaluacion          : Integer;
        DireccionVisita                 : String;
        DireccionEntrega                : String;
        Estimacion                      : Integer;
        FuenteFinanciamiento            : String;
        VisibilidadMonto                : Integer;
        MontoEstimado                   : Double;
        Tiempo                          : String;
        UnidadTiempo                    : String;
        Modalidad                       : Integer;
        TipoPago                        : String;
        NombreResponsablePago           : String;
        EmailResponsablePago            : String;
        NombreResponsableContrato       : String;
        EmailResponsableContrato        : String;
        FonoResponsableContrato         : String;
        ProhibicionContratacion         : String;
        SubContratacion                 : String;
        UnidadTiempoDuracionContrato    : Integer;
        TiempoDuracionContrato          : String;
        TipoDuracionContrato            : String;
        JustificacionMontoEstimado      : String;
        ObservacionContract             : String;
        ExtensionPlazo                  : Integer;
        EsBaseTipo                      : Integer;
        UnidadTiempoContratoLicitacion  : String;
        ValorTiempoRenovacion           : String;
        PeriodoTiempoRenovacion         : String;
        EsRenovable                     : Integer;
        AdjudicacionTipo                : Integer;
        AdjudicacionFecha               : DateTime; // duplicate (see FechaAdjudicacion)
        AdjudicacionNumero              : String;
        AdjudicacionNumeroOferentes     : Integer;
        AdjudicacionUrlActa             : String;
        Status                          : String; // (In = keyword found, Out = keyword not found)
        Comprador                       : Composition of MercadoPublicoComprador;
        Items                           : Composition of many MercadoPublicoProducto on Items.Licitacione = $self;
};

//Buyers (MercadoPublico - Chile)
entity MercadoPublicoComprador: cuid {
        CodigoOrganismo                 : String;
        NombreOrganismo                 : String;
        RutUnidad                       : String;
        CodigoUnidad                    : String;
        NombreUnidad                    : String;
        DireccionUnidad                 : String;
        ComunaUnidad                    : String;
        RegionUnidad                    : String;
        RutUsuario                      : String;
        CodigoUsuario                   : String;
        NombreUsuario                   : String;
        CargoUsuario                    : String;
};


// Products (MercadoPublico - Chile)
entity MercadoPublicoProducto: cuid {
        Correlativo                     : Integer;
        CodigoProducto                  : Integer;
        CodigoCategoria                 : String;
        Categoria                       : String;
        NombreProducto                  : String;
        Descripcion                     : String;
        UnidadMedida                    : String;
        Cantidad                        : Double;
        AdjudicacionRutProveedor        : String;
        AdjudicacionNombreProveedor     : String;
        AdjudicacionCantidad            : Double;
        AdjudicacionMontoUnitario       : Double;
        MatchedProductName              : String;
        MatchedProductKeyword           : String;
        Licitacione                     : Association to MercadoPublicoLicitacione;
};


//Purchase Orders (Mercado Publico - Chile)
entity MercadoPublicoOrdenesDeCompra: managed {
    key Codigo                          : String;
        Nombre                          : String;
        CodigoEstado                    : Integer;
        Estado                          : String;
        CodigoLicitacion                : String;
        Descripcion                     : String;
        CodigoTipo                      : String;
        Tipo                            : String;
        TipoMoneda                      : String;
        CodigoEstadoProveedor           : Integer;
        EstadoProveedor                 : String;
        FechaCreacion                   : DateTime;
        FechaEnvio                      : DateTime;
        FechaAceptacion                 : DateTime;
        FechaCancelacion                : DateTime;
        FechaUltimaModificacion         : DateTime;
        TieneItems                      : String;
        PromedioCalificacion            : Double;
        CantidadEvaluacion              : Integer;
        Descuentos                      : Double;
        Cargos                          : Double;
        TotalNeto                       : Double;
        PorcentajeIva                   : Double;
        Impuestos                       : Double;
        Total                           : Double;
        Financiamiento                  : String;
        Pais                            : String;
        TipoDespacho                    : String;
        FormaPago                       : String;
        Comprador                       : Composition of MercadoPublicoOrdenesDeCompraComprador;
        Proveedor                       : Composition of MercadoPublicoOrdenesDeCompraProveedor;
        Items                           : Composition of many MercadoPublicoOrdenesDeCompraProducto on Items.OrdenesDeCompra = $self;        
}

// Buyers Purchase Orders (Mercado Publico - Chile)
entity MercadoPublicoOrdenesDeCompraComprador: cuid {
        CodigoOrganismo                 : String;
        NombreOrganismo                 : String;
        RutUnidad                       : String;
        CodigoUnidad                    : String;
        NombreUnidad                    : String;
        Actividad                       : String;
        DireccionUnidad                 : String;
        ComunaUnidad                    : String;
        RegionUnidad                    : String;
        Pais                            : String;
        NombreContacto                  : String;
        CargoContacto                   : String;
        FonoContacto                    : String;
        MailContacto                    : String;
};

//Vendor Purchase Orders (Mercado Publico - Chile)
entity MercadoPublicoOrdenesDeCompraProveedor: cuid {
        Codigo                          : String;
        Nombre                          : String;
        Actividad                       : String;
        CodigoSucursal                  : String;
        NombreSucursal                  : String;
        RutSucursal                     : String;
        Direccion                       : String;
        Comuna                          : String;
        Region                          : String;
        Pais                            : String;
        NombreContacto                  : String;
        CargoContacto                   : String;
        FonoContacto                    : String;
        MailContacto                    : String;
};

//Product Purchase Orders (Mercado Publico - Chile)
entity MercadoPublicoOrdenesDeCompraProducto: cuid {
        Correlativo                     : Integer;
        CodigoCategoria                 : Integer;
        Categoria                       : String;
        CodigoProducto                  : Integer;
        Producto                        : String;
        EspecificacionComprador         : String;
        EspecificacionProveedor         : String;
        Cantidad                        : Double;
        Unidad                          : String;
        Moneda                          : String;
        PrecioNeto                      : Double;
        TotalCargos                     : Double;
        TotalDescuentos                 : Double;
        TotalImpuestos                  : Double;
        Total                           : Double;
        OrdenesDeCompra                 : Association to MercadoPublicoOrdenesDeCompra;
};