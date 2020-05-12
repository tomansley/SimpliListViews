global with sharing class ListViewProcessBatch implements Database.AllowsCallouts, Database.Batchable<SObject>, Database.Stateful, Schedulable {
    
    private String query = 'SELECT Id, Name, SObjectType, DeveloperName, CreatedById FROM ListView WHERE SObjectType != null';
    private final Integer batchSize = 1;
    private Set<Id> listViewIds = null;

    /*
        Simpli_lv.ListViewProcessBatch b = new Simpli_lv.ListViewProcessBatch();
        b.execute(null);
    */
    global ListViewProcessBatch() {
    }

    /*
     * Constructor used to only process those list views who's Ids are provided.
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

        //never get the excluded objects
        String orgWideExcObjs = HelperMetadata.getOrgWideSettingValue('Excluded Object Types', '');
        List<String> excObjs = orgWideExcObjs.split(',');
        if (excObjs.size() > 0)
            query += ' AND SObjectType NOT IN :excObjs';

        if (listViewIds != null && listViewIds.size() > 0)
            query += ' AND Id IN :listViewIds';

        query += ' ORDER BY SObjectType';

        if (Test.isRunningTest())
            query += ' LIMIT 1';

		return Database.getQueryLocator(query);
	}

	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
	global void execute(Database.BatchableContext BC, List<SObject> scope) 
	{
        List<List_View__c> simpliListViews = new List<List_View__c>();
    
        List<ListView> listViews = (List<ListView>) scope;

        for (ListView listView: listViews)
        {

            System.debug(LoggingLevel.DEBUG, 'Getting ListView - ' + listView);

            //check that this user is allowed to update the list view config
            if (!ListViewHelper.isUpdateable(listView)) 
            {   
                System.debug(LoggingLevel.DEBUG, 'List view ' + listView.SObjectType + '.' + listView.Name + ' not updateable by current user.');
                continue;
            }

            //create URL to find the list view query
            String endPoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v40.0/sobjects/' + listView.SObjectType + '/listviews/' + listView.Id + '/describe';
            
            //get list view describe
            String callResponse = HelperREST.performInternalCallout(endPoint, null);

            if (Test.isRunningTest())
                callResponse = '{"columns":[{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Name","hidden":false,"label":"Name","selectListItem":"Name","sortDirection":"ascending","sortIndex":0,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Account.Name","hidden":false,"label":"Account Name","selectListItem":"Account.Name","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Title","hidden":false,"label":"Title","selectListItem":"Title","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"9-0","descendingLabel":"0-9","fieldNameOrPath":"Phone","hidden":false,"label":"Phone","selectListItem":"Phone","sortDirection":null,"sortIndex":null,"sortable":true,"type":"phone"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Email","hidden":false,"label":"Email","selectListItem":"Email","sortDirection":null,"sortIndex":null,"sortable":true,"type":"email"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Owner.Alias","hidden":false,"label":"Contact Owner Alias","selectListItem":"Owner.Alias","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Id","hidden":true,"label":"Contact ID","selectListItem":"Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"CreatedDate","hidden":true,"label":"Created Date","selectListItem":"CreatedDate","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"LastModifiedDate","hidden":true,"label":"Last Modified Date","selectListItem":"LastModifiedDate","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"SystemModstamp","hidden":true,"label":"System Modstamp","selectListItem":"SystemModstamp","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Account.Id","hidden":true,"label":"Account ID","selectListItem":"Account.Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"AccountId","hidden":true,"label":"Account ID","selectListItem":"AccountId","sortDirection":null,"sortIndex":null,"sortable":false,"type":"reference"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Owner.Id","hidden":true,"label":"User ID","selectListItem":"Owner.Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"OwnerId","hidden":true,"label":"Owner ID","selectListItem":"OwnerId","sortDirection":null,"sortIndex":null,"sortable":false,"type":"reference"}],"id":"00B3h000003ZfMY","orderBy":[{"fieldNameOrPath":"Name","nullsPosition":"first","sortDirection":"ascending"},{"fieldNameOrPath":"Id","nullsPosition":"first","sortDirection":"ascending"}],"query":"SELECT Name, Account.Name, Title, Phone, Email, Owner.Alias, Id, CreatedDate, LastModifiedDate, SystemModstamp, Account.Id, AccountId, Owner.Id, OwnerId FROM Contact USING SCOPE mine ORDER BY Name ASC NULLS FIRST, Id ASC NULLS FIRST","scope":"mine","sobjectType":"Contact","whereCondition":{"conditions":[],"conjunction":"and"}}';

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
                
                User usr = UserHelper.getUserDetails(listView.CreatedById);
                if (usr == null 
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

            } catch (Exception e) { 

            }
        }

        HelperSchema.checkListViewCreatable();
        
        upsert simpliListViews Primary_Key__c;		
	}
	
	/* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */ 
	global void finish(Database.BatchableContext BC) 
	{
	}
	
	global class ListViewProcessBatchException extends Exception { }

}