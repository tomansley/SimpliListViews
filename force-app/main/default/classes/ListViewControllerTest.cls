@isTest
private class ListViewControllerTest {

    @testSetup
    private static void createSampleData()
    {
    }

    static testMethod void updateObjectListViewsTest()
    {
        HelperTest.createListViews();

        String result = ListViewController.updateObjectListViews('Account');

        System.assert(result == 'success');
    }

    static testMethod void updateSingleListViewTest()
    {
        HelperTest.createListViews();

        String result = ListViewController.updateSingleListView('Account', 'AllAccounts');

        System.assert(result == 'success');
    }

    static testMethod void updateAllListViewsTest()
    {
        HelperTest.createListViews();

        String result = ListViewController.updateAllListViews();

        System.assert(result == 'success');
    }


    static testMethod void listViewControllerTest() {

        HelperTest.createListViews();
        List<List_View_Action__c> lvActions = HelperTest.createListViewActions();
        Account acct = HelperTest.insertAccount('List View Account');

        List<ListViewController.SelectOption> objs = ListViewController.getListViewObjects('',''); 

        System.assert(objs != null);
        System.assert(objs.size() > 0);
        

        List<ListViewController.SelectOption> listviews = ListViewController.getObjectListViews('Account');

        System.assert(listviews != null);
        System.assert(listviews.size() > 0);


        ListViewController.RowsWrapper rows = ListViewController.getListViewData('Account', 'AllAccounts');

        System.assert(rows != null);
        System.assert(rows.getFieldMetaData() != null);
        System.assert(rows.getFieldMetaData().size() > 0);
        System.assert(rows.getRows() != null);
        System.assert(rows.getRows().size() > 0);

        
        List<ListViewController.SelectOption> actions = ListViewController.getListViewsActions('Account');

        System.assert(actions != null);
        System.assert(actions.size() > 0);
        

        ListViewController.ActionWrapper action = ListViewController.getListViewAction('Update:Account');
        System.assert(action.getLabel() != null);
        System.assert(action.getObjectType() != null);
        System.assert(action.getParameters() != null);
        System.assert(action.getParameters().size() > 0);
        System.assert(action.getParameters()[0].getAPIName() != null);
        System.assert(action.getParameters()[0].getLabel() != null);
        System.assert(action.getParameters()[0].getType() != null);
        System.assert(action.getParameters()[0].getValue() != null);
        System.assert(action.getParameters()[0].getPlaceholder() != null);
        

        String result = ListViewController.processAction('Delete:null', '["' + acct.Id + '"]', '[]');

        System.assert(result == ListViewAction.RESULT_OK);

    }


}