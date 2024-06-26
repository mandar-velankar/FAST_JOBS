//const CronJob = require('cron').CronJob;
const { CronJob } = require('cron');
const axios = require('axios');
const qs = require("qs");
const cds = require('@sap/cds');
const { v4: uuidv4 } = require('uuid');
const { ProcessMaterials, ProcessCustomers } = require('./ItalyJobs');
const { ProcessMaterialsBrazil, ProcessCustomersBrazil } = require('./BrazilJobs');
const { ExtendPriceAgreements } = require('./PriceAgreementJobs');


module.exports = async () => {

  // const model = await cds.load(['db', 'srv']);
  // let db = cds.reflect(model);

  const db = await cds.connect.to('db'); // connect to database service
  const { SchedulerJobConfig, SchedulerApiConfig, SchedulerApiConfigUsers, SchedulerApiConfigOAuth } = db.entities("com.bayer.SXTENDER.AdminData");

  // connect to service
  const srv = await cds.connect.to('SalesOpportunityService');
  const {
    ParticipatedPublicMarketOpportunities,
    MercadoPublicoOrdenesDeCompra
  } = srv.entities;

  class MercadoPublico {

    constructor() {
      this.basicAuth = "";
      this.oauthAuth = "";
      this.host = "";
      this.serviceUrl = "";
      this.proxyHost = "";
      this.proxyPort = "";
      this.apiUser = "";
      this.apiPassword = "";
      this.oAuthProvider = "";
      this.grantType = "";
      this.clientID = "";
      this.clientSecret = "";
      this.resources = {};
      this.consultationDate = this.dateToDDMMYYYY(new Date()); //"20062021" example of specific day;
      

    }
    async loadConfig() {
      // get api config
      const mercadoApi = await cds.run(SELECT.from(SchedulerApiConfig).where({ Provider: 'MercadoPublco' }));

      this.mercadoConfig = mercadoApi[0];
      if (this.mercadoConfig.AuthType === "BASIC") {
        this.basicAuth = await cds.run(
          SELECT.one.from(SchedulerApiConfigUsers, this.mercadoConfig.User_ID)
        );
      } else if (this.mercadoConfig.AuthType === "OAUTH") {
        this.oauthAuth = await cds.run(
          SELECT.one.from(SchedulerApiConfigOAuth, this.mercadoConfig.OAuth_ID)
        );
      }
      this.classification_search_terms = await cds.run(SELECT.from('com.bayer.SXTENDER.IntegrationData.MercadoPublicoClassificationKeywords'));
      this.classification_products = await cds.run(SELECT.from('com.bayer.SXTENDER.IntegrationData.MercadoPublicoClassificationProducts'));

      this.host = this.mercadoConfig.Host;
      this.serviceUrl = this.mercadoConfig.BasePath;
      this.proxyHost = this.mercadoConfig.ProxyHost;
      this.proxyPort = this.mercadoConfig.ProxyPort;

      if (this.mercadoConfig.AuthType === "BASIC") {
        this.apiUser = this.basicAuth.ApiUser;
        this.apiPassword = this.basicAuth.ApiPassword;
      }

      if (this.mercadoConfig.AuthType === "OAUTH") {
        this.oAuthProvider = this.oauthAuth.OAuthProvider;
        this.grantType = this.oauthAuth.GrantType;
        this.clientID = this.oauthAuth.ClientID;
        this.clientSecret = this.oauthAuth.ClientSecret;
      }

      let tendersConfig = mercadoApi.find(item => item.Resource.indexOf("Tender") > -1);
      let poConfig = mercadoApi.find(item => item.Resource.indexOf("PurchaseOrder") > -1);

      this.resources = {
        tenders: {
          path: tendersConfig.ResourcePath,
          requestDelay: tendersConfig.RequestDelay,
          requestMaxRetry: tendersConfig.RequestMaxRetry

        },
        purchaseOrders: {
          path: poConfig.ResourcePath,
          requestDelay: poConfig.RequestDelay,
          requestMaxRetry: poConfig.RequestMaxRetry
        }
      };
      return mercadoApi;
    }
    /**
     * Fetches Tenders and saves them to the DB
     * @returns {CronJob}
     */
    async fetchTenders() {
      
      // const jobInfo = await cds.run(SELECT.from(SchedulerJobConfig).where({ JobName: 'MercadoPublco-Tenders' }));
      // const cronTime = '00 00 * * *';
      // if (jobInfo && jobInfo.length > 0) {
      //     cronTime = jobInfo[0].JobTime;
      // }
      // return new CronJob(cronTime, async () => {
      // this.cronManager.add("MercadoPublco-Tenders",cronTime, async () => {
        
        console.log(` `);
        console.log(`Load Config ...`);
        await this.loadConfig();

        let url = `${this.host}${this.serviceUrl}${this.resources.tenders.path}?fecha=${this.consultationDate}`;

        const start = new Date().getTime();
        console.log(` `);
        console.log(`Job "FetchTenders" started : ${new Date()}`);

        try {

          console.log(` `);
          console.log(`Fetching data from ${url} `);

          const results = await this.fetchWithRetry(url);
          const tenders = results.data.Listado;

          const tenderDetails = await this.getTendersWithDetails(tenders);

          console.log(` `);
          console.log(`${tenderDetails.length} tenders fetched`);

          if (tenderDetails && tenderDetails.length > 0) {
            console.log(` `);
            console.log(`Saving data ...`);
            await this.createTenders(tenderDetails);
          }

        } catch (err) {
          console.log(err);
        } finally {

          const end = new Date().getTime();
          const time = end - start;

          console.log(` `);
          console.log(`Job "FetchTenders" completed successfully : ${new Date()}`);
          console.log(`Execution time: ${time}ms`);

        }

      // });
      // this.cronManager.start("MercadoPublco-Tenders");
    }


    /**
     * Fetches tender results and saves them to the DB
     * the Mercado API periodically updates the opportunties with results.
     * we need to get those results and update the opportunity in the backend.
     * @returns {CronJob}
     */
    // fetchTenderResults(cronTime) {
    async fetchTenderResults() {

      // return new CronJob(cronTime, async () => {


        const start = new Date().getTime();
        console.log(` `);
        console.log(`Job "FetchTenderResults" started : ${new Date()}`);

        console.log(` `);
        console.log(`Load Config ...`);
        await this.loadConfig();

        try {

          let query = SELECT.from(ParticipatedPublicMarketOpportunities).where({ CountryCode: 'CL' })
          const participatedOpportunities = await srv.run(query);

          console.log(` `);
          console.log(`Fetching results ...`);

          const opportunitiesWithDetails = await this.getTendersWithDetails(participatedOpportunities);

          console.log(` `);
          console.log(`Fetching results complete.`);

          if (opportunitiesWithDetails && opportunitiesWithDetails.length > 0) {
            console.log(` `);
            console.log(`Saving results ...`);
            await this.updateTenders(opportunitiesWithDetails);
          }

        } catch (err) {
          console.log(err);
        } finally {

          const end = new Date().getTime();
          const time = end - start;

          console.log(` `);
          console.log(`Job "FetchTenderResults" completed successfully : ${new Date()}`);
          console.log(`Execution time: ${time}ms`);

        }


      // });

    }

    /**
     * Fetches Purchase orders from MercadoPublico API and saves them in the DB
     * @returns {CronJob}
     */
    // fetchPurchaseOrders(cronTime) {
    async fetchPurchaseOrders() {

      // return new CronJob(cronTime, async () => {

        console.log(` `);
        console.log(`Load Config ...`);
        await this.loadConfig();

        let url = `${this.host}${this.serviceUrl}${this.resources.purchaseOrders.path}?fecha=${this.consultationDate}`;

        const start = new Date().getTime();
        console.log(` `);
        console.log(`Job "FetchPurchaseOrders" started : ${new Date()}`);

        try {

          console.log(` `);
          console.log(`Fetching data from ${url} `);

          const results = await this.fetchWithRetry(url);
          const purchaseOrders = results.data.Listado;

          const poWithDetails = await this.getPurchaseOrdersWithDetails(purchaseOrders);

          console.log(` `);
          console.log(`${poWithDetails.length} purchase orders fetched`);

          if (poWithDetails && poWithDetails.length > 0) {
            console.log(` `);
            console.log(`Saving data ...`);
            await this.createPurchaseOrders(poWithDetails);
          }

        } catch (err) {
          console.log(err);
        } finally {

          const end = new Date().getTime();
          const time = end - start;

          console.log(` `);
          console.log(`Job "FetchPurchaseOrders" completed successfully : ${new Date()}`);
          console.log(`Execution time: ${time}ms`);

        }

      // });

    }

    getBearerToken() {
      if (this.mercadoConfig.AuthType === "OAUTH" && this.oAuthProvider && this.clientID && this.clientSecret) {

        const PROXY_HOST = this.proxyHost;
        const PROXY_PORT = this.proxyPort;

        console.log("Bearer Token scheduler proxyHost:", PROXY_HOST);
        console.log("Bearer Token scheduler proxyPort:", PROXY_PORT);

        return axios({
          method: 'post',
          url: this.oAuthProvider,
          headers: {
            'Authorization': `Basic ${Buffer.from(`${this.clientID}:${this.clientSecret}`).toString('base64')}`,
            'Content-Type': 'application/x-www-form-urlencoded'
          },
          data: qs.stringify({
            'grant_type': this.grantType
          })/*, when testing locally, comment out the proxy
          proxy: {
            host: PROXY_HOST,
            port: PROXY_PORT
          }*/
        });
      }
      throw Error("Only use bearer token for OAUTH config");
    }
    /**
     * Fetches data from a given entpoint. In case of failure, the request will be retried.
     * @param {String} url
     * @returns {Promise}
     */
    async fetchWithRetry(url) {

      const REQUEST_DELAY = this.resources.tenders.requestDelay;
      const MAX_RETRY = this.resources.tenders.requestMaxRetry;
      // const API_USER = this.apiUser;
      // const API_PASSWORD = this.apiPassword;
      const PROXY_HOST = this.proxyHost;
      const PROXY_PORT = this.proxyPort;
      let config = {};
      const that = this;

      if (this.mercadoConfig.AuthType === "BASIC") {
        console.log(`Will use basic auth with user ${this.basicAuth.ApiUser}\n`);
        config = {
          auth: {
            apiUser: this.basicAuth.ApiUser,
            apiPassword: this.basicAuth.ApiPassword,
          },
        };
      }

      if (this.mercadoConfig.AuthType === "OAUTH") {
        console.log(`Will use OAuth auth ${this.grantType} with clientID ${this.clientID}`);
        try {
          const oauthCredentials = await this.getBearerToken();
          console.log(`OAuth auth access token ${oauthCredentials.data.access_token}\n`);
          config = {
            headers: {
              'Authorization': `Bearer ${oauthCredentials.data.access_token}`,
            }
          };
        } catch (error) {
          console.log(`OAuth auth not able to fetch access token!\n`);
          const errLog = await that.saveError(error, url);
          throw new Error(error);
        }
      }

      let currentRetry = 0;

      function wait(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
      }

      function successHandler(response) {
        return response;
      }

      async function errorHandler(error) {

        if (currentRetry < MAX_RETRY) {
          currentRetry++;
          console.log(`Retrying ... \n\t [${currentRetry}] of [${MAX_RETRY}] - ${url}`);
          return sendWithRetry();
        } else {
          console.log(`\nRetried ${currentRetry} times but still failed to fetch from: ${url}\n`);
          const errLog = await that.saveError(error, url);
          throw new Error(error);

        }
      }

      async function sendWithRetry() {

        await wait(REQUEST_DELAY);

        // console.log(`Sending basic auth request to ${url} with [${API_USER}] - [${API_PASSWORD}]`);

        //get using basic auth setting that configures the API header
        return axios.get(url, config
          // {
          // auth: {
          //   username: API_USER,
          //   password: API_PASSWORD,
          // }, // when testing locally, comment out the proxy
          /*proxy: {
            host: PROXY_HOST,
            port: PROXY_PORT
          }*/
          // }
        ).then(successHandler).catch(errorHandler);
        // }

      }

      return sendWithRetry();
    }

    /**
     * Fetches Tenders with details for a given list of tenders
     * @param {Array} - list of tenders  
     * @returns {Promise <Array>} - list of tenders with details
     */
    async getTendersWithDetails(tenders) {
      const tenderDetails = [];

      for (let i = 0; i < tenders.length; i++) {
        try {

          let url = `${this.host}${this.serviceUrl}${this.resources.tenders.path}?codigo=${tenders[i].CodigoExterno}`;

          const detail = await this.fetchWithRetry(url);
          tenderDetails.push(detail.data.Listado[0]);

          console.log(`Tender ${detail.data.Listado[0].CodigoExterno} -> success`);
        } catch (error) {
          console.log(`Tender ${error.message}`);
        }
      }

      return tenderDetails;

    }

    async createTenders(tenders) {

      if (tenders && tenders.length > 0) {

        for (let a = 0; a < tenders.length; a++) {

          const mappedTenderObj = this.mapMercadoFields(tenders[a]);
          const classifiedTender = this.classifyTender(mappedTenderObj);

          const licitacione = this.getEntity(classifiedTender, 'licitacione');
          const comprador = this.getEntity(classifiedTender, 'comprador');
          const items = this.getEntity(classifiedTender, 'items');

          const insertPromises = [];

          insertPromises.push(cds.run(INSERT.into('com.bayer.SXTENDER.IntegrationData.MercadoPublicoLicitacione', licitacione)));
          insertPromises.push(cds.run(INSERT.into('com.bayer.SXTENDER.IntegrationData.MercadoPublicoComprador', comprador)));
          insertPromises.push(cds.run(INSERT.into('com.bayer.SXTENDER.IntegrationData.MercadoPublicoProducto', items)));

          try {
            await Promise.all(insertPromises);
            console.log(`Tender ${classifiedTender.CodigoExterno} success`);
          } catch (error) {
            console.log(`Tender ${classifiedTender.CodigoExterno} -> failed - ${error.message}`);
          }

        }

      }

    }


    async updateTenders(tenders) {

      if (tenders && tenders.length > 0) {

        for (let a = 0; a < tenders.length; a++) {
          try {

            const mappedTenderObj = this.mapMercadoFields(tenders[a]);
            const classifiedTender = this.classifyTender(mappedTenderObj);

            const licitacione = this.getEntity(classifiedTender, 'licitacione');
            const comprador = this.getEntity(classifiedTender, 'comprador');
            const items = this.getEntity(classifiedTender, 'items');

            const oldLicitacione = await cds.run(SELECT.one.from('com.bayer.SXTENDER.IntegrationData.MercadoPublicoLicitacione').where({ CodigoExterno: licitacione.CodigoExterno }));
            const oldProducts = await cds.run(SELECT.from('com.bayer.SXTENDER.IntegrationData.MercadoPublicoProducto').where({ Licitacione_CodigoExterno: licitacione.CodigoExterno }));

            // copy over the old ID's
            licitacione.Comprador_ID = oldLicitacione.Comprador_ID
            comprador.ID = oldLicitacione.Comprador_ID


            const updatePromises = [];

            // Update Licitacione + Comprador
            updatePromises.push(cds.run(UPDATE('com.bayer.SXTENDER.IntegrationData.MercadoPublicoLicitacione').where({ CodigoExterno: licitacione.CodigoExterno }).with(licitacione)));
            updatePromises.push(cds.run(UPDATE('com.bayer.SXTENDER.IntegrationData.MercadoPublicoComprador').where({ ID: oldLicitacione.Comprador_ID }).with(comprador)));


            // Update Items
            for (let i = 0; i < items.length; i++) {
              const oldProduct = oldProducts.find(oldP => oldP.Correlativo === items[i].Correlativo);

              // We need to reuse the old ID therefore we delete the new ID
              // We also need to copy over the old values for MatchedProductName and MatchedProductKeyword
              delete items[i]['ID'];
              items[i].MatchedProductName = oldProduct.MatchedProductName;
              items[i].MatchedProductKeyword = oldProduct.MatchedProductKeyword;

              updatePromises.push(cds.run(UPDATE('com.bayer.SXTENDER.IntegrationData.MercadoPublicoProducto').where({ ID: oldProduct.ID }).with(items[i])));
            }

            await Promise.all(updatePromises);
            console.log(`Tender ${classifiedTender.CodigoExterno} successfully updated`);

          } catch (error) {
            console.log(`Tender ${classifiedTender.CodigoExterno} update failed - ${error.message}`);
          }

        }

      }

    }


    /**
   * Fetches Purchase orders with details for a given list of purchase orders
   * @param {Array} - list of purchase orders  
   * @returns {Promise <Array>} - list of purchase orders with details
   */
    async getPurchaseOrdersWithDetails(porders) {
      const poWithDetails = [];

      for (let i = 0; i < porders.length; i++) {
        try {

          let url = `${this.host}${this.serviceUrl}${this.resources.purchaseOrders.path}?codigo=${porders[i].Codigo}`;

          const detail = await this.fetchWithRetry(url);
          poWithDetails.push(detail.data.Listado[0]);

          console.log(`PO ${detail.data.Listado[0].Codigo} -> success`);
        } catch (error) {
          console.log(`PO ${error.message}`);
        }
      }

      return poWithDetails;

    }


    async createPurchaseOrders(poWithDetails) {

      if (poWithDetails && poWithDetails.length > 0) {

        for (let a = 0; a < poWithDetails.length; a++) {

          const mappedPurchaseOrderObj = this.mapMercadoPurchaseOrderFields(poWithDetails[a]);

          let query = INSERT.into(MercadoPublicoOrdenesDeCompra, mappedPurchaseOrderObj);

          try {
            await srv.run(query);
            console.log(`PO ${mappedPurchaseOrderObj.Codigo} successfully created in the DB`);
          } catch (error) {
            console.log(`PO ${mappedPurchaseOrderObj.Codigo} creation failed - ${error.message}`);
          }

        }

      }

    }

    /**
     * Saves the error in the DB.
     * @param {Object} error 
     * @returns {Promise}
     */
    async saveError(error, url) {

      if (error) {

        try {

          const errorEntity = {
            JobName: "MercadoPublico",
            JobDescription: "",
            ErrorMessage: error.message,
            ResourceURL: url,
            ConsultationDate: new Date().toJSON()
          };

          console.log(`Failed with error: ${error}`);
          await cds.run(INSERT.into('com.bayer.SXTENDER.AdminData.SchedulerErrorLog', errorEntity));

          const urlParts = url.match(/=(.*?)&/);
          const msg = urlParts && urlParts.length > 0 && urlParts[1] || "Request";

          return `${msg} -> failed. See 'SchedulerErrorLog'`;

        } catch (err) {
          return err.message;
        }

      }

    }


    /**
     * Return only a part of the tender object
     * @param {Object} tender 
     * @param {String} entityType 
     * @returns {Object}
     */
    getEntity(tender, entityType) {

      if (entityType === "licitacione") {
        const obj = {
          ...tender
        };
        delete obj['Comprador'];
        delete obj['Items'];
        return obj;
      }

      if (entityType === "comprador") {
        const obj = {
          ...tender
        };
        return obj['Comprador'];
      }

      if (entityType === "items") {
        const obj = {
          ...tender
        };
        return obj['Items'];
      }

    }

    /**
     * Maps the fields from the API response to the entity fields
     * @param {Object} tender 
     * @returns {Object}
     */
    mapMercadoFields(tender) {
      if (tender) {
        const compradorUUID = uuidv4();

        const newTender = {
          ...tender,
          "FechaCreacion": tender.Fechas.FechaCreacion,
          "FechaCierre": tender.Fechas.FechaCierre,
          "FechaInicio": tender.Fechas.FechaInicio,
          "FechaFinal": tender.Fechas.FechaFinal,
          "FechaPubRespuestas": tender.Fechas.FechaPubRespuestas,
          "FechaActoAperturaTecnica": tender.Fechas.FechaActoAperturaTecnica,
          "FechaActoAperturaEconomica": tender.Fechas.FechaActoAperturaEconomica,
          "FechaPublicacion": tender.Fechas.FechaPublicacion,
          "FechaAdjudicacion": tender.Fechas.FechaAdjudicacion,
          "FechaEstimadaAdjudicacion": tender.Fechas.FechaEstimadaAdjudicacion,
          "FechaSoporteFisico": tender.Fechas.FechaSoporteFisico,
          "FechaTiempoEvaluacion": tender.Fechas.FechaTiempoEvaluacion,
          "FechaEstimadaFirma": tender.Fechas.FechaEstimadaFirma,
          "FechasUsuario": tender.Fechas.FechasUsuario,
          "FechaVisitaTerreno": tender.Fechas.FechaVisitaTerreno,
          "FechaEntregaAntecedentes": tender.Fechas.FechaEntregaAntecedentes,
          "AdjudicacionTipo": tender.Adjudicacion && tender.Adjudicacion.Tipo,
          "AdjudicacionFecha": tender.Adjudicacion && tender.Adjudicacion.Fecha,
          "AdjudicacionNumero": tender.Adjudicacion && tender.Adjudicacion.Numero,
          "AdjudicacionNumeroOferentes": tender.Adjudicacion && tender.Adjudicacion.NumeroOferentes,
          "AdjudicacionUrlActa": tender.Adjudicacion && tender.Adjudicacion.UrlActa,
          "Comprador_ID": compradorUUID,
          "Status": "",
          "Comprador": {
            "ID": compradorUUID,
            ...tender.Comprador
          },
          "Items": tender.Items && tender.Items.Listado.map(item => {

            return {
              "ID": uuidv4(),
              "Licitacione_CodigoExterno": tender.CodigoExterno,
              "Correlativo": item.Correlativo,
              "CodigoProducto": item.CodigoProducto,
              "CodigoCategoria": item.CodigoCategoria,
              "Categoria": item.Categoria,
              "NombreProducto": item.NombreProducto,
              "Descripcion": item.Descripcion,
              "UnidadMedida": item.UnidadMedida,
              "Cantidad": item.Cantidad,
              "AdjudicacionRutProveedor": item.Adjudicacion && item.Adjudicacion.RutProveedor,
              "AdjudicacionNombreProveedor": item.Adjudicacion && item.Adjudicacion.NombreProveedor,
              "AdjudicacionCantidad": item.Adjudicacion && item.Adjudicacion.Cantidad,
              "AdjudicacionMontoUnitario": item.Adjudicacion && item.Adjudicacion.MontoUnitario,
              "MatchedProductName": "",
              "MatchedProductKeyword": ""
            }
          }),
          createdAt: new Date().toJSON(),
          createdBy: "system"
        };

        delete newTender['Fechas'];
        delete newTender['Adjudicacion'];

        return newTender;

      }
    }

    /**
     * Maps the fields of purchase order from the API response to the entity fields
     * @param {Object} purchase order 
     * @returns {Object}
     */
    mapMercadoPurchaseOrderFields(purchaseOrder) {
      if (purchaseOrder) {

        const compradorUUID = uuidv4();
        const proveedorUUID = uuidv4();

        const newPurchaseOrder = {
          ...purchaseOrder,
          "FechaCreacion": purchaseOrder.Fechas.FechaCreacion,
          "FechaEnvio": purchaseOrder.Fechas.FechaEnvio,
          "FechaAceptacion": purchaseOrder.Fechas.FechaAceptacion,
          "FechaCancelacion": purchaseOrder.Fechas.FechaCancelacion,
          "FechaUltimaModificacion": purchaseOrder.Fechas.FechaUltimaModificacion,
          "Comprador_ID": compradorUUID,
          "Comprador": {
            "ID": compradorUUID,
            ...purchaseOrder.Comprador
          },
          "Proveedor_ID": proveedorUUID,
          "Proveedor": {
            "ID": proveedorUUID,
            ...purchaseOrder.Proveedor
          },
          "Items": purchaseOrder.Items && purchaseOrder.Items.Listado.map(item => {

            return {
              "ID": uuidv4(),
              "OrdenesDeCompra_Codigo": purchaseOrder.Codigo,
              ...item

            }
          }),

          createdAt: new Date().toJSON(),
          createdBy: "system"
        };

        delete newPurchaseOrder['Fechas'];

        return newPurchaseOrder;

      }
    }

    /**
     * Classifies a tender by adding a status with the value 'In' or 'Out'
     * In = a product with keyword was found, 
     * Out = a product with keyword was not found
     * @param {Object} tender 
     * @returns {Object} new tender object
     */
    classifyTender(tender) {

      const { Items: products } = tender;

      const classifiedProducts = products.map(product => this.classifyProduct(product));

      // Checks if some of the products got mached.
      // if matched -> MatchedProductName will have a value
      const isTenderClassified = classifiedProducts.some(prd => prd.MatchedProductName);

      return {
        ...tender,
        "Status": isTenderClassified ? "In" : "Out",
        "Items": classifiedProducts
      };

    }

    /**
     * Classifies and enriches a product with additional data by matching 
     * the Product Name or Product Description to a list of keywords. 
     * The keyword is first searched in the Product Name and when not found it is searched in the description.
     * @param {Object} Product 
     * @returns {Object} - new Product object
     */
    classifyProduct(product) {

      const _search_keywords = this.classification_search_terms;
      const _keyword_products = this.classification_products;
      const _search_text_product = product.NombreProducto.toLowerCase();
      const _search_text_desc = product.Descripcion.toLowerCase();

      let matchedProductName = "";
      let matchedProductKeyword = "";

      // search the keyword in the text
      const _keyword_found_in_product = _search_keywords.find(_term => _search_text_product.indexOf(_term.KEYWORD) > -1);
      const _keyword_found_in_description = _search_keywords.find(_term => _search_text_desc.indexOf(_term.KEYWORD) > -1);

      if (_keyword_found_in_product) {
        const prd = _keyword_products.find(prod => prod.PRODUCTID === _keyword_found_in_product.PRODUCT_PRODUCTID);
        matchedProductName = prd.PRODUCTNAME;
        matchedProductKeyword = _keyword_found_in_product.KEYWORD;
      } else if (_keyword_found_in_description) {
        const prd = _keyword_products.find(prod => prod.PRODUCTID === _keyword_found_in_description.PRODUCT_PRODUCTID);
        matchedProductName = prd.PRODUCTNAME;
        matchedProductKeyword = _keyword_found_in_description.KEYWORD;
      }

      return {
        ...product,
        "MatchedProductName": matchedProductName,
        "MatchedProductKeyword": matchedProductKeyword
      };

    }

    /**
     * Formats given date to ddmmyyyy
     * @param {object} date 
     * @returns {string}
     */
    dateToDDMMYYYY(date) {
      var d = date.getDate();
      var m = date.getMonth() + 1;
      var y = date.getFullYear();
      return `${(d <= 9 ? '0' + d : d)}${(m <= 9 ? '0' + m : m)}${y}`;
    }

  }
  // if(!this.mercadoPublico) this.mercadoPublico = new MercadoPublico();
  const mercadoPublico = new MercadoPublico()
  return { mercadoPublico }

};


module.exports.ItalyJobs = {

  processMaterials: function (cronTime) {
    return new ProcessMaterials(cronTime);
  },

  processCustomers: function (cronTime) {
    return new ProcessCustomers(cronTime);
  },


}

module.exports.BrazilJobs = {
    processMaterialsBrazil: function (cronTime) {
      return new ProcessMaterialsBrazil(cronTime);
    },
  
    processCustomersBrazil: function (cronTime) {
      return new ProcessCustomersBrazil(cronTime);
    },
}

module.exports.PriceAgreementJobs = {

    ExtendPriceAgreements: function (cronTime) {
      return new ExtendPriceAgreements(cronTime);
    },  
  
}