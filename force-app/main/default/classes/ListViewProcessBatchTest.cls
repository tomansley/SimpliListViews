@IsTest
private class ListViewProcessBatchTest {

    @testSetup
    private static void createSampleData()
    {
    }

    static testMethod void listViewProcessBatchTest() {

        Test.startTest();
            ListViewProcessBatch job = new ListViewProcessBatch();
            Database.executeBatch(job);
        Test.stopTest();
    }

}