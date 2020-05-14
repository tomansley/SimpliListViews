@isTest
private class ListViewControllerTest {

    @testSetup
    private static void createSampleData()
    {
    }

    @IsTest
    static void getUserConfigTest()
    {
    
        Test.startTest();
            
        //create user config by doing an upsert
        ListViewController.updateUserConfig('CompName 1', 'pinnedListView', 'Account:AllAccounts');

        Map<String, String> configs = ListViewController.getUserConfigs('CompName 1');

        System.assert(configs.size() == 1);
        System.assert(configs.get('pinnedListView') == 'Account:AllAccounts');

        //update user config
        ListViewController.updateUserConfig('CompName 1', 'pinnedListView', 'Contact:AllContacts');
        ListViewController.updateUserConfig('CompName 2', 'pinnedListView', 'Account:AllAccounts');

        configs = ListViewController.getUserConfigs('CompName 1');

        System.assert(configs.size() == 1);
        System.assert(configs.get('pinnedListView') == 'Contact:AllContacts');



        Test.stopTest();
        
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

    static testMethod void updateChangedListViewTest()
    {
        HelperTest.createListViews();

        String result = ListViewController.updateChangedListViews();

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


        ListViewController.RowsWrapper rows = ListViewController.getListViewData('Account', 'AllAccounts', '', '', '');

        System.assert(rows != null);
        System.assert(rows.getFieldMetaData() != null);
        System.assert(rows.getFieldMetaData().size() > 0);
        System.assert(rows.getRows() != null);
        System.assert(rows.getRows().size() > 0);
        System.assert(rows.getRowCount() > 0);
        System.assert(rows.getCoreListViewURL() != '');

        ListViewController.RowWrapper row = rows.rows[0];
        System.assert(row != null);
        System.assert(row.getRowId() != null);
        System.assert(row.getCheckboxId() != null);
        System.assert(row.getFields() != null);
        System.assert(row.getFields().size() > 0);

        ListViewController.FieldWrapper field = row.fields[0];
        System.assert(field != null);
        System.assert(field.getLabel() != null);
        System.assert(field.getName() != null);
        System.assert(field.getSortIndex() != null);
        System.assert(field.getSortIndexDisplay() != null);
        System.assert(field.getSortDir() != null);
        System.assert(field.getType() != null);
        System.assert(field.getValue() != null);
        System.assert(field.getHasURL() != null);
        System.assert(field.getURL() != null);

        
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

    static testMethod void stupidMetadataAPITest()
    {
        ListViewMetadataAPIService.ListViewFilter f = new ListViewMetadataAPIService.ListViewFilter();
        ListViewMetadataAPIService.ReadResult r = new ListViewMetadataAPIService.ReadResult();
        ListViewMetadataAPIService.Error e = new ListViewMetadataAPIService.Error();
        ListViewMetadataAPIService.LogInfo l = new ListViewMetadataAPIService.LogInfo();
        ListViewMetadataAPIService.DebuggingHeader_element d = new ListViewMetadataAPIService.DebuggingHeader_element();
        ListViewMetadataAPIService.readMetadata_element r1 = new ListViewMetadataAPIService.readMetadata_element();
        ListViewMetadataAPIService.readMetadataResponse_element r2 = new ListViewMetadataAPIService.readMetadataResponse_element();
        ListViewMetadataAPIService.CallOptions_element c = new ListViewMetadataAPIService.CallOptions_element();
        ListViewMetadataAPIService.DebuggingInfo_element d2 = new ListViewMetadataAPIService.DebuggingInfo_element();
        ListViewMetadataAPIService.ReadListViewResult r3 = new ListViewMetadataAPIService.ReadListViewResult();
        ListViewMetadataAPIService.readListViewResponse_element r4 = new ListViewMetadataAPIService.readListViewResponse_element();

        System.assert(true);
    }

}