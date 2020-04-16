@isTest
private class ListViewActionBLTest {

    @testSetup
    private static void createSampleData()
    {
    }

    static testMethod void listViewControllerTest() {

        List<List_View_Action__c> lvActions = HelperTest.createListViewActions();

        System.assert(lvActions != null);
        System.assert(lvActions.size() > 0);

        List_View_Action__c lvAction = lvActions[0];

        String beforePrimaryKey = lvAction.Primary_Key__c;

        lvAction.Label__c = 'Changed Name';

        update lvAction;

    }


}