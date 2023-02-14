/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 10-16-2022
 * @last modified by  : 
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   08-04-2020   tom@ansleyllc.com   Initial Version
 * 2.0   06-18-2021   tom@ansleyllc.com   Added offset to allow for larger datasets
 * 3.0   06-18-2021   tom@ansleyllc.com   Added logic when list views are not initialized
 * 4.0   07-30-2021   tom@ansleyllc.com   Added updateRecords() method
 * 5.0   08-16-2021   tom@ansleyllc.com   Updated getListViewsActions() and added permission check for each action before display
 * 6.0   08-20-2021   tom@ansleyllc.com   renamed getListViewsActions() to getListViewActions()
 * 7.0   08-25-2021   tom@ansleyllc.com   renamed getListViewColumnLabels() to getListViewColumns()
 * 8.0   12-15-2021   tom@ansleyllc.com   Pulled out creating types due to different methods for handling types with package names etc.
 **/
public without sharing class ListViewController
{

    public static final String SUCCESS = 'success';
    public static final String FAILED = 'failed';

    @AuraEnabled
    public static Boolean hasModifyAll()
    {
        ListViewErrorHelper.processLogs(true);

        return HelperProfile.hasModifyAll();
    }

    /*
     * Method to retrieve the progress of the initialization batch process
     */
    @AuraEnabled
    public static String getListViewInitProgress(String batchId)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewInitProgress(' + batchId + ')');
        String result = '0';
        String status = '';
        
        if (batchId != '')
        {
            //Query the Batch apex jobs            
            List<AsyncApexJob> jobs = HelperScheduler.getCurrentlyRunningJobs();

            if (jobs.size() == 0) { 
                
                result = '0';
                status = 'Waiting';

                if(getIsInitialized())
                {
                    status = 'Completed';
                    result = '100';
                }

            } else if (jobs[0].TotalJobItems == 0) {
            
                result = '0';
                status = jobs[0].Status + ' ' + jobs[0].ApexClass.Name;

            } else { 

                Decimal percentComp = (Decimal.valueOf(jobs[0].JobItemsProcessed)/Decimal.valueOf(jobs[0].TotalJobItems)) * 100;
                if (percentComp == 100) 
                    percentComp = 99; //make it 99 if done as 100 is considered completely finished!
                result = String.valueOf(percentComp);
                status = jobs[0].Status + ' ' + jobs[0].ApexClass.Name;
                
            }
        } else {
            result = '-1';
        }

        System.debug(LoggingLevel.DEBUG, 'Finishing ListViewController.getListViewInitProgress with result - ' + result + ':' + status);
        
        ListViewErrorHelper.processLogs(true);

        return String.valueOf(result) + ':' + status;
    }

    /*
     * Method which returns list of objects names and API names in the system
     */
    @AuraEnabled(cacheable=true)
    public static List<SelectOption> getListViewObjects(String includedObjects, String excludedObjects)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewObjects(' + includedObjects + ', ' + excludedObjects + ')');
        List<SelectOption> configListOptions = new List<SelectOption>();

        Set<String> excObjs = HelperString.getSetFromString(excludedObjects, ',');
        Set<String> incObjs = HelperString.getSetFromString(includedObjects, ',');

        Map<String, String> listviewObjects = ListViewHelper.getListViewObjects(incObjs, excObjs);

        String debug = '\n\n================ FINAL OBJECT LIST ================\n';
        for (String apiName: listviewObjects.keySet())
        {
            debug += apiName + ' - ' + listviewObjects.get(apiName) + '\n';
            configListOptions.add(new SelectOption(apiName, listviewObjects.get(apiName)));         
        }
        debug += '===================================================\n';
        System.debug(LoggingLevel.DEBUG, debug);

        configListOptions.sort();

        ListViewErrorHelper.processLogs(true);

        return configListOptions;
    }

    @AuraEnabled
    public static Boolean getIsInitialized()
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getIsInitialized()');

        Boolean isInitialized = false;
        try {
            isInitialized = Boolean.valueOf(ListViewConfigHelper.getOrgWideConfigParam('IsInitialized'));
        } catch(Exception e) {
            //no global config!
        }
        ListViewErrorHelper.processLogs(true);

        return isInitialized;
    }

    @AuraEnabled
    public static List<SelectOption> getObjectListViews(String objectName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getObjectListViews(' + objectName + ')');

        Map<String, List_View__c> listviews = ListViewHelper.getListViewsByObject(objectName);

        List<SelectOption> configListOptions = new List<SelectOption>();

        for (List_View__c listview : listviews.values())
        {
            configListOptions.add(new SelectOption(listview.API_Name__c, listview.Label__c));         
        }

        configListOptions.sort();

        ListViewErrorHelper.processLogs(true);

        return configListOptions;
    }

    @AuraEnabled
    public static ListViewAbstract.ListViewConfigWrapper getListViewConfig(String objectName, String listViewName, String listViewMode)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewConfig(' + objectName + ', ' + listViewName + ', ' + listViewMode + ')');

        ListViewAbstract.ListViewConfigWrapper lvConfigWrapper = new ListViewAbstract.ListViewConfigWrapper(objectName, listViewName, listViewMode);

        if (objectName == null || listViewName == null)
            return lvConfigWrapper;


        Map<Id, List_View__c> listViews = ListViewHelper.getListViews(objectName, listViewName);
        if (listViews.isEmpty())
            throw new ListViewException('The list view configuration can not be found for object ' + objectName + ' and list view name - ' + listViewName + ')');

        List_View__c listview = listViews.values()[0];

        String objType = null;
        if (listView.RecordTypeId == null || listView.RecordTypeId == ListViewHelper.coreRTId)
            objType = ListViewHelper.CORE_APEX_CLASS;
        else
            objType = listView.Custom_Apex_Class__c;

        //get an apex Type of the object type
        Type t = HelperSchema.getClassType(objType);

        //create a new instance
        ListViewAbstract lvLogic = (ListViewAbstract) t.newInstance();
        lvLogic.listviewMode = listViewMode;

        //set all request information into the apex processing class.
        lvlogic.setRequestData(listview);

        lvConfigWrapper = lvlogic.lvConfig;

        ListViewErrorHelper.addLog('ListViewController(getListViewConfig)', lvConfigWrapper.getDebugString());

        ListViewErrorHelper.processLogs(true);

        return lvConfigWrapper;
    }

    /**
    * @description Method which gets the users SORT configuration for the provided COMPONENT. The method manually creates
                   the JSON request as it makes it easier on the front end to handle. Here is an example JSON response - 
                   {"listviews": [{"name": "Account:Simpli_LV_Acct_1","fields": [{"sortIndex": "0", "fieldName": "Name", "sortDirection": "true"},{"sortIndex": "1", "fieldName": "BillingState", "sortDirection": "false"}]}, {"name": "Account:PlatinumandGoldSLACustomers","fields": [{"sortIndex": "0", "fieldName": "Name", "sortDirection": "true"},{"sortIndex": "1", "fieldName": "BillingState", "sortDirection": "false"},{"sortIndex": "2", "fieldName": "Id", "sortDirection": "false"}]}]}

    * @author tom@ansleyllc.com | 10-10-2020 
    * @param compName the component name which is the name of the Lightning component that calls this method.
    * @return Map<String, String> 
    **/
    @AuraEnabled
    public static String getUserSortConfigs(String compName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getUserSortConfigs(' + compName + ')');

        String sortConfigJSON = '{"listviews": [';
        //String sortJSON = '{';
        //get the users component config
        List<List_View_User_Config__c> configs = ListViewUserConfigHelper.getCurrentUserCompSortConfigs(compName);
        for (List_View_User_Config__c config: configs)
        {
            sortConfigJSON += '{"name": "' + config.Name__c.removeStart('sortOrder:') + '","fields": [';

            List<String> sortFields = config.Value__c.split(';');

            for (String sortField: sortFields)
            {
                List<String> sortParts = sortField.split(':');
                sortConfigJSON += '{"sortIndex": "' + sortParts[0] + '", "fieldName": "' + sortParts[2] + '", "sortDirection": "' + sortParts[1] + '"},';
            }

            sortConfigJSON = sortConfigJSON.removeEnd(',') + ']},';

        }
        sortConfigJSON = sortConfigJSON.removeEnd(',') + ']}';

        ListViewErrorHelper.processLogs(true);

        return sortConfigJSON;
    }

    @AuraEnabled
    public static String getListViewConfigParameter(String objectName, String listViewName, String paramName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewConfigParameter(' + objectName + ', ' + listViewName + ',' + paramName + ')');
        
        String paramValue = ListViewConfigHelper.getListViewConfigParameter(objectName, listViewName, paramName);
        
        ListViewErrorHelper.processLogs(true);

        return paramValue;
    }

    /**
    * @description Method which gets the users configuration for the provided COMPONENT.
    *              Note that this method also gets the org wide defaults as it needs to layer those defaults on top of the user config
    * @author tom@ansleyllc.com | 10-10-2020 
    * @param compName the component name which is the name of the Lightning component that calls this method.
    * @return Map<String, String> 
    **/
    @AuraEnabled
    public static Map<String, String> getComponentConfig(String compName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getComponentConfig(' + compName + ')');
        Map<String, String> userConfigs = ListViewUserConfigHelper.getComponentConfig(compName);
        
        ListViewErrorHelper.processLogs(true);

        return userConfigs;
    }

    @AuraEnabled
    public static String updateUserConfig(String compName, String configName, String value)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateUserConfig(' + compName + ', ' + configName + ',' + value + ')');
        try {
            ListViewUserConfigHelper.updateCurrentUserConfigValue(compName, configName, value);
        } catch (Exception e) {
            String message = 'Exception during ListViewController.updateUserConfig(' + compName + ',' + configName + ',' + value + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
            return 'There was an error during user configuration update';
        }

        ListViewErrorHelper.processLogs(true);

        return SUCCESS;
    }

    /*
     * Method to update a specific list view for a user with given column width data.
     */
    @AuraEnabled
    public static String updateUserConfigListViewWidth(String compName, String configName, String columnIndex, String width)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateUserConfigListViewWidth(' + compName + ', ' + configName + ',' + columnIndex + ',' + width + ')');
        try {

            //get existing config if it exists.
            List_View_User_Config__c widthConfig = ListViewUserConfigHelper.getCurrentUserConfigByName(compName, configName); 

            String widthStr = '';

            //if config exists then UPDATE
            if (widthConfig != null)
            {
                //list width config example - 1:25;2:25;3:120;4:80
                widthStr = widthConfig.Value__c;

                //break up string into columns
                List<String> columnWidthsStr = widthStr.split(';');
                Map<Integer, String> widthsByIndex = new Map<Integer, String>();
                Boolean hasValue = false;
                for (String columnWidthStr: columnWidthsStr)
                {
                    //update individual column width data if it exists
                    List<String> values = columnWidthStr.split(':');
                    if (values[0] == columnIndex) //value[0] = column index
                    {
                        hasValue = true;
                        widthsByIndex.put(Integer.valueOf(values[0]), width);
                    } else {
                        widthsByIndex.put(Integer.valueOf(values[0]), values[1]);
                    }
                }

                //add column and width if the column index doesn't already exist
                if (!hasValue)
                    widthsByIndex.put(Integer.valueOf(columnIndex), width);

                //go through map and sort
                List<Integer> columnIndexes = new List<Integer>(widthsByIndex.keySet());
                columnIndexes.sort();

                //go through map and recreate string
                widthStr = '';
                for (Integer tmpColumnIndex: columnIndexes)
                {
                    String tmpWidth = widthsByIndex.get(tmpColumnIndex);

                    widthStr += tmpColumnIndex + ':' + tmpWidth + ';';
                }
                
            //else INSERT new data
            } else {
                widthStr = columnIndex + ':' + width;
            }

            ListViewUserConfigHelper.updateCurrentUserConfigValue(compName, configName, widthStr);

        } catch (Exception e) {
            String message = 'Exception during ListViewController.updateUserConfigListViewWidth(' + compName + ',' + configName + ',' + columnIndex + ',' + width + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
            return 'There was an error during user configuration update';
        }

        ListViewErrorHelper.processLogs(true);

        return SUCCESS;
    }

    @AuraEnabled
    public static String updateObjectListViews(String objectType)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateObjectListViews(' + objectType + ')');
        //update the list view
        Boolean result = ListViewHelper.updateListViewsFromObj(objectType);

        //remove cache so that list views are refetched
        CacheHelper.clearCache(UserInfo.getUserId().removeStart('005'));

        ListViewErrorHelper.processLogs(true);

        return SUCCESS;
    }

    @AuraEnabled
    public static String updateSingleListView(String objectType, String listViewName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateSingleListView(' + objectType + ', ' + listViewName + ')');
        //get the listviews with object and name
        Map<Id, List_View__c> listviews = ListViewHelper.getListViews(objectType, listViewName);

        //if no listviews return failed
        if (listviews.size() == 0) return FAILED;

        //get the list views Id
        Set<Id> lvId = new Set<Id>();
        lvId.add(listviews.values()[0].Id);

        //update the list view
        System.debug(LoggingLevel.FINE, 'A - ' + HelperLimits.getLimitsString());
        Boolean result = ListViewHelper.updateListViewsFromSLVIds(lvId);

        //remove cache so that list views are refetched
        CacheHelper.clearCache(UserInfo.getUserId().removeStart('005'));

        ListViewErrorHelper.processLogs(true);

        return SUCCESS;
    }

	@AuraEnabled
	public static String updateChangedListViews()
	{
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateChangedListViews()');

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

        ListViewErrorHelper.processLogs(true);

        return SUCCESS;
	}

	@AuraEnabled
	public static String updateAllListViews()
	{
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateAllListViews()');

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

        ListViewErrorHelper.processLogs(true);

        return jobId;
	}

    @AuraEnabled(cacheable=true)
    public static List<ListViewAbstract.ActionWrapper> getListViewActions(String objectType, String listViewName, String componentName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewActions(' + objectType + ', ' + listViewName + ', ' + componentName + ')');
        
        List<ListViewAbstract.ActionWrapper> actions = ListViewActionHelper.getListViewActions(objectType, listViewName, componentName);

        ListViewErrorHelper.processLogs(true);

        return actions;
    }

    @AuraEnabled
    public static ListViewAbstract.ActionWrapper getListViewActionAndData(String actionName, String dataIds)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewAction(' + actionName + ', ' + dataIds + ')');

        ListViewAbstract.ActionWrapper wrapper = getListViewAction(actionName);

        try {

            //if we are provided record Ids then get the record and try to set the initial values.
            if (dataIds != null){
                List<Object> listIds = (List<Object>) JSON.deserializeUntyped(dataIds);
                if (listIds.size() == 1)
                {
                    //1. get the object API Name
                    String objAPIName = wrapper.getObjectType();

                    //2. get the single record Id
                    String recordId = (String) listIds[0];

                    //3. Get the list of fields
                    List<String> fieldAPINames = new List<String>();
                    for (ListViewAbstract.ActionParameterWrapper param: wrapper.getDisplayParameters())
                    {
                        fieldAPINames.add(param.getAPIName());
                    }

                    //4. Get record
                    SObject record = HelperDatabase.query(objAPIName, fieldAPINames, recordId);

                    //5. Set the record values into the action wrapper
                    if (record != null)
                    {
                        for (ListViewAbstract.ActionParameterWrapper param: wrapper.getDisplayParameters())
                        {
                            param.setDefaultValue(record.get(param.getAPIName()));
                        }
                    }
                }
            }
        } catch (Exception e) {
            String message = 'Exception during ListViewController.getListViewAction(' + actionName + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
        }

        ListViewErrorHelper.processLogs(true);

        return wrapper;
    }

    @AuraEnabled
    public static ListViewAbstract.ActionWrapper getListViewAction(String actionName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewAction(' + actionName + ')');

        ListViewAbstract.ActionWrapper wrapper = null;
        if (!String.isEmpty(actionName))
        {

            List_View_Action__c action = null;
    
            try {
                action = ListViewActionHelper.getListViewActionByKey(actionName);
                wrapper = new ListViewAbstract.ActionWrapper(action);

            } catch (Exception e) {
                String message = 'Exception during ListViewController.getListViewAction(' + actionName + ')  ' + ListViewException.getExtendedString(e);
                ListViewErrorHelper.createFutureUsageError(message); 
            }
        }

        ListViewErrorHelper.processLogs(true);

        return wrapper;
    }

    /*
     * Method which determines whether a list view data request is valid or not.
     */
    @AuraEnabled
    public static String isValidListViewDataRequest(String objectName, String joinFieldName, String joinData)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.isValidListViewDataRequest(' + objectName + ', ' + joinFieldName + ',' + joinData + ')');
        String result = SUCCESS;

        //if we have join information then get the record Ids
        Set<String> joinRecordIds = null;
        if (joinFieldName != '' && joinData != '')
        {
            //check that we can actually act on the join data as it could be for another component.
            if (HelperSchema.isValidSFDCFieldName(objectName, joinFieldName))
            {
                Map<String, Object> joinDataMap = (Map<String, Object>) JSON.deserializeUntyped(joinData);
                joinRecordIds = HelperString.getSetFromString(((String) joinDataMap.get('recordIds')), ',');
                joinRecordIds.remove(null); //make sure we remove any nulls
                joinRecordIds.remove('');

                //if we have any Ids we need to check that the Ids match the field object type
                //unless its a polymorphic field, then we just have to go with it!!
                if (joinRecordIds.size() > 0
                    && !ListViewHelper.POLYMORPHIC_FIELDS.contains(joinFieldName)
                    && !joinFieldName.contains('.'))
                {
                    //get the type of the join field lookup object.
                    String objType = HelperSchema.getObjectTypeForField(objectName, joinFieldName);

                    String objType2 = '';
                    //this is crazy. In order to get any one value from a set
                    //I have to iterate over it and break at the first value!!
                    for (String recordId: joinRecordIds)
                    {
                        objType2 = HelperSchema.getObjectTypeFromId(recordId);
                        break;
                    }

                    if (objType != objType2)
                        result = 'failure';
                }
            }
        }
        
        System.debug(LoggingLevel.DEBUG, 'Leaving isValidListViewDataRequest - ' + result);
        ListViewErrorHelper.processLogs(true);

        return result;
    }

    @AuraEnabled
    public static ListViewAbstract.RowsWrapper getListViewDataShell(String compType, String objectName, String listViewName, String joinFieldName, String joinData)
    {
        ListViewAbstract.RowsWrapper rows = getListViewData(null, compType, objectName, listViewName, null, joinFieldName, joinData, -1, true, '');
        
        //clone the only returned row and change its rowId
        ListViewAbstract.RowWrapper rowWrapper = rows.getRows()[0];
        rowWrapper.rowId = '1';
        rowWrapper.sfdcId = '1';

        String debug = '\n\n------------------------------------\n';
        for(ListViewAbstract.FieldWrapper field: rowWrapper.getFields())
        {
            field.setFieldObj(null);
            field.setObjValueId(null);
            field.setValue(null);
            debug += field.getName() + ' - ' + field.getIsEditable() + ' - ' + field.getType() + '\n';
        }
        debug += '------------------------------------\n';
        System.debug(LoggingLevel.DEBUG, debug);

        Integer rowCount = Integer.valueOf(ListViewConfigHelper.getOrgWideConfigParam('MassCreateRowCount', '10'));


        for (Integer count = 2; count < rowCount + 1; count++)
        {
            ListViewAbstract.RowWrapper row = rowWrapper.cloneWrapper(false);
            row.rowId = String.valueOf(count);
            rows.addRow(row);
        }
        return rows;
    }

    @AuraEnabled
    public static ListViewAbstract.RowsWrapper getListViewData(String pageName, String compType, String objectName, String listViewName, String sortData, String joinFieldName, String joinData, Integer offset, String textSearchStr)
    {
        return getListViewData(pageName, compType, objectName, listViewName, sortData, joinFieldName, joinData, offset, false, textSearchStr);
    }

    /**
    * @description Method to retrieve list view data based on user provided criteria.
    * @author tom@ansleyllc.com | 06-28-2021 
    * @param pageName the name of the lightning page that the list is being displayed on. This is used for list view config retrieval
    * @param compType the type of the component the data is being retrieved for.
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
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewData(' + pageName + ', ' + objectName + ', ' + listViewName + ',' + sortData + ',' + joinFieldName + ',' + joinData + ', ' + isShell + ', ' + textSearchStr + ')');
        
        ListViewAbstract.RowsWrapper rowData                   = null;

        //------------------------------------------------------------------------------------------
        //JOIN INFORMATION
        //------------------------------------------------------------------------------------------
        Set<String> joinRecordIds = null;
        if (!String.isEmpty(joinFieldName) && !String.isEmpty(joinData))
        {
            System.debug(LoggingLevel.DEBUG, 'We have join data and a join field');
            //check that we can actually act on the join data as it could be for another component.
            if (HelperSchema.isValidSFDCFieldName(objectName, joinFieldName))
            {
                Map<String, Object> joinDataMap = (Map<String, Object>) JSON.deserializeUntyped(joinData);
                joinRecordIds = HelperString.getSetFromString(((String) joinDataMap.get('recordIds')), ',');
                joinRecordIds.remove(null); //make sure we remove any nulls
                joinRecordIds.remove('');

                //if we have any Ids we need to check that the Ids match the field object type
                //unless its a polymorphic field!
                if (joinRecordIds.size() > 0
                    && !ListViewHelper.POLYMORPHIC_FIELDS.contains(joinFieldName)
                    && !joinFieldName.contains('.'))
                {
                    System.debug(LoggingLevel.DEBUG, 'joinRecordIds != 0, joinFieldName is NOT polymorphic, joinFieldName != contain "."');

                    //get the type of the join field lookup object.
                    String objType = HelperSchema.getObjectTypeForField(objectName, joinFieldName);

                    String objType2 = '';

                    //this is crazy. In order to get any one value from a set
                    //I have to iterate over it and break at the first value!!
                    for (String recordId: joinRecordIds)
                    {
                        objType2 = HelperSchema.getObjectTypeFromId(recordId);
                        break;
                    }
                    System.debug(LoggingLevel.DEBUG, 'First object type - ' + objType);
                    System.debug(LoggingLevel.DEBUG, 'Second object type - ' + objType2);

                    if (objType != objType2
                        && !ListViewHelper.POLYMORPHIC_FIELDS.contains(joinFieldName)) //if we have join data that doesn't match return an empty shell. This can happen if we have multiple components that all have different join id types
                    {      
                        rowData = getListViewData(pageName, compType, objectName, listViewName, sortData, joinFieldName, '{"recordIds":""}', offset, true, '');
                        rowData.clearRows();
                        return rowData;
                    } else {
                        System.debug(LoggingLevel.DEBUG, 'Object types do not match');
                    }
                } else {
                    System.debug(LoggingLevel.DEBUG, 'joinRecordIds.size() - ' + joinRecordIds.size());
                    System.debug(LoggingLevel.DEBUG, '!ListViewHelper.POLYMORPHIC_FIELDS.contains(joinFieldName) - ' + !ListViewHelper.POLYMORPHIC_FIELDS.contains(joinFieldName));
                    System.debug(LoggingLevel.DEBUG, '!joinFieldName.contains(\'.\') - ' + !joinFieldName.contains('.'));

                }
            } else {
                System.debug(LoggingLevel.DEBUG, 'joinFieldName is not valid');
            }
        }

        //------------------------------------------------------------------------------------------
        //LIST VIEW METADATA
        //------------------------------------------------------------------------------------------
        Map<Id, List_View__c> listviews = ListViewHelper.getListViews(objectName, listViewName);

        if (listviews.size() > 0) 
        {

            List_View__c listview = listviews.values()[0];

            //------------------------------------------------------------------------------------------
            //SORTING INFORMATION
            //------------------------------------------------------------------------------------------
            List<ListViewHelper.ColumnSortData> columnSortData = new List<ListViewHelper.ColumnSortData>();
            String sortStr = '';
            Boolean isDefaultSort = false;

            //if sorting is provided from the UI then use it first
            if (sortData != null && sortData.length() > 2) //the value when empty can be "[]"
            {
                //below is a bit of a mess at the moment because Map objects cannot be stringified
                //in Javascript. So we end up with a list of list!!
                List<Object> sortValues = (List<Object>) JSON.deserializeUntyped(sortData);
                System.debug(LoggingLevel.DEBUG, 'SORT VALUES - ' + sortValues);
                for (Object values: sortValues)
                {
                    List<Object> sortVals = (List<Object>) values;
                    List<Object> tst = (List<Object>) sortVals[1];

                    ListViewHelper.ColumnSortData columnData = new ListViewHelper.ColumnSortData();
                    columnData.sortIndex     = (Integer) tst[0];
                    columnData.fieldName     = (String) tst[1];
                    columnData.sortDirection = (Boolean) tst[2];

                    columnSortData.add(columnData);
                    sortStr += columnData.getUserConfigString() + ';';
                }

                columnSortData.sort();
                sortStr = sortStr.removeEnd(';');

            //if no sort order provided from UI then check if there is a default sort order
            } else if (!String.isEmpty(listview.Default_Sort_Order__c))
            {
                List<String> sortValues = listview.Default_Sort_Order__c.split(';');
                System.debug(LoggingLevel.DEBUG, 'SORT VALUES 1 - ' + sortValues);
                for (String values: sortValues)
                {
                    ListViewHelper.ColumnSortData columnData = new ListViewHelper.ColumnSortData();
                    columnData.sortIndex     = Integer.valueOf(values.split(':')[0]);
                    columnData.fieldName     = values.split(':')[2];
                    columnData.sortDirection = Boolean.valueOf(values.split(':')[1]);

                    columnSortData.add(columnData);
                    sortStr += columnData.getUserConfigString() + ';';
                }

                columnSortData.sort();
                isDefaultSort = true;
            }

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
            ListViewAbstract lvLogic = (ListViewAbstract) t.newInstance();
            lvLogic.setIsShell(isShell);
            lvLogic.setMode(compType);
            lvLogic.setPageName(pageName);
            lvLogic.setTextSearchString(textSearchStr);
    
            //set all request information into the apex processing class.
            lvlogic.setRequestData(listview, columnSortData, joinFieldName, joinRecordIds, offset);

            rowData = lvLogic.getData();
            rowData.setIsDefaultSort(isDefaultSort);

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
            if (!isDefaultSort && !isShell)
                ListViewUserConfigHelper.updateSortConfigValue(pageName, sortStr, objectName, listviewName);

        } else {
            throw new ListViewException('The list view configuration can not be found for object ' + objectName + ' and list view name - ' + listViewName + ')');
        }
        
        ListViewErrorHelper.processLogs(true);

        return rowData;

    }

    @AuraEnabled
    public static String processParamChange(String objectName, String listViewName, String paramName, String paramValue, String paramLabel, String paramType)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.processParamChange(' + objectName + ', ' + listViewName + ', ' + paramName + ', ' + paramValue + ', ' + paramLabel + ', ' + paramType + ')');

        String rtnStr = 'Ok:';

        try {

            String errorStr = ListViewConfigHelper.updateListViewParam(objectName, listViewName, paramName, paramValue, paramLabel, paramType);

            if (errorStr != '')
            {
                rtnStr = 'Failed:' + errorStr;    
            }

        } catch (Exception e) {
            rtnStr = 'Failed:' + e.getMessage();
            String message = 'Exception during ListViewController.processParamChange(' + objectName + ', ' + listViewName + ', ' + paramName + ', ' + paramValue + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
        }

        ListViewErrorHelper.processLogs(true);

        return rtnStr;
    }

    /*
     * action = remove or add
     * conditionData = condition id (if remove) or condition data map (if add)
     */
    @AuraEnabled
    public static String processConditionChange(String objectName, String listViewName, String action, String conditionData)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.processConditionChange(' + objectName + ', ' + listViewName + ', ' + action + ', ' + conditionData + ')');

        String rtnStr = 'Ok:';

        if (action == 'add')
        {
            //get the field/value pairs of the update data
            List<Object> listValues = (List<Object>) JSON.deserializeUntyped(conditionData);
            Map<String, Object> mapValues = new Map<String, Object>();
            for (Object key: listValues)
            {
                List<Object> keyValues = (List<Object>) key;
                mapValues.put( (String) keyValues[0], keyValues[1]);
            }

            try {
                ListViewConfigHelper.addListViewCondition(objectName, 
                                                          listViewName, 
                                                          (String) mapValues.get('field'), 
                                                          (String) mapValues.get('operator'),
                                                          (String) mapValues.get('value'),
                                                          (String) mapValues.get('order'),
                                                          (String) mapValues.get('color'));
                CacheListViewConfig.remove(objectName, listViewName);
            } catch (Exception e) {
                rtnStr = 'Failed:' + e.getMessage();
                String message = 'Exception during ListViewController.processConditionChange(' + objectName + ', ' + listViewName + ', ' + action + ', ' + conditionData + ')  ' + ListViewException.getExtendedString(e);
                ListViewErrorHelper.createFutureUsageError(message); 
                }

        } else if (action == 'remove')
        {
            try {
                ListViewConfigHelper.deleteListViewCondition(conditionData);
                CacheListViewConfig.remove(objectName, listViewName);
            } catch (Exception e) {
                rtnStr = 'Failed:' + e.getMessage();
                String message = 'Exception during ListViewController.processConditionChange(' + objectName + ', ' + listViewName + ', ' + action + ', ' + conditionData + ')  ' + ListViewException.getExtendedString(e);
                ListViewErrorHelper.createFutureUsageError(message); 
            }
        }

        ListViewErrorHelper.processLogs(true);

        return rtnStr;
    }

    @AuraEnabled
    public static String processAction(String actionKey, String dataIds, String valuesMap)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.processAction(' + actionKey + ', ' + dataIds + ',' + valuesMap + ')');
    
        String responseStr = ListViewAction.RESULT_OK;
        List_View_Action__c action = null;

        try {
            action = ListViewActionHelper.getListViewActionByKey(actionKey);
        } catch (Exception e) {
            String message = 'Exception during ListViewController.processAction(' + actionKey + ',' + dataIds + ',' + valuesMap + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
            responseStr = ListViewAction.RESULT_ERROR + ':Couldn\'t find action config for name provided!';
            return responseStr;
        }

        System.debug(LoggingLevel.DEBUG, 'Action - ' + action);
        
        Type t = null;
        try {
            // Get the Type corresponding to the class name
            t = HelperSchema.getClassType(action.Apex_Class_Name__c);
        } catch (Exception e) {
            responseStr = ListViewAction.RESULT_ERROR + ':Couldn\'t find apex class "' + action.Apex_Class_Name__c + '" for config with name ' + action.Label__c;
            return responseStr; 
        }
        
        //get the list of Ids of the records that are to be processed.
        List<Object> listIds = (List<Object>) JSON.deserializeUntyped(dataIds);
        List<String> listStrIds = new List<String>();
        for (Object listId: listIds)
            listStrIds.add((String) listId);

        //get the field/value pairs of the update data
        List<Object> listValues = (List<Object>) JSON.deserializeUntyped(valuesMap);
        Map<String, Object> mapValues = new Map<String, Object>();
        for (Object key: listValues)
        {
            List<Object> keyValues = (List<Object>) key;
            mapValues.put( (String) keyValues[0], keyValues[1]);
        }

        //create the object from configuration.
        ListViewAction actionJob = null;
        
        //if we have a FLOW
        if (action.Is_Flow__c == true) {
            if (String.isEmpty(action.Flow_API_Name__c)) throw new ListViewException('Flow actions must have a flow API name');
            ListViewActionFlow actionFlow = (ListViewActionFlow) t.newInstance();
            actionFlow.setFlowName(action.Flow_API_Name__c);
            actionJob = actionFlow;

        //if we have a REGULAR ACTION
        } else {
            actionJob = (ListViewAction) t.newInstance();
        }

        //process the object
        try {
            responseStr = actionJob.process(listStrIds, mapValues);
        } catch (Exception e) {
            responseStr = ListViewAction.RESULT_ERROR + ':There was an error processing the records - ' + e.getMessage();
            String message = 'Exception during ListViewController.processAction(' + actionKey + ', ' + dataIds + ', ' + valuesMap + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
        }
        
        ListViewErrorHelper.processLogs(true);

        return responseStr;
    }

    @AuraEnabled(cacheable=true)
    public static List<ListViewAbstract.ListViewColumn> getListViewColumns(String objectName, String listViewName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewColumns(' + objectName + ', ' + listViewName + ')');

        //get the core SFDC list view data
        Map<Id, List_View__c> listViews = ListViewHelper.getListViews(objectName, listViewName);
        if (listViews.size() == 0) return new List<ListViewAbstract.ListViewColumn>();
        List_View__c listView = listViews.values()[0];

        //-------------------------------------------------------------------
        String objType = null;
        if (listView.RecordTypeId == null || listView.RecordTypeId == ListViewHelper.coreRTId)
            objType = ListViewHelper.CORE_APEX_CLASS;
        else
            objType = listView.Custom_Apex_Class__c;

        //get an apex Type of the object type
        Type t = HelperSchema.getClassType(objType);

        //create a new instance
        ListViewAbstract lvLogic = (ListViewAbstract) t.newInstance();

        //set all request information into the apex processing class.
        lvlogic.setRequestData(listview);

        List<ListViewAbstract.ListViewColumn> columnData = lvLogic.getColumnData();

        columnData.sort();

        ListViewErrorHelper.processLogs(true);

        return columnData;
    }

    /**
    * @description Method which accepts a record Id and a JSON string containing field data to be updated on the record.
    * @author tom@ansleyllc.com | 07-22-2021 
    **/
    @AuraEnabled
    public static String updateRecord(String rowId, String rowData)
    {
        //get just the Id as we return Id:position
        String id = rowId.split(':')[0];

        //add all field data - remember that Map objects cannot be stringified in Javascript so we need to turn
        //everything into an array before sending so here we turn it back again.
        Map<String, String> fieldMap = new Map<String, String>();
        List<Object> fieldData = (List<Object>) JSON.deserializeUntyped(rowData);
        for (Object values: fieldData)
        {
            List<Object> fieldDataVals = (List<Object>) values;
            String fieldName = (String) fieldDataVals[0];
            String value     = (String) fieldDataVals[1];
            
            fieldMap.put(fieldName, value);
        }

        String result = '';
        try {
            ListViewHelper.updateRecord(id, fieldMap);

        } catch (Exception e) {
            String message = 'Exception during ListViewController.updateRecord(' + rowId + ', ' + rowData + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(message);
            result = 'There was an error saving the records - ' + e.getMessage();
        }

        ListViewErrorHelper.processLogs(true);

        return result;
    }

    /**
    * @description Method which accepts a record Id and a JSON string containing field data to be updated on the record.
    * @author tom@ansleyllc.com | 07-30-2021 
    **/
    @AuraEnabled
    public static String updateRecords(String rowData)
    {
        System.debug(LoggingLevel.FINE, 'Starting updateRecords - ' + rowData);

        Map<String, Map<String, String>> dataMap = getRowDataFromJSON(rowData);

        System.debug(LoggingLevel.FINE, 'dataMap - ' + dataMap);
        String result = '';
        try {
            ListViewHelper.updateRecords(ListViewHelper.PROC_TYPE_UPDATE, null, dataMap);

        } catch (Exception e) {
            String message = 'Exception during ListViewController.updateRecords(' + rowData + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(message);
            result = 'There was an error saving the records - ' + e.getMessage();
        }

        ListViewErrorHelper.processLogs(true);

        return result;

    }

    /**
    * @description Method which accepts a record Id and a JSON string containing field data to use for creating new records.
    * @author tom@ansleyllc.com | 11-13-2021 
    **/
    @AuraEnabled
    public static String createRecords(String objType, String rowData)
    {
        System.debug(LoggingLevel.FINE, 'Starting createRecords(' + objType + ', ' + rowData + ')');

        Map<String, Map<String, String>> dataMap = getRowDataFromJSON(rowData);

        String result = '';
        try {
            Map<String, SObject> results = ListViewHelper.updateRecords(ListViewHelper.PROC_TYPE_CREATE, objType, dataMap);

            result = results.size() + ':' + SUCCESS;
        } catch (Exception e) {
            String message = 'Exception during ListViewController.createRecords(' + rowData + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(message);
            result = 'There was an error saving the records - ' + e.getMessage();
        }

        ListViewErrorHelper.processLogs(true);

        return result;

    }

    @AuraEnabled(cacheable=true)
    public static List<SelectOption> getPicklistValues(String objectName, String fieldName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewPicklistController.getPicklistValues(' + objectName + ',' + fieldName + ')');
        
        Map<String, String> picklistVals = HelperSchema.getPicklistMap(objectName, fieldName);

        List<SelectOption> options = new List<SelectOption>();
        for (String key: picklistVals.keySet())
            options.add(new SelectOption(key, picklistVals.get(key)));
        return options;
    }

    //=============================
    // INTERNAL CLASSES
    //=============================

    /**
      * @description Method which takes a JSON string and converts it back into row data for processing
      * @author tom.h.ansley@medtronic.com | 11-13-2021 
      **/
    private static Map<String, Map<String, String>> getRowDataFromJSON(String jsonString)
    {
        //remember that Map objects cannot be stringified in Javascript so we need to turn
        //everything into an array before sending so here we turn it back again. AND, this 
        //is a map of maps so its trickier
        Map<String, Object> rowMap = (Map<String, Object>) JSON.deserializeUntyped(jsonString);
        Map<String, Map<String, String>> dataMap = new Map<String, Map<String, String>>();
        System.debug(LoggingLevel.FINE, 'rowMap - ' + rowMap);
        for (String rowId: rowMap.keySet())
        {
            System.debug(LoggingLevel.FINE, 'Row Id - ' + rowId);
            Map<String, String> fieldMap = new Map<String, String>();

            //get just the Id as we return Id:position
            String id = rowId.split(':')[0];

            List<Object> fieldDataVals = (List<Object>) rowMap.get(rowId);
            System.debug(LoggingLevel.FINE, 'fieldDataVals - ' + fieldDataVals);
            for (Object valuePairs: fieldDataVals)
            {
                List<Object> values = (List<Object>) valuePairs;
                String fieldName    = (String) values[0];
                String value        = (String) values[1];
            
                fieldMap.put(fieldName, value);
            }
            dataMap.put(id, fieldMap);

        }
        System.debug(LoggingLevel.FINE, 'dataMap - ' + dataMap);

        return dataMap;
    }

    //=============================
    // INTERNAL CLASSES
    //=============================

    /* 
    * Have to build our own SelectOption object as Lightning cannot use System.SelectOption
    */
    public class SelectOption implements Comparable {
        public SelectOption(String value, String label) {
            this.value = value;
            this.label = label;
            this.disabled = false;
            this.escapeItem = false;
        }

        @AuraEnabled
        public String label { get;set; }
        @AuraEnabled
        public String value { get;set; }
        @AuraEnabled
        public Boolean disabled { get;set; }
        @AuraEnabled
        public Boolean escapeItem { get;set; }

        public Integer compareTo(Object compareTo) {
            SelectOption option2 = (SelectOption) compareTo;
            return label.compareTo(option2.label);
        }
    }

}