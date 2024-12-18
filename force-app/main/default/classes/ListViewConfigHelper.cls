/**
 * @File Name          : ListViewConfigHelper.cls
 * @Description        : 
 * @Author             : tom@ansleyllc.com
 * @Group              : 
 * @Last Modified By   : tom@ansleyllc.com
 * @Last Modified On   : 12-02-2024
 * @Modification Log   : 
 * Ver       Date            Author         Modification
 * 1.0    6/11/2020   tom@ansleyllc.com     Initial Version
 * 2.0   06-18-2021   tom@ansleyllc.com     Added offset to allow for larger datasets
 * 3.0   07-27-2021   tom@ansleyllc.com     Added logic for new admin page.
 * 4.0   08-18-2021   tom@ansleyllc.com     Updated strings to static final variables
 * 4.0   08-25-2021   tom@ansleyllc.com     Major enhancement to condition validation for more types
 * 4.0   12-15-2021   tom@ansleyllc.com     Removed old methods for checking object accessibility
 * 5.0   07-02-2024   tom@ansleyllc.com     Created global methods and set class to global
**/
global with sharing class ListViewConfigHelper {

    private static Map<String,Object> orgWideConfigParams = null; //convenience variable to easily access param values
    public static final String ALL = 'All';

    public static final String DEBUG = 'Debug';

    public static final String OPER_EQUAL = 'Equals';
    public static final String OPER_NOT_EQUAL = 'Not Equal';
    public static final String OPER_GREATER = 'Greater Than';
    public static final String OPER_LESS = 'Less Than';
    public static final String OPER_CONTAINS = 'Contains';
    public static final String OPER_DOES_NOT_CONTAIN = 'Does Not Contain';

    public static final String TODAY = 'Today';
    public static final String TOMORROW = 'Tomorrow';
    public static final String YESTERDAY = 'Yesterday';

    public static final Set<String> READ_ONLY_PARAMS = new Set<String>{'ListViewObjects', 'IsInitialized', 'RefreshJob'};

    //=======================================================================
    // ORG WIDE PARAM METHODS
    //=======================================================================

    @TestVisible
    private static void resetCache(String objectName, String listViewName)
    {
        if (objectName == ALL && listViewName == ALL)
            orgWideConfigParams = null;
        CacheListViewConfig.remove(objectName, listViewName);
    }

    /*
     * Method to populate the cache.
     */
    private static void populateOrgWideConfigParams() 
    {
        if (orgWideConfigParams == null)
        {

            orgWideConfigParams = new Map<String,Object>();

            List_View_Config__c config = getListViewConfig(ALL, ALL);

            for (List_View_Config_Parameter__c param: config.List_View_Config_Parameters__r)
            {
                if (String.isEmpty(param.Parameter_Value__c))
                    orgWideConfigParams.put(param.Parameter_Name__c, '');
                else
                    orgWideConfigParams.put(param.Parameter_Name__c, param.Parameter_Value__c);
            }
        }

    }

    public static Boolean isDebuggingOn()
    {
        return Boolean.valueOf(getOrgWideConfigParam(DEBUG));
    }

    /**
    * @description Method to get the parameter details for the org wide configuration.
    * @author tom@ansleyllc.com | 07-07-2021 
    **/
    public static Map<String, List_View_Config_Parameter__c> getOrgWideParamDetails()
    {
        return getListViewParamDetails(ALL, ALL);
    }

    public static void setOrgWideConfigParam(String settingName, String value)
    {

        List_View_Config__c config = getListViewConfig(ALL, ALL);

        for (List_View_Config_Parameter__c param: config.List_View_Config_Parameters__r)
        {
            if (param.Parameter_Name__c == settingName)
            {
                //update database
                param.Parameter_Value__c = value;

                //bug fix to stop failures during auto updates of params without labels.
                if (param.Parameter_Label__c == null)
                    param.Parameter_Label__c = param.Parameter_Name__c;

                HelperDatabase.updateRecord(param);

                //update session cache
                if (orgWideConfigParams == null)
                    orgWideConfigParams = new Map<String,Object>();
                orgWideConfigParams.put(settingName, value);
                break;
            }
        }

        //force org cache update
        resetCache(ALL, ALL);


    }

    /**
    * @description Method to get all the org wide config params
    * @author tom@ansleyllc.com | 07-07-2021 
    * @return Map<String, Object> 
    **/
    public static Map<String,Object> getOrgWideConfigParams()
    {
        populateOrgWideConfigParams();

        return orgWideConfigParams;
    }

    /*
     * Method to get a specific config setting for the org. Note that for this method if
     * the setting is not found the provided value is returned.
     */
    public static String getOrgWideConfigParam(String settingName, String defaultValue)
    {
        populateOrgWideConfigParams();

        String value = defaultValue;
        if (orgWideConfigParams.get(settingName) != null)
            value = (String) orgWideConfigParams.get(settingName);

        return value;
    }


    /*
     * Method to get a specific config setting for the org. Note that for this method if
     * the setting is not found an exception is thrown.
     */
    public static String getOrgWideConfigParam(String settingName)
    {
        populateOrgWideConfigParams();
        String value = (String) orgWideConfigParams.get(settingName);
        if (value == null)
            value = '';
        return value;
    }

    public static String setOrgWideParams(Map<String, Object> newParams)
    {

        Map<String, List_View_Config_Parameter__c> paramDetails = getOrgWideParamDetails();

        for (String paramName: newParams.keySet())
        {

            List_View_Config_Parameter__c paramDetail = paramDetails.get(paramName);

            Object newValue = newParams.get(paramName);

            System.debug(LoggingLevel.FINE, 'NEW VALUE - ' + paramName + ' - '  + newValue);

            if (paramDetail.Parameter_Type__c.toLowerCase() == ListViewHelper.TYPE_BOOLEAN)
            {
                paramDetail.Parameter_Value__c = String.valueOf(newValue);
            } else if (paramDetail.Parameter_Type__c.toLowerCase() == ListViewHelper.TYPE_NUMBER)
            {
                paramDetail.Parameter_Value__c = String.valueOf(newValue);
            } else if (paramDetail.Parameter_Name__c == 'ExcludedObjectTypes' //total hack as we cannot add new picklist values
                    || paramDetail.Parameter_Name__c == 'IncludedObjectTypes'
                    || paramDetail.Parameter_Name__c == 'ExcludedRecordPopoverTypes')
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

        //force org cache update
        resetCache(ALL, ALL);

        //if the excluded list views was changed we need to delete those list views that are to be excluded
        if (newParams.get('ExcludedListViews') != null && ((String) newParams.get('ExcludedListViews') != ''))
            deleteExcludedListViews();

        return '';
    }

    @TestVisible
    private static void deleteExcludedListViews()
    {
        String soql = 'SELECT Id FROM List_View__c WHERE ';

        List<String> excStrings = ListViewConfigHelper.getOrgWideConfigParam('ExcludedListViews').split('\\|');

        if (excStrings.size() > 0 && excStrings[0] != '')
        {
            for (String excString: excStrings)
                soql += 'API_Name__c LIKE \'%' + excString + '%\' OR ';
        }

        soql = soql.removeEnd(' OR ');

        System.debug(LoggingLevel.DEBUG, 'Final SOQL - ' + soql);

        Map<String, Object> vars = new Map<String, Object>();
        vars.put(HelperBatch.VAR_SOQL_STATEMENT, soql);
        vars.put(HelperBatch.VAR_BATCH_SIZE, 40);
        vars.put(HelperBatch.VAR_OPERATION, HelperBatch.OPER_DELETE);

        HelperBatch job = new HelperBatch(vars);

        if (!Test.isRunningTest())
            Database.executeBatch(job);
    
    }


    //=======================================================================
    // LIST VIEW PARAM METHODS
    //=======================================================================

    /**
    * @description Method to get the parameter details for a provided list view.
    * @author tom@ansleyllc.com | 07-07-2021 
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

        System.debug(LoggingLevel.FINE, 'Starting updateListViewParam(' + objectName + ', ' + listViewName + ', ' + paramName + ', ' + paramValue + ')');

        String errorStr = ListViewConfigHelper.validateParameter(objectName, listViewName, paramName, paramValue);

        if (errorStr == '')
        {

            SObjectAccessDecision dec = 
                Security.stripInaccessible(AccessType.READABLE,
                    [SELECT Parameter_Name__c,
                            Parameter_Type__c,
                            Parameter_Value__c
                    FROM List_View_Config_Parameter__c
                    WHERE List_View_Config__r.Name = :listViewName
                        AND List_View_Config__r.List_View_Object__c = :objectName
                        AND Parameter_Name__c = :paramName]);

            List<List_View_Config_Parameter__c> params = (List<List_View_Config_Parameter__c>) dec.getRecords();

            //if we have a parameter
            if (params.size() > 0)
            {
                System.debug(LoggingLevel.FINE, 'Old param found - ' + params[0]);

                params[0].Parameter_Value__c = paramValue;
            
            //we have no parameter so we need to create one
            } else {

                List_View_Config__c config = getListViewConfig(objectName, listViewName);
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = config.Id;
                param.Parameter_Name__c   = paramName;
                param.Parameter_Type__c   = paramType;
                param.Parameter_Value__c  = paramValue;
                param.Parameter_Label__c  = paramLabel;
                params.add(param);
            }

            System.debug(LoggingLevel.FINE, 'Updated params - ' + params);

            HelperDatabase.upsertRecords(params);

            //force org cache update
            resetCache(objectName, listViewName);

            System.debug(LoggingLevel.FINE, 'Finished upserting param!');
        }

        return errorStr;
        
    }

    public static void addListViewCondition(String objectName, String listViewName, String fieldName, String fieldOperator, String fieldValue, String fieldOrder, String fieldColor, Boolean highlightCellOnly)
    {

        //get the list view config for the parameter
        List_View_Config__c lvConfig = getListViewConfig(objectName, listViewName);

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c          = fieldName;
        condition.Highlight_Cell_Only__c = highlightCellOnly;
        condition.Highlight_Color__c     = fieldColor;
        condition.Operator__c            = fieldOperator;
        condition.Order__c               = fieldOrder;
        condition.Value__c               = fieldValue;
        condition.List_View_Config__c    = lvConfig.Id;

        System.debug(LoggingLevel.DEBUG, 'ADDING CONDITION - ' + condition);
        HelperDatabase.insertRecord(condition);

        //force org cache update
        resetCache(objectName, listViewName);

    }

    public static void addListViewColumnStyle(String objectName, String listViewName, String fieldName, String decoration, String font, String style, String transform, String variant, String weight, String alignment, String backgroundColor, String textColor)
    {

        //get the list view config for the column style
        List_View_Config__c lvConfig = getListViewConfig(objectName, listViewName);

        List_View_Config_Column_Style__c columnStyle = new List_View_Config_Column_Style__c();
        columnStyle.Field_Name__c             = fieldName;
        columnStyle.List_View_Config__c       = lvConfig.Id;
        columnStyle.Style_Decoration__c       = decoration;
        columnStyle.Style_Font__c             = font;
        columnStyle.Style_Style__c            = style;
        columnStyle.Style_Transform__c        = transform;
        columnStyle.Style_Variant__c          = variant;
        columnStyle.Style_Weight__c           = weight;
        columnStyle.Style_Alignment__c        = alignment;
        columnStyle.Style_Background_Color__c = backgroundColor;
        columnStyle.Style_Text_Color__c       = textColor;

        System.debug(LoggingLevel.DEBUG, 'ADDING COLUMN STYLE - ' + columnStyle);
        HelperDatabase.insertRecord(columnStyle);

        //force org cache update
        resetCache(objectName, listViewName);

    }

    public static void deleteListViewCondition(String id)
    {
        System.debug(LoggingLevel.FINE, 'Deleting list view condition - ' + id);

        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Id 
                 FROM List_View_Config_Condition__c
                 WHERE Id = :id]);

        List<List_View_Config_Condition__c> conditions = (List<List_View_Config_Condition__c>) dec.getRecords();

        HelperDatabase.deleteRecords(conditions);

    }

    public static void deleteListViewColumnStyle(String id)
    {
        System.debug(LoggingLevel.FINE, 'Deleting list view column style - ' + id);

        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Id 
                 FROM List_View_Config_Column_Style__c
                 WHERE Id = :id]);

        List<List_View_Config_Column_Style__c> columnStyles = (List<List_View_Config_Column_Style__c>) dec.getRecords();

        HelperDatabase.deleteRecords(columnStyles);

    }

    public static String getListViewConfigParameter(String objectName, String listViewName, String paramName)
    {
        System.debug(LoggingLevel.FINE, 'Starting getListViewConfigParameter(' + objectName + ', ' + listViewName + ', ' + paramName + ')');

        String paramValue = null;
        List_View_Config__c config = getListViewConfig(objectName, listViewName);
        if (config != null)
        {
            for (List_View_Config_Parameter__c param: config.List_View_Config_Parameters__r)
            {
                if (param.Parameter_Name__c == paramName)
                    paramValue = param.Parameter_Value__c;
            }   
        }
        return paramValue;
    }

    public static List_View_Config__c getListViewConfig(String objectName, String listViewName) 
    {
        List_View_Config__c config = CacheListViewConfig.get(objectName, listViewName);
        return config;
    }
    
    /**
    * @description Method to get a shortened global config FROM THE DATABASE DIRECTLY
    *              We need a way to circumvent forcing a global config create when searching
    *              for the config. This method should only get called by the core global config
    *              initialization method. The method only returns basic data to determine if the
    *              global config and parameters exist.
    * @author tom@ansleyllc.com | 12-02-2024 
    * @return List_View_Config__c the global config if one exists.
    **/
    public static List_View_Config__c forceGetGlobalConfig()
    {
        System.debug(LoggingLevel.FINE, 'Starting forceGetGlobalConfig()');

        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Name,
                        (SELECT Parameter_Name__c,
                                Parameter_Value__c
                        FROM List_View_Config_Parameters__r
                        ORDER BY Parameter_Label__c)
                        FROM List_View_Config__c
                    WHERE Name = 'All'
                        AND List_View_Object__c = 'All']);

        List<List_View_Config__c> configs = (List<List_View_Config__c>) dec.getRecords();

        if (configs.size() > 1)
            throw new ListViewException('Found more than one global config!');
        else if (configs.size() == 0)
            return null;
        System.debug(LoggingLevel.FINE, 'Returning configs - ' + configs[0]);
        return configs[0];
    }

    /*
     * 
       delete [SELECT Id FROM List_View_Config__c WHERE CreatedDate > 2021-10-12T12:00:00Z];
     */
    public static List_View_Config__c getListViewConfigCache(String objectName, String listViewName) 
    {
        System.debug(LoggingLEvel.FINE, 'Starting getListViewConfig(' + objectName + ', ' + listViewName + ')');

        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Name,
                        List_View_Object__c,
                        List_View_Label__c,
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
                                    Highlight_Cell_Only__c,
                                    Operator__c,
                                    Order__c,
                                    Value__c
                        FROM List_View_Config_Conditions__r
                        ORDER BY Order__c ASC),
                        (SELECT Field_Name__c,
                                Style_Decoration__c,
                                Style_Font__c,
                                Style_Style__c,
                                Style_Transform__c,
                                Style_Variant__c,
                                Style_Weight__c,
                                Style_Alignment__c,
                                Style_Background_Color__c,
                                Style_Text_Color__c
                         FROM List_View_Config_Column_Styles__r
                         ORDER BY Field_Name__c)
            FROM List_View_Config__c
                    WHERE Name = :listViewName
                        AND List_View_Object__c = :objectName]);

        List<List_View_Config__c> configs = (List<List_View_Config__c>) dec.getRecords();

        if (configs.size() > 1)
            throw new ListViewException('Found more than one list view config with name - ' + listViewName + ' and object - ' + objectName);
        else if (configs.size() == 0) {
            if (objectName == 'All' && listViewName == 'All')
                configs.add(ListViewHelper.insertCoreGlobalConfig());
            else
                return null;
                //throw new ListViewException('No list view config was found with name - ' + listViewName + ' and object - ' + objectName);
        }
        System.debug(LoggingLevel.FINE, 'Returning configs - ' + configs);
        return configs[0];
    }

    public static String getPrimaryKey(String objectName, String listViewName)
    {
        return objectName.replace(' ', '_') + ':' + listViewName;
    }

    public static Map<String, List_View_Config__c> getListViewConfigs(Set<String> primaryKeys) 
    {
        List<List_View_Config__c> configs = [SELECT Name,
                                                List_View_Object__c,
                                                List_View_Label__c,
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
                                                            Highlight_Cell_Only__c,
                                                            Operator__c,
                                                            Order__c,
                                                            Value__c
                                                FROM List_View_Config_Conditions__r
                                                ORDER BY Order__c ASC),
                                                (SELECT Field_Name__c,
                                                        Style_Decoration__c,
                                                        Style_Font__c,
                                                        Style_Style__c,
                                                        Style_Transform__c,
                                                        Style_Variant__c,
                                                        Style_Weight__c,
                                                        Style_Alignment__c,
                                                        Style_Background_Color__c,
                                                        Style_Text_Color__c
                                                FROM List_View_Config_Column_Styles__r
                                                ORDER BY Field_Name__c)
                                    FROM List_View_Config__c
                                            WHERE Primary_Key__c IN :primaryKeys];

        Map<String, List_View_Config__c> mappedConfigs = new Map<String, List_View_Config__c>();
        for (List_View_Config__c config: configs)
        {
            mappedConfigs.put(config.Primary_Key__c, config);
        }

        return mappedConfigs;

    }

    public static Map<String, List_View_Config__c> getListViewConfigsById(Set<String> ids) 
    {
        return new Map<String, List_View_Config__c>(
            [SELECT Name,
                    List_View_Object__c,
                    List_View_Label__c,
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
                                Highlight_Cell_Only__c,
                                Operator__c,
                                Order__c,
                                Value__c
                    FROM List_View_Config_Conditions__r
                    ORDER BY Order__c ASC),
                    (SELECT Field_Name__c,
                            Style_Decoration__c,
                            Style_Font__c,
                            Style_Style__c,
                            Style_Transform__c,
                            Style_Variant__c,
                            Style_Weight__c,
                            Style_Alignment__c,
                            Style_Background_Color__c,
                            Style_Text_Color__c
                    FROM List_View_Config_Column_Styles__r
                    ORDER BY Field_Name__c)
        FROM List_View_Config__c
                WHERE Id IN :ids]);
    }

    /**
    * @description Method to validate parameter updates
    * @author tom@ansleyllc.com | 08-17-2020 
    * @param paramName the name of the parameter being updated
    * @param paramValue the value the parameter is being updated to
    * @return String the error message if the parameter is invalid.
    **/
    public static String validateParameter(String objectName, String listViewName, String paramName, String paramValue)
    {
        String error = '';

        if (paramName == ListViewHelper.PARAM_REFRESH_RATE)
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

        } else if (paramName == ListViewHelper.PARAM_RETURN_SIZE)
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


        } else if (paramName == ListViewHelper.PARAM_TOTAL_COLUMNS)
        {
        } else if (paramName == ListViewHelper.PARAM_ADD_FIELDS)
        {
            if (paramValue != '')
            {

                try {

                    //get the list view
                    List_View__c listview = ListViewHelper.getListViews(objectName, listViewName).values()[0];
            
                    //get the list views query
                    String query = listview.Core_ListView_Query__c;

                    //get the fields on the SELECT
                    String selectStr = query.substringBetween('SELECT ', ' FROM ');
        
                    selectStr += ', ' + paramValue;
            
                    String soql = 'SELECT ' + selectStr + ' FROM ' + objectName + ' LIMIT 1';

                    System.debug(LoggingLevel.FINE, 'Param Validation SOQL - ' + soql);

                    List<SObject> result = Database.query(soql);

                } catch (Exception e) {
                    error = 'The additional fields are invalid. Please ensure syntax is correct, there are no duplicate fields, and the names are valid API field names - ' + e.getMessage();
                }
            }
        
        } else if (paramName == ListViewHelper.PARAM_SPLIT_COLUMNS)
        {
            paramValue = paramValue.remove(' ');
            List<String> fieldNames = paramValue.split(',');

            if (fieldNames.size() > 4) {
                error = 'Only 4 columns can be added.';
            } else {

                try {

                    String soql = 'SELECT ' + paramValue + ' FROM ' + objectName + ' LIMIT 1';

                    System.debug(LoggingLevel.FINE, 'Param Validation SOQL - ' + soql);

                    List<SObject> result = Database.query(soql);

                } catch (Exception e) {
                    error = 'The split column fields are invalid. Please ensure syntax is correct and the names are valid API field names - ' + e.getMessage();
                }
            }
        }

        return error;
    }

    /**
    * @description Method to validate a condition given an object being validated against and
    * a condition. The return of an HTML color indicates the condition yielded a result. If no
    * color was returned the value did meet any criteria.
    *
    * NOTE - DATE and DATETIME come through as millisecond strings and therefore need to be converted.
    *
    * @author tom@ansleyllc.com | 08-05-2020 
    * @param value the value being validated against
    * @param type the type of the value being validated against
    * @param conditions the conditions the value is being validated against
    * @return String either an HTML color (condition match) or empty string (condition not met)
    **/
    public static String validateFieldCondition(Object value, String type, List_View_Config_Condition__c condition)
    {
        try {
            System.debug(LoggingLevel.FINE, 'Starting validateFieldCondition(' + value + ',' + type + ')');
            System.debug(LoggingLevel.FINE, 'Conditions - ' + condition);

            if (value == null || condition == null) return '';
        
            System.debug(LoggingLevel.FINE, 'Value     = ' + value);
            System.debug(LoggingLevel.FINE, 'Type      = ' + type);
            System.debug(LoggingLevel.FINE, 'Operator  = ' + condition.Operator__c);
            System.debug(LoggingLevel.FINE, 'condValue = ' + condition.Value__c);

            //if we have a meaningless comparison then skip
            if ((value == null || value == '') && type != ListViewHelper.TYPE_STRING) return '';

            //EQUAL
            if (condition.Operator__c == OPER_EQUAL) {
                if (type == ListViewHelper.TYPE_DOUBLE) {
                    if (value == Double.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
                }else if (type == ListViewHelper.TYPE_DATE) {
                    
                    Date dte = getDateValue(condition.Value__c);
                    if (HelperDate.convertMillisToDate((String) value) == dte) return condition.Highlight_Color__c;

                } else if (type == ListViewHelper.TYPE_DATETIME) {
                    
                    DateTime dte = getDateTimeValue(condition.Value__c);
                    if (HelperDate.convertMillisToDateTime((String) value) == dte) return condition.Highlight_Color__c;

                } else if (type == ListViewHelper.TYPE_TIME) {
                    if (HelperDate.getTimeFromString((String) value) == HelperDate.getTimeFromString(condition.Value__c)) return condition.Highlight_Color__c;
                } else if (String.valueOf(value) == condition.Value__c) return condition.Highlight_Color__c;

            //NOT EQUAL
            } else if (condition.Operator__c == OPER_NOT_EQUAL) {
                if (type == ListViewHelper.TYPE_DOUBLE) {
                    if (value != Double.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
                } else if (type == ListViewHelper.TYPE_DATE) {
                    
                    Date dte = getDateValue(condition.Value__c);
                    if (HelperDate.convertMillisToDate((String) value) != dte) return condition.Highlight_Color__c;

                } else if (type == ListViewHelper.TYPE_DATETIME) {
                    
                    DateTime dte = getDateTimeValue(condition.Value__c);
                    if (HelperDate.convertMillisToDateTime((String) value) != dte) return condition.Highlight_Color__c;

                } else if (type == ListViewHelper.TYPE_TIME) {
                    if (HelperDate.getTimeFromString((String) value) != HelperDate.getTimeFromString(condition.Value__c)) return condition.Highlight_Color__c;
                } else if (String.valueOf(value) != condition.Value__c) return condition.Highlight_Color__c;

            //GREATER THAN
            } else if (condition.Operator__c == OPER_GREATER) {
                if ((type == ListViewHelper.TYPE_STRING 
                        || type == ListViewHelper.TYPE_EMAIL 
                        || type == ListViewHelper.TYPE_MULTI_PICK 
                        || type == ListViewHelper.TYPE_PHONE 
                        || type == ListViewHelper.TYPE_PICKLIST 
                        || type == ListViewHelper.TYPE_RICH_TEXTAREA
                        || type == ListViewHelper.TYPE_TEXTAREA
                        || type == ListViewHelper.TYPE_URL) 
                        && String.valueOf(value) > condition.Value__c) return condition.Highlight_Color__c;
                else if ((type == ListViewHelper.TYPE_DECIMAL 
                        || type == ListViewHelper.TYPE_CURRENCY 
                        || type == ListViewHelper.TYPE_NUMBER 
                        || type == ListViewHelper.TYPE_PERCENT) 
                        && Decimal.valueOf(String.valueOf(value)) > Decimal.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
                else if (type == ListViewHelper.TYPE_DATE) {
                    
                    Date dte = getDateValue(condition.Value__c);
                    if (HelperDate.convertMillisToDate((String) value) > dte) return condition.Highlight_Color__c;

                } else if (type == ListViewHelper.TYPE_DATETIME) {
                    
                    DateTime dte = getDateTimeValue(condition.Value__c);
                    if (HelperDate.convertMillisToDateTime((String) value) > dte) return condition.Highlight_Color__c;

                } else if (type == ListViewHelper.TYPE_DOUBLE && Double.valueOf(value) > Double.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
                else if (type == ListViewHelper.TYPE_INTEGER && Integer.valueOf(value) > Integer.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
                else if (type == ListViewHelper.TYPE_TIME && HelperDate.getTimeFromString((String) value) > HelperDate.getTimeFromString(condition.Value__c)) return condition.Highlight_Color__c;
        
            //LESS THAN
            } else if (condition.Operator__c == OPER_LESS) {
                if ((type == ListViewHelper.TYPE_STRING 
                        || type == ListViewHelper.TYPE_EMAIL 
                        || type == ListViewHelper.TYPE_MULTI_PICK 
                        || type == ListViewHelper.TYPE_PHONE 
                        || type == ListViewHelper.TYPE_PICKLIST 
                        || type == ListViewHelper.TYPE_RICH_TEXTAREA
                        || type == ListViewHelper.TYPE_TEXTAREA
                        || type == ListViewHelper.TYPE_URL) 
                        && String.valueOf(value) < condition.Value__c) return condition.Highlight_Color__c;
                else if ((type == ListViewHelper.TYPE_DECIMAL 
                        || type == ListViewHelper.TYPE_CURRENCY 
                        || type == ListViewHelper.TYPE_NUMBER 
                        || type == ListViewHelper.TYPE_PERCENT) 
                        && Decimal.valueOf(String.valueOf(value)) < Decimal.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
                else if (type == ListViewHelper.TYPE_DATE) {
                    
                    Date dte = getDateValue(condition.Value__c);
                    if (HelperDate.convertMillisToDate((String) value) < dte) return condition.Highlight_Color__c;

                } else if (type == ListViewHelper.TYPE_DATETIME) {
                    
                    DateTime dte = getDateTimeValue(condition.Value__c);
                    if (HelperDate.convertMillisToDateTime((String) value) < dte) return condition.Highlight_Color__c;

                } else if (type == ListViewHelper.TYPE_DOUBLE && Double.valueOf(value) < Double.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
                else if (type == ListViewHelper.TYPE_INTEGER && Integer.valueOf(value) < Integer.valueOf(condition.Value__c)) return condition.Highlight_Color__c;
                else if (type == ListViewHelper.TYPE_TIME && HelperDate.getTimeFromString((String) value) < HelperDate.getTimeFromString(condition.Value__c)) return condition.Highlight_Color__c;

            //CONTAINS
            } else if (condition.Operator__c == OPER_CONTAINS) {
                if (type == ListViewHelper.TYPE_DATETIME
                    || type == ListViewHelper.TYPE_DATE
                    || type == ListViewHelper.TYPE_TIME
                    || type == ListViewHelper.TYPE_PERCENT
                    || type == ListViewHelper.TYPE_CURRENCY) throw new ListViewException('Cannot use "Contains" operator on DateTime, Date, Time, Percent or Currency types');
                if (String.valueOf(value).contains(condition.Value__c)) return condition.Highlight_Color__c;

            //DOES NOT CONTAIN
            } else if (condition.Operator__c == OPER_DOES_NOT_CONTAIN) {
                if (!String.valueOf(value).contains(condition.Value__c)) return condition.Highlight_Color__c;
            }

        } catch (Exception e) {
            String message = 'Exception during ListViewController.validateFieldCondition(' + value + ',' + type + ',' + condition + ')  ' + ListViewException.getExtendedString(e);
            if (!HelperLimits.hasReachedLimit('DMLStatements'))
                ListViewErrorHelper.createFutureUsageError(message); 
        }
        return '';
    }








    //================================================================================================================
    // GLOBAL METHODS
    //================================================================================================================

    global static void updateOrgWideParam(String settingName, String value)
    {
        setOrgWideConfigParam(settingName, value);
    }

    global static void updateOrgWideParams(Map<String, String> newParams)
    {
        setOrgWideParams(newParams);
    }
    
    global static String getOrgWideParam(String settingName)
    {
        return ListViewConfigHelper.getOrgWideConfigParam(settingName);
    }

    global static Map<String, String> getOrgWideParams()
    {
        Map<String, String> params = new Map<String, String>();

        Map<String, Object> orgWideParams = ListViewConfigHelper.getOrgWideConfigParams();

        for (String key: orgWideParams.keySet())
            params.put(key, String.valueOf(orgWideParams.get(key)));

        return params;
    }






    //================================================================================================================
    // PRIVATE METHODS
    //================================================================================================================

    private static Date getDateValue(String condValue)
    {
        Date dte = null;
        if (condValue == TODAY)
            dte = System.today();
        else if (condValue == TOMORROW)
            dte = System.today().addDays(1);
        else if (condValue == YESTERDAY)
            dte = System.today().addDays(-1);
        else 
            dte = Date.valueOf(condValue);

        return dte;
    }

    private static DateTime getDateTimeValue(String condValue)
    {
        DateTime dte = null;
        if (condValue == TODAY)
            dte = HelperDate.convertDateToDateTime(System.today());
        else if (condValue == TOMORROW)
            dte = HelperDate.convertDateToDateTime(System.today().addDays(1));
        else if (condValue == YESTERDAY)
            dte = HelperDate.convertDateToDateTime(System.today().addDays(-1));
        else 
            dte = DateTime.valueOf(condValue);

        return dte;
    }

}