/**
 * @File Name          : ListViewConfigHelper.cls
 * @Description        : 
 * @Author             : tom.h.ansley@medtronic.com
 * @Group              : 
 * @Last Modified By   : tom.h.ansley@medtronic.com
 * @Last Modified On   : 11-05-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/11/2020   tom.h.ansley@medtronic.com     Initial Version
**/
public with sharing class ListViewConfigHelper {

    private static Map<String,Object> orgWideConfigParams           = null;
    private static List_View_Config__c orgWideConfig                = null;

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
            throw new ListViewException(message);
        }

        for (List_View_Config_Parameter__c param: configs[0].List_View_Config_Parameters__r)
        {
            if (param.Parameter_Name__c == settingName)
            {
                //update database
                param.Parameter_Value__c = value;

                //bug fix to stop failures during auto updates of params without labels.
                if (param.Parameter_Label__c == null)
                    param.Parameter_Label__c = param.Parameter_Name__c;

                HelperDatabase.updateRecord(param, 'Simpli_lv__List_View_Config_Parameter__c');

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
                throw new ListViewException(message);
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

    public static String updateListViewParam(String objectName, String listViewName, String paramName, String paramValue, String paramLabel, String paramType)
    {

        System.debug(LoggingLevel.DEBUG, 'Starting updateListViewParam(' + objectName + ', ' + listViewName + ', ' + paramName + ', ' + paramValue + ')');

        String errorStr = ListViewConfigHelper.validateParameter(objectName, listViewName, paramName, paramValue);

        if (errorStr == '')
        {

            HelperSchema.checkListViewConfigsAccessible();

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

                List_View_Config__c config = getListViewConfig(objectName, listViewName)[0];
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = config.Id;
                param.Parameter_Name__c   = paramName;
                param.Parameter_Type__c   = paramType;
                param.Parameter_Value__c  = paramValue;
                param.Parameter_Label__c  = paramLabel;
                params.add(param);
        
                //throw new ListViewException('No parameter with provided list view name, object name and parameter name found - ' + listViewName + ', ' + objectName + ', ' + paramName);

            }

            HelperDatabase.upsertRecords(params, 'Simpli_lv__List_View_Config_Parameter__c');

            System.debug(LoggingLevel.DEBUG, 'Finished upserting param!');

        }

        return errorStr;
        
    }

    public static void addListViewCondition(String objectName, String listViewName, String fieldName, String fieldOperator, String fieldValue, String fieldOrder, String fieldColor)
    {

        //get the list view config for the parameter
        List<List_View_Config__c> lvConfig = getListViewConfig(objectName, listViewName);

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = fieldName;
        condition.Highlight_Color__c  = fieldColor;
        condition.Operator__c         = fieldOperator;
        condition.Order__c            = fieldOrder;
        condition.Value__c            = fieldValue;
        condition.List_View_Config__c = lvConfig[0].Id;

        HelperDatabase.insertRecord(condition, 'simpli_lv__List_View_Config_Condition__c');
    }

    public static void deleteListViewCondition(String id)
    {
        System.debug(LoggingLevel.DEBUG, 'Deleting list view condition - ' + id);

        HelperSchema.checkListViewConfigsAccessible();

        List<List_View_Config_Condition__c> conditions = [SELECT Id 
                                                          FROM List_View_Config_Condition__c
                                                          WHERE Id = :id];

        HelperDatabase.deleteRecords(conditions, 'simpli_lv__List_View_Config_Condition__c');

    }
    
    /*
     * Method to retrieve the latest list view configuration. The method first looks at the cache
     * to see if it has already been retrieved. If not it goes and gets it. After retrieving it then
     * checks against default configuration params to ensure all values have been set appropriately
     */
    public static List<List_View_Config__c> getListViewConfig(String objectName, String listViewName) 
    {
        System.debug(LoggingLEvel.DEBUG, 'Starting getListViewConfig(' + objectName + ', ' + listViewName + ')');

        List<List_View_Config__c> configs = new List<List_View_Config__c>();

        HelperSchema.checkListViewConfigsAccessible();

        configs = [SELECT Name,
                            List_View_Object__c,
                            LastModifiedDate,
                            LastModifiedBy.Name,
                            Primary_Key__c,
                            (SELECT Parameter_Name__c,
                                    Parameter_Type__c,
                                    Parameter_Label__c,
                                    Parameter_Value__c
                            FROM List_View_Config_Parameters__r
                            ORDER BY Parameter_Label__c),
                            (SELECT Field_Name__c,
                                        Highlight_Color__c,
                                        Operator__c,
                                        Order__c,
                                        Value__c
                            FROM List_View_Config_Conditions__r
                            ORDER BY Order__c ASC)
                FROM List_View_Config__c
                        WHERE Name = :listViewName
                            AND List_View_Object__c = :objectName];

        if (configs.size() > 1)
            throw new ListViewException('Found more than one list view config with name - ' + listViewName + ' and object - ' + objectName);

        System.debug(LoggingLevel.DEBUG, 'Returning configs - ' + configs);
        return configs;
    }

    public static String getPrimaryKey(String objectName, String listViewName)
    {
        return objectName.replace(' ', '_') + ':' + listViewName;
    }

    public static Map<String, List_View_Config__c> getListViewConfigs(Set<String> primaryKeys) 
    {
        List<List_View_Config__c> configs = [SELECT Name,
                                                List_View_Object__c,
                                                LastModifiedDate,
                                                LastModifiedBy.Name,
                                                Primary_Key__c,
                                                (SELECT Parameter_Name__c,
                                                        Parameter_Type__c,
                                                        Parameter_Label__c,
                                                        Parameter_Value__c
                                                FROM List_View_Config_Parameters__r
                                                ORDER BY Parameter_Label__c),
                                                (SELECT Field_Name__c,
                                                            Highlight_Color__c,
                                                            Operator__c,
                                                            Order__c,
                                                            Value__c
                                                FROM List_View_Config_Conditions__r
                                                ORDER BY Order__c ASC)
                                    FROM List_View_Config__c
                                            WHERE Primary_Key__c IN :primaryKeys];

        Map<String, List_View_Config__c> mappedConfigs = new Map<String, List_View_Config__c>();
        for (List_View_Config__c config: configs)
        {
            mappedConfigs.put(getPrimaryKey(config.List_View_Object__c, config.Name), config);
        }

        return mappedConfigs;

    }

    public static String getParameterDescription(String name)
    {
        String descr = '';

        if (name == 'AdditionalFields') descr = 'String holding the additional API field names that should be returned in the list view data (comma delimited).';
        else if (name == 'RefreshRate') descr = 'The number of seconds between refreshes if the list view can be auto refreshed.';
        else if (name == 'ReturnSize') descr = 'The maximum number of rows of data that can be returned. Note that org and list view configuration takes precedence.';
        else if (name == 'TotalColumns') descr = 'String holding the API field names of the columns within the list view that should have a total in the footer.';
        else if (name == 'TotalColumnsColor') descr = 'The HTML color that the footer row should be displayed in. i.e. #E5F0FA.';
        else if (name == 'AllRows') descr = 'Indicates whether deleted and archived records should be included in list view results.';
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
            if (paramValue != '')
            {

                try {

                    //check security on object
                    HelperSchema.checkObjectAccessible(objectName);

                    //get the list view
                    List_View__c listview = ListViewHelper.getListViews(objectName, listViewName).values()[0];
            
                    //get the list views query
                    String query = listview.Core_ListView_Query__c;

                    //get the fields on the SELECT
                    String selectStr = query.substringBetween('SELECT ', ' FROM ');

                    //check all added fields for security
                    List<String> allFields = paramValue.split(',');
                    for (String field: allFields)
                    {
                        //do security validation on additional fields. If the field is a lookup the security is performed later
                        if (!field.contains('.'))
                            HelperSchema.checkObjectFieldAccessible(objectName, field);
                    }
        
                    selectStr += ', ' + paramValue;
            
                    String soql = 'SELECT ' + selectStr + ' FROM ' + objectName + ' LIMIT 1';

                    System.debug(LoggingLevel.DEBUG, 'Param Validation SOQL - ' + soql);

                    List<SObject> result = Database.query(soql);

                } catch (Exception e) {
                    error = 'The additional fields are invalid. Please ensure syntax is correct, there are no duplicate fields, and the names are valid API field names - ' + e.getMessage();
                }
            }
        }

        return error;
    }

    /**
    * @description Method to validate a condition given an object being validated against and
    * a condition. The return of an HTML color indicates the condition yielded a result. If no
    * color was returned the value did meet any criteria.
    * @author tom.h.ansley@medtronic.com | 08-05-2020 
    * @param value the value being validated against
    * @param conditions the conditions the value is being validated against
    * @return String either an HTML color (condition match) or empty string (condition not met) 
    **/
    public static String validateFieldCondition(Object value, List<List_View_Config_Condition__c> conditions)
    {

        System.debug(LoggingLevel.DEBUG, 'STARTING validateFieldCondition with value - ' + value);
        System.debug(LoggingLevel.DEBUG, 'Conditions - ' + conditions);

        if (value == null || conditions == null || conditions.size() == 0) return '';
    
        for (List_View_Config_Condition__c condition: conditions)
        {
            System.debug(LoggingLevel.DEBUG, 'Value     = ' + value);
            System.debug(LoggingLevel.DEBUG, 'Operator  = ' + condition.Operator__c);
            System.debug(LoggingLevel.DEBUG, 'condValue = ' + condition.Value__c);

            if (condition.Operator__c == OPER_EQUAL) {
                if (value == condition.Value__c) return condition.Highlight_Color__c;
            } else if (condition.Operator__c == OPER_NOT_EQUAL) {
                if (value != condition.Value__c) return condition.Highlight_Color__c;
            } else if (condition.Operator__c == OPER_GREATER) {
                Decimal inputValue = Decimal.valueOf(String.valueOf(value));
                Decimal condValue = Decimal.valueOf(condition.Value__c);
                if (inputValue > condValue) return condition.Highlight_Color__c;
            } else if (condition.Operator__c == OPER_LESS) {
                Decimal inputValue = Decimal.valueOf(String.valueOf(value));
                Decimal condValue = Decimal.valueOf(condition.Value__c);
                if (inputValue < condValue) return condition.Highlight_Color__c;
            } else if (condition.Operator__c == OPER_CONTAINS) {
                if (((String) value).contains((String) condition.Value__c)) return condition.Highlight_Color__c;
            }

        }

        return '';
    }
    
    public class ListViewConfigDefault
    {
        public String name  {get; set;}
        public String label {get; set;}
        public String type  {get; set;}
        public String value {get; set;}
        public String description {get; set;}
    }

}