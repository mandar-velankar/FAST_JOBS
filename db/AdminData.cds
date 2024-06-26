namespace com.bayer.SXTENDER.AdminData;

using {
    User,
    Country,
    managed,
    cuid
} from '@sap/cds/common';
using {com.bayer.SXTENDER.MasterData} from './MasterData';
using {com.bayer.SXTENDER.AdminDataViews} from './AdminDataViews';
using {com.bayer.SXTENDER.BrazilContractingData} from '../db/BrazilContractingData';

//Autorization tables
//-------------------
@cds.persistence.exists
entity CONDITIONAL_ACCESS {
    key Id               : Integer not null;
        CWIDs_COGS       : String(5000);
        CWIDs_Price      : String(5000);
        CWIDs_Volume     : String(5000);
        CWIDs_Penalty    : String(5000);
        CWIDs_MarketData : String(5000);
}

//EHQUT-268955-Spain - correct mistakes on Commercial agreement templates
@cds.persistence.exists
entity PT_TMUSER {
        ToolIdentity    : String(20);
        ToolID          : Integer;
    key UserID          : String(50);
        UserName        : String(100);
        LoginTime       : String(255);
        CWID            : String(12);
        UserEmail       : String(255);
        Role            : String(100);
        ContactNumber   : String(20);
        BU              : String;
        //Associations
        Countries       : Association to many PT_TMUSERCTRY
                              on Countries.User = $self;
        toUserCountries : Association to many AdminDataViews.UserCountries
                              on toUserCountries.USER_ID = UserID;
        UserTerritory   : Association to many MasterData.UserTerritory
                              on UserTerritory.UserID = UserID;
}

@cds.persistence.exists
entity PT_TMUSERCTRY {
    key CWID         : String(5);
    key CountryCode  : String;
        ActiveRecord : String(3);
        //Associations
        User         : Association to PT_TMUSER
                           on User.CWID = CWID; //This cannot be found in OData
        Country      : Association to MasterData.PT_TMCTRY
                           on Country.CountryCode = CountryCode; //This can be found in OData
}

@cds.persistence.exists
entity PT_TMUSERCTRYN {
    key CountryCode : String;
        CWIDs       : String(500);
}

//PDF templates
//-------------
@cds.persistence.exists
entity TemplateCountry {
    key CountryCode    : String;
    key Classification : String(50); //Added Classification (db#2)
        TemplateId     : Integer;
}

@cds.persistence.exists
entity Template {
    key TemplateId     : Integer;
        Template       : LargeString;
        HeaderTemplate : LargeString;
        HeaderHeight   : String;
        FooterTemplate : LargeString;
        FooterHeight   : String;
        Format         : String(2);
        Orientation    : String;
        Border         : String;
}

//Mail Templates
//---------------
/*entity MailTemplateCountry {
    key CountryCode    : String(2);
    key TemplateId     : Integer;
}*/

@cds.persistence.exists
entity MailTemplate {
    key CountryCode    : String;
    key Language       : String(2);
    key TemplateId     : String(100);
        MailTemplateFile      : Association to MailTemplateFile
                            on MailTemplateFile.templateId = TemplateId; //This can be found in OData
}

@cds.persistence.exists
entity MailTemplateFile {
    key templateId     : String(100);
    title:String(100);
    filename:String(250);
    content   : LargeBinary @Core.MediaType: mediaType;//'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    mediaType:String @Core.IsMediaType;
}


// entity MandatoryTableFieldsCountry {
//     key CountryCode : String(2);
//     key View        : String(100);
//     key Model       : String(100);
//     key Field       : String(100);
//         Required    : Boolean;
// }

//Customizing tables
//------------------

//Customizing for: tables (sap.m.Table...)
@cds.persistence.exists
entity CountryTablesCustomization {
    key CountryCode : String;
    key TableID     : String(100);
    key Column      : String(100);
        BindingPath : String(255);
        Visible     : Boolean;
        Required    : Boolean;
        Description : String(255);
}

//Customizing for: tabs
@cds.persistence.exists
entity CountryTabsCustomization {
    key CountryCode : String;
    key TabID       : String(100);
        Visible     : Boolean;
}

//Customizing for: fragments
@cds.persistence.exists
entity CountryFragmentsCustomization {
    key CountryCode   : String;
    key FragmentID    : String(100);
    key FragmentName  : String(100);
}

//config for application urls
@cds.persistence.exists
entity AppConfig: cuid {
    CountryCode         : String;
    Environment         : String(10);
    ApplicationName     : String(40);
    Control             : String(100);
    URL                 : String;
}

// Scheduler configuration
@cds.persistence.exists
entity SchedulerApiConfig: cuid {
    Provider            : String; 
    Host                : String;
    BasePath            : String;
    Resource            : String;
    ResourcePath        : String;
    ProxyHost           : String;
    ProxyPort           : Integer;
    RequestDelay        : Integer;
    RequestMaxRetry     : Integer;
    AuthType            : String;
    CountryCode         : String;
    User                : Association to SchedulerApiConfigUsers;
    OAuth               : Association to SchedulerApiConfigOAuth;
}

// Scheduler basic auth configuration
@cds.persistence.exists
entity SchedulerApiConfigUsers : cuid {
    ApiUser     : String;
    ApiPassword : String;
}

// Scheduler oauth configuration
@cds.persistence.exists
entity SchedulerApiConfigOAuth : cuid {
    OAuthProvider : String;
    GrantType     : String;
    ClientID      : String;
    ClientSecret  : String;
}

@cds.persistence.exists
entity SchedulerJobConfig: cuid , managed{
    JobName : String;
    JobTime : String;
}

// entity SchedulerJobs: cuid {
//     JobName          : String;
//     StartedAt        : Timestamp;
//     FinishedAt       : Timestamp;
//     Status           : String;
// }

@cds.persistence.exists
entity SchedulerErrorLog: cuid {
    JobName          : String;
    JobDescription   : String;
    ErrorMessage     : String;
    ResourceURL      : String;
    ConsultationDate : Timestamp;
}

// Settings for the OfferValidity
@cds.persistence.exists
entity NextDateSettings {
    CurrentMonth      : Integer;
    NextDay           : Integer;
    NextMonth         : Integer;
    NextYearDelta     : Integer;
}


// entity ExcelAttachment {
//     key template : String(100);
//     key OfferId : String(50);
//     content   : LargeBinary @Core.MediaType: mediaType;//'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
//     mediaType:String @Core.IsMediaType;
// }

// @cds.persistence.exists
//@cds.persistence.exists
//entity WordAttachment {
//     key template : String(100);
//     key OfferId : String(50);
//     key CountryCode    : String;
//     content   : LargeBinary @Core.MediaType: mediaType;//'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
//     mediaType:String @Core.IsMediaType;
// }

@cds.persistence.exists
entity WordTemplateCountry {
    key countryCode    : String;
    key templateId     : Integer;
        WordTemplates      : Association to WordTemplate
                            on WordTemplates.templateId = templateId; //This can be found in OData
}

@cds.persistence.exists
entity WordTemplate {
    key templateId     : Integer;
    name:String(100);
    filename:String(250);
    content   : LargeBinary @Core.MediaType: mediaType;//'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    mediaType:String @Core.IsMediaType;
}

@cds.persistence.exists
entity ExcelTemplateCountry {
    key countryCode    : String;
    key templateId     : Integer;
        ExcelTemplates      : Association to ExcelTemplate
                            on ExcelTemplates.templateId = templateId; //This can be found in OData
}

@cds.persistence.exists
entity ExcelTemplate {
    key templateId     : Integer;
    name:String(100);
    filename:String(250);
    content   : LargeBinary @Core.MediaType: mediaType;//'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    mediaType:String @Core.IsMediaType;
}

@cds.persistence.exists
entity ContractStatus: cuid {
    Status: String(200);
}

@cds.persistence.exists
entity SalesOrderStatus: cuid {
    Status: String(200);
}