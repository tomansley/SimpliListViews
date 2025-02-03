/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-29-2025
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   07-07-2021   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewAdminController {

    public static final String SUCCESS = 'success';

    @AuraEnabled
    public static String clearCache()
    {
        String response = SUCCESS;

        CacheHelper.clearAllCache();

        return response;
    }

    @AuraEnabled
    public static String importConfigJSON(String configStr)
    {
        return ListViewHelper.importJSON(configStr);
    }

    /*
        System.debug(LoggingLevel.DEBUG, 'RESULT - ' + ListViewAdminController.getConfigExportJSON());
     */
    @AuraEnabled
    public static String getConfigExportJSON()
    {
        return ListViewHelper.exportJSON(ListViewHelper.TYPE_CUSTOM, true, true, true);
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
            ListViewErrorHelper.createFutureUsageError('The global config could not be created!'); 
            canCreate = false;
        }

        try {
            if (!canCreate) {
                ListViewHelper.insertCoreGlobalConfig();
                isCreated = true;
            }
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
                response = ListViewActionHelper.FAILED;

        } catch (Exception e) {
            response = ListViewActionHelper.FAILED;
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
            jobId = ListViewActionHelper.FAILED;
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

        ListViewAbstract.ListViewConfigWrapper config = new ListViewAbstract.ListViewConfigWrapper(null, orgWideConfig, params, 'App Page', null);

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

        String result = ListViewConfigHelper.setOrgWideParams(mapValues);

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

    @AuraEnabled
    public static String createAction(String actionFields)
    {
        System.debug(LoggingLevel.FINE, 'Starting ListViewAdminController.createAction(' + actionFields + ')');
        String debug = '\n\n----- Action Create Request -----\n';
        String response = '';

        List<Object> untypesValues = (List<Object>) JSON.deserializeUntyped(actionFields);
        Map<String, String> actionValues = new Map<String, String>();
        for (Object untypedValue: untypesValues)
        {
            List<Object> values = (List<Object>) untypedValue;
            String fieldName = (String) values[0];
            if (fieldName != 'actionUserPermissions')
            {
                actionValues.put(fieldName, (String) values[1]);
                debug += fieldName + ' - ' + (String) values[1] + '\n';
            } else {
                if (values[1] instanceof List<Object>)
                {
                    String fieldValue = HelperString.getStringFromList((List<Object>) values[1], ';');
                    actionValues.put(fieldName, fieldValue);
                    debug += fieldName + ' - ' + fieldValue + '\n';
                } 
            }
        }

        response = ListViewActionHelper.createAction(actionValues);
        
        System.debug(LoggingLevel.FINE, debug);
        ListViewErrorHelper.addLog('ListViewAdminController(createAction)', debug + '\n\n' + response);

        return response;
    }

}