/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 12-08-2021
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
        String debug = '';
        
        try {        
            SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, scope);
            List<List_View__c> listViews = (List<List_View__c>) dec.getRecords();
            Map<String, List_View__c> deletedListViews = new Map<String, List_View__c>();
            Map<String, List_View_Config__c> deletedLVConfigs = new Map<String, List_View_Config__c>();
            List<List_View_Config_Condition__c> deletedLVConfigConds = new List<List_View_Config_Condition__c>();
            List<List_View_Config_Parameter__c> deletedLVConfigParams = new List<List_View_Config_Parameter__c>();
            List<List_View_User_Config__c> deletedUserConfigs = new List<List_View_User_Config__c>();

            //get the set of core list view Ids
            Set<Id> coreListViewIDs = HelperCollection.getIdFieldSet(listViews, 'Core_ListView_Id__c');

            //get the associated core list views
            List<ListView> coreListViews = ListViewHelper.getCoreListViews(coreListViewIDs);
            //get map of core list views
            Map<Id, ListView> coreListViewsById = new Map<Id, ListView>(coreListViews);

            //go through SLV list views looking for ones that have deleted core list view Ids
            for (List_View__c listView: listViews)
            {
                //if a core list view does not exist for the id then delete it
                if (!coreListViewsById.containsKey(listView.Core_ListView_Id__c))
                {
                    deletedListViews.put(listView.Primary_Key__c, listView);
                    debug += 'Deleting list view - ' + listView.Primary_Key__c + '\n';
                }
            }

            //find all list view configs/conditions/parameters
            if (deletedListViews.size() > 0)
            {
                //get all configs for the list views to be deleted
                deletedLVConfigs = ListViewConfigHelper.getListViewConfigs(deletedListViews.keySet());
                
                for (List_View_Config__c lvConfig: deletedLVConfigs.values())
                {
                    debug += 'Deleting list view config - ' + lvConfig.Primary_Key__c + '\n';
                
                    deletedLVConfigConds.addAll(lvConfig.List_View_Config_Conditions__r);

                    deletedLVConfigParams.addAll(lvConfig.List_View_Config_Parameters__r);
                }
            } else {
                debug += 'No list views or configs deleted\n';
            }

            if (deletedLVConfigs.size() > 0)
            {
                //use primary keys to find the user configs
                String userConfSOQL = 'SELECT Id, Name__c, Value__c, Primary_Key__c FROM List_View_User_Config__c WHERE ';
                for (String tmpPKey: deletedLVConfigs.keySet())
                {
                    userConfSOQL += 'Name__c LIKE \'%' + tmpPKey + '%\' OR ';
                    userConfSOQL += 'Primary_Key__c LIKE \'%' + tmpPKey + '%\' OR ';
                    userConfSOQL += 'Value__c LIKE \'%' + tmpPKey + '%\' OR ';
                }

                userConfSOQL = userConfSOQL.removeEnd(' OR ');

                System.debug(LoggingLevel.FINE, 'CONF SOQL - ' + userConfSOQL);
                
                SObjectAccessDecision dec2 = 
                    Security.stripInaccessible(AccessType.READABLE,
                        Database.query(userConfSOQL));

                deletedUserConfigs = (List<List_View_User_Config__c>) dec2.getRecords();

                for (List_View_User_Config__c userConfig: deletedUserConfigs)
                    debug += 'Deleting user config - ' + userConfig.Name__c + '/' + userConfig.Value__c + '\n';

            }


            HelperDatabase.deleteRecords(deletedListViews.values(), 'simpli_lv__List_View__c');
            HelperDatabase.deleteRecords(deletedLVConfigConds, 'simpli_lv__List_View_Config_Condition__c');
            HelperDatabase.deleteRecords(deletedLVConfigParams, 'simpli_lv__List_View_Config_Parameter__c');
            HelperDatabase.deleteRecords(deletedLVConfigs.values(), 'simpli_lv__List_View_Config__c');
            HelperDatabase.deleteRecords(deletedUserConfigs, 'simpli_lv__List_View_User_Config__c');

        } catch (Exception e) {
            String message = 'Exception during ListViewCleanBatch.execute()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(message); 
        }

        System.debug(LoggingLevel.DEBUG, debug);
        ListViewErrorHelper.addLog('ListViewCleanBatch(start)', debug);

        ListViewErrorHelper.processLogs(false);

	}
	
	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */ 
	public void finish(Database.BatchableContext BC) 
	{
	}

}