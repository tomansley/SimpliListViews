/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 07-25-2024
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-05-2020   tom@ansleyllc.com   Initial Version
 * 2.0   08-18-2021   tom@ansleyllc.com   Updated strings to static final variables
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
    static void testValidateStringFieldConditions()
    {

        String HIGHLIGHT_COLOR = '#c59e9e';

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = 'Name';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = HIGHLIGHT_COLOR;

        //-------------------------------------------------------------------------------------
        //CONTAINS
        condition.Operator__c         = ListViewConfigHelper.OPER_CONTAINS;
        condition.Value__c            = 'Burlington';
        String value = 'Burlington Coat Factory';
        String type = ListViewHelper.TYPE_STRING;

        //POSITIVE TEST
        String result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = 'Sterlington Coat Factory';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_EQUAL;
        condition.Value__c            = 'Burlington';
        value = 'Burlington';

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = 'Burlington Coat Factory';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //NOT EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_NOT_EQUAL;
        condition.Value__c            = 'Burlington';
        value = 'Burlington';

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = 'Burlington Coat Factory';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //GREATER THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_GREATER;
        condition.Value__c            = 'Burlington1';
        value = 'Burlington';

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = 'Burlington2';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //LESS THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_LESS;
        condition.Value__c            = 'Burlington1';
        value = 'Burlington';

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = 'Burlington2';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

    }

    @IsTest
    static void testValidateDecimalFieldConditions()
    {

        String HIGHLIGHT_COLOR = '#c59e9e';

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = 'AccountNumber';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = HIGHLIGHT_COLOR;

        //-------------------------------------------------------------------------------------
        //CONTAINS
        condition.Operator__c         = ListViewConfigHelper.OPER_CONTAINS;
        condition.Value__c            = '5';
        Decimal value = Decimal.valueOf('34657');
        String type = ListViewHelper.TYPE_DECIMAL;

        //POSITIVE TEST
        String result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = Decimal.valueOf('1234');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_EQUAL;
        condition.Value__c            = '5';
        value = Decimal.valueOf('5');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = Decimal.valueOf('4');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //NOT EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_NOT_EQUAL;
        condition.Value__c            = '5';
        value = Decimal.valueOf('5');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = Decimal.valueOf('4');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //GREATER THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_GREATER;
        condition.Value__c            = '5';
        value = Decimal.valueOf('4');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = Decimal.valueOf('6');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //LESS THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_LESS;
        condition.Value__c            = '5';
        value = Decimal.valueOf('4');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = Decimal.valueOf('6');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

    }

    @IsTest
    static void testValidateIntegerFieldConditions()
    {

        String HIGHLIGHT_COLOR = '#c59e9e';

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = 'AccountNumber';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = HIGHLIGHT_COLOR;

        //-------------------------------------------------------------------------------------
        //CONTAINS
        condition.Operator__c         = ListViewConfigHelper.OPER_CONTAINS;
        condition.Value__c            = '5';
        Integer value = Integer.valueOf('34657');
        String type = ListViewHelper.TYPE_INTEGER;

        //POSITIVE TEST
        String result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = Integer.valueOf('1234');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_EQUAL;
        condition.Value__c            = '5';
        value = Integer.valueOf('5');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = Integer.valueOf('4');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //NOT EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_NOT_EQUAL;
        condition.Value__c            = '5';
        value = Integer.valueOf('5');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = Integer.valueOf('4');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //GREATER THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_GREATER;
        condition.Value__c            = '5';
        value = Integer.valueOf('4');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = Integer.valueOf('6');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //LESS THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_LESS;
        condition.Value__c            = '5';
        value = Integer.valueOf('4');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = Integer.valueOf('6');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

    }

    @IsTest
    static void testValidateDoubleFieldConditions()
    {

        String HIGHLIGHT_COLOR = '#c59e9e';

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = 'AccountNumber';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = HIGHLIGHT_COLOR;

        //-------------------------------------------------------------------------------------
        //CONTAINS
        condition.Operator__c         = ListViewConfigHelper.OPER_CONTAINS;
        condition.Value__c            = '5';
        Double value = Double.valueOf('34657');
        String type = ListViewHelper.TYPE_DOUBLE;

        //POSITIVE TEST
        String result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = Double.valueOf('1234');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_EQUAL;
        condition.Value__c            = '5';
        value = Double.valueOf('5');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = Double.valueOf('4');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //NOT EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_NOT_EQUAL;
        condition.Value__c            = '5';
        value = Double.valueOf('5');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = Double.valueOf('4');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //GREATER THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_GREATER;
        condition.Value__c            = '5';
        value = Double.valueOf('4');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = Double.valueOf('6');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //LESS THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_LESS;
        condition.Value__c            = '5';
        value = Double.valueOf('4');

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = Double.valueOf('6');
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

    }

    @IsTest
    static void testValidateDateFieldConditions()
    {

        String HIGHLIGHT_COLOR = '#c59e9e';

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = 'AccountDate';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = HIGHLIGHT_COLOR;

        //-------------------------------------------------------------------------------------
        //CONTAINS
        condition.Operator__c         = ListViewConfigHelper.OPER_CONTAINS;
        condition.Value__c            = '2021-07-06';
        String value = '1625547600000';
        String type = ListViewHelper.TYPE_DATE;

        //POSITIVE TEST
        String result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = '1625547600000';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_EQUAL;
        condition.Value__c            = '2021-07-06';
        value = '1625547600000';

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = '1725549000000';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //NOT EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_NOT_EQUAL;
        condition.Value__c            = '2021-07-06';
        value = '1625547600000';

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = '1635547600000';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //GREATER THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_GREATER;
        condition.Value__c            = '2021-07-06';


        //EQUAL TEST
        value = '1625547600000';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == '');

        //NEGATIVE TEST
        value = '1615547500000';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == '');

        //POSITIVE TEST
        value = '1665547700000';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //LESS THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_LESS;
        condition.Value__c            = '2021-07-06';
        value = '1625547500000';

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = '1625547700000';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

    }

    @IsTest
    static void testValidateDateTimeFieldConditions()
    {

        String HIGHLIGHT_COLOR = '#c59e9e';

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = 'AccountDateTime';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = HIGHLIGHT_COLOR;

        //-------------------------------------------------------------------------------------
        //CONTAINS
        condition.Operator__c         = ListViewConfigHelper.OPER_CONTAINS;
        condition.Value__c            = '2021-07-06 08:27:00 AM';
        String value = '1625578020000';

        String type = ListViewHelper.TYPE_DATETIME;

        //POSITIVE TEST
        String result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = '1625578020000';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_EQUAL;
        condition.Value__c            = '2021-07-06 08:27:00 AM';
        value = '1625578020000';

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = '1625578030000';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //NOT EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_NOT_EQUAL;
        condition.Value__c            = '2021-07-06 08:27:00 AM';
        value = '1625578020000';

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = '1625577020000';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //GREATER THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_GREATER;
        condition.Value__c            = '2021-07-06 08:27:00 AM';
        value = '1625578010000';

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');

        //NEGATIVE TEST
        value = '1625578030000';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //LESS THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_LESS;
        condition.Value__c            = '2021-07-06 08:27:00 AM';
        value = '1625577020000';

        //POSITIVE TEST
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = '1625588020000';
        
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);

        System.assert(result == '');
        //-------------------------------------------------------------------------------------

    }

    @IsTest
    static void testValidateTimeFieldConditions()
    {

        String HIGHLIGHT_COLOR = '#c59e9e';

        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = 'AccountTime';
        condition.Order__c            = '1';
        condition.Highlight_Color__c  = HIGHLIGHT_COLOR;

        //-------------------------------------------------------------------------------------
        //CONTAINS
        condition.Operator__c         = ListViewConfigHelper.OPER_CONTAINS;
        condition.Value__c            = '06:45:00 AM';

        String type = ListViewHelper.TYPE_TIME;

        //POSITIVE TEST
        String value = '06:45:00 AM';
        String result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == '');

        //NEGATIVE TEST
        value = '06:45:00 AM';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_EQUAL;
        condition.Value__c            = '06:45:00 AM';

        //POSITIVE TEST
        value = '06:45:00 AM';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = '06:45:00 PM';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == '');
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //NOT EQUALS
        condition.Operator__c         = ListViewConfigHelper.OPER_NOT_EQUAL;
        condition.Value__c            = '06:45:00 AM';

        //NEGATIVE TEST
        value = '06:45:00 AM';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == '');

        //POSITIVE TEST
        value = '06:45:01 AM';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //GREATER THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_GREATER;
        condition.Value__c            = '06:45:00 AM';

        //NEGATIVE TEST
        value = '06:44:00 AM';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == '');

        //POSITIVE TEST
        value = '06:45:01 AM';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == HIGHLIGHT_COLOR);
        //-------------------------------------------------------------------------------------

        //-------------------------------------------------------------------------------------
        //LESS THAN
        condition.Operator__c         = ListViewConfigHelper.OPER_LESS;
        condition.Value__c            = '06:45:00 AM';

        //POSITIVE TEST
        value = '06:44:59 AM';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == HIGHLIGHT_COLOR);

        //NEGATIVE TEST
        value = '06:45:01 AM';
        result = ListViewConfigHelper.validateFieldCondition(value, type, condition);
        System.assert(result == '');
        //-------------------------------------------------------------------------------------

    }

    @IsTest
    static void testAddDeleteCondition()
    {
        //create a list view
        List<List_View__c> listViews = HelperTest.createCoreListViews();

        Boolean conditionAdded = true;

        try {
            ListViewConfigHelper.addListViewCondition('Account', 'simpli_lv__AllAccounts', 'CreatedBy.Name', 'Equals', 'Testerson', '1', '#000000');

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

        List_View_Config__c config = [SELECT Id FROM List_View_Config__c WHERE Primary_Key__c = 'Account:simpli_lv__AllAccounts'];

        //get the parameters of the created list view
        List<List_View_Config_Parameter__c> params = [SELECT Id FROM List_View_Config_Parameter__c WHERE List_View_Config__c = :config.Id];

        Test.startTest();

        System.assert(params.size() > 0);

        String result = ListViewConfigHelper.updateListViewParam('Account', 'simpli_lv__AllAccounts', ListViewHelper.PARAM_ADD_FIELDS, 'CreatedBy.Name, Owner.Profile.Name', 'Additional Fields', ListViewHelper.TYPE_STRING);

        System.assert(result == '');

        result = ListViewConfigHelper.updateListViewParam('Account', 'simpli_lv__AllAccounts', ListViewHelper.PARAM_ADD_FIELDS, 'CreatedBy.Name, Owner.Profile.Na', 'Additional Fields', ListViewHelper.TYPE_STRING);

        System.assert(result != '');

        result = ListViewConfigHelper.updateListViewParam('Account', 'simpli_lv__AllAccounts', 'RefreshRate', '45', 'Refresh Rate', ListViewHelper.TYPE_NUMBER);

        System.assert(result == '');

        result = ListViewConfigHelper.updateListViewParam('Account', 'simpli_lv__AllAccounts', 'ReturnSize', '123', 'Return Size', ListViewHelper.TYPE_NUMBER);

        System.assert(result == '');

        result = ListViewConfigHelper.updateListViewParam('Account', 'simpli_lv__AllAccounts', 'AllRows', 'true', 'All Rows', ListViewHelper.TYPE_BOOLEAN);

        System.assert(result == '');

        Test.stopTest();

    }

}