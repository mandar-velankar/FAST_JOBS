namespace com.bayer.SXTENDER.BankGuaranteeData;

using {
    User,
    Country,
    managed, 
    cuid
} from '@sap/cds/common';
using {com.bayer.SXTENDER.TransactionalData} from './TransactionalData';
using {com.bayer.SXTENDER.AdminDataViews} from './AdminDataViews';
using {com.bayer.SXTENDER.PriceAgreementDataViews} from './PriceAgreementDataViews';



@cds.persistence.exists
entity BankGuarantees: cuid, managed {
    TenderID: String;
    CountryCode: String;
    Reference: String;
    IssueDate: DateTime;
    ClosingDate: DateTime;
    ExpectedExpiryDate: DateTime;
    Status:  String;
    BankStatus: String; //Status field for Spain
    BankName:String;//added this field for Spain
    BankRequestDate:DateTime;//added this field for Spain
    ShippingDate:DateTime;//added this field for Spain
    Type: String;
    GuaranteedAmount: Double;
    Currency: String;
    Comment: String;
    Tender: Association to TransactionalData.PT_TMTEND on Tender.TenderID = TenderID;
    PriceAgreement: Association to PriceAgreementDataViews.PriceAgreementExpiryDate on PriceAgreement.TenderId = TenderID;
}