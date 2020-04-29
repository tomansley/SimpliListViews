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

    public class ListViewActionParameterException extends Exception {}
}