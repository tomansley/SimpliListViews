/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   07-07-2021   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewAdminController {
    
    @AuraEnabled
    public static ListViewAbstract.ListViewConfigWrapper getOrgWideConfig()
    {
        //get the org wide config
        List_View_Config__c orgWideConfig = ListViewConfigHelper.getListViewConfig('All', 'All');

        List<List_View_Config_Parameter__c> params = new List<List_View_Config_Parameter__c>();
        for (List_View_Config_Parameter__c param: orgWideConfig.List_View_Config_Parameters__r)
            params.add(param);

        ListViewAbstract.ListViewConfigWrapper config = new ListViewAbstract.ListViewConfigWrapper(null, orgWideConfig, params);

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

        return objNames;
    }

}