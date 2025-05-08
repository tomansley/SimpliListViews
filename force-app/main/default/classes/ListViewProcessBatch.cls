/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 05-08-2025
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   08-05-2020   tom@ansleyllc.com   Initial Version
 * 2.0   07-12-2021   tom@ansleyllc.com   Added setting of org wide config to identify that the list views have been initialized.
**/
global with sharing class ListViewProcessBatch implements Database.AllowsCallouts, Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    public static final String TYPE_ALL = 'all';
    public static final String TYPE_PERIOD = 'period';

    private String query = 'SELECT Id, Name, SObjectType, DeveloperName, NamespacePrefix, CreatedById FROM ListView WHERE SObjectType != null';
    private Integer batchSize = 40;
    private Set<Id> listViewIds = null;
    private String processType = TYPE_ALL;

    /*
        Simpli_lv.ListViewProcessBatch b = new Simpli_lv.ListViewProcessBatch();
        b.execute(null);
    */
    global ListViewProcessBatch() {
    }

    /*
     * Constructor used to only process those list views who's Ids are provided.
       Set<Id> ids = new Set<Id>{'00B3h000007cUeiEAE'};
       ListViewProcessBatch job = new ListViewProcessBatch(ids);
       Database.executeBatch(job);
     */
    global ListViewProcessBatch(Set<Id> listViewIds)
    {
        this.listViewIds = listViewIds;
    }

    global ListViewProcessBatch(String processType)
    {
        this.processType = processType;
    }

	/* IMPLEMENTS SCHEDULABLE INTERFACE */
	global void execute(SchedulableContext sc)
	{
        String procSize = ListViewConfigHelper.getOrgWideConfigParam('ProcessingSize', '20');

        if (!String.isEmpty(procSize))
            batchSize = Integer.valueOf(procSize);

		database.executebatch(this, batchSize);
	}
       
	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
        Database.QueryLocator locator = null;
        try {

            //------------------------------------------------------------------------
            //if there are included objects then only process those
            //------------------------------------------------------------------------
            String inclObjs = ListViewConfigHelper.getOrgWideConfigParam('IncludedObjectTypes', '');
            Set<String> orgWideIncObjs = HelperString.getSetFromString(inclObjs, ',');
            Set<String> orgWideExcObjs = new Set<String>();
            
            if (!orgWideIncObjs.isEmpty())
            {
                query += ' AND SObjectType IN :orgWideIncObjs';
            
            //only worry about excluded objects if there are no included objects
            } else { 

                //------------------------------------------------------------------------
                //never get the excluded objects
                //------------------------------------------------------------------------
                String exclObjs = ListViewConfigHelper.getOrgWideConfigParam('ExcludedObjectTypes', '');
                orgWideExcObjs = HelperString.getSetFromString(exclObjs, ',');
                
                if (!orgWideExcObjs.isEmpty())
                    query += ' AND SObjectType NOT IN :orgWideExcObjs';
            }

            //------------------------------------------------------------------------
            //always exclude list views to be excluded by admin param
            //------------------------------------------------------------------------
            List<String> excStrings = ListViewConfigHelper.getOrgWideConfigParam('ExcludedListViews', '').split('\\|');

            if (excStrings.size() == 1 && excStrings[0] != '') {

                query += ' AND (NOT DeveloperName LIKE \'%' + excStrings[0] + '%\') ';
            
            } else if (excStrings.size() > 1)  {
                query += ' AND (';
                for (String excString: excStrings)
                    query += '(NOT DeveloperName LIKE \'%' + excString + '%\') OR ';
                query = query.removeEnd(' OR ') + ') ';
            }

            //------------------------------------------------------------------------
            //if list view Ids have been provided then add them
            //------------------------------------------------------------------------
            if (listViewIds != null && listViewIds.size() > 0)
                query += ' AND Id IN :listViewIds';

            //------------------------------------------------------------------------
            //if we are querying for a specific period (scheduled update)
            //------------------------------------------------------------------------
            if (processType == TYPE_PERIOD) {
                
                String refreshJobConfig = ListViewConfigHelper.getOrgWideConfigParam('RefreshJob', 'Not Scheduled');

                if (!String.isEmpty(refreshJobConfig) && refreshJobConfig == HelperScheduler.NOT_SCHEDULED)
                {
                    List<String> jobValues = refreshJobConfig.split(':');

                    String timePeriod = jobValues[0];
                    DateTime dte = null;

                    if (timePeriod == 'minutely')
                        dte = System.now().addMinutes(-Integer.valueOf(jobValues[1]));
                    else if (timePeriod == 'hourly')
                        dte = System.now().addHours(-1);
                    else if (timePeriod == 'daily') 
                        dte = System.now().addDays(-1);
                    else if (timePeriod == 'weekly') 
                        dte = System.now().addHours(-7);
                    else
                        dte = System.now().addHours(-30);
                
                    query += ' AND LastModifiedDate > ' + HelperDate.getSOQLDateTime(dte);

                }
        
            }

            if (Test.isRunningTest())
                query += ' LIMIT 1';

            String debug = 'SOQL - ' + query;
            debug += 'Inc Objs - ' + HelperString.getStringFromSet(orgWideIncObjs, ',') + '\n';
            debug += 'Exc Objs - ' + HelperString.getStringFromSet(orgWideExcObjs, ',') + '\n';
            debug += 'Exc LVs - ' + HelperString.getStringFromList(excStrings, ',') + '\n';
            
            ListViewErrorHelper.addLog('ListViewProcessBatch(start)', debug);

            ListViewErrorHelper.processLogs(false);

            return Database.getQueryLocator(query);

        } catch (Exception e) {
            String message = 'Exception 2 during ListViewProcessBatch.start(' + query + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(message);
        }
                
        return null;
	}

	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
	global void execute(Database.BatchableContext BC, List<SObject> scope) 
	{
        try {
            ListViewHelper.updateListViewsFromCore((List<ListView>) scope);

            ListViewErrorHelper.processLogs(false);

        } catch (Exception e) {
            String message = 'Exception during ListViewProcessBatch.execute()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(message); 
        }
	}
	
	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */ 
	global void finish(Database.BatchableContext BC) 
	{
        //delete all list views that are EXCLUDED from being displayed
        //but may have been created at another time
        Database.executeBatch(new ListViewCleanBatch(), 40);
	}
	
	global class ListViewProcessBatchException extends Exception { }

}