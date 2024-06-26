using {com.bayer.SXTENDER.AdminData} from '../db/AdminData';
using {
    User,
    Country,
    managed,
    cuid
} from '@sap/cds/common';

service SchedulerService @(path : 'scheduler')@(requires : ['authenticated-user']) {
    type Job {
        Name  : String;
        JobTime: String;
        Status: String;
    };
    entity SchedulerJobConfig as projection on AdminData.SchedulerJobConfig;
    function SystemJobs() returns array of Job;
    action ManageJob( Action:String, JobName:String ) returns array of Job;
}
