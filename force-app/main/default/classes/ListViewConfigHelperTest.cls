/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 08-20-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   tom.h.ansley@medtronic.com   Initial Version
 * 2.0   08-18-2021   tom.h.ansley@medtronic.com   Updated strings to static final variables
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
            
            ListViewConfigHelper.setOrgWideConfigParam('ListViewObjects', 'Test Setting');
            
        Test.stopTest();

        String value = ListViewConfigHelper.getOrgWideConfigParam('ListViewObjects');

        System.assert(value == 'Test Setting');
    }

    @IsTest
    static void testValidateFieldCondition()
    {

        String name = 'Burlington Coat Factory';
        String type = ListViewHelper.TYPE_STRING;

        List<List_View_Config_Condition__c> conditions = new List<List_View_Config_Condition__c>();

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = 'Account Name';
        condition.Operator__c         = 'Contains';
        condition.Value__c            = 'Burlington';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = '#c59e9e';
        conditions.add(condition);

        String result = ListViewConfigHelper.validateFieldCondition(name, type, conditions);

        System.assert(result != '');

        name = 'Sterlington Coat Factory';
        
        result = ListViewConfigHelper.validateFieldCondition(name, type, conditions);

        System.assert(result == '');

    }

    @IsTest
    static void testAddDeleteCondition()
    {
        //create a list view
        List<List_View__c> listViews = HelperTest.createCoreListViews();

        Boolean conditionAdded = true;

        try {
            ListViewConfigHelper.addListViewCondition('Account', 'AllAccounts', 'CreatedBy.Name', 'Equals', 'Testerson', '1', '#000000');

            HelperSchema.checkListViewConfigsAccessible();
            List_View_Config_Condition__c condition = [SELECT Id FROM List_View_Config_Condition__c WHERE Value__c = 'Testerson'];

            ListViewConfigHelper.deleteListViewCondition(condition.Id);

        } catch (Exception e) {
            conditionAdded = false;
        }

        System.assert(conditionAdded);
    }

    @IsTest
    static void testParamLifeCycle()
    {
        //create a list view
        List<List_View__c> listViews = HelperTest.createCoreListViews();

        HelperSchema.checkListViewConfigsAccessible();
        List_View_Config__c config = [SELECT Id FROM List_View_Config__c WHERE Primary_Key__c = 'Account:AllAccounts'];

        //get the parameters of the created list view
        List<List_View_Config_Parameter__c> params = [SELECT Id FROM List_View_Config_Parameter__c WHERE List_View_Config__c = :config.Id];

        Test.startTest();

        System.assert(params.size() > 0);

        String result = ListViewConfigHelper.updateListViewParam('Account', 'AllAccounts', 'AdditionalFields', 'CreatedBy.Name, Owner.Profile.Name', 'Additional Fields', ListViewHelper.TYPE_STRING);

        System.assert(result == '');

        result = ListViewConfigHelper.updateListViewParam('Account', 'AllAccounts', 'AdditionalFields', 'CreatedBy.Name, Owner.Profile.Na', 'Additional Fields', ListViewHelper.TYPE_STRING);

        System.assert(result != '');

        result = ListViewConfigHelper.updateListViewParam('Account', 'AllAccounts', 'RefreshRate', '45', 'Refresh Rate', ListViewHelper.TYPE_NUMBER);

        System.assert(result == '');

        result = ListViewConfigHelper.updateListViewParam('Account', 'AllAccounts', 'ReturnSize', '123', 'Return Size', ListViewHelper.TYPE_NUMBER);

        System.assert(result == '');

        result = ListViewConfigHelper.updateListViewParam('Account', 'AllAccounts', 'AllRows', 'true', 'All Rows', ListViewHelper.TYPE_BOOLEAN);

        System.assert(result == '');

        Test.stopTest();

    }

}