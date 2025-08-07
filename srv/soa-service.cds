using { com.bayer.SXTENDER.IntegrationDataConversion } from '../db/IntegrationDataConversion';
using { com.bayer.SXTENDER.IntegrationData } from '../db/IntegrationData';
using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
using { com.bayer.SXTENDER.TransactionalDataViews } from '../db/TransactionalDataViews';
using { com.bayer.SXTENDER.MasterData } from '../db/./MasterData';
using { com.bayer.SXTENDER.SalesOpportunityData } from '../db/SalesOpportunityData';
using { com.bayer.SXTENDER.AdminData } from '../db/AdminData';
using { com.bayer.SXTENDER.AdminDataViews } from '../db/AdminDataViews';
using { com.bayer.SXTENDER.MasterDataViews } from '../db/./MasterDataViews';
//using { com.bayer.SXTENDER.TransactionalData } from '../db/TransactionalData';
//using { com.bayer.SXTENDER.TransactionalDataConversion} from '../db/TransactionalDataConversion';

service SalesOpportunityService @(path: 'salesopportunity') @(requires:['f_tndr_cag_admin','f_tndr_cag_salesopportunity_user','f_tndr_cag_technical_user','authenticated-user']){
    //@cds.persistence.exists
    entity CountryTenderNo @readonly         as projection on TransactionalDataViews.CountryTenderNo;
    @cds.autoexpose
    //@cds.persistence.exists
    //entity CountryChannels @readonly         as projection on MasterData.MASTER_COUNTRY_CHANNELS;
    entity CountryChannels @readonly         as select from MasterData.MASTER_COUNTRY_CHANNELS {
        *
    } where ChannelName != 'Private';
    @cds.autoexpose
    //@cds.persistence.exists
    entity CountryClassifications @readonly  as projection on MasterData.MASTER_COUNTRY_CLASSIFICATION;
    @cds.autoexpose
    //@cds.persistence.exists
    entity CountryTenderType @readonly       as projection on MasterData.MASTER_COUNTRY_TENDER_TYPE;
    //@cds.persistence.exists
    entity TenderType @readonly              as projection on MasterData.MASTER_TENDER_TYPE;
    //@cds.persistence.exists
    entity PT_TMINST @readonly               as projection on MasterData.PT_TMINST;
    //@cds.persistence.exists
    entity CountryBrands @readonly           as projection on MasterDataViews.CountryBrands;
    //@cds.persistence.exists
    entity CountryBrandProducts @readonly    as projection on MasterDataViews.CountryBrandProducts;
    //@cds.persistence.exists
    entity CountryCurrency @readonly as projection on MasterDataViews.CountryCurrency;

    //@cds.persistence.exists
    entity Buyers as projection on IntegrationDataConversion.PublicMarketBuyers;
    //@cds.persistence.exists
    entity Products as projection on IntegrationDataConversion.PublicMarketProducts;

    //Admin Data Views
    //@cds.persistence.exists
    entity UserCountry as projection on AdminData.PT_TMUSERCTRY;
    //@cds.persistence.exists
    entity TenderCountriesUser @(restrict: [
		{grant: '*', to: 'authenticated-user', where: 'User.CWID = $user.id'}
	]) as projection on MasterData.PT_TMCTRY{
		*,
		User: redirected to UserCountry
	};

    //@cds.persistence.exists
    entity PublicMarketTenders as projection on IntegrationDataConversion.PublicMarketTenders
    {
        *,
        Comprador: redirected to Buyers,
        Items: redirected to Products
    };

    //@cds.persistence.exists
    entity PT_TMTEND as projection on TransactionalData.PT_TMTEND {
        * ,
    };
    //@cds.persistence.exists
    entity CountrySpecificInformation as projection on TransactionalData.CountrySpecificTenderInfo;

    //@cds.persistence.exists
    entity PT_TMTNOFST as projection on TransactionalData.PT_TMTNOFST;
    
    //@cds.persistence.exists
    entity PublicMarketTenderStatuses as select from PublicMarketTenders as opp
    left outer join TransactionalData.CountrySpecificTenderInfo as info 
        on opp.CodigoExterno = info.TenderReference
    left outer join TransactionalData.PT_TMTEND as TMTEND
        on info.TenderID = TMTEND.TenderID
    {
        key opp.CodigoExterno,
        info.TenderID as TenderID,
        case 
            when info.TenderReference is null or TMTEND.Active = 0 then opp.TenderMatchingStatus else 'Participated' 
        end as Status:String,
        case 
            when info.TenderReference is null then 'NA'
            when not exists (select TenderID from TransactionalData.PT_TMQUTO as tmqt where info.TenderID = tmqt.TenderID) then 'Draft'
            when exists (select TenderID, Outcome from TransactionalData.PT_TMTRRES as trres where info.TenderID = trres.TenderID and trres.Outcome = 'Won') 
                and not exists (select TenderID from TransactionalDataViews.ResultsWithAppealInProgress as rwaip where info.TenderID = rwaip.TenderID) 
                and exists (select lic.CodigoExterno, lic.CreatedAt as licCreatedAt, lic.StateCode, compra.CodigoLicitacion, compra.FechaCreacion as compraCreatedAt, compra.Estado from IntegrationDataConversion.PublicMarketTenders as lic
                                inner join IntegrationData.MercadoPublicoOrdenesDeCompra as compra on lic.CodigoExterno = compra.CodigoLicitacion)
                    then 'PO'
            when exists (select TenderID, Outcome from TransactionalData.PT_TMTRRES as trres where info.TenderID = trres.TenderID and trres.Outcome = 'Won') 
                and not exists (select TenderID from TransactionalDataViews.ResultsWithAppealInProgress as rwaip where info.TenderID = rwaip.TenderID) then 'Won'
            when exists (select TenderID from TransactionalDataViews.ResultsWithAppealInProgress as rwaip2 where info.TenderID = rwaip2.TenderID) then 'AppealInProgress'
            when exists (select TenderID, Outcome from TransactionalData.PT_TMTRRES as trres2 where info.TenderID = trres2.TenderID and trres2.Outcome <> 'Won') 
                or exists (select TenderID from TransactionalDataViews.ResultsWithAppealInProgress as rwaip3 where info.TenderID = rwaip3.TenderID) then 'Lost'
            when exists (select TenderID, OfferID from TransactionalData.PT_TMOFRS as offer inner join TransactionalDataViews.OfferStatus as stoffer on offer.OfferID = stoffer.OFFER_ID where offer.TenderID = info.TenderID and stoffer.STATUS = 'Quotation Submitted' and offer.Active = 1) then 'Submitted'
            when exists (select TenderID from TransactionalData.PT_TMQUTO as tmqt2 where info.TenderID = tmqt2.TenderID)
                and not exists (select TenderID, Outcome from TransactionalData.PT_TMTRRES as trres2 where info.TenderID = trres2.TenderID)
                and exists (select AdjudicacionRutProveedor from IntegrationData.MercadoPublicoProducto where AdjudicacionRutProveedor != null and Licitacione.CodigoExterno = info.TenderReference) then 'Results Available'
        end as SubStatus:String,
    };

    //@cds.persistence.exists
    entity PublicMarketOpportunities as select from PublicMarketTenders as opp
    left outer join PublicMarketTenderStatuses as st 
        on opp.CodigoExterno = st.CodigoExterno
    {
        key opp.CodigoExterno,
        opp.Name,
        opp.StateCode,
        opp.Description,
        opp.Status,
        opp.BidClosingDays,
        opp.Notified,
        opp.CodeType,
        opp.TenderType,
        opp.CallType,
        opp.Currency,
        opp.Stages,
        opp.StateSteps,
        opp.Reason,
        opp.AdvertisingOfferStatus,
        opp.JustificationAdvertising,
        opp.Contract,
        opp.Works,
        opp.ClaimsAmount,
        opp.CreatedAt,
        opp.ClosingDate,
        opp.StartDate,
        opp.FinalDate,
        opp.DatePubAnswers,
        opp.TechnicalOpeningActDate,
        opp.EconomicOpeningActDate,
        opp.PublicationDate,
        opp.AwardDate,
        opp.EstimatedAwardDate,
        opp.PhysicalSupportDate,
        opp.DateTimeEvaluation,
        opp.EstimatedSignatureDate,
        opp.UserDate,
        opp.FieldVisitTab,
        opp.DeliveryBackgroundDate,
        opp.UnitEvaluationTime,
        opp.VisitAddress,
        opp.DeliveryAddress,
        opp.Estimate,
        opp.FinancingSource,
        opp.VisibilityAmount,
        opp.EstimatedAmount,
        opp.TenderTime,
        opp.UnitTime,
        opp.Modality,
        opp.PaymentType,
        opp.ResponsiblePaymentName,
        opp.ResponsiblePaymentEmail,
        opp.ResponsibleContractName,
        opp.ResponsibleContractEmail,
        opp.ResponsibleContractPhone,
        opp.ContractingProhibition,
        opp.Outsourcing,
        opp.UnitTimeContractDuration,
        opp.ContractDurationTime,
        opp.ContractDurationType,
        opp.EstimatedJustificationAmount,
        opp.ContractObservation,
        opp.TermExtension,
        opp.IsBaseType,
        opp.TenderContractUnitTime,
        opp.RenewalTimeValue,
        opp.RenewalTimePeriod,
        opp.IsRenewable,
        opp.AwardType,
        opp.AwardNumber,
        opp.AwardNumberOfBidders,
        opp.AwardMinutesURL,
        opp.TenderMatchingStatus,
        st.TenderID as TenderID,
        st.Status as MainStatus,
        st.SubStatus,
        opp.Comprador: redirected to Buyers,
        opp.Items: redirected to Products
    };

    //@cds.persistence.exists
    entity ParticipatedPublicMarketOpportunities as select from CountrySpecificInformation as countryInfo
    left outer join PT_TMTEND as tndr 
        on countryInfo.TenderID = tndr.TenderID 
    left outer join PT_TMTNOFST as status 
        on countryInfo.TenderID = status.TenderID 
    {
        countryInfo.CountryCode,
        countryInfo.TenderID,
        countryInfo.TenderReference as CodigoExterno,
        status.STATUS as Status
        
    }where countryInfo.CountryCode = 'CL' 
    and tndr.Active = 1
    and status.STATUS = 'Quotation Submitted'
    and status.Active = 1
    and status.CountryCode = 'CL';

    //@cds.persistence.exists
    entity MercadoPublicoOrdenesDeCompra as projection on IntegrationData.MercadoPublicoOrdenesDeCompra;


};