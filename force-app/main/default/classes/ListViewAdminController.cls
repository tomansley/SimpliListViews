/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 07-18-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-07-2021   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewAdminController {
    
    @AuraEnabled
    public static ListViewAbstract.ListViewConfigWrapper getOrgWideConfig()
    {
        //get the org wide config
        List<List_View_Config__c> orgWideConfigs = ListViewConfigHelper.getListViewConfig('All', 'All');

        List_View_Config__c orgWideConfig = orgWideConfigs[0];

        List<List_View_Config_Parameter__c> params = new List<List_View_Config_Parameter__c>();
        for (List_View_Config_Parameter__c param: orgWideConfig.List_View_Config_Parameters__r)
            params.add(param);

        ListViewAbstract.ListViewConfigWrapper config = new ListViewAbstract.ListViewConfigWrapper(orgWideConfig, params);

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
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewAdminController.getObjectNames()');
        List<ListViewController.SelectOption> objNames = new List<ListViewController.SelectOption>();

        Map<String, String> objMap = HelperSchema.getAllObjectNames();

        for (String obj: objMap.keySet())
            objNames.add(new ListViewController.SelectOption(obj, objMap.get(obj)));         
    
        objNames.sort();

        return objNames;
    }

}