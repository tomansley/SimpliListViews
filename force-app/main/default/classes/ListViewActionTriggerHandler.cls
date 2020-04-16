public with sharing class ListViewActionTriggerHandler {

    /*
     * Method which takes a set of List_View_Action__c records that are being inserted 
     * and executes logic BEFORE the records have been INSERTED.
     * @param newRecords the list of List_View_Action__c records
     */ 
    public static void onBeforeInsert(List<List_View_Action__c> newRecords)
    {
        ListViewActionBL.validateObjectType(newRecords);
        ListViewActionBL.setPrimaryKey(newRecords);
    }
    
    /*
     * Method which takes a set of List_View_Action__c records that are being inserted 
     * and executes logic AFTER the records have been INSERTED.
     * @param newRecords the map of List_View_Action__c records and their new id's
     */ 
    public static void onAfterInsert(Map<Id, List_View_Action__c> newRecords)
    { 

    }
    
    /*
     * Method which takes a set of List_View_Action__c records that are being updated 
     * and executes logic BEFORE the records have been UPDATED.
     * @param newRecords the map of new List_View_Action__c records
     * @param oldRecords the map of old List_View_Action__c records
     */ 
    public static void onBeforeUpdate(Map<Id, List_View_Action__c> newRecords, Map<Id, List_View_Action__c> oldRecords)
    {
        ListViewActionBL.validateObjectType(newRecords.values());
        ListViewActionBL.setPrimaryKey(newRecords.values());
    }

    /*
     * Method which takes a set of List_View_Action__c records that are being updated 
     * and executes logic AFTER the records have been UPDATED.
     * @param newRecords the map of new List_View_Action__c records
     * @param oldRecords the map of old List_View_Action__c records
     */ 
    public static void onAfterUpdate(Map<Id, List_View_Action__c> newRecords, Map<Id, List_View_Action__c> oldRecords)
    {

    }
}