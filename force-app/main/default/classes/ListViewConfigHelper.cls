public with sharing class ListViewConfigHelper {
    
    public static List<List_View_Config__c> getListViewConfig(String objectType, String listViewName) 
    {
        return [SELECT Name,
                       List_View_Object__c,
                       (SELECT Parameter_Name__c,
                               Parameter_Type__c,
                               Parameter_Value__c
                        FROM List_View_Config_Parameters__r)
                FROM List_View_Config__c
                WHERE Name = :listViewName
                    AND List_View_Object__c = :objectType];
    }

}