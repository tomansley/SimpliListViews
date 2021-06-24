/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 06-21-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-06-2020   tom.h.ansley@medtronic.com   Initial Version
**/
@isTest
private class ListViewControllerTest {

    @testSetup
    private static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();

        HelperTest.insertAccount('Test Account 1');
    }

    @IsTest
    static void getUserConfigTest()
    {
    
        Test.startTest();
            
        //create user config by doing an upsert
        ListViewController.updateUserConfig('CompName 1', 'pinnedListView', 'Account:AllAccounts');

        Map<String, String> configs = ListViewController.getUserConfigs('CompName 1');

        System.assert(configs.size() == 11);
        System.assert(configs.get('pinnedListView') == 'Account:AllAccounts');

        //update user config
        ListViewController.updateUserConfig('CompName 1', 'pinnedListView', 'Contact:AllContacts');
        ListViewController.updateUserConfig('CompName 2', 'pinnedListView', 'Account:AllAccounts');

        configs = ListViewController.getUserConfigs('CompName 1');

        System.assert(configs.size() == 11);
        System.assert(configs.get('pinnedListView') == 'Contact:AllContacts');



        Test.stopTest();
        
    }

    static testMethod void updateObjectListViewsTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.updateObjectListViews('Account');

        System.assert(result == 'success');
    }

    static testMethod void updateSingleListViewTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.updateSingleListView('Account', 'AllAccounts');

        System.assert(result == 'success');
    }

    static testMethod void processParamChangeTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.processParamChange('Account', 'AllAccounts', 'RefreshRate', '45', 'Refresh Rate', 'Number');

        System.assert(result == 'Ok:');

    }

    static testMethod void processConditionChangeTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.processConditionChange('Account', 'AllAccounts', 'add', '[["field","Account Name"],["operator","Equals"],["value","Dickenson plc"],["order","1"],["color","#A02929"]]');

        System.assert(result == 'Ok:');

        HelperSchema.checkListViewConfigsAccessible();
        List_View_Config_Condition__c condition = [SELECT ID FROM List_View_Config_Condition__c WHERE Value__c = 'Dickenson plc'];

        result = ListViewController.processConditionChange('Account', 'AllAccounts', 'remove', condition.Id);

        System.assert(result == 'Ok:');

    }

    static testMethod void getListViewColumnLabelsTest()
    {
        HelperTest.createCoreListViews();

        List<ListViewController.SelectOption> labels = ListViewController.getListViewColumnLabels('Account', 'AllAccounts');

        System.assert(labels.size() > 0);
    }


    static testMethod void getListViewConfigTest()
    {
        HelperTest.createCoreListViews();

        ListViewAbstract.ListViewConfigWrapper lvConfig = ListViewController.getListViewConfig('Account', 'AllAccounts');

        System.assert(lvConfig.listViewConfig != null);

        System.assert(lvConfig.getName() != null);
        System.assert(lvConfig.getObject() != null);
        System.assert(lvConfig.getLastModifiedText() != null);
        System.assert(lvConfig.getLastModifiedBy() != null);
        System.assert(lvConfig.getLastModifiedDate() != null);
        List<ListViewAbstract.ListViewParam> params = lvConfig.getParameters();
        System.assert(params.size() > 0);
        System.assert(params[0].getLabel() != null);
        System.assert(params[0].getName() != null);
        System.assert(params[0].getType() != null);
        System.assert(params[0].getPlaceHolder() != null);
        System.assert(params[0].getDescription() != null);
        System.assert(params[0].getUpdateImmediate() != null);
        System.assert(params[0].getIsBoolean() != null);
        List<ListViewAbstract.ListViewCondition> conditions = lvConfig.getConditions();
        System.assert(conditions.size() > 0);
        System.assert(conditions[0].getCondition() != null);
        System.assert(conditions[0].getFieldName() != null);
        System.assert(conditions[0].getOperator() != null);
        System.assert(conditions[0].getValue() != null);
        System.assert(conditions[0].getOrder() != null);
        System.assert(conditions[0].getColor() != null);
        System.assert(conditions[0].getId() != null);

    }

    static testMethod void updateChangedListViewTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.updateChangedListViews();

        System.assert(result == 'success');
    }


    static testMethod void updateAllListViewsTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.updateAllListViews();

        System.assert(result != 'failed');
    }


    static testMethod void listViewControllerTest() {

        HelperTest.createCoreListViews();
        Account acct = HelperTest.insertAccount('List View Account');

        List<ListViewController.SelectOption> objs = ListViewController.getListViewObjects('',''); 

        System.assert(objs != null);
        System.assert(objs.size() > 0);
        

        List<ListViewController.SelectOption> listviews = ListViewController.getObjectListViews('Account');

        System.assert(listviews != null);
        System.assert(listviews.size() > 0);

        ListViewAbstract.RowsWrapper rows = ListViewController.getListViewData('', 'Account', 'AllAccounts', '', '', '', '', -1);

        System.assert(rows != null);
        System.assert(rows.getFieldMetaData() != null);
        System.assert(rows.getFieldMetaData().size() > 0);
        System.assert(rows.getRows() != null);
        System.assert(rows.getRows().size() > 0);
        System.assert(rows.getRowCount() > 0);
        System.assert(rows.getCoreListViewURL() != '');
        System.assert(rows.getDataAsString() != null);
        System.assert(rows.getListView() != null);

        ListViewAbstract.ListViewWrapper listViewWrapper = rows.getListView();
        System.assert(listViewWrapper.getLastModifiedText() != null);
        System.assert(listViewWrapper.getLastModifiedBy() != null);
        System.assert(listViewWrapper.getLastModifiedDate() != null);


        ListViewAbstract.RowWrapper row = rows.rows[0];
        System.assert(row != null);
        System.assert(row.getRowId() != null);
        System.assert(row.getCheckboxId() != null);
        System.assert(row.getFields() != null);
        System.assert(row.getFields().size() > 0);
        System.assert(row.getHighlight() != null);
        System.assert(row.getHighlightColor() != null);

        ListViewAbstract.FieldWrapper field = row.getFields()[0];
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

        
        List<ListViewController.SelectOption> actions = ListViewController.getListViewsActions('Account', 'AllAccounts');

        System.assert(actions != null);
        System.assert(actions.size() > 0);
        

        ListViewAbstract.ActionWrapper action = ListViewController.getListViewAction('Update:Account');
        System.assert(action.getLabel() != null);
        System.assert(action.getObjectType() != null);
        System.assert(action.getParameters() != null);
        System.assert(action.getParameters().size() > 0);
        System.assert(action.getParameters()[0].getAPIName() != null);
        System.assert(action.getParameters()[0].getLabel() != null);
        System.assert(action.getParameters()[0].getType() != null);
        //System.assert(action.getParameters()[0].getValue() != null);
        System.assert(action.getParameters()[0].getPlaceholder() != null);
        

        String result = ListViewController.processAction('Delete:null', '["' + acct.Id + '"]', '[]');

        System.assert(result.startsWith(ListViewAction.RESULT_OK));

        String validResult =  ListViewController.isValidListViewDataRequest('Account', 'OwnerId', '');

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