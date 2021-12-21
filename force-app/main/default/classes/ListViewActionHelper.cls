/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 12-21-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   08-05-2020   tom@ansleyllc.com   Initial Version
 * 2.0   08-16-2021   tom@ansleyllc.com   Added permission check for each action before display
 * 3.0   08-20-2021   tom@ansleyllc.com   Updated strings to static final variables, added 2 new fields - Is_Hyperlink__c, Hyperlink_Target__c, new logic to handle whether actions are displayed based on user permissions
 * 4.0   08-20-2021   tom@ansleyllc.com   Removed Hyperlink_Target__c
**/
public with sharing class ListViewActionHelper {

    public static final Id coreRTId = Schema.SObjectType.List_View_Action__c.getRecordTypeInfosByDeveloperName().get('Core').getRecordTypeId();
    public static final Id customRTId = Schema.SObjectType.List_View_Action__c.getRecordTypeInfosByDeveloperName().get('Custom').getRecordTypeId();

    public static final String PERM_CREATE = 'Create';
    public static final String PERM_READ   = 'Read';
    public static final String PERM_EDIT   = 'Edit';
    public static final String PERM_DELETE = 'Delete';

    public static final String VIS_ALWAYS = 'Always displayed';
    public static final String VIS_ONLY_ONE = 'Displayed if one record is selected';
    public static final String VIS_AT_LEAST_ONE = 'Displayed if one or more records are selected';

    public static final String PARAM_KEY_URL = 'URL';

    private static String debugString = '';

    public static String getPrimaryKey(List_View_Action__c action)
    {
        return action.Label__c.deleteWhitespace() + ':' + action.Object_Type__c;
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

    /**
    * @description Method to retrieve the actions associated with an object and list view.
    * @author tom@ansleyllc.com | 08-15-2021 
    * @return Map<String, String> the primary key of the action and the action name
    **/
    public static List<ListViewAbstract.ActionWrapper> getListViewActions(String objectType, String listViewName, String componentName)
    {
        debugString += 'getListViewActions(' + objectType + ', ' + listViewName + ')';

        List<ListViewAbstract.ActionWrapper> actions = new List<ListViewAbstract.ActionWrapper>();

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
                actions.add(new ListViewAbstract.ActionWrapper(action));         
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
}