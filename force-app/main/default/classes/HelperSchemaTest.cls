/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 09-09-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-06-2020   tom.h.ansley@medtronic.com   Initial Version
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

        Object value = HelperSchema.getValueForField('Account', 'Name', HelperSchema.NAME, 'Test Account Name');

        System.assert(value instanceof String);

        Boolean deletable = HelperSchema.checkObjectDeletable('Account', false);

        System.assert(deletable != null);

        String typeName = HelperSchema.getSObjectTypeFromId(UserInfo.getUserId());

        System.assertEquals('User', typeName);

        Boolean isValid = HelperSchema.isValidSFDCFieldName('Account', 'Name');

        HelperSchema.checkObjectFieldAccessible('Account', 'Name');

        HelperSchema.checkObjectDeletable('Account', false);

        HelperSchema.getObjectTypeForField('Account', 'Name');

        HelperTest.insertAccount('Test Account');
        HelperSchema.checkSelectAccessible('SELECT Id FROM Account');
        Account acc = [SELECT Id FROM Account LIMIT 1];
        HelperSchema.checkObjectDeletable(acc);

    }
}