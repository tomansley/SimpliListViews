/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-09-2020   tom@ansleyllc.com   Initial Version
**/
@isTest
private class ListViewActionTest {

    @testSetup
    private static void createSampleData()
    {
    }

    static testMethod void listViewActionParameterTest() 
    {

        List<List_View_Action__c> lvActions = ListViewHelper.insertCoreActions();

        Test.startTest();
            List_View_Action__c updateAction = ListViewActionHelper.getListViewActionByKey('Update:Account');
            System.assert(updateAction.List_View_Action_Parameters__r != null);
            System.assert(updateAction.List_View_Action_Parameters__r.size() == 2);

            List_View_Action_Parameter__c param = updateAction.List_View_Action_Parameters__r[0];
            System.assert(param != null);
            
            //change param field to AccountNumber
            param.Field_API_Name__c   = 'AccountNumber';

            HelperDatabase.updateRecord(param, 'simpli_lv__List_View_Action_Parameter__c');

        Test.stopTest();

        HelperSchema.checkListViewActionsAccessible();
        List_View_Action_Parameter__c paramUpdate = [SELECT Field_API_Name__c FROM List_View_Action_Parameter__c WHERE Id = :param.Id];
        System.assert(paramUpdate.Field_API_Name__c == 'AccountNumber');

    }

    static testMethod void listViewActionCreateTest() 
    {

        Test.startTest();
            List<List_View_Action__c> lvActions = ListViewHelper.insertCoreActions();
        Test.stopTest();

        System.assert(lvActions != null);
        System.assert(lvActions.size() > 0);

    }

    static testMethod void listViewActionUpdateTest() {

        Test.startTest();
        
            ListViewHelper.insertCoreActions();

            List_View_Action__c deleteAction = ListViewActionHelper.getListViewActionByKey('Delete:null');

            String beforePrimaryKey = deleteAction.Primary_Key__c;

            deleteAction.Label__c = 'Changed Name';

            HelperDatabase.updateRecord(deleteAction, 'simpli_lv__List_View_Action__c');

            deleteAction = ListViewActionHelper.getListViewActionByKey('ChangedName:null');

        Test.stopTest();

        System.assert(beforePrimaryKey != deleteAction.Primary_Key__c);

    }

    static testMethod void listViewActionDeleteProcessTest() {

        ListViewHelper.insertCoreActions();

        Account acct = HelperTest.insertAccount('List View Account');

        Test.startTest();

            String result = ListViewController.processAction('Delete:null', '["' + acct.Id + '"]', '[]');

        Test.stopTest();

        System.assert(result.startsWith(ListViewAction.RESULT_OK));
    
    }

    static testMethod void listViewActionUpdateProcessTest() {

        ListViewHelper.insertCoreActions();

        Account acct = HelperTest.insertAccount('List View Account');

        Test.startTest();

            String result = ListViewController.processAction('Update:Account', '["' + acct.Id + '"]', '[["Industry","Relaxation"],["Name","Grand Hotel"]]');

        Test.stopTest();

        System.assert(result.startsWith(ListViewAction.RESULT_OK));
    
    }

    static testMethod void listViewActionOppCloseProcessTest() {

        ListViewHelper.insertCoreActions();

        Account acct = HelperTest.insertAccount('List View Account');
        Opportunity opp = HelperTest.insertOpportunity(acct, 'Opportunity 1');

        Test.startTest();

            String result = ListViewController.processAction('SetCloseLost:Opportunity', '["' + opp.Id + '"]', '[["CloseDate","2020-05-04"]]');

        Test.stopTest();

        System.assert(result.startsWith(ListViewAction.RESULT_OK));
    
    }

    static testMethod void listViewActionNullTest() {

        Test.startTest();

            ListViewActionNull action = new ListViewActionNull();
            String result = action.process(null, null);
            System.assertEquals(result, ListViewAction.RESULT_OK + ':');

        Test.stopTest();

    }

    static testMethod void listViewActionEmailTest() {

        ListViewHelper.insertCoreActions();
        Account acct = HelperTest.insertAccount('Send Email Test Account');
        Contact cont = HelperTest.insertContact(acct);
        
        Test.startTest();
        
            String result = ListViewController.processAction('SendEmail:Contact', '["' + cont.Id + '"]', '[["Subject","Test Subject"],["Body","<p>This is the <b>email </b>body</p>"]]');

        Test.stopTest();

        System.assert(result.contains(ListViewAction.RESULT_OK + ':'));

    }

}