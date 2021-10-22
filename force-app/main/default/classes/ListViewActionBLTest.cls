/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   09-09-2020   tom@ansleyllc.com   Initial Version
**/
@isTest
private class ListViewActionBLTest {

    @testSetup
    private static void createSampleData()
    {
    }

    static testMethod void listViewControllerTest() {

        List<List_View_Action__c> lvActions = ListViewHelper.insertCoreActions();

        System.assert(lvActions != null);
        System.assert(lvActions.size() > 0);

        List_View_Action__c lvAction = lvActions[0];

        String beforePrimaryKey = lvAction.Primary_Key__c;

        lvAction.Label__c = 'Changed Name';

		HelperDatabase.updateRecord(lvAction, 'simpli_lv__List_View_Action__c');

    }


}