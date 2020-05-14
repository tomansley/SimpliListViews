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
    }
}