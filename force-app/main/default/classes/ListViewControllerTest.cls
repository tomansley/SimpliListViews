/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 08-06-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-06-2020   tom.h.ansley@medtronic.com   Initial Version
**/
@isTest
global class ListViewControllerTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();

        HelperTest.insertAccount('Test Account 1');
    }

    @IsTest
    static void getListViewInitProgressTest()
    {

        Test.startTest();

            String result = ListViewController.getListViewInitProgress(null);

            Boolean isInit = ListViewController.getIsInitialized();

            ListViewConfigHelper.setOrgWideConfigParam('IsInitialized', 'true');

            Boolean isInit2 = ListViewController.getIsInitialized();

        Test.stopTest();

        System.assertEquals('0:', result);
        System.assertEquals(false, isInit);
        System.assertEquals(true, isInit2);
    }

    @IsTest
    static void getUserConfigTest()
    {
    
        Test.startTest();
            
        //create user config by doing an upsert
        ListViewController.updateUserConfig('CompName 1', 'pinnedListView', 'Account:AllAccounts');

        Map<String, String> configs = ListViewController.getComponentConfig('CompName 1');

        System.assertEquals(16, configs.size());
        System.assertEquals('Account:AllAccounts', configs.get('pinnedListView'));

        //update user config
        ListViewController.updateUserConfig('CompName 1', 'pinnedListView', 'Contact:AllContacts');
        ListViewController.updateUserConfig('CompName 2', 'pinnedListView', 'Account:AllAccounts');

        configs = ListViewController.getComponentConfig('CompName 1');

        System.assertEquals(16, configs.size());
        System.assertEquals('Contact:AllContacts', configs.get('pinnedListView'));



        Test.stopTest();
        
    }

    static testMethod void updateObjectListViewsTest()
    {
        HelperTest.createCoreListViews();

        Test.startTest();

            Test.setMock(HttpCalloutMock.class, new ListViewControllerTest.ListViewControllerTest_CalloutMock());

            String result = ListViewController.updateObjectListViews('Account');

        Test.stopTest();

        System.assertEquals(result, 'success');
    }

    static testMethod void updateSingleListViewTest()
    {
        HelperTest.createCoreListViews();

        Test.startTest();

            Test.setMock(HttpCalloutMock.class, new ListViewControllerTest.ListViewControllerTest_CalloutMock());

            String result = ListViewController.updateSingleListView('Account', 'AllAccounts');

        Test.stopTest();

        System.assertEquals(result, 'success');
    }

    static testMethod void processParamChangeTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.processParamChange('Account', 'AllAccounts', 'RefreshRate', '45', 'Refresh Rate', 'Number');

        System.assertEquals(result, 'Ok:');

    }

    static testMethod void processConditionChangeTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.processConditionChange('Account', 'AllAccounts', 'add', '[["field","Account Name"],["operator","Equals"],["value","Dickenson plc"],["order","1"],["color","#A02929"]]');

        System.assertEquals(result, 'Ok:');

        HelperSchema.checkListViewConfigsAccessible();
        List_View_Config_Condition__c condition = [SELECT ID FROM List_View_Config_Condition__c WHERE Value__c = 'Dickenson plc'];

        result = ListViewController.processConditionChange('Account', 'AllAccounts', 'remove', condition.Id);

        System.assertEquals(result, 'Ok:');

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

        System.assertNotEquals(lvConfig.listViewConfig, null);

        System.assertNotEquals(lvConfig.getName(), null);
        System.assertNotEquals(lvConfig.getObject(), null);
        System.assertNotEquals(lvConfig.getLastModifiedText(), null);
        System.assertNotEquals(lvConfig.getLastModifiedBy(), null);
        System.assertNotEquals(lvConfig.getLastModifiedDate(), null);
        List<ListViewAbstract.ListViewParam> params = lvConfig.getParameters();
        System.assert(params.size() > 0);
        System.assertNotEquals(params[0].getLabel(), null);
        System.assertNotEquals(params[0].getName(), null);
        System.assertNotEquals(params[0].getType(), null);
        System.assertNotEquals(params[0].getPlaceHolder(), null);
        System.assertNotEquals(params[0].getDescription(), null);
        System.assertNotEquals(params[0].getUpdateImmediate(), null);
        System.assertNotEquals(params[0].getIsBoolean(), null);
        List<ListViewAbstract.ListViewCondition> conditions = lvConfig.getConditions();
        System.assert(conditions.size() > 0);
        System.assertNotEquals(conditions[0].getCondition(), null);
        System.assertNotEquals(conditions[0].getFieldName(), null);
        System.assertNotEquals(conditions[0].getOperator(), null);
        System.assertNotEquals(conditions[0].getValue(), null);
        System.assertNotEquals(conditions[0].getOrder(), null);
        System.assertNotEquals(conditions[0].getColor(), null);
        System.assertNotEquals(conditions[0].getId(), null);

    }

    static testMethod void updateChangedListViewTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.updateChangedListViews();

        System.assertEquals(result, 'success');
    }


    static testMethod void updateAllListViewsTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.updateAllListViews();

        System.assertNotEquals(result, 'failed');
    }


    static testMethod void listViewControllerTest() {

        HelperTest.createCoreListViews();
        Account acct = HelperTest.insertAccount('List View Account');

        List<ListViewController.SelectOption> objs = ListViewController.getListViewObjects('',''); 

        System.assertNotEquals(objs, null);
        System.assert(objs.size() > 0);
        

        List<ListViewController.SelectOption> listviews = ListViewController.getObjectListViews('Account');

        System.assertNotEquals(listviews, null);
        System.assert(listviews.size() > 0);

        ListViewAbstract.RowsWrapper rows = ListViewController.getListViewData('', 'Account', 'AllAccounts', '', '', '', -1);

        System.assertNotEquals(rows, null);
        System.assertNotEquals(rows.getFieldMetaData(), null);
        System.assert(rows.getFieldMetaData().size() > 0);
        System.assertNotEquals(rows.getRows(), null);
        System.assert(rows.getRows().size() > 0);
        System.assert(rows.getRowCount() > 0);
        System.assertNotEquals(rows.getCoreListViewURL(), '');
        System.assertNotEquals(rows.getDataAsString(), null);
        System.assertNotEquals(rows.getListView(), null);

        ListViewAbstract.ListViewWrapper listViewWrapper = rows.getListView();
        System.assertNotEquals(listViewWrapper.getLastModifiedText(), null);
        System.assertNotEquals(listViewWrapper.getLastModifiedBy(), null);
        System.assertNotEquals(listViewWrapper.getLastModifiedDate(), null);


        ListViewAbstract.RowWrapper row = rows.rows[0];
        System.assertNotEquals(row, null);
        System.assertNotEquals(row.getRowId(), null);
        System.assertNotEquals(row.getCheckboxId(), null);
        System.assertNotEquals(row.getFields(), null);
        System.assert(row.getFields().size() > 0);
        System.assertNotEquals(row.getHighlight(), null);
        System.assertNotEquals(row.getHighlightColor(), null);

        ListViewAbstract.FieldWrapper field = row.getFields()[0];
        System.assertNotEquals(field, null);
        System.assertNotEquals(field.getLabel(), null);
        System.assertNotEquals(field.getName(), null);
        System.assertNotEquals(field.getSortIndex(), null);
        System.assertNotEquals(field.getSortIndexDisplay(), null);
        System.assertNotEquals(field.getSortDir(), null);
        System.assertNotEquals(field.getType(), null);
        System.assertNotEquals(field.getValue(), null);
        System.assertNotEquals(field.getHasURL(), null);
        System.assertNotEquals(field.getURL(), null);

        
        List<ListViewController.SelectOption> actions = ListViewController.getListViewsActions('Account', 'AllAccounts');

        System.assertNotEquals(actions, null);
        System.assert(actions.size() > 0);
        

        ListViewAbstract.ActionWrapper action = ListViewController.getListViewAction('Update:Account');
        System.assertNotEquals(action.getLabel(), null);
        System.assertNotEquals(action.getObjectType(), null);
        System.assertNotEquals(action.getParameters(), null);
        System.assert(action.getParameters().size() > 0);
        System.assertNotEquals(action.getParameters()[0].getAPIName(), null);
        System.assertNotEquals(action.getParameters()[0].getLabel(), null);
        System.assertNotEquals(action.getParameters()[0].getType(), null);
        //System.assertNotEquals(action.getParameters()[0].getValue(), null);
        System.assertNotEquals(action.getParameters()[0].getPlaceholder(), null);
        

        String result = ListViewController.processAction('Delete:null', '["' + acct.Id + '"]', '[]');

        System.assert(result.startsWith(ListViewAction.RESULT_OK));

        String validResult =  ListViewController.isValidListViewDataRequest('Account', 'OwnerId', '');

    }

    @IsTest
    static void updateRecordTest()
    {

        Account acct = HelperTest.insertAccount('Update Record Test Account');
        
        Test.startTest();

            String result = ListViewController.updateRecord(acct.Id + ':4', '[["Site","Site Test"],["BillingState","AZ"],["Type","Customer - Channel"],["AnnualRevenue","23000000"]]');

        Test.stopTest();

        System.assertEquals('', result);
    }

    @IsTest
    static void updateRecordsTest()
    {

        Account acct = HelperTest.insertAccount('Update Record Test Account');
        Account acct2 = HelperTest.insertAccount('Test Acct 2');
        Account acct3 = HelperTest.insertAccount('Accounts 3');
        
        Test.startTest();

            String result = ListViewController.updateRecords('{"' + acct.Id + ':4":[["BillingState","CA"],["Type","Prospect"]],"' + acct2.Id + ':9":[["BillingState","IN"],["Type","Customer - Direct"]],"' + acct3.Id + ':11":[["BillingState","AZ"],["Type","Channel Partner / Reseller"]]}');

        Test.stopTest();

        System.assertEquals('', result);
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

    global class ListViewControllerTest_CalloutMock implements HttpCalloutMock  {
   
        //method to send mock respose
        global HTTPResponse respond(HTTPRequest request) {
    
            HTTPResponse wsResponse = new HTTPResponse();

            String body = '';
            System.debug(LoggingLEvel.DEBUG, 'END POINT - ' + request.getEndPoint());
            if (request.getEndpoint().contains('Account/listviews/'))
                body = '{"columns":[{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Name","hidden":false,"label":"Account Name","selectListItem":"Name","sortDirection":"ascending","sortIndex":0,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Site","hidden":false,"label":"Account Site","selectListItem":"Site","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"New to Old","descendingLabel":"Old to New","fieldNameOrPath":"simpli_lv__Test_Date__c","hidden":false,"label":"Test Date","selectListItem":"simpli_lv__Test_Date__c","sortDirection":null,"sortIndex":null,"sortable":true,"type":"date"},{"ascendingLabel":"New to Old","descendingLabel":"Old to New","fieldNameOrPath":"simpli_lv__Test_Date_Time__c","hidden":false,"label":"Test Date Time","selectListItem":"simpli_lv__Test_Date_Time__c","sortDirection":null,"sortIndex":null,"sortable":true,"type":"datetime"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"BillingState","hidden":false,"label":"Billing State/Province","selectListItem":"BillingState","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"Low to High","descendingLabel":"High to Low","fieldNameOrPath":"Type","hidden":false,"label":"Type","selectListItem":"toLabel(Type)","sortDirection":null,"sortIndex":null,"sortable":true,"type":"picklist"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Owner.Alias","hidden":false,"label":"Account Owner Alias","selectListItem":"Owner.Alias","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Id","hidden":true,"label":"Account ID","selectListItem":"Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"CreatedDate","hidden":true,"label":"Created Date","selectListItem":"CreatedDate","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"LastModifiedDate","hidden":true,"label":"Last Modified Date","selectListItem":"LastModifiedDate","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"SystemModstamp","hidden":true,"label":"System Modstamp","selectListItem":"SystemModstamp","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Owner.Id","hidden":true,"label":"User ID","selectListItem":"Owner.Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"OwnerId","hidden":true,"label":"Owner ID","selectListItem":"OwnerId","sortDirection":null,"sortIndex":null,"sortable":false,"type":"reference"}],"id":"00B3h000003ZfMK","orderBy":[{"fieldNameOrPath":"Name","nullsPosition":"first","sortDirection":"ascending"},{"fieldNameOrPath":"Id","nullsPosition":"first","sortDirection":"ascending"}],"query":"SELECT Name, Site, simpli_lv__Test_Date__c, simpli_lv__Test_Date_Time__c, BillingState, toLabel(Type), Owner.Alias, Id, CreatedDate, LastModifiedDate, SystemModstamp, Owner.Id, OwnerId FROM Account ORDER BY Name ASC NULLS FIRST, Id ASC NULLS FIRST","scope":"everything","sobjectType":"Account","whereCondition":{"conditions":[],"conjunction":"and"}}';

            wsResponse.setHeader('Content-Type', 'application/json');
            wsResponse.setBody(body);
            wsResponse.setStatusCode(200);    
            return wsResponse;
        }
    
    }

}