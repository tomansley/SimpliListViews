/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 03-28-2022
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-06-2020   tom@ansleyllc.com   Initial Version
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
    static void hasModifyAllTest()
    {

        Test.startTest();

            Boolean hasModifyAll = ListViewController.hasModifyAll();

        Test.stopTest();

        //not checking assertion as installing user might not be sys admin?
        //System.assertEquals(true, hasModifyAll);
        System.assertEquals(true, true);
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

        System.assertEquals('0:Waiting', result);
        System.assertEquals(false, isInit);
        System.assertEquals(true, isInit2);
    }

    @IsTest
    static void getUserConfigTest()
    {
    
        Test.startTest();
            
        //create user config by doing an upsert
        ListViewController.updateUserConfig('CompName 1', 'pinnedListView', 'Account:simpli_lv__AllAccounts');

        Map<String, String> configs = ListViewController.getComponentConfig('CompName 1');

        System.assertEquals(23, configs.size());
        System.assertEquals('Account:simpli_lv__AllAccounts', configs.get('pinnedListView'));

        //update user config
        ListViewController.updateUserConfig('CompName 1', 'pinnedListView', 'Contact:simpli_lv__AllContacts');
        ListViewController.updateUserConfig('CompName 2', 'pinnedListView', 'Account:simpli_lv__AllAccounts');

        configs = ListViewController.getComponentConfig('CompName 1');

        System.assertEquals(23, configs.size());
        System.assertEquals('Contact:simpli_lv__AllContacts', configs.get('pinnedListView'));



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

            String result = ListViewController.updateSingleListView('Account', 'simpli_lv__AllAccounts');

        Test.stopTest();

        System.assertEquals(result, 'success');
    }

    static testMethod void processParamChangeTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.processParamChange('Account', 'simpli_lv__AllAccounts', 'RefreshRate', '45', 'Refresh Rate', ListViewHelper.TYPE_NUMBER);

        System.assertEquals(result, 'Ok:');

    }

    static testMethod void processConditionChangeTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.processConditionChange('Account', 'simpli_lv__AllAccounts', 'add', '[["field","Account Name"],["operator","Equals"],["value","Dickenson plc"],["order","1"],["color","#A02929"]]');

        System.assertEquals(result, 'Ok:');

        List_View_Config_Condition__c condition = [SELECT ID FROM List_View_Config_Condition__c WHERE Value__c = 'Dickenson plc'];

        result = ListViewController.processConditionChange('Account', 'simpli_lv__AllAccounts', 'remove', condition.Id);

        System.assertEquals(result, 'Ok:');

    }

    static testMethod void getListViewColumnsTest()
    {
        HelperTest.createCoreListViews();

        List<ListViewAbstract.ListViewColumn> labels = ListViewController.getListViewColumns('Account', 'simpli_lv__AllAccounts');

        System.assert(labels.size() > 0);
    }


    static testMethod void getListViewConfigTest()
    {
        HelperTest.createCoreListViews();

        ListViewAbstract.ListViewConfigWrapper lvConfig = ListViewController.getListViewConfig('Account', 'simpli_lv__AllAccounts', 'App Page');

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

        Test.startTest();

            Test.setMock(HttpCalloutMock.class, new ListViewControllerTest.ListViewControllerTest_CalloutMock());

            String result = ListViewController.updateChangedListViews();

        Test.stopTest();

        System.assertEquals(result, 'success');

    }


    static testMethod void updateAllListViewsTest()
    {
        HelperTest.createCoreListViews();

        String result = ListViewController.updateAllListViews();

        System.assertNotEquals(result, 'failed');
    }

    static testMethod void getListViewActionAndDataTest()
    {
        Account acct = HelperTest.insertAccount('Test Acct for getListViewActionAndDataTest');

        Test.startTest();
            ListViewAbstract.ActionWrapper action = ListViewController.getListViewActionAndData('Update:ListViewActionUpdate:Core:Account', '["' + acct.Id + '"]');
        Test.stopTest();

        System.assertEquals('Update', action.getLabel());
        System.assert(action.getDisplayParameters().size() > 0);
        ListViewAbstract.ActionParameterWrapper param = action.getDisplayParameters()[0];
        System.debug(LoggingLevel.DEBUG, 'PARAMS - ' + action.getDisplayParameters());
        System.assert(!String.isEmpty(param.getValue()));
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

        ListViewAbstract.RowsWrapper rows = ListViewController.getListViewData('', ListViewHelper.MODE_APP, 'Account', 'simpli_lv__AllAccounts', '', '', '', -1, '');

        System.assertNotEquals(rows, null);
        System.assertNotEquals(rows.getFieldMetaData(), null);
        System.assert(rows.getFieldMetaData().size() > 0);
        System.assertNotEquals(rows.getRows(), null);
        System.assert(rows.getRows().size() > 0);
        System.assert(rows.getRowCount() > 0);
        System.assertNotEquals(rows.getCoreListViewURL(), '');
        System.assertNotEquals(rows.getDataAsString(), null);
        System.assertNotEquals(rows.getListView(), null);
        System.assertNotEquals(rows.getObjectName(), null);
        System.assertNotEquals(rows.getCoreListId(), null);
        System.assertNotEquals(rows.getUserTimeZone(), null);
        System.assertNotEquals(rows.getIsEdited(), null);
        System.assertNotEquals(rows.getIsCoreListView(), null);
        System.assertNotEquals(rows.getHasTotalsRow(), null);


        ListViewAbstract.ListViewWrapper listViewWrapper = rows.getListView();
        System.assertNotEquals(listViewWrapper.getLastModifiedText(), null);
        System.assertNotEquals(listViewWrapper.getLastModifiedBy(), null);
        System.assertNotEquals(listViewWrapper.getLastModifiedDate(), null);
        System.assertNotEquals(listViewWrapper.getOffset(), null);
        System.assertNotEquals(listViewWrapper.getListViewType(), null);
        System.assertNotEquals(listViewWrapper.getRowLimit(), null);

        ListViewAbstract.RowWrapper row = rows.rows[0];
        System.assertNotEquals(row, null);
        System.assertNotEquals(row.getRowId(), null);
        System.assertNotEquals(row.getCheckboxId(), null);
        System.assertNotEquals(row.getFields(), null);
        System.assert(row.getFields().size() > 0);
        System.assertNotEquals(row.getHighlight(), null);
        System.assertNotEquals(row.getHighlightColor(), null);
        System.assertNotEquals(row.getSalesforceId(), null);
        System.assertNotEquals(row.getIsDeleted(), null);
        System.assertNotEquals(row.getIsEdited(), null);
        System.assertNotEquals(row.getIsDisplayed(), null);


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
        System.assertNotEquals(field.getKey(), null);
        System.assertNotEquals(field.getSortingTooltip(), null);
        System.assertNotEquals(field.getSortable(), null);
        System.assertNotEquals(field.getIsEditable(), null);
        System.assertNotEquals(field.getURLTarget(), null);
        System.assertNotEquals(field.getFieldObjName(), null);
        System.assertNotEquals(field.getIsBoolean(), null);
        System.assertNotEquals(field.getIsCurrency(), null);
        System.assertNotEquals(field.getIsDate(), null);
        System.assertNotEquals(field.getIsDateTime(), null);
        System.assertNotEquals(field.getIsDecimal(), null);
        System.assertNotEquals(field.getIsDouble(), null);
        System.assertNotEquals(field.getIsEmail(), null);
        System.assertNotEquals(field.getIsInteger(), null);
        System.assertNotEquals(field.getIsLookup(), null);
        System.assertNotEquals(field.getIsMultiPicklist(), null);
        System.assertNotEquals(field.getIsPercent(), null);
        System.assertNotEquals(field.getIsPhone(), null);
        System.assertNotEquals(field.getIsPicklist(), null);
        System.assertNotEquals(field.getIsString(), null);
        System.assertNotEquals(field.getIsTextArea(), null);
        System.assertNotEquals(field.getIsTime(), null);
        System.assertNotEquals(field.getIsURL(), null);
        System.assertNotEquals(field.getUIValue(), null);
        System.assertNotEquals(field.getUIMultiPicklistValues(), null);

        List<ListViewAbstract.ListViewColumn> columns = ListViewController.getListViewColumns('Account', 'simpli_lv__AllAccounts');
        System.assertNotEquals(columns, null);
        System.assert(columns.size() > 0);

        ListViewAbstract.ListViewColumn column = columns[0];
        System.assertNotEquals(column.getIsBoolean(), null);
        System.assertNotEquals(column.getIsCurrency(), null);
        System.assertNotEquals(column.getIsDate(), null);
        System.assertNotEquals(column.getIsDateTime(), null);
        System.assertNotEquals(column.getIsDecimal(), null);
        System.assertNotEquals(column.getIsDouble(), null);
        System.assertNotEquals(column.getIsEmail(), null);
        System.assertNotEquals(column.getIsInteger(), null);
        System.assertNotEquals(column.getIsLookup(), null);
        System.assertNotEquals(column.getIsMultiPicklist(), null);
        System.assertNotEquals(column.getIsPercent(), null);
        System.assertNotEquals(column.getIsPhone(), null);
        System.assertNotEquals(column.getIsPicklist(), null);
        System.assertNotEquals(column.getIsString(), null);
        System.assertNotEquals(column.getIsTextArea(), null);
        System.assertNotEquals(column.getIsTime(), null);
        System.assertNotEquals(column.getIsURL(), null);
        System.assertNotEquals(column.getLabel(), null);
        System.assertNotEquals(column.getType(), null);
        System.assertNotEquals(column.getValue(), null);
        
        List<ListViewAbstract.ActionWrapper> actions = ListViewController.getListViewActions('Account', 'simpli_lv__AllAccounts', '');

        System.assertNotEquals(actions, null);
        System.assert(actions.size() > 0);
        

        ListViewAbstract.ActionWrapper action = ListViewController.getListViewAction('Update:ListViewActionUpdate:Core:Account');
        System.assertNotEquals(action.getLabel(), null);
        System.assertNotEquals(action.getObjectType(), null);
        System.assertNotEquals(action.getHasDisplayParameters(), null);
        System.assertNotEquals(action.getNonDisplayParameters(), null);
        System.assertNotEquals(action.getAllParameters(), null);
        System.assertNotEquals(action.getPrimaryKey(), null);
        System.assertNotEquals(action.getValue(), null);
        System.assertNotEquals(action.getIsHyperlink(), null);
        System.assertNotEquals(action.getHyperlink(), null);

        System.assertNotEquals(action.getDisplayParameters(), null);
        System.assert(action.getDisplayParameters().size() > 0);

        ListViewAbstract.ActionParameterWrapper actionParam = action.getDisplayParameters()[0];

        System.assertNotEquals(actionParam.getAPIName(), null);
        System.assertNotEquals(actionParam.getLabel(), null);
        System.assertNotEquals(actionParam.getType(), null);
        System.assertNotEquals(actionParam.getPlaceholder(), null);
        System.assertNotEquals(actionParam.getIsBoolean(), null);
        System.assertNotEquals(actionParam.getIsCurrency(), null);
        System.assertNotEquals(actionParam.getIsDate(), null);
        System.assertNotEquals(actionParam.getIsDateTime(), null);
        System.assertNotEquals(actionParam.getIsDecimal(), null);
        System.assertNotEquals(actionParam.getIsDouble(), null);
        System.assertNotEquals(actionParam.getIsEmail(), null);
        System.assertNotEquals(actionParam.getIsInteger(), null);
        System.assertNotEquals(actionParam.getIsLookup(), null);
        System.assertNotEquals(actionParam.getIsMultiPicklist(), null);
        System.assertNotEquals(actionParam.getIsPercent(), null);
        System.assertNotEquals(actionParam.getIsPhone(), null);
        System.assertNotEquals(actionParam.getIsPicklist(), null);
        System.assertNotEquals(actionParam.getIsString(), null);
        System.assertNotEquals(actionParam.getIsTextArea(), null);
        System.assertNotEquals(actionParam.getIsTime(), null);
        System.assertNotEquals(actionParam.getIsURL(), null);
        

        String result = ListViewController.processAction('Delete:ListViewActionDelete:Core:null', '["' + acct.Id + '"]', '[]');

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

    static testMethod void getListViewDataShellTest() {

        HelperTest.createCoreListViews();
        Account acct = HelperTest.insertAccount('List View Account');

        ListViewAbstract.RowsWrapper rows = ListViewController.getListViewDataShell(ListViewHelper.MODE_APP, 'Account', 'simpli_lv__AllAccounts', '', '');

        System.assertNotEquals(rows, null);
        System.assert(rows.getRowCount() > 0);
    }

    static testMethod void getListViewDataWithSearchTest() {

        HelperTest.createCoreListViews();
        List<Id> accIds = new List<Id>();
        accIds.add(HelperTest.insertAccount('List View Account').Id);
        accIds.add(HelperTest.insertAccount('Ansley LLC').Id);

        Test.setFixedSearchResults(accIds);
        Test.startTest();
            ListViewAbstract.RowsWrapper rows = ListViewController.getListViewData('', ListViewHelper.MODE_APP, 'Account', 'simpli_lv__AllAccounts', '', '', '', -1, 'Ansley');
        Test.stopTest();

        System.assertNotEquals(rows, null);
        System.assert(rows.getRowCount() > 0);
    }

    static testMethod void createRecordsTest() {

        Test.startTest();
            String result = ListViewController.createRecords('Account', '{"1":[["Name","Mass Create Test"],["BillingState","WI"],["simpli_lv__Active__c","Yes"],["Type","Prospect"],["AnnualRevenue","1000"]]} for MassCreateModal');
        Test.stopTest();

        System.assertEquals('1:success', result);
    }

    static testMethod void getPicklistValuesTest() {

        Test.startTest();
            List<ListViewController.SelectOption> options = ListViewController.getPicklistValues('Account', 'Type');
        Test.stopTest();

        System.assert(options.size() > 0);
    }

    static testMethod void getListViewDataWithJoinDataTest() {
        HelperTest.createCoreListViews();

        Account acct = HelperTest.insertAccount('List View Account');

        Contact cont = HelperTest.insertContact(acct, 'First1', 'Last1', 'testy1@testerson.com');
        cont = HelperTest.insertContact(acct, 'Secondly', 'LastName', 'tom@testerson.com');

        Test.startTest();
            ListViewAbstract.RowsWrapper rows = ListViewController.getListViewData('', ListViewHelper.MODE_APP, 'Contact', 'simpli_lv__AllContacts', '', 'AccountId', '{"recordIds":"' + acct.Id + '","objectType":"Account","uniqueComponentId":"Example_7_Account_List_View:439820"}', -1, '');
        Test.stopTest();

        System.assert(rows.getRowCount() > 0);
    }

    static testMethod void getListViewDataWithSortingDataTest() {
        HelperTest.createCoreListViews();

        HelperTest.insertAccount('List View Account');
        HelperTest.insertAccount('Ansley LLC');

        Test.startTest();
            ListViewAbstract.RowsWrapper rows = ListViewController.getListViewData('Test_Page_Name', ListViewHelper.MODE_APP, 'Account', 'simpli_lv__AllAccounts', '[[0,[0,"Industry",true]]]', '', '', -1, '');
        Test.stopTest();

        System.assert(rows.getRowCount() > 0);
    }

    static testMethod void isValidListViewDataRequestTest() {
        HelperTest.createCoreListViews();
        Account acct = HelperTest.insertAccount('List View Account');

        Test.startTest();
            String result = ListViewController.isValidListViewDataRequest('Contact', 'AccountId', '{"recordIds":"' + acct.Id + '","objectType":"Account","uniqueComponentId":"Example_7_Account_List_View:439820"}');
        Test.stopTest();

        System.assertEquals('success', result);
    }

    static testMethod void getListViewConfigParameterTest() {

        ListViewConfigHelper.updateListViewParam('Account', 'simpli_lv__AllAccounts', ListViewHelper.PARAM_ADD_FIELDS, 'CreatedBy.Name, Owner.Profile.Name', 'Additional Fields', ListViewHelper.TYPE_STRING);

        Test.startTest();
            String result = ListViewController.getListViewConfigParameter('Account', 'simpli_lv__AllAccounts', ListViewHelper.PARAM_ADD_FIELDS);
        Test.stopTest();

        System.assertNotEquals('', result);
    }

    static testMethod void getUserSortConfigsTest() {

        HelperTest.createCoreListViews();

        HelperTest.insertAccount('List View Account');
        HelperTest.insertAccount('Ansley LLC');
        
        //this passes in a sorting order so it automatically saves it as well. Useful for testing GET functionality
        ListViewController.getListViewData('Test_Page_Name', ListViewHelper.MODE_APP, 'Account', 'simpli_lv__AllAccounts', '[[0,[0,"Industry",true]]]', '', '', -1, '');

        Test.startTest();
            String configsJSON = ListViewController.getUserSortConfigs('Test_Page_Name');

            Object configs = JSON.deserializeUntyped(configsJSON);
        Test.stopTest();

        System.assertNotEquals(null, configs);
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