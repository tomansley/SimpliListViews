/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 11-05-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-05-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewActionParameterBL {
    
    public static void validateFieldNames(List<List_View_Action_Parameter__c> newRecords)
    {

        Set<Id> actionIds = new Set<Id>();
        for (List_View_Action_Parameter__c param: newRecords)
            actionIds.add(param.List_View_Action__c);

        Map<Id, List_View_Action__c> actions = ListViewActionHelper.getListViewConfigs(actionIds);

        for (List_View_Action_Parameter__c param: newRecords)
        {
        }

    }

}