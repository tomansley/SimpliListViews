/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-14-2022
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   07-07-2021   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewAdminController {
    
    public static final String SUCCESS = 'success';
    public static final String FAILED = 'failed';

    @AuraEnabled
    public static String importConfigJSON(String configStr)
    {
        String response = '';
        String debug = '\n\n----- Import Response -----\n';

        try {
            System.debug(LoggingLevel.FINE, 'Starting ListViewAdminController.importConfigJSON(' + configStr + ')');

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
                                oldParam.Parameter_Value__c = 'false';
                            
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
            log.Subtype__c       = 'ListViewAdminController(importConfigJSON)';
            HelperDatabase.insertRecord(log);
            response = 'There was an error importing the data. Please see the logs for more details - ' + message;
        }

        List_View_Error__c log   = new List_View_Error__c();
        log.Running_User__c  = UserInfo.getUserId();
        log.Message__c       = debug;
        log.Type__c          = ListViewErrorHelper.TYPE_LOG;
        log.Subtype__c       = 'ListViewAdminController(importConfigJSON)';
        HelperDatabase.insertRecord(log);

        return response;
    }

    /*
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + ListViewAdminController.getConfigExportJSON());
     */
    @AuraEnabled
    public static String getConfigExportJSON(){
        String jsonStr = '';
        
        //the thing we will stuff all objects into and then JSONify!
        Map<String, List<SObject>> objects = new Map<String, List<SObject>>();

        //1. List Views where record type is custom
        Map<Id, List_View__c> listviews = ListViewHelper.getListViewsByType(ListViewHelper.TYPE_CUSTOM, false);
        objects.put('ListViews', listviews.values());

        Set<String> primaryKeys = new Set<String>();
        primaryKeys.add('All:All');
        for (List_View__c listview: listviews.values())
            primaryKeys.add(ListViewHelper.getPrimaryKey(listview));

        //2. All configs for the custom list views and the global configs
        Map<String, List_View_Config__c> configs = ListViewConfigHelper.getListViewConfigs(primaryKeys);
        objects.put('ListViewConfigs', configs.values());

        //3. All actions
        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        objects.put('Actions', actions);

        jsonStr = JSON.serialize(objects);

        return jsonStr;
    }

    @AuraEnabled
    public static Boolean createGlobalConfig()
    {
        Boolean isCreated = false;
        Boolean canCreate = false;        
        //first we try to get the config as we do not want to create the config twice
        try {
            getOrgWideConfig();
        } catch (Exception e) {
            canCreate = true;
        }

        if (!canCreate)
            throw new ListViewException('global config already exists!');
        
        try {

            ListViewHelper.insertCoreGlobalConfig();
            isCreated = true;
        } catch (Exception e) {
            throw new ListViewException(ListViewException.getExtendedString(e));
        }

        return isCreated;
    }

    @AuraEnabled
    public static String scheduleRefreshJob()
    {
        String response = SUCCESS;

        try {

            Boolean result = HelperScheduler.scheduleRefreshJob();

            if (!result)
                response = FAILED;

        } catch (Exception e) {
            response = FAILED;
        }

        return response;
    }

	@AuraEnabled
	public static String cleanListViews()
	{
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewAdminController.cleanListViews()');

        Simpli_lv.ListViewCleanBatch b = new Simpli_lv.ListViewCleanBatch();
        
        Id jobId = null;
        
        try {
            jobId = Database.executebatch(b, 40);
        } catch (Exception e) {
            jobId = FAILED;
            String message = 'Exception during ListViewAdminController.cleanListViews()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
        }

        ListViewErrorHelper.processLogs(true);

        return jobId;
	}

    @AuraEnabled
    public static ListViewAbstract.ListViewParam getOrgWideConfigParam(String paramName)
    {
        //get the org wide config
        ListViewAbstract.ListViewConfigWrapper config = getOrgWideConfig();

        ListViewAbstract.ListViewParam param = config.getParameter(paramName);

        ListViewErrorHelper.processLogs(true);

        return param;
    }

    @AuraEnabled
    public static ListViewAbstract.ListViewConfigWrapper getOrgWideConfig()
    {
        //get the org wide config
        List_View_Config__c orgWideConfig = ListViewConfigHelper.getListViewConfig('All', 'All');

        List<List_View_Config_Parameter__c> params = new List<List_View_Config_Parameter__c>();
        for (List_View_Config_Parameter__c param: orgWideConfig.List_View_Config_Parameters__r)
            params.add(param);

        ListViewAbstract.ListViewConfigWrapper config = new ListViewAbstract.ListViewConfigWrapper(null, orgWideConfig, params, 'App Page');

        ListViewErrorHelper.processLogs(true);

        return config;
    }

    @AuraEnabled
    public static String saveOrgWideConfig(String paramStr)
    {
        List<Object> listValues = (List<Object>) JSON.deserializeUntyped(paramStr);
        Map<String, Object> mapValues = new Map<String, Object>();
        for (Object key: listValues)
        {
            List<Object> keyValues = (List<Object>) key;
            mapValues.put( (String) keyValues[0], keyValues[1]);
        }

        String result = ListViewConfigHelper.updateOrgWideParams(mapValues);

        ListViewErrorHelper.processLogs(true);

        return 'Ok:';
    }

    @AuraEnabled(cacheable=true)
    public static List<ListViewController.SelectOption> getObjectNames()
    {
        System.debug(LoggingLevel.FINE, 'Starting ListViewAdminController.getObjectNames()');
        List<ListViewController.SelectOption> objNames = new List<ListViewController.SelectOption>();

        Map<String, String> objMap = HelperSchema.getAllObjectNames();

        for (String obj: objMap.keySet())
            objNames.add(new ListViewController.SelectOption(obj, objMap.get(obj)));         
    
        objNames.sort();

        ListViewErrorHelper.processLogs(true);

        return objNames;
    }

}