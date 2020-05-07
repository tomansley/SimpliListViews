global with sharing class ListViewHelper {
    
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
            if (!isUpdateable(listView))
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
        return getListViewObjects('', '');
    }
    
    /*
    * Method to get all objects that have had their list views processed.
    * if includedObjects is passed in those objects will be returned. If
    * includedObjects is empty or null all objects are returned.
    * The map is returned as follows - (API Name, Label)
    */
    public static Map<String, String> getListViewObjects(String pageWideIncObjs, String pageWideExcObjs)
    {
        Map<String, String> mappedListviewObjects = new Map<String, String>();
        AggregateResult[] listViewObjects = [SELECT Object_Name__c FROM List_View__c GROUP BY Object_Name__c LIMIT 2000];

        String orgWideExcObjs = HelperMetadata.getOrgWideSettingValue('Excluded Object Types', '');
        String orgWideIncObjs = HelperMetadata.getOrgWideSettingValue('Included Object Types', '');

        for (AggregateResult result: listViewObjects)
        {
            String objAPIName = (String) result.get('simpli_lv__Object_Name__c');

            //PAGE - if included objects have been included then check against.
            if (pageWideIncObjs == null || pageWideIncObjs == '' || pageWideIncObjs.contains(objAPIName))
            {

                //PAGE - if excluded objects have been included then be sure to remove
                if (pageWideExcObjs == null || pageWideExcObjs == '' || !pageWideExcObjs.contains(objAPIName))
                {
                    //ORG-WIDE - if we are including all objects or have a list then check against it.
                    if (orgWideIncObjs == '' || orgWideIncObjs.contains(objAPIName))
                    {
                        //ORG-WIDE - do not add excluded objs
                        if (!orgWideExcObjs.contains(objAPIName))
                        {
                            String objLabel = HelperSchema.getObjectSchema(objAPIName).getLabel();

                            mappedListviewObjects.put(objAPIName, objLabel);
                        }
                    }
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
                                                 Territories_And_Subordinates__c
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
                                                Territories_And_Subordinates__c
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
                                                Territories_And_Subordinates__c
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

    /*
     * Method to use the SOQL query retrieved from the core listview describe, amend it to include
     * the possible additional fields added by the user and then use it to get the data.
     */ 
    public static List<SObject> getListViewData(List_View__c listview, Map<String, String> lvConfig, List<ListViewHelper.ColumnSortData> sortData)
    {

        //---------------------------------------------------
        // Parse out the query retrieved from the list view.
        //---------------------------------------------------
        String query = listview.Core_ListView_Query__c;
        String selectStr = query.substringBefore(' FROM ');
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
        if (lvConfig.get('AdditionalFields') != null)
            selectStr += ', ' + lvConfig.get('AdditionalFields');

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
        // Put the query back together again
        //------------------------------------------------------
        query = selectStr + ' FROM ' + whereStr + ' ORDER BY ' + orderByStr;

        //add any limits to the data returned. Max = 2000
        if (lvConfig.get('ReturnSize') != null)
            query += ' LIMIT ' + lvConfig.get('ReturnSize');
        else
            query += ' LIMIT 2000';

        System.debug(LoggingLevel.DEBUG, 'Final SOQL - ' + query);

        //get rows of data from query
        List<SObject> objectRows = Database.query(query);

        return objectRows;

    }

    global static void insertCoreConfiguration()
    {

        HelperSchema.checkListViewActionsCreatable();

        List<List_View_Action__c> actions = new List<List_View_Action__c>();

        List_View_Action__c orgDeleteAction = new List_View_Action__c();
        orgDeleteAction.Apex_Class_Name__c = 'ListViewActionDelete';
        orgDeleteAction.Label__c           = 'Delete';

        actions.add(orgDeleteAction);

        List_View_Action__c acctUpdateAction = new List_View_Action__c();
        acctUpdateAction.Apex_Class_Name__c = 'ListViewActionUpdate';
        acctUpdateAction.Label__c           = 'Update';
        acctUpdateAction.Object_Type__c = 'Account';

        actions.add(acctUpdateAction);

        insert actions;

        List<List_View_Action_Parameter__c> params = new List<List_View_Action_Parameter__c>();

        List_View_Action_Parameter__c param = new List_View_Action_Parameter__c();
        param.Field_API_Name__c   = 'Name';
        param.Label__c            = 'Account Name';
        param.List_View_Action__c = acctUpdateAction.Id;
        param.Placeholder_Text__c = 'Account name goes here...';
        param.Type__c             = 'STRING';

        params.add(param);

        param                     = new List_View_Action_Parameter__c();
        param.Field_API_Name__c   = 'Industry';
        param.Label__c            = 'Industry';
        param.List_View_Action__c = acctUpdateAction.Id;
        param.Placeholder_Text__c = 'Industry goes here...';
        param.Type__c             = 'STRING';

        params.add(param);

        insert params;

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

        if (lv.OwnerId == UserInfo.getUserId()) return true;

        if (lv.All_Internal_Users__c) return true;

        if (lv.Roles__c.contains(usr.UserRole.Name)) return true;

        return false;
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

        if (lv.Owner_Name__c == 'Automated Process'
            && usr.Profile.Name == 'System Administrator') return true;

        return false;
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
    public static Boolean isUpdateable(ListView lv)
    {
        User usr = UserHelper.getCurrentUser();
        User owner = UserHelper.getUserDetails(lv.CreatedById);

        if (lv.CreatedById == UserInfo.getUserId()) return true;

        if ((owner == null
            || (owner.FirstName == 'Automated' 
                && owner.LastName == 'Process'))
            && usr.Profile.Name == 'System Administrator') return true;

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
}