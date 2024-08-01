/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 07-31-2024
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   08-05-2020   tom@ansleyllc.com   Initial Version
 * 2.0   08-16-2021   tom@ansleyllc.com   Added permission check for each action before display
 * 3.0   08-20-2021   tom@ansleyllc.com   Updated strings to static final variables, added 2 new fields - Is_Hyperlink__c, Hyperlink_Target__c, new logic to handle whether actions are displayed based on user permissions
 * 4.0   08-20-2021   tom@ansleyllc.com   Removed Hyperlink_Target__c
**/
global with sharing class ListViewActionHelper {

    public static final Id coreRTId = Schema.SObjectType.List_View_Action__c.getRecordTypeInfosByDeveloperName().get('Core').getRecordTypeId();
    public static final Id customRTId = Schema.SObjectType.List_View_Action__c.getRecordTypeInfosByDeveloperName().get('Custom').getRecordTypeId();

    public static final String PERM_CREATE = 'Create';
    public static final String PERM_READ   = 'Read';
    public static final String PERM_EDIT   = 'Edit';
    public static final String PERM_DELETE = 'Delete';

    public static final String VIS_ALWAYS = 'Always displayed';
    public static final String VIS_ONLY_ONE = 'Displayed if one record is selected';
    public static final String VIS_AT_LEAST_ONE = 'Displayed if one or more records are selected';

    public static final String PARAM_KEY_URL               = 'URL';
    public static final String PARAM_KEY_EMAIL_TEMP_FOLDER = 'EmailTemplateFolder';
    public static final String PARAM_KEY_EMAIL_WHAT_ID     = 'EmailTemplateWhatIdField';

    public static final String SUCCESS = 'success';
    public static final String FAILED = 'failed';

    public static final String SUB_TYPE_MANUAL   = 'Manual';
    public static final String SUB_TYPE_TOOLING  = 'Tooling';
    public static final String SUB_TYPE_METADATA = 'Metadata';

    private static String debugString = '';

    public static String getPrimaryKey(List_View_Action__c action)
    {
        String recTypeStr = 'Core';
        if (action.RecordTypeId == customRTId)
            recTypeStr = 'Custom';
        return action.Label__c.deleteWhitespace() + ':' + action.Apex_Class_Name__c + ':' + recTypeStr + ':' + action.Object_Type__c;
    }

    public static String createAction(Map<String, String> actionFields)
    {
        String response = SUCCESS;

        try {
            //--------------------------------------------------
            // CREATE THE ACTION USING THE MAIN DETAILS
            //--------------------------------------------------
            List_View_Action__c action = new List_View_Action__c();
            List<List_View_Action_Parameter__c> actionParams = new List<List_View_Action_Parameter__c>();
            action.Label__c          = actionFields.get('actionLabel');
            action.Is_Active__c      = Boolean.valueOf(actionFields.get('actionIsActive'));
            action.Object_Type__c    = actionFields.get('actionObjectType');
            action.Component_Name__c = actionFields.get('actionComponentName');
            action.Permissions__c    = actionFields.get('actionUserPermissions');
            action.Selected_Record_Visibility__c = actionFields.get('actionRecordVisible');

            if (actionFields.get('actionRecordType') == 'Core')
                action.RecordTypeId = coreRTId;
            else {
                action.RecordTypeId = customRTId;
                action.Subtype__c = SUB_TYPE_MANUAL;
                if (String.isEmpty(action.Object_Type__c))
                    throw new ListViewException('Custom actions of subtype "Manual" must have an object type if they are not of type hyperlink or flow');
            }


            //--------------------------------------------------
            // HANDLE EACH ACTION TYPE SPECIFICALLY
            //--------------------------------------------------
            String actionType = actionFields.get('actionType');

            if (actionType == 'HyperLink')
            {
                action.Apex_Class_Name__c = 'ListViewActionHyperLink';
                action.Is_Hyperlink__c = true;
                
                actionParams.add(createActionParameter('URL', 'URL', 'url', -1, actionFields.get('hyperlinkURL')));

                if (!String.isEmpty(actionFields.get('hyperlinkSubParamName1')))
                    actionParams.add(createActionParameter(actionFields.get('hyperlinkSubParamName1'), actionFields.get('hyperlinkSubParamName1'), 'string', -1, actionFields.get('hyperlinkSubParamField1')));  

                if (!String.isEmpty(actionFields.get('hyperlinkSubParamName2')))
                    actionParams.add(createActionParameter(actionFields.get('hyperlinkSubParamName2'), actionFields.get('hyperlinkSubParamName2'), 'string', -1, actionFields.get('hyperlinkSubParamField2')));     
                

            } else if (actionType == 'EmailClassic')
            {
                action.Apex_Class_Name__c = 'ListViewActionEmail';

                actionParams.add(createActionParameter('Subject', 'Email Subject', 'string', -1, ''));  
                actionParams.add(createActionParameter('Body', 'Email Body', 'rich textarea', -1, ''));  

                if (!String.isEmpty(actionFields.get('sendEmailClassicFieldName')))
                    actionParams.add(createActionParameter('API Field Name', 'API Field Name', 'string', -1, actionFields.get('sendEmailClassicFieldName')));     


            } else if (actionType == 'EmailTemplate')
            {
                action.Apex_Class_Name__c = 'ListViewActionEmail';

                actionParams.add(createActionParameter('EmailTemplateFolder', 'EmailTemplateFolder', 'string', -1, actionFields.get('sendEmailTemplateFolderName')));  

                if (!String.isEmpty(actionFields.get('sendEmailTemplateWhatIdField')))
                    actionParams.add(createActionParameter('EmailTemplateWhatIdField', 'EmailTemplateWhatIdField', 'string', -1, actionFields.get('sendEmailTemplateWhatIdField')));     

            } else if (actionType == 'LaunchFlow')
            {
                action.Apex_Class_Name__c = 'ListViewActionFlow';
                action.Is_Flow__c       = true;
                action.Flow_API_Name__c = actionFields.get('launchFlowAPIName');
                action.Flow_Type__c     = 'Autolaunched Flow';

            } else if (actionType == 'ScreenFlow')
            {
                action.Apex_Class_Name__c = 'ListViewActionFlow';
                action.Is_Flow__c = true;
                action.Flow_API_Name__c = actionFields.get('screenFlowAPIName');
                action.Flow_Type__c     = 'Screen Flow';

                if (!String.isEmpty(actionFields.get('screenFlowFrameHeight')))
                    action.Flow_Frame_Height__c = actionFields.get('screenFlowFrameHeight');

                if (!String.isEmpty(actionFields.get('screenFlowFrameWidth')))
                    action.Flow_Frame_Height__c = actionFields.get('screenFlowFrameWidth');
    
            } else if (actionType == 'SaveToPDF')
            {
                action.Apex_Class_Name__c = 'ListViewActionPDF';

            } else if (actionType == 'Custom')
            {
                action.Apex_Class_Name__c = actionFields.get('customApexClassName');

            } else if (actionType == 'ManageData')
            {
                String actionSubType = actionFields.get('actionSubType'); 
    
                if (actionSubType == 'Create')
                {
                    action.Apex_Class_Name__c = 'ListViewActionCreate';
                    
                    if (!String.isEmpty(actionFields.get('manageDataCreateOwnerField')))
                    actionParams.add(createActionParameter('UserField', 'UserField', ListViewHelper.TYPE_STRING, -1, actionFields.get('manageDataCreateOwnerField')));

                    if (!String.isEmpty(actionFields.get('manageDataCreateRedirectField')))
                        actionParams.add(createActionParameter('NoRedirect', 'NoRedirect', ListViewHelper.TYPE_BOOLEAN, -1, actionFields.get('manageDataCreateRedirectField')));

                } else if (actionSubType == 'Edit')
                {
                    action.Apex_Class_Name__c = 'ListViewActionEdit';

                } else if (actionSubType == 'EditAll')
                {
                    action.Apex_Class_Name__c = 'ListViewActionEditAll';

                } else if (actionSubType == 'Clone')
                {
                    action.Apex_Class_Name__c = 'ListViewActionClone';

                } else if (actionSubType == 'Delete')
                {
                    action.Apex_Class_Name__c = 'ListViewActionDelete';

                } else if (actionSubType == 'MassCreate')
                {
                    action.Apex_Class_Name__c = 'ListViewActionMassCreate';

                    if (!String.isEmpty(actionFields.get('manageDataMassCreateListViewName')))
                        action.Mass_Create_List_View_Name__c = actionFields.get('manageDataMassCreateListViewName');

                } else if (actionSubType == 'MassUpdate')
                {
                    action.Apex_Class_Name__c = 'ListViewActionUpdate';
                    //we could have up to 8 parameters for the mass update
                    for (Integer index = 1; index < 8; index++)
                    {
                        if (!String.isEmpty(actionFields.get('manageDataMassUpdateLabel' + index))
                            && !String.isEmpty(actionFields.get('manageDataMassUpdateField' + index))
                            && !String.isEmpty(actionFields.get('manageDataMassUpdateType' + index)))
                        {
                            Integer order = 1;
                            if (!String.isEmpty(actionFields.get('manageDataMassUpdateOrder' + index)))
                                order = Integer.valueOf(actionFields.get('manageDataMassUpdateOrder' + index));

                            String defaultValue = '';
                            if (!String.isEmpty(actionFields.get('manageDataMassUpdateDefault' + index)))
                                defaultValue = actionFields.get('manageDataMassUpdateDefault' + index);

                            actionParams.add(createActionParameter(actionFields.get('manageDataMassUpdateField' + index), 
                                                                actionFields.get('manageDataMassUpdateLabel' + index), 
                                                                actionFields.get('manageDataMassUpdateType' + index),
                                                                order,
                                                                defaultValue));     
                        }
                    }

                }
            }

            //insert the ACTION
            action = (List_View_Action__c) HelperDatabase.insertRecord(action);

            //set ACTION ID into params
            for (List_View_Action_Parameter__c param: actionParams)
                param.List_View_Action__c = action.Id;

            //insert PARAMS
            HelperDatabase.insertRecords(actionParams);

        } catch (Exception e) {
            response = e.getMessage();
        }


        return response;
    }

    private static List_View_Action_Parameter__c createActionParameter(String apiName, String label, String type, Integer order, String value)
    {
        List_View_Action_Parameter__c param = new List_View_Action_Parameter__c();
        param.Field_API_Name__c = apiName;
        param.Label__c          = label;
        param.Type__c           = type;
        param.Display_Order__c  = order;
        param.Default_Value__c  = value;

        return param;
    }

    public static List<List_View_Action__c> getListViewActions()
    {
        SObjectAccessDecision dec = 
         Security.stripInaccessible(AccessType.READABLE,
                [SELECT Label__c,
                        Apex_Class_Name__c,
                        Object_Type__c,
                        Primary_Key__c,
                        Subtype__c,
                        RecordTypeId,
                        RecordType.Name,
                        Permissions__c,
                        Is_Hyperlink__c,
                        Is_Active__c,
                        Is_Flow__c,
                        Flow_API_Name__c,
                        Flow_Frame_Height__c,
                        Flow_Frame_Width__c,
                        Flow_Type__c,
                        Mass_Create_List_View_Name__c,
                        Selected_Record_Visibility__c,
                        Component_Name__c,
                        (SELECT Field_API_Name__c,
                                Label__c,
                                Display_Order__c,
                                Type__c,
                                Default_Value__c,
                                Placeholder_Text__c,
                                Lookup_Type__c
                        FROM List_View_Action_Parameters__r
                        ORDER BY Display_Order__c NULLS LAST)
                FROM List_View_Action__c
                LIMIT 2000]);

        return dec.getRecords();
    }

    public static Map<Id, List_View_Action__c> getListViewActions(Set<Id> actionIds) 
    {
        SObjectAccessDecision dec = 
         Security.stripInaccessible(AccessType.READABLE,
            [SELECT Label__c,
                    Apex_Class_Name__c,
                    Object_Type__c,
                    Primary_Key__c,
                    Subtype__c,
                    RecordTypeId,
                    RecordType.Name,
                    Permissions__c,
                    Is_Hyperlink__c,
                    Is_Active__c,
                    Is_Flow__c,
                    Flow_API_Name__c,
                    Flow_Frame_Height__c,
                    Flow_Frame_Width__c,
                    Flow_Type__c,
                    Mass_Create_List_View_Name__c,
                    Selected_Record_Visibility__c,
                    Component_Name__c,
                    (SELECT Field_API_Name__c,
                            Label__c,
                            Display_Order__c,
                            Type__c,
                            Default_Value__c,
                            Placeholder_Text__c,
                            Lookup_Type__c
                    FROM List_View_Action_Parameters__r
                    ORDER BY Display_Order__c NULLS LAST)
            FROM List_View_Action__c
            WHERE Id IN :actionIds
                AND Is_Active__c = TRUE]);

        return new Map<Id, List_View_Action__c>((List<List_View_Action__c>) dec.getRecords());
    }

    /*
     * Method to get a list view action based on its primary key
     */
    public static List_View_Action__c getListViewActionByKey(String primaryKey)
    {
        SObjectAccessDecision dec = 
         Security.stripInaccessible(AccessType.READABLE,
                [SELECT Label__c,
                        Apex_Class_Name__c,
                        Object_Type__c,
                        Primary_Key__c,
                        Subtype__c,
                        RecordTypeId,
                        RecordType.Name,
                        Permissions__c,
                        Is_Hyperlink__c,
                        Is_Active__c,
                        Is_Flow__c,
                        Flow_Type__c,
                        Flow_API_Name__c,
                        Flow_Frame_Height__c,
                        Flow_Frame_Width__c,
                        Mass_Create_List_View_Name__c,
                        Selected_Record_Visibility__c,
                        Component_Name__c,
                        (SELECT Field_API_Name__c,
                                Label__c,
                                Display_Order__c,
                                Type__c,
                                Default_Value__c,
                                Placeholder_Text__c,
                                Lookup_Type__c
                         FROM List_View_Action_Parameters__r
                         ORDER BY Display_Order__c NULLS LAST)
                FROM List_View_Action__c
                WHERE Primary_Key__c = :primaryKey]);

        return (List_View_Action__c) dec.getRecords()[0];
    }

    /*
     * Method to get a list view action based on its primary key
     */
    public static Map<String, List_View_Action__c> getListViewActionsByKey(Set<String> primaryKeys)
    {
        SObjectAccessDecision dec = 
         Security.stripInaccessible(AccessType.READABLE,
                [SELECT Label__c,
                        Apex_Class_Name__c,
                        Object_Type__c,
                        Primary_Key__c,
                        Subtype__c,
                        RecordTypeId,
                        RecordType.Name,
                        Permissions__c,
                        Is_Hyperlink__c,
                        Is_Active__c,
                        Is_Flow__c,
                        Flow_Type__c,
                        Flow_API_Name__c,
                        Flow_Frame_Height__c,
                        Flow_Frame_Width__c,
                        Mass_Create_List_View_Name__c,
                        Selected_Record_Visibility__c,
                        Component_Name__c,
                        (SELECT Field_API_Name__c,
                                Label__c,
                                Display_Order__c,
                                Type__c,
                                Default_Value__c,
                                Placeholder_Text__c,
                                Lookup_Type__c
                         FROM List_View_Action_Parameters__r
                         ORDER BY Display_Order__c NULLS LAST)
                FROM List_View_Action__c
                WHERE Primary_Key__c IN :primaryKeys]);

        List<List_View_Action__c> actions = (List<List_View_Action__c>) dec.getRecords();
        Map<String, List_View_Action__c> actionsByKey = new Map<String, List_View_Action__c>();
        for (List_View_Action__c action: actions)
            actionsByKey.put(action.Primary_Key__c, action);

        return actionsByKey;
    }

    /**
    * @description Method to retrieve the actions associated with an object and list view.
    * @author tom@ansleyllc.com | 08-15-2021 
    * @return Map<String, String> the primary key of the action and the action name
    **/
    public static List<ListViewActionWrapper> getListViewActions(String objectType, String listViewName, String componentName)
    {
        debugString += 'getListViewActions(' + objectType + ', ' + listViewName + ')';

        List<ListViewActionWrapper> actions = new List<ListViewActionWrapper>();

        //get the list views
        Map<Id, List_View__c> listViews = ListViewHelper.getListViews(objectType, listViewName);

        if (listViews.isEmpty())
            throw new ListViewException('The list view configuration can not be found for object ' + objectType + ' and list view name - ' + listViewName + ')');

        List_View__c listview = listViews.values()[0];

        //get the actions based on the list view
        Map<String, List_View_Action__c> lvActions = ListViewActionHelper.getListViewActionsByListView(listview);

        for (String actionName: lvActions.keySet())
        {
            List_View_Action__c action = lvActions.get(actionName);
            if (canPerformAction(objectType, componentName, action))
                actions.add(new ListViewActionWrapper(action));         
        }

        System.debug(LoggingLevel.DEBUG, debugString);
        ListViewErrorHelper.addLog('ListViewActionHelper(getListViewActions)', debugString);
        return actions;
    }

    /**
    * @description Method to get all list view actions given the object name and list view type
    *              Note that any actions with an object type of NULL are also returned as these
    *              actions are universal.
    * @author tom@ansleyllc.com | 10-31-2020 
    * @param objectType the object type of the actions to be returned.
    * @param listViewType one of All, Core or Custom
    * @return Map<String, List_View_Action__c> returned as follows - (API Name, Action)
    **/
    public static Map<String, List_View_Action__c> getListViewActionsByListView(List_View__c listview)
    {
        System.debug(LoggingLevel.FINE, 'Starting getListViewActionsByListView(' + listview + ')');

        Id rt = ListViewActionHelper.coreRTId;
        if (listview.RecordTypeId == ListViewHelper.customRTId)
        {
            rt = ListViewActionHelper.customRTId;
            debugString += 'List View RT - Custom(' + rt + '), ';
        } else {
            debugString += 'List View RT - Core(' + rt + '), ';
        }

        Set<String> subTypes = new Set<String>();
        if (listview.RecordTypeId == ListViewHelper.customRTId)
            subTypes.add(listview.Subtype__c);

        debugString += 'List View Subtypes - ' + subTypes + ', ';

            //get list view data
            SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Label__c,
                        Apex_Class_Name__c,
                        Object_Type__c,
                        Primary_Key__c,
                        Subtype__c,
                        RecordTypeId,
                        RecordType.Name,
                        Permissions__c,
                        Is_Hyperlink__c,
                        Is_Active__c,
                        Is_Flow__c,
                        Flow_Type__c,
                        Flow_API_Name__c,
                        Flow_Frame_Height__c,
                        Flow_Frame_Width__c,
                        Mass_Create_List_View_Name__c,
                        Selected_Record_Visibility__c,
                        Component_Name__c,
                        (SELECT Field_API_Name__c,
                                Label__c,
                                Display_Order__c,
                                Type__c,
                                Default_Value__c,
                                Placeholder_Text__c,
                                Lookup_Type__c
                        FROM List_View_Action_Parameters__r
                        ORDER BY Display_Order__c NULLS LAST)
                    FROM List_View_Action__c
                    WHERE RecordTypeId = :rt
                            AND (Object_Type__c = :listview.Object_Name__c
                                OR Object_Type__c = NULL)
                            AND (Subtype__c = NULL
                                OR Subtype__c IN :subTypes)
                            AND Is_Active__c = TRUE
                        ORDER BY Label__c]);

        List<List_View_Action__c> actions = (List<List_View_Action__c>) dec.getRecords();

        debugString += 'List views returned - ' + actions.size() + ', ';

        Map<String, List_View_Action__c> actionsByName = new Map<String, List_View_Action__c>();
        for (List_View_Action__c action: actions)
            actionsByName.put(action.Label__c, action);

        return actionsByName;
    }

    private static Boolean canPerformAction(String objectType, String componentName, List_View_Action__c action)
    {
        Boolean result = true;
        if (!String.isEmpty(action.Permissions__c))
        {
            if (action.Permissions__c.contains(PERM_CREATE))
                result = HelperSchema.checkObjectCreateable(objectType, false);       
            if (action.Permissions__c.contains(PERM_EDIT))
                result = HelperSchema.checkObjectUpdateable(objectType, false);       
            if (action.Permissions__c.contains(PERM_DELETE))
                result = HelperSchema.checkObjectDeletable(objectType, false);       
            if (action.Permissions__c.contains(PERM_READ))
                result = HelperSchema.checkObjectAccessible(objectType, false);
        }

        //if the action is specific to a component.
        if (!String.isEmpty(action.Component_Name__c) && action.Component_Name__c != componentName)
            result = false;

        debugString += 'canPerformAction - ' + result + ' - ' + objectType + ' - ' + componentName + ' - ' + action.Primary_Key__c + ', ';
        return result;
    }

    global static String getAllListViewActions(String objectType, String listViewName, String componentName)
    {
        List<ListViewActionWrapper> actions = getListViewActions(objectType, listViewName, componentName);

        String actionsJSON = JSON.serialize(actions);

        return actionsJSON;
    }

    global static String processAction(String actionKey, String dataIds, String valuesMap)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewActionHelper.processAction(' + actionKey + ', ' + dataIds + ',' + valuesMap + ')');
    
        String responseStr = ListViewAction.RESULT_OK;
        List_View_Action__c action = null;

        try {
            action = ListViewActionHelper.getListViewActionByKey(actionKey);
        } catch (Exception e) {
            String message = 'Exception during ListViewActionHelper.processAction(' + actionKey + ',' + dataIds + ',' + valuesMap + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
            responseStr = ListViewAction.RESULT_ERROR + ':Couldn\'t find action config with provided key (' + actionKey + ').';
            return responseStr;
        }

        System.debug(LoggingLevel.DEBUG, 'Action - ' + action);
        
        Type t = null;
        try {
            // Get the Type corresponding to the class name
            t = HelperSchema.getClassType(action.Apex_Class_Name__c);
        } catch (Exception e) {
            responseStr = ListViewAction.RESULT_ERROR + ':Couldn\'t find apex class "' + action.Apex_Class_Name__c + '" for config with name ' + action.Label__c;
            return responseStr; 
        }
        
        //get the list of Ids of the records that are to be processed.
        List<Object> listIds = new List<Object>();
        if (!String.isBlank(dataIds))
            listIds = (List<Object>) JSON.deserializeUntyped(dataIds);
        List<String> listStrIds = new List<String>();
        for (Object listId: listIds)
            listStrIds.add((String) listId);

        //get the field/value pairs of the update data
        List<Object> listValues = new List<Object>();
        if (!String.isBlank(valuesMap))
            listValues = (List<Object>) JSON.deserializeUntyped(valuesMap);
        Map<String, Object> mapValues = new Map<String, Object>();
        for (Object key: listValues)
        {
            List<Object> keyValues = (List<Object>) key;
            mapValues.put( (String) keyValues[0], keyValues[1]);
        }

        //create the object from configuration.
        ListViewAction actionJob = null;
        
        //if we have a FLOW
        if (action.Is_Flow__c == true) {
            if (String.isEmpty(action.Flow_API_Name__c)) throw new ListViewException('Flow actions must have a flow API name');
            ListViewActionFlow actionFlow = (ListViewActionFlow) t.newInstance();
            actionFlow.setFlowName(action.Flow_API_Name__c);
            actionJob = actionFlow;

        //if we have a REGULAR ACTION
        } else {
            actionJob = (ListViewAction) t.newInstance();
        }

        //process the object
        try {
            responseStr = actionJob.process(listStrIds, mapValues);
        } catch (Exception e) {
            responseStr = ListViewAction.RESULT_ERROR + ':' + e.getMessage();
            String message = 'Exception during ListViewActionHelper.processAction(' + actionKey + ', ' + dataIds + ', ' + valuesMap + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
        }
        
        ListViewErrorHelper.processLogs(true);

        ListViewUserActivityHelper.registerAction('', '', actionKey, action.Id, listIds.size());

        return responseStr;
    }
}