/**
 * @author            : tom@ansleyllc.com
 * @last modified on  : 12-06-2021
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
 **/
global with sharing class ListViewHelper 
{
    
    public static final Id coreRTId = Schema.SObjectType.List_View__c.getRecordTypeInfosByDeveloperName().get('Core').getRecordTypeId();
    public static final Id customRTId = Schema.SObjectType.List_View__c.getRecordTypeInfosByDeveloperName().get('Custom').getRecordTypeId();
   
    public static final Set<String> POLYMORPHIC_FIELDS = new Set<String>{ 'WhatId', 'WhoId'};

    public static final String CORE_APEX_CLASS = 'ListViewCore';

    public static final String PROC_TYPE_CREATE = 'create';
    public static final String PROC_TYPE_UPDATE = 'update';
    
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

    public static final String PARAM_ADD_FIELDS   = 'AdditionalFields';

    public static final String SUBTYPE_MANUAL = 'Manual';
    public static final String SUBTYPE_TOOLING = 'Tooling';
    public static final String SUBTYPE_METADATA = 'Metadata';

    public static final String ID_TYPE_CORE = 'Core';
    public static final String ID_TYPE_SLV  = 'SLV';

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
        Type t = Type.forName(objectType);

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
        return getChangedListViews(null, null, lapsedMinutes);
    }

    /*
     * Method to return all CORE list views that have been altered by the running user
     * within the past 2 weeks.
     */
    public static Map<Id, ListView> getLastChangedListViewForUser(Id userId)
    {
        return getChangedListViews(1, userId, null);
    }

    private static Map<Id, ListView> getChangedListViews(Integer recLimit, Id modifiedById, Integer minutesBack)
    {
        Integer soqlLimit = 5000;
        if (recLimit != null)
            soqlLimit = recLimit;

        String soql = 'SELECT Id, ' + 
                             'Name, ' + 
                             'SObjectType, ' + 
                             'DeveloperName, ' + 
                             'LastModifiedById, ' +
                             'NamespacePrefix ' + 
                        'FROM ListView ' + 
                        'WHERE ';

        if (modifiedById != null)
            soql += 'LastModifiedById = \'' + modifiedById + '\' AND ';

        if (minutesBack != null)
            soql += 'LastModifiedDate > ' + System.now().addMinutes(minutesBack) + ' AND ';

        soql = soql.removeEnd('AND ');

        soql += 'ORDER BY LastModifiedDate DESC ';

        soql += 'LIMIT ' + soqlLimit;

        List<SObject> listViews = Database.query(soql);

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, listViews);
        Map<Id, ListView> listViewsById = new Map<Id, ListView>( (List<ListView>) dec.getRecords());
        return listViewsById;

    }

    private static List<ListView> getCoreListViews(Set<Id> lvIds)
    {
        //get the CORE list views.
        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Id, 
                        Name, 
                        SObjectType, 
                        DeveloperName, 
                        NamespacePrefix, 
                        CreatedById 
                 FROM ListView 
                 WHERE Id IN :lvIds]);
        
        return (List<ListView>) dec.getRecords();
    }

    private static List<ListView> getCoreListViews(String objectName)
    {
        //get the CORE list views.
        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Id, 
                        Name, 
                        SObjectType, 
                        DeveloperName, 
                        NamespacePrefix, 
                        CreatedById 
                 FROM ListView 
                 WHERE SObjectType = :objectName]);
        
        return (List<ListView>) dec.getRecords();
    }

    /*
     * Method to update list view describe details including the SOQL statement.
     * The object type of the list views to be updated is provided. This method should not be used 
     * for more than 50 list views. If more need to be updated then use the batch job.
     * HANDLES CORE ONLY
     */
    public static Boolean updateListViewsFromObj(String objectName)
    {
        List<ListView> coreListViews = getCoreListViews(objectName);

        if (coreListViews.size() > 50)
            return false;

        return updateListViews(coreListViews);
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

    /*
     * Method to update CUSTOM list views based on the CORE list views provided.
     * 
      ListViewHelper.updateListViews(ListViewHelper.ID_TYPE_SLV, new Set<Id>{'a003h00000BWOUhAAP'});
     * 
     * HANDLES CORE ONLY
     */
    public static Boolean updateListViews(List<ListView> listviews)
    {
        System.debug(LoggingLEvel.DEBUG, 'Starting updateListViews(' + listviews + ')');
        Map<String, List_View__c> updatedListViews = new Map<String, List_View__c>();
        Map<String, List_View_Config__c> simpliListViewConfigs = new Map<String, List_View_Config__c>(); 

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
                        String direction = 'true';
                        if (orderItemObj.get('sortDirection') == 'descending')
                            direction = 'false';

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
        System.debug(LoggingLevel.FINE, 'ListViewHelper.getListViewObjects(' + pageWideIncObjs + ', ' + pageWideExcObjs + ', ' + isInit + ')');
        String debug = '';
        Map<String, String> mappedListviewObjects = new Map<String, String>();
        Map<String, String> listViewObjects =  null;

        listViewObjects =  new Map<String, String>();

        String exclObjs = ListViewConfigHelper.getOrgWideConfigParam('ExcludedObjectTypes');
        debug += 'Org Wide Excluded Object Types - ' + exclObjs + '\n';
        Set<String> orgWideExcObjs = HelperString.getSetFromString(exclObjs, ',');
        debug += 'orgWideExcObjs size - ' + orgWideExcObjs.size() + '\n';

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

                System.debug(LoggingLevel.FINE, 'objAPIName - ' + objAPIName);

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
        System.debug(LoggingLevel.FINE, 'Called getListViewsByType(type ' + type);

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

    /*
     * Method to get all list views for a provided object.
     * The map is returned as follows - (API Name, List View)
     */
    public static Map<String, List_View__c> getListViewsByObject(String objAPIName)
    {

        System.debug(LoggingLevel.FINE, 'objAPIName - ' + objAPIName);

        //if we have a core list view object make sure that the user has access to the object itself if its
        if (HelperSchema.isObject(objAPIName) && !HelperSchema.checkObjectAccessible(objAPIName, false))
            throw new ListViewException('Object ' + objAPIName + ' is not accessible to the current user');

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
        System.debug(LoggingLevel.FINE, debug);

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
        if (HelperSchema.isValidSFDCFieldName(listview.Object_Name__c, 'IsDeleted'))
            selectFields.add('IsDeleted');

        selectStr = '';
        for (String field: selectFields)
        {
            field = HelperSchema.scrubFieldNameForSOQL(field); //remove weird stuff like toLabel() etc.
            selectStr += field + ', ';
        }
        selectStr = selectStr.removeEnd(', ');

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
            && lvConfigParams.get('AllRows') == 'true'                     //if AllRows = true
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
                scopeStr += 'USING SCOPE ' + listview.Filter_Scope__c;
            else
                scopeStr += 'USING SCOPE Everything';
        }

        //------------------------------------------------------
        // Put the query back together again
        //------------------------------------------------------
        query = 'SELECT ' + selectStr + ' FROM ' + objectName + ' ' + scopeStr + ' ' + whereStr + orderByStr + limitStr + allRowsStr;

        System.debug(LoggingLevel.FINE, 'Final SOQL - ' + query);
        ListViewErrorHelper.addLog('ListViewHelper(getListViewData)', query + '\n\n' + debug);

        //get rows of data from query
        List<SObject> objectRows = null;
        try {
            objectRows = Database.query(query);
        } catch (Exception e) {
            ListViewErrorHelper.createFutureUsageError('Exception during ListViewHelper.getListViewData(' + query + ')  ' + ListViewException.getExtendedString(e));
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
            ListViewErrorHelper.createFutureUsageError('Exception during ListViewHelper.getListViewData(' + soql + ')  ' + ListViewException.getExtendedString(e));
            throw new ListViewException('There was an error during data retrieval. Please try again or notify an administrator. (' + e.getMessage() + ')');
        }
        
        return objectRows;

    }
    
    /**
    * @description Convenience method which assumes the following - 
                   i.  This is not to retrieve an example.
                   ii. This does not have any paging requirements
    * @author tom@ansleyllc.com | 06-21-2021 
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
        String selectStr = soql.substringBeforeLast(' FROM ');
        System.debug(LoggingLevel.FINE, 'selectStr - ' + selectStr);
        String objectName = soql.substringAfterLast(' FROM ');
        if (objectName.contains(' '))
            objectName = objectName.substringBefore(' ');
        System.debug(LoggingLevel.FINE, 'objectName - ' + objectName);
        String whereStr = 'WHERE ' + soql.substringAfterLast(' WHERE ');
        if (whereStr == 'WHERE ') 
            whereStr = '';
        if (whereStr.containsIgnoreCase(' ORDER BY '))
            whereStr = whereStr.substringBefore(' ORDER BY ');
        System.debug(LoggingLevel.FINE, 'whereStr - ' + whereStr);
        String orderByStr = soql.substringAfterLast(' FROM ').substringAfterLast(' ORDER BY ').substringBeforeLast(' LIMIT ');
        System.debug(LoggingLevel.FINE, 'orderByStr - ' + orderByStr);
        String limitStr = '';
        if (soql.containsIgnoreCase(' LIMIT '))
            limitStr = soql.substring(soql.lastIndexOf('LIMIT'));
        System.debug(LoggingLevel.FINE, 'limitStr - ' + limitStr);

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
        System.debug(LoggingLevel.FINE, 'LIMIT STR - ' + limitStr);

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
        // Handle the USING SCOPE statement
        //------------------------------------------------------
        String scopeStr = 'USING SCOPE ';
        if (!String.isEmpty(lvConfig?.getListView().Filter_Scope__c))
            scopeStr += lvConfig.getListView().Filter_Scope__c;
        else
            scopeStr += 'Everything';

        //------------------------------------------------------
        // Put the query back together again
        //------------------------------------------------------
        soql = selectStr + ' FROM ' + objectName + ' ' + scopeStr + ' ' + whereStr + orderByStr + limitStr + allRowsStr;

        System.debug(LoggingLevel.FINE, 'Final SOQL - ' + soql);

        return soql;
    }

    public static List<List_View_Action__c> insertCoreActions()
    {
        List<List_View_Action__c> actions = new List<List_View_Action__c>();

        List_View_Action__c orgNewAction = new List_View_Action__c();
        orgNewAction.Apex_Class_Name__c  = 'ListViewActionNull';
        orgNewAction.Label__c            = 'New';
        orgNewAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		orgNewAction.Permissions__c      = ListViewActionHelper.PERM_CREATE;
        orgNewAction.Is_Active__c        = true;

        actions.add(orgNewAction);

        List_View_Action__c orgCloneAction = new List_View_Action__c();
        orgCloneAction.Apex_Class_Name__c  = 'ListViewActionNull';
        orgCloneAction.Label__c            = 'Clone';
        orgCloneAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		orgCloneAction.Permissions__c      = ListViewActionHelper.PERM_CREATE;
        orgCloneAction.Is_Active__c        = true;

        actions.add(orgCloneAction);

        List_View_Action__c orgEditAction = new List_View_Action__c();
        orgEditAction.Apex_Class_Name__c  = 'ListViewActionNull';
        orgEditAction.Label__c            = 'Edit';
        orgEditAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		orgEditAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;
        orgEditAction.Is_Active__c        = true;

        actions.add(orgEditAction);

        List_View_Action__c orgEditAllAction = new List_View_Action__c();
        orgEditAllAction.Apex_Class_Name__c  = 'ListViewActionNull';
        orgEditAllAction.Label__c            = 'Edit All';
        orgEditAllAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		orgEditAllAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;
        orgEditAllAction.Is_Active__c        = true;

        actions.add(orgEditAllAction);

        List_View_Action__c orgDeleteAction = new List_View_Action__c();
        orgDeleteAction.Apex_Class_Name__c  = 'ListViewActionDelete';
        orgDeleteAction.Label__c            = 'Delete';
        orgDeleteAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		orgDeleteAction.Permissions__c      = ListViewActionHelper.PERM_DELETE;
        orgDeleteAction.Is_Active__c        = true;

        actions.add(orgDeleteAction);

        List_View_Action__c acctUpdateAction = new List_View_Action__c();
        acctUpdateAction.Apex_Class_Name__c  = 'ListViewActionUpdate';
        acctUpdateAction.Label__c            = 'Update';
        acctUpdateAction.Object_Type__c      = 'Account';
        acctUpdateAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		acctUpdateAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;
        acctUpdateAction.Is_Active__c        = true;

        actions.add(acctUpdateAction);

        List_View_Action__c oppsCloseUpdateAction = new List_View_Action__c();
        oppsCloseUpdateAction.Apex_Class_Name__c  = 'ListViewActionOppsClose';
        oppsCloseUpdateAction.Label__c            = 'Set Close Lost';
        oppsCloseUpdateAction.Object_Type__c      = 'Opportunity';
        oppsCloseUpdateAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		oppsCloseUpdateAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;
        oppsCloseUpdateAction.Is_Active__c        = true;

        actions.add(oppsCloseUpdateAction);

        List_View_Action__c hyperAction = new List_View_Action__c();
        hyperAction.Apex_Class_Name__c  = 'ListViewActionNull';
        hyperAction.Label__c            = 'Go To A Cool App';
        hyperAction.Object_Type__c      = 'simpli_lv__List_View__c';
        hyperAction.Is_Hyperlink__c     = true;
        hyperAction.RecordTypeId        = ListViewActionHelper.coreRTId;
        hyperAction.Is_Active__c        = true;

        actions.add(hyperAction);

        List_View_Action__c mailAction = new List_View_Action__c();
        mailAction.Apex_Class_Name__c  = 'ListViewActionEmail';
        mailAction.Label__c            = 'Send Email';
        mailAction.Object_Type__c      = 'Contact';
        mailAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		mailAction.Permissions__c      = ListViewActionHelper.PERM_READ;
        mailAction.Is_Active__c        = true;

        actions.add(mailAction);

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

    public static List<List_View_Config__c> insertCoreListViewConfig()
    {
        List<List_View_Config__c> configs = new List<List_View_Config__c>();

        List_View_Config__c config = new List_View_Config__c();
        config.Name                = 'simpli_lv__PlatinumandGoldSLACustomers';
        config.List_View_Label__c  = 'Platinum And Gold SLA Customers';
        config.List_View_Object__c = 'Account';
        config.Primary_Key__c      = config.List_View_Object__c + ':' + config.Name;
        configs.add(config);

        List_View_Config__c config2 = new List_View_Config__c();
        config2.Name                = 'All';
        config2.List_View_Object__c = 'All';
        config2.List_View_Label__c   = 'Org Wide Configuration';
        config2.Primary_Key__c      = config2.List_View_Object__c + ':' + config2.Name;
        configs.add(config2);

        List_View_Config__c config3 = new List_View_Config__c();
        config3.Name                = 'simpli_lv__AllAccounts';
        config3.List_View_Object__c = 'Account';
        config3.List_View_Label__c   = 'All Accounts';
        config3.Primary_Key__c      = config3.List_View_Object__c + ':' + config3.Name;
        configs.add(config3);

        configs = HelperDatabase.insertRecords(configs);
        Map<String, SObject> configsByName = HelperCollection.getStringMappedObjects(configs, 'Name');
        config = (simpli_lv__List_View_Config__c) configsByName.get('simpli_lv__PlatinumandGoldSLACustomers');
        config2 = (simpli_lv__List_View_Config__c) configsByName.get('All');
        config3 = (simpli_lv__List_View_Config__c) configsByName.get('simpli_lv__AllAccounts');

        List<List_View_Config_Parameter__c> params2 = new List<List_View_Config_Parameter__c>();
      
        List_View_Config_Parameter__c param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config.Id;
        param2.Parameter_Name__c   = PARAM_ADD_FIELDS;
        param2.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param2.Parameter_Value__c  = 'Type, AnnualRevenue,CreatedBy.Name,Owner.Profile.Name';
        param2.Parameter_Label__c  = 'Additional Fields';
        params2.add(param2);
        
        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config.Id;
        param2.Parameter_Name__c   = 'TotalColumns';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
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
        param2.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param2.Parameter_Value__c  = '';
        param2.Parameter_Label__c  = 'List View Objects';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'IncludedObjectTypes';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param2.Parameter_Value__c  = '';
        param2.Parameter_Label__c  = 'Included Object Types';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'ExcludedObjectTypes';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param2.Parameter_Value__c  = 'FlowInterview,CollaborationGroup,Idea,OperatingHours,ServiceAppointment,WorkType,Solution';
        param2.Parameter_Label__c  = 'Excluded Object Types';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplayActionsButton';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Actions Button';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'AllowAdmin';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Admin Button';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplayListViewReprocessingButton';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display List View Reprocessing Button';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplayOriginalListViewButton';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Original List View Button';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplaySelectedCount';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Selected Count';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'AllowDataExport';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Allow Data Export';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'AllowAutomaticDataRefresh';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Allow Automatic Data Refresh';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplayRowCount';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Row Count';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'MaxRowsDisplayed';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
        param2.Parameter_Value__c  = '2500';
        param2.Parameter_Label__c  = 'Max Rows Displayed';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'QueryPagingSize';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
        param2.Parameter_Value__c  = '250';
        param2.Parameter_Label__c  = 'Query Paging Size';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'IsInitialized';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'false';
        param2.Parameter_Label__c  = 'Is Initialized';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'AllowInlineEditing';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Allow Inline Editing';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplayTextSearch';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Text Search';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'DisplayRecordPopovers';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'true';
        param2.Parameter_Label__c  = 'Display Record Popovers';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'ExcludedRecordPopoverTypes';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param2.Parameter_Value__c  = '';
        param2.Parameter_Label__c  = 'Excluded Record Popover Types';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'Debug';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
        param2.Parameter_Value__c  = 'false';
        param2.Parameter_Label__c  = 'Debug';
        params2.add(param2);

        param2 = new List_View_Config_Parameter__c();
        param2.List_View_Config__c = config2.Id;
        param2.Parameter_Name__c   = 'RefreshJob';
        param2.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
        param2.Parameter_Value__c  = HelperScheduler.NOT_SCHEDULED;
        param2.Parameter_Label__c  = 'Scheduled Refresh Job';
        params2.add(param2);


        //---------------------------------------
        // 
        //---------------------------------------
        param2 = new List_View_Config_Parameter__c();
		param2.Parameter_Name__c = PARAM_ADD_FIELDS;
		param2.Parameter_Type__c = ListViewHelper.TYPE_STRING;
		param2.Parameter_Value__c = 'CreatedBy.Name, Owner.Profile.Name, AnnualRevenue';
		param2.List_View_Config__c = config3.Id;
        param2.Parameter_Label__c  = 'Additional Fields';
        params2.add(param2);
        
        param2 = new List_View_Config_Parameter__c();
		param2.Parameter_Name__c = 'TotalColumns';
		param2.Parameter_Type__c = ListViewHelper.TYPE_STRING;
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
        
        params2 = HelperDatabase.insertRecords(params2);

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

        lv                          = new List_View__c();
        lv.Custom_Apex_Class__c     = 'ListViewCustomManual';
        lv.Label__c                 = 'Campaign Members';
        lv.Core_ListView_Columns__c = '[{"fieldNameOrPath":"Name","type":"string","label":"Name"},  {"fieldNameOrPath":"Status","type":"string","label":"Status"},{"fieldNameOrPath":"Type","type":"string","label":"Type"},{"fieldNameOrPath":"Phone","type":"string","label":"Phone"}]';
        lv.Core_ListView_Query__c   = 'SELECT Name, Status, Type, Phone FROM CampaignMember';
        lv.Object_Name__c           = 'CampaignMember';
        lv.RecordTypeId             = ListViewHelper.customRTId;
        lv.Subtype__c               = 'Manual';

        listViews.add(lv);

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

        return listViews;
    }

    global static void insertCoreConfiguration()
    {
        insertCoreActions();

        insertCoreListViewConfig();

        insertCoreListViews();
    }

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