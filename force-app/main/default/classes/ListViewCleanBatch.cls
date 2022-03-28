/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 03-28-2022
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   12-06-2021   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewCleanBatch implements Database.AllowsCallouts, Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    private String query = 'SELECT Id, Core_ListView_Id__c, Primary_Key__c FROM List_View__c WHERE RecordType.Name = \'Core\'';
    private final Integer batchSize             = 25;

    /*
        ListViewCleanBatch b = new ListViewCleanBatch();
        b.execute(null);
    */
    public ListViewCleanBatch() {
    }

	/* IMPLEMENTS SCHEDULABLE INTERFACE */
	public void execute(SchedulableContext sc)
	{
		database.executebatch(this, batchSize);
	}
       
	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
	public Database.QueryLocator start(Database.BatchableContext BC) 
	{
        if (Test.isRunningTest())
            query += ' LIMIT 25';

        String debug = 'SOQL - ' + query;
        
        System.debug(LoggingLevel.DEBUG, debug);
        ListViewErrorHelper.addLog('ListViewCleanBatch(start)', debug);

        ListViewErrorHelper.processLogs(false);

        return Database.getQueryLocator(query);

	}

	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
	public void execute(Database.BatchableContext BC, List<SObject> scope) 
	{
        ListViewHelper.cleanListViews((List<List_View__c>) scope);
	}
	
	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */ 
	public void finish(Database.BatchableContext BC) 
	{
        //delete all list views that are EXCLUDED from being displayed
        //but may have been created at another time
        Database.executeBatch(new ListViewPostProcessBatch(), 40);
	}

}