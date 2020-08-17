/**
 * @File Name          : ListViewConfigHelper.cls
 * @Description        : 
 * @Author             : tom.h.ansley@medtronic.com
 * @Group              : 
 * @Last Modified By   : tom.h.ansley@medtronic.com
 * @Last Modified On   : 08-17-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/11/2020   tom.h.ansley@medtronic.com     Initial Version
**/
public with sharing class ListViewConfigHelper {

    private static Map<String,Object> orgWideConfigParams           = null;
    private static List_View_Config__c orgWideConfig                = null;
    private static Map<String, List_View_Config__c> listViewConfigs = new Map<String, List_View_Config__c>();

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

    public static String updateListViewParam(String objectName, String listViewName, String paramName, String paramValue)
    {

        System.debug(LoggingLevel.DEBUG, 'Starting updateListViewParam(' + objectName + ', ' + listViewName + ', ' + paramName + ', ' + paramValue + ')');

        String errorStr = ListViewConfigHelper.validateParameter(objectName, listViewName, paramName, paramValue);

        if (errorStr == '')
        {

            List<List_View_Config_Parameter__c> params = [SELECT Parameter_Name__c,
                                                            Parameter_Type__c,
                                                            Parameter_Value__c
                                                    FROM List_View_Config_Parameter__c
                                                    WHERE List_View_Config__r.Name = :listViewName
                                                        AND List_View_Config__r.List_View_Object__c = :objectName
                                                        AND Parameter_Name__c = :paramName];

            //if we have a parameter
            if (params.size() > 0)
            {
                System.debug(LoggingLevel.DEBUG, 'Param found - ' + params[0]);

                params[0].Parameter_Value__c = paramValue;
            
            //we have no parameter so we need to create one
            } else {

                System.debug(LoggingLevel.DEBUG, 'Creating param as nothing found');

                //get the list view config for the parameter
                List<List_View_Config__c> lvConfig = getListViewConfig(objectName, listViewName);
                
                //get the defaults for the parameters
                ListViewConfigDefaults defaults = new ListViewConfigDefaults();

                //create the parameter
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.Parameter_Name__c = paramName;
                param.Parameter_Value__c = paramValue;
                param.List_View_Config__c = lvConfig[0].Id;
                param.Parameter_Type__c = defaults.params.get(paramName).type;

                System.debug(LoggingLevel.DEBUG, 'Param created - ' + param);

                params.add(param);

            }

            upsert params;

            System.debug(LoggingLevel.DEBUG, 'Finished upserting param!');

        }

        return errorStr;
        
    }

    public static void addListViewCondition(String objectType, String listViewName, String fieldName, String fieldOperator, String fieldValue, String fieldOrder, String fieldColor)
    {
        //get the list view config for the parameter
        List<List_View_Config__c> lvConfig = getListViewConfig(objectType, listViewName);

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = fieldName;
        condition.Highlight_Color__c  = fieldColor;
        condition.Operator__c         = fieldOperator;
        condition.Order__c            = fieldOrder;
        condition.Value__c            = fieldValue;
        condition.List_View_Config__c = lvConfig[0].Id;

        insert condition;
    }

    public static void deleteListViewCondition(String id)
    {
        System.debug(LoggingLevel.DEBUG, 'Deleting list view condition - ' + id);
        delete [SELECT Id 
                FROM List_View_Config_Condition__c
                WHERE Id = :id];
    }
    
    /*
     * Method to retrieve the latest list view configuration. The method first looks at the cache
     * to see if it has already been retrieved. If not it goes and gets it. After retrieving it then
     * checks against default configuration params to ensure all values have been set appropriately
     */
    public static List<List_View_Config__c> getListViewConfig(String objectType, String listViewName) 
    {

        List<List_View_Config__c> configs = new List<List_View_Config__c>();

        List_View_Config__c config = listViewConfigs.get(objectType + ':' + listViewName);

        if (config == null)
        {

            HelperSchema.checkObjectAccessible('List_View_Config__c');
            HelperSchema.checkObjectAccessible('List_View_Config_Parameter__c');
            HelperSchema.checkObjectAccessible('List_View_Config_Condition__c');

            configs = [SELECT Name,
                                List_View_Object__c,
                                LastModifiedDate,
                                LastModifiedBy.Name,
                                (SELECT Parameter_Name__c,
                                        Parameter_Type__c,
                                        Parameter_Value__c
                                FROM List_View_Config_Parameters__r
                                ORDER BY Parameter_Name__c),
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

        } else {
            configs.add(config);
        }

        return configs;
    }

    public static String getParameterDescription(String name)
    {
        String descr = '';

        if (name == 'AdditionalFields') descr = 'String holding the additional API field names that should be returned in the list view data (comma delimited).';
        else if (name == 'RefreshRate') descr = 'The number of seconds between refreshes if the list view can be auto refreshed.';
        else if (name == 'ReturnSize') descr = 'The maximum number of rows of data that can be returned. Note that org and list view configuration takes precedence.';
        else if (name == 'TotalColumns') descr = 'String holding the API field names of the columns within the list view that should have a total in the footer.';
        else if (name == 'TotalColumnsColor') descr = 'The HTML color that the footer row should be displayed in. i.e. #E5F0FA.';
        return descr;
    }

    /**
    * @description Method to validate parameter updates
    * @author tom.h.ansley@medtronic.com | 08-17-2020 
    * @param paramName the name of the parameter being updated
    * @param paramValue the value the parameter is being updated to
    * @return String the error message if the parameter is invalid.
    **/
    public static String validateParameter(String objectName, String listViewName, String paramName, String paramValue)
    {
        String error = '';

        if (paramName == 'RefreshRate')
        {

            try {
                Integer rate = Integer.valueOf(paramValue);

                if (rate < 10 || rate > 500)
                {
                    error = 'Refresh rate must be between 10 and 500';
                }
            } catch (Exception e) {
                error = 'Refresh rate must be an integer value';
            }

        } else if (paramName == 'ReturnSize')
        {
            try {
                Integer size = Integer.valueOf(paramValue);

                if (size > 500)
                {
                    error = 'Return size must be less than 500';
                }
            } catch (Exception e) {
                error = 'Return size must be an integer value';
            }


        } else if (paramName == 'TotalColumns')
        {
        } else if (paramName == 'AdditionalFields')
        {
            String soql = 'SELECT ' + paramValue + ' FROM ' + objectName + ' LIMIT 1';

            try {
                List<SObject> result = Database.query(soql);
            } catch (Exception e) {
                error = 'There was an error testing the additional fields. Please ensure the names are valid API field names - ' + e.getMessage();
            }
        }

        return error;
    }

    /**
    * @description Method to validate a condition given an object being validated against and
    * a condition.
    * @author tom.h.ansley@medtronic.com | 08-05-2020 
    * @param value 
    * @param condition 
    * @return Boolean 
    **/
    public static String validateFieldCondition(Object value, List<List_View_Config_Condition__c> conditions)
    {

        System.debug(LoggingLevel.DEBUG, 'STARTING validateFieldCondition with value - ' + value);
        System.debug(LoggingLevel.DEBUG, 'Conditions - ' + conditions);

        if (value == null || conditions == null || conditions.size() == 0) return '';

        String valueStr = String.valueOf(value);
    
        for (List_View_Config_Condition__c condition: conditions)
        {
            System.debug(LoggingLevel.DEBUG, 'ValueStr        = ' + valueStr);
            System.debug(LoggingLevel.DEBUG, 'Operator        = ' + condition.Operator__c);
            System.debug(LoggingLevel.DEBUG, 'Condition Value = ' + condition.Value__c);

            if (condition.Operator__c == OPER_EQUAL) {
                if (valueStr == condition.Value__c) return condition.Highlight_Color__c;
            } else if (condition.Operator__c == OPER_NOT_EQUAL) {
                if (valueStr != condition.Value__c) return condition.Highlight_Color__c;
            } else if (condition.Operator__c == OPER_GREATER) {
                if (valueStr > condition.Value__c) return condition.Highlight_Color__c;
            } else if (condition.Operator__c == OPER_LESS) {
                if (valueStr < condition.Value__c) return condition.Highlight_Color__c;
            } else if (condition.Operator__c == OPER_CONTAINS) {
                if (valueStr.contains(condition.Value__c)) return condition.Highlight_Color__c;
            }

        }

        return '';
    }

    public class ListViewConfigHelperException extends Exception { }
    
    public class ListViewConfigDefaults
    {
        public Map<String, ListViewConfigDefault> params {get; set;}

        public ListViewConfigDefaults()
        {
            params = new Map<String, ListViewConfigDefault>();

            ListViewConfigDefault defaultConfig = new ListViewConfigDefault();
            defaultConfig.name        = 'AdditionalFields';
            defaultConfig.type        = 'String';
            defaultConfig.value       = '';
            defaultConfig.description = 'String holding the additional API field names that should be returned in the list view data (comma delimited).';
    
            params.put(defaultConfig.name, defaultConfig);

            defaultConfig = new ListViewConfigDefault();
            defaultConfig.name        = 'ReturnSize';
            defaultConfig.type        = 'Number';
            defaultConfig.value       = '100';
            defaultConfig.description = 'The maximum number of rows of data that can be returned. Note that org and list view configuration takes precedence.';

            params.put(defaultConfig.name, defaultConfig);

            defaultConfig = new ListViewConfigDefault();
            defaultConfig.name        = 'RefreshRate';
            defaultConfig.type        = 'Number';
            defaultConfig.value       = '30';
            defaultConfig.description = 'The number of seconds between refreshes if the list view can be auto refreshed.';

            params.put(defaultConfig.name, defaultConfig);

            defaultConfig = new ListViewConfigDefault();
            defaultConfig.name        = 'TotalColumns';
            defaultConfig.type        = 'String';
            defaultConfig.value       = '';
            defaultConfig.description = 'String holding the columns within the list view that should have a total in the footer.';

            params.put(defaultConfig.name, defaultConfig);

            defaultConfig = new ListViewConfigDefault();
            defaultConfig.name        = 'TotalColumnsColor';
            defaultConfig.type        = 'Color';
            defaultConfig.value       = '#E5F0FA';
            defaultConfig.description = 'The HTML color that the footer row should be displayed in. i.e. #E5F0FA.';

            params.put(defaultConfig.name, defaultConfig);

        }
    }

    public class ListViewConfigDefault
    {
        public String name  {get; set;}
        public String type  {get; set;}
        public String value {get; set;}
        public String description {get; set;}
    }

}