/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 02-02-2022
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
        ListViewHelper.insertCoreConfiguration();
    }

    static testMethod void listViewActionParameterTest() 
    {

        Test.startTest();
            List_View_Action__c updateAction = ListViewActionHelper.getListViewActionByKey('Update:Account');
            System.assert(updateAction.List_View_Action_Parameters__r != null);
            System.assert(updateAction.List_View_Action_Parameters__r.size() == 2);

            List_View_Action_Parameter__c param = updateAction.List_View_Action_Parameters__r[0];
            System.assert(param != null);
            
            //change param field to AccountNumber
            param.Field_API_Name__c   = 'AccountNumber';

            HelperDatabase.updateRecord(param);

        Test.stopTest();

        SObjectAccessDecision dec = 
         Security.stripInaccessible(AccessType.READABLE,
                [SELECT Field_API_Name__c FROM List_View_Action_Parameter__c WHERE Id = :param.Id]);
        List_View_Action_Parameter__c paramUpdate = (List_View_Action_Parameter__c) dec.getRecords()[0];
        System.assert(paramUpdate.Field_API_Name__c == 'AccountNumber');

    }

    static testMethod void listViewActionUpdateTest() {

        Test.startTest();
        
            List_View_Action__c deleteAction = ListViewActionHelper.getListViewActionByKey('Delete:ListViewActionDelete:Core:null');

            String beforePrimaryKey = deleteAction.Primary_Key__c;

            deleteAction.Label__c = 'Changed Name';

            HelperDatabase.updateRecord(deleteAction);

            deleteAction = ListViewActionHelper.getListViewActionByKey('ChangedName:ListViewActionDelete:Core:null');

        Test.stopTest();

        System.assert(beforePrimaryKey != deleteAction.Primary_Key__c);

    }

    static testMethod void listViewActionDeleteProcessTest() {

        Account acct = HelperTest.insertAccount('List View Account');

        Test.startTest();

            String result = ListViewController.processAction('Delete:null', '["' + acct.Id + '"]', '[]');

        Test.stopTest();

        System.assert(result.startsWith(ListViewAction.RESULT_OK));
    
    }

    static testMethod void listViewActionUpdateProcessTest() {

        Account acct = HelperTest.insertAccount('List View Account');

        Test.startTest();

            String result = ListViewController.processAction('Update:Account', '["' + acct.Id + '"]', '[["Industry","Relaxation"],["Name","Grand Hotel"]]');

        Test.stopTest();

        System.assert(result.startsWith(ListViewAction.RESULT_OK));
    
    }

    static testMethod void listViewActionOppCloseProcessTest() {

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

        Account acct = HelperTest.insertAccount('Send Email Test Account');
        Contact cont = HelperTest.insertContact(acct);
        
        Test.startTest();
        
            String result = ListViewController.processAction('SendEmail:Contact', '["' + cont.Id + '"]', '[["Subject","Test Subject"],["Body","<p>This is the <b>email </b>body</p>"]]');

        Test.stopTest();

        System.assert(result.contains(ListViewAction.RESULT_OK + ':'));

    }

}