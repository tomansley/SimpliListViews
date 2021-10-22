/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-26-2021   tom@ansleyllc.com   Initial Version
**/
@isTest
global class ListViewLookupControllerTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();

        HelperTest.insertAccount('Test Account 1');
    }

    @IsTest
    static void getListViewInitProgressTest()
    {

        Test.startTest();

        List<sObject> accts = ListViewLookupController.search('Test', 'Account');

        Test.stopTest();

        System.assertEquals(1, accts.size());
    }

}