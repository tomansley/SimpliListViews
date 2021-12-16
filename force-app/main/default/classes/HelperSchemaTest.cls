/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 12-16-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   08-06-2020   tom@ansleyllc.com   Initial Version
**/
@IsTest
public with sharing class HelperSchemaTest {
    
    @IsTest
    static void HelperSchemaMethodTests() {
        
        String str = HelperSchema.getFieldLookupObject('User', 'ProfileId');

        System.assertEquals('Profile', str);

        Boolean bool = HelperSchema.isValidSFDCObjectName('Account');

        System.assertEquals(true, bool);

        Schema.SObjectField field = HelperSchema.getFieldByKey('Account', 'AnnualRevenue', HelperSchema.NAME);

        System.assert(field != null);

        Schema.DescribeFieldResult fieldDesc = HelperSchema.getFieldDescribeResult('Account', 'AnnualRevenue');

        System.assert(fieldDesc != null);

        Map<String, Schema.SObjectField> fields = HelperSchema.getFieldsForObject('Account', HelperSchema.LABEL);

        System.assert(fields.size() > 0);

        HelperSchema.getObjectFieldDebug('Account', HelperSchema.LABEL, fields);

        Schema.DisplayType fieldType = HelperSchema.getFieldType('Account', 'AnnualRevenue');

        System.assert(fieldType == Schema.DisplayType.CURRENCY);

        Schema.DescribeSObjectResult objSchema = HelperSchema.getObjectSchema('Account');

        Object value = HelperSchema.getValueForField('Account', 'Name', 'Test Account Name');

        System.assert(value instanceof String);

        Boolean deletable = HelperSchema.checkObjectDeletable('Account', false);

        System.assert(deletable != null);

        String typeName = HelperSchema.getSObjectTypeFromId(UserInfo.getUserId());

        System.assertEquals('User', typeName);

        Boolean isValid = HelperSchema.isValidSFDCFieldName('Account', 'Name');
        System.assertEquals(true, isValid);
        isValid = HelperSchema.isValidSFDCFieldName('Account', 'LastModifiedBy.Name');
        System.assertEquals(true, isValid);
        isValid = HelperSchema.isValidSFDCFieldName('Account', 'LastModifiedBy.Profile.Name');
        System.assertEquals(true, isValid);
        isValid = HelperSchema.isValidSFDCFieldName('List_View_Config_Condition__c', 'simpli_lv__Highlight_Color__c');
        System.assertEquals(true, isValid);
        isValid = HelperSchema.isValidSFDCFieldName('simpli_lv__List_View_Config_Condition__c', 'simpli_lv__Highlight_Color__c');
        System.assertEquals(true, isValid);

        HelperSchema.checkObjectDeletable('Account', false);

        HelperSchema.getObjectTypeForField('Account', 'Name');

        HelperTest.insertAccount('Test Account');
        Account acc = [SELECT Id FROM Account LIMIT 1];
        HelperSchema.checkObjectDeletable(acc);

        System.assertEquals('coreid', HelperSchema.getFieldRelationshipType('Account','LastModifiedBy'));  
        System.assertEquals('field', HelperSchema.getFieldRelationshipType('Account','Name'));
        System.assertEquals('childrel', HelperSchema.getFieldRelationshipType('Opportunity','OpportunityLineItems'));
        System.assertEquals('coreid', HelperSchema.getFieldRelationshipType('OpportunityLineItem','Product2'));
        System.assertEquals('field', HelperSchema.getFieldRelationshipType('Product2','ProductCode'));

        System.assertEquals('Product Code', HelperSchema.getSFDCFieldLabel('Opportunity','OpportunityLineItems.Product2.ProductCode'));

    }

    @IsTest
    static void HelperSchemaGetClassTests() {
        HelperSchema.getClassType('ListViewCore');          
    }
    
}