@isTest
private class ListViewActionTest {

    @testSetup
    private static void createSampleData()
    {
    }

    static testMethod void listViewActionCreateTest() 
    {

        Test.startTest();
            List<List_View_Action__c> lvActions = HelperTest.createListViewActions();
        Test.stopTest();

        System.assert(lvActions != null);
        System.assert(lvActions.size() > 0);

    }

    static testMethod void listViewActionUpdateTest() {

        Test.startTest();
        
            HelperTest.createListViewActions();

            List_View_Action__c deleteAction = ListViewActionHelper.getListViewActionByKey('Delete:null');

            String beforePrimaryKey = deleteAction.Primary_Key__c;

            deleteAction.Label__c = 'Changed Name';

            update deleteAction;

            deleteAction = ListViewActionHelper.getListViewActionByKey('ChangedName:null');

        Test.stopTest();

        System.assert(beforePrimaryKey != deleteAction.Primary_Key__c);

    }

    static testMethod void listViewActionDeleteProcessTest() {

        HelperTest.createListViewActions();

        Account acct = HelperTest.insertAccount('List View Account');

        Test.startTest();

            String result = ListViewController.processAction('Delete:null', '["' + acct.Id + '"]', '[]');

        Test.stopTest();

        System.assert(result == ListViewAction.RESULT_OK);
    
    }

    static testMethod void listViewActionUpdateProcessTest() {

        HelperTest.createListViewActions();

        Account acct = HelperTest.insertAccount('List View Account');

        Test.startTest();

            String result = ListViewController.processAction('Update:Account', '["' + acct.Id + '"]', '[["Industry","Relaxation"],["Name","Grand Hotel"]]');

        Test.stopTest();

        System.assert(result == ListViewAction.RESULT_OK);
    
    }


}