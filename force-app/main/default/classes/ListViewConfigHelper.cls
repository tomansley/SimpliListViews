/**
 * @File Name          : ListViewConfigHelper.cls
 * @Description        : 
 * @Author             : tom.h.ansley@medtronic.com
 * @Group              : 
 * @Last Modified By   : tom.h.ansley@medtronic.com
 * @Last Modified On   : 07-27-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/11/2020   tom.h.ansley@medtronic.com     Initial Version
 * 2.0   06-18-2021   tom.h.ansley@medtronic.com   Added offset to allow for larger datasets
 * 3.0   07-27-2021   tom.h.ansley@medtronic.com   Added logic for new admin page.
**/
public with sharing class ListViewConfigHelper {

    private static Map<String,Object> orgWideConfigParams           = null;
    private static List_View_Config__c orgWideConfig                = null;
    private static final String ALL = 'All';

    public static final String OPER_EQUAL = 'Equals';
    public static final String OPER_NOT_EQUAL = 'Not Equal';
    public static final String OPER_GREATER = 'Greater Than';
    public static final String OPER_LESS = 'Less Than';
    public static final String OPER_CONTAINS = 'Contains';

    public static final String TYPE_BOOLEAN     =  'boolean';
    public static final String TYPE_STRING      = 'string';
    public static final String TYPE_DECIMAL     = 'decimal';
    public static final String TYPE_CURRENCY    = 'currency';
    public static final String TYPE_DATE        = 'date';
    public static final String TYPE_DATETIME    = 'datetime';
    public static final String TYPE_NUMBER      = 'number';
    public static final String TYPE_LIST_STRING = 'list(string)';

    //=======================================================================
    // ORG WIDE PARAM METHODS
    //=======================================================================

    /*
     * Method to populate the cache.
     */
    private static void populateOrgWideConfig() 
    {
        if (orgWideConfig == null)
        {

            orgWideConfigParams = new Map<String,Object>();

            List<List_View_Config__c> configs = getListViewConfig(ALL, ALL);
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

    /**
    * @description Method to get the parameter details for the org wide configuration.
    * @author tom.h.ansley@medtronic.com | 07-07-2021 
    **/
    public static Map<String, List_View_Config_Parameter__c> getOrgWideParamDetails()
    {
        return getListViewParamDetails(ALL, ALL);
    }

    public static void setOrgWideConfigParam(String settingName, String value)
    {
        populateOrgWideConfig();

        List<List_View_Config__c> configs = getListViewConfig(ALL, ALL);
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

    /**
    * @description Method to get all the org wide config params
    * @author tom.h.ansley@medtronic.com | 07-07-2021 
    * @return Map<String, Object> 
    **/
    public static Map<String,Object> getOrgWideConfigParams()
    {
        populateOrgWideConfig();

        return orgWideConfigParams;
    }

    /*
     * Method to get all config for the org.
     */
    public static String getOrgWideConfigParam(String settingName)
    {
        populateOrgWideConfig();

        return (String) orgWideConfigParams.get(settingName);
    }

    public static String updateOrgWideParams(Map<String, Object> newParams)
    {

        Map<String, List_View_Config_Parameter__c> paramDetails = getOrgWideParamDetails();

        for (String paramName: newParams.keySet())
        {

            List_View_Config_Parameter__c paramDetail = paramDetails.get(paramName);

            Object newValue = newParams.get(paramName);

            System.debug(LoggingLevel.DEBUG, 'NEW VALUE - ' + paramName + ' - '  + newValue);

            if (paramDetail.Parameter_Type__c.toLowerCase() == TYPE_BOOLEAN)
            {
                paramDetail.Parameter_Value__c = String.valueOf(newValue);
            } else if (paramDetail.Parameter_Type__c.toLowerCase() == TYPE_NUMBER)
            {
                paramDetail.Parameter_Value__c = String.valueOf(newValue);
            } else if (paramDetail.Parameter_Type__c.toLowerCase() == TYPE_LIST_STRING)
            {
                paramDetail.Parameter_Value__c = '';
                List<Object> values = (List<Object>) newValue;
                for (Object value: values)
                    paramDetail.Parameter_Value__c += (String) value + ',';
                    paramDetail.Parameter_Value__c = paramDetail.Parameter_Value__c.removeEnd(',');
            } else {
                paramDetail.Parameter_Value__c = String.valueOf(newValue);
            }
        }

        update paramDetails.values();

        orgWideConfig = null;
        populateOrgWideConfig();

        return '';
    }


    //=======================================================================
    // LIST VIEW PARAM METHODS
    //=======================================================================

    /**
    * @description Method to get the parameter details for a provided list view.
    * @author tom.h.ansley@medtronic.com | 07-07-2021 
    **/
    public static Map<String, List_View_Config_Parameter__c> getListViewParamDetails(String objectName, String listViewName)
    {
        List<List_View_Config_Parameter__c> params = [SELECT Parameter_Name__c,
                                                              Parameter_Type__c,
                                                              Parameter_Label__c,
                                                              Parameter_Value__c
                                                       FROM List_View_Config_Parameter__c
                                                       WHERE List_View_Config__r.Name = :listViewName
                                                                AND List_View_Config__r.List_View_Object__c = :objectName];
                                                                
        Map<String, List_View_Config_Parameter__c> paramMap = new Map<String, List_View_Config_Parameter__c>();
        for (List_View_Config_Parameter__c param: params)
            paramMap.put(param.Parameter_Name__c, param);

        return paramMap;
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

                Integer maxRowsDisplayed = Integer.valueOf(ListViewConfigHelper.getOrgWideConfigParam('MaxRowsDisplayed'));

                if (size > maxRowsDisplayed)
                {
                    error = 'Return size must be no greater than ' + maxRowsDisplayed;
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
    * @param type the type of the value being validated against
    * @param conditions the conditions the value is being validated against
    * @return String either an HTML color (condition match) or empty string (condition not met)
    **/
    public static String validateFieldCondition(Object value, String type, List<List_View_Config_Condition__c> conditions)
    {

        System.debug(LoggingLevel.DEBUG, 'Starting validateFieldCondition(' + value + ',' + type + ')');
        System.debug(LoggingLevel.DEBUG, 'Conditions - ' + conditions);

        if (value == null || conditions == null || conditions.size() == 0) return '';
    
        for (List_View_Config_Condition__c condition: conditions)
        {
            System.debug(LoggingLevel.DEBUG, 'Value     = ' + value);
            System.debug(LoggingLevel.DEBUG, 'Type      = ' + type);
            System.debug(LoggingLevel.DEBUG, 'Operator  = ' + condition.Operator__c);
            System.debug(LoggingLevel.DEBUG, 'condValue = ' + condition.Value__c);

            //if we have a meaningless comparison then skip
            if ((value == null || value == '') && type != 'string') continue;

            if (condition.Operator__c == OPER_EQUAL) {
                if (value == condition.Value__c) return condition.Highlight_Color__c;
            } else if (condition.Operator__c == OPER_NOT_EQUAL) {
                if (value != condition.Value__c) return condition.Highlight_Color__c;
            } else if (condition.Operator__c == OPER_GREATER) {
                if (type == TYPE_STRING && String.valueOf(value) > condition.Value__c) return condition.Highlight_Color__c;
                else if (type == TYPE_DECIMAL && Decimal.valueOf(String.valueOf(value)) > Decimal.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
                else if (type == TYPE_DATE && Date.valueOf(value) > Date.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
            } else if (condition.Operator__c == OPER_LESS) {
                if (type == TYPE_STRING && String.valueOf(value) < condition.Value__c) return condition.Highlight_Color__c;
                else if (type == TYPE_DECIMAL && Decimal.valueOf(String.valueOf(value)) < Decimal.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
                else if (type == TYPE_DATE && Date.valueOf(value) < Date.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
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