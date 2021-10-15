/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 10-14-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   tom.h.ansley@medtronic.com   Initial Version
 * 2.0   07-12-2021   tom.h.ansley@medtronic.com   Added setting of org wide config to identify that the list views have been initialized.
**/
global with sharing class ListViewPreProcessBatch implements Database.AllowsCallouts, Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    private String query = 'SELECT Id, Name, SObjectType, DeveloperName, NamespacePrefix, CreatedById FROM ListView WHERE SObjectType != null';
    private final Integer batchSize = 25;
    private Set<Id> listViewIds = null;

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

            System.debug(LoggingLevel.FINE, 'SOQL - ' + query);
            System.debug(LoggingLevel.FINE, 'Exc Objs - ' + HelperString.getStringFromSet(orgWideExcObjs, ','));
            
            HelperSchema.checkSelectAccessible(query);

            return Database.getQueryLocator(query);

        } catch (Exception e) {
            String message = 'Exception 2 during ListViewPreProcessBatch.start(' + query + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createUsageErrorNonFuture(message);
            Database.setSavepoint();
        }
                
        return null;
	}

	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
	global void execute(Database.BatchableContext BC, List<SObject> scope) 
	{
        try {
            System.debug(LoggingLevel.FINE, 'Test1');
            List<List_View__c> simpliListViews = new List<List_View__c>();
            List<List_View_Config__c> simpliListViewConfigs = new List<List_View_Config__c>();
        
            List<ListView> listViews = (List<ListView>) scope;

            //--------------------------------------------------------------------------------
            //this is to handle the issue where names do not include package names. 10-13-2021
            //--------------------------------------------------------------------------------
            System.debug(LoggingLevel.FINE, 'Test2');
            Map<Id, ListView> tmpListViewsMap = new Map<Id, ListView>();
            for (ListView lv: listViews)
                tmpListViewsMap.put(lv.Id, lv);
            System.debug(LoggingLevel.FINE, 'Test3');

            List<List_View__c> tmpListViews = [SELECT Id, Name, Primary_Key__c, Core_ListView_Id__c FROM List_View__c WHERE Core_ListView_Id__c IN :tmpListViewsMap.keySet()];
            System.debug(LoggingLevel.FINE, 'Test4');

            //get the list views set of primary keys
            Set<String> listViewPKeys = new Set<String>();
            for (List_View__c tmpListView: tmpListViews)
                listViewPKeys.add(tmpListView.Primary_Key__c);
            System.debug(LoggingLevel.FINE, 'Test5');

            String debug1 = '\n\n----------- PRIMARY KEYS -----------------------------------------------------------\n';
            for (String tmpKey: listViewPKeys)
                debug1 += tmpKey + '\n';
            debug1 += '----------------------------------------------------------------------\n';
            System.debug(LoggingLevel.FINE, debug1);

            //use primary keys to find the configs
            List<List_View_Config__c> tmpListViewConfigs = [SELECT Id, Name, Primary_Key__c FROM List_View_Config__c WHERE Primary_Key__c IN :listViewPKeys];
            System.debug(LoggingLevel.FINE, 'Test6');

            //create map of configs based on primary keys for easy access
            Map<String, List_View_Config__c> tmpListViewsConfigMap = new Map<String, List_View_Config__c>();
            for (List_View_Config__c tmpListViewConfig: tmpListViewConfigs)
                tmpListViewsConfigMap.put(tmpListViewConfig.Primary_Key__c, tmpListViewConfig);

            System.debug(LoggingLevel.FINE, 'Test7');
                //use primary keys to find the user configs
            String userConfSOQL = 'SELECT Id, Name__c, Value__c, Primary_Key__c FROM List_View_User_Config__c WHERE ';
            for (String tmpPKey: listViewPKeys)
            {
                userConfSOQL += 'Name__c LIKE \'%' + tmpPKey + '%\' OR ';
                userConfSOQL += 'Primary_Key__c LIKE \'%' + tmpPKey + '%\' OR ';
                userConfSOQL += 'Value__c LIKE \'%' + tmpPKey + '%\' OR ';
            }

            userConfSOQL = userConfSOQL.removeEnd(' OR ');

            System.debug(LoggingLevel.FINE, 'CONF SOQL - ' + userConfSOQL);
            List<List_View_User_Config__c> tmpUserConfigs = Database.query(userConfSOQL);
            
            debug1 = '\n\n-----------USER CONFS -----------------------------------------------------------\n';
            for (List_View_User_Config__c tmpUserConfig: tmpUserConfigs)
                debug1 += tmpUserConfig.Name__c + ' - ' + tmpUserConfig.Primary_Key__c + ' - ' + tmpUserConfig.Value__c + '\n';
            debug1 += '----------------------------------------------------------------------\n';
            System.debug(LoggingLevel.FINE, debug1);

            //create map of user configs based on primary keys for easy access
            Map<String, List<List_View_User_Config__c>> tmpUserConfigMap = new Map<String, List<List_View_User_Config__c>>();
            for (List_View_User_Config__c tmpUserConfig: tmpUserConfigs)
            {
                for (String tmpPrimaryKey: listViewPKeys)
                {
                    List<List_View_User_Config__c> tmpUserConfigList = tmpUserConfigMap.get(tmpPrimaryKey);
                    if (tmpUserConfigList == null)
                    {
                        tmpUserConfigList = new List<List_View_User_Config__c>();
                        tmpUserConfigMap.put(tmpPrimaryKey, tmpUserConfigList);
                    }

                    if (tmpUserConfig.Name__c.contains(tmpPrimaryKey) 
                        || tmpUserConfig.Value__c.contains(tmpPrimaryKey)
                        || tmpUserConfig.Primary_Key__c.contains(tmpPrimaryKey))
                    {
                        tmpUserConfigList.add(tmpUserConfig);
                    }
                }
            }


            System.debug(LoggingLevel.FINE, 'Test7');

            for (List_View__c tmpListView: tmpListViews)
            {
                //get the standard ListView
                ListView lv = tmpListViewsMap.get(tmpListView.Core_ListView_Id__c);

                String oldPrimaryKey = tmpListView.Primary_Key__c;

                //get the list views config
                List_View_Config__c tmpListViewConfig = tmpListViewsConfigMap.get(oldPrimaryKey);

                //get the user configs
                List<List_View_User_Config__c> tmpUserConfigList = tmpUserConfigMap.get(oldPrimaryKey);

                //set the CORRECT API Name
                String apiName = lv.DeveloperName;
                if (!String.isEmpty(lv.NamespacePrefix))
                    apiName = lv.NamespacePrefix + '__' + apiName;

                //update list views API name and primary key
                tmpListView.API_Name__c = apiName;
                tmpListView.Primary_Key__c           = lv.SObjectType + ':' + apiName;

                //update the list view config name and primary key
                if (tmpListViewConfig != null)
                {
                    tmpListViewConfig.Name = tmpListView.API_Name__c;
                    tmpListViewConfig.Primary_Key__c = tmpListView.Primary_Key__c;
                }

                if (tmpUserConfigList != null)
                {
                    for (List_View_User_Config__c tmpUserConfig: tmpUserConfigList)
                    {
                        tmpUserConfig.Name__c        = tmpUserConfig.Name__c.replace(oldPrimaryKey, tmpListViewConfig.Primary_Key__c);
                        tmpUserConfig.Value__c       = tmpUserConfig.Value__c.replace(oldPrimaryKey, tmpListViewConfig.Primary_Key__c);
                        tmpUserConfig.Primary_Key__c = tmpUserConfig.Primary_Key__c.replace(oldPrimaryKey, tmpListViewConfig.Primary_Key__c);
                    }
                }

            }

            String debug = '\n\n----------------------------------------------------------------------\n';
            for (List_View__c tmpListView: tmpListViews)
                debug += tmpListView.Name + ' - ' + tmpListView.Primary_Key__c + '\n';
            debug += '----------------------------------------------------------------------\n';

            debug += '\n\n----------------------------------------------------------------------\n';
            for (List_View_Config__c tmpListViewConfig: tmpListViewConfigs)
                debug += tmpListViewConfig.Name + ' - ' + tmpListViewConfig.Primary_Key__c + '\n';
            debug += '----------------------------------------------------------------------\n';

            debug += '\n\n----------------------------------------------------------------------\n';
            for (List_View_User_Config__c tmpUserConfig: tmpUserConfigs)
                debug += tmpUserConfig.Name__c + ' - ' + tmpUserConfig.Primary_Key__c + ' - ' + tmpUserConfig.Value__c + '\n';
            debug += '----------------------------------------------------------------------\n';

            System.debug(LoggingLevel.FINE, debug);
            HelperDatabase.updateRecords(tmpUserConfigs, 'Simpli_lv__List_View_User_Config__c');
            HelperDatabase.updateRecords(tmpListViewConfigs, 'Simpli_lv__List_View_Config__c');
            HelperDatabase.updateRecords(tmpListViews, 'Simpli_lv__List_View__c');

        } catch (Exception e) {
            String message = 'Exception during ListViewPreProcessBatch.execute()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createUsageErrorNonFuture(message); 
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