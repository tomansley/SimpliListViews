/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 02-03-2022
 * @last modified by  : tom@ansleyllc.com
**/
@isTest
private class HelperBatchTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

 	@isTest
	static void HelperBatchUpdateTest()
	{
        Account acc = HelperTest.insertAccount('Batch Test Insert Account');

        Test.startTest();
            Map<String, Object> vars = new Map<String, Object>();
            vars.put(HelperBatch.VAR_SOQL_STATEMENT, 'SELECT Id FROM Account WHERE Name = \'Batch Test Insert Account\'');
            vars.put(HelperBatch.VAR_BATCH_SIZE, 100);
            vars.put(HelperBatch.VAR_OPERATION, HelperBatch.OPER_UPDATE);

            Map<String,Object> fieldUpdates = new Map<String,Object>();
            fieldUpdates.put('AnnualRevenue', 12010.00);
            fieldUpdates.put('AccountNumber', '1221543543');
            vars.put(HelperBatch.VAR_FIELD_UPDATES, fieldUpdates);

            HelperBatch job = new HelperBatch(vars);
            Database.executeBatch(job);

        Test.stopTest();

        List<Account> updatedAccs = [SELECT Id, AnnualRevenue, AccountNumber FROM Account WHERE Name = 'Batch Test Insert Account'];

        System.assertEquals(1, updatedAccs.size());
        System.assertEquals(12010.00, updatedAccs[0].AnnualRevenue);
        System.assertEquals('1221543543', updatedAccs[0].AccountNumber);

    }

    @isTest
	static void HelperBatchDeleteTest()
	{
        Account acc = HelperTest.insertAccount('Batch Test Insert Account');

        Test.startTest();
            Map<String, Object> vars = new Map<String, Object>();
            vars.put(HelperBatch.VAR_OBJECT_TYPE, 'Account');
            vars.put(HelperBatch.VAR_BATCH_SIZE, 100);
            vars.put(HelperBatch.VAR_OPERATION, HelperBatch.OPER_DELETE);
            vars.put(HelperBatch.VAR_HARD_DELETE, true);

            HelperBatch job = new HelperBatch(vars);
            Database.executeBatch(job);

        Test.stopTest();

        List<Account> updatedAccs = [SELECT Id, AnnualRevenue, AccountNumber FROM Account WHERE Name = 'Batch Test Insert Account'];

        System.assertEquals(0, updatedAccs.size());

    }

}