namespace com.bayer.SXTENDER.PricingAppData;

using { User, Country, managed } from '@sap/cds/common';
using { com.bayer.SXTENDER.MasterData } from './MasterData';

//Master Data (institutes groups tables)
entity InstituteGroup{
	key Id:Integer;
    CountryCode:String;
    Channel:String(50);
	Name:String(50);
	//Associations
    Country:Association[1] to MasterData.PT_TMCTRY on Country.CountryCode = CountryCode;
    Institutes:Association[*] to InstituteGroupInstitute on Institutes.InstituteGroup = $self;
}

entity InstituteGroupInstitute{
    key InstituteGroupId:Integer;
    key InstituteId:Integer;
    //Associations
    InstituteGroup:Association[1] to InstituteGroup on InstituteGroup.Id = InstituteGroupId;
    Institute:Association[1] to MasterData.PT_TMINST on Institute.InstituteID = InstituteId;
}

//Price Data (problem with on identified??? as on unmanaged association)
//---Table: all data
entity InstituteGroupPrice{
    key InstituteGroupId:Integer;
    key ProductPackId:Integer;
    key EffectiveDate:DateTime;
    UoM:String(4);
    Currency:String(3);
    MSP:Double;
    NSP:Double;
    //Associations
    InstituteGroup:Association[1] to InstituteGroup on InstituteGroup.Id = InstituteGroupId;
    ProductPack:Association[1] to MasterData.PT_TMPRDPCK on ProductPack.PRODUCTPACKID = ProductPackId;
}

entity ApprovalStatus {
    key CountryCode         : String;
    key InstituteGroupId    : Integer;
    key ProductPackId       : Integer;
    key ApproverEmailId     : String(100);
    key ApproverType        : String(30);
    key StatusTime          : DateTime;
    key Division            : String(200);
        ApproverTypeSection : Integer;
        ApprovalStatus      : String(100);
        SenderComment       : String(500);
        ApproverComment     : String(500);
        SentBy              : String(100);
        ApprovalDate        : Date;
        FlowId              : String(255);
        RequiredAction      : String(12);
        //Associations
        CountryApprover     : Association to many CountryApprovers
                                  on CountryApprover.CountryCode = CountryCode
                                  and CountryApprover.ApproverType = ApproverType
                                  and CountryApprover.ApproverEmailId = ApproverEmailId
                                  and CountryApprover.Division = Division;
}

entity CountryApprovers{
	key CountryCode         : String;
	key ApproverType        : String(200);
	key Division            : String(200);
    key ApproverEmailId     : String(200);
	    ApproverName        : String(200);
}


//---Views: latest data
entity MostRecentInstituteGroupPrice as select from InstituteGroupPrice as igp{
    igp.InstituteGroupId,
    igp.ProductPackId,
    max(igp.EffectiveDate) as MaxEffectiveDate:DateTime
}group by igp.InstituteGroupId, igp.ProductPackId;

entity InstituteGroupPriceLatest as select from InstituteGroupPrice as igp
inner join MostRecentInstituteGroupPrice as l
    on igp.InstituteGroupId = l.InstituteGroupId
    and igp.ProductPackId = l.ProductPackId
    and igp.EffectiveDate = l.MaxEffectiveDate
{
    key igp.InstituteGroupId,
    key igp.ProductPackId,
    igp.UoM,
    igp.Currency,
    igp.MSP,
    igp.NSP,
    igp.InstituteGroup,
    igp.ProductPack,
    'Approved' as Status:String(50)
};


// Latest Approvals 
entity LatestApprovalRequests as select from ApprovalStatus as approvals{
    key approvals.CountryCode,
    key approvals.InstituteGroupId,
    key approvals.ProductPackId,
    key approvals.ApproverEmailId,
    key approvals.ApproverType,
    key approvals.Division,
    max(approvals.StatusTime) as MaxStatusTime:DateTime
}
group by approvals.CountryCode,
    approvals.InstituteGroupId,
    approvals.ProductPackId,
    approvals.ApproverEmailId,
    approvals.ApproverType,
    approvals.Division;

entity ApprovalRequests as select from ApprovalStatus as approvals
inner join LatestApprovalRequests as latestApprovals
    on approvals.CountryCode = latestApprovals.CountryCode 
    and approvals.InstituteGroupId = latestApprovals.InstituteGroupId 
    and approvals.ApproverEmailId = latestApprovals.ApproverEmailId
    and approvals.ApproverType = latestApprovals.ApproverType
    and approvals.Division = latestApprovals.Division
    and approvals.StatusTime = latestApprovals.MaxStatusTime 
{
    key approvals.CountryCode,
    key approvals.InstituteGroupId,
    key approvals.ProductPackId,
    key approvals.ApproverEmailId,
    key approvals.ApproverType,
    key approvals.StatusTime,
    key approvals.Division,
    approvals.ApproverTypeSection,
    approvals.ApprovalStatus,
    approvals.SenderComment,
    approvals.ApproverComment,
    approvals.SentBy,
    approvals.ApprovalDate,
    approvals.FlowId,
    approvals.RequiredAction,
    CountryApprover
};