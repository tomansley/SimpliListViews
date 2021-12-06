/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 12-06-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   tom@ansleyllc.com   Initial Version
 * 2.0   07-12-2021   tom@ansleyllc.com   Added setting of org wide config to identify that the list views have been initialized.
**/
global with sharing class ListViewPreProcessBatch implements Database.AllowsCallouts, Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    private String query = 'SELECT Id, Name, SObjectType, DeveloperName, NamespacePrefix, CreatedById FROM ListView WHERE SObjectType != null';
    private final Integer batchSize             = 25;
    private Set<Id> listViewIds                 = null;

    /*
        Simpli_lv.ListViewPreProcessBatch b = new Simpli_lv.ListViewPreProcessBatch();
        b.execute(null);
    */
    global ListViewPreProcessBatch() {
    }

	/* IMPLEMENTS SCHEDULABLE INTERFACE */
	global void execute(SchedulableContext sc)
	{
		database.executebatch(this, batchSize);
	}
       
	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
        //finally set isInitialized to true.
        ListViewConfigHelper.setOrgWideConfigParam('IsInitialized', 'false');

        Database.QueryLocator locator = null;
        try {

            //never get the excluded objects
            String exclObjs = ListViewConfigHelper.getOrgWideConfigParam('ExcludedObjectTypes');
            Set<String> orgWideExcObjs = HelperString.getSetFromString(exclObjs, ',');
            
            if (!orgWideExcObjs.isEmpty())
                query += ' AND SObjectType NOT IN :orgWideExcObjs';

            if (listViewIds != null && listViewIds.size() > 0)
                query += ' AND Id IN :listViewIds';

            if (Test.isRunningTest())
                query += ' LIMIT 1';

            String debug = 'SOQL - ' + query;
            debug += 'Exc Objs - ' + HelperString.getStringFromSet(orgWideExcObjs, ',');
            
            System.debug(LoggingLevel.DEBUG, debug);
            ListViewErrorHelper.addLog('ListViewPreProcessBatch(start)', debug);

            ListViewErrorHelper.processLogs(false);

            return Database.getQueryLocator(query);

        } catch (Exception e) {
            String message = 'Exception during ListViewPreProcessBatch.start(' + query + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(message);
        }
                
        ListViewErrorHelper.processLogs(false);

        return null;
	}

	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
	global void execute(Database.BatchableContext BC, List<SObject> scope) 
	{
        try {        
            SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, scope);
            List<ListView> listViews = (List<ListView>) dec.getRecords();

        } catch (Exception e) {
            String message = 'Exception during ListViewPreProcessBatch.execute()  ' + ListViewException.getExtendedString(e);

            ListViewErrorHelper.createNonFutureUsageError(message); 
        }


	}
	
	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */ 
	global void finish(Database.BatchableContext BC) 
	{
        ListViewProcessBatch job = new ListViewProcessBatch();
        job.execute(null);
	}
	
	global class ListViewProcessBatchException extends Exception { }

}