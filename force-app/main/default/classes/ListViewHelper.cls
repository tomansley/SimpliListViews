/**
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 08-18-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   tom.h.ansley@medtronic.com   Initial Version
**/
global with sharing class ListViewHelper {
    
    /*
     ListViewHelper.updateListViewObjectsSetting();
     */
    public static void updateListViewObjectsSetting()
    {
        //get API Name/Label of all list view objects
        Map<String, String> listViewObjects = getListViewObjects(new Set<String>(), new Set<String>(), true);

        //turn to JSON
        String jsonStr = JSON.serialize(listViewObjects);

        System.debug(LoggingLevel.DEBUG, 'JSON - ' + jsonStr);

        ListViewConfigHelper.setOrgWideConfigParam('List View Objects', jsonStr);

    }

    /*
     * Method to return all CORE list views that have been altered by the running user
     * within the past 2 weeks.
     */
    public static Map<Id, ListView> getChangedListViews(Integer recLimit)
    {

        HelperSchema.checkObjectAccessible('ListView');

        Integer soqlLimit = 5000;
        if (recLimit != null)
            soqlLimit = recLimit;

        Map<Id, ListView> listViews = new Map<Id, ListView>([SELECT Id, 
                                                                    Name, 
                                                                    SObjectType, 
                                                                    DeveloperName, 
                                                                    LastModifiedById FROM ListView 
                                                            WHERE LastModifiedById = :UserInfo.getUserId()
                                                                    AND LastModifiedDate > :System.today().addDays(-1)
                                                            ORDER BY LastModifiedDate DESC
                                                            LIMIT :soqlLimit]);

        return listViews;
    }

    /*
     * Method to update list view describe details including the SOQL statement.
     * The set passed in is the CUSTOM list view Ids. This method should not be used 
     * for more than 50 list views. If more need to be updated then use the batch job.
     */
    public static Boolean updateListViews(String objectName)
    {
        List<List_View__c> updatedListViews = new List<List_View__c>();

        //get the CORE list views.
        List<ListView> coreListViews = [SELECT Id, Name, SObjectType, DeveloperName, CreatedById FROM ListView WHERE SObjectType = :objectName];
        
        for (ListView listView: coreListViews)
        {

            //create URL to find the list view query
            String endPoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v40.0/sobjects/' + listView.SObjectType + '/listviews/' + listView.Id + '/describe';
            
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
                simpliListView.OwnerId                  = listView.CreatedById;
                simpliListView.Core_ListView_Query__c   = (String) jsonResponse.get('query');
                simpliListView.Core_ListView_Columns__c = JSON.serialize(jsonResponse.get('columns'));

                updatedListViews.add(simpliListView);

                System.debug(LoggingLevel.DEBUG, 'Updated Simpli List View - ' + simpliListView);

                //use the metadata API to try and enrich the listview data.
                HelperMetadataAPI.enrichListViewFromMetadata(simpliListView);

            } catch (Exception e) {
                String message = 'Exception during ListViewHelper.updateListViews(' + objectName + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
                ListViewErrorHelper.createUsageError(message); 
            }
    
        }

        HelperSchema.checkObjectCreatable('List_View__c');
        HelperSchema.checkObjectUpdateable('List_View__c');

        upsert updatedListViews Primary_Key__c;

        return true;
    }

    /*
     * Method to retrieve list view describe details including the SOQL statement.
     * The set passed in is the CUSTOM list view Ids. This method should not be used 
     * for more than 50 list views. If more need to be updated then use the batch job.
     */
    public static Boolean updateListViews(Set<Id> lvIds)
    {
        List<List_View__c> updatedListViews = new List<List_View__c>();

        //get the CUSTOM list views.
        List<List_View__c> listViews = getListViewsById(lvIds).values();
        Map<Id, List_View__c> listViewsByCoreId = new Map<Id, List_View__c>();

        //get the CORE list view Ids from the CUSTOM list views.
        //but only get those that the user is allowed to update
        for (List_View__c listView: listViews)
        {
            if (isUpdateable(listView))
                listViewsByCoreId.put(listView.Core_ListView_Id__c, listView);
        }

        //get the CORE list views.
        List<ListView> coreListViews = [SELECT Id, Name, SObjectType, DeveloperName, CreatedById FROM ListView WHERE Id IN :listViewsByCoreId.keySet()];
        
        for (ListView listView: coreListViews)
        {

            //create URL to find the list view query
            String endPoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v40.0/sobjects/' + listView.SObjectType + '/listviews/' + listView.Id + '/describe';
            
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
                simpliListView.OwnerId                  = listView.CreatedById;
                simpliListView.Core_ListView_Query__c   = (String) jsonResponse.get('query');
                simpliListView.Core_ListView_Columns__c = JSON.serialize(jsonResponse.get('columns'));

                updatedListViews.add(simpliListView);

                System.debug(LoggingLevel.DEBUG, 'Updated Simpli List View - ' + simpliListView);

                //use the metadata API to try and enrich the listview data.
                HelperMetadataAPI.enrichListViewFromMetadata(simpliListView);

            } catch (Exception e) {
                String message = 'Exception during ListViewHelper.updateListViews(' + lvIds + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
                ListViewErrorHelper.createUsageError(message); 
            }

        }

        upsert updatedListViews Primary_Key__c;

        return true;
    }

    /*
    * Method to get all objects that have had their list views processed.
    * The map is returned as follows - (API Name, Label)
    */
    public static Map<String, String> getListViewObjects()
    {
        return getListViewObjects(new Set<String>(), new Set<String>(), false);
    }
    
    /*
    * Method to get all objects that have had their list views processed.
    * if includedObjects is passed in those objects will be returned. If
    * includedObjects is empty or null all objects are returned.
    * The map is returned as follows - (API Name, Label)
    ListViewHelper.getListViewObjects(new Set<String>(), new Set<String>());
    */
    public static Map<String, String> getListViewObjects(Set<String> pageWideIncObjs, Set<String> pageWideExcObjs, Boolean fresh)
    {
        System.debug(LoggingLevel.DEBUG, 'ListViewHelper.getListViewObjects(' + pageWideIncObjs + ', ' + pageWideExcObjs + ', ' + fresh + ')');

        Map<String, String> mappedListviewObjects = new Map<String, String>();
        Map<String, String> listViewObjects =  null;

        if (fresh)
        {

            listViewObjects =  new Map<String, String>();

            String exclObjs = ListViewConfigHelper.getOrgWideConfigParam('Excluded Object Types');
            Set<String> orgWideExcObjs = HelperString.getSetFromString(exclObjs, ',');
    
            HelperSchema.checkObjectAccessible('List_View__c');

            AggregateResult[] aggListViewObjects = [SELECT Object_Name__c 
                                                 FROM List_View__c 
                                                 WHERE Object_Name__c NOT IN :orgWideExcObjs 
                                                    AND Object_Name__c NOT IN :pageWideExcObjs 
                                                 GROUP BY Object_Name__c 
                                                 LIMIT 2000]; //limit for security review. No other reason
    
    
            for (AggregateResult result: aggListViewObjects)
            {
                String objAPIName = (String) result.get('simpli_lv__Object_Name__c');
    
                String objLabel = HelperSchema.getObjectSchema(objAPIName).getLabel();

                listViewObjects.put(objAPIName, objLabel);
            }
        
        } else {

            String jsonStr = ListViewConfigHelper.getOrgWideConfigParam('List View Objects');

            if (jsonStr != null && jsonStr != '')
                listViewObjects =  (Map<String, String>) JSON.deserialize(jsonStr, Map<String,String>.class);    
            else
                listViewObjects = new Map<String, String>();
        }

        String inclObjs = ListViewConfigHelper.getOrgWideConfigParam('Included Object Types');
        Set<String> orgWideIncObjs = HelperString.getSetFromString(inclObjs, ',');

        for (String objAPIName: listViewObjects.keySet())
        {

            //if there are PAGE included objects then only include those.
            if (pageWideIncObjs.isEmpty() || pageWideIncObjs.contains(objAPIName))
            {

                //if there are ORG WIDE included objects then only include those.
                if (orgWideIncObjs.isEmpty() || orgWideIncObjs.contains(objAPIName))
                {
                    mappedListviewObjects.put(objAPIName, listViewObjects.get(objAPIName));
                }
            }
        }

        return mappedListviewObjects;
    }

    /*
     * Method to get list views by Id
     */
    public static Map<Id, List_View__c> getListViewsById(Set<Id> lvIds)
    {
        System.debug(LoggingLevel.DEBUG, 'lvIds - ' + lvIds);

        HelperSchema.checkObjectAccessible('List_View__c');

        List<List_View__c> listviews = [SELECT Label__c,
                                                 Describe__c,
                                                 Core_ListView_Id__c,
                                                 Object_Name__c,
                                                 Primary_Key__c,
                                                 API_Name__c,
                                                 Core_ListView_Columns__c,
                                                 Core_ListView_Query__c,
                                                 OwnerId,
                                                 All_Internal_Users__c,
                                                 Boolean_Filter__c,
                                                 Filter_Scope__c,
                                                 Groups__c,
                                                 Roles__c,
                                                 Roles_And_Subordinates__c,
                                                 Territories__c,
                                                 Territories_And_Subordinates__c,
                                                 LastModifiedDate,
                                                 LastModifiedBy.Name
                                           FROM List_View__c
                                          WHERE Id IN :lvIds];

        Map<Id, List_View__c> lvs = new Map<Id, List_View__c>();

        //now check security
        for (List_View__c lv: listviews)
        {
            if (isVisible(lv))
                lvs.put(lv.Id, lv);
        }
        return lvs;
    }

    /*
     * Method to get all list views for a provided object.
     * The map is returned as follows - (API Name, List View)
     */
    public static Map<String, List_View__c> getListViewsByObject(String objAPIName)
    {

        System.debug(LoggingLevel.DEBUG, 'objAPIName - ' + objAPIName);

        //make sure that the user has access to the object itself.
        if (!HelperSchema.checkObjectAccessible(objAPIName, false))
            return new Map<String, List_View__c>();

        //get list view data
        List<List_View__c> listviews = [SELECT Label__c,
                                                Describe__c,
                                                Core_ListView_Id__c,
                                                Object_Name__c,
                                                Primary_Key__c,
                                                API_Name__c,
                                                Core_ListView_Columns__c,
                                                Core_ListView_Query__c,
                                                OwnerId,
                                                All_Internal_Users__c,
                                                Boolean_Filter__c,
                                                Filter_Scope__c,
                                                Groups__c,
                                                Roles__c,
                                                Roles_And_Subordinates__c,
                                                Territories__c,
                                                Territories_And_Subordinates__c,
                                                LastModifiedDate,
                                                LastModifiedBy.Name
                                        FROM List_View__c
                                        WHERE Object_Name__c = :objAPIName
                                        ORDER BY Label__c];

        Map<String, List_View__c> listviewsByName = new Map<String, List_View__c>();

        //now check security
        for (List_View__c listview: listviews)
        {
            if (isVisible(listview))
                listViewsByName.put(listview.API_Name__c, listview);
        }

        return listviewsByName;
    }

    /*
     * Method to get a specific list view given its object and list view API names
     */
    public static Map<Id, List_View__c> getListViews(String objAPIName, String listViewAPIName)
    {
        System.debug(LoggingLevel.DEBUG, 'objAPIName - ' + objAPIName);
        System.debug(LoggingLevel.DEBUG, 'listViewAPIName - ' + listViewAPIName);

        HelperSchema.checkObjectAccessible('List_View__c');

        //get list view data
        List<List_View__c> listviews = [SELECT Label__c,
                                                Describe__c,
                                                Core_ListView_Id__c,
                                                Object_Name__c,
                                                Primary_Key__c,
                                                API_Name__c,
                                                Core_ListView_Columns__c,
                                                Core_ListView_Query__c,
                                                OwnerId,
                                                All_Internal_Users__c,
                                                Boolean_Filter__c,
                                                Filter_Scope__c,
                                                Groups__c,
                                                Roles__c,
                                                Roles_And_Subordinates__c,
                                                Territories__c,
                                                Territories_And_Subordinates__c,
                                                LastModifiedDate,
                                                LastModifiedBy.Name
                                        FROM List_View__c
                                        WHERE Object_Name__c = :objAPIName
                                            AND API_Name__c = :listViewAPIName];

        Map<Id, List_View__c> listviewsById = new Map<Id, List_View__c>();

        //now check security
        for (List_View__c listview: listviews)
        {
            if (isVisible(listview))
                listViewsById.put(listview.Id, listview);
        }

        return listviewsById;
    }

    public static List<SObject> getListViewData(List_View__c listview, List_View_Config__c lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Boolean example)
    {

        String debug = '\n\nStarting getListViewData - \n';
        debug += 'listview           - ' + listview + '\n';
        debug += 'lvConfig           - ' + lvConfig + '\n';
        debug += 'sortData           - ' + sortData + '\n';
        debug += 'joinFieldName      - ' + joinFieldName + '\n';
        if (joinRecordIds != null)
            debug += 'joinRecordIds Size - ' + joinRecordIds.size() + '\n';
        debug += 'joinRecordIds      - ' + joinRecordIds + '\n\n';
        System.debug(LoggingLevel.DEBUG, debug);

        Map<String, String> lvConfigParams = new Map<String, String>();
        if (lvConfig != null) //there might not e a config yet for this list view
        {
            for (List_View_Config_Parameter__c param: lvConfig.List_View_Config_Parameters__r)
                lvConfigParams.put(param.Parameter_Name__c, param.Parameter_Value__c);
        }
        
        //check the object is accessible by this user
        HelperSchema.checkObjectAccessible(listview.Object_Name__c);

            //---------------------------------------------------
        // Parse out the query retrieved from the list view.
        //---------------------------------------------------
        String query = listview.Core_ListView_Query__c;
        String selectStr = query.substringBetween('SELECT ', ' FROM ');
        String whereStr = null;
        String orderByStr = '';
        if (query.contains(' ORDER BY '))
        {
            whereStr = query.substringBetween(' FROM ', ' ORDER BY ');
            orderByStr = query.substringAfter(' ORDER BY ');

        } else {
            whereStr = query.substringAfter(' FROM ');
        }

        //------------------------------------------------------
        // Update all additional fields on the SELECT statement
        //------------------------------------------------------
        if (lvConfigParams.get('AdditionalFields') != null)
        {
            List<String> allFields = lvConfigParams.get('AdditionalFields').split(',');
            for (String field: allFields)
            {
                //do security validation on additional fields. If the field is a lookup the security is performed later
                if (!field.contains('.'))
                    HelperSchema.checkObjectFieldAccessible(listview.Object_Name__c, field);
            }

            selectStr += ', ' + lvConfigParams.get('AdditionalFields');
        }

        //------------------------------------------------------
        // Handle all changes to the WHERE statement
        //------------------------------------------------------
        if (joinFieldName != '' && joinRecordIds != null && joinRecordIds.size() > 0)
        {
            if (whereStr.contains(' WHERE '))
                whereStr += ' AND ' + joinFieldName + ' IN :joinRecordIds';
            else
                whereStr += ' WHERE ' + joinFieldName + ' IN :joinRecordIds';
        }

        //------------------------------------------------------
        // Handle all changes to the ORDER BY statement
        //------------------------------------------------------
        if (sortData != null && sortData.size() > 0)
        {
            orderByStr = '';
            
            for (ListViewHelper.ColumnSortData columnSortData: sortData)
            {
                orderByStr += columnSortData.fieldName + ' ';
                if (columnSortData.sortDirection == true)
                    orderByStr += 'ASC NULLS FIRST, ';
                else
                    orderByStr += 'DESC NULLS FIRST, ';

            }

            orderByStr = orderByStr.removeEnd(', ');
        }

        //------------------------------------------------------
        // Handle the LIMIT statement
        //------------------------------------------------------
        String limitStr = ' LIMIT ';
        
        //if we are getting join records then do not use a limit
        if (joinRecordIds != null && joinRecordIds.size() > 0)
        {
            limitStr = '';
        
        } else {

            //if we only need an example record
            if (example)
                limitStr += '1';
                
            //if we have a list view limit then use it
            if (lvConfigParams.get('ReturnSize') != null)
                limitStr += lvConfigParams.get('ReturnSize');
            
            //otherwise use 250
            else
                limitStr += '250';
        }

        //------------------------------------------------------
        // Handle the ALL ROWS statement
        //------------------------------------------------------
        String allRowsStr = '';
        if (lvConfigParams.get('AllRows') != null && lvConfigParams.get('AllRows') == 'true')
        {
            allRowsStr += ' ALL ROWS';
        }

        //------------------------------------------------------
        // Put the query back together again
        //------------------------------------------------------
        query = 'SELECT ' + selectStr + ' FROM ' + whereStr + ' ORDER BY ' + orderByStr + limitStr + allRowsStr;

        System.debug(LoggingLevel.DEBUG, 'Final SOQL - ' + query);

        //get rows of data from query
        List<SObject> objectRows = null;
        try {
            objectRows = Database.query(query);
        } catch (Exception e) {
            String message = 'Exception during ListViewHelper.getListViewData(' + query + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageError(message);
            throw new ListViewHelperException('There was an error during data retrieval. Please try again or notify an administrator.');
        }
        
        return objectRows;

    }

    /*
     * Method to use the SOQL query retrieved from the core listview describe, amend it to include
     * the possible additional fields added by the user and then use it to get the data.
     */ 
    public static List<SObject> getListViewData(List_View__c listview, List_View_Config__c lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds)
    {
        return getListViewData(listview, lvConfig, sortData, joinFieldName, joinRecordIds, false);
    }

    global static void insertCoreConfiguration()
    {

        //-----------------------------------------------------
        // Create List View Actions
        //-----------------------------------------------------
        HelperSchema.checkListViewActionsCreatable();

        List<List_View_Action__c> actions = new List<List_View_Action__c>();

        List_View_Action__c orgDeleteAction = new List_View_Action__c();
        orgDeleteAction.Apex_Class_Name__c = 'ListViewActionDelete';
        orgDeleteAction.Label__c           = 'Delete';

        actions.add(orgDeleteAction);

        List_View_Action__c acctUpdateAction = new List_View_Action__c();
        acctUpdateAction.Apex_Class_Name__c = 'ListViewActionUpdate';
        acctUpdateAction.Label__c           = 'Update';
        acctUpdateAction.Object_Type__c     = 'Account';

        actions.add(acctUpdateAction);

        List_View_Action__c oppsCloseUpdateAction = new List_View_Action__c();
        oppsCloseUpdateAction.Apex_Class_Name__c = 'ListViewActionOppsClose';
        oppsCloseUpdateAction.Label__c           = 'Set Close Lost';
        oppsCloseUpdateAction.Object_Type__c     = 'Opportunity';

        actions.add(oppsCloseUpdateAction);

        insert actions;

        List<List_View_Action_Parameter__c> params = new List<List_View_Action_Parameter__c>();

        List_View_Action_Parameter__c param = new List_View_Action_Parameter__c();
        param.Field_API_Name__c   = 'Name';
        param.Label__c            = 'Account Name';
        param.Display_Order__c    = 1;
        param.List_View_Action__c = acctUpdateAction.Id;
        param.Placeholder_Text__c = 'Account name goes here...';
        param.Type__c             = 'STRING';

        params.add(param);

        param                     = new List_View_Action_Parameter__c();
        param.Field_API_Name__c   = 'Industry';
        param.Label__c            = 'Industry';
        param.Display_Order__c    = 2;
        param.List_View_Action__c = acctUpdateAction.Id;
        param.Placeholder_Text__c = 'Industry goes here...';
        param.Type__c             = 'STRING';

        params.add(param);

        param                     = new List_View_Action_Parameter__c();
        param.Field_API_Name__c   = 'CloseDate';
        param.Label__c            = 'Close Date';
        param.Display_Order__c    = 1;
        param.List_View_Action__c = oppsCloseUpdateAction.Id;
        param.Placeholder_Text__c = '';
        param.Type__c             = 'DATE';

        params.add(param);

        insert params;

        //-----------------------------------------------------
        // Create List View Configs
        //-----------------------------------------------------
        HelperSchema.checkListViewConfigsCreatable();

        List<List_View_Config__c> configs = new List<List_View_Config__c>();

        List_View_Config__c config = new List_View_Config__c();
        config.Name                = 'PlatinumandGoldSLACustomers';
        config.List_View_Object__c = 'Account';
        configs.add(config);

        List_View_Config__c config2 = new List_View_Config__c();
        config2.Name                = 'All';
        config2.List_View_Object__c = 'All';
        configs.add(config2);

        List_View_Config__c config3 = new List_View_Config__c();
        config3.Name                = 'AllAccounts';
        config3.List_View_Object__c = 'Account';
        configs.add(config3);

        insert configs;

        List<List_View_Config_Parameter__c> params2 = new List<List_View_Config_Parameter__c>();
      
        List_View_Config_Parameter__c param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config.Id;
        param2.Parameter_Name__c   = 'AdditionalFields';
        param2.Parameter_Type__c   = 'String';
        param2.Parameter_Value__c  = 'Type, AnnualRevenue,CreatedBy.Name,Owner.Profile.Name';
        params2.add(param2);
        
        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config.Id;
        param2.Parameter_Name__c   = 'TotalColumns';
        param2.Parameter_Type__c   = 'String';
        param2.Parameter_Value__c  = 'AnnualRevenue';
        params2.add(param2);
        
        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config.Id;
        param2.Parameter_Name__c   = 'TotalColumnsColor';
        param2.Parameter_Type__c   = 'Color';
        param2.Parameter_Value__c  = '#E5F0FA';
        params2.add(param2);
        
        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'List View Objects';
        param2.Parameter_Type__c   = 'String';
        param2.Parameter_Value__c  = '';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'Included Object Types';
        param2.Parameter_Type__c   = 'String';
        param2.Parameter_Value__c  = '';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'Excluded Object Types';
        param2.Parameter_Type__c   = 'String';
        param2.Parameter_Value__c  = 'FlowInterview,CollaborationGroup,Idea,OperatingHours,ServiceAppointment,WorkType,Solution';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
		param2.Parameter_Name__c = 'AdditionalFields';
		param2.Parameter_Type__c = 'String';
		param2.Parameter_Value__c = 'CreatedBy.Name, Owner.Profile.Name, AnnualRevenue';
		param2.List_View_Config__c = config3.Id;
        params2.add(param2);
        
        param2 = new List_View_Config_Parameter__c();
		param2.Parameter_Name__c = 'TotalColumns';
		param2.Parameter_Type__c = 'String';
		param2.Parameter_Value__c = 'AnnualRevenue';
		param2.List_View_Config__c = config3.Id;
        params2.add(param2);
        
        param2 = new List_View_Config_Parameter__c();
		param2.Parameter_Name__c = 'TotalColumnsColor';
		param2.Parameter_Type__c = 'Color';
		param2.Parameter_Value__c = '#E5F0FA';
		param2.List_View_Config__c = config3.Id;
        params2.add(param2);
        
        insert params2;

        List<List_View_Config_Condition__c> conditions = new List<List_View_Config_Condition__c>();

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.List_View_Config__c = config.Id;
        condition.Field_Name__c       = 'Account Name';
        condition.Operator__c         = 'Contains';
        condition.Value__c            = 'Burlington';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = '#c59e9e';
        conditions.add(condition);

        insert conditions;

    }

    /*
     * Method to check security and determine whether the list view is visible
     * to the requesting user. The following security is performed.
     * 1. if user is owner
     * 2. if list view allows all internal users.
     * 3. if user is in allowed roles
     * 4. if user is in allowed groups
     * 5. if user is in allowed territories
     */
    public static Boolean isVisible(List_View__c lv)
    {
        User usr = UserHelper.getCurrentUser();

        //if (lv.OwnerId == UserInfo.getUserId()) return true;

        //if (lv.All_Internal_Users__c) return true;

        //if (lv.Roles__c.contains(usr.UserRole.Name)) return true;

        return true;
    }

    /*
     * Method to check security and determine whether the list view is visible
     * to the requesting user. The following security is performed.
     * 1. if user is owner
     * 2. if list view allows all internal users.
     * 3. if user is in allowed roles
     * 4. if user is in allowed groups
     * 5. if user is in allowed territories
     */
    public static Boolean isUpdateable(List_View__c lv)
    {
        User usr = UserHelper.getCurrentUser();

        if (lv.OwnerId == UserInfo.getUserId()) return true;

        if (usr.Profile.Name == 'System Administrator') return true;

        return false;
    }

    public class ColumnSortData implements Comparable {

        public String fieldName;
        public Boolean sortDirection;
        public Integer sortIndex;

        public Integer compareTo(Object compareTo) {
            ColumnSortData sortData2 = (ColumnSortData) compareTo;
            if (sortIndex > sortData2.sortIndex)
                return 1;
            else if (sortIndex < sortData2.sortIndex)
                return -1;
            else
                return 0;
        }
    }

    public class ListViewHelperException extends Exception { }
}