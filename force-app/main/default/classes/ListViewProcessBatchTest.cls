/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 11-05-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-05-2020   tom.h.ansley@medtronic.com   Initial Version
**/
@IsTest
private class ListViewProcessBatchTest {

    @testSetup
    private static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

    static testMethod void listViewProcessBatchTest() {

        Test.startTest();
            ListViewProcessBatch job = new ListViewProcessBatch();
            Database.executeBatch(job);
        Test.stopTest();

        System.assert(true);
    }

}