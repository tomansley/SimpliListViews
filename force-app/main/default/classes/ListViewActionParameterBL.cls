/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-04-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-05-2020   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewActionParameterBL {
    
    public static void validate(List<List_View_Action_Parameter__c> newRecords)
    {

        Set<Id> actionIds = new Set<Id>();
        for (List_View_Action_Parameter__c param: newRecords)
            actionIds.add(param.List_View_Action__c);

        Map<Id, List_View_Action__c> actions = ListViewActionHelper.getListViewActions(actionIds);

        for (List_View_Action_Parameter__c param: newRecords)
        {
            if (param.Type__c == ListViewHelper.TYPE_LOOKUP && String.isEmpty(param.Lookup_Type__c))
                param.addError('A lookup type must be provided when adding a lookup parameter. The type should be set to the API name of the object that the field looks up to.');
        }

    }

}