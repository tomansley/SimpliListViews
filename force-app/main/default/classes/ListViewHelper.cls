/**
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 08-18-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   tom.h.ansley@medtronic.com   Initial Version
 * 2.0   02-17-2021   tom.h.ansley@medtronic.com   Added New action config
 * 3.0   06-18-2021   tom.h.ansley@medtronic.com   Added offset to allow for larger datasets
 * 4.0   06-18-2021   tom.h.ansley@medtronic.com   Added updateRecord() method to update records based on inline editing, added Edit All action for inline-editing of all list view rows, added org wide config params for identifying if inline-editing is allowed and whether the list views have been initialized.
 * 5.0   08-02-2021   tom.h.ansley@medtronic.com   Added List_View_Label__c,
 *                                                 Added getObjectForValue() for getting proper object for string value, 
 *                                                 Added updateRecords() method to update multiple records based on inline editing, 
 *                                                 Moved in static strings for types from ListViewConfigHelper,  
 *                                                 Added DisplayTextSearch org wide config
 * 6.0   08-03-2021   tom.h.ansley@medtronic.com   Performance enhancement when retrieving listview objects
 * 7.0   08-16-2021   tom.h.ansley@medtronic.com   Added permission check for each action before display
 **/
global with sharing class ListViewHelper {
    
    public static final Id coreRTId = Schema.SObjectType.List_View__c.getRecordTypeInfosByDeveloperName().get('Core').getRecordTypeId();
    public static final Id customRTId = Schema.SObjectType.List_View__c.getRecordTypeInfosByDeveloperName().get('Custom').getRecordTypeId();
   
    public static final String TYPE_ALL    = 'All';
    public static final String TYPE_CORE   = 'Core';
    public static final String TYPE_CUSTOM = 'Custom';
    
    public static final String TYPE_BOOLEAN     = 'boolean';
    public static final String TYPE_DOUBLE      = 'double';
    public static final String TYPE_STRING      = 'string';
    public static final String TYPE_DECIMAL     = 'decimal';
    public static final String TYPE_CURRENCY    = 'currency';
    public static final String TYPE_DATE        = 'date';
    public static final String TYPE_DATETIME    = 'datetime';
    public static final String TYPE_NUMBER      = 'number';
    public static final String TYPE_BLOB        = 'blob';
    public static final String TYPE_PERCENT     = 'percent';
    public static final String TYPE_TIME        = 'time';

    public static final String SUBTYPE_MANUAL = 'Manual';
    public static final String SUBTYPE_TOOLING = 'Tooling';
    public static final String SUBTYPE_METADATA = 'Metadata';

    public static Integer offset           = -1;                  //used to hold the offset that is set when performing a query.

    public static String getPrimaryKey(List_View__c listView)
    {
        return listView.Object_Name__c.replace(' ', '_') + ':' + listView.API_Name__c;
    }

 	/*
	 * Method which, given a field type and field value will convert the provided value into the 
	 * correct object based on the provided fields type.
	 */
	public static Object getObjectForValue(String type, String value)
	{
        System.debug(LoggingLevel.FINE, 'Starting getObjectForValue - ' + type + '/' + value);
		Object objValue = null;

        if (type == ListViewHelper.TYPE_BOOLEAN) return Boolean.valueOf(value);
        else if (type == ListViewHelper.TYPE_DOUBLE) { 
                                                            if (String.isEmpty(value)) return null;
                                                            objValue = Double.valueOf(value);
                                                            }
        else if (type == ListViewHelper.TYPE_BLOB) return Blob.valueOf(value);
        else if (type == ListViewHelper.TYPE_CURRENCY) {
                                                                if (String.isEmpty(value)) return null;
                                                                objValue = Double.valueOf(value);
                                                                } 
        else if (type == ListViewHelper.TYPE_DATE) { 
                                                                if (String.isEmpty(value)) return null;
                                                                objValue = Date.valueOf(value);
                                                            }
        else if (type == ListViewHelper.TYPE_NUMBER) {
                                                                if (String.isEmpty(value)) return null;
                                                                objValue = Integer.valueOf(value);
                                                            }
        else if (type == ListViewHelper.TYPE_PERCENT) { 
                                                                if (String.isEmpty(value)) return null;
                                                                objValue = Double.valueOf(value);
                                                            }
        else if (type == ListViewHelper.TYPE_DATETIME) { 
                                                                if (String.isEmpty(value)) return null;
                                                                objValue = DateTime.valueOfGmt(value.replace('T', ' ').remove('.000Z')); //2021-07-21 20:45:00
                                                                }
        else if (type == ListViewHelper.TYPE_TIME) { 
                                                                if (String.isEmpty(value)) return null;
                                                                objValue = Time.newInstance(Integer.valueOf(value.substring(0, 2)), 
                                                                                            Integer.valueOf(value.substring(3, 5)),
                                                                                            Integer.valueOf(value.substring(6, 8)), 
                                                                                            Integer.valueOf(value.substring(9))); //03:15:00.000
                                                                }
        else objValue = value;		 

        System.debug(LoggingLevel.FINE, 'Finished getObjectForValue - ' + type + '/' + objValue);

		return objValue;
	}

    /**
    * @description Method to update a SINGLE record given its record Id and a map of field updates
    * @author tom.h.ansley@medtronic.com | 07-29-2021 
    * @param fieldValues map of field values with the record Id as key to return map of field values and the API field name being the key of the field values.
    * @return String blank string = success. Anything else is failure.    **/
    public static String updateRecords(Map<String, Map<String, String>> rowValues)
    {
        String result = '';
        Map<Id, SObject> updatedObjs = new Map<Id, SObject>(); //use map to ensure no duplicates

        if (rowValues.size() == 0) return result;

        //get object type from id
        String objType = HelperSchema.getSObjectTypeFromId(new List<String>(rowValues.keySet())[0]); //get the first record Id to determine object type. ALL types must be the same!!

        //instantiate object
        Type t = Type.forName(objType);

        for (String rowId: rowValues.keySet())
        {
            SObject rec = (SObject) t.newInstance();

            //add record Id to object
            rec.put('Id', rowId);

            Map<String, String> fieldValues = rowValues.get(rowId);
            for (String fieldName: fieldValues.keySet())
            {
                Object fieldValue = null;
                
                //if we have a lookup
                if (fieldName.contains('.'))
                {
                    fieldValue = fieldValues.get(fieldName);
                    String fixedFieldName = fieldName.substringBefore('.');

                    //if we have an OOTB lookup name then we need to add "Id"
                    if (!fixedFieldName.contains('__'))
                        fixedFieldName += 'Id';

                    rec.put(fixedFieldName, fieldValue);
                } else {
                    fieldValue = HelperSchema.getValueForField(objType, fieldName, fieldValues.get(fieldName));
                    rec.put(fieldName, fieldValue);
                }

            }

            updatedObjs.put(rowId, rec);
            System.debug(LoggingLevel.FINE, 'Saving record - ' + rec);
        }

        try {
            HelperDatabase.updateRecords(updatedObjs.values(), objType);
        } catch (Exception e) {
            String message = 'Exception during ListViewHelper.updateRecords() - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageErrorNonFuture(message);
            result = 'There was an error saving the records - ' + e.getMessage();
        }

        return result;
    }

    /**
    * @description Method to update a SINGLE record given its record Id and a map of field updates
    * @author tom.h.ansley@medtronic.com | 07-22-2021 
    * @param rowId the record Id of the record to be updated
    * @param fieldValues map of field values with the field name being the key
    * @return String blank string = success. Anything else is failure.
    **/
    public static String updateRecord(String rowId, Map<String, String> fieldValues)
    {
        String result = '';

        Map<String, Map<String, String>> fieldsByRowId = new Map<String, Map<String, String>>();

        fieldsByRowId.put(rowId, fieldValues);

        result = updateRecords(fieldsByRowId);

        return result;
    }
    

    /*
     ListViewHelper.updateListViewObjectsSetting();
     */
    public static void updateListViewObjectsSetting()
    {
        //get API Name/Label of all list view objects
        Map<String, String> listViewObjects = getInitListViewObjects();

        //turn to JSON
        String jsonStr = JSON.serialize(listViewObjects);

        System.debug(LoggingLevel.DEBUG, 'JSON - ' + jsonStr);

        ListViewConfigHelper.setOrgWideConfigParam('ListViewObjects', jsonStr);

    }

    /*
     * Method to return all CORE list views that have been altered by the running user
     * within the past 2 weeks.
     */
    public static Map<Id, ListView> getChangedListViews(Integer recLimit)
    {

        HelperSchema.checkListViewAccessible();

        Integer soqlLimit = 5000;
        if (recLimit != null)
            soqlLimit = recLimit;

        Map<Id, ListView> listViews = new Map<Id, ListView>([SELECT Id, 
                                                                    Name, 
                                                                    SObjectType, 
                                                                    DeveloperName, 
                                                                    LastModifiedById 
                                                            FROM ListView 
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
        HelperSchema.checkSelectAccessible('SELECT Id, Name, SObjectType, DeveloperName, CreatedById FROM ListView');
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
                simpliListView.RecordTypeId             = ListViewHelper.coreRTId;

                updatedListViews.add(simpliListView);

                System.debug(LoggingLevel.DEBUG, 'Updated Simpli List View - ' + simpliListView);

                //use the metadata API to try and enrich the listview data.
                HelperMetadataAPI.enrichListViewFromMetadata(simpliListView);

            } catch (Exception e) {
                String message = 'Exception during ListViewHelper.updateListViews(' + objectName + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
                ListViewErrorHelper.createUsageError(message); 
            }
    
        }

        HelperDatabase.upsertRecords(updatedListViews, 'Simpli_lv__List_View__c', 'simpli_lv__Primary_Key__c', true);

        return true;
    }

    /*
     * Method to retrieve list view describe details including the SOQL statement.
     * The set passed in is the CUSTOM list view Ids. This method should not be used 
     * for more than 50 list views. If more need to be updated then use the batch job.
     * 
     * HANDLES CORE ONLY
     */
    public static Boolean updateListViews(Set<Id> lvIds)
    {
        List<List_View__c> updatedListViews = new List<List_View__c>();

        //get the CUSTOM list views.
        List<List_View__c> listViews = getListViewsById(lvIds, true).values();
        Map<Id, List_View__c> listViewsByCoreId = new Map<Id, List_View__c>();

        //get the CORE list view Ids from the CUSTOM list views.
        //but only get those that the user is allowed to update
        for (List_View__c listView: listViews)
        {
            if (isUpdateable(listView))
                listViewsByCoreId.put(listView.Core_ListView_Id__c, listView);
        }

        //get the CORE list views.
        HelperSchema.checkSelectAccessible('SELECT Id, Name, SObjectType, DeveloperName, CreatedById FROM ListView');
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
                simpliListView.RecordTypeId             = ListViewHelper.coreRTId;

                updatedListViews.add(simpliListView);

                System.debug(LoggingLevel.DEBUG, 'Updated Simpli List View - ' + simpliListView);

                //use the metadata API to try and enrich the listview data.
                HelperMetadataAPI.enrichListViewFromMetadata(simpliListView);

            } catch (Exception e) {
                String message = 'Exception during ListViewHelper.updateListViews(' + lvIds + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
                ListViewErrorHelper.createUsageError(message); 
            }

        }

        HelperDatabase.upsertRecords(updatedListViews, 'simpli_lv__List_View__c', 'simpli_lv__Primary_Key__c', true);

        return true;
    }

    /*
    * Method to get all objects that have had their list views processed.
    * The map is returned as follows - (API Name, Label)
    */
    public static Map<String, String> getInitListViewObjects()
    {
        return getListViewObjects(new Set<String>(), new Set<String>(), true);
    }
    
    public static Map<String, String> getListViewObjects(Set<String> pageWideIncObjs, Set<String> pageWideExcObjs)
    {
        return getListViewObjects(pageWideIncObjs, pageWideExcObjs, false);
    }

    /*
    * Method to get all objects that have had their list views processed.
    * if includedObjects is passed in those objects will be returned. If
    * includedObjects is empty or null all objects are returned.
    * The map is returned as follows - (API Name, Label)
    *
        Map<String, String> objs = ListViewHelper.getListViewObjects(new Set<String>(), new Set<String>(), true);
        for (String key: objs.keySet())
        {
            System.debug(key + ' - ' + objs.get(key));
        }
    */
    public static Map<String, String> getListViewObjects(Set<String> pageWideIncObjs, Set<String> pageWideExcObjs, Boolean isInit)
    {
        System.debug(LoggingLevel.DEBUG, 'ListViewHelper.getListViewObjects(' + pageWideIncObjs + ', ' + pageWideExcObjs + ', ' + isInit + ')');

        Map<String, String> mappedListviewObjects = new Map<String, String>();
        Map<String, String> listViewObjects =  null;

        listViewObjects =  new Map<String, String>();

        String exclObjs = ListViewConfigHelper.getOrgWideConfigParam('ExcludedObjectTypes');
        System.debug(LoggingLevel.DEBUG, 'Org Wide Excluded Object Types - ' + exclObjs);
        Set<String> orgWideExcObjs = HelperString.getSetFromString(exclObjs, ',');
        System.debug(LoggingLevel.DEBUG, 'orgWideExcObjs size - ' + orgWideExcObjs.size());

        HelperSchema.checkListViewAccessible();

        if (isInit)
        {
            //------------------------------------
            //CORE LIST VIEWS (FRESH)
            //------------------------------------
            AggregateResult[] aggListViewObjects = [SELECT Object_Name__c 
                                                    FROM List_View__c 
                                                    WHERE Object_Name__c NOT IN :orgWideExcObjs 
                                                    AND Object_Name__c NOT IN :pageWideExcObjs
                                                    AND SubType__c != :SUBTYPE_TOOLING
                                                    GROUP BY Object_Name__c 
                                                    LIMIT 2000]; //limit for security review. No other reason


            for (AggregateResult result: aggListViewObjects)
            {
                String objAPIName = (String) result.get('simpli_lv__Object_Name__c');

                System.debug(LoggingLevel.DEBUG, 'objAPIName - ' + objAPIName);

                Schema.DescribeSObjectResult objDesc = HelperSchema.getObjectSchema(objAPIName);
                if (objDesc != null)
                {
                    String objLabel = objDesc.getLabel();
                    listViewObjects.put(objAPIName, objLabel);
                }
            }

        } else {

            //------------------------------------
            //CORE LIST VIEWS (CACHED)
            //------------------------------------
            String lvObjsStr = ListViewConfigHelper.getOrgWideConfigParam('ListViewObjects');
            Map<String, String> lvObjs = (Map<String, String>) JSON.deserialize(lvObjsStr, Map<String, String>.class);
    
            for (String objName: lvObjs.keySet())
                listViewObjects.put(objName, lvObjs.get(objName));

            //------------------------------------
            //OTHER LIST VIEWS
            //------------------------------------
            Map<Id, List_View__c> listViews = getListViewsByType(TYPE_CUSTOM);

            for (List_View__c listView: listViews.values())
            {
                //only admin can view tooling API list views
                if (listView.SubType__c != SUBTYPE_TOOLING || HelperProfile.isSysAdmin())
                {
                    Schema.DescribeSObjectResult objDesc = HelperSchema.getObjectSchema(listView.Object_Name__c);
                    if (objDesc != null && !orgWideExcObjs.contains(objDesc.getName()) && !pageWideExcObjs.contains(objDesc.getName()))
                    {
                        String objLabel = objDesc.getLabel();
                        listViewObjects.put(listView.Object_Name__c, objLabel);
                    } else if (!orgWideExcObjs.contains(listView.Object_Name__c) && !pageWideExcObjs.contains(listView.Object_Name__c)) {
                        listViewObjects.put(listView.Object_Name__c, listView.Object_Name__c);
                    }
                }
            }

        }


        String inclObjs = ListViewConfigHelper.getOrgWideConfigParam('IncludedObjectTypes');
        Set<String> orgWideIncObjs = HelperString.getSetFromString(inclObjs, ',');

        System.debug(LoggingLevel.DEBUG, 'pageWideIncObjs ' + pageWideIncObjs);
        System.debug(LoggingLevel.DEBUG, 'orgWideIncObjs ' + orgWideIncObjs);
    
        for (String objAPIName: listViewObjects.keySet())
        {

            System.debug('Working ' + objAPIName);
            //if there are PAGE included objects then only include those.
            if (pageWideIncObjs.isEmpty() || pageWideIncObjs.contains(objAPIName))
            {

                //if there are ORG WIDE included objects then only include those.
                if (orgWideIncObjs.isEmpty() || orgWideIncObjs.contains(objAPIName))
                {
                    mappedListviewObjects.put(objAPIName, listViewObjects.get(objAPIName));
                    System.debug(LoggingLevel.DEBUG, 'Adding mapping - ' + objAPIName);
                }
            }
        }

        String resultStr = '\n\n-------------------------------------------------\n';
        for (String objectName: mappedListviewObjects.keySet())
            resultStr += 'Object ' + objectName + ' - ' + mappedListviewObjects.get(objectName) + '\n';
        resultStr = '-------------------------------------------------\n\n';

        System.debug(LoggingLevel.DEBUG, resultStr);
        return mappedListviewObjects;
    }

    public static Map<Id, List_View__c> getListViewsByType(String type)
    {
        System.debug(LoggingLevel.DEBUG, 'Called getListViewsByType(type ' + type);

        Set<Id> rtIds = new Set<Id>();
        if (type == TYPE_ALL || type == TYPE_CUSTOM)
            rtIds.add(ListViewHelper.customRTId);
        if (type == TYPE_ALL || type == TYPE_CORE)
            rtIds.add(ListViewHelper.coreRTId);

        HelperSchema.checkListViewAccessible();

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
                                                 LastModifiedBy.Name,
                                                 RecordType.Name,
                                                 Custom_Apex_Class__c,
                                                 Subtype__c
                                           FROM List_View__c
                                          WHERE RecordTypeId IN :rtIds];

        Map<Id, List_View__c> lvs = new Map<Id, List_View__c>();

        //now check security
        for (List_View__c lv: listviews)
        {
            lvs.put(lv.Id, lv);
        }
        return lvs;

    }

    /*
     * Method to get list views by Id
     */
    public static Map<Id, List_View__c> getListViewsById(Set<Id> lvIds, Boolean onlyCore)
    {
        System.debug(LoggingLevel.DEBUG, 'Called getListViewsById(lvIds ' + lvIds + ', onlyCore ' + onlyCore);

        Set<Id> rtIds = new Set<Id>();
        rtIds.add(ListViewHelper.coreRTId);
        if (!onlyCore)
            rtIds.add(ListViewHelper.customRTId);

        HelperSchema.checkListViewAccessible();

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
                                                 LastModifiedBy.Name,
                                                 RecordType.Name,
                                                 Custom_Apex_Class__c,
                                                 Subtype__c
                                           FROM List_View__c
                                          WHERE Id IN :lvIds
                                                AND RecordTypeId IN :rtIds];

        Map<Id, List_View__c> lvs = new Map<Id, List_View__c>();

        //now check security
        for (List_View__c lv: listviews)
        {
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

        //if we have a core list view object make sure that the user has access to the object itself if its
        if (HelperSchema.isObject(objAPIName) && !HelperSchema.checkObjectAccessible(objAPIName, false))
            throw new ListViewException('Object ' + objAPIName + ' is not accessible to the current user');

        //get list view data
        HelperSchema.checkListViewAccessible();
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
                                                LastModifiedBy.Name,
                                                RecordType.Name,
                                                Custom_Apex_Class__c,
                                                Subtype__c
                                        FROM List_View__c
                                        WHERE Object_Name__c = :objAPIName
                                        ORDER BY Label__c];

        Map<String, List_View__c> listviewsByName = new Map<String, List_View__c>();

        //now check security
        for (List_View__c listview: listviews)
        {
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

        HelperSchema.checkListViewAccessible();

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
                                                LastModifiedBy.Name,
                                                RecordType.Name,
                                                Custom_Apex_Class__c,
                                                Subtype__c
                                        FROM List_View__c
                                        WHERE Object_Name__c = :objAPIName
                                            AND API_Name__c = :listViewAPIName];

        Map<Id, List_View__c> listviewsById = new Map<Id, List_View__c>();

        //now check security
        for (List_View__c listview: listviews)
        {
            listViewsById.put(listview.Id, listview);
        }

        return listviewsById;
    }

    public static List<SObject> getListViewData(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Boolean example, Integer offset)
    {

        String debug = '\n\nStarting getListViewData - \n';
        debug += 'listview                        - ' + listview + '\n';
        debug += 'listview.Core_ListView_Query__c - ' + listview.Core_ListView_Query__c + '\n';
        debug += 'lvConfig                        - ' + lvConfig + '\n';
        debug += 'sortData                        - ' + sortData + '\n';
        debug += 'joinFieldName                   - ' + joinFieldName + '\n';
        if (joinRecordIds != null)
            debug += 'joinRecordIds Size - ' + joinRecordIds.size() + '\n';
        debug += 'joinRecordIds      - ' + joinRecordIds + '\n\n';
        System.debug(LoggingLevel.DEBUG, debug);

        Map<String, String> lvConfigParams = new Map<String, String>();
        if (lvConfig != null) //there might not be config yet for this list view
        {
            for (List_View_Config_Parameter__c param: lvConfig.listViewConfig.List_View_Config_Parameters__r)
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
        if (query.containsIgnoreCase(' ORDER BY '))
        {
            whereStr = query.substringBetween(' FROM ', ' ORDER BY ');
        } else {
            whereStr = query.substringAfter(' FROM ');
        }

        //------------------------------------------------------
        // Update all additional fields on the SELECT statement
        //------------------------------------------------------
        List<String> selectFields = selectStr.split(',');
        selectStr = '';
        for (String field: selectFields)
        {
            //do security validation on regular fields. If the field is a lookup the security is performed later
            Boolean isAccessible = false;
            if (!field.contains('.'))
            {
                if (field.contains('toLabel(')) field = field.substringBetween('toLabel(', ')');
                isAccessible = HelperSchema.checkObjectFieldAccessible(listview.Object_Name__c, field, false);
            } else {
                isAccessible = true;
            }
            if (isAccessible)
                selectStr += field + ', ';
        }
        selectStr = selectStr.removeEnd(', ');


        if (HelperSchema.isValidSFDCFieldName(listview.Object_Name__c, 'IsDeleted'))
            selectStr += ', IsDeleted';

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
        if (joinFieldName != '' && joinRecordIds?.size() > 0)
        {
            if (whereStr.containsIgnoreCase(' WHERE '))
                whereStr += ' AND ' + joinFieldName + ' IN :joinRecordIds';
            else
                whereStr += ' WHERE ' + joinFieldName + ' IN :joinRecordIds';
        }

        //------------------------------------------------------
        // Handle all changes to the ORDER BY statement
        //------------------------------------------------------
        if (sortData?.size() > 0)
        {
            System.debug('SORT DATA - ' + sortData);
            orderByStr = ' ORDER BY ';
            
            for (ListViewHelper.ColumnSortData columnSortData: sortData)
            {
                //make sure the field name is valid
                if (HelperSchema.isValidSFDCFieldName(listview.Object_Name__c, columnSortData.fieldName))
                {
                    orderByStr += columnSortData.fieldName + ' ';
                    if (columnSortData.sortDirection == true)
                        orderByStr += 'ASC NULLS LAST, ';
                    else
                        orderByStr += 'DESC NULLS FIRST, ';
                } else {
                    System.debug(LoggingLevel.DEBUG, 'Sort column not valid - ' + columnSortData.fieldName);
                    throw new ListViewException('Sort column not valid - ' + columnSortData.fieldName);
                }
            }

            orderByStr = orderByStr.removeEnd(', ').removeEnd('ORDER BY ');
        }

        //------------------------------------------------------
        // Handle the LIMIT statement
        //------------------------------------------------------
        String limitStr = ' LIMIT ';
        
        //if we are getting join records then do not use a limit
        if (joinRecordIds?.size() > 0)
        {
            limitStr = '';
        
        } else {

            //if we only need an example record
            if (example)
            {
                limitStr = ' LIMIT 1';
                
            //if we have a list view limit then use it
            } else if (lvConfigParams.get('ReturnSize') != null)
            {
                Integer returnSize = Integer.valueOf(lvConfigParams.get('ReturnSize'));
                limitStr = ' LIMIT ' + returnSize;
                if (offset == null) offset = -1;

                //if we have an offset or we are returning LARGE datasets
                if (offset != -1 || returnSize > 500)
                {
                    Integer queryPagingSize = Integer.valueOf(ListViewConfigHelper.getOrgWideConfigParam('QueryPagingSize'));
                    Integer rowLimit = queryPagingSize;
                    //if we DO NOT have an offset then set to 0
                    if (offset == -1)
                    {
                        offset = 0;

                    //if we DO have an offset then increase it but not above the return size max
                    } else {
                        System.debug(LoggingLEvel.DEBUG, 'Offset - ' + offset);
                        System.debug(LoggingLEvel.DEBUG, 'returnSize - ' + returnSize);
                        
                        //if we have NOT hit the max
                        if ((offset + rowLimit) < returnSize)
                        {
                            offset = offset + queryPagingSize;
                        }

                        if ((offset + rowLimit) > returnSize)
                        {
                            rowLimit = returnSize - offset;
                        }
                    }
                    limitStr = ' LIMIT ' + rowLimit + ' OFFSET ' + offset;

                    ListViewHelper.offset = offset; //set the offset as static to be used up the stack.
                }

            //otherwise use 100
            } else {
                limitStr = ' LIMIT 100';
            }
        }

        System.debug(LoggingLevel.DEBUG, 'LIMIT STR - ' + limitStr);

        //------------------------------------------------------
        // Handle the ALL ROWS statement
        //------------------------------------------------------
        String allRowsStr = '';
        if (offset == -1                                                   //Cannot use ALL ROWS with OFFSET
            && lvConfigParams.get('AllRows') != null                      //if we have AllRows variable
            && lvConfigParams.get('AllRows') == 'true'                     //if AllRows = true
            && lvConfigParams.get('ReturnSize') != null                    //if we have ReturnSize variable
            && (Integer.valueOf(lvConfigParams.get('ReturnSize')) < 750)) //if ReturnSize < 750
        {
            allRowsStr += ' ALL ROWS';
        }

        //------------------------------------------------------
        // Put the query back together again
        //------------------------------------------------------
        query = 'SELECT ' + selectStr + ' FROM ' + whereStr + orderByStr + limitStr + allRowsStr;

        System.debug(LoggingLevel.DEBUG, 'Final SOQL - ' + query);

        //get rows of data from query
        List<SObject> objectRows = null;
        try {
            objectRows = Database.query(query);
        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during ListViewHelper.getListViewData(' + query + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            throw new ListViewException('There was an error during data retrieval. Please try again or notify an administrator. (' + e.getMessage() + ')');
        }
        
        return objectRows;

    }

    /*
     * Method to use the SOQL query retrieved from the core listview describe, amend it to include
     * the possible additional fields added by the user and then use it to get the data.
     */ 
    public static List<SObject> getListViewData(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds)
    {
        return getListViewData(listview, lvConfig, sortData, joinFieldName, joinRecordIds, false, -1);
    }

    /*
     * Method to use the SOQL query retrieved from the core listview describe, amend it to include
     * the possible additional fields added by the user and then use it to get the data.
     */ 
    public static List<SObject> getListViewData(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Integer offset)
    {
        return getListViewData(listview, lvConfig, sortData, joinFieldName, joinRecordIds, false, offset);
    }

    /*
     * Method to use the SOQL query retrieved from the core listview describe, amend it to include
     * the possible additional fields added by the user and then use it to get the data.
     */ 
    public static List<SObject> getListViewData(String soql, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds)
    {
        return getListViewData(soql, lvConfig, sortData, joinFieldName, joinRecordIds, false, -1);
    }

    /*
     * Method to use the SOQL query retrieved from the core listview describe, amend it to include
     * the possible additional fields added by the user and then use it to get the data.
     */ 
    public static List<SObject> getListViewData(String soql, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Integer offset)
    {
        return getListViewData(soql, lvConfig, sortData, joinFieldName, joinRecordIds, false, offset);
    }

    /*
      ListViewHelper.getListViewData('SELECT Name, List_View_Label__c, List_View_Object__c, LastModifiedDate, LastModifiedBy.Name, Primary_Key__c, (SELECT Parameter_Name__c, Parameter_Type__c, Parameter_Label__c, Parameter_Value__c FROM List_View_Config_Parameters__r ORDER BY Parameter_Label__c), (SELECT Field_Name__c, Highlight_Color__c, Operator__c, Order__c, Value__c FROM List_View_Config_Conditions__r ORDER BY Order__c ASC) FROM List_View_Config__c', null, null, null, null, false);
     */
    public static List<SObject> getListViewData(String soql, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Boolean example, Integer offset)
    {
        soql = getSOQLQuery(soql, lvConfig, sortData, joinFieldName, joinRecordIds, example, offset);
        
        //get rows of data from query
        List<SObject> objectRows = null;
        try {
            objectRows = Database.query(soql);
        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during ListViewHelper.getListViewData(' + soql + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString());
            throw new ListViewException('There was an error during data retrieval. Please try again or notify an administrator. (' + e.getMessage() + ')');
        }
        
        return objectRows;

    }
    
    /**
    * @description Convenience method which assumes the following - 
                   i.  This is not to retrieve an example.
                   ii. This does not have any paging requirements
    * @author tom.h.ansley@medtronic.com | 06-21-2021 
    **/
    public static String getSOQLQuery(String soql, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds)
    {
        return getSOQLQuery(soql, lvConfig, sortData, joinFieldName, joinRecordIds, false, -1);
    }

    public static String getSOQLQuery(String soql, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Boolean example, Integer offset)
    {

        String debug = '\n\nStarting getListViewData - \n';
        debug += 'soql                            - ' + soql + '\n';
        debug += 'lvConfig                        - ' + lvConfig + '\n';
        debug += 'sortData                        - ' + sortData + '\n';
        debug += 'joinFieldName                   - ' + joinFieldName + '\n';

        if (joinRecordIds != null)
            debug += 'joinRecordIds Size - ' + joinRecordIds.size() + '\n';
        debug += 'joinRecordIds      - ' + joinRecordIds + '\n\n';
        System.debug(LoggingLevel.DEBUG, debug);

        Map<String, String> lvConfigParams = new Map<String, String>();
        if (lvConfig != null) //there might not be config yet for this list view
        {
            for (List_View_Config_Parameter__c param: lvConfig.listViewConfig.List_View_Config_Parameters__r)
                lvConfigParams.put(param.Parameter_Name__c, param.Parameter_Value__c);
        }
        
        //---------------------------------------------------
        // Parse out the query retrieved from the list view.
        //---------------------------------------------------
        String selectStr = soql.substringBeforeLast(' FROM ');
        System.debug(LoggingLevel.DEBUG, 'selectStr - ' + selectStr);
        String objectName = soql.substringAfterLast(' FROM ');
        if (objectName.contains(' '))
            objectName = objectName.substringBefore(' ');
        System.debug(LoggingLevel.DEBUG, 'objectName - ' + objectName);
        String whereStr = 'WHERE ' + soql.substringAfterLast(' WHERE ');
        if (whereStr == 'WHERE ') 
            whereStr = '';
        if (whereStr.containsIgnoreCase(' ORDER BY '))
            whereStr = whereStr.substringBefore(' ORDER BY ');
        System.debug(LoggingLevel.DEBUG, 'whereStr - ' + whereStr);
        String orderByStr = soql.substringAfterLast(' FROM ').substringAfterLast(' ORDER BY ').substringBeforeLast(' LIMIT ');
        System.debug(LoggingLevel.DEBUG, 'orderByStr - ' + orderByStr);
        String limitStr = '';
        if (soql.containsIgnoreCase(' LIMIT '))
            limitStr = soql.substring(soql.lastIndexOf('LIMIT'));
        System.debug(LoggingLevel.DEBUG, 'limitStr - ' + limitStr);

        //check the object is accessible by this user
        HelperSchema.checkObjectAccessible(objectName);

        //------------------------------------------------------
        // Handle all changes to the WHERE statement
        //------------------------------------------------------
        if (joinFieldName != '' && joinRecordIds?.size() > 0)
        {
            if (whereStr.containsIgnoreCase(' WHERE '))
                whereStr += ' AND ' + joinFieldName + ' IN :joinRecordIds';
            else
                whereStr += ' WHERE ' + joinFieldName + ' IN :joinRecordIds';
        }

        //------------------------------------------------------
        // Handle all changes to the ORDER BY statement
        //------------------------------------------------------
        if (sortData?.size() > 0)
        {
            System.debug('SORT DATA - ' + sortData);
            orderByStr = ' ORDER BY ';
            
            for (ListViewHelper.ColumnSortData columnSortData: sortData)
            {
                //make sure the field name is valid if we are not dealing with an API callout
                if (lvConfig?.getListView().Subtype__c == ListViewHelper.SUBTYPE_TOOLING || HelperSchema.isValidSFDCFieldName(objectName, columnSortData.fieldName))
                {
                    orderByStr += columnSortData.fieldName + ' ';
                    if (columnSortData.sortDirection == true)
                        orderByStr += 'ASC NULLS LAST, ';
                    else
                        orderByStr += 'DESC NULLS FIRST, ';
                } else {
                    System.debug(LoggingLevel.DEBUG, 'Sort column not valid - ' + columnSortData.fieldName);
                }
            }

            orderByStr = orderByStr.removeEnd(', ').removeEnd('ORDER BY ');
        } else {
            if (orderByStr != '')
                orderByStr = ' ORDER BY ' + orderByStr;
        }

        //------------------------------------------------------
        // Handle the LIMIT statement
        //------------------------------------------------------
        
        //if we are getting join records then do not use a limit
        if (joinRecordIds?.size() > 0)
        {
            limitStr = '';
        
        } else {

            //if we only need an example record
            if (example)
            {
                limitStr = ' LIMIT 1';
                
            //if we have a list view limit then use it
            } else if (lvConfigParams.get('ReturnSize') != null)
            {
                Integer returnSize = Integer.valueOf(lvConfigParams.get('ReturnSize'));
                limitStr = ' LIMIT ' + returnSize;
                if (offset == null) offset = -1;

                //if we have an offset or we are returning LARGE datasets
                if (offset != -1 || returnSize > 500)
                {
                    Integer rowLimit = 500;
                    //if we DO NOT have an offset then set to 0
                    if (offset == -1)
                    {
                        offset = 0;

                    //if we DO have an offset then increase it but not above the return size max
                    } else {
                        System.debug(LoggingLEvel.DEBUG, 'Offset - ' + offset);
                        System.debug(LoggingLEvel.DEBUG, 'returnSize - ' + returnSize);
                        
                        //if we have NOT hit the max
                        if ((offset + rowLimit) < returnSize)
                        {
                            offset = offset + 500;
                        }

                        if ((offset + rowLimit) > returnSize)
                        {
                            rowLimit = returnSize - offset;
                        }
                    }
                    limitStr = ' LIMIT ' + rowLimit + ' OFFSET ' + offset;

                    ListViewHelper.offset = offset; //set the offset as static to be used up the stack.
                }

            //otherwise use 100
            } else {
                limitStr = ' LIMIT 100';
            }
        }
        System.debug(LoggingLevel.DEBUG, 'LIMIT STR 2 - ' + limitStr);

        //------------------------------------------------------
        // Handle the ALL ROWS statement
        //------------------------------------------------------
        String allRowsStr = '';
        if (offset == -1                                                   //Cannot use ALL ROWS with OFFSET
            && lvConfigParams.get('AllRows') != null                       //if we have AllRows variable
            && lvConfigParams.get('AllRows') == 'true'                     //if AllRows = true
            && lvConfigParams.get('ReturnSize') != null                    //if we have ReturnSize variable
            && (Integer.valueOf(lvConfigParams.get('ReturnSize')) < 750))  //if ReturnSize < 750
        {
            allRowsStr += ' ALL ROWS';
        }

        //------------------------------------------------------
        // Put the query back together again
        //------------------------------------------------------
        soql = selectStr + ' FROM ' + objectName + ' ' + whereStr + orderByStr + limitStr + allRowsStr;

        System.debug(LoggingLevel.DEBUG, 'Final SOQL - ' + soql);

        return soql;
    }

    global static void insertCoreConfiguration()
    {

        //-----------------------------------------------------
        // Create List View Actions
        //-----------------------------------------------------

        List<List_View_Action__c> actions = new List<List_View_Action__c>();

        List_View_Action__c orgNewAction = new List_View_Action__c();
        orgNewAction.Apex_Class_Name__c  = 'ListViewActionNull';
        orgNewAction.Label__c            = 'New';
        orgNewAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		orgNewAction.Permissions__c      = ListViewActionHelper.PERM_CREATE;

        actions.add(orgNewAction);

        List_View_Action__c orgCloneAction = new List_View_Action__c();
        orgCloneAction.Apex_Class_Name__c  = 'ListViewActionNull';
        orgCloneAction.Label__c            = 'Clone';
        orgCloneAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		orgCloneAction.Permissions__c      = ListViewActionHelper.PERM_CREATE;

        actions.add(orgCloneAction);

        List_View_Action__c orgEditAction = new List_View_Action__c();
        orgEditAction.Apex_Class_Name__c  = 'ListViewActionNull';
        orgEditAction.Label__c            = 'Edit';
        orgEditAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		orgEditAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;

        actions.add(orgEditAction);

        List_View_Action__c orgEditAllAction = new List_View_Action__c();
        orgEditAllAction.Apex_Class_Name__c  = 'ListViewActionNull';
        orgEditAllAction.Label__c            = 'Edit All';
        orgEditAllAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		orgEditAllAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;

        actions.add(orgEditAllAction);

        List_View_Action__c orgDeleteAction = new List_View_Action__c();
        orgDeleteAction.Apex_Class_Name__c  = 'ListViewActionDelete';
        orgDeleteAction.Label__c            = 'Delete';
        orgDeleteAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		orgDeleteAction.Permissions__c      = ListViewActionHelper.PERM_DELETE;

        actions.add(orgDeleteAction);

        List_View_Action__c acctUpdateAction = new List_View_Action__c();
        acctUpdateAction.Apex_Class_Name__c  = 'ListViewActionUpdate';
        acctUpdateAction.Label__c            = 'Update';
        acctUpdateAction.Object_Type__c      = 'Account';
        acctUpdateAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		acctUpdateAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;

        actions.add(acctUpdateAction);

        List_View_Action__c oppsCloseUpdateAction = new List_View_Action__c();
        oppsCloseUpdateAction.Apex_Class_Name__c  = 'ListViewActionOppsClose';
        oppsCloseUpdateAction.Label__c            = 'Set Close Lost';
        oppsCloseUpdateAction.Object_Type__c      = 'Opportunity';
        oppsCloseUpdateAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		oppsCloseUpdateAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;

        actions.add(oppsCloseUpdateAction);

        HelperDatabase.insertRecords(actions, 'Simpli_lv__List_View_Action__c');

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

        HelperDatabase.insertRecords(params, 'Simpli_lv__List_View_Action_Parameter__c');

        //-----------------------------------------------------
        // Create List View Configs
        //-----------------------------------------------------

        List<List_View_Config__c> configs = new List<List_View_Config__c>();

        List_View_Config__c config = new List_View_Config__c();
        config.Name                = 'PlatinumandGoldSLACustomers';
        config.List_View_Label__c  = 'Platinum And Gold SLA Customers';
        config.List_View_Object__c = 'Account';
        config.Primary_Key__c      = config.List_View_Object__c + ':' + config.Name;
        configs.add(config);

        List_View_Config__c config2 = new List_View_Config__c();
        config2.Name                = 'All';
        config2.List_View_Object__c = 'All';
        config.List_View_Label__c   = 'Org Wide Configuration';
        config2.Primary_Key__c      = config2.List_View_Object__c + ':' + config2.Name;
        configs.add(config2);

        List_View_Config__c config3 = new List_View_Config__c();
        config3.Name                = 'AllAccounts';
        config3.List_View_Object__c = 'Account';
        config.List_View_Label__c   = 'All Accounts';
        config3.Primary_Key__c      = config3.List_View_Object__c + ':' + config3.Name;
        configs.add(config3);

        HelperDatabase.insertRecords(configs, 'Simpli_lv__List_View_Config__c');

        List<List_View_Config_Parameter__c> params2 = new List<List_View_Config_Parameter__c>();
      
        List_View_Config_Parameter__c param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config.Id;
        param2.Parameter_Name__c   = 'AdditionalFields';
        param2.Parameter_Type__c   = 'String';
        param2.Parameter_Value__c  = 'Type, AnnualRevenue,CreatedBy.Name,Owner.Profile.Name';
        param2.Parameter_Label__c  = 'Additional Fields';
        params2.add(param2);
        
        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config.Id;
        param2.Parameter_Name__c   = 'TotalColumns';
        param2.Parameter_Type__c   = 'String';
        param2.Parameter_Value__c  = 'AnnualRevenue';
        param2.Parameter_Label__c  = 'Total Columns';
        params2.add(param2);
        
        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config.Id;
        param2.Parameter_Name__c   = 'TotalColumnsColor';
        param2.Parameter_Type__c   = 'Color';
        param2.Parameter_Value__c  = '#6C95BD';
        param2.Parameter_Label__c  = 'Total Row Color';
        params2.add(param2);
        
        //---------------------------------------
        // ALL:ALL Config
        //---------------------------------------
        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'ListViewObjects';
        param2.Parameter_Type__c   = 'String';
        param2.Parameter_Value__c  = '';
        param2.Parameter_Label__c  = 'List View Objects';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'IncludedObjectTypes';
        param2.Parameter_Type__c   = 'String';
        param2.Parameter_Value__c  = '';
        param2.Parameter_Label__c  = 'Included Object Types';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'ExcludedObjectTypes';
        param2.Parameter_Type__c   = 'String';
        param2.Parameter_Value__c  = 'FlowInterview,CollaborationGroup,Idea,OperatingHours,ServiceAppointment,WorkType,Solution';
        param2.Parameter_Label__c  = 'Excluded Object Types';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplayActionsButton';
        param2.Parameter_Type__c   = 'Boolean';
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Actions Button';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'AllowAdmin';
        param2.Parameter_Type__c   = 'Boolean';
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Admin Button';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplayListViewReprocessingButton';
        param2.Parameter_Type__c   = 'Boolean';
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display List View Reprocessing Button';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplayOriginalListViewButton';
        param2.Parameter_Type__c   = 'Boolean';
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Original List View Button';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplaySelectedCount';
        param2.Parameter_Type__c   = 'Boolean';
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Selected Count';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'AllowDataExport';
        param2.Parameter_Type__c   = 'Boolean';
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Allow Data Export';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'AllowAutomaticDataRefresh';
        param2.Parameter_Type__c   = 'Boolean';
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Allow Automatic Data Refresh';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplayRowCount';
        param2.Parameter_Type__c   = 'Boolean';
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Row Count';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'MaxRowsDisplayed';
        param2.Parameter_Type__c   = 'Number';
        param2.Parameter_Value__c  = '2500';
        param2.Parameter_Label__c  = 'Max Rows Displayed';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'QueryPagingSize';
        param2.Parameter_Type__c   = 'Number';
        param2.Parameter_Value__c  = '250';
        param2.Parameter_Label__c  = 'Query Paging Size';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'IsInitialized';
        param2.Parameter_Type__c   = 'Boolean';
        param2.Parameter_Value__c  = 'false';
        param2.Parameter_Label__c  = 'Is Initialized';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'AllowInlineEditing';
        param2.Parameter_Type__c   = 'Boolean';
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Allow Inline Editing';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplayTextSearch';
        param2.Parameter_Type__c   = 'Boolean';
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Text Search';
        params2.add(param2);

        //---------------------------------------
        // 
        //---------------------------------------
        param2 = new List_View_Config_Parameter__c();
		param2.Parameter_Name__c = 'AdditionalFields';
		param2.Parameter_Type__c = 'String';
		param2.Parameter_Value__c = 'CreatedBy.Name, Owner.Profile.Name, AnnualRevenue';
		param2.List_View_Config__c = config3.Id;
        param2.Parameter_Label__c  = 'Additional Fields';
        params2.add(param2);
        
        param2 = new List_View_Config_Parameter__c();
		param2.Parameter_Name__c = 'TotalColumns';
		param2.Parameter_Type__c = 'String';
		param2.Parameter_Value__c = 'AnnualRevenue';
		param2.List_View_Config__c = config3.Id;
        param2.Parameter_Label__c  = 'Total Columns';
        params2.add(param2);
        
        param2 = new List_View_Config_Parameter__c();
		param2.Parameter_Name__c = 'TotalColumnsColor';
		param2.Parameter_Type__c = 'Color';
		param2.Parameter_Value__c = '#6C95BD';
		param2.List_View_Config__c = config3.Id;
        param2.Parameter_Label__c  = 'Total Row Color';
        params2.add(param2);
        
        HelperDatabase.insertRecords(params2, 'Simpli_lv__List_View_Config_Parameter__c');

        List<List_View_Config_Condition__c> conditions = new List<List_View_Config_Condition__c>();

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.List_View_Config__c = config.Id;
        condition.Field_Name__c       = 'Account Name';
        condition.Operator__c         = 'Contains';
        condition.Value__c            = 'Burlington';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = '#c59e9e';
        conditions.add(condition);

        HelperDatabase.insertRecords(conditions, 'Simpli_lv__List_View_Config_Condition__c');

        //-----------------------------------------------------
        // Create List Views
        //-----------------------------------------------------
        List<List_View__c> listViews = new List<List_View__c>();

        List_View__c lv             = new List_View__c();
        lv.Custom_Apex_Class__c     = 'ListViewCustomToolingQuery';
        lv.Label__c                 = 'Apex Logs';
        lv.Core_ListView_Columns__c = '[{"fieldNameOrPath":"DurationMilliseconds","type":"decimal","label":"Duration"},{"fieldNameOrPath":"Id","type":"string","label":"Id"},{"fieldNameOrPath":"LogLength","type":"decimal","label":"Length"},{"fieldNameOrPath":"LogUserId","type":"string","label":"User"},{"fieldNameOrPath":"Operation","type":"string","label":"Operation"},{"fieldNameOrPath":"Request","type":"string","label":"Request"},{"fieldNameOrPath":"StartTime","type":"string","label":"Start Time"},{"fieldNameOrPath":"Status","type":"string","label":"Status"}]';
        lv.Core_ListView_Query__c   = 'SELECT DurationMilliseconds,Id,LogLength,LogUserId,Operation,Request,StartTime,Status FROM ApexLog ORDER BY StartTime DESC';
        lv.Object_Name__c           = 'ApexLog';
        lv.RecordTypeId             = ListViewHelper.customRTId;
        lv.Subtype__c               = ListViewHelper.SUBTYPE_TOOLING;

        listViews.add(lv);

        lv                          = new List_View__c();
        lv.Custom_Apex_Class__c     = 'ListViewCustomManual';
        lv.Label__c                 = 'Custom Non-Core Example';
        lv.Core_ListView_Columns__c = '[{"fieldNameOrPath":"Name","type":"string","label":"Name"},{"fieldNameOrPath":"simpli_lv__List_View_Object__c","type":"string","label":"Object"},{"fieldNameOrPath":"LastModifiedDate","type":"string","label":"Last Modified"},{"fieldNameOrPath":"LastModifiedBy.Name","type":"string","label":"Last Modified By"},{"fieldNameOrPath":"simpli_lv__Primary_Key__c","type":"string","label":"Primary Key"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Parameters__r.simpli_lv__Parameter_Name__c","type":"string","label":"Parameter Name"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Parameters__r.simpli_lv__Parameter_Type__c","type":"string","label":"Parameter Type"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Parameters__r.simpli_lv__Parameter_Label__c","type":"string","label":"Parameter Label"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Parameters__r.simpli_lv__Parameter_Value__c","type":"string","label":"Parameter Value"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Conditions__r.simpli_lv__Field_Name__c","type":"string","label":"Field Name"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Conditions__r.simpli_lv__Highlight_Color__c","type":"string","label":"Highlight Color"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Conditions__r.simpli_lv__Operator__c","type":"string","label":"Operator"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Conditions__r.simpli_lv__Order__c","type":"string","label":"Order"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Conditions__r.simpli_lv__Value__c","type":"string","label":"Value"}]';
        lv.Core_ListView_Query__c   = 'SELECT Name,List_View_Label__c,List_View_Object__c,LastModifiedDate,LastModifiedBy.Name,Primary_Key__c,(SELECT Parameter_Name__c,Parameter_Type__c,Parameter_Label__c,Parameter_Value__c FROM List_View_Config_Parameters__r ORDER BY Parameter_Label__c),( SELECT Field_Name__c,Highlight_Color__c,Operator__c,Order__c,Value__c FROM List_View_Config_Conditions__r ORDER BY Order__c ASC) FROM List_View_Config__c';
        lv.Object_Name__c           = 'simpli_lv__List_View_Config__c';
        lv.RecordTypeId             = ListViewHelper.customRTId;
        lv.Subtype__c               = 'Manual';

        listViews.add(lv);

        lv                          = new List_View__c();
        lv.Custom_Apex_Class__c     = 'ListViewCustomManual';
        lv.Label__c                 = 'Custom Opportunity Example';
        lv.Core_ListView_Columns__c = '[{"fieldNameOrPath": "Name","type": "string","label": "Opp Name"},{"fieldNameOrPath": "StageName","type": "string","label": "Stage"},{"fieldNameOrPath": "CloseDate","type": "date","label": "Close Date"},{"fieldNameOrPath": "ExpectedRevenue","type": "currency","label": "Revenue"},{"fieldNameOrPath": "Account.Name","type": "string","label": "Acct Name"},{"fieldNameOrPath": "Account.Type","type": "string","label": "Acct Type"},{"fieldNameOrPath": "Account.Industry","type": "string","label": "Acct Industry"},{"fieldNameOrPath": "PriceBook2.Name","type": "string","label": "Price Book"},{"fieldNameOrPath": "PriceBook2.IsActive","type": "string","label": "PB Active"},{"fieldNameOrPath": "OpportunityLineItems.Name","type": "string","label": "LI Name"},{"fieldNameOrPath": "OpportunityLineItems.ListPrice","type": "currency","label": "Price"},{"fieldNameOrPath": "OpportunityLineItems.Product2.ProductCode","type": "string","label": "Prod Code"},{"fieldNameOrPath": "OpportunityLineItems.Product2.LastModifiedBy.Name","type": "string","label": "Last Modified"},{"fieldNameOrPath": "OpportunityLineItems.Quantity","type": "decimal","label": "Quantity"},{"fieldNameOrPath": "OpportunityLineItems.TotalPrice","type": "currency","label": "Total"}]';
        lv.Core_ListView_Query__c   = 'SELECT Name, StageName, CloseDate, ExpectedRevenue, Account.Name, Account.Type, Account.Industry, Pricebook2.Name, PriceBook2.IsActive, (SELECT Name, ListPrice, Product2.Name, Product2.ProductCode, Product2.LastModifiedBy.Name, Quantity, TotalPrice FROM OpportunityLineItems) FROM Opportunity WHERE HasOpportunityLineItem = true AND IsWon = false AND IsClosed = false';
        lv.Object_Name__c           = 'Opportunity';
        lv.RecordTypeId             = ListViewHelper.customRTId;
        lv.Subtype__c               = 'Manual';

        listViews.add(lv);

        HelperDatabase.insertRecords(listViews, 'Simpli_lv__List_View__c');
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
/*    public static Boolean isVisible(List_View__c lv)
    {
        if (lv.OwnerId == UserInfo.getUserId()) return true;

        if (lv.All_Internal_Users__c != null && lv.All_Internal_Users__c) return true;

        User usr = UserHelper.getCurrentUser();

        if (lv.Roles__c != null && usr.UserRole != null && lv.Roles__c.contains(usr.UserRole.Name)) return true;

        return false;
    }
*/
    /*
     * Method to check security and determine whether the list view is updateable
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

        if (HelperProfile.isSysAdmin()) return true;

        if (lv.All_Internal_Users__c != null && lv.All_Internal_Users__c) return true;

        return false;
    }

    public class ColumnSortData implements Comparable {

        public String fieldName;
        public Boolean sortDirection;
        public Integer sortIndex;

        public ColumnSortData()
        {

        }

        public ColumnSortData(String fieldName, Boolean sortDirection, Integer sortIndex)
        {
            this.fieldName     = fieldName.toLowerCase();
            this.sortDirection = sortDirection;
            this.sortIndex     = sortIndex;
        }

        /*
         * Method to create the user config string for this sorted column
         * which gets saved as part of the users list view config.
         */
        public String getUserConfigString()
        {
            return sortIndex + ':' + sortDirection + ':' + fieldName;
        }

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