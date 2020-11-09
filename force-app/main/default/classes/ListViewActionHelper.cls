/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 11-02-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewActionHelper {

    public static final Id coreRTId = Schema.SObjectType.List_View_Action__c.getRecordTypeInfosByDeveloperName().get('Core').getRecordTypeId();
    public static final Id customRTId = Schema.SObjectType.List_View_Action__c.getRecordTypeInfosByDeveloperName().get('Custom').getRecordTypeId();
   
    public static final String SUBTYPE_MANUAL = 'Manual';
    public static final String SUBTYPE_TOOLING = 'Tooling';
    public static final String SUBTYPE_METADATA = 'Metadata';

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
                                                RecordType.Name
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