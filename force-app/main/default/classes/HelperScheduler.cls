/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 12-01-2021
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class HelperScheduler {

    public static final String SCHED_NAME_PREFIX = 'SLV Reprocess List Views';
    public static final String NOT_SCHEDULED = 'Not Scheduled';

    public static List<AsyncApexJob> getCurrentlyRunningJobs() 
    {
        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT TotalJobItems, 
                        Status, 
                        NumberOfErrors, 
                        MethodName, 
                        JobType, 
                        JobItemsProcessed,
                        ApexClass.Name,
                        Id 
                FROM AsyncApexJob 
                WHERE ApexClass.Name IN ('ListViewPostProcessBatch', 'ListViewProcessBatch', 'ListViewPreProcessBatch')
                        AND Status NOT IN ('Completed', 'Scheduled')]);

        return (List<AsyncApexJob>) dec.getRecords();
    }

    public static void unscheduleRefreshJobs()
    {
        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Id 
                    FROM CronTrigger 
                    WHERE CronJobDetail.Name LIKE :SCHED_NAME_PREFIX+'%']);

        List<CronTrigger> jobs = (List<CronTrigger>) dec.getRecords();
        
        for (CronTrigger job: jobs)
            System.abortJob(job.Id);

    }

    public static Boolean scheduleRefreshJob()
    {
        Boolean isScheduled = true;

        //get the org wide config
        String refreshJobConfig = ListViewConfigHelper.getOrgWideConfigParam('RefreshJob');

        //UNSCHEDULE JOB
        if (String.isEmpty(refreshJobConfig) || refreshJobConfig == NOT_SCHEDULED)
        {
            unscheduleRefreshJobs();
            
        //SCHEDULE JOB
        } else {

            List<String> jobValues = refreshJobConfig.split(':');

            //[0] = time period
            //[1] = (minutely) selected X minutes, (all others) selected minute
            //[2] = (daily, weekly, monthly) selected hour in day
            //[3] = (weekly) selected day in week, (monthly) selected day in month

            String timePeriod = jobValues[0];
            String cronStr = '';

            //String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;

            if (timePeriod == 'minutely') //POSSIBLE VALUES ARE 5,10,15,20,30
            {
                System.schedule(SCHED_NAME_PREFIX + ' 0', '0 00 * * * ?', new ListViewProcessScheduled());

                //30
                if (jobValues[1] == '5' || jobValues[1] == '10' || jobValues[1] == '15' || jobValues[1] == '30')
                    System.schedule(SCHED_NAME_PREFIX + ' 30', '0 30 * * * ?', new ListViewProcessScheduled());

                //20
                if (jobValues[1] == '5' || jobValues[1] == '10' || jobValues[1] == '20')
                {
                    System.schedule(SCHED_NAME_PREFIX + ' 20', '0 20 * * * ?', new ListViewProcessScheduled());
                    System.schedule(SCHED_NAME_PREFIX + ' 40', '0 40 * * * ?', new ListViewProcessScheduled());
                }

                //15
                if (jobValues[1] == '5' || jobValues[1] == '15')
                {
                    System.schedule(SCHED_NAME_PREFIX + ' 15', '0 15 * * * ?', new ListViewProcessScheduled());
                    System.schedule(SCHED_NAME_PREFIX + ' 45', '0 45 * * * ?', new ListViewProcessScheduled());
                }

                //10
                if (jobValues[1] == '5' || jobValues[1] == '10')
                {
                    System.schedule(SCHED_NAME_PREFIX + ' 10', '0 10 * * * ?', new ListViewProcessScheduled());
                    System.schedule(SCHED_NAME_PREFIX + ' 50', '0 50 * * * ?', new ListViewProcessScheduled());
                }

                //5
                if (jobValues[1] == '5')
                {
                    System.schedule(SCHED_NAME_PREFIX + ' 5', '0 5 * * * ?', new ListViewProcessScheduled());
                    System.schedule(SCHED_NAME_PREFIX + ' 25', '0 25 * * * ?', new ListViewProcessScheduled());
                    System.schedule(SCHED_NAME_PREFIX + ' 35', '0 35 * * * ?', new ListViewProcessScheduled());
                    System.schedule(SCHED_NAME_PREFIX + ' 55', '0 55 * * * ?', new ListViewProcessScheduled());
                }

            } else {
                
                if (timePeriod == 'hourly')
                    cronStr = '0 ' + jobValues[1] + ' * * * ?';
                else if (timePeriod == 'daily')
                    cronStr = ' 0 ' + jobValues[1] + ' ' + jobValues[2] + ' * * ?';
                else if (timePeriod == 'weekly')
                    cronStr = '0 ' + jobValues[1] + ' ' + jobValues[2] + ' ? * ' + jobValues[3] + ' *';
                else if (timePeriod == 'monthly')
                    cronStr = '0 ' + jobValues[1] + ' ' + jobValues[2] + ' ' + jobValues[3] + ' * ? *';

                System.schedule(SCHED_NAME_PREFIX, cronStr, new ListViewProcessScheduled());
            }
        }

        return isScheduled;
    }

}