using { com.bayer.SXTENDER.TransactionalData }          from '../db/TransactionalData';
using { com.bayer.SXTENDER.TransactionalDataViews }     from '../db/TransactionalDataViews';
using { com.bayer.SXTENDER.MasterData }                 from '../db/./MasterData';
using { com.bayer.SXTENDER.SalesOpportunityData }       from '../db/SalesOpportunityData';
using { com.bayer.SXTENDER.AdminData }                  from '../db/AdminData';
using { com.bayer.SXTENDER.AdminDataViews }             from '../db/AdminDataViews';
using { com.bayer.SXTENDER.MasterDataViews }            from '../db/./MasterDataViews';

service CreateOpportunityService @(path: 'createopportunity') @(requires:['f_tndr_cag_admin','f_tndr_cag_createopportunity_user','f_tndr_cag_technical_user','authenticated-user']){
    //@cds.persistence.exists
    entity CountryTenderNo        @readonly as projection on TransactionalDataViews.CountryTenderNo;
    //@cds.persistence.exists
    @cds.autoexpose
    entity CountryChannels        @readonly as select from MasterData.MASTER_COUNTRY_CHANNELS {
        *
    } where ChannelName != 'Private';
    //@cds.persistence.exists
    @cds.autoexpose
    entity CountryClassifications @readonly as projection on MasterData.MASTER_COUNTRY_CLASSIFICATION;
    //@cds.persistence.exists
    @cds.autoexpose
    entity CountryTenderType      @readonly as projection on MasterData.MASTER_COUNTRY_TENDER_TYPE;
    //@cds.persistence.exists
    entity TenderType             @readonly as projection on MasterData.MASTER_TENDER_TYPE;
    //@cds.persistence.exists
    entity PT_TMINST              @readonly as projection on MasterData.PT_TMINST;
    //@cds.persistence.exists
    entity CountryBrands          @readonly as projection on MasterDataViews.CountryBrands;
    //@cds.persistence.exists
    entity CountryBrandProducts   @readonly as projection on MasterDataViews.CountryBrandProducts;
    //@cds.persistence.exists
    entity CountryCurrency        @readonly as projection on MasterDataViews.CountryCurrency;

    //@cds.persistence.exists
    entity SalesOpportunities       as projection on SalesOpportunityData.SalesOpportunities{
        *,
        Institute: redirected to PT_TMINST,
        Products: redirected to SalesOpportunityProducts
    };
    //@cds.persistence.exists
    entity SalesOpportunityProducts as projection on SalesOpportunityData.SalesOpportunityProducts;

    //Admin Data Views
    //@cds.persistence.exists
    entity UserCountry              as projection on AdminData.PT_TMUSERCTRY;
    //@cds.persistence.exists
    entity TenderCountriesUser @(restrict: [
		{grant: '*', to: 'authenticated-user', where: 'User.CWID = $user.id'}
	]) as projection on MasterData.PT_TMCTRY{
		*,
		User: redirected to UserCountry
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
    entity OpportunityTenderStatus as select from SalesOpportunities as opp
    left outer join TransactionalData.CountrySpecificTenderInfo as info 
        on opp.ID = info.TenderReference
    left outer join TransactionalData.PT_TMTEND as TMTEND
        on info.TenderID = TMTEND.TenderID
    {
        key opp.ID as TenderReference,
        info.TenderID as TenderID,
        case 
            when info.TenderReference is null or TMTEND.Active = 0 
            then 
                case 
                    when opp.TenderMatchingStatus = 'In' then 'New' 
                    when opp.TenderMatchingStatus = 'Out' then 'Declined' 
                end
            else 'Active' 
        end as Status:String,
        case 
            when info.TenderReference is null then 'NA'
            when not exists (select TenderID from TransactionalData.PT_TMQUTO as tmqt where info.TenderID = tmqt.TenderID) then 'Draft'
            when exists (select TenderID, Outcome from TransactionalData.PT_TMTRRES as trres where info.TenderID = trres.TenderID and trres.Outcome = 'Won') 
                and not exists (select TenderID from TransactionalDataViews.ResultsWithAppealInProgress as rwaip where info.TenderID = rwaip.TenderID) then 'Won'
            when exists (select TenderID from TransactionalDataViews.ResultsWithAppealInProgress as rwaip2 where info.TenderID = rwaip2.TenderID) then 'AppealInProgress'
            when exists (select TenderID, Outcome from TransactionalData.PT_TMTRRES as trres2 where info.TenderID = trres2.TenderID and trres2.Outcome <> 'Won') 
                or exists (select TenderID from TransactionalDataViews.ResultsWithAppealInProgress as rwaip3 where info.TenderID = rwaip3.TenderID) then 'Lost'
            when exists (select TenderID, OfferID from TransactionalData.PT_TMOFRS as offer inner join TransactionalDataViews.OfferStatus as stoffer on offer.OfferID = stoffer.OFFER_ID where offer.TenderID = info.TenderID and stoffer.STATUS = 'Quotation Submitted' and offer.Active = 1) then 'Submitted'
        end as SubStatus:String,
    };


    //@cds.persistence.exists
    entity PublicSalesOpportunities as select from SalesOpportunities as opp
    left outer join OpportunityTenderStatus as st 
        on opp.ID = st.TenderReference
    {
        key opp.ID,
        opp.CountryCode,
        opp.TenderReference,
        opp.Classification,
        opp.Division,
        opp.TenderChannel,
        opp.PublicationDate,
        opp.OfferDueDate,
        opp.NextPublicationDate,
        opp.ExpectedAwardDate,
        opp.ContractLength,
        opp.ExtensionPeriod,
        opp.TenderMatchingStatus,
        opp.Description,
        opp.Currency,
        opp.FoldersCreated,
        opp.OpportunityValue,
        st.Status as MainStatus,
        st.SubStatus,
        opp.Institute: redirected to PT_TMINST,
        opp.Products: redirected to SalesOpportunityProducts
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
};