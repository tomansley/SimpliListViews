/**
 * @File Name          : ListViewConfigHelper.cls
 * @Description        : 
 * @Author             : tom.h.ansley@medtronic.com
 * @Group              : 
 * @Last Modified By   : tom.h.ansley@medtronic.com
 * @Last Modified On   : 6/11/2020, 8:35:27 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/11/2020   tom.h.ansley@medtronic.com     Initial Version
**/
public with sharing class ListViewConfigHelper {

    public static Map<String,Object> orgWideConfig = null;

    public static void setOrgWideConfig(String settingName, String value)
    {
        populateOrgWideConfig();

        List<List_View_Config__c> configs = getListViewConfig('All', 'All');
        if (configs.size() == 0)
        {
            String message = 'Org wide list view config could not be retrieved';
            ListViewErrorHelper.createUsageError(message);
            throw new ListViewConfigHelperException(message);
        }

        for (List_View_Config_Parameter__c param: configs[0].List_View_Config_Parameters__r)
        {
            if (param.Parameter_Name__c == settingName)
            {
                //update database
                param.Parameter_Value__c = value;

                HelperSchema.checkObjectUpdateable('List_View_Config_Parameter__c');

                update param;

                //update cache
                orgWideConfig.put(settingName, value);

                break;
            }
        }

    }

    /*
     * Method to populate the cache.
     */
    public static void populateOrgWideConfig() 
    {
        if (orgWideConfig == null)
        {

            orgWideConfig = new Map<String,Object>();

            List<List_View_Config__c> configs = getListViewConfig('All', 'All');
            if (configs.size() == 0)
            {
                String message = 'Org wide list view config could not be retrieved';
                ListViewErrorHelper.createUsageError(message);
                throw new ListViewConfigHelperException(message);
            }

            for (List_View_Config_Parameter__c param: configs[0].List_View_Config_Parameters__r)
                orgWideConfig.put(param.Parameter_Name__c, param.Parameter_Value__c);
        }

    }

    /*
     * Method to get all config for the org.
     */
    public static String getOrgWideConfig(String settingName)
    {
        populateOrgWideConfig();

        return (String) orgWideConfig.get(settingName);
    }
    
    public static List<List_View_Config__c> getListViewConfig(String objectType, String listViewName) 
    {
        return [SELECT Name,
                       List_View_Object__c,
                       (SELECT Parameter_Name__c,
                               Parameter_Type__c,
                               Parameter_Value__c
                        FROM List_View_Config_Parameters__r)
                FROM List_View_Config__c
                WHERE Name = :listViewName
                    AND List_View_Object__c = :objectType];
    }

	public class ListViewConfigHelperException extends Exception { }

}