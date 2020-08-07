/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 08-06-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   tom.h.ansley@medtronic.com   Initial Version
**/
@isTest
private class ListViewConfigHelperTest {

    @testSetup
    private static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

    @IsTest
    static void setOrgWideConfigTest()
    {
    
        Test.startTest();
            
            ListViewConfigHelper.setOrgWideConfigParam('List View Objects', 'Test Setting');
            
        Test.stopTest();

        String value = ListViewConfigHelper.getOrgWideConfigParam('List View Objects');

        System.assert(value == 'Test Setting');
    }

    @IsTest
    static void testValidateFieldCondition()
    {

        String name = 'Burlington Coat Factory';

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = 'Account Name';
        condition.Operator__c         = 'Contains';
        condition.Value__c            = 'Burlington';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = '#c59e9e';

        Boolean result = ListViewConfigHelper.validateFieldCondition(name, condition);

        System.assert(result == true);

        name = 'Sterlington Coat Factory';
        
        result = ListViewConfigHelper.validateFieldCondition(name, condition);

        System.assert(result == false);

    }

}