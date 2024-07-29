/**
 * @author            : tom@ansleyllc.com
 * @last modified on  : 07-24-2024
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   08-05-2020   tom@ansleyllc.com   Initial Version
 * 2.0   02-17-2021   tom@ansleyllc.com   Added New action config
 * 3.0   06-18-2021   tom@ansleyllc.com   Added offset to allow for larger datasets
 * 4.0   06-18-2021   tom@ansleyllc.com   Added updateRecord() method to update records based on inline editing, added Edit All action for inline-editing of all list view rows, added org wide config params for identifying if inline-editing is allowed and whether the list views have been initialized.
 * 5.0   08-02-2021   tom@ansleyllc.com   Added List_View_Label__c,
 *                                        Added getObjectForValue() for getting proper object for string value, 
 *                                        Added updateRecords() method to update multiple records based on inline editing, 
 *                                        Moved in static strings for types from ListViewConfigHelper,  
 *                                        Added DisplayTextSearch org wide config
 * 6.0   08-03-2021   tom@ansleyllc.com   Performance enhancement when retrieving listview objects
 * 7.0   08-16-2021   tom@ansleyllc.com   Added permission check for each action before display
 * 8.0   08-18-2021   tom@ansleyllc.com   Updated strings to static final variables, added hyperlink action config
 * 9.0   08-18-2021   tom@ansleyllc.com   Added TYPE_COMBOBOX. Added CampaignMember config
 * 10    12-15-2021   tom@ansleyllc.com   Removed old methods for checking object accessibility.
 * 11    12-15-2021   tom@ansleyllc.com   Pulled out creating types due to different methods for handling types with package names etc.
 * 12    09-24-2022   tom@ansleyllc.com   Added SOQL SLV substitution for current user.
 **/
global with sharing class ListViewHelper 
{
    public static String LATEST_QUERY = '';
    public static final Id coreRTId = Schema.SObjectType.List_View__c.getRecordTypeInfosByDeveloperName().get('Core').getRecordTypeId();
    public static final Id customRTId = Schema.SObjectType.List_View__c.getRecordTypeInfosByDeveloperName().get('Custom').getRecordTypeId();
   
    public static final Set<String> POLYMORPHIC_FIELDS = new Set<String>{ 'WhatId', 'WhoId'};

    public static final String CORE_APEX_CLASS = 'ListViewCore';

    public static final String SUCCESS = 'success';
    public static final String FAILED = 'failed';

    public static final String PROC_TYPE_CREATE = 'create';
    public static final String PROC_TYPE_UPDATE = 'update';
    
    public static final String MODE_APP     = 'App Page';
    public static final String MODE_SINGLE  = 'Single List View';
    public static final String MODE_RELATED = 'Related List View';
    public static final String MODE_SPLIT   = 'Split View';

    public static final String TYPE_ALL    = 'All';
    public static final String TYPE_CORE   = 'Core';
    public static final String TYPE_CUSTOM = 'Custom';
    
    public static final String TYPE_ID            = 'id';
    public static final String TYPE_BOOLEAN       = 'boolean';
    public static final String TYPE_DOUBLE        = 'double';
    public static final String TYPE_STRING        = 'string';
    public static final String TYPE_DECIMAL       = 'decimal';
    public static final String TYPE_CURRENCY      = 'currency';
    public static final String TYPE_DATE          = 'date';
    public static final String TYPE_DATETIME      = 'datetime';
    public static final String TYPE_NUMBER        = 'number';
    public static final String TYPE_BLOB          = 'blob';
    public static final String TYPE_PERCENT       = 'percent';
    public static final String TYPE_TIME          = 'time';
    public static final String TYPE_PICKLIST      = 'picklist';
    public static final String TYPE_MULTI_PICK    = 'multipicklist';
    public static final String TYPE_LOOKUP        = 'lookup';
    public static final String TYPE_TEXTAREA      = 'textarea';
    public static final String TYPE_RICH_TEXTAREA = 'rich textarea';
    public static final String TYPE_URL           = 'url';
    public static final String TYPE_HTML          = 'html';
    public static final String TYPE_IMAGE         = 'image';
    public static final String TYPE_EMAIL         = 'email';
    public static final String TYPE_PHONE         = 'phone';
    public static final String TYPE_INTEGER       = 'integer';
    public static final String TYPE_COMBOBOX      = 'combobox';

    public static final String PARAM_ADD_FIELDS           = 'AdditionalFields';
    public static final String PARAM_TOTAL_COLUMNS        = 'TotalColumns';
    public static final String PARAM_RETURN_SIZE          = 'ReturnSize';
    public static final String PARAM_REFRESH_RATE         = 'RefreshRate';
    public static final String PARAM_SINGLE_CLICK_REFRESH = 'SingleClickAutoDataRefresh';
    public static final String PARAM_TOTAL_COLUMN_COLOR   = 'TotalColumnsColor';
    public static final String PARAM_EXPORT_HEADER_TYPE   = 'ExportHeaderType';
    public static final String PARAM_ALL_ROWS             = 'AllRows';
    public static final String PARAM_PDF_ORIENT_PORTRAIT  = 'PDFOrientationPortrait';
    public static final String PARAM_PDF_THEME            = 'PDFTheme';
    public static final String PARAM_SPLIT_COLUMNS        = 'SplitColumns';

    public static final String SUBTYPE_MANUAL = 'Manual';
    public static final String SUBTYPE_TOOLING = 'Tooling';
    public static final String SUBTYPE_METADATA = 'Metadata';

    public static final String ID_TYPE_CORE = 'Core';
    public static final String ID_TYPE_SLV  = 'SLV';

    public static final String QUERY_TYPE_SOQL = 'soql';
    public static final String QUERY_TYPE_SOSL = 'sosl';

    public static final String TTRUE = 'true';
    public static final String FFALSE = 'false';

    private static Boolean simpliLVsGetRetry = false;             //used to identify whether we are trying to perform a list view get retry with the "simpli_lv__" attached.

    public static Integer offset           = -1;                  //used to hold the offset that is set when performing a query.

    public static String getPrimaryKey(List_View__c listView)
    {
        return listView.Object_Name__c.replace(' ', '_') + ':' + listView.API_Name__c;
    }

    public static String getPrimaryKey(String objectName, String listViewName)
    {
        return objectName.replace(' ', '_') + ':' + listViewName;
    }

    public static Boolean hasEnterprise()
    {
        if (HelperSchema.isPackageInstalled(HelperSchema.SLVE_NAMESPACE)) 
            return true;
        else if (HelperSchema.isObject('simpli_lv_ent__List_Views_Org_Connection__c')) //a hack for the enterprise org as its not installed
            return true;
        else
            return false;
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
    * @description Method to update/create MANY records given their record Ids (for updates) and a map of field updates
    * @author tom@ansleyllc.com | 07-29-2021 
    * @param rowValues map of field values with the record Id as key to return map of field values and the API field name being the key of the field values.
    * @param objType this is NOT required. If rows are passed in with Ids then those can be used to identify the type.
    * @return Map<Id, SObject> objects updated/created with the record Id as key
    **/
    public static Map<String, SObject> updateRecords(String processType, String objType, Map<String, Map<String, String>> rowValues)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting updateRecords(' + processType + ', ' + objType + ', ' + rowValues + ')');
        Map<String, SObject> updatedObjs = new Map<String, SObject>(); //use map to ensure no duplicates

        if (rowValues.size() == 0) return updatedObjs;

        //use the provided object type
        String objectType = objType;

        //if the provided type is NULL then we are upserting 
        if (String.isEmpty(objectType))
            objectType = HelperSchema.getSObjectTypeFromId(new List<String>(rowValues.keySet())[0]); //get the first record Id to determine object type. ALL types must be the same!!

        
        //instantiate object
        Type t = HelperSchema.getClassType(objectType);

        for (String rowId: rowValues.keySet())
        {
            SObject rec = (SObject) t.newInstance();

            System.debug(LoggingLevel.DEBUG, 'Test 2 - ' + rowId);

            //add record Id to object
            if (processType == PROC_TYPE_UPDATE)
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
                    fieldValue = HelperSchema.getValueForField(objectType, fieldName, fieldValues.get(fieldName));
                    rec.put(fieldName, fieldValue);
                }

            }

            updatedObjs.put(rowId, rec);
            System.debug(LoggingLevel.FINE, 'Saving record - ' + rec);
        }

        HelperDatabase.upsertRecords(updatedObjs.values());

        return updatedObjs;
    }

    /**
    * @description Method to UPDATE a SINGLE record given its record Id and a map of field updates
    * @author tom@ansleyllc.com | 07-22-2021 
    * @param rowId the record Id of the record to be updated
    * @param fieldValues map of field values with the field name being the key
    * @return String blank string = success. Anything else is failure.
    **/
    public static SObject updateRecord(String rowId, Map<String, String> fieldValues)
    {
        Map<String, Map<String, String>> fieldsByRowId = new Map<String, Map<String, String>>();

        fieldsByRowId.put(rowId, fieldValues);

        return updateRecords(PROC_TYPE_UPDATE, null, fieldsByRowId).values()[0];
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

        System.debug(LoggingLevel.FINE, 'JSON - ' + jsonStr);

        ListViewConfigHelper.setOrgWideConfigParam('ListViewObjects', jsonStr);

    }

    public static Map<Id, ListView> getChangedListViews(Integer lapsedMinutes)
    {
        return getChangedListViews(null, UserInfo.getUserId(), lapsedMinutes);
    }

    /*
     * Method to return all CORE list views that have been altered by the running user
     * within the past 2 weeks.
     */
    public static Map<Id, ListView> getLastChangedListViewForUser(Id userId)
    {
        return getChangedListViews(1, userId, null);
    }

    /**
    * @description Method to get core list views based on provided criteria.
    * @author tom@ansleyllc.com | 01-28-2022 
    * @param type the following types are currently implemented - ByObject, ById, ModifiedBy
    * @param values the criteria values based on the type.
    * @return List<ListView> all list views which match the provided criteria with the org excluded list views removed as well.

        ListViewHelper.getChangedListViews(10);
        ListViewHelper.getLastChangedListViewForUser(UserInfo.getUserId());
        
    **/
    private static List<ListView> getCoreListViews(String type, Map<String, Object> values)
    {
        Integer soqlLimit = 5000;

        Set<Id> ids = null;
        String soql = 'SELECT Id, ' +
                             'Name, ' +
                             'SObjectType, ' +
                             'DeveloperName, ' +
                             'NamespacePrefix, ' +
                             'CreatedById ' +
                        'FROM ListView ';

        //Handle all values passed in
        if (type == 'ByObject')
        {
            soql += 'WHERE SObjectType = \'' + (String) values.get('ObjectName') + '\' ';

        } else if (type == 'ByName') 
        {
            soql += 'WHERE SObjectType = \'' + (String) values.get('ObjectName') + '\' ';
            soql += ' AND DeveloperName = \'' + (String) values.get('ListViewName') + '\' ';
            
        } else if (type == 'ById')
        {
            ids = (Set<Id>) values.get('Ids');
            soql += 'WHERE Id IN :ids ';

        } else if (type == 'ModifiedBy')
        {
            System.debug(LoggingLevel.DEBUG, 'VALUES - ' + values);
            soql += 'WHERE LastModifiedById = \'' + (Id) values.get('modifiedBy') + '\' ';
            
            if (values.get('minutesBack') != null)
            {
                Integer minBack = -((Integer) values.get('minutesBack'));
                DateTime dt = System.now().addMinutes(minBack);
                soql += 'AND LastModifiedDate > ' + HelperDate.getSOQLDateTime(dt) + ' ';
            }

            if (values.get('limit') != null)
                soqlLimit = (Integer) values.get('limit');    
        } else {
            throw new ListViewException('A valid type(ByName, ByObject, ById, ModifiedBy) must be provided - ' + type);
        }

        //always exclude list views to be excluded by admin param
        List<String> excStrings = ListViewConfigHelper.getOrgWideConfigParam('ExcludedListViews').split('\\|');

        if (excStrings.size() == 1 && excStrings[0] != '') {

            soql += ' AND (NOT DeveloperName LIKE \'%' + excStrings[0] + '%\') ';
        
        } else if (excStrings.size() > 1)  {
            soql += ' AND (';
            for (String excString: excStrings)
                soql += '(NOT DeveloperName LIKE \'%' + excString + '%\') OR ';
            soql = soql.removeEnd(' OR ') + ') ';
        }

        soql += 'ORDER BY LastModifiedDate DESC ';

        soql += 'LIMIT ' + soqlLimit;

        System.debug(LoggingLevel.DEBUG, 'Final getCoreListViews SOQL - ' + soql);

        List<ListView> listViews = Database.query(soql);

        //get the CORE list views.
        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, listViews);
        
        return (List<ListView>) dec.getRecords();
    }

    @TestVisible
    private static Map<Id, ListView> getChangedListViews(Integer recLimit, Id modifiedById, Integer minutesBack)
    {
        System.debug(LoggingLevel.DEBUG, 'MIN BACK - ' + minutesBack);

        Map<String, Object> values = new Map<String, Object>();
        values.put('limit', recLimit);
        values.put('modifiedBy', modifiedById);
        values.put('minutesBack', minutesBack);

        Map<Id, ListView> listViewsById = new Map<Id, ListView>(getCoreListViews('ModifiedBy', values));

        return listViewsById;

    }

    @TestVisible
    private static List<ListView> getCoreListViews(String objectName)
    {
        Map<String, Object> values = new Map<String, Object>();
        values.put('ObjectName', objectName);
        
        return getCoreListViews('ByObject', values);
    }

    public static List<ListView> getCoreListViews(Set<Id> lvIds)
    {
        Map<String, Object> values = new Map<String, Object>();
        values.put('Ids', lvIds);
        
        return getCoreListViews('ById', values);
    }

    public static List<ListView> getCoreListViews(String objectName, String listViewName)
    {
        Map<String, Object> values = new Map<String, Object>();
        values.put('ObjectName', objectName);
        values.put('ListViewName', listViewName);
        return ListViewHelper.getCoreListViews('ByName', values);
    }

    /*
     * Method to update list view describe details including the SOQL statement.
     * The object type of the list views to be updated is provided. This method should not be used 
     * for more than 50 list views. If more need to be updated then use the batch job.
     * HANDLES CORE ONLY
     */
    public static Boolean updateListViewsFromObj(String objectName)
    {
        //get CORE list views
        List<ListView> coreListViews = getCoreListViews(objectName);

        if (coreListViews.size() > 50)
            return false;

        //get SLV list views
        Map<String, List_View__c> slvListViews = getListViewsByObjectCache(objectName, true);

        //Remove valid core list views
        for (ListView coreListView: coreListViews)
            slvListViews.remove(coreListView.DeveloperName);

        Boolean result = updateListViews(coreListViews);

        //can only clean AFTER updating the list views.
        ListViewHelper.cleanListViews(slvListViews.values());

        CacheHelper.clearAllCache();
        return result;
    }

    /*
     * Method to update list view describe details including the SOQL statement.
     * The set passed in is the CORE list view Ids. This method should not be used 
     * for more than 50 list views. If more need to be updated then use the batch job.
     * HANDLES CORE ONLY
     */
    public static Boolean updateListViewsFromCoreIds(Set<Id> coreIds)
    {
        List<ListView> coreListViews = getCoreListViews(coreIds);

        if (coreIds.size() > 50)
            return false;
            
        return updateListViews(coreListViews);
    }

    /*
     * Method to update list view describe details including the SOQL statement.
     * The set passed in is the CUSTOM list view Ids. This method should not be used 
     * for more than 50 list views. If more need to be updated then use the batch job.
     * HANDLES CORE ONLY
     */
    public static Boolean updateListViewsFromSLVIds(Set<Id> slvIds)
    {
        if (slvIds.size() > 50)
            return false;
            
        Set<Id> coreLVIds = new Set<Id>();

        //get the CUSTOM list views.
        List<List_View__c> listViews = getListViewsById(slvIds, true).values();
        Map<Id, List_View__c> listViewsByCoreId = new Map<Id, List_View__c>();

        //get the CORE list view Ids from the CUSTOM list views.
        //but only get those that the user is allowed to update
        for (List_View__c listView: listViews)
        {
            if (isUpdateable(listView))
                coreLVIds.add(listView.Core_ListView_Id__c);
        }

        List<ListView> coreListViews = getCoreListViews(coreLVIds);

        return updateListViews(coreListViews);
    }

    public static Boolean updateListViewsFromCore(List<ListView> listviews)
    {
        if (listviews.size() > 50)
            return false;

        return updateListViews(listviews);
    }

    /*
     * Method to update CUSTOM list views based on the CORE list views provided.
     * 
      ListViewHelper.updateListViews(ListViewHelper.ID_TYPE_SLV, new Set<Id>{'a003h00000BWOUhAAP'});
     * 
     * HANDLES CORE ONLY
     */
    private static Boolean updateListViews(List<ListView> listviews)
    {
        System.debug(LoggingLEvel.DEBUG, 'Starting updateListViews(' + listviews + ')');
        Map<String, List_View__c> updatedListViews = new Map<String, List_View__c>();
        Map<String, List_View_Config__c> simpliListViewConfigs = new Map<String, List_View_Config__c>(); 
        Set<String> objectNames = new Set<String>(); //used to remove all list views that have been updated in the cache

        for (ListView listView: listviews)
        {

            if (String.isEmpty(listView.SObjectType) || String.isEmpty(listView.Id)) continue;

            //create URL to find the list view query
            String endPoint = URL.getOrgDomainUrl().toExternalForm() + '/services/data/v52.0/sobjects/' + listView.SObjectType + '/listviews/' + listView.Id + '/describe';
            
            //get list view describe
            String callResponse = HelperREST.performInternalCallout(endPoint, null);

            //turn JSON string into map
            try {
                Object response = JSON.deserializeUntyped(callResponse);
                if (response instanceof List<Object>) 
                {
                    ListViewErrorHelper.addLog('ListViewHelper(updateListViews)', String.valueOf(response));
                    continue; //if we get a list we cannot process it.
                }
                Map<String,Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(callResponse);

                List_View__c simpliListView = new List_View__c();
                String apiName = listView.DeveloperName;
                System.debug(LoggingLevel.DEBUG, 'PREFIX - ' + listView.NamespacePrefix);
                if (!String.isEmpty(listView.NamespacePrefix))
                    apiName = listView.NamespacePrefix + '__' + apiName;
                System.debug(LoggingLevel.DEBUG, 'API NAME - ' + apiName);
                    
                simpliListView.Custom_Apex_Class__c     = ListViewHelper.CORE_APEX_CLASS;
                simpliListView.API_Name__c              = apiName;
                simpliListView.Object_Name__c           = listview.SObjectType;
                simpliListView.Describe__c              = callResponse;
                simpliListView.Label__c                 = listView.Name;
                simpliListView.Core_ListView_Id__c      = listView.Id;
                simpliListView.Primary_Key__c           = listview.SObjectType + ':' + apiName;
                simpliListView.Core_ListView_Query__c   = (String) jsonResponse.get('query');
                simpliListView.Core_ListView_Columns__c = JSON.serialize(jsonResponse.get('columns'));
                simpliListView.RecordTypeId             = ListViewHelper.coreRTId;

                objectNames.add(simpliListView.Object_Name__c);

                User usr = UserHelper.getUserDetails(listView.CreatedById);
                if (usr == null || !usr.IsActive || (usr.FirstName == 'Automated' && usr.LastName == 'Process'))
                    simpliListView.OwnerId              = UserInfo.getUserId();
                else
                    simpliListView.OwnerId              = listView.CreatedById;

                //0:true:BillingState;1:true:Type
                //set the default sort order
                if (jsonResponse.get('orderBy') != null)
                {
                    String orderStr = '';
                    List<Object> orderItems = (List<Object>) jsonResponse.get('orderBy');
                    for (Integer index = 0; index < orderItems.size(); index++)
                    {
                        Map<String, Object> orderItemObj = (Map<String, Object>) orderItems.get(index);
                        String direction = ListViewHelper.TTRUE;
                        if (orderItemObj.get('sortDirection') == 'descending')
                            direction = ListViewHelper.FFALSE;

                        orderStr += index + ':' + direction + ':' + orderItemObj.get('fieldNameOrPath') + ';';
                        System.debug(LoggingLevel.DEBUG, 'ORDER - ' + orderStr);
                    }
                    orderStr = orderStr.removeEnd(';');
                    simpliListView.Default_Sort_Order__c = orderStr;
                }

                updatedListViews.put(simpliListView.Primary_Key__c, simpliListView);

                System.debug(LoggingLevel.FINE, 'Updated Simpli List View - ' + simpliListView);

                //use the metadata API to try and enrich the listview data.
                enrichListViewFromMetadata(simpliListView);

                List_View_Config__c config = new List_View_Config__c();
                config.Name                = simpliListView.API_Name__c;
                config.List_View_Label__c  = simpliListView.Label__c;
                config.List_View_Object__c = simpliListView.Object_Name__c;
                config.Primary_Key__c      = ListViewConfigHelper.getPrimaryKey(config.List_View_Object__c, config.Name);

                simpliListViewConfigs.put(config.Primary_Key__c, config);

            } catch (Exception e) {
                String message = 'Exception during ListViewHelper.updateListViews()\n';
                message += listView + '\n';
                message += ListViewException.getExtendedString(e);
                ListViewErrorHelper.addException('ListViewHelper(updateListViews)', message);
            }

        }

        HelperDatabase.upsertRecords(updatedListViews.values(), 'simpli_lv__Primary_Key__c', true);
        HelperDatabase.upsertRecords(simpliListViewConfigs.values(), 'simpli_lv__Primary_Key__c', true);           

        return true;
    }

    private static List_View__c enrichListViewFromMetadata(List_View__c coreListView)
    {
        ListViewMetadataAPIService.MetadataPort service = ListViewMetadataAPIService.createService();

        ListViewMetadataAPIService.ListView listView = null;
        // Read List View information
        if (Test.isRunningTest())
        {
            listView = new ListViewMetadataAPIService.ListView();
            listView.columns = new List<String>();
            listView.columns.add('NAME');
            listView.label = 'Test Label';
            listView.sharedTo = new ListViewMetadataAPIService.SharedTo();
            

        } else {
            listView = (ListViewMetadataAPIService.ListView) service.readMetadata('ListView', new String[] { coreListView.Object_Name__c + '.' + coreListView.API_Name__c }).getRecords()[0];
        }

        System.debug(LoggingLevel.DEBUG, 'Listview Metadata - ' + listView);

        ListViewMetadataAPIService.SharedTo sharedTo = null;
        //we might have no listview returned.
        if (listView.label != null)
        {
            
            System.debug(LoggingLevel.DEBUG, 'List View - ' + listView);
            
            System.debug(LoggingLevel.DEBUG, 'ListView.booleanFilter - ' + listView.booleanFilter);
            System.debug(LoggingLevel.DEBUG, 'ListView.columns - ' + listView.columns);
            System.debug(LoggingLevel.DEBUG, 'ListView.division - ' + listView.division);
            System.debug(LoggingLevel.DEBUG, 'ListView.filters - ' + listView.filters);
            System.debug(LoggingLevel.DEBUG, 'ListView.filterScope - ' + listView.filterScope);
            System.debug(LoggingLevel.DEBUG, 'ListView.fullName - ' + listView.fullName);
            System.debug(LoggingLevel.DEBUG, 'ListView.label - ' + listView.label);
            System.debug(LoggingLevel.DEBUG, 'ListView.language - ' + listView.language);
            System.debug(LoggingLevel.DEBUG, 'ListView.queue - ' + listView.queue);
            System.debug(LoggingLevel.DEBUG, 'ListView.sharedTo - ' + listView.sharedTo);
            System.debug(LoggingLevel.DEBUG, 'ListView.type - ' + listView.type);
            System.debug(LoggingLevel.DEBUG, 'ListView.columns - ' + listView.columns);
            System.debug(LoggingLevel.DEBUG, 'ListView.filters - ' + listView.filters);

            coreListView.Is_Private__c = false;
            coreListView.Is_Non_Editable__c = false;

            if(listView.sharedTo != null)
            {
                sharedTo = listView.sharedTo;

                System.debug(LoggingLevel.DEBUG, 'SharedTo.allCustomerPortalUsers - ' + sharedTo.allCustomerPortalUsers);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.allInternalUsers - ' + sharedTo.allInternalUsers);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.allPartnerUsers - ' + sharedTo.allPartnerUsers);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.group_x - ' + sharedTo.group_x);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.role - ' + sharedTo.role);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.roleAndSubordinates - ' + sharedTo.roleAndSubordinates);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.roleAndSubordinatesInternal - ' + sharedTo.roleAndSubordinatesInternal);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.territory - ' + sharedTo.territory);
                System.debug(LoggingLevel.DEBUG, 'SharedTo.territoryAndSubordinates - ' + sharedTo.territoryAndSubordinates);
            }

            coreListview.Boolean_Filter__c = listView.booleanFilter;
            coreListview.Filter_Scope__c = listView.filterScope;

            if(sharedTo != null)
            {
                if (sharedTo.allInternalUsers != null)
                    coreListview.All_Internal_Users__c = true;
                else 
                    coreListview.All_Internal_Users__c = false;

                if (sharedTo.group_x != null)
                    coreListview.Groups__c = String.join(sharedTo.group_x, ',');
                else
                    coreListview.Groups__c = null;

                if (sharedTo.role != null)
                    coreListview.Roles__c = String.join(sharedTo.role, ',');
                else
                    coreListview.Roles__c = null;

                if (sharedTo.roleAndSubordinates != null)
                    coreListview.Roles_And_Subordinates__c = String.join(sharedTo.roleAndSubordinates, ',');
                else
                    coreListview.Roles_And_Subordinates__c = null;

                if (sharedTo.territory != null)
                    coreListview.Territories__c = String.join(sharedTo.territory, ',');
                else
                    coreListview.Territories__c = null;
                
                if (sharedTo.territoryAndSubordinates != null)
                    coreListview.Territories_And_Subordinates__c = String.join(sharedTo.territoryAndSubordinates, ',');
                else
                    coreListview.Territories_And_Subordinates__c = null;
        
            } else {
                coreListview.All_Internal_Users__c = false;
                coreListview.Groups__c = null;
                coreListview.Roles__c = null;
                coreListview.Roles_And_Subordinates__c = null;
                coreListview.Territories__c = null;
                coreListview.Territories_And_Subordinates__c = null;
            }

        //this is a bit of a hack to allow RECENTLY VIEWED list view to not be private.
        } else if (coreListView.Core_ListView_Query__c.contains('USING SCOPE mru') && coreListView.API_Name__c.contains('RecentlyViewed')) {
            
            coreListView.Is_Private__c = false;
            coreListView.Is_Non_Editable__c = true;
            coreListview.All_Internal_Users__c = false;
            coreListview.Groups__c = null;
            coreListview.Roles__c = null;
            coreListview.Roles_And_Subordinates__c = null;
            coreListview.Territories__c = null;
            coreListview.Territories_And_Subordinates__c = null;

        } else {
           
            coreListView.Is_Private__c = true;
            coreListView.Is_Non_Editable__c = false;
            coreListview.All_Internal_Users__c = false;
            coreListview.Groups__c = null;
            coreListview.Roles__c = null;
            coreListview.Roles_And_Subordinates__c = null;
            coreListview.Territories__c = null;
            coreListview.Territories_And_Subordinates__c = null;
        }

        return coreListView;
        
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
        return getListViewObjects(pageWideIncObjs, pageWideExcObjs, true);
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
        System.debug(LoggingLevel.FINE, 'ListViewHelper.getListViewObjects(' + pageWideIncObjs + ', ' + pageWideExcObjs + ', ' + isInit + ')');
        String debug = '';
        Map<String, String> mappedListviewObjects = new Map<String, String>();
        Map<String, String> listViewObjects =  null;

        listViewObjects =  new Map<String, String>();

        String exclObjs = ListViewConfigHelper.getOrgWideConfigParam('ExcludedObjectTypes');
        debug += 'Org Wide Excluded Object Types - ' + exclObjs + '\n';
        Set<String> orgWideExcObjs = HelperString.getSetFromString(exclObjs, ',');
        debug += 'orgWideExcObjs size - ' + orgWideExcObjs.size() + '\n';

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
                                                    LIMIT 5000]; //limit for security review. No other reason

            //get object labels from cache
            String jsonLabels = (String) CacheObjectLabels.get(CacheObjectLabels.ALL_OBJECTS);
            Map<String, String> cacheLabels = (Map<String, String>) JSON.deserialize(jsonLabels, Map<String, String>.class);


            for (AggregateResult result: aggListViewObjects)
            {
                String objAPIName = (String) result.get('simpli_lv__Object_Name__c');

                System.debug(LoggingLevel.FINE, 'objAPIName - ' + objAPIName);

                String objLabel = cacheLabels.get(objAPIName);
                if (!String.isEmpty(objLabel))
                    listViewObjects.put(objAPIName, objLabel);
            }

            //------------------------------------
            //TOOLING LIST VIEWS (FRESH)
            //------------------------------------
            List<List_View__c> toolingListViews = [SELECT Object_Name__c, 
                                                          Label__c
                                                    FROM List_View__c 
                                                    WHERE Object_Name__c NOT IN :orgWideExcObjs 
                                                    AND Object_Name__c NOT IN :pageWideExcObjs
                                                    AND SubType__c = :SUBTYPE_TOOLING
                                                    LIMIT 5000]; //limit for security review. No other reason


            for (List_View__c lv: toolingListViews)
                    listViewObjects.put(lv.Object_Name__c, lv.Label__c);

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
            Map<Id, List_View__c> listViews = getListViewsByType(TYPE_CUSTOM, false);

            for (List_View__c listView: listViews.values())
            {

                System.debug(LoggingLevel.DEBUG, 'Working CUSTOM List View - ' + listView.Label__c);

                //only admin can view tooling API list views
                if (listView.SubType__c != SUBTYPE_TOOLING || HelperProfile.hasModifyAll())
                {
                    System.debug(LoggingLevel.DEBUG, 'Working CUSTOM List View MORE - ' + listView.Object_Name__c);
                    Schema.DescribeSObjectResult objDesc = HelperSchema.getObjectSchema(listView.Object_Name__c);
                    if (objDesc != null && !orgWideExcObjs.contains(objDesc.getName()) && !pageWideExcObjs.contains(objDesc.getName()))
                    {
                        String objLabel = objDesc.getLabel();
                        listViewObjects.put(listView.Object_Name__c, objLabel);
                        System.debug(LoggingLevel.DEBUG, 'GETTING CUSTOM LV LABEL - ' + objLabel);
                    } else if (!orgWideExcObjs.contains(listView.Object_Name__c) && !pageWideExcObjs.contains(listView.Object_Name__c)) {
                        listViewObjects.put(listView.Object_Name__c, listView.Object_Name__c);
                        System.debug(LoggingLevel.DEBUG, 'USING LV OBJECT AS LABEL - ' + listView.Object_Name__c);
                    }
                }
            }

        }


        String inclObjs = ListViewConfigHelper.getOrgWideConfigParam('IncludedObjectTypes');
        Set<String> orgWideIncObjs = HelperString.getSetFromString(inclObjs, ',');

        debug += 'pageWideIncObjs ' + pageWideIncObjs + '\n';
        debug += 'orgWideIncObjs ' + orgWideIncObjs + '\n';
    
        for (String objAPIName: listViewObjects.keySet())
        {

            System.debug(LoggingLevel.FINE, 'Working ' + objAPIName);
            //if there are PAGE included objects then only include those.
            if (pageWideIncObjs.isEmpty() || pageWideIncObjs.contains(objAPIName))
            {

                //if there are ORG WIDE included objects then only include those.
                if (orgWideIncObjs.isEmpty() || orgWideIncObjs.contains(objAPIName))
                {
                    mappedListviewObjects.put(objAPIName, listViewObjects.get(objAPIName));
                    System.debug(LoggingLevel.FINE, 'Adding mapping - ' + objAPIName);
                }
            }
        }

        debug += '\n\n----------------------- RESULT --------------------------\n';
        for (String objectName: mappedListviewObjects.keySet())
            debug += 'Object ' + objectName + ' - ' + mappedListviewObjects.get(objectName) + '\n';
        debug += '---------------------------------------------------------\n\n';

        System.debug(LoggingLevel.FINE, debug);
        ListViewErrorHelper.addLog('ListViewHelper(getListViewObjects)', debug);
        return mappedListviewObjects;
    }

    public static Map<Id, List_View__c> getListViewsByType(String type)
    {
        return getListViewsByType(type, true);
    }

    public static Map<Id, List_View__c> getListViewsByType(String type, Boolean checkVisibility)
    {
        if (checkVisibility)
        {
            return (Map<Id, List_View__c>) CacheListViews.get(CacheListViews.LOAD_TYPE_TYPE +
                                                                CacheHelper.SPLITTER +
                                                                UserInfo.getUserId().removeStart('005') +
                                                                CacheHelper.SPLITTER +
                                                                type);
        } else {
            return getListViewsByTypeCache(type, false);
        }
    }

    public static Map<Id, List_View__c> getListViewsByTypeCache(String type, Boolean checkVisibility)
    {
        System.debug(LoggingLevel.FINE, 'Called getListViewsByTypeCache(type ' + type);

        Set<Id> rtIds = new Set<Id>();
        if (type == TYPE_ALL || type == TYPE_CUSTOM)
            rtIds.add(ListViewHelper.customRTId);
        if (type == TYPE_ALL || type == TYPE_CORE)
            rtIds.add(ListViewHelper.coreRTId);

        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Label__c,
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
                        Subtype__c,
                        Is_Private__c,
                        Is_Non_Editable__c,
                        Default_Sort_Order__c
                FROM List_View__c
                WHERE RecordTypeId IN :rtIds
                ORDER BY Object_Name__c, Label__c]);

        Map<Id, List_View__c> listviews = new Map<Id, List_View__c>( (List<List_View__c>) dec.getRecords());

        Map<Id, List_View__c> listviewsById = listviews;
        
        if (checkVisibility)
            listviewsById = getVisibleListViews(listviews, 'getListViewsByType(' + type + ')');
        
        return listviewsById;
    }

    /*
     * Method to get list views by Id
     */
    public static Map<Id, List_View__c> getListViewsById(Set<Id> lvIds, Boolean onlyCore)
    {
        System.debug(LoggingLevel.FINE, 'Called getListViewsById(lvIds ' + lvIds + ', onlyCore ' + onlyCore);

        Set<Id> rtIds = new Set<Id>();
        rtIds.add(ListViewHelper.coreRTId);
        if (!onlyCore)
            rtIds.add(ListViewHelper.customRTId);

        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Label__c,
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
                        Subtype__c,
                        Is_Private__c,
                        Is_Non_Editable__c,
                        Default_Sort_Order__c
                FROM List_View__c
                WHERE Id IN :lvIds
                    AND RecordTypeId IN :rtIds]);

        Map<Id, List_View__c> listviews = new Map<Id, List_View__c>( (List<List_View__c>) dec.getRecords());

        Map<Id, List_View__c> listviewsById = getVisibleListViews(listviews, 'getListViewsById(' + lvIds + ', ' + onlyCore + ')');
        return listviewsById;
    }

    public static Map<String, List_View__c> getListViewsByObject(String objAPIName)
    {
        return (Map<String, List_View__c>) CacheListViews.get(CacheListViews.LOAD_TYPE_OBJ +
                                                                CacheHelper.SPLITTER +
                                                                UserInfo.getUserId().removeStart('005') +
                                                                CacheHelper.SPLITTER +
                                                                objAPIName);

    }

    public static Map<String, List_View__c> getListViewsByObjectCache(String objAPIName, Boolean onlyCore)
    {

        System.debug(LoggingLevel.FINE, 'objAPIName - ' + objAPIName + ', onlyCore - ' + onlyCore);

        Set<Id> rtIds = new Set<Id>();
        rtIds.add(ListViewHelper.coreRTId);
        if (!onlyCore)
            rtIds.add(ListViewHelper.customRTId);

        //get list view data
        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Label__c,
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
                        Subtype__c,
                        Is_Private__c,
                        Is_Non_Editable__c,
                        Default_Sort_Order__c
                FROM List_View__c
                WHERE Object_Name__c = :objAPIName
                    AND RecordTypeId IN :rtIds
                ORDER BY Label__c]);

        Map<Id, List_View__c> listviews = new Map<Id, List_View__c>( (List<List_View__c>) dec.getRecords());

        //now check security
        Map<Id, List_View__c> listviewsById = getVisibleListViews(listviews, 'getListViewsByObject(' + objAPIName + ')');

        Map<String, List_View__c> listviewsByName = new Map<String, List_View__c>();

        for (List_View__c listview: listviewsById.values())
            listViewsByName.put(listview.API_Name__c, listview);

        return listviewsByName;
    }

    /*
     * Method to get a specific list view given its object and list view API names
     * This method cannot be cached because the list view API names can be longer than 50 chars
     */
    public static Map<Id, List_View__c> getListViews(String objAPIName, String listViewAPIName)
    {
        System.debug(LoggingLevel.FINE, 'objAPIName - ' + objAPIName);
        System.debug(LoggingLevel.FINE, 'listViewAPIName - ' + listViewAPIName);

        //get list view data
        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Label__c,
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
                        Subtype__c,
                        Is_Private__c,
                        Is_Non_Editable__c,
                        Default_Sort_Order__c
                FROM List_View__c
                WHERE Object_Name__c = :objAPIName
                    AND API_Name__c = :listViewAPIName]);

        Map<Id, List_View__c> listviews = new Map<Id, List_View__c>( (List<List_View__c>) dec.getRecords());

        if (listviews.isEmpty() && !simpliLVsGetRetry)
        {
            simpliLVsGetRetry = true;
            listviews = getListViews(objAPIName, 'simpli_lv__' + listViewAPIName);
            simpliLVsGetRetry = false;
        }

        Map<Id, List_View__c> listviewsById = getVisibleListViews(listviews, 'getListViews(' + objAPIName + ', ' + listViewAPIName + ')');

        return listviewsById;
    }

    //===============================================================================
    // CORE LIST VIEWS
    //===============================================================================


    public static List<SObject> getCoreListViewData(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds)
    {
        return getCoreListViewData(listview, lvConfig, sortData, joinFieldName, joinRecordIds, false, -1, '');
    }

    public static List<SObject> getCoreListViewData(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Integer offset)
    {
        return getCoreListViewData(listview, lvConfig, sortData, joinFieldName, joinRecordIds, false, offset, '');
    }

    public static List<SObject> getCoreListViewData(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Boolean example, Integer offset, String soslTextSearchStr)
    {
        if (String.isEmpty(soslTextSearchStr))
            return getCoreListViewData(listview, lvConfig, sortData, joinFieldName, joinRecordIds, example, offset);
        else
            return getSOSLListViewData(soslTextSearchStr, listview, lvConfig, sortData, joinFieldName, joinRecordIds, offset);
    }

    public static List<SObject> getCoreListViewData(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Boolean example, Integer offset)
    {

        //get rows of data from query
        List<SObject> objectRows = null;
        String query;
        try {

            query = getCoreListViewQuery(listview, lvConfig, sortData, joinFieldName, joinRecordIds, example, offset);
            ListViewErrorHelper.addLog('ListViewHelper(getListViewData)', query);

            objectRows = Database.query(query);

            //put the query string into a static variable for use across the app (for debugging purposes)
            LATEST_QUERY = query;

        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during ListViewHelper.getCoreListViewData(' + query + ')  ' + ListViewException.getExtendedString(e));
            throw new ListViewException('There was an error during data retrieval. Please try again or notify an administrator. (' + e.getMessage() + ')');
        }
        
        return objectRows;

    }

    public static String getCoreListViewQuery(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Boolean example, Integer offset)
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
        System.debug(LoggingLevel.FINE, debug);

        Map<String, String> lvConfigParams = new Map<String, String>();
        if (lvConfig != null) //there might not be config yet for this list view
        {
            for (List_View_Config_Parameter__c param: lvConfig.listViewConfig.List_View_Config_Parameters__r)
                lvConfigParams.put(param.Parameter_Name__c, param.Parameter_Value__c);
        }
        
        //---------------------------------------------------
        // Parse out the query retrieved from the list view.
        //---------------------------------------------------
        
        //first replace everything NOT within single quotes with upper case.
        //this needs to be done as we want to use upper case to handle all the 
        //SOQL stuff but everything between quotes is literal and must remain as it is.
        String query = HelperString.toUpperCaseExceptLiterals(listview.Core_ListView_Query__c);
        debug += 'Query after upper casing - ' + query + '\n';

        //String query = listview.Core_ListView_Query__c.toUpperCase();
        String selectStr = query.substringBetween('SELECT ', ' FROM ');
        String objectName = query.substringAfterLast(' FROM ');
        if (objectName.contains(' '))
            objectName = objectName.substringBefore(' ');
        System.debug(LoggingLevel.FINE, 'objectName - ' + objectName);

        String whereStr = null;
        String orderByStr = '';
        if (query.containsIgnoreCase(' ORDER BY '))
        {
            whereStr = query.substringBetween(' FROM ', ' ORDER BY ');
        } else {
            whereStr = query.substringAfter(' FROM ');
        }
        whereStr = whereStr.removeStart(objectName);
        System.debug(LoggingLevel.FINE, 'whereStr - ' + whereStr);

        //------------------------------------------------------
        // Update all additional fields on the SELECT statement
        //------------------------------------------------------
        Set<String> selectFields = new Set<String>(selectStr.split(',')); //use set to remove duplicates

        //Additional Fields
        if (lvConfigParams.get(PARAM_ADD_FIELDS) != null)
            selectFields.addAll(lvConfigParams.get(PARAM_ADD_FIELDS).split(','));

        //IsDeleted
        if (HelperSchema.isValidSFDCFieldName(listview.Object_Name__c, 'IsDeleted') && !selectFields.contains(' ISDELETED'))
            selectFields.add('ISDELETED');

        if (HelperSchema.isValidSFDCFieldName(listview.Object_Name__c, 'RecordTypeId') && !selectFields.contains(' RECORDTYPEID'))
            selectFields.add('RECORDTYPEID');

        selectStr = '';
        for (String field: selectFields)
        {
            //field = HelperSchema.scrubFieldNameForSOQL(field); //remove weird stuff like toLabel() etc.
            selectStr += field + ', ';
        }
        selectStr = selectStr.removeEnd(', ');

        //------------------------------------------------------
        // Handle all changes to the WHERE statement
        //------------------------------------------------------
        if (joinFieldName != '' && joinRecordIds?.size() > 0)
        {
            //if we already have a WHERE clause then place brackets around the entire clause so that it doesn't break when adding more logic.
            if (whereStr.containsIgnoreCase(' WHERE '))
            {
                whereStr = whereStr.replace(' WHERE ', ' WHERE (');
                whereStr += ') AND ' + joinFieldName + ' IN :joinRecordIds';
            } else {
                whereStr += ' WHERE ' + joinFieldName + ' IN :joinRecordIds';
            }
        }

        //------------------------------------------------------
        // Handle all changes to the ORDER BY statement
        //------------------------------------------------------
        if (sortData?.size() > 0)
        {
            System.debug(LoggingLevel.FINE, 'Sort data - ' + sortData);
            orderByStr = ' ORDER BY ';
            
            for (ListViewHelper.ColumnSortData columnSortData: sortData)
            {
                //make sure the field name is valid
                if (columnSortData.fieldName.contains('.') || HelperSchema.isValidSFDCFieldName(listview.Object_Name__c, columnSortData.fieldName))
                {
                    orderByStr += columnSortData.fieldName + ' ';
                    if (columnSortData.sortDirection == true)
                        orderByStr += 'ASC NULLS LAST, ';
                    else
                        orderByStr += 'DESC NULLS FIRST, ';
                } else {
                    System.debug(LoggingLevel.FINE, 'Sort column not valid - ' + columnSortData.fieldName);
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
                        System.debug(LoggingLevel.FINE, 'Offset - ' + offset);
                        System.debug(LoggingLevel.FINE, 'returnSize - ' + returnSize);
                        
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

        System.debug(LoggingLevel.FINE, 'LIMIT STR - ' + limitStr);

        //------------------------------------------------------
        // Handle the ALL ROWS statement
        //------------------------------------------------------
        String allRowsStr = '';
        if (offset == -1                                                   //Cannot use ALL ROWS with OFFSET
            && lvConfigParams.get('AllRows') != null                      //if we have AllRows variable
            && lvConfigParams.get('AllRows') == ListViewHelper.TTRUE                     //if AllRows = true
            && lvConfigParams.get('ReturnSize') != null                    //if we have ReturnSize variable
            && (Integer.valueOf(lvConfigParams.get('ReturnSize')) < 750)) //if ReturnSize < 750
        {
            allRowsStr += ' ALL ROWS';
        }

        //------------------------------------------------------
        // Handle the USING SCOPE statement
        //------------------------------------------------------
        String scopeStr = '';
        if (!whereStr.contains('USING SCOPE ')) //where clause might already contain the scope
        {
            if (!String.isEmpty(listview.Filter_Scope__c))
            {
                if (listview.Filter_Scope__c == 'Queue') //for queues the group Id is provided in the query so we just get everything
                    scopeStr += 'USING SCOPE Everything';
                else
                    scopeStr += 'USING SCOPE ' + listview.Filter_Scope__c;
            } else
                scopeStr += 'USING SCOPE Everything';
        }

        //------------------------------------------------------
        // Put the query back together again
        //------------------------------------------------------
        query = 'SELECT ' + selectStr + ' FROM ' + objectName + ' ' + scopeStr + ' ' + whereStr + orderByStr + limitStr + allRowsStr;

        System.debug(LoggingLevel.FINE, 'Final SOQL - ' + query);
        ListViewErrorHelper.addLog('ListViewHelper(getListViewQuery)', debug);

        return query;
    }


    //===============================================================================
    // CUSTOM LIST VIEWS
    //===============================================================================

    public static List<SObject> getCustomListViewData(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds)
    {
        return getCustomListViewData(listview, lvConfig, sortData, joinFieldName, joinRecordIds, false, -1);
    }

    public static List<SObject> getCustomListViewData(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Integer offset)
    {
        return getCustomListViewData(listview, lvConfig, sortData, joinFieldName, joinRecordIds, false, offset);
    }

    public static List<SObject> getCustomListViewData(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Boolean example, Integer offset, String soslTextSearchStr)
    {
        if (String.isEmpty(soslTextSearchStr)) {
            return getCustomListViewData(listview, lvConfig, sortData, joinFieldName, joinRecordIds, example, offset);
        } else
            return getSOSLListViewData(soslTextSearchStr, listview, lvConfig, sortData, joinFieldName, joinRecordIds, offset);
    }

    public static List<SObject> getCustomListViewData(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Boolean example, Integer offset)
    {
        String soql = getCustomListViewQuery(listview.Core_ListView_Query__c, lvConfig, sortData, joinFieldName, joinRecordIds, example, offset);
        
        //get rows of data from query
        List<SObject> objectRows = null;
        try {
            objectRows = Database.query(soql);
        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during ListViewHelper.getCustomListViewData(' + soql + ')  ' + ListViewException.getExtendedString(e));
            throw e;
        }
        
        return objectRows;

    }
    
    /**
    * @description Convenience method which assumes the following - 
                   i.  This is not to retrieve an example.
                   ii. This does not have any paging requirements
    * @author tom@ansleyllc.com | 06-21-2021 
    **/
    public static String getCustomListViewQuery(String soql, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds)
    {
        return getCustomListViewQuery(soql, lvConfig, sortData, joinFieldName, joinRecordIds, false, -1);
    }

    /*
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + ListViewHelper.getCustomListViewQuery('SELECT Name, v2sales__V2_Path_Stage_Name__c, v2sales__V2_Action_Name__c, v2sales__Is_Completed__c, v2sales__Is_Opp_At_Stage__c FROM v2sales__V2_Action_Instance__c WHERE v2sales__Is_Opp_At_Stage__c = true', null, new List<ListViewHelper.ColumnSortData>(), '', new Set<String>(), true, -1));
     */
    public static String getCustomListViewQuery(String soql, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Boolean example, Integer offset)
    {

        String debug = '\n\n------------------------- GET SOQL QUERY -------------------------\n';
        debug += 'soql                            - ' + soql + '\n';
        debug += 'lvConfig                        - ' + lvConfig + '\n';
        debug += 'sortData                        - ' + sortData + '\n';
        debug += 'joinFieldName                   - ' + joinFieldName + '\n';

        if (joinRecordIds != null)
            debug += 'joinRecordIds Size - ' + joinRecordIds.size() + '\n';
        debug += 'joinRecordIds                   - ' + joinRecordIds + '\n\n';

        Map<String, String> lvConfigParams = new Map<String, String>();
        if (lvConfig != null) //there might not be config yet for this list view
        {
            for (List_View_Config_Parameter__c param: lvConfig.listViewConfig.List_View_Config_Parameters__r)
                lvConfigParams.put(param.Parameter_Name__c, param.Parameter_Value__c);
        }
        
        //---------------------------------------------------
        // Parse out the query retrieved from the list view.
        //---------------------------------------------------
        
        //SCRUB SOQL and replace everything NOT within single quotes with upper case.
        //this needs to be done as we want to use upper case to handle all the 
        //SOQL stuff but everything between quotes is literal and must remain as it is.
        soql = HelperString.toUpperCaseExceptLiterals(HelperString.scrubSOQL(soql));
        debug += 'Query after upper casing and scrubbing - ' + soql + '\n';
        
        //OBJECT NAME
        String objectName = soql.replaceAll('\\(.*?\\)', '').substringAfterLast(' FROM '); //get rid of everything inside brackets and then get expression after FROM
        if (objectName.contains(' '))                                                      //if expression contains stuff after object then remove it.
            objectName = objectName.substringBefore(' ');
        debug += 'OBJNAME                         - ' + objectName + '\n';


        //SELECT
        String selectStr = soql.substringBefore(' FROM ' + objectName + ' WHERE');
        if (selectStr == soql) //not sure this is needed.
            selectStr = soql.substringBefore(' FROM ' + objectName);

        if (HelperSchema.isValidSFDCFieldName(objectName, 'RecordTypeId') && !selectStr.contains('RECORDTYPEID'))
            selectStr = selectStr + ', RECORDTYPEID';

        debug += 'SELECT                          - ' + selectStr + '\n';

        //SCOPE
        String scopeStr = 'USING SCOPE ';
        if (!String.isEmpty(lvConfig?.getListView().Filter_Scope__c))
            scopeStr += lvConfig.getListView().Filter_Scope__c;
        else
            scopeStr += 'Everything';
        debug += 'SCOPE                           - ' + scopeStr + '\n';


        //WHERE
        String whereStr = 'WHERE ' + soql.substringAfter(' FROM ' + objectName).substringAfter(' WHERE ');
        if (whereStr == 'WHERE ') 
            whereStr = '';
        if (whereStr.containsIgnoreCase(' ORDER BY '))
            whereStr = whereStr.substringBeforeLast(' ORDER BY ');

        if (joinFieldName != '' && joinRecordIds?.size() > 0)
        {
            //if we already have a WHERE clause then place brackets around the entire clause so that it doesn't break when adding more logic.
            if (whereStr.containsIgnoreCase('WHERE '))
            {
                whereStr = whereStr.replace('WHERE ', ' WHERE (');
                whereStr += ') AND ' + joinFieldName + ' IN :joinRecordIds';
            } else {
                whereStr += ' WHERE ' + joinFieldName + ' IN :joinRecordIds';
            }
        }

        //SLV substitutions
        if (whereStr.contains('$$CURRENT_USER$$'))
            whereStr = whereStr.replace('$$CURRENT_USER$$', '\'' + UserInfo.getUserId() + '\'');

        debug += 'WHERE                           - ' + whereStr + '\n';


        //ORDER BY
        String orderByStr = soql.substringAfterLast(' FROM ').substringAfterLast(' ORDER BY ').substringBeforeLast(' LIMIT ');
        
        if (sortData?.size() > 0)
        {
            System.debug(LoggingLevel.FINE, 'Sort data - ' + sortData);
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
                    System.debug(LoggingLevel.FINE, 'Sort column not valid - ' + columnSortData.fieldName);
                }
            }

            orderByStr = orderByStr.removeEnd(', ').removeEnd('ORDER BY ');
        } else {
            if (orderByStr != '')
                orderByStr = ' ORDER BY ' + orderByStr;
        }
        debug += 'ORDER                           - ' + orderByStr + '\n';

        //LIMIT
        String limitStr = '';
        if (soql.containsIgnoreCase(' LIMIT '))
            limitStr = soql.substring(soql.lastIndexOf('LIMIT'));

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
                        System.debug(LoggingLevel.FINE, 'Offset - ' + offset);
                        System.debug(LoggingLevel.FINE, 'returnSize - ' + returnSize);
                        
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
        debug += 'LIMIT                           - ' + limitStr + '\n';

        //------------------------------------------------------
        // Handle the ALL ROWS statement
        //------------------------------------------------------
        String allRowsStr = '';
        if (offset == -1                                                   //Cannot use ALL ROWS with OFFSET
            && lvConfigParams.get('AllRows') != null                       //if we have AllRows variable
            && lvConfigParams.get('AllRows') == ListViewHelper.TTRUE                     //if AllRows = true
            && lvConfigParams.get('ReturnSize') != null                    //if we have ReturnSize variable
            && (Integer.valueOf(lvConfigParams.get('ReturnSize')) < 750))  //if ReturnSize < 750
        {
            allRowsStr += ' ALL ROWS';
        }
        debug += 'ALLROWS                         - ' + allRowsStr + '\n';

        //------------------------------------------------------
        // Put the query back together again
        //------------------------------------------------------
        soql = selectStr + ' FROM ' + objectName + ' ' + scopeStr + ' ' + whereStr + orderByStr + limitStr + allRowsStr;
        debug += '\nFINAL SOQL LAYOUT               - SELECT + \' FROM \' + OBJNAME + \' \' + SCOPE + \' \' + WHERE + ORDER + LIMIT + ALLROWS\n';
        debug += 'FINAL SOQL                      - ' + soql + '\n';

        System.debug(LoggingLevel.FINE, debug);
        ListViewErrorHelper.addLog('ListViewHelper(getCustomListViewQuery)', debug);

        //put the query string into a static variable for use across the app (for debugging purposes)
        LATEST_QUERY = soql;

        return soql;
    }


    //===============================================================================
    // SOSL
    //===============================================================================

    public static List<SObject> getSOSLListViewData(String textSearchStr, List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Integer offset)
    {
        String sosl = getSOSLQuery(listview, lvConfig, sortData, textSearchStr, offset, joinFieldName, joinRecordIds);
        
        //get rows of data from query
        List<SObject> objectRows = null;
        try {
            objectRows = search.query(sosl)[0];
        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during ListViewHelper.getSOSLListViewData(' + sosl + ')  ' + ListViewException.getExtendedString(e));
            throw new ListViewException('There was an error during data retrieval. Please try again or notify an administrator. (' + e.getMessage() + ')');
        }
        
        return objectRows;

    }

    public static String getSOSLQuery(List_View__c listview, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String soslTextString, Integer offset, String joinFieldName, Set<String> joinRecordIds)
    {
        if (!canPerformSOSLQuery(listview))
            throw new ListViewException('Cannot perform a text search against this custom list view due to subqueries within SELECT statement.');

        String soql = listview.Core_ListView_Query__c;
        String debug = '\n\n------------------------- GET SOSL QUERY -------------------------\n';
        debug += 'soql                            - ' + soql + '\n';
        debug += 'lvConfig                        - ' + lvConfig + '\n';
        debug += 'sortData                        - ' + sortData + '\n';
        debug += 'joinFieldName                   - ' + joinFieldName + '\n';

        if (joinRecordIds != null)
            debug += 'joinRecordIds Size - ' + joinRecordIds.size() + '\n';
        debug += 'joinRecordIds                   - ' + joinRecordIds + '\n\n';

        Map<String, String> lvConfigParams = new Map<String, String>();
        if (lvConfig != null) //there might not be config yet for this list view
        {
            for (List_View_Config_Parameter__c param: lvConfig.listViewConfig.List_View_Config_Parameters__r)
                lvConfigParams.put(param.Parameter_Name__c, param.Parameter_Value__c);
        }
        
        //---------------------------------------------------
        // Parse out the query retrieved from the list view.
        //---------------------------------------------------
        
        //SCRUB SOQL
        soql = HelperString.scrubSOQL(soql);
        
        //OBJECT NAME
        String objectName = soql.replaceAll('\\(.*?\\)', '').substringAfterLast(' FROM '); //get rid of everything inside brackets and then get expression after FROM
        if (objectName.contains(' '))                                                      //if expression contains stuff after object then remove it.
            objectName = objectName.substringBefore(' ');
        debug += 'OBJNAME                         - ' + objectName + '\n';


        //SELECT
        String selectStr = soql.substringBetween('SELECT ', ' FROM ' + objectName + ' WHERE');
        if (selectStr == null)
            selectStr = soql.substringBetween('SELECT ', ' FROM ' + objectName);
        debug += 'SELECT                          - ' + selectStr + '\n';
        System.debug(LoggingLevel.DEBUG, debug);

        Set<String> selectFields = new Set<String>(selectStr.split(',')); //use set to remove duplicates

        //Additional Fields
        if (lvConfigParams.get(PARAM_ADD_FIELDS) != null)
            selectFields.addAll(lvConfigParams.get(PARAM_ADD_FIELDS).split(','));

        //IsDeleted
        if (HelperSchema.isValidSFDCFieldName(listview.Object_Name__c, 'IsDeleted') && !selectFields.contains(' IsDeleted'))
            selectFields.add('IsDeleted');

        if (HelperSchema.isValidSFDCFieldName(listview.Object_Name__c, 'RecordTypeId') && !selectFields.contains(' RecordTypeId'))
            selectFields.add('RecordTypeId');

        selectStr = '';
        for (String field: selectFields)
        {
            field = HelperSchema.scrubFieldNameForSOQL(field); //remove weird stuff like toLabel() etc.
            selectStr += field + ', ';
        }
        selectStr = selectStr.removeEnd(', ');


        //SCOPE
        String scopeStr = 'USING SCOPE ';
        if (!String.isEmpty(lvConfig?.getListView().Filter_Scope__c))
            scopeStr += lvConfig.getListView().Filter_Scope__c;
        else
            scopeStr += 'Everything';
        debug += 'SCOPE                           - ' + scopeStr + '\n';


        //WHERE
        String whereStr = 'WHERE ' + soql.substringAfter(' FROM ' + objectName).substringAfter(' WHERE ');
        if (whereStr == 'WHERE ') 
            whereStr = '';
        if (whereStr.containsIgnoreCase(' ORDER BY '))
            whereStr = whereStr.substringBeforeLast(' ORDER BY ');
        debug += 'WHERE                           - ' + whereStr + '\n';

        if (joinFieldName != '' && joinRecordIds?.size() > 0)
        {
            //if we already have a WHERE clause then place brackets around the entire clause so that it doesn't break when adding more logic.
            if (whereStr.containsIgnoreCase('WHERE '))
            {
                whereStr = whereStr.replace('WHERE ', ' WHERE (');
                whereStr += ') AND ' + joinFieldName + ' IN :joinRecordIds';
            } else {
                whereStr += ' WHERE ' + joinFieldName + ' IN :joinRecordIds';
            }
        }
        debug += 'WHERE                           - ' + whereStr + '\n';

        //ORDER BY
        String orderByStr = soql.substringAfterLast(' FROM ').substringAfterLast(' ORDER BY ').substringBeforeLast(' LIMIT ');
        
        if (sortData?.size() > 0)
        {
            System.debug(LoggingLevel.FINE, 'Sort data - ' + sortData);
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
                    System.debug(LoggingLevel.FINE, 'Sort column not valid - ' + columnSortData.fieldName);
                }
            }

            orderByStr = orderByStr.removeEnd(', ').removeEnd('ORDER BY ');
        } else {
            if (orderByStr != '')
                orderByStr = ' ORDER BY ' + orderByStr;
        }
        debug += 'ORDER                           - ' + orderByStr + '\n';

        //LIMIT
        String limitStr = '';
        if (soql.containsIgnoreCase(' LIMIT '))
            limitStr = soql.substring(soql.lastIndexOf('LIMIT'));

        if (lvConfigParams.get('ReturnSize') != null)
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
                    System.debug(LoggingLevel.FINE, 'Offset - ' + offset);
                    System.debug(LoggingLevel.FINE, 'returnSize - ' + returnSize);
                    
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
        debug += 'LIMIT                           - ' + limitStr + '\n';

        //------------------------------------------------------
        // Put the query back together again
        //------------------------------------------------------
        String sosl = 'FIND {' + soslTextString + '} IN ALL FIELDS RETURNING ' + objectName + ' (' + selectStr + ' ' + whereStr + orderByStr + limitStr + ') ' ;
        debug += '\nFINAL SOSL LAYOUT               - FIND {SOSLTEXTSTRING} IN ALL FIELDS RETURNING OBJNAME (SELECT WHERE ORDERBY LIMIT)\n';
        debug += 'FINAL SOSL                      - ' + sosl + '\n';

        System.debug(LoggingLevel.FINE, debug);
        ListViewErrorHelper.addLog('ListViewHelper(getSOSLQuery)', debug);

        //put the query string into a static variable for use across the app (for debugging purposes)
        LATEST_QUERY = sosl;

        return sosl;
    }

    /**
    * @description Method to determine whether the list view (based on the SOQL string) can perform
    *              a SOSL query. This is determined by checking if there is more than one SELECT statement
    *              in the main SELECT statement. If so then it cannot perform a SOSL query.
    * @author tom.h.ansley@medtronic.com | 12-31-2021 
    * @param listView the list view to check if a SOSL query can be performed on it.
    * @return Boolean true - YES, false - NO
    **/
    public static Boolean canPerformSOSLQuery(List_View__c listView)
    {
        String soql = listView.Core_ListView_Query__c;

        //must get the object name from the SOQL statement!
        String objectName = soql.replaceAll('\\(.*?\\)', '').substringAfterLast(' FROM '); //get rid of everything inside brackets and then get expression after FROM
        if (objectName.contains(' '))                                                      //if expression contains stuff after object then remove it.
            objectName = objectName.substringBefore(' ');

        String selectStr = soql.removeStart('SELECT ').substringBefore(' FROM ' + objectName + ' WHERE');

        if (selectStr.containsIgnoreCase('SELECT '))
            return false;
        else
            return true;
    }

    public static String deleteListViews(Map<String, List_View__c> listViews)
    {
        String response = SUCCESS;
        String debug = '';
        Map<String, List_View_Config__c> deletedLVConfigs = new Map<String, List_View_Config__c>();
        List<List_View_Config_Column_Style__c> deletedLVConfigStyles = new List<List_View_Config_Column_Style__c>();
        List<List_View_Config_Condition__c> deletedLVConfigConds = new List<List_View_Config_Condition__c>();
        List<List_View_Config_Parameter__c> deletedLVConfigParams = new List<List_View_Config_Parameter__c>();
        List<List_View_User_Config__c> deletedUserConfigs = new List<List_View_User_Config__c>();

        try {
            
            if (listViews.size() > 0)
            {
                //get all configs for the list views to be deleted
                deletedLVConfigs = ListViewConfigHelper.getListViewConfigs(listViews.keySet());
                
                for (List_View_Config__c lvConfig: deletedLVConfigs.values())
                {
                    debug += 'Deleting list view config - ' + lvConfig.Primary_Key__c + '\n';
                
                    deletedLVConfigStyles.addAll(lvConfig.List_View_Config_Column_Styles__r);

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


            HelperDatabase.deleteRecords(listViews.values(), 'simpli_lv__List_View__c');
            HelperDatabase.deleteRecords(deletedLVConfigStyles, 'simpli_lv__List_View_Config_Column_Style__c');
            HelperDatabase.deleteRecords(deletedLVConfigConds, 'simpli_lv__List_View_Config_Condition__c');
            HelperDatabase.deleteRecords(deletedLVConfigParams, 'simpli_lv__List_View_Config_Parameter__c');
            HelperDatabase.deleteRecords(deletedLVConfigs.values(), 'simpli_lv__List_View_Config__c');
            HelperDatabase.deleteRecords(deletedUserConfigs, 'simpli_lv__List_View_User_Config__c');

        } catch (Exception e) {
            response = 'Exception during ListViewHelper.deleteListViews()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(response); 
        }
        System.debug(LoggingLevel.DEBUG, debug);

        return response;
    }

    public static void cleanListViews(List<List_View__c> scope) 
    {
        String debug = '';
        
        try {        
            SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, scope);
            List<List_View__c> listViews = (List<List_View__c>) dec.getRecords();
            Map<String, List_View__c> deletedListViews = new Map<String, List_View__c>();

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

            deleteListViews(deletedListViews);

        } catch (Exception e) {
            String message = 'Exception during ListViewHelper.cleanListViews()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(message); 
        }

        System.debug(LoggingLevel.DEBUG, debug);
        ListViewErrorHelper.addLog('ListViewHelper(cleanListViews)', debug);

        ListViewErrorHelper.processLogs(false);

    }

    public static List<List_View_Action__c> insertCoreActions()
    {
        List<List_View_Action__c> actions = new List<List_View_Action__c>();

        List_View_Action__c orgNewAction = new List_View_Action__c();
        orgNewAction.Apex_Class_Name__c  = 'ListViewActionCreate';
        orgNewAction.Label__c            = 'New';
        orgNewAction.RecordTypeId        = ListViewActionHelper.coreRTId;
        orgNewAction.Permissions__c      = ListViewActionHelper.PERM_CREATE;
        orgNewAction.Is_Active__c        = true;
        orgNewAction.Selected_Record_Visibility__c = ListViewActionHelper.VIS_ALWAYS;

        actions.add(orgNewAction);

        List_View_Action__c orgCloneAction = new List_View_Action__c();
        orgCloneAction.Apex_Class_Name__c  = 'ListViewActionClone';
        orgCloneAction.Label__c            = 'Clone';
        orgCloneAction.RecordTypeId        = ListViewActionHelper.coreRTId;
        orgCloneAction.Permissions__c      = ListViewActionHelper.PERM_CREATE;
        orgCloneAction.Is_Active__c        = true;
        orgCloneAction.Selected_Record_Visibility__c = ListViewActionHelper.VIS_ONLY_ONE;

        actions.add(orgCloneAction);

        List_View_Action__c orgEditAction = new List_View_Action__c();
        orgEditAction.Apex_Class_Name__c  = 'ListViewActionEdit';
        orgEditAction.Label__c            = 'Edit';
        orgEditAction.RecordTypeId        = ListViewActionHelper.coreRTId;
        orgEditAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;
        orgEditAction.Is_Active__c        = true;
        orgEditAction.Selected_Record_Visibility__c = ListViewActionHelper.VIS_ONLY_ONE;

        actions.add(orgEditAction);

        List_View_Action__c orgEditAllAction = new List_View_Action__c();
        orgEditAllAction.Apex_Class_Name__c  = 'ListViewActionEditAll';
        orgEditAllAction.Label__c            = 'Edit All';
        orgEditAllAction.RecordTypeId        = ListViewActionHelper.coreRTId;
        orgEditAllAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;
        orgEditAllAction.Is_Active__c        = true;
        orgEditAllAction.Selected_Record_Visibility__c = ListViewActionHelper.VIS_ALWAYS;

        actions.add(orgEditAllAction);

        List_View_Action__c orgDeleteAction = new List_View_Action__c();
        orgDeleteAction.Apex_Class_Name__c  = 'ListViewActionDelete';
        orgDeleteAction.Label__c            = 'Delete';
        orgDeleteAction.RecordTypeId        = ListViewActionHelper.coreRTId;
        orgDeleteAction.Permissions__c      = ListViewActionHelper.PERM_DELETE;
        orgDeleteAction.Is_Active__c        = true;
        orgDeleteAction.Selected_Record_Visibility__c = ListViewActionHelper.VIS_AT_LEAST_ONE;

        actions.add(orgDeleteAction);

        List_View_Action__c acctUpdateAction = new List_View_Action__c();
        acctUpdateAction.Apex_Class_Name__c  = 'ListViewActionUpdate';
        acctUpdateAction.Label__c            = 'Update';
        acctUpdateAction.Object_Type__c      = 'Account';
        acctUpdateAction.RecordTypeId        = ListViewActionHelper.coreRTId;
        acctUpdateAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;
        acctUpdateAction.Is_Active__c        = true;
        acctUpdateAction.Selected_Record_Visibility__c = ListViewActionHelper.VIS_AT_LEAST_ONE;

        actions.add(acctUpdateAction);

        List_View_Action__c oppsCloseUpdateAction = new List_View_Action__c();
        oppsCloseUpdateAction.Apex_Class_Name__c  = 'ListViewActionOppsClose';
        oppsCloseUpdateAction.Label__c            = 'Set Close Lost';
        oppsCloseUpdateAction.Object_Type__c      = 'Opportunity';
        oppsCloseUpdateAction.RecordTypeId        = ListViewActionHelper.coreRTId;
        oppsCloseUpdateAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;
        oppsCloseUpdateAction.Is_Active__c        = true;
        oppsCloseUpdateAction.Selected_Record_Visibility__c = ListViewActionHelper.VIS_AT_LEAST_ONE;

        actions.add(oppsCloseUpdateAction);

        List_View_Action__c hyperAction = new List_View_Action__c();
        hyperAction.Apex_Class_Name__c  = 'ListViewActionHyperLink';
        hyperAction.Label__c            = 'Go To A Cool App';
        hyperAction.Object_Type__c      = 'simpli_lv__List_View__c';
        hyperAction.Is_Hyperlink__c     = true;
        hyperAction.RecordTypeId        = ListViewActionHelper.coreRTId;
        hyperAction.Is_Active__c        = true;
        hyperAction.Selected_Record_Visibility__c = ListViewActionHelper.VIS_ALWAYS;

        actions.add(hyperAction);

        List_View_Action__c mailAction = new List_View_Action__c();
        mailAction.Apex_Class_Name__c  = 'ListViewActionEmail';
        mailAction.Label__c            = 'Send Email';
        mailAction.Object_Type__c      = 'Contact';
        mailAction.RecordTypeId        = ListViewActionHelper.coreRTId;
        mailAction.Permissions__c      = ListViewActionHelper.PERM_READ;
        mailAction.Is_Active__c        = true;
        mailAction.Selected_Record_Visibility__c = ListViewActionHelper.VIS_AT_LEAST_ONE;

        actions.add(mailAction);

        List_View_Action__c savePDFCoreAction = new List_View_Action__c();
        savePDFCoreAction.Apex_Class_Name__c  = 'ListViewActionPDF';
        savePDFCoreAction.Label__c            = 'Save To PDF';
        savePDFCoreAction.Object_Type__c      = '';
        savePDFCoreAction.RecordTypeId        = ListViewActionHelper.coreRTId;
        savePDFCoreAction.Permissions__c      = ListViewActionHelper.PERM_READ;
        savePDFCoreAction.Is_Active__c        = true;
        savePDFCoreAction.Selected_Record_Visibility__c = ListViewActionHelper.VIS_ALWAYS;

        actions.add(savePDFCoreAction);

        List_View_Action__c savePDFCustomAction = new List_View_Action__c();
        savePDFCustomAction.Apex_Class_Name__c  = 'ListViewActionPDF';
        savePDFCustomAction.Label__c            = 'Save To PDF';
        savePDFCustomAction.Object_Type__c      = 'Opportunity';
        savePDFCustomAction.SubType__c          = 'Manual';
        savePDFCustomAction.RecordTypeId        = ListViewActionHelper.customRTId;
        savePDFCustomAction.Permissions__c      = ListViewActionHelper.PERM_READ;
        savePDFCustomAction.Is_Active__c        = true;
        savePDFCustomAction.Selected_Record_Visibility__c = ListViewActionHelper.VIS_ALWAYS;

        actions.add(savePDFCustomAction);
        
        actions = HelperDatabase.insertRecords(actions);
        Map<String, SObject> actionsByLabel = HelperCollection.getStringMappedObjects(actions, 'Label__c');

        List<List_View_Action_Parameter__c> params = new List<List_View_Action_Parameter__c>();

        List_View_Action_Parameter__c param = new List_View_Action_Parameter__c();
        param.Field_API_Name__c   = 'Name';
        param.Label__c            = 'Account Name';
        param.Display_Order__c    = 1;
        param.List_View_Action__c = actionsByLabel.get('Update').Id;
        param.Placeholder_Text__c = 'Account name goes here...';
        param.Type__c             = ListViewHelper.TYPE_STRING;

        params.add(param);

        param                     = new List_View_Action_Parameter__c();
        param.Field_API_Name__c   = 'Industry';
        param.Label__c            = 'Industry';
        param.Display_Order__c    = 2;
        param.List_View_Action__c = actionsByLabel.get('Update').Id;
        param.Placeholder_Text__c = 'Industry goes here...';
        param.Type__c             = ListViewHelper.TYPE_PICKLIST;

        params.add(param);

        param                     = new List_View_Action_Parameter__c();
        param.Field_API_Name__c   = 'CloseDate';
        param.Label__c            = 'Close Date';
        param.Display_Order__c    = 1;
        param.List_View_Action__c = actionsByLabel.get('Set Close Lost').Id;
        param.Placeholder_Text__c = '';
        param.Type__c             = ListViewHelper.TYPE_DATE;

        params.add(param);

        param                     = new List_View_Action_Parameter__c();
        param.Field_API_Name__c   = 'URL';
        param.Label__c            = 'URL';
        param.Display_Order__c    = -1;
        param.List_View_Action__c = actionsByLabel.get('Go To A Cool App').Id;
        param.Type__c             = ListViewHelper.TYPE_URL;
        param.Default_Value__c    = 'https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FZ7BDUA1';

        params.add(param);

        param                     = new List_View_Action_Parameter__c();
        param.Field_API_Name__c   = 'Subject';
        param.Label__c            = 'Email Subject';
        param.Display_Order__c    = 1;
        param.List_View_Action__c = actionsByLabel.get('Send Email').Id;
        param.Type__c             = ListViewHelper.TYPE_STRING;
        param.Default_Value__c    = '';

        params.add(param);

        param                     = new List_View_Action_Parameter__c();
        param.Field_API_Name__c   = 'Body';
        param.Label__c            = 'Email Body';
        param.Display_Order__c    = 2;
        param.List_View_Action__c = actionsByLabel.get('Send Email').Id;
        param.Type__c             = ListViewHelper.TYPE_RICH_TEXTAREA;
        param.Default_Value__c    = '';

        params.add(param);

        params = HelperDatabase.insertRecords(params);

        return actions;
    }

    //---------------------------------------
    // ALL:ALL Config
    //---------------------------------------
    public static List_View_Config__c insertCoreGlobalConfig()
    {
        List_View_Config__c config = new List_View_Config__c();
        config.Name                = 'All';
        config.List_View_Object__c = 'All';
        config.List_View_Label__c   = 'Org Wide Configuration';
        config.Primary_Key__c      = config.List_View_Object__c + ':' + config.Name;
        
        config = (List_View_Config__c) HelperDatabase.insertRecord(config);

        List<List_View_Config_Parameter__c> params = new List<List_View_Config_Parameter__c>();
        List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'ListViewObjects';
        param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param.Parameter_Value__c  = '';
        param.Parameter_Label__c  = 'List View Objects';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'IncludedObjectTypes';
        param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param.Parameter_Value__c  = '';
        param.Parameter_Label__c  = 'Included Object Types';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'ExcludedObjectTypes';
        param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param.Parameter_Value__c  = 'FlowInterview,CollaborationGroup,Idea,OperatingHours,ServiceAppointment,WorkType,Solution';
        param.Parameter_Label__c  = 'Excluded Object Types';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'DisplayActionsButton';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Display Actions Button';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'AllowAdmin';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Display Admin Button';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'DisplayListViewReprocessingButton';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Display List View Reprocessing Button';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'DisplayOriginalListViewButton';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Display Original List View Button';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'DisplaySelectedCount';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Display Selected Count';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'AllowDataExport';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Allow Data Export';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'AllowAutomaticDataRefresh';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Allow Automatic Data Refresh';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'DisplayRowCount';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Display Row Count';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'MaxRowsDisplayed';
        param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
        param.Parameter_Value__c  = '2500';
        param.Parameter_Label__c  = 'Max Rows Displayed';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'QueryPagingSize';
        param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
        param.Parameter_Value__c  = '250';
        param.Parameter_Label__c  = 'Query Paging Size';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'IsInitialized';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.FFALSE;
        param.Parameter_Label__c  = 'Is Initialized';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'AllowInlineEditing';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Allow Inline Editing';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'DisplayAllRelatedRecords';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.FFALSE;
        param.Parameter_Label__c  = 'Display All Related Records';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'AllowHorizontalScrolling';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.FFALSE;
        param.Parameter_Label__c  = 'Allow Horizontal Scrolling';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'DisplayTextSearch';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Display Text Search';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'DisplayRecordPopovers';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Display Record Popovers';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'TypeAheadListSearch';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.FFALSE;
        param.Parameter_Label__c  = 'Use Type-Ahead For List View Search';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'TypeAheadObjectSearch';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.FFALSE;
        param.Parameter_Label__c  = 'Use Type-Ahead For Object Search';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'ExcludedRecordPopoverTypes';
        param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param.Parameter_Value__c  = '';
        param.Parameter_Label__c  = 'Excluded Record Popover Types';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'Debug';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.FFALSE;
        param.Parameter_Label__c  = 'Debug';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'RefreshJob';
        param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param.Parameter_Value__c  = HelperScheduler.NOT_SCHEDULED;
        param.Parameter_Label__c  = 'Scheduled Refresh Job';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'ExcludedListViews';
        param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param.Parameter_Value__c  = '';
        param.Parameter_Label__c  = 'Excluded List Views';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'AddObjNameOnLookupLabels';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.FFALSE;
        param.Parameter_Label__c  = 'Add Object Name On Lookup Labels';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'UseSimpleSorting';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Use Standard Single Column Sorting';
        params.add(param);

        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = 'NoSorting';
        param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param.Parameter_Value__c  = ListViewHelper.TTRUE;
        param.Parameter_Label__c  = 'Do Not Allow Sorting';
        params.add(param);

        HelperDatabase.insertRecords(params);

        return ListViewConfigHelper.getListViewConfig('All', 'All'); 
    }

    public static List<List_View_Config__c> insertCoreListViewConfig()
    {
        insertCoreGlobalConfig();

        List<List_View_Config__c> configs = new List<List_View_Config__c>();

        List_View_Config__c config = new List_View_Config__c();
        config.Name                = 'simpli_lv__PlatinumandGoldSLACustomers';
        config.List_View_Label__c  = 'Platinum And Gold SLA Customers';
        config.List_View_Object__c = 'Account';
        config.Primary_Key__c      = config.List_View_Object__c + ':' + config.Name;
        configs.add(config);

        List_View_Config__c config2 = new List_View_Config__c();
        config2.Name                = 'simpli_lv__AllAccounts';
        config2.List_View_Object__c = 'Account';
        config2.List_View_Label__c   = 'All Accounts';
        config2.Primary_Key__c      = config2.List_View_Object__c + ':' + config2.Name;
        configs.add(config2);

        configs = HelperDatabase.insertRecords(configs);
        Map<String, SObject> configsByName = HelperCollection.getStringMappedObjects(configs, 'Name');
        config = (simpli_lv__List_View_Config__c) configsByName.get('simpli_lv__PlatinumandGoldSLACustomers');
        config2 = (simpli_lv__List_View_Config__c) configsByName.get('simpli_lv__AllAccounts');

        List<List_View_Config_Parameter__c> params = new List<List_View_Config_Parameter__c>();
      
        List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = PARAM_ADD_FIELDS;
        param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param.Parameter_Value__c  = 'Type, AnnualRevenue,CreatedBy.Name,Owner.Profile.Name';
        param.Parameter_Label__c  = 'Additional Fields';
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = ListViewHelper.PARAM_TOTAL_COLUMNS;
        param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param.Parameter_Value__c  = 'AnnualRevenue';
        param.Parameter_Label__c  = 'Total Columns';
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
        param.List_View_Config__c = config.Id;
        param.Parameter_Name__c   = ListViewHelper.PARAM_TOTAL_COLUMN_COLOR;
        param.Parameter_Type__c   = 'Color';
        param.Parameter_Value__c  = '#6C95BD';
        param.Parameter_Label__c  = 'Total Row Color';
        params.add(param);

        //---------------------------------------
        // 
        //---------------------------------------
        param = new List_View_Config_Parameter__c();
        param.Parameter_Name__c = PARAM_ADD_FIELDS;
        param.Parameter_Type__c = ListViewHelper.TYPE_STRING;
        param.Parameter_Value__c = 'CreatedBy.Name, Owner.Profile.Name, AnnualRevenue';
        param.List_View_Config__c = config2.Id;
        param.Parameter_Label__c  = 'Additional Fields';
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
        param.Parameter_Name__c = ListViewHelper.PARAM_TOTAL_COLUMNS;
        param.Parameter_Type__c = ListViewHelper.TYPE_STRING;
        param.Parameter_Value__c = 'AnnualRevenue';
        param.List_View_Config__c = config2.Id;
        param.Parameter_Label__c  = 'Total Columns';
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
        param.Parameter_Name__c = ListViewHelper.PARAM_TOTAL_COLUMN_COLOR;
        param.Parameter_Type__c = 'Color';
        param.Parameter_Value__c = '#6C95BD';
        param.List_View_Config__c = config2.Id;
        param.Parameter_Label__c  = 'Total Row Color';
        params.add(param);
        
        HelperDatabase.insertRecords(params);

        List<List_View_Config_Condition__c> conditions = new List<List_View_Config_Condition__c>();

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.List_View_Config__c = config.Id;
        condition.Field_Name__c       = 'Name';
        condition.Operator__c         = 'Contains';
        condition.Value__c            = 'Burlington';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = '#c59e9e';
        conditions.add(condition);

        conditions = HelperDatabase.insertRecords(conditions);

        return configs;
    }

    public static List<List_View__c> insertCoreListViews()
    {
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

        listViews = HelperDatabase.insertRecords(listViews);

        //org might not have CampaignMember object so do it individually.
        if (HelperSchema.isObject('CampaignMember')) //if we do not have sales cloud this will not work!
        {
            listViews = new List<List_View__c>();
            lv                          = new List_View__c();
            lv.Custom_Apex_Class__c     = 'ListViewCustomManual';
            lv.Label__c                 = 'Campaign Members';
            lv.Core_ListView_Columns__c = '[{"fieldNameOrPath":"Name","type":"string","label":"Name"},  {"fieldNameOrPath":"Status","type":"string","label":"Status"},{"fieldNameOrPath":"Type","type":"string","label":"Type"},{"fieldNameOrPath":"Phone","type":"string","label":"Phone"}]';
            lv.Core_ListView_Query__c   = 'SELECT Name, Status, Type, Phone FROM CampaignMember';
            lv.Object_Name__c           = 'CampaignMember';
            lv.RecordTypeId             = ListViewHelper.customRTId;
            lv.Subtype__c               = 'Manual';

            listViews.add(lv);
            listViews = HelperDatabase.insertRecords(listViews);

        }

        //org might not have PriceBook2 object so do it individually.
        try 
        {
            listViews = new List<List_View__c>();
            lv                          = new List_View__c();
            lv.Custom_Apex_Class__c     = 'ListViewCustomManual';
            lv.Label__c                 = 'Pricebook Standard';
            lv.Core_ListView_Columns__c = '[{"fieldNameOrPath":"Name","type":"string","label":"Name"},{"fieldNameOrPath":"CreatedDate","type":"date","label":"Created Date"},{"fieldNameOrPath":"IsActive","type":"boolean","label":"Is Active"},{"fieldNameOrPath":"IsStandard","type":"boolean","label":"Is Standard"},{"fieldNameOrPath":"LastModifiedDate","type":"datetime","label":"Last Modified Date"}]';
            lv.Core_ListView_Query__c   = 'SELECT CreatedDate,IsActive,IsStandard,LastModifiedDate,Name FROM Pricebook2';
            lv.Object_Name__c           = 'Pricebook2';
            lv.RecordTypeId             = ListViewHelper.customRTId;
            lv.Subtype__c               = 'Manual';

            listViews.add(lv);
            listViews = HelperDatabase.insertRecords(listViews);

        } catch (Exception e) { }


        return listViews;
    }

    /**
    * @description Method to retrieve list view data based on user provided criteria.
    * @author tom@ansleyllc.com | 06-28-2021 
    * @param pageName the name of the lightning page that the list is being displayed on. This is used for list view config retrieval
    * @param compType the mode of the component the data is being retrieved for.
    * @param objectName the name of the list view object
    * @param listViewName the name of the list view
    * @param sortData the sorting information for the list view.
    * @param joinFieldName used by a list view component listening on the same page. Indicates the field name used to join the data between the two list views.
    * @param joinData the joined field data to use when performing the query.
    * @param offset indicates the offset if the data is being paged.
    * @param isShell indicates whether the request should only retrieve the rowwrapper without data or all the data
    * @return ListViewAbstract.RowsWrapper 
    **/
    public static ListViewAbstract.RowsWrapper getListViewData(String pageName, String compType, String objectName, String listViewName, String sortData, String joinFieldName, String joinData, Integer offset, Boolean isShell, String textSearchStr)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewHelper.getListViewData(' + pageName + ', ' + objectName + ', ' + listViewName + ',' + sortData + ',' + joinFieldName + ',' + joinData + ', ' + isShell + ', ' + textSearchStr + ')');
        
        ListViewAbstract.RowsWrapper rowData = null;

        ListViewAbstract lvLogic = getListViewProcessor(pageName, compType, objectName, listViewName, offset, isShell, textSearchStr);
        lvLogic.setListView(ListViewHelper.getListViews(objectName, listViewName).values()[0]);

        lvLogic.setSortingData(sortData);
        lvLogic.setJoinData(joinFieldName, joinData);
        lvlogic.setOffset(offset);

        rowData = lvLogic.getData();

        String debug = '\n\n=======================================================================================\n';
        for (ListViewAbstract.RowWrapper row: rowData.rows)
        {
            debug += '-------------------------------------\n';
            debug += 'Row Id - ' + row.getRowId() + '\n';
            for (String field: row.fields.keySet())
            {
                ListViewAbstract.FieldWrapper fWrapper = row.fields.get(field);
                debug += 'Field - ' + fWrapper + '\n';
            }                
            debug += '-------------------------------------\n';
        }
        debug       += '=======================================================================================\n';
        System.debug(LoggingLevel.FINE, debug);
        
        //update the sorting for this user for this list view for this component. This MUST be done at the end!
        if (!rowData.isDefaultSort && !isShell)
            ListViewUserConfigHelper.updateSortConfigValue(pageName, lvLogic.getSortString(), objectName, listviewName);

        ListViewUserActivityHelper.registerView(pageName, compType, objectName, listViewName, lvLogic.listview.Id, rowData.getRowCount());

        ListViewErrorHelper.processLogs(true);

        return rowData;

    }

    public static ListViewAbstract getListViewProcessor(String pageName, String compType, String objectName, String listViewName, Integer offset, Boolean isShell, String textSearchStr)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewHelper.getListViewData(' + pageName + ', ' + objectName + ', ' + listViewName + ',' + isShell + ', ' + textSearchStr + ')');
        ListViewAbstract lvLogic = null;

        //------------------------------------------------------------------------------------------
        //LIST VIEW METADATA
        //------------------------------------------------------------------------------------------
        Map<Id, List_View__c> listviews = ListViewHelper.getListViews(objectName, listViewName);

        if (listviews.size() > 0) 
        {

            List_View__c listview = listviews.values()[0];

            //------------------------------------------------------------------------------------------
            //LIST VIEW APEX CLASS CREATION AND PROCESSING
            //------------------------------------------------------------------------------------------
            String objType = null;
            if (listView.RecordTypeId == null || listView.RecordTypeId == ListViewHelper.coreRTId)
            {
                objType = ListViewHelper.CORE_APEX_CLASS;

            } else {
                
                objType = listView.Custom_Apex_Class__c;
            }

            //get an apex Type of the object type
            Type t = HelperSchema.getClassType(objType);

            //create a new instance
            lvLogic = (ListViewAbstract) t.newInstance();
            lvLogic.setIsShell(isShell);
            lvLogic.setMode(compType);
            lvLogic.setPageName(pageName);
            lvLogic.setTextSearchString(textSearchStr);

        } else {
            throw new ListViewException('The list view configuration can not be found for object ' + objectName + ' and list view name - ' + listViewName + ')');
        }
        
        return lvlogic;
    }

    public static String exportJSON(String type, Boolean incLVConf, Boolean incGlobalConf, Boolean incActions)
    {
        return exportJSON(type, incLVConf, incGlobalConf, incActions, new Set<Id>());    
    }

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

        if (HelperProfile.hasModifyAll()) return true;

        if (lv.All_Internal_Users__c != null && lv.All_Internal_Users__c) return true;

        return false;
    }

    public static String updateSingleListView(String objectType, String listViewName)
    {
        objectType = String.escapeSingleQuotes(objectType);
        listViewName = String.escapeSingleQuotes(listViewName);

        //get the listviews with object and name
        Map<Id, List_View__c> listviews = ListViewHelper.getListViews(objectType, listViewName);

        //if we have an SLV listview to update
        if (listviews.size() > 0) {

            //get the list views Id
            Set<Id> lvId = new Set<Id>();
            lvId.add(listviews.values()[0].Id);

            //update the list view
            Boolean result = ListViewHelper.updateListViewsFromSLVIds(lvId);

        //if we don't then try to update because the list view could be new
        } else {
            List<ListView> coreListViews = ListViewHelper.getCoreListViews(objectType, listViewName);
            Boolean result = updateListViewsFromCore(coreListViews);
        }

        //remove cache so that list views are refetched
        CacheHelper.clearCache(UserInfo.getUserId().removeStart('005'));

        return SUCCESS;
    }

    public static String updateObjectListViews(String objectType)
    {
        //update the list view
        Boolean result = ListViewHelper.updateListViewsFromObj(objectType);

        //remove cache so that list views are refetched
        CacheHelper.clearCache(UserInfo.getUserId().removeStart('005'));

        return SUCCESS;
    }

    public static String updateAllListViews()
    {

        Simpli_lv.ListViewPreProcessBatch b = new Simpli_lv.ListViewPreProcessBatch();
        
        Id jobId = null;
        
        try {
            jobId = Database.executebatch(b, 40);
        } catch (Exception e) {
            jobId = FAILED;
            String message = 'Exception during ListViewController.updateAllListViews()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
        }

        //remove cache so that list views are refetched
        CacheHelper.clearAllCache();

        return jobId;
    }

    public static String updateChangedListViews()
    {
        //try get the last changed CORE list view
        Map<Id, ListView> changedListViews = ListViewHelper.getLastChangedListViewForUser(UserInfo.getUserId());

        if (changedListViews.size() > 0)
        {
            //get the changed CORE list view
            ListView lv = changedListViews.values()[0];

            //get the SIMPLI listviews with object and name
            Map<Id, List_View__c> listviews = ListViewHelper.getListViews(lv.SObjectType, lv.DeveloperName);

            //if SIMPLI listviews return then process
            if (listviews.size() > 0)
            {

                //get the list views Id
                Set<Id> lvId = new Set<Id>();
                lvId.add(listviews.values()[0].Id);

                //update the list view
                ListViewHelper.updateListViewsFromSLVIds(lvId);

            }
        }

        return SUCCESS;
    }





    //================================================================================================================
    // GLOBAL METHODS
    //================================================================================================================

    global static void insertCoreConfiguration()
    {
        insertCoreActions();

        insertCoreListViewConfig();

        insertCoreListViews();
    }

    global static String deleteCustomListViews(Map<String, List_View__c> listViews)
    {
        return deleteListViews(listViews);
    }

    global static String refreshObjectListViews(String objectName)
    { 
        objectName = String.escapeSingleQuotes(objectName);
        return updateObjectListViews(objectName);
    }

    global static String refreshSingleListView(String objectName, String listViewName)
    {
        return updateSingleListView(objectName, listViewName);
    }

    global static String refreshChangedListViews()
    {
        return updateChangedListViews();
    }

    global static String refreshAllListViews()
    {
        return updateAllListViews();
    }

    global static Map<String, List_View__c> getObjectListViews(String objectName)
    {
        objectName = String.escapeSingleQuotes(objectName);
        return ListViewHelper.getListViewsByObject(objectName);
    }


    global static Map<String, String> getListViewObjects()
    {
        return getListViewObjects(new Set<String>(), new Set<String>(), true);
    }

    global static void clearCache()
    {
        CacheHelper.clearAllCache();
    }

    /*
        System.debug(LoggingLevel.ERROR, 'SOQL - ' + ListViewHelper.getListViewQuery('Example_1_All_List_View', 'App Page', 'simpli_lv__List_View__c', 'simpli_lv__All','','','', -1, false,''));     
    */
    global static String getListViewQuery(String pageName, String compType, String objectName, String listViewName, String sortData, String joinField, String joinData, Integer offset, Boolean isShell, String textSearchStr)
    {
        ListViewAbstract lvLogic = getListViewProcessor(pageName, compType, objectName, listViewName, offset, isShell, textSearchStr);
        List_View__c listview = ListViewHelper.getListViews(objectName, listViewName).values()[0];
        lvLogic.setListView(listview);
        lvLogic.setSortingData(sortData);
        lvLogic.setJoinData(joinField, joinData);
        lvlogic.setOffset(offset);

        return lvlogic.getQuery();
    }

    /*
        System.debug(LoggingLevel.ERROR, 'SOQL - ' + ListViewHelper.getListViewQuery('Example_1_All_List_View', 'App Page', 'simpli_lv__List_View__c', 'simpli_lv__All_Custom','[]','','', -1, false,''));     
    */
    global static List<Map<String, String>> getListViewColumns(String pageName, String compType, String objectName, String listViewName, String sortData, String joinField, String joinData, Integer offset, Boolean isShell, String textSearchStr)
    {
        ListViewAbstract lvLogic = getListViewProcessor(pageName, compType, objectName, listViewName, offset, isShell, textSearchStr);
        List_View__c listview = ListViewHelper.getListViews(objectName, listViewName).values()[0];
        lvLogic.setListView(listview);
        lvLogic.setSortingData(sortData);
        lvLogic.setJoinData(joinField, joinData);
        lvlogic.setOffset(offset);

        List<Map<String, String>> columns = new List<Map<String, String>>();
        for (ListViewAbstract.ListViewColumn column: lvlogic.getColumnData())
        {
            Map<String, String> c = new Map<String, String>();
            c.put('label', column.getLabel());
            c.put('name', column.name);
            c.put('columnWidth', column.width);
            c.put('type', column.type);
            columns.add(c);
        }

        return columns;
    }

    /*
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + ListViewAdminController.getConfigExportJSON());
     */
    global static String exportJSON(String type, Boolean incLVConf, Boolean incGlobalConf, Boolean incActions, Set<Id> ids)
    {
        String jsonStr = '';
        
        //the thing we will stuff all objects into and then JSONify!
        Map<String, List<SObject>> objects = new Map<String, List<SObject>>();

        //1. List Views where record type is custom
        Map<Id, List_View__c> listviews = getListViewsByType(type, false);

        List<List_View__c> lvs = new List<List_View__c>();
        if (ids?.size() > 0)
        {
            for (Id id: ids)
            {
                if (listviews.containsKey(id))
                    lvs.add(listviews.get(id));
            }
            
        } else {
            lvs.addAll(listviews.values());
        }
        objects.put('ListViews', lvs);

        Set<String> primaryKeys = new Set<String>();
        if (incGlobalConf)
            primaryKeys.add('All:All');

        if (incLVConf) {
            for (List_View__c listview: lvs)
                primaryKeys.add(getPrimaryKey(listview));
        }

        if (!primaryKeys.isEmpty()) {
            //2. All configs for the custom list views and the global configs
            Map<String, List_View_Config__c> configs = ListViewConfigHelper.getListViewConfigs(primaryKeys);
            objects.put('ListViewConfigs', configs.values());
        }

        //3. All actions
        if (incActions) {
            List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
            objects.put('Actions', actions);
        }

        jsonStr = JSON.serialize(objects);

        return jsonStr;
    }

    global static String importJSON(String configStr)
    {
        String response = '';
        String debug = '\n\n----- Import Response -----\n';

        try {
            System.debug(LoggingLevel.FINE, 'Starting ListViewHelper.importJSON(' + configStr + ')');

            Map<String, List<SObject>> allConfig = (Map<String, List<SObject>>) JSON.deserialize(configStr, Map<String, List<SObject>>.class);

            //-----------------------------------------------------------------
            //GET THE DATA FROM THE INPUT (making sure to CLONE the objects and
            //                             removing any Id that might exist)
            //
            //-----------------------------------------------------------------

            Map<Integer, List_View__c> oldListViews = new Map<Integer, List_View__c>();
            Map<Integer, List_View__c> newListViews = new Map<Integer, List_View__c>();

            Map<Integer, List_View_Action__c> oldActions = new Map<Integer, List_View_Action__c>();
            Map<Integer, List_View_Action__c> newActions = new Map<Integer, List_View_Action__c>();

            Map<Integer, List_View_Config__c> oldConfigs = new Map<Integer, List_View_Config__c>();
            Map<Integer, List_View_Config__c> newConfigs = new Map<Integer, List_View_Config__c>();

            for (String objType: allConfig.keySet())
            {
                if (objType == 'ListViews')
                {
                    Integer tempKey = 1;
                    //get all list views from input
                    List<List_View__c> tempListViews = (List<List_View__c>) allConfig.get('ListViews');
                    for (List_View__c listview: tempListViews)
                    {
                        listview.Core_ListView_Id__c = '';
                        listview.RecordTypeId = ListViewHelper.customRTId;
                        listview.OwnerId = UserInfo.getUserId();
                        listview.Id = null;
                        //create a new cloned list view that will be used for upsertion.
                        newListViews.put(tempKey, listview.clone(false, true, false, false));
                        tempKey++;
                    }
                } else if (objType == 'ListViewConfigs') 
                {
                    Integer tempKey = 1;
                    //get all configs from input
                    List<List_View_Config__c> tempConfigs = (List<List_View_Config__c>) allConfig.get('ListViewConfigs');
                    for (List_View_Config__c config: tempConfigs)
                    {
                        config.OwnerId = UserInfo.getUserId();
                        config.Id = null;

                        //create a new cloned config that will be used for upsertion.
                        newConfigs.put(tempKey, config.clone(false, true, false, false));

                        //put the old config aside for use when handling children
                        oldConfigs.put(tempKey, config);
                        tempKey++;
                    }

                //because the actions primary key is not an external Id we cannot use it as a primary key (doh!) so we need to use the Ids!
                } else if (objType == 'Actions')
                {
                    Integer tempKey = 1;

                    //get the imported actions.
                    List<List_View_Action__c> importActions = (List<List_View_Action__c>) allConfig.get('Actions');
                    
                    //because the actions primary key is not an external Id we cannot use it as a primary key (doh!) so we need to use the Ids!
                    Set<String> primaryKeys = HelperCollection.getStringFieldSet(importActions, 'Primary_Key__c');
                    Map<String, List_View_Action__c> existingActionsByKey = ListViewActionHelper.getListViewActionsByKey(primaryKeys);

                    //go through the imported actions. If it exists then set the imported actions Id to the existing Id based on primary key
                    for (List_View_Action__c action: importActions)
                    {
                        action.OwnerId = UserInfo.getUserId();
                        action.Id = null;

                        if (String.isEmpty(action.Subtype__c))
                            action.RecordTypeId = ListViewActionHelper.coreRTId;
                        else
                            action.RecordTypeId = ListViewActionHelper.customRTId;

                        List_View_Action__c existingAction = existingActionsByKey.get(action.Primary_Key__c);
                        if (existingAction != null)
                            action.Id = existingAction.Id; //set the correct existing Id into the old action based on the primary key
                        else
                            action.Id = null;
                    }

                    //now clone the imported action.
                    for (List_View_Action__c action: importActions)
                    {
                        //create a new cloned action that will be used for upsertion.
                        newActions.put(tempKey, action.clone(true, true, false, false)); //preserveId = true in this case!

                        //put the old action aside for use when handling children
                        oldActions.put(tempKey, action);
                        tempKey++;
                    }
                }
            }




            //-----------------------------------------------------------------
            //INSERT LIST VIEWS (Easy as there are no children)
            // RESULTS - WORKS FOR UPDATES
            //           WORKS FOR INSERT (where API and Primary Key are changed)
            //-----------------------------------------------------------------

            List<Database.UpsertResult> results = HelperDatabase.upsertRecordsNoStrip(newListViews.values(), 'simpli_lv__Primary_Key__c', false);

            Integer errorCount = 0;
            Integer successCount = 0;
            for (Database.UpsertResult result: results)
            {
                if (result.isSuccess()) {
                    successCount++;
                    debug += 'List View Success - ' + result.getId() + '\n';
                } else {
                    errorCount++;
                    debug += 'List View Error   - ' + result.getErrors() + '\n';
                }
            }

            response += 'List Views:' + successCount + ':' + errorCount + ';      ';
            debug    += 'List Views Totals:' + successCount + ':' + errorCount + '\n\n';

            //-----------------------------------------------------------------
            //GET THE CONFIG PARAMETERS AND CONDITIONS FROM THE CONFIGS
            //-----------------------------------------------------------------

            Map<Integer, List<List_View_Config_Parameter__c>> configParamsByKey = new Map<Integer, List<List_View_Config_Parameter__c>>();
            Map<Integer, List<List_View_Config_Condition__c>> configCondsByKey = new Map<Integer, List<List_View_Config_Condition__c>>();

            //1. Put all config parameters and conditions into a map by the tempKey
            for (Integer key: oldConfigs.keySet())
            {
                List_View_Config__c oldConfig = oldConfigs.get(key);

                if (oldConfig.List_View_Config_Parameters__r != null)
                    configParamsByKey.put(key, oldConfig.List_View_Config_Parameters__r);
                if (oldConfig.List_View_Config_Conditions__r != null)
                    configCondsByKey.put(key, oldConfig.List_View_Config_Conditions__r);
            }

            //2. upsert all configs
            results = HelperDatabase.upsertRecordsNoStrip(newConfigs.values(), 'simpli_lv__Primary_Key__c', false);

            errorCount = 0;
            successCount = 0;
            Set<String> successConfigIds = new Set<String>();
            for (Database.UpsertResult result: results)
            {
                if (result.isSuccess()) {
                    successCount++;
                    successConfigIds.add(result.getId());
                    debug += 'Config Success - ' + result.getId() + '\n';
                } else {
                    errorCount++;
                    debug += 'Config Error   - ' + result.getErrors() + '\n';
                }
            }

            response += 'Configs:' + successCount + ':' + errorCount + ';      ';
            debug    += 'Configs Totals:' + successCount + ':' + errorCount + '\n\n';

            Map<String, List_View_Config__c> fullConfigs = ListViewConfigHelper.getListViewConfigsById(successConfigIds); 


            //3. Put Ids of configs into config params and put in list for upsert
            List<List_View_Config_Parameter__c> configParams = new List<List_View_Config_Parameter__c>();
            for (Integer key: configParamsByKey.keySet())
            {
                List<List_View_Config_Parameter__c> params = configParamsByKey.get(key);
                if (params != null)
                {
                    List_View_Config__c newConfig = newConfigs.get(key);
                    if (newConfig.Id != null)
                    {
                        List_View_Config__c fullConfig = fullConfigs.get(newConfig.Id);

                        for (List_View_Config_Parameter__c oldParam: params)
                        {

                            //if we are importing the is Initialized parameter for the global configs then automatically set to false!
                            if (newConfig.Primary_Key__c == 'All:All' && oldParam.Parameter_Name__c == 'IsInitialized')
                                oldParam.Parameter_Value__c = ListViewHelper.FFALSE;
                            
                            //check if the param already exists
                            Boolean paramExists = false;
                            for (List_View_Config_Parameter__c param: fullConfig.List_View_Config_Parameters__r)
                            {
                                if (param.Parameter_Name__c == oldParam.Parameter_Name__c)
                                    paramExists = true;
                            }

                            if (!paramExists)
                            {
                                oldParam.Id = null;

                                List_View_Config_Parameter__c newParam = oldParam.clone(false, true, false, false);
                                newParam.List_View_Config__c = newConfig.Id;
                                configParams.add(newParam);
                            }
                        }
                    }
                }
            }

            results = HelperDatabase.upsertRecordsNoStrip(configParams, null, false);

            errorCount = 0;
            successCount = 0;
            for (Database.UpsertResult result: results)
            {
                if (result.isSuccess()) {
                    successCount++;
                    debug += 'Config Param Success - ' + result.getId() + '\n';
                } else {
                    errorCount++;
                    debug += 'Config Param Error   - ' + result.getErrors() + '\n';
                }
            }
            debug    += 'Config Params Totals:' + successCount + ':' + errorCount + '\n\n';



            //3. Put Ids of configs into config conds and put in list for upsert
            List<List_View_Config_Condition__c> configConds = new List<List_View_Config_Condition__c>();
            for (Integer key: configCondsByKey.keySet())
            {
                List<List_View_Config_Condition__c> conds = configCondsByKey.get(key);
                if (conds != null)
                {
                    List_View_Config__c newConfig = newConfigs.get(key);
                    if (newConfig.Id != null)
                    {
                        List_View_Config__c fullConfig = fullConfigs.get(newConfig.Id);

                        for (List_View_Config_Condition__c oldCond: conds)
                        {
                            //check if the condition already exists
                            Boolean condExists = false;
                            for (List_View_Config_Condition__c cond: fullConfig.List_View_Config_Conditions__r)
                            {
                                if (cond.Field_Name__c == oldCond.Field_Name__c 
                                    && cond.Highlight_Color__c == oldCond.Highlight_Color__c)
                                    condExists = true;
                            }

                            if (!condExists)
                            {
                                oldCond.OwnerId = UserInfo.getUserId();
                                oldCond.Id = null;
                                List_View_Config_Condition__c newCond = oldCond.clone(false, true, false, false);
                                newCond.List_View_Config__c = newConfig.Id;
                                configConds.add(newCond);
                            }
                        }
                    }
                }
            }

            results = HelperDatabase.upsertRecordsNoStrip(configConds, null, false);

            errorCount = 0;
            successCount = 0;
            for (Database.UpsertResult result: results)
            {
                if (result.isSuccess()) {
                    successCount++;
                    debug += 'Config Cond Success - ' + result.getId() + '\n';
                } else {
                    errorCount++;
                    debug += 'Config Cond Error   - ' + result.getErrors() + '\n';
                }
            }
            debug    += 'Config Conds Totals:' + successCount + ':' + errorCount + '\n\n';





            //-----------------------------------------------------------------
            //INSERT ACTIONS AND PARAMETERS
            // RESULTS - WORKS FOR UPDATES
            //           WORKS FOR INSERT (where Primary Key is changed)
            //-----------------------------------------------------------------

            Map<Integer, List<List_View_Action_Parameter__c>> actionParamsByKey = new Map<Integer, List<List_View_Action_Parameter__c>>();

            //1. Put all action parameters into a map by the tempKey
            for (Integer key: oldActions.keySet())
            {
                List_View_Action__c oldAction = oldActions.get(key);
                if (oldAction.List_View_Action_Parameters__r != null)
                {
                    actionParamsByKey.put(key, oldAction.List_View_Action_Parameters__r);
                }
            }

            //2. upsert all actions
            results = HelperDatabase.upsertRecordsNoStrip(newActions.values(), 'Id', false);

            errorCount = 0;
            successCount = 0;
            Set<Id> successActionIds = new Set<Id>();
            for (Database.UpsertResult result: results)
            {
                if (result.isSuccess()) {
                    successCount++;
                    successActionIds.add(result.getId());
                    debug += 'Action Success - ' + result.getId() + '\n';
                } else {
                    errorCount++;
                    debug += 'Action Error   - ' + result.getErrors() + '\n';
                }
            }
            response += 'Actions:' + successCount + ':' + errorCount + ';      ';
            debug    += 'Actions Totals:' + successCount + ':' + errorCount + '\n\n';

            //REGET the actions so that we can determine if the parameters already exist
            Map<Id, List_View_Action__c> fullActions = ListViewActionHelper.getListViewActions(successActionIds); 



            //3. Put Ids of actions into action parameters and put in list for upsert
            List<List_View_Action_Parameter__c> actionParams = new List<List_View_Action_Parameter__c>();
            for (Integer key: actionParamsByKey.keySet())
            {
                List<List_View_Action_Parameter__c> params = actionParamsByKey.get(key);
                if (params != null)
                {
                    List_View_Action__c newAction = newActions.get(key);
                    if (newAction.Id != null)
                    {
                        List_View_Action__c fullAction = fullActions.get(newAction.Id);

                        for (List_View_Action_Parameter__c oldParam: params)
                        {
                            //check if the parameter already exists
                            Boolean paramExists = false;
                            for (List_View_Action_Parameter__c param: fullAction.List_View_Action_Parameters__r)
                            {
                                if (param.Field_API_Name__c == oldParam.Field_API_Name__c)
                                    paramExists = true;
                            }

                            if (!paramExists)
                            {
                                oldParam.Id = null;
                                List_View_Action_Parameter__c newParam = oldParam.clone(false, true, false, false);
                                newParam.List_View_Action__c = newAction.Id;
                                actionParams.add(newParam);
                            }
                        }
                    }
                }
            }

            //4. Insert action parameters
            results = HelperDatabase.upsertRecordsNoStrip(actionParams, null, false);

            errorCount = 0;
            successCount = 0;
            for (Database.UpsertResult result: results)
            {
                if (result.isSuccess()) {
                    successCount++;
                    debug += 'Action Param Success - ' + result.getId() + '\n';
                } else {
                    errorCount++;
                    debug += 'Action Param Error   - ' + result.getErrors() + '\n';
                }
            }
            debug    += 'Action Params Totals:' + successCount + ':' + errorCount + '\n\n';
            System.debug(LoggingLevel.DEBUG, 'Import response - ' + response);
        } catch (Exception e) {
            String message = ListViewException.getExtendedString(e);
            List_View_Error__c log   = new List_View_Error__c();
            log.Running_User__c  = UserInfo.getUserId();
            log.Message__c       = message;
            log.Type__c          = ListViewErrorHelper.TYPE_EXCEPTION;
            log.Subtype__c       = 'ListViewHelper(importJSON)';
            HelperDatabase.insertRecord(log);
            response = 'There was an error importing the data. Please see the logs for more details - ' + message;
        }

        List_View_Error__c log   = new List_View_Error__c();
        log.Running_User__c  = UserInfo.getUserId();
        log.Message__c       = debug;
        log.Type__c          = ListViewErrorHelper.TYPE_LOG;
        log.Subtype__c       = 'ListViewHelper(importJSON)';
        HelperDatabase.insertRecord(log);

        return response;
    }

    global class StandAloneListView {
        @AuraEnabled
        global List<ListViewHelper.StandAloneColumn> columns {get; set;}
        @AuraEnabled
        global List<ListViewHelper.StandAloneRow> data {get; set;}
    }

    global class StandAloneColumn {
        @AuraEnabled
        global String label {get; set;}
        @AuraEnabled
        global String columnWidth {get; set;}
        @AuraEnabled
        global String name {get; set;}
        @AuraEnabled
        global String type {get; set;}
    }

    global class StandAloneRow {
        @AuraEnabled
        global List<StandAloneField> fields {get; set;}

        public StandAloneRow() {
            fields = new List<StandAloneField>();
        }

        public void addField(String value) {
            fields.add(new StandAloneField(value));
        }
    }

    global class StandAloneField {
        @AuraEnabled
        global String value {get; set;}

        public StandAloneField(String value) {
            this.value = value;
        }
    }


    //================================================================================================================
    // PRIVATE METHODS
    //================================================================================================================


    /*
     * Method to check security and determine whether the list view is visible
     * to the requesting user. The following security is performed.
     * 1. if user is sys admin - TRUE
     * 2. if user is owner - TRUE
     * 3. if list view has role requirement and user is in role - TRUE
     * 4. if user is in allowed groups
     * 5. if user is in allowed territories
     */
    private static Map<Id, List_View__c> getVisibleListViews(Map<Id, List_View__c> listviews, String callId)
    {
        Map<Id, List_View__c> visible = new Map<Id, List_View__c>();
        Map<Id, List_View__c> hasGroup = new Map<Id, List_View__c>();
        Set<String> allGroupNames = new Set<String>();
        String debug = '\n\n----- List View Visibility Matrix -----\n';
        debug += 'Call Id              - ' + callId + '\n';
        debug += 'User                 - ' + UserInfo.getName() + ' (' + UserInfo.getUserId() + ')\n\n';

        //if the user has modify all data (sys admin) then return all list views
        if (HelperProfile.hasModifyAll()) 
        {
            visible = listviews;
            debug += 'Has Modify All           - true\n';
        
        } else {
            debug += 'Has Modify All           - false\n';

            for (List_View__c lv: listviews.values())
            {
                //if the current user owns the list view then its visible
                if (lv.OwnerId == UserInfo.getUserId())
                {
                    visible.put(lv.Id, lv);
                    debug += 'Is Owner                 - true (' + lv.Label__c + ')\n';
                }

                debug += 'Is Private               - ' + lv.Is_Private__c + '\n';

                //only check roles/groups etc if the lv is NOT private
                if (!lv.Is_Private__c)
                {

                    //if there are no groups, roles or territories then its visible
                    if (String.isEmpty(lv.Groups__c) 
                                && String.isEmpty(lv.Roles__c)
                                && String.isEmpty(lv.Roles_And_Subordinates__c)
                                && String.isEmpty(lv.Territories_And_Subordinates__c)
                                && String.isEmpty(lv.Territories__c)) 
                    {                                
                        visible.put(lv.Id, lv);
                        debug += 'Is Owner                 - false (' + lv.Label__c + ')\n';
                        debug += 'NO Group/Role/Territory Data (' + lv.Label__c + ')\n';
                    
                    //if there are groups, roles or territories then add to list views to check
                    } else {
                        debug += 'Is Owner                 - false (' + lv.Label__c + ')\n';
                        debug += 'HAS Group/Role/Territory Data (' + lv.Label__c + ')\n';
                        hasGroup.put(lv.Id, lv);
                        if (!String.isEmpty(lv.Groups__c))
                            allGroupNames.addAll(lv.Groups__c.split(','));
                    }
                }
            }

        }

        //if there are groups, roles or territories
        if (!hasGroup.isEmpty())
        {

            //this is used to initialize the groups. We need a better way
            Map<String, Group> allGroupsByName = HelperGroup.getGroupsByName(allGroupNames);

            for (List_View__c lv: hasGroup.values())
            {
                Set<String> groups = new Set<String>();
                //get list of groups that need to be checked for membership
                if (!String.isEmpty(lv.Groups__c))
                    groups.addAll(lv.Groups__c.split(','));
                debug += '\nList View Groups         - ' + groups + '\n';

                if (!groups.isEmpty())
                {
                    Boolean result = HelperGroup.isUserInGroups(groups, UserInfo.getUserId());
                    debug += 'Is In Group              - ' + result + '(' + lv.Label__c + ')\n';
                    if (result)
                        visible.put(lv.Id, lv);
    
                } else {
                    debug += 'Is In Group              - true (no groups)' + '(' + lv.Label__c + ')\n';
                }

                //==========================================================================

                Set<String> roles = new Set<String>();
                if (!String.isEmpty(lv.Roles__c))
                    roles.addAll(lv.Roles__c.split(','));
                debug += '\nList View Roles          - ' + roles + '\n';

                if (!roles.isEmpty())
                {
                    Boolean result = HelperRole.isUserInRoles(roles, false);
                    debug += 'Is In Roles              - ' + result + '(' + lv.Label__c + ')\n';
                    if (result)
                        visible.put(lv.Id, lv);
    
                } else {
                    debug += 'Is In Roles              - true (no roles)' + '(' + lv.Label__c + ')\n';
                }
    
                //==========================================================================

                Set<String> subRoles = new Set<String>();
                if (!String.isEmpty(lv.Roles_And_Subordinates__c))
                    subRoles.addAll(lv.Roles_And_Subordinates__c.split(','));
                debug += '\nList View Sub Roles      - ' + subRoles + '\n';
    
                if (!subRoles.isEmpty())
                {
                    Boolean result = HelperRole.isUserInRoles(subRoles, true);
                    debug += 'Is In Roles And Subs     - ' + result + '(' + lv.Label__c + ')\n';
                    if (result)
                        visible.put(lv.Id, lv);
    
                } else {
                    debug += 'Is In Roles And Subs     - true (no subroles)' + '(' + lv.Label__c + ')\n';
                }
            }
        }
        debug += '\n----- Visible List Views -----\n';
        for (List_View__c lv: visible.values())
            debug += lv.Label__c + ' - ' + lv.Id + '\n';
        debug += '---------------------------------------\n\n';

        System.debug(LoggingLevel.FINE, debug);
        ListViewErrorHelper.addLog('ListViewHelper(getVisibleListViews)', debug);
        

        return visible;
    }









    
    //================================================================================================================
    // INNER CLASSES
    //================================================================================================================


    public class ColumnSortData implements Comparable {

        public String fieldName;
        public Boolean sortDirection;
        public Integer sortIndex;

        public ColumnSortData()
        {

        }

        public ColumnSortData(String fieldName, Boolean sortDirection, Integer sortIndex)
        {
            this.fieldName     = fieldName;
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