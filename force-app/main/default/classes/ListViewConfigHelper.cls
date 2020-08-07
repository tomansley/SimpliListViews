/**
 * @File Name          : ListViewConfigHelper.cls
 * @Description        : 
 * @Author             : tom.h.ansley@medtronic.com
 * @Group              : 
 * @Last Modified By   : tom.h.ansley@medtronic.com
 * @Last Modified On   : 08-06-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/11/2020   tom.h.ansley@medtronic.com     Initial Version
**/
public with sharing class ListViewConfigHelper {

    private static Map<String,Object> orgWideConfigParams = null;
    private static List_View_Config__c orgWideConfig      = null;

    public static final String OPER_EQUAL = 'Equals';
    public static final String OPER_NOT_EQUAL = 'Not Equal';
    public static final String OPER_GREATER = 'Greater Than';
    public static final String OPER_LESS = 'Less Than';
    public static final String OPER_CONTAINS = 'Contains';

    public static void setOrgWideConfigParam(String settingName, String value)
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
                orgWideConfigParams.put(settingName, value);

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

            orgWideConfigParams = new Map<String,Object>();

            List<List_View_Config__c> configs = getListViewConfig('All', 'All');
            if (configs.size() == 0)
            {
                String message = 'Org wide list view config could not be retrieved';
                ListViewErrorHelper.createUsageError(message);
                throw new ListViewConfigHelperException(message);
            }

            orgWideConfig = configs[0];

            for (List_View_Config_Parameter__c param: configs[0].List_View_Config_Parameters__r)
                orgWideConfigParams.put(param.Parameter_Name__c, param.Parameter_Value__c);
        }

    }

    /*
     * Method to get all config for the org.
     */
    public static String getOrgWideConfigParam(String settingName)
    {
        populateOrgWideConfig();

        return (String) orgWideConfigParams.get(settingName);
    }
    
    public static List<List_View_Config__c> getListViewConfig(String objectType, String listViewName) 
    {
        HelperSchema.checkObjectAccessible('List_View_Config__c');

        return [SELECT Name,
                       List_View_Object__c,
                       (SELECT Parameter_Name__c,
                               Parameter_Type__c,
                               Parameter_Value__c
                        FROM List_View_Config_Parameters__r),
                        (SELECT Field_Name__c,
                                Highlight_Color__c,
                                Operator__c,
                                Order__c,
                                Value__c
                 FROM List_View_Config_Conditions__r
                 ORDER BY Order__c ASC)
         FROM List_View_Config__c
                WHERE Name = :listViewName
                    AND List_View_Object__c = :objectType];
    }

    /**
    * @description Method to validate a condition given an object being validated against and
    * a condition.
    * @author tom.h.ansley@medtronic.com | 08-05-2020 
    * @param value 
    * @param condition 
    * @return Boolean 
    **/
    public static Boolean validateFieldCondition(Object value, List_View_Config_Condition__c condition)
    {
        if (value == null || condition == null) return false;

        String valueStr = String.valueOf(value);
    
        System.debug(LoggingLevel.DEBUG, 'ValueStr        = ' + valueStr);
        System.debug(LoggingLevel.DEBUG, 'Operator        = ' + condition.Operator__c);
        System.debug(LoggingLevel.DEBUG, 'Condition Value = ' + condition.Value__c);

        if (condition.Operator__c == OPER_EQUAL) {
            if (valueStr == condition.Value__c) return true;
        } else if (condition.Operator__c == OPER_NOT_EQUAL) {
            if (valueStr != condition.Value__c) return true;
        } else if (condition.Operator__c == OPER_GREATER) {
            if (valueStr > condition.Value__c) return true;
        } else if (condition.Operator__c == OPER_LESS) {
            if (valueStr < condition.Value__c) return true;
        } else if (condition.Operator__c == OPER_CONTAINS) {
            if (valueStr.contains(condition.Value__c)) return true;
        }
        return false;
    }

	public class ListViewConfigHelperException extends Exception { }

}