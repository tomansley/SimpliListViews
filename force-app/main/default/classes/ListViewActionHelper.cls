/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 08-16-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   tom.h.ansley@medtronic.com   Initial Version
 * 2.0   08-16-2021   tom.h.ansley@medtronic.com   Added permission check for each action before display
**/
public with sharing class ListViewActionHelper {

    public static final Id coreRTId = Schema.SObjectType.List_View_Action__c.getRecordTypeInfosByDeveloperName().get('Core').getRecordTypeId();
    public static final Id customRTId = Schema.SObjectType.List_View_Action__c.getRecordTypeInfosByDeveloperName().get('Custom').getRecordTypeId();

    public static final String PERM_CREATE = 'Create';
    public static final String PERM_READ   = 'Read';
    public static final String PERM_EDIT   = 'Edit';
    public static final String PERM_DELETE = 'Delete';

    public static String getPrimaryKey(List_View_Action__c action)
    {
        return action.Label__c.deleteWhitespace() + ':' + action.Object_Type__c;
    }

    public static Map<Id, List_View_Action__c> getListViewConfigs(Set<Id> actionIds) 
    {
        HelperSchema.checkListViewActionsAccessible();

        return new Map<Id, List_View_Action__c>([SELECT Label__c,
                                                        Apex_Class_Name__c,
                                                        Object_Type__c,
                                                        Primary_Key__c,
                                                        Subtype__c,
                                                        RecordTypeId,
                                                        RecordType.Name,
                                                        Permissions__c,
                                                        (SELECT Field_API_Name__c,
                                                                Label__c,
                                                                Display_Order__c,
                                                                Type__c,
                                                                Default_Value__c,
                                                                Placeholder_Text__c
                                                        FROM List_View_Action_Parameters__r
                                                        ORDER BY Display_Order__c NULLS LAST)
                                                FROM List_View_Action__c
                                                WHERE Id IN :actionIds]);
    }

    /*
     * Method to get a list view action based on its primary key
     */
    public static List_View_Action__c getListViewActionByKey(String primaryKey)
    {
        HelperSchema.checkListViewActionsAccessible();

        return [SELECT Label__c,
                        Apex_Class_Name__c,
                        Object_Type__c,
                        Primary_Key__c,
                        Subtype__c,
                        RecordTypeId,
                        RecordType.Name,
                        Permissions__c,
                        (SELECT Field_API_Name__c,
                                Label__c,
                                Display_Order__c,
                                Type__c,
                                Default_Value__c,
                                Placeholder_Text__c
                         FROM List_View_Action_Parameters__r
                         ORDER BY Display_Order__c NULLS LAST)
                FROM List_View_Action__c
                WHERE Primary_Key__c = :primaryKey];
    }

    /**
    * @description Method to retrieve the actions associated with an object and list view.
    * @author tom.h.ansley@medtronic.com | 08-15-2021 
    * @return Map<String, String> the primary key of the action and the action name
    **/
    public static Map<String, String> getListViewActionsForListView(String objectType, String listViewName)
    {
        Map<String, String> actions = new Map<String, String>();

        //get the list view
        List_View__c listview = ListViewHelper.getListViews(objectType, listViewName).values()[0];

        //get the actions based on the list view
        Map<String, List_View_Action__c> lvActions = ListViewActionHelper.getListViewActionsByListView(listview);

        for (String actionName: lvActions.keySet())
        {
            List_View_Action__c action = lvActions.get(actionName);
            if (canPerformAction(objectType, action))
                actions.put(actionName, action.Primary_Key__c);         
        }

        return actions;
    }

    public static Boolean canPerformAction(String objectType, List_View_Action__c action)
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
        return result;
    }

    /**
    * @description Method to get all list view actions given the object name and list view type
    *              Note that any actions with an object type of NULL are also returned as these
    *              actions are universal.
    * @author tom.h.ansley@medtronic.com | 10-31-2020 
    * @param objectType the object type of the actions to be returned.
    * @param listViewType one of All, Core or Custom
    * @return Map<String, List_View_Action__c> returned as follows - (API Name, Action)
    **/
    public static Map<String, List_View_Action__c> getListViewActionsByListView(List_View__c listview)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting getListViewActionsByListView(' + listview + ')');
        HelperSchema.checkListViewActionsAccessible();

        Id rt = ListViewActionHelper.coreRTId;
        if (listview.RecordTypeId == ListViewHelper.customRTId)
            rt = ListViewActionHelper.customRTId;

        Set<String> subTypes = new Set<String>();
        if (listview.RecordTypeId == ListViewHelper.customRTId)
            subTypes.add(listview.Subtype__c);

        //get list view data
        List<List_View_Action__c> actions = [SELECT Label__c,
                                                Apex_Class_Name__c,
                                                Object_Type__c,
                                                Primary_Key__c,
                                                Subtype__c,
                                                RecordTypeId,
                                                RecordType.Name,
                                                Permissions__c
                                            FROM List_View_Action__c
                                            WHERE RecordTypeId = :rt
                                                    AND (Object_Type__c = :listview.Object_Name__c
                                                        OR Object_Type__c = NULL)
                                                    AND (Subtype__c = NULL
                                                        OR Subtype__c IN :subTypes)
                                             ORDER BY Label__c];

        Map<String, List_View_Action__c> actionsByName = new Map<String, List_View_Action__c>();
        for (List_View_Action__c action: actions)
            actionsByName.put(action.Label__c, action);

        return actionsByName;
    }
}