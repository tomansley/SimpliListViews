/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 10-13-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   06-30-2021   tom.h.ansley@medtronic.com   Initial Version
**/
@isTest
public with sharing class ListViewPostProcessBatchTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

    @isTest
    static void ListViewPostProcessBatchTest1() {
        
        System.assert([SELECT Id FROM List_View__c].size() > 0);

        Test.startTest();

            ListViewPostProcessBatch job = new ListViewPostProcessBatch();
            job.execute(null);
            job.start(null);
            job.execute(null, [SELECT Id FROM List_View__c]);
            job.finish(null);

        Test.stopTest();

        System.assertEquals(0, [SELECT Id FROM List_View__c].size());
    }

}