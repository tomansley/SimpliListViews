/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-05-2022
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-20-2021   tom@ansleyllc.com   Initial Version
 * 2.0   11-03-2021   tom@ansleyllc.com   Added getRecordName() method
 * 3.0   12-15-2021   tom@ansleyllc.com   Removed old methods for checking object accessibility.
**/
public with sharing class ListViewLookupController {
    
    @AuraEnabled(cacheable=true)
    public static List<sObject> search(String searchTerm, String obj) {
        String soql = null;

        if(searchTerm == null || searchTerm == ''){
            soql = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(obj) + ' WHERE LastViewedDate != NULL ORDER BY LastViewedDate DESC LIMIT 5'; 
        }
        else {
            soql = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(obj) + ' WHERE Name Like  \'%' + String.escapeSingleQuotes(searchTerm) + '%\' LIMIT 5';
        }
        
        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, database.query(soql));
        
        List<sObject> lookUpList = dec.getRecords();

        return lookUpList;  
    }

    @AuraEnabled
    public static String getRecordName(String selectedId, String fieldObjName){
        
        String soql = 'SELECT Id, Name FROM ' + String.escapeSingleQuotes(fieldObjName) + ' WHERE Id = \'' + String.escapeSingleQuotes(selectedId) + '\'';

        return (String) Database.query(soql)[0].get('Name');
    }

}