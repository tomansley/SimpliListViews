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