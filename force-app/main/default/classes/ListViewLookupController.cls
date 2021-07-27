/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 07-26-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-20-2021   tom.h.ansley@medtronic.com   Initial Version
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
        
        HelperSchema.checkSelectAccessible(soql);
        
        List<sObject> lookUpList = database.query(soql);

        return lookUpList;  
    }

}