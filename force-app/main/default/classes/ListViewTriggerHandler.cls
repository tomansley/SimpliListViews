/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-23-2020   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewTriggerHandler {

        /*
         * Method which takes a set of List_View__c records that are being inserted 
         * and executes logic BEFORE the records have been INSERTED.
         * @param newRecords the list of List_View__c records
         */ 
        public static void onBeforeInsert(List<List_View__c> newRecords)
        {
            ListViewBL.setFields(newRecords);

            ListViewBL.validate(newRecords); //validate at end so that we can set all fields before hand.
        }
        
        /*
         * Method which takes a set of List_View__c records that are being inserted 
         * and executes logic AFTER the records have been INSERTED.
         * @param newRecords the map of List_View__c records and their new id's
         */ 
        public static void onAfterInsert(Map<Id, List_View__c> newRecords)
        { 
            ListViewBL.updateCoreListViewId(newRecords);

            ListViewBL.updateListViewConfigs(newRecords);
        }
        
        /*
         * Method which takes a set of List_View__c records that are being updated 
         * and executes logic BEFORE the records have been UPDATED.
         * @param newRecords the map of new List_View__c records
         * @param oldRecords the map of old List_View__c records
         */ 
        public static void onBeforeUpdate(Map<Id, List_View__c> newRecords, Map<Id, List_View__c> oldRecords)
        {
            ListViewBL.updateFields(newRecords, oldRecords);
        }
    
        /*
         * Method which takes a set of List_View__c records that are being updated 
         * and executes logic AFTER the records have been UPDATED.
         * @param newRecords the map of new List_View__c records
         * @param oldRecords the map of old List_View__c records
         */ 
        public static void onAfterUpdate(Map<Id, List_View__c> newRecords, Map<Id, List_View__c> oldRecords)
        {
            ListViewBL.updateListViewConfigs(newRecords);
        }
    }