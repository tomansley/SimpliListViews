/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 03-25-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-04-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public without sharing class ListViewController
{

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
                status = jobs[0].Status;

            } else if (jobs[0].Status == 'Completed') { 
            
                result = '100';
                status = jobs[0].Status;

            } else { 

                Decimal percentComp = (Decimal.valueOf(jobs[0].JobItemsProcessed)/Decimal.valueOf(jobs[0].TotalJobItems)) * 100;
                result = String.valueOf(percentComp);
                status = jobs[0].Status;
                
            }
        } else {
            result = '-1';
        }

        System.debug(LoggingLevel.DEBUG, 'Finishing ListViewController.getListViewInitProgress with result - ' + result + ':' + status);
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
    public static ListViewAbstract.ListViewConfigWrapper getListViewConfig(String objectName, String listViewName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewConfig(' + objectName + ', ' + listViewName + ')');
        ListViewAbstract.ListViewConfigWrapper lvConfigWrapper = null;

        List_View__c listview = ListViewHelper.getListViews(objectName, listViewName).values()[0];

        String objType = null;
        if (listView.RecordTypeId == null || listView.RecordTypeId == ListViewHelper.coreRTId)
            objType = 'ListViewCore';
        else
            objType = listView.Custom_Apex_Class__c;

        //get an apex Type of the object type
        Type t = Type.forName(objType);

        //create a new instance
        ListViewAbstract lvLogic = (ListViewAbstract) t.newInstance();

        //set all request information into the apex processing class.
        lvlogic.setRequestData(listview);

        lvConfigWrapper = lvlogic.lvConfig;

        return lvConfigWrapper;
    }


    /**
    * @description Method which gets the users SORT configuration for the provided COMPONENT. The method manually creates
                   the JSON request as it makes it easier on the front end to handle. Here is an example JSON response - 
                   {"listviews": [{"name": "Account:Simpli_LV_Acct_1","fields": [{"sortIndex": "0", "fieldName": "Name", "sortDirection": "true"},{"sortIndex": "1", "fieldName": "BillingState", "sortDirection": "false"}]}, {"name": "Account:PlatinumandGoldSLACustomers","fields": [{"sortIndex": "0", "fieldName": "Name", "sortDirection": "true"},{"sortIndex": "1", "fieldName": "BillingState", "sortDirection": "false"},{"sortIndex": "2", "fieldName": "Id", "sortDirection": "false"}]}]}

    * @author tom.h.ansley@medtronic.com | 10-10-2020 
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

        return sortConfigJSON;
    }

    /**
    * @description Method which gets the users configuration for the provided COMPONENT.
    *              Note that this method also gets the org wide defaults
    * @author tom.h.ansley@medtronic.com | 10-10-2020 
    * @param compName the component name which is the name of the Lightning component that calls this method.
    * @return Map<String, String> 
    **/
    @AuraEnabled
    public static Map<String, String> getUserConfigs(String compName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getUserConfigs(' + compName + ')');
        Map<String, String> userConfigs = new Map<String, String>();

        //get the users component config
        Map<String, List_View_User_Config__c> configs = ListViewUserConfigHelper.getCurrentUserCompConfig(compName);
        for (List_View_User_Config__c config: configs.values())
            userConfigs.put(config.Name__c, config.Value__c);

        //get the org wide config
        List<List_View_Config__c> orgWideConfigs = ListViewConfigHelper.getListViewConfig('All', 'All');
        if (orgWideConfigs.size() == 1)
        {
            for (List_View_Config_Parameter__c param: orgWideConfigs[0].List_View_Config_Parameters__r)
                userConfigs.put(param.Parameter_Name__c, param.Parameter_Value__c);
        }

        for (String config: userConfigs.keySet())
            System.debug(LoggingLevel.DEBUG, config + ' - ' + userConfigs.get(config));
        
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
    public static List<SelectOption> getListViewsActions(String objectType, String listViewName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewsActions(' + objectType + ', ' + listViewName + ')');
        List<SelectOption> actionsOptions = new List<SelectOption>();

        List_View__c listview = ListViewHelper.getListViews(objectType, listViewName).values()[0];

        Map<String, List_View_Action__c> actions = ListViewActionHelper.getListViewActionsByListView(listview);

        for (String actionName: actions.keySet())
            actionsOptions.add(new SelectOption(actions.get(actionName).Primary_Key__c, actionName));         
    
        actionsOptions.sort();

        return actionsOptions;
    }

    @AuraEnabled(cacheable=true)
    public static ListViewAbstract.ActionWrapper getListViewAction(String actionName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.updateSingleListView(' + actionName + ')');

        ListViewAbstract.ActionWrapper wrapper = null;
        if (actionName != '')
        {

            List_View_Action__c action = null;
    
            try {
                action = ListViewActionHelper.getListViewActionByKey(actionName);
                wrapper = new ListViewAbstract.ActionWrapper(action);
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
    public static ListViewAbstract.RowsWrapper getListViewData(String pageName, String objectName, String listViewName, String sortData, String sortChanged, String joinFieldName, String joinData)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewController.getListViewData(' + pageName + ', ' + objectName + ', ' + listViewName + ',' + sortData + ',' + sortChanged + ',' + joinFieldName + ',' + joinData + ')');
        
        ListViewAbstract.RowsWrapper rowData                   = null;

        //------------------------------------------------------------------------------------------
        //JOIN INFORMATION
        //------------------------------------------------------------------------------------------
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
                    sortStr += columnData.getUserConfigString() + ';';
                }

                columnSortData.sort();
                sortStr = sortStr.removeEnd(';');

            }

            //------------------------------------------------------------------------------------------
            //LIST VIEW APEX CLASS CREATION AND PROCESSING
            //------------------------------------------------------------------------------------------
            String objType = null;
            if (listView.RecordTypeId == null || listView.RecordTypeId == ListViewHelper.coreRTId)
            {
                objType = 'ListViewCore';

            } else {
                
                objType = listView.Custom_Apex_Class__c;
            }

            //get an apex Type of the object type
            Type t = Type.forName(objType);

            //create a new instance
            ListViewAbstract lvLogic = (ListViewAbstract) t.newInstance();
    
            //set all request information into the apex processing class.
            lvlogic.setRequestData(listview, columnSortData, joinFieldName, joinRecordIds);

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
            if (sortChanged != null && sortChanged == 'true')
                ListViewUserConfigHelper.updateSortConfigValue(pageName, sortStr, objectName, listviewName);

        }
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

        //get the core SFDC list view data
        Map<Id, List_View__c> listViews = ListViewHelper.getListViews(objectName, listViewName);
        if (listViews.size() == 0) return new List<SelectOption>();
        List_View__c listView = listViews.values()[0];

        //-------------------------------------------------------------------
        String objType = null;
        if (listView.RecordTypeId == null || listView.RecordTypeId == ListViewHelper.coreRTId)
            objType = 'ListViewCore';
        else
            objType = listView.Custom_Apex_Class__c;

        //get an apex Type of the object type
        Type t = Type.forName(objType);

        //create a new instance
        ListViewAbstract lvLogic = (ListViewAbstract) t.newInstance();

        //set all request information into the apex processing class.
        lvlogic.setRequestData(listview);

        Map<String, String> labels = lvLogic.getColumnLabels();

        for (String fieldName: labels.keySet())
            labelOptions.add(new SelectOption(fieldName, labels.get(fieldName)));         
    
        labelOptions.sort();

        return labelOptions;
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