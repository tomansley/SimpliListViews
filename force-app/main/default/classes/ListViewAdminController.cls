/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 12-07-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   07-07-2021   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewAdminController {
    
    public static final String SUCCESS = 'success';
    public static final String FAILED = 'failed';

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

        ListViewAbstract.ListViewConfigWrapper config = new ListViewAbstract.ListViewConfigWrapper(null, orgWideConfig, params);

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