/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 12-08-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   06-30-2021   tom@ansleyllc.com   Initial Version
**/
@isTest
public with sharing class ListViewCleanBatchTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

    @isTest
    static void ListViewCleanBatchCustomTest() {
        
        System.assert([SELECT Id FROM List_View__c].size() == 5);

        Test.startTest();
            ListViewCleanBatch job = new ListViewCleanBatch();
            job.execute(null);
            job.start(null);
            job.finish(null);

        Test.stopTest();

        System.assertEquals(5, [SELECT Id FROM List_View__c].size());
    }

    @isTest
    static void ListViewCleanBatchCoreTest() {
        
        HelperTest.createCoreListViews();

        System.assert([SELECT Id FROM List_View__c].size() == 6);

        Test.startTest();
            ListViewCleanBatch job = new ListViewCleanBatch();
            job.execute(null);
            job.start(null);
            job.finish(null);

        Test.stopTest();

        System.assertEquals(6, [SELECT Id FROM List_View__c].size());
    }

    @isTest
    static void ListViewCleanBatchDirtyTest() {
        
        HelperTest.createCoreListViews();

        HelperTest.createDeletedCoreListViews();

        System.assert([SELECT Id FROM List_View__c].size() == 7);

        Test.startTest();
            ListViewCleanBatch job = new ListViewCleanBatch();
            job.execute(null);
            job.start(null);
            job.finish(null);

        Test.stopTest();

        System.assertEquals(6, [SELECT Id FROM List_View__c].size());
    }
}