/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 07-26-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-26-2021   tom.h.ansley@medtronic.com   Initial Version
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