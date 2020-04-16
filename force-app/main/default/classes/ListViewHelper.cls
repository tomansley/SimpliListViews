public with sharing class ListViewHelper {
    
    /*
     * Method to retrieve a list views describe details including the SOQL statement.
     * The set passed in is the CUSTOM list view Ids. This method should not be used 
     * for more than 50 list views. If more need to be updated then use the batch job.
     */
    public static Boolean updateListViews(Set<Id> lvIds)
    {
        List<List_View__c> updatedListViews = new List<List_View__c>();

        //get the CUSTOM list views.
        Map<Id, List_View__c> listViews = getListViewsById(lvIds);

        //get the CORE list view Ids from the CUSTOM list views.
        Map<Id, List_View__c> listViewsByCoreId = new Map<Id, List_View__c>();
        for (List_View__c listView: listViews.values())
            listViewsByCoreId.put(listView.Core_ListView_Id__c, listView);

        //get the CORE list views.
        List<ListView> coreListViews = [SELECT Id, Name, SObjectType, DeveloperName FROM ListView WHERE Id IN :listViewsByCoreId.keySet()];
        
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
                simpliListView.API_Name__c    = listView.DeveloperName;
                simpliListView.Object_Name__c = listview.SObjectType;
                simpliListView.Describe__c    = callResponse;
                simpliListView.Label__c       = listView.Name;
                simpliListView.Primary_Key__c = listview.SObjectType + ':' + listView.DeveloperName;

                updatedListViews.add(simpliListView);

                System.debug(LoggingLevel.DEBUG, 'Updated Simpli List View - ' + simpliListView);

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
        Map<String, String> mappedListviewObjects = new Map<String, String>();
        AggregateResult[] listViewObjects = [SELECT Object_Name__c FROM List_View__c GROUP BY Object_Name__c];

        String excludedObjs = HelperMetadata.getOrgWideSettingValue('Excluded Object Types', '');

        for (AggregateResult result: listViewObjects)
        {
            String objAPIName = (String) result.get('simpli_lv__Object_Name__c');

            //do not add excluded objs
            if (!excludedObjs.contains(objAPIName))
            {
                String objLabel = HelperSchema.getObjectSchema(objAPIName).getLabel();

                mappedListviewObjects.put(objAPIName, objLabel);
            }
        }

        return mappedListviewObjects;
    }

    /*
     * Method to get list views by Id
     */
    public static Map<Id, List_View__c> getListViewsById(Set<Id> lvIds)
    {
        return new Map<Id, List_View__c>([SELECT Label__c,
                                                 Describe__c,
                                                 Core_ListView_Id__c,
                                                 Object_Name__c,
                                                 Primary_Key__c,
                                                 API_Name__c
                                          FROM List_View__c
                                          WHERE Id IN :lvIds]);
    }

    /*
        * Method to get all list views for a provided object.
        * The map is returned as follows - (API Name, List View)
        */
    public static Map<String, List_View__c> getListViewsByObject(String objAPIName)
    {
        //get list view data
        List<List_View__c> listviews = [SELECT Label__c,
                                                Describe__c,
                                                Core_ListView_Id__c,
                                                Object_Name__c,
                                                Primary_Key__c,
                                                API_Name__c
                                        FROM List_View__c
                                        WHERE Object_Name__c = :objAPIName
                                        ORDER BY Label__c];

        Map<String, List_View__c> listviewsByName = new Map<String, List_View__c>();
        for (List_View__c listview: listviews)
            listViewsByName.put(listview.API_Name__c, listview);

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
        return new Map<Id, List_View__c>([SELECT Label__c,
                                                 Describe__c,
                                                 Core_ListView_Id__c,
                                                 Object_Name__c,
                                                 Primary_Key__c,
                                                 API_Name__c
                                          FROM List_View__c
                                          WHERE Object_Name__c = :objAPIName
                                                AND API_Name__c = :listViewAPIName]);
    }

    /*
     * Method to get a specific list view given its object and list view API names
     */
    public static CustomListView getListView(String objAPIName, String listViewAPIName)
    {
        //get list view data
        List_View__c listView = [SELECT Label__c,
                                        Describe__c,
                                        Core_ListView_Id__c,
                                        Object_Name__c,
                                        Primary_Key__c,
                                        API_Name__c
                                FROM List_View__c
                                WHERE Object_Name__c = :objAPIName
                                    AND API_Name__c = :listViewAPIName];

        CustomListView lv = new CustomListView(listView.Describe__c);

        return lv;
    }

    /*
     * Method to use the SOQL query retrieved from the core listview describe, amend it to include
     * the possible additional fields added by the user and then use it to get the data.
     */ 
    public static List<SObject> getListViewData(CustomListView listview, Map<String, String> lvConfig)
    {

        //get query from map
        String query = listview.getQuery();

        String selectStr = query.substringBefore(' FROM ');

        String whereStr = query.substringAfter(' FROM ');

        //add any additional fields to the SELECT
        if (lvConfig.get('AdditionalFields') != null)
            selectStr += ', ' + lvConfig.get('AdditionalFields');

        query = selectStr + ' FROM ' + whereStr;

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

    public static void insertCoreConfiguration()
    {

    }
    
    public class CustomListView {

        private Map<String,Object> listViewDesc = null;

        public CustomListView(String describe)
        {
            listViewDesc = (Map<String, Object>) JSON.deserializeUntyped(describe);
        }

        public String getQuery()
        {
            return (String) listViewDesc.get('query');
        }

        public List<Object> getColumns()
        {
            return (List<Object>) listViewDesc.get('columns');
        }

    }

}