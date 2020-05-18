public with sharing class ListViewController
{

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
    public static Map<String, String> getListViewConfig(String objectType, String listViewName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewConfig(' + objectType + ', ' + listViewName + ')');
        Map<String, String> configParams = new Map<String, String>();

        List<List_View_Config__c> configs = ListViewConfigHelper.getListViewConfig(objectType, listViewName);

        if (configs.size() == 0) return new Map<String, String>();

        List_View_Config__c config = configs[0];

        for (List_View_Config_Parameter__c param: config.List_View_Config_Parameters__r)
            configParams.put(param.Parameter_Name__c, param.Parameter_Value__c);         
        
        return configParams;
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
        b.execute(null);
	
		return 'success';
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

        //get the custom list view config
        Map<String, String> lvConfig = getListViewConfig(objectName, listViewName);

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
            rowData = handleRowsToWrapper(objectRows, listview, lvConfig, columnSortData);

            rowData.objName    = objectName;
            rowData.coreListId = listview.Core_ListView_Id__c;

        }
        return rowData;

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
            responseStr = 'Couldn\'t find action config for name provided!';
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
            responseStr = 'Couldn\'t find apex class "' + action.Apex_Class_Name__c + '" for config with name ' + action.Label__c;
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
        responseStr = actionJob.process(listStrIds, mapValues);

        return responseStr;
    }

    /*
        * Method to take a list of SObjects retrieved using a listviews query and convert the
        * rows into something that front end lightning components can handle.
        */
    private static RowsWrapper handleRowsToWrapper(List<SObject> dataRows, List_View__c listView, Map<String, String> lvConfig, List<ListViewHelper.ColumnSortData> sortData)
    {
        System.debug('Starting ListViewController.handleRowsToWrapper - ' + System.now().getTime());

        Map<String, ListViewHelper.ColumnSortData> sortDataByFieldName = new Map<String, ListViewHelper.ColumnSortData>();
        for (ListViewHelper.ColumnSortData columnData: sortData)
            sortDataByFieldName.put(columnData.fieldName, columnData);

        RowsWrapper rows = new RowsWrapper();
        
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

        System.debug('Checkpoint 1 ListViewController.handleRowsToWrapper - ' + System.now().getTime());

        //set the CUSTOM COLUMN meta data into the rows wrapper
        if (lvConfig.get('AdditionalFields') != null && dataRows.size() > 0)
        {
            //get the field names in a list
            List<String> fields = lvConfig.get('AdditionalFields').deleteWhitespace().split(',');

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

        System.debug('Checkpoint 2 ListViewController.handleRowsToWrapper - ' + System.now().getTime());

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
        }

        System.debug('Ending ListViewController.handleRowsToWrapper - ' + System.now().getTime());
        return rows;
    }

    //-----------------------------
    // INTERNAL CLASS
    //-----------------------------
    
    //class which wraps up an action
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

    //class which wraps up all the row data for sending to front end.
    public class RowsWrapper
    {
        public String objName;
        public String coreListId;
        public List<RowWrapper> rows;
        public List<FieldWrapper> fieldMetaData;
        
        public RowsWrapper()
        {
            rows = new List<RowWrapper>();
            fieldMetaData = new List<FieldWrapper>();
        }

        @AuraEnabled(cacheable=true)
        public Integer getRowCount()
        {
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

        //Example - https://simpli-list-view-dev-dev-ed.lightning.force.com/lightning/o/Account/list?filterName=00B3h000003ZfMQEA0
        @AuraEnabled(cacheable=true)
        public String getCoreListViewURL()
        {
            return URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/o/' + objName + '/list?filterName=' + coreListId;
        }
        
    }
    
    public class RowWrapper
    {

        public List<FieldWrapper> fields;
        public String rowId;

        public RowWrapper(String rowId)
        {
            this.rowId = rowId;
            fields = new List<FieldWrapper>();
        }

        public void addField(FieldWrapper field)
        {
            fields.add(field);
        }

        @AuraEnabled(cacheable=true)
        public List<FieldWrapper> getFields()
        {
            return fields;
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
    }

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