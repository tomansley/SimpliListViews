/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 09-09-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-04-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewController
{

    public static Set<String> validTotalColumns = new Set<String>{'integer', 'decimal', 'currency'};

    /*
     * Method to retrieve the progress of the initialization batch process
     */
    @AuraEnabled
    public static String getListViewInitProgress(String batchId)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewInitProgress(' + batchId + ')');
        String result = '0';
        
        if (batchId != '')
        {
            //Query the Batch apex jobs
            HelperSchema.checkSelectAccessible('SELECT TotalJobItems, Status, NumberOfErrors, MethodName, JobType, JobItemsProcessed, Id FROM AsyncApexJob');
            List<AsyncApexJob> jobs = [SELECT TotalJobItems, 
                                              Status, 
                                              NumberOfErrors, 
                                              MethodName, 
                                              JobType, 
                                              JobItemsProcessed, 
                                              Id 
                                       FROM AsyncApexJob 
                                       WHERE Id = :batchId];

            if (jobs.size() == 0) { 
                
                result = '0';

            } else if (jobs[0].TotalJobItems == 0) {
            
                result = '0';

            } else if (jobs[0].Status == 'Completed') { 
            
                result = '100';

            } else { 

                Decimal percentComp = (Decimal.valueOf(jobs[0].JobItemsProcessed)/Decimal.valueOf(jobs[0].TotalJobItems)) * 100;
                result = String.valueOf(percentComp);
                
            }
        } else {
            result = '-1';
        }

        System.debug(LoggingLevel.DEBUG, 'Finishing ListViewController.getListViewInitProgress with result - ' + result);
        return String.valueOf(result);
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

        Map<String, String> listviewObjects = ListViewHelper.getListViewObjects(incObjs, excObjs, false);

        for (String apiName: listviewObjects.keySet())
            configListOptions.add(new SelectOption(apiName, listviewObjects.get(apiName)));         
    
        configListOptions.sort();

        return configListOptions;
    }

    @AuraEnabled(cacheable=true)
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

        return configListOptions;
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getListViewConfigParams(String objectType, String listViewName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewConfigParams(' + objectType + ', ' + listViewName + ')');
        Map<String, String> configParams = new Map<String, String>();

        List<List_View_Config__c> configs = ListViewConfigHelper.getListViewConfig(objectType, listViewName);

        if (configs.size() == 0) return new Map<String, String>();

        List_View_Config__c config = configs[0];

        for (List_View_Config_Parameter__c param: config.List_View_Config_Parameters__r)
            configParams.put(param.Parameter_Name__c, param.Parameter_Value__c);         
        
        return configParams;
    }

    @AuraEnabled(cacheable=true)
    public static ListViewConfigWrapper getListViewConfig(String objectType, String listViewName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewConfig(' + objectType + ', ' + listViewName + ')');
        ListViewConfigWrapper lvConfig = null;

        List<List_View_Config__c> configs = ListViewConfigHelper.getListViewConfig(objectType, listViewName);

        if (configs.size() == 0) return new ListViewConfigWrapper(listViewName, objectType);

        lvConfig = new ListViewConfigWrapper(configs[0]);

        return lvConfig;
    }

    @AuraEnabled
    public static Map<String, String> getUserConfigs(String compName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getUserConfigs(' + compName + ')');
        Map<String, String> userConfigs = new Map<String, String>();

        Map<String, List_View_User_Config__c> configs = ListViewUserConfigHelper.getCurrentUserCompConfig(compName);
        for (List_View_User_Config__c config: configs.values())
            userConfigs.put(config.Name__c, config.Value__c);

        System.debug(LoggingLevel.DEBUG, 'User configs - ' + userConfigs);
        return userConfigs;
    }

    @AuraEnabled
    public static String updateUserConfig(String compName, String configName, String value)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateUserConfig(' + compName + ', ' + configName + ',' + value + ')');
        try {
            ListViewUserConfigHelper.updateCurrentUserConfigValue(compName, configName, value);
        } catch (Exception e) {
            String message = 'Exception during ListViewController.updateUserConfig(' + compName + ',' + configName + ',' + value + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageError(message); 
            return 'There was an error during user configuration update';
        }
        return 'success';
    }

    @AuraEnabled
    public static String updateObjectListViews(String objectType)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateObjectListViews(' + objectType + ')');
        //update the list view
        Boolean result = ListViewHelper.updateListViews(objectType);

        return 'success';
    }

    @AuraEnabled
    public static String updateSingleListView(String objectType, String listViewName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateSingleListView(' + objectType + ', ' + listViewName + ')');
        //get the listviews with object and name
        Map<Id, List_View__c> listviews = ListViewHelper.getListViews(objectType, listViewName);

        //if no listviews return failed
        if (listviews.size() == 0) return 'failed';

        //get the list views Id
        Set<Id> lvId = new Set<Id>();
        lvId.add(listviews.values()[0].Id);

        //update the list view
        Boolean result = ListViewHelper.updateListViews(lvId);

        return 'success';
    }

	@AuraEnabled
	public static String updateChangedListViews()
	{
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateChangedListViews()');

        //try get the last changed CORE list view
        Map<Id, ListView> changedListViews = ListViewHelper.getChangedListViews(1);

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
                ListViewHelper.updateListViews(lvId);

            }
        }

		return 'success';
	}

	//SimpliUIBatchController.getListViewData('Contact', 'AllContacts');
	@AuraEnabled
	public static String updateAllListViews()
	{
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateAllListViews()');
        Simpli_lv.ListViewProcessBatch b = new Simpli_lv.ListViewProcessBatch();
        
        Id jobId = null;
        
        try {
            jobId = Database.executebatch(b, 40);
        } catch (Exception e) {
            jobId = 'failed';
            String message = 'Exception during ListViewController.updateAllListViews() - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageError(message); 
        }
		return jobId;
	}

    @AuraEnabled(cacheable=true)
    public static List<SelectOption> getListViewsActions(String objectType)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewsActions(' + objectType + ')');
        List<SelectOption> actionsOptions = new List<SelectOption>();

        Map<String, List_View_Action__c> actions = ListViewActionHelper.getListViewActionsByObject(objectType);

        for (String actionName: actions.keySet())
            actionsOptions.add(new SelectOption(actions.get(actionName).Primary_Key__c, actionName));         
    
        actionsOptions.sort();

        return actionsOptions;
    }

    @AuraEnabled(cacheable=true)
    public static ActionWrapper getListViewAction(String actionName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateSingleListView(' + actionName + ')');

        ActionWrapper wrapper = null;
        if (actionName != '')
        {

            List_View_Action__c action = null;
    
            try {
                action = ListViewActionHelper.getListViewActionByKey(actionName);
                wrapper = new ActionWrapper(action);
            } catch (Exception e) {
                String message = 'Exception during ListViewController.getListViewAction(' + actionName + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
                ListViewErrorHelper.createUsageError(message); 
            }
        }
        return wrapper;
    }

    /*
     * Method which determines whether a list view data request is valid or not.
     */
    @AuraEnabled
    public static String isValidListViewDataRequest(String objectName, String joinFieldName, String joinData)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.isValidListViewDataRequest(' + objectName + ', ' + joinFieldName + ',' + joinData + ')');
        String result = 'success';

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
                if (joinRecordIds.size() > 0)
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
        return result;
    }

    /*
       
     */
    @AuraEnabled(cacheable=true)
    public static RowsWrapper getListViewData(String objectName, String listViewName, String sortData, String joinFieldName, String joinData)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewData(' + objectName + ', ' + listViewName + ',' + sortData + ',' + joinFieldName + ',' + joinData + ')');
        
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
                if (joinRecordIds.size() > 0)
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
                        return null;
                }
            }
        }

        //get the custom list view config and params
        List<List_View_Config__c> lvConfigs = ListViewConfigHelper.getListViewConfig(objectName, listViewName);
        List_View_Config__c lvConfig = null;
        ListViewConfigWrapper lvConfigWrapper = null;

        //we may not have any configuration for the provided list view names - FYI
        if (lvConfigs.size() > 0) 
        {
            lvConfigWrapper = new ListViewConfigWrapper(lvConfigs[0]);
            lvConfig = lvConfigWrapper.listViewConfig;
        }

        //get the core SFDC list view data
        Map<Id, List_View__c> listviews = ListViewHelper.getListViews(objectName, listViewName);

        RowsWrapper rowData = null;

        if (listviews.size() > 0)
        {

            List_View__c listview = listviews.values()[0];

            //handle the sorting data
            List<ListViewHelper.ColumnSortData> columnSortData = new List<ListViewHelper.ColumnSortData>();
            if (sortData.length() > 0)
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
                }

                columnSortData.sort();
            }

            //get list view data
            List<SObject> objectRows = ListViewHelper.getListViewData(listview, lvConfig, columnSortData, joinFieldName, joinRecordIds);
            
            //turn SObjects into wrapper classes.
            rowData = handleRowsToWrapper(objectRows, listview, lvConfigWrapper, columnSortData);

            rowData.objName    = objectName;
            rowData.coreListId = listview.Core_ListView_Id__c;

        }
        return rowData;

    }

    @AuraEnabled
    public static String processParamChange(String objectName, String listViewName, String paramName, String paramValue)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.processParamChange(' + objectName + ', ' + listViewName + ', ' + paramName + ', ' + paramValue + ')');

        String rtnStr = 'Ok:';

        try {

            String errorStr = ListViewConfigHelper.updateListViewParam(objectName, listViewName, paramName, paramValue);

            if (errorStr != '')
            {
                rtnStr = 'Failed:' + errorStr;    
            }

        } catch (Exception e) {
            rtnStr = 'Failed:' + e.getMessage();
            String message = 'Exception during ListViewController.processParamChange(' + objectName + ', ' + listViewName + ', ' + paramName + ', ' + paramValue + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageError(message); 
        }

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
            } catch (Exception e) {
                rtnStr = 'Failed:' + e.getMessage();
                String message = 'Exception during ListViewController.processConditionChange(' + objectName + ', ' + listViewName + ', ' + action + ', ' + conditionData + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
                ListViewErrorHelper.createUsageError(message); 
                }

        } else if (action == 'remove')
        {
            try {
                ListViewConfigHelper.deleteListViewCondition(conditionData);
            } catch (Exception e) {
                rtnStr = 'Failed:' + e.getMessage();
                String message = 'Exception during ListViewController.processConditionChange(' + objectName + ', ' + listViewName + ', ' + action + ', ' + conditionData + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
                ListViewErrorHelper.createUsageError(message); 
            }
        }

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
            String message = 'Exception during ListViewController.processAction(' + actionKey + ',' + dataIds + ',' + valuesMap + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageError(message); 
            responseStr = ListViewAction.RESULT_ERROR + ':Couldn\'t find action config for name provided!';
            return responseStr;
        }

        // Get the Type corresponding to the class name
        Type t = null;

		Integer index = action.Apex_Class_Name__c.indexOf('.');
    	if (index != -1) {
        	// With namespace "ns.Type"
        	t = Type.forName(action.Apex_Class_Name__c.substring(index), action.Apex_Class_Name__c.substring(index + 1, action.Apex_Class_Name__c.length()));
    	} else {
        	// Just "Type"
        	t = Type.forName(null, action.Apex_Class_Name__c);
    	}

        if (t == null) {
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
        ListViewAction actionJob = (ListViewAction) t.newInstance();

        //process the object
        try {
            responseStr = actionJob.process(listStrIds, mapValues);
        } catch (Exception e) {
            responseStr = ListViewAction.RESULT_ERROR + ':There was an error processing the records  - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            String message = 'Exception during ListViewController.processAction(' + actionKey + ', ' + dataIds + ', ' + valuesMap + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageError(message); 
    }
        return responseStr;
    }

    @AuraEnabled(cacheable=true)
    public static List<SelectOption> getListViewColumnLabels(String objectName, String listViewName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewColumnLabels(' + objectName + ', ' + listViewName + ')');
        List<SelectOption> labelOptions = new List<SelectOption>();

        List<String> labels = getColumnLabels(objectName, listViewName);

        for (String label: labels)
            labelOptions.add(new SelectOption(label, label));         
    
        labelOptions.sort();

        return labelOptions;
    }

    /*
     * Method to get a list of the column labels for a list view.
     
       System.debug(LoggingLevel.DEBUG, 'Labels - ' + ListViewController.getListViewColumnLabels('Account','PlatinumandGoldSLACustomers'));
     */
    private static List<String> getColumnLabels(String objectName, String listViewName)
    {

        //get the core SFDC list view data
        Map<Id, List_View__c> listViews = ListViewHelper.getListViews(objectName, listViewName);
        if (listViews.size() == 0) return new List<String>();
        List_View__c listView = listViews.values()[0];

        //get the custom list view config and params
        List<List_View_Config__c> lvConfigs = ListViewConfigHelper.getListViewConfig(objectName, listViewName);
        List_View_Config__c lvConfig = null;
        ListViewConfigWrapper lvConfigWrapper = null;

        //we may not have any configuration for the provided list view names - FYI
        if (lvConfigs.size() > 0) 
        {
            lvConfigWrapper = new ListViewConfigWrapper(lvConfigs[0]);
            lvConfig = lvConfigWrapper.listViewConfig;
        }

        SObject exampleRow = null;
        
        //try to get a true example row
        List<SObject> objectRows = ListViewHelper.getListViewData(listview, lvConfig, null, null, null, true);
        if (objectRows.size() > 0) 
        {
            exampleRow = objectRows[0];
        //if no row then use object type (which will not work if there are weird additional fields.)
        } else {
            Type t = Type.forName(objectName);
            exampleRow = (SObject) t.newInstance();
        }

        List<String> colLabels = new List<String>();

        //get all columns from the list view
        List<Object> allColumns = (List<Object>) JSON.deserializeUntyped(listView.Core_ListView_Columns__c);

        //get the CORE SFDC COLUMN meta data
        for (Object column: allColumns)
        {
            Map<String, Object> columnData = (Map<String, Object>) column;

            String fieldName = (String) columnData.get('fieldNameOrPath');
            Boolean hidden   = (Boolean) columnData.get('hidden');

            if (!hidden)
            {
                HelperSchema.FieldData d = HelperSchema.getFieldData(exampleRow, fieldName);
         
                colLabels.add(d.label);
            }
            
        }

        //set the CUSTOM COLUMN meta data into the rows wrapper
        if (lvConfigWrapper != null 
            && lvConfigWrapper.getParameter('AdditionalFields') != null 
            && lvConfigWrapper.getParameter('AdditionalFields').getValue() != null
            && lvConfigWrapper.getParameter('AdditionalFields').getValue() != '')
        {
            //get the field names in a list
            List<String> fields = lvConfigWrapper.getParameter('AdditionalFields').getValue().deleteWhitespace().split(',');

            System.debug(LoggingLevel.DEBUG, 'Additional Fields - ' + fields);

            for (String fieldName: fields)
            {
                HelperSchema.FieldData d = HelperSchema.getFieldData(exampleRow, fieldName);
         
                if (d != null)
                    colLabels.add(d.label);
            }
        }

        return colLabels;
    }

    /*
        * Method to take a list of SObjects retrieved using a listviews query and convert the
        * rows into something that front end lightning components can handle.
        */
    private static RowsWrapper handleRowsToWrapper(List<SObject> dataRows, List_View__c listView, 
                                                   ListViewConfigWrapper lvConfigWrapper,
                                                   List<ListViewHelper.ColumnSortData> sortData)
    {
        System.debug('Starting ListViewController.handleRowsToWrapper - ' + System.now().getTime());

        Map<String, ListViewHelper.ColumnSortData> sortDataByFieldName = new Map<String, ListViewHelper.ColumnSortData>();
        for (ListViewHelper.ColumnSortData columnData: sortData)
            sortDataByFieldName.put(columnData.fieldName, columnData);

        RowsWrapper rows = new RowsWrapper(listView);
        
        //get all columns from the list view
        List<Object> allColumns = (List<Object>) JSON.deserializeUntyped(listView.Core_ListView_Columns__c);
        List<Object> columns = new List<Object>();
        Boolean addColumn = true;

        //set the CORE SFDC COLUMN meta data into the rows wrapper
        for (Object column: allColumns)
        {
            Map<String, Object> columnData = (Map<String, Object>) column;

            String fieldName = (String) columnData.get('fieldNameOrPath');
            Boolean hidden   = (Boolean) columnData.get('hidden');

            if (!hidden)
            {
                FieldWrapper field = new FieldWrapper((String) columnData.get('label'), 
                                                      (String) columnData.get('type'),
                                                      fieldName);

                if (sortDataByFieldName.containsKey(fieldName))
                {
                    field.sortIndex = String.valueOf(sortDataByFieldName.get(fieldName).sortIndex);
                    field.sortDir   = sortDataByFieldName.get(fieldName).sortDirection;
                }

                rows.addFieldMetaData(field);

                columns.add(column);
            }
            
        }

        //set the CUSTOM COLUMN meta data into the rows wrapper
        if (lvConfigWrapper != null
            && lvConfigWrapper.getParameter('AdditionalFields') != null 
            && lvConfigWrapper.getParameter('AdditionalFields').getValue() != null 
            && lvConfigWrapper.getParameter('AdditionalFields').getValue() != '' 
            && dataRows.size() > 0)
        {
            //get the field names in a list
            List<String> fields = lvConfigWrapper.getParameter('AdditionalFields').getValue().deleteWhitespace().split(',');

            System.debug(LoggingLevel.DEBUG, 'FIELDS - ' + fields);

            //get the object type we are working with
            String objType = HelperSchema.getObjectType(dataRows[0]);

            for (String fieldName: fields)
            {

                HelperSchema.FieldData fieldData = HelperSchema.getFieldData(dataRows[0], fieldName);
                String label = fieldData.label;

                FieldWrapper field = new FieldWrapper(label, 
                                                      fieldData.type.name().toLowerCase(),
                                                      fieldName);

                if (sortDataByFieldName.containsKey(fieldName))
                {
                    field.sortIndex = String.valueOf(sortDataByFieldName.get(fieldName).sortIndex);
                    field.sortDir   = sortDataByFieldName.get(fieldName).sortDirection;
                }

                rows.addFieldMetaData(field);

                Map<String, Object> newColumn = new Map<String, Object>();
                newColumn.put('type', fieldData.type.name().toLowerCase());
                newColumn.put('fieldNameOrPath', fieldName);
                newColumn.put('hidden', false);
                newColumn.put('label', label);

                columns.add(newColumn);

            }
        }

        //for each row of data
        for (SObject row: dataRows)
        {

            RowWrapper rowWrapper = new RowWrapper((String.valueOf(row.get('Id'))));
            rows.addRow(rowWrapper);

            //for each listview column
            for (Object column: columns)
            {
                Map<String, Object> columnData = (Map<String, Object>) column;

                String fieldType = (String) columnData.get('type');
                String fieldName = (String) columnData.get('fieldNameOrPath');
                Boolean hidden   = (Boolean) columnData.get('hidden');

                System.debug(LoggingLevel.DEBUG, 'Field - ' + fieldName + ', Type - ' + fieldType);

                //do not display hidden
                if (hidden) continue;

                HelperSchema.FieldData fieldData = HelperSchema.getFieldData(row, fieldName);

                FieldWrapper field = new FieldWrapper(fieldData.label, 
                                                    String.valueOf(fieldData.value), 
                                                    fieldData.type.name().toLowerCase(),
                                                    fieldName);

                if (fieldData.name == 'Name') {
                    String url = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + String.valueOf(fieldData.fieldObj.get('Id')) + '/view';
                    field.setURL(url);
                }

                if (sortDataByFieldName.containsKey(fieldName))
                {
                    field.sortIndex = String.valueOf(sortDataByFieldName.get(fieldName).sortIndex);
                    field.sortDir   = sortDataByFieldName.get(fieldName).sortDirection;
                }

                rowWrapper.addField(field);

            }

            if (lvConfigWrapper != null)
            rowWrapper.calculateHighlighting(lvConfigWrapper.conditions);
        }

        //if totals have been configured
        if (lvConfigWrapper != null
            && lvConfigWrapper.getParameter('TotalColumns') != null 
            && lvConfigWrapper.getParameter('TotalColumns').getValue() != '')
        {

            rows.hasTotalsRow = true;

            System.debug(LoggingLevel.DEBUG, 'Starting total column calculations!');

            String totalColumns = lvConfigWrapper.getParameter('TotalColumns').getValue();

            System.debug(LoggingLevel.DEBUG, 'TotalColumns - ' + totalColumns);

            RowWrapper totalWrapper = new RowWrapper('000000000000000000');
            totalWrapper.highlight = true;
            if (lvConfigWrapper.getParameter('TotalColumnsColor') != null)
                totalWrapper.highlightColor = lvConfigWrapper.getParameter('TotalColumnsColor').getValue();
            else
                totalWrapper.highlightColor = '#FFFFFF';
            totalWrapper.isTotals = true;

            rows.addRow(totalWrapper);

            //for each row of data
            for (RowWrapper rowWrapper: rows.getRows())
            {

                if (rowWrapper.getIsTotals()) continue;

                List<FieldWrapper> fields = rowWrapper.getFields();

                //for each field
                for (FieldWrapper fieldWrapper: fields)
                {

                    FieldWrapper totalField = totalWrapper.getField(fieldWrapper.getName());

                    //if this is the first pass then we will need to create a wrapper 
                    //regardless of whether its a column that is to be calculated.
                    if (totalField == null)
                    {
                        String initValue = '';

                        //for the very first column add the TOTALS string
                        if (totalWrapper.getFields().size() == 0)
                            initValue = 'TOTALS';
                        //for any VALID calculation columns
                        else if (validTotalColumns.contains(fieldWrapper.getType()))
                            initValue = '0';
                        else 
                            initValue = '';

                        totalField = new FieldWrapper(fieldWrapper.getLabel(),  
                                            initValue,
                                            fieldWrapper.getType(),
                                            fieldWrapper.getName());

                        System.debug(LoggingLevel.DEBUG, 'Added total field - ' + totalField);

                        totalWrapper.addField(totalField);
                    }

                    //see if the field is a column to be totalled
                    if (totalColumns.contains(fieldWrapper.getName()))
                    {
                        System.debug(LoggingLevel.DEBUG, 'Found a column to total - ' + fieldWrapper.getName());

                        System.debug(LoggingLevel.DEBUG, 'fieldWrapper.getValue() - ' + fieldWrapper.getValue());
                        System.debug(LoggingLevel.DEBUG, 'fieldWrapper.getType() - ' + fieldWrapper.getType());
                        System.debug(LoggingLevel.DEBUG, 'totalField.value - ' + totalField.value);
                        System.debug(LoggingLevel.DEBUG, 'totalField.getType() - ' + totalField.getType());

                        //if this is a valid column for total calculation and there is a value to calculate
                        if (validTotalColumns.contains(totalField.getType()) && fieldWrapper.getValue() != null && fieldWrapper.getValue() != '')
                        {
                            if (totalField.getType() == 'currency')
                                totalField.value = String.valueOf(Decimal.valueOf(String.valueOf(fieldWrapper.getValue())) + Decimal.valueOf(totalField.value));
                            else
                                totalField.value = String.valueOf(Decimal.valueOf(fieldWrapper.getValue()) + Decimal.valueOf(totalField.value));

                            
                        }
                    }
                }


            }

        }

        System.debug('Ending ListViewController.handleRowsToWrapper - ' + System.now().getTime());
        return rows;
    }

    //=============================
    // INTERNAL CLASSES
    //=============================
    
    //-------------------------------------------------------------------
    //ROWS - class which wraps up ALL row data for sending to front end.
    //       this includes the table data itself as well as any rows, 
    //       row or field config.
    //-------------------------------------------------------------------
    public class RowsWrapper
    {
        public String objName;
        public String coreListId;
        public ListViewWrapper listView;
        public List<RowWrapper> rows;
        public List<FieldWrapper> fieldMetaData;
        public String csvData;
        public Boolean hasTotalsRow;
        
        public RowsWrapper(List_View__c listView)
        {
            this.listView = new ListViewWrapper(listView);
            rows = new List<RowWrapper>();
            fieldMetaData = new List<FieldWrapper>();
            hasTotalsRow = false;
        }

        @AuraEnabled(cacheable=true)
        public Integer getRowCount()
        {
            if (hasTotalsRow)
                return rows.size()-1;
            else
                return rows.size();
        }

        public void addRow(RowWrapper row)
        {
            rows.add(row);
        }

        @AuraEnabled(cacheable=true)
        public List<RowWrapper> getRows()
        {
            return rows;
        }   	
        
        public void addFieldMetaData(FieldWrapper field)
        {
            fieldMetaData.add(field);
        }

        @AuraEnabled(cacheable=true)
        public List<FieldWrapper> getFieldMetaData()
        {
            return fieldMetaData;
        }

        @AuraEnabled(cacheable=true)
        public ListViewWrapper getListView()
        {
            return listView;
        }

        /*
         * Method to retrieve the data in CSV format.
         */
        @AuraEnabled(cacheable=true)
        public String getDataAsString()
        {
            String dataStr = getHeadersAsCSVString();

            //if we have no data then return
            if (rows == null || rows.size() == 0) return dataStr;

            //for each row of data
            for (RowWrapper row: rows)
                dataStr += row.getDataAsCSVString();

            return dataStr;
        }

        @AuraEnabled(cacheable=true)
        public String getHeadersAsCSVString()
        {
            String dataStr = '';

            for (FieldWrapper column: fieldMetaData)
            {
                dataStr += '"' + column.name.replaceAll('"', '""') + '"' + ',';
            }

            dataStr = dataStr.removeEnd(',') + '\n';

            return dataStr;
        }

        //Example - https://simpli-list-view-dev-dev-ed.lightning.force.com/lightning/o/Account/list?filterName=00B3h000003ZfMQEA0
        @AuraEnabled(cacheable=true)
        public String getCoreListViewURL()
        {
            return URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/o/' + objName + '/list?filterName=' + coreListId;
        }
        
    }
    
    //-----------------------------------------------------------
    //ROW - wrapper which holds one ROW of field data and config.
    //-----------------------------------------------------------
    public class RowWrapper
    {

        public Map<String, FieldWrapper> fields; //the list of fields and values for the row
        public String rowId;                     //the SFDC record id. USed to identify rows on the UI
        public Boolean highlight;                //indicates whether the row should be highlighted due to conditions set by user
        public String highlightColor;            //the color the row should be set to if being highlighted.
        public Boolean isTotals;                 //indicates whether this row is a totals row.

        public RowWrapper(String rowId)
        {
            this.rowId = rowId;
            this.highlight = false;
            this.highlightColor = '';
            fields = new Map<String, FieldWrapper>();
            isTotals = false;
        }

        public void addField(FieldWrapper field)
        {
            fields.put(field.getName(), field);
        }

        @AuraEnabled(cacheable=true)
        public List<FieldWrapper> getFields()
        {
            return fields.values();
        }

        public FieldWrapper getField(String apiName)
        {
            return fields.get(apiName);
        }
        
        @AuraEnabled(cacheable=true)
        public String getRowId()
        {
            return rowId;
        }

        @AuraEnabled(cacheable=true)
        public String getCheckBoxId()
        {
            return 'checkbox:' + rowId;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getHighlight()
        {
            return highlight;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsTotals()
        {
            return isTotals;
        }

        @AuraEnabled(cacheable=true)
        public String getHighlightColor()
        {
            return highlightColor;
        }

        @AuraEnabled(cacheable=true)
        public String getDataAsCSVString()
        {
            String dataStr = '';

            //get the field data. We make sure to escape delimiter
            for (FieldWrapper rowData: getFields())
            {
                dataStr += '"' + rowData.value.replaceAll('"', '""') + '"' + ',';
            }

            dataStr = dataStr.removeEnd(',') + '\n';

            return dataStr;
        }

        /*
         * Method to calculate and set the conditional highlighting of rows based on provided configuration conditions.
         * We pass in the condition details each time as its a complex object that cannot be passed to the lightning UI
         */
        public void calculateHighlighting(Map<String, List<ListViewCondition>> lvConfigConditions)
        {
            System.debug(LoggingLevel.DEBUG, 'Calculating highlighting for row!');
            System.debug(LoggingLevel.DEBUG, 'Conditions are - ' + lvConfigConditions);
            //for each field
            for (FieldWrapper field: fields.values())
            {
                System.debug(LoggingLevel.DEBUG, 'Looking at field with name = ' + field.label + ' and value = ' + field.value);

                //check of there is a condition name which matches a field
                List<ListViewCondition> conditions = lvConfigConditions.get(field.label.toLowerCase());

                //if there is then validate
                if (conditions != null)
                {

                    System.debug(LoggingLevel.DEBUG, 'We have ' + conditions.size() + ' matching conditions!');

                    List<List_View_Config_Condition__c> lvConditions = new List<List_View_Config_Condition__c>();
                    for (ListViewCondition condition: conditions)
                        lvConditions.add(condition.getCondition());

                    String color = ListViewConfigHelper.validateFieldCondition(field.value, lvConditions);

                    System.debug(LoggingLevel.DEBUG, 'Condition validation result = ' + color);

                    //get the highlight color as well regardless.
                    if (color != '')
                        highlightColor = color;
                }
            }
        }
    }

    //---------------------------------------------------------------------
    //FIELD - wrapper holding data for a single cell in a table. This data 
    //        includes both table data as well as config for how it should 
    //        be displayed.
    //---------------------------------------------------------------------
    public class FieldWrapper
    {

        public String label;
        public String value;
        public String type;
        public String url;
        public String name;
        public Boolean sortDir; //true = asc, false = desc
        public String sortIndex;
        
        public FieldWrapper(String label, String value, String type, String name)
        {
            this.label     = label;
            this.type      = type;
            this.value     = value;
            this.name      = name;
            this.sortDir   = true;
            this.sortIndex = '';

            if (this.value == null)
                this.value = '';
        }
        
        public FieldWrapper(String label, String type, String name)
        {
            this.label   = label;
            this.type    = type;
            this.name    = name;
            this.sortdir = true;
            this.sortIndex = '';
        }
        
        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            return label;
        }
        
        @AuraEnabled(cacheable=true)
        public String getName()
        {
            return name;
        }
        
        @AuraEnabled(cacheable=true)
        public String getSortIndex()
        {
            return sortIndex;
        }
        
        @AuraEnabled(cacheable=true)
        public String getSortIndexDisplay()
        {
            if (sortIndex == null || sortIndex == '') return '';
            return String.valueOf(Integer.valueOf(sortIndex) + 1); //add one as we don't want to start on a zero'th value for users!
        }
        
        @AuraEnabled(cacheable=true)
        public Boolean getSortDir()
        {
            return sortDir;
        }
        
        @AuraEnabled(cacheable=true)
        public String getType()
        {
            return type;
        }
        
        @AuraEnabled(cacheable=true)
        public String getValue()
        {
            return value;
        }

        @AuraEnabled
        public Boolean getHasURL()
        {
            if (this.url == null) return false;
            return true;    
        }
        
        public void setURL(String url)
        {
            this.url = url;
        }

        @AuraEnabled(cacheable=true)
        public String getURL()
        {
            return url;
        }
        
    }

    //-------------------------------------------------------------------
    //LIST VIEW - wrapper which holds list view information. Note that 
    //            we cannot pass any SObject to a lightning component so 
    //            need to add fields to this wrapper as we need them.
    //-------------------------------------------------------------------
    public class ListViewWrapper
    {
        public DateTime lastModifiedDate;
        public String lastModifiedBy;

        public ListViewWrapper(List_View__c listView)
        {
            lastModifiedDate = listView.LastModifiedDate;
            lastModifiedBy   = listView.LastModifiedBy.Name;
        }

        @AuraEnabled(cacheable=true)
        public String getLastModifiedText()
        {
            return  'Last Modified By: ' + lastModifiedBy + ' - ' + lastModifiedDate;
        }

        @AuraEnabled(cacheable=true)
        public String getLastModifiedBy()
        {
            return lastModifiedBy;
        }
        
        @AuraEnabled(cacheable=true)
        public DateTime getLastModifiedDate()
        {
            return lastModifiedDate;
        }
        
    }

    //-------------------------------------------------------------------
    //LIST VIEW - wrapper which holds list view CONFIG information. Note 
    //CONFIG      that we cannot pass any SObject to a lightning component 
    //            so need to add fields to this wrapper as we need them.
    //-------------------------------------------------------------------
    public class ListViewConfigWrapper
    {
        public List_View_Config__c listViewConfig;
        public DateTime lastModifiedDate;
        public String lastModifiedBy;
        public Map<String, ListViewParam> parameters;
        public Map<String, List<ListViewCondition>> conditions;
        public String name;
        public String obj;

        public ListViewConfigWrapper (String name, String obj)
        {
            this.name = name;
            this.obj = obj;
            parameters       = new Map<String,ListViewParam>();
            conditions       = new Map<String, List<ListViewCondition>>();
        }

        public ListViewConfigWrapper(List_View_Config__c listView)
        {
            this.listViewConfig = listView;
            this.name        = listView.Name;
            this.obj         = listView.List_View_Object__c;
            lastModifiedDate = listView.LastModifiedDate;
            lastModifiedBy   = listView.LastModifiedBy.Name;
            parameters       = new Map<String,ListViewParam>();
            conditions       = new Map<String, List<ListViewCondition>>();

            for (List_View_Config_Parameter__c param: listView.List_View_Config_Parameters__r)
            {
                parameters.put(param.Parameter_Name__c, new ListViewParam(param.Parameter_Label__c,
                                                                          param.Parameter_Name__c, 
                                                                          param.Parameter_Value__c, 
                                                                          param.Parameter_Type__c));
            }

            //now add other parameters that have not been set but we need defaults

            System.debug(LoggingLevel.DEBUG, 'All OLD config params - ' + parameters);

            //get the default params
            ListViewConfigHelper.ListViewConfigDefaults paramDefaults = new ListViewConfigHelper.ListViewConfigDefaults();

            //set defaults if they do not exist
            for (ListViewConfigHelper.ListViewConfigDefault param: paramDefaults.params.values())
            {
                System.debug(LoggingLevel.DEBUG, 'Looking at def param - ' + param);

                ListViewParam lvParam = parameters.get(param.name);
                if (lvParam == null)
                {
                    System.debug(LoggingLevel.DEBUG, 'Creating new param - ' + param.name);

                    lvParam = new ListViewParam(param.label, param.name, param.value, param.type);
                    lvParam.description = param.description;
                    parameters.put(param.name, lvParam);

                //if we already have the parameter then just set the description as that info does not get saved.
                } else {
                    lvParam.description = param.description;
                }
            }



            System.debug(LoggingLevel.DEBUG, 'All NEW config params - ' + parameters);


            for (List_View_Config_Condition__c condition: listView.List_View_Config_Conditions__r)
            {
                List<ListViewCondition> conditionList = conditions.get(condition.Field_Name__c.toLowerCase());
                if (conditionList == null)
                {
                    conditionList = new List<ListViewCondition>();
                    conditions.put(condition.Field_Name__c.toLowerCase(), conditionList);
                }
                conditionList.add(new ListViewCondition(condition));
            }
            
        }

        @AuraEnabled(cacheable=true)
        public String getName()
        {
            return name;
        }
        
        @AuraEnabled(cacheable=true)
        public String getObject()
        {
            return obj;
        }
        
        @AuraEnabled(cacheable=true)
        public String getLastModifiedText()
        {
            return  'Last Modified By: ' + lastModifiedBy + ' - ' + lastModifiedDate;
        }

        @AuraEnabled(cacheable=true)
        public String getLastModifiedBy()
        {
            return lastModifiedBy;
        }
        
        @AuraEnabled(cacheable=true)
        public DateTime getLastModifiedDate()
        {
            return lastModifiedDate;
        }

        @AuraEnabled(cacheable=true)
        public List<ListViewParam> getParameters()
        {
            List<ListViewParam> params = parameters.values();
            params.sort();

            return params;
        }

        public ListViewParam getParameter(String name)
        {
            return parameters.get(name);
        }

        @AuraEnabled(cacheable=true)
        public List<ListViewCondition> getConditions()
        {
            List<ListViewCondition> allConditions = new List<ListViewCondition>();
            for (String name: conditions.keySet())
                allConditions.addAll(conditions.get(name));

            return allConditions;
        }

        public List<ListViewCondition> getCondition(String field)
        {
            return conditions.get(field);
        }


        
    }

    public class ListViewParam implements Comparable
    {
        public Id paramId;
        public String name;
        public String label;
        public String value;
        public String type;
        public String description;

        public ListViewParam(String label, String name, String value, String type)
        {
            this.label = label;
            this.name = name;
            this.value = value;
            this.type = type;
            this.description = '';
        }

        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            return label;
        }

        @AuraEnabled(cacheable=true)
        public String getName()
        {
            return name;
        }

        @AuraEnabled(cacheable=true)
        public String getValue()
        {
            return value;
        }

        @AuraEnabled(cacheable=true)
        public String getType()
        {
            return type;
        }

        @AuraEnabled(cacheable=true)
        public String getPlaceHolder()
        {
            return 'Enter a value here...';
        }

        @AuraEnabled(cacheable=true)
        public String getDescription()
        {
            return description;
        }

        @AuraEnabled(cacheable=true)
        /*
         * Method which indicates whether an update should occur on this parameter immediately after its been changed vs.
         * after the user leaves the input field.
         */
        public Boolean getUpdateImmediate()
        {
            if (getType().toLowerCase() == 'color' 
                || getType().toLowerCase() == 'boolean') 
                return true;
            else 
                return false;
        }

        @AuraEnabled(cacheable=true)
        public Boolean getIsBoolean()
        {
            if (getType().toLowerCase() == 'boolean') 
                return true;
            else 
                return false;            
        }

        public Integer compareTo(Object compareTo) {
            ListViewParam param2 = (ListViewParam) compareTo;
            return label.compareTo(param2.label);
        }
    }

    public class ListViewCondition
    {
        public List_View_Config_Condition__c condition;
        public String fieldLabel;
        public String operator;
        public String value;
        public String order;
        public String color;
        public String id;

        public ListViewCondition(List_View_Config_Condition__c condition)
        {
            this.condition = condition;
            fieldLabel     = condition.Field_Name__c;
            operator       = condition.Operator__c;
            value          = condition.Value__c;
            order          = condition.Order__c;
            color          = condition.Highlight_Color__c;
            id             = condition.Id;
        }

        public List_View_Config_Condition__c getCondition()
        {
            return condition;
        }

        @AuraEnabled(cacheable=true)
        public String getFieldLabel()
        {
            return fieldLabel;
        }

        @AuraEnabled(cacheable=true)
        public String getOperator()
        {
            return operator;
        }

        @AuraEnabled(cacheable=true)
        public String getValue()
        {
            return value;
        }

        @AuraEnabled(cacheable=true)
        public String getOrder()
        {
            return order;
        }

        @AuraEnabled(cacheable=true)
        public String getColor()
        {
            return color;
        }

        @AuraEnabled(cacheable=true)
        public String getId()
        {
            return id;
        }

    }

    //---------------------------------------
    //ACTION - class which wraps up an action
    //---------------------------------------
    public class ActionWrapper
    {
        public List_View_Action__c action;
        public List<ActionParameterWrapper> parameters;

        public ActionWrapper(List_View_Action__c action)
        {
            this.action = action;
            parameters = new List<ActionParameterWrapper>();
            for (List_View_Action_Parameter__c param: action.List_View_Action_Parameters__r)
                parameters.add(new ActionParameterWrapper(param));
        }

        @AuraEnabled(cacheable=true)
        public List<ActionParameterWrapper> getParameters()
        {
            return parameters;    
        }

        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            return action.Label__c;
        }

        @AuraEnabled(cacheable=true)
        public String getObjectType()
        {
            return action.Object_Type__c;
        }

    }

    //---------------------------------------------------------
    //ACTION PARAM - class which wraps up an action parameter.
    //---------------------------------------------------------
    public class ActionParameterWrapper
    {
        public List_View_Action_Parameter__c param;

        public ActionParameterWrapper(List_View_Action_Parameter__c param)
        {
            this.param = param;
        }

        @AuraEnabled(cacheable=true)
        public String getAPIName()
        {
            return param.Field_API_Name__c;
        }

        @AuraEnabled(cacheable=true)
        public String getLabel()
        {
            return param.Label__c;
        }

        @AuraEnabled(cacheable=true)
        public String getType()
        {
            return param.Type__c;
        }

        @AuraEnabled(cacheable=true)
        public String getValue()
        {
            return param.Default_Value__c;
        }

        @AuraEnabled(cacheable=true)
        public String getPlaceholder()
        {
            return param.Placeholder_Text__c;
        }

    }

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