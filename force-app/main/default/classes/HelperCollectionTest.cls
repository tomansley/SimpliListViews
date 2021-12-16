/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 12-16-2021
 * @last modified by  : tom@ansleyllc.com
**/
@isTest
public with sharing class HelperCollectionTest {
    
    public static testMethod void HelperCollectionTestMethod() {
        
        List<SObject> accounts = new List<Account>();
        Account acc= HelperTest.insertAccount('Test');
        
        accounts.add(acc);
        String fieldName='Name';
        String fieldId = 'Id';
        
        System.assert(HelperCollection.getIdFieldSet(accounts,fieldId).size() > 0);  
        System.assert(HelperCollection.getIdFieldList(accounts,fieldId).size() > 0);  
        System.assert(HelperCollection.getStringFieldSet(accounts,fieldName).size() > 0); 
        System.assert(HelperCollection.getStringFieldList(accounts,fieldName).size() > 0);
        System.assert(HelperCollection.getIdMappedObjects(accounts,fieldId).size() > 0);
        System.assert(HelperCollection.getStringMappedObjects(accounts,fieldName).size() > 0);
        
    }
}