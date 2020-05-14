@isTest
private class ListViewActionTest {

    @testSetup
    private static void createSampleData()
    {
    }

    static testMethod void listViewActionParameterTest() 
    {

        List<List_View_Action__c> lvActions = HelperTest.createListViewActions();

        Test.startTest();
            List_View_Action__c updateAction = ListViewActionHelper.getListViewActionByKey('Update:Account');
            System.assert(updateAction.List_View_Action_Parameters__r != null);
            System.assert(updateAction.List_View_Action_Parameters__r.size() == 2);

            List_View_Action_Parameter__c param = updateAction.List_View_Action_Parameters__r[0];
            System.assert(param != null);
            
            //change param field to AccountNumber
            param.Field_API_Name__c   = 'AccountNumber';

            update param;

        Test.stopTest();

        List_View_Action_Parameter__c paramUpdate = [SELECT Field_API_Name__c FROM List_View_Action_Parameter__c WHERE Id = :param.Id];
        System.assert(paramUpdate.Field_API_Name__c == 'AccountNumber');

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

    static testMethod void listViewActionOppCloseProcessTest() {

        HelperTest.createListViewActions();

        Account acct = HelperTest.insertAccount('List View Account');
        Opportunity opp = HelperTest.insertOpportunity(acct, 'Opportunity 1');

        Test.startTest();

            String result = ListViewController.processAction('SetCloseLost:Opportunity', '["' + opp.Id + '"]', '[["CloseDate","2020-05-04"]]');

        Test.stopTest();

        System.assert(result == ListViewAction.RESULT_OK);
    
    }

}