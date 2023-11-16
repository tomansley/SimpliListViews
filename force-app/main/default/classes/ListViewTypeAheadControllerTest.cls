@isTest
public with sharing class ListViewTypeAheadControllerTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();

        HelperTest.createCoreListViews();
    }

    @isTest
	static void searchSchemaTest()
	{
        Test.startTest();

            List<ListViewController.SelectOption> options = ListViewTypeAheadController.search('schema', 'Acc', 'SObject', 'Label', 'Name', null);
            System.assert(options.size() > 0);

            options = ListViewTypeAheadController.search('schema', 'Contact', 'SObject', 'Label', 'Name', 'simpli_lv__Object_Name__c NOT IN [\'Contact\']');

            Test.stopTest();
    }

    @isTest
	static void searchSObjectTest()
	{
        Test.startTest();

            List<ListViewController.SelectOption> options = ListViewTypeAheadController.search('sobject', 'Acc', 'simpli_lv__List_View__c', 'simpli_lv__Label__c', 'simpli_lv__API_Name__c', 'simpli_lv__Object_Name__c = \'Account\'');
            System.assert(options.size() > 0);

            Test.stopTest();
    }

    @isTest
	static void getRecordNameTest()
	{
        Account acc = HelperTest.insertAccount('getRecordName');
        Test.startTest();

            String name = ListViewTypeAheadController.getRecordName(acc.Id, 'Account', 'Name');

        Test.stopTest();
        System.assertEquals('getRecordName', name);
    }

}