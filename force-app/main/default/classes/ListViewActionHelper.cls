/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 09-09-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewActionHelper {


    public static Map<Id, List_View_Action__c> getListViewConfigs(Set<Id> actionIds) 
    {
        HelperSchema.checkListViewActionsAccessible();

        return new Map<Id, List_View_Action__c>([SELECT Label__c,
                                                        Apex_Class_Name__c,
                                                        Object_Type__c,
                                                        Primary_Key__c,
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

    /*
     * Method to get all list view actions for a provided object.
     * The map is returned as follows - (API Name, List View)
     */
    public static Map<String, List_View_Action__c> getListViewActionsByObject(String objectType)
    {
        HelperSchema.checkListViewActionsAccessible();

        //get list view data
        List<List_View_Action__c> actions = [SELECT Label__c,
                                                Apex_Class_Name__c,
                                                Object_Type__c,
                                                Primary_Key__c
                                        FROM List_View_Action__c
                                        WHERE Object_Type__c = :objectType
                                            OR Object_Type__c = NULL
                                        ORDER BY Label__c];

        Map<String, List_View_Action__c> actionsByName = new Map<String, List_View_Action__c>();
        for (List_View_Action__c action: actions)
            actionsByName.put(action.Label__c, action);

        return actionsByName;
    }
}