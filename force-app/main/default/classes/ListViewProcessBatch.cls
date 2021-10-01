/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 09-27-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   tom.h.ansley@medtronic.com   Initial Version
 * 2.0   07-12-2021   tom.h.ansley@medtronic.com   Added setting of org wide config to identify that the list views have been initialized.
**/
global with sharing class ListViewProcessBatch implements Database.AllowsCallouts, Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    private String query = 'SELECT Id, Name, SObjectType, DeveloperName, CreatedById FROM ListView WHERE SObjectType != null';
    private final Integer batchSize = 50;
    private Set<Id> listViewIds = null;

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
            String message = 'Exception during ListViewProcessBatch.start(' + query + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createUsageErrorNonFuture(message);
            Database.setSavepoint();
        }
                
        return null;
	}

	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
	global void execute(Database.BatchableContext BC, List<SObject> scope) 
	{
        try {
            List<List_View__c> simpliListViews = new List<List_View__c>();
            List<List_View_Config__c> simpliListViewConfigs = new List<List_View_Config__c>();
        
            List<ListView> listViews = (List<ListView>) scope;

            Set<String> sObjectSet = new Set<String>();
            for (ListView listView: listViews)
            {

                System.debug(LoggingLevel.DEBUG, 'Getting ListView - ' + listView);

                if (String.isEmpty(listView.SObjectType) || String.isEmpty(listView.Id)) continue;

                //create URL to find the list view query
                String endPoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v50.0/sobjects/' + listView.SObjectType + '/listviews/' + listView.Id + '/describe';
                
                //get list view describe
                String callResponse = HelperREST.performInternalCallout(endPoint, null);

                //turn JSON string into map
                try {
                    Map<String,Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(callResponse);

                    List_View__c simpliListView = new List_View__c();
                    simpliListView.API_Name__c              = listView.DeveloperName;
                    simpliListView.Object_Name__c           = listview.SObjectType;
                    simpliListView.Describe__c              = callResponse;
                    simpliListView.Label__c                 = listView.Name;
                    simpliListView.Core_ListView_Id__c      = listView.Id;
                    simpliListView.Primary_Key__c           = listview.SObjectType + ':' + listView.DeveloperName;
                    System.debug(LoggingLevel.DEBUG, 'PRIMARY KEY - ' + simpliListView.Primary_Key__c);
                    simpliListView.RecordTypeId             = ListViewHelper.coreRTId;
                    
                    User usr = UserHelper.getUserDetails(listView.CreatedById);


                    if (usr == null 
                        || !usr.IsActive
                        || (usr.FirstName == 'Automated' 
                            && usr.LastName == 'Process'))
                    {
                        simpliListView.OwnerId              = UserInfo.getUserId();
                    } else {
                        simpliListView.OwnerId              = listView.CreatedById;
                    }

                    simpliListView.Core_ListView_Query__c   = (String) jsonResponse.get('query');
                    simpliListView.Core_ListView_Columns__c = JSON.serialize(jsonResponse.get('columns'));
        
                    simpliListViews.add(simpliListView);

                    System.debug(LoggingLevel.DEBUG, 'Added Simpli List View - ' + simpliListView);

                    //use the metadata API to try and enrich the listview data.
                    HelperMetadataAPI.enrichListViewFromMetadata(simpliListView);

                    List_View_Config__c config = new List_View_Config__c();
                    config.Name                = simpliListView.API_Name__c;
                    config.List_View_Label__c  = simpliListView.Label__c;
                    config.List_View_Object__c = simpliListView.Object_Name__c;
                    config.Primary_Key__c      = config.List_View_Object__c + ':' + config.Name;

                    simpliListViewConfigs.add(config);

                    sObjectSet.add(listView.SobjectType);

                } catch (Exception e) {
                    System.debug(LoggingLevel.FINE, 'Exception thrown - ' + e.getMessage() + ' - ' + e.getStackTraceString());
                    //we don't care about exceptions here because it means the listview is not one that can be handled.
                }
            }
            
            System.debug(LoggingLevel.FINE, 'SObjects - ' + HelperString.getStringFromSet(sObjectSet, ','));


            HelperDatabase.upsertRecords(simpliListViews, 'Simpli_lv__List_View__c', 'simpli_lv__Primary_Key__c', true);
            HelperDatabase.upsertRecords(simpliListViewConfigs, 'Simpli_lv__List_View_Config__c', 'simpli_lv__Primary_Key__c', true);           

        } catch (Exception e) {
            String message = 'Exception during ListViewProcessBatch.execute()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createUsageErrorNonFuture(message); 
        }
	}
	
	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */ 
	global void finish(Database.BatchableContext BC) 
	{
        //delete all list views that are EXCLUDED from being displayed
        //but may have been created at another time
        Database.executeBatch(new ListViewDeleteBatch());
	}
	
	global class ListViewProcessBatchException extends Exception { }

}