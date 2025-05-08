/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 05-08-2025
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-18-2021   tom@ansleyllc.com   Initial Version
**/
@isTest
global class ListViewAdminControllerTest {

    @testSetup
    static void createSampleData()
    {
        HelperTest.insertAccount('Test Account 1');
    }

    @IsTest
    static void createActionHyperlinkTest()
    {
        ListViewHelper.insertCoreConfiguration();

        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize = actions.size();

        String jsonStr = '[["actionRecordType","Core"],["actionType","Hyperlink"],["actionSubType",""],["actionLabel","Hyperlink Test - Active - Core"],["actionIsActive","true"],["hyperlinkURL","https://www.google.com/$recordId$"],["hyperlinkSubParamName1","recordId"],["hyperlinkSubParamField1","Id"],["actionHasObject","true"],["actionObjectType","Account"],["actionHasComponent","false"],["actionComponentName",""],["actionRecordVisible","Always Displayed"],["actionUserPermissions",["Read","Create"]]]';

        Test.startTest();
            String response = ListViewAdminController.createAction(jsonStr);
        Test.stopTest();

        actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize2 = actions.size();

        System.assertEquals('success', response);
        System.assertEquals(actionsSize+1, actionsSize2);

        List_View_Action__c action = ListViewActionHelper.getListViewActionByKey('HyperlinkTest-Active-Core:ListViewActionHyperLink:Core:Account');

        System.assert(action != null);
        System.assertEquals(2, action.List_View_Action_Parameters__r.size());

        System.assert(action.RecordTypeId != null);
        System.assertEquals('Core', action.RecordType.Name);
        System.assertEquals(true, action.Is_Active__c);
        System.assertEquals(true, action.Is_Hyperlink__c);
        System.assertEquals('Hyperlink Test - Active - Core', action.Label__c);
        System.assertEquals(null, action.Subtype__c);
        System.assert(action.RecordTypeId != null);

        for (List_View_Action_Parameter__c param: action.List_View_Action_Parameters__r)
        {
            if (param.Field_API_Name__c == 'recordId')
            {
                System.assertEquals('recordId', param.Label__c);
                System.assertEquals('string', param.Type__c);
                System.assertEquals('Id', param.Default_Value__c);
                System.assertEquals(-1, param.Display_Order__c);
            }
        }


    }

    @IsTest
    static void createActionEmailClassicTest()
    {
        ListViewHelper.insertCoreConfiguration();

        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize = actions.size();

        String jsonStr = '[["actionRecordType","Custom"],["actionType","EmailClassic"],["actionSubType",""],["actionLabel","Email Classic Test - Inactive - Custom"],["actionIsActive","false"],["actionHasObject","true"],["actionObjectType","Opportunity"],["actionHasComponent","true"],["actionComponentName","LtnComp"],["actionRecordVisible","Always Displayed"],["actionUserPermissions",""]]';

        Test.startTest();
            String response = ListViewAdminController.createAction(jsonStr);
        Test.stopTest();

        actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize2 = actions.size();

        System.assertEquals('success', response);
        System.assertEquals(actionsSize+1, actionsSize2);

        List_View_Action__c action = ListViewActionHelper.getListViewActionByKey('EmailClassicTest-Inactive-Custom:ListViewActionEmail:Custom:Opportunity');

        System.assert(action != null);
    }

    @IsTest
    static void createActionEmailTemplateTest()
    {
        ListViewHelper.insertCoreConfiguration();

        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize = actions.size();

        String jsonStr = '[["actionRecordType","Core"],["actionType","EmailTemplate"],["actionSubType",""],["actionLabel","Send Email From Template Test - Active - Core"],["actionIsActive","true"],["sendEmailTemplateFolderName","Template Folder Name"],["sendEmailTemplateWhatIdField","AccountId"],["actionHasObject","false"],["actionObjectType",""],["actionHasComponent","false"],["actionComponentName",""],["actionRecordVisible","Displayed if multiple records are selected"],["actionUserPermissions",["Read","Create"]]]';

        Test.startTest();
            String response = ListViewAdminController.createAction(jsonStr);
        Test.stopTest();

        actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize2 = actions.size();

        System.assertEquals('success', response);
        System.assertEquals(actionsSize+1, actionsSize2);

        List_View_Action__c action = ListViewActionHelper.getListViewActionByKey('SendEmailFromTemplateTest-Active-Core:ListViewActionEmail:Core:null');

        System.assert(action != null);
    }

    @IsTest
    static void createActionLWCComponentTest()
    {
        ListViewHelper.insertCoreConfiguration();

        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize = actions.size();

        String jsonStr = '[["actionRecordType","Core"],["actionType","LightningComponent"],["actionSubType",""],["actionLabel","Display LWC Component"],["actionIsActive","false"],["lwcComponentAPIName","c__myComponent"],["actionHasObject","false"],["actionObjectType",""],["actionHasComponent","false"],["actionComponentName",""],["actionRecordVisible","Always Displayed"],["actionUserPermissions",""]]';

        Test.startTest();
            String response = ListViewAdminController.createAction(jsonStr);
        Test.stopTest();

        actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize2 = actions.size();

        System.assertEquals('success', response);
        System.assertEquals(actionsSize+1, actionsSize2);

        List_View_Action__c action = ListViewActionHelper.getListViewActionByKey('DisplayLWCComponent:ListViewActionLWC:Core:null');

        System.assert(action != null);
    }

    @IsTest
    static void createActionAutoFlowTest()
    {
        ListViewHelper.insertCoreConfiguration();

        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize = actions.size();

        String jsonStr = '[["actionRecordType","Core"],["actionType","LaunchFlow"],["actionSubType",""],["actionLabel","Auto Launch Test"],["actionIsActive","false"],["launchFlowAPIName","FlowAPIName"],["actionHasObject","false"],["actionObjectType",""],["actionHasComponent","false"],["actionComponentName",""],["actionRecordVisible","Always Displayed"],["actionUserPermissions",""]]';

        Test.startTest();
            String response = ListViewAdminController.createAction(jsonStr);
        Test.stopTest();

        actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize2 = actions.size();

        System.assertEquals('success', response);
        System.assertEquals(actionsSize+1, actionsSize2);

        List_View_Action__c action = ListViewActionHelper.getListViewActionByKey('AutoLaunchTest:ListViewActionFlow:Core:null');

        System.assert(action != null);
    }

    @IsTest
    static void createActionScreenFlowTest()
    {
        ListViewHelper.insertCoreConfiguration();

        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize = actions.size();

        String jsonStr = '[["actionRecordType","Core"],["actionType","ScreenFlow"],["actionSubType",""],["actionLabel","Screen Flow Test"],["actionIsActive","true"],["screenFlowAPIName","ScreenAPIName"],["screenFlowFrameHeight","600"],["screenFlowFrameWidth","1000"],["actionHasObject","true"],["actionObjectType","Opportunity"],["actionHasComponent","false"],["actionComponentName",""],["actionRecordVisible","Displayed if one record is selected"],["actionUserPermissions",["Create"]]]';

        Test.startTest();
            String response = ListViewAdminController.createAction(jsonStr);
        Test.stopTest();

        actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize2 = actions.size();

        System.assertEquals('success', response);
        System.assertEquals(actionsSize+1, actionsSize2);

        List_View_Action__c action = ListViewActionHelper.getListViewActionByKey('ScreenFlowTest:ListViewActionFlow:Core:Opportunity');

        System.assert(action != null);
    }

    @IsTest
    static void createActionManageDataCreateTest()
    {
        ListViewHelper.insertCoreConfiguration();

        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize = actions.size();

        String jsonStr = '[["actionRecordType","Custom"],["actionType","ManageData"],["actionSubType","Create"],["actionLabel","Create Record Test"],["actionIsActive","true"],["manageDataCreateOwnerField","OwnerId"],["actionHasObject","true"],["actionObjectType","Account"],["actionHasComponent","false"],["actionComponentName",""],["actionRecordVisible","Always Displayed"],["actionUserPermissions",""]]';

        Test.startTest();
            String response = ListViewAdminController.createAction(jsonStr);
        Test.stopTest();

        actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize2 = actions.size();

        System.assertEquals('success', response);
        System.assertEquals(actionsSize+1, actionsSize2);

        List_View_Action__c action = ListViewActionHelper.getListViewActionByKey('CreateRecordTest:ListViewActionCreate:Custom:Account');

        System.assert(action != null);
    }

    @IsTest
    static void createActionManageDataMassCreateTest()
    {
        ListViewHelper.insertCoreConfiguration();

        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize = actions.size();

        String jsonStr = '[["actionRecordType","Core"],["actionType","ManageData"],["actionSubType","MassCreate"],["actionLabel","Mass Create Test"],["actionIsActive","true"],["actionHasObject","false"],["actionObjectType",""],["actionHasComponent","false"],["actionComponentName",""],["actionRecordVisible","Always Displayed"],["actionUserPermissions",""]]';

        Test.startTest();
            String response = ListViewAdminController.createAction(jsonStr);
        Test.stopTest();

        actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize2 = actions.size();

        System.assertEquals('success', response);
        System.assertEquals(actionsSize+1, actionsSize2);

        List_View_Action__c action = ListViewActionHelper.getListViewActionByKey('MassCreateTest:ListViewActionMassCreate:Core:null');

        System.assert(action != null);
    }

    @IsTest
    static void createActionManageDataMassUpdateTest()
    {
        ListViewHelper.insertCoreConfiguration();

        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize = actions.size();

        String jsonStr = '[["actionRecordType","Core"],["actionType","ManageData"],["actionSubType","MassUpdate"],["actionLabel","Mass Update Test"],["actionIsActive","true"],["manageDataMassUpdateLabel1","Account Name"],["manageDataMassUpdateField1","Name"],["manageDataMassUpdateType1","string"],["manageDataMassUpdateOrder1","1"],["manageDataMassUpdateLabel2","Revenue"],["manageDataMassUpdateField2","AnnualRevenue"],["manageDataMassUpdateType2","decimal"],["manageDataMassUpdateOrder2","2"],["manageDataMassUpdateLabel3","Account Type"],["manageDataMassUpdateField3","Type"],["manageDataMassUpdateType3","string"],["manageDataMassUpdateOrder3","3"],["actionHasObject","true"],["actionObjectType","Account"],["actionHasComponent","false"],["actionComponentName",""],["actionRecordVisible","Always Displayed"],["actionUserPermissions",["Read"]]]';

        Test.startTest();
            String response = ListViewAdminController.createAction(jsonStr);
        Test.stopTest();

        actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize2 = actions.size();

        System.assertEquals('success', response);
        System.assertEquals(actionsSize+1, actionsSize2);

        List_View_Action__c action = ListViewActionHelper.getListViewActionByKey('MassUpdateTest:ListViewActionUpdate:Core:Account');

        System.assert(action != null);
    }

    @IsTest
    static void createActionSaveToPDFTest()
    {
        ListViewHelper.insertCoreConfiguration();

        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize = actions.size();

        String jsonStr = '[["actionRecordType","Core"],["actionType","SaveToPDF"],["actionSubType",""],["actionLabel","Save To PDF Test"],["actionIsActive","true"],["actionHasObject","false"],["actionObjectType",""],["actionHasComponent","false"],["actionComponentName",""],["actionRecordVisible","Always Displayed"],["actionUserPermissions",""]]';

        Test.startTest();
            String response = ListViewAdminController.createAction(jsonStr);
        Test.stopTest();

        actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize2 = actions.size();

        System.assertEquals('success', response);
        System.assertEquals(actionsSize+1, actionsSize2);

        List_View_Action__c action = ListViewActionHelper.getListViewActionByKey('SaveToPDFTest:ListViewActionPDF:Core:null');

        System.assert(action != null);
        System.assertEquals('ListViewActionPDF', action.Apex_Class_Name__c);
    }

    @IsTest
    static void createActionCustomTest()
    {
        ListViewHelper.insertCoreConfiguration();

        List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize = actions.size();

        String jsonStr = '[["actionRecordType","Core"],["actionType","Custom"],["actionSubType",""],["actionLabel","Custom Action Test"],["actionIsActive","true"],["customApexClassName","ListViewActionUpdate"],["actionHasObject","false"],["actionObjectType",""],["actionHasComponent","false"],["actionComponentName",""],["actionRecordVisible","Always Displayed"],["actionUserPermissions",""]]';

        Test.startTest();
            String response = ListViewAdminController.createAction(jsonStr);
        Test.stopTest();

        actions = ListViewActionHelper.getListViewActions();
        Integer actionsSize2 = actions.size();

        System.assertEquals('success', response);
        System.assertEquals(actionsSize+1, actionsSize2);

        List_View_Action__c action = ListViewActionHelper.getListViewActionByKey('CustomActionTest:ListViewActionUpdate:Core:null');

        System.assert(action != null);
        System.assertEquals('ListViewActionUpdate', action.Apex_Class_Name__c);
    }

    @IsTest
    static void getOrgWideConfigTest()
    {
        ListViewHelper.insertCoreConfiguration();
    
        Test.startTest();
            
            ListViewAbstract.ListViewConfigWrapper config = ListViewAdminController.getOrgWideConfig();

            System.assertEquals('All', config.getObject());
            System.assertEquals('All', config.getName());
            System.assertEquals(30, config.getParameters().size());

            ListViewAbstract.ListViewParam param = config.getParameters()[0];
            System.assertNotEquals(param.getReadOnly(), null);
            System.assertNotEquals(param.getListValues(), null);
            System.assertNotEquals(param.getIsListString(), null);

        Test.stopTest();
        
    }

    @IsTest
    static void importConfigJSONTest()
    {
        //to recreate JSON perform following - 
        //1. Export from admin page.
        //2. Replace the following chars - \" with \\"
        //3  Remove the following chars = \n and \r and \t
        //4. Replace the following chars - ' with \'
        String jsonConfig = '{"Actions":[{"attributes":{"type":"simpli_lv__List_View_Action__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View_Action__c/a023h00000jdB3MAAU"},"simpli_lv__Is_Flow__c":false,"simpli_lv__Selected_Record_Visibility__c":"Always displayed","simpli_lv__Flow_API_Name__c":null,"simpli_lv__Label__c":"Edit2 All","simpli_lv__Flow_Type__c":null,"simpli_lv__Primary_Key__c":"Edit2All:null","simpli_lv__Object_Type__c":null,"simpli_lv__Permissions__c":"Edit","simpli_lv__Is_Active__c":true,"simpli_lv__Mass_Create_List_View_Name__c":null,"simpli_lv__Subtype__c":null,"simpli_lv__List_View_Action_Parameters__r":null,"simpli_lv__Component_Name__c":null,"simpli_lv__Flow_Frame_Width__c":null,"simpli_lv__Flow_Frame_Height__c":null,"simpli_lv__Apex_Class_Name__c":"ListViewActionEditAll","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v53.0/sobjects/RecordType/0123h000000VDsIAAW"},"Id":"0123h000000VDsIAAW","Name":"Core"},"RecordTypeId":"0123h000000VDsIAAW","Id":"a023h00000jdB3MAAU","simpli_lv__Is_Hyperlink__c":false}],"ListViewConfigs":[{"attributes":{"type":"simpli_lv__List_View_Config__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View_Config__c/a013h00000EgkdkAAB"},"Name":"InterestingAccountQuery","simpli_lv__List_View_Object__c":"Account","LastModifiedDate":"2022-01-12T18:29:59.000+0000","LastModifiedById":"0053h000000xrj3AAA","simpli_lv__Primary_Key__c":"Account:InterestingAccountQuery","Id":"a013h00000EgkdkAAB","simpli_lv__List_View_Config_Parameters__r":{"totalSize":9,"done":true,"records":[{"attributes":{"type":"simpli_lv__List_View_Config_Parameter__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View_Config_Parameter__c/a033h00000Q7X4wAAF"},"simpli_lv__List_View_Config__c":"a013h00000EgkdkAAB","Id":"a033h00000Q7X4wAAF","simpli_lv__Parameter_Name__c":"AllRows","simpli_lv__Parameter_Type__c":"boolean","simpli_lv__Parameter_Label__c":"Include All Rows","simpli_lv__Parameter_Value__c":"false"},{"attributes":{"type":"simpli_lv__List_View_Config_Parameter__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View_Config_Parameter__c/a033h00000kshdTAAQ"},"simpli_lv__List_View_Config__c":"a013h00000EgkdkAAB","Id":"a033h00000kshdTAAQ","simpli_lv__Parameter_Name__c":"PDFTheme","simpli_lv__Parameter_Type__c":"string","simpli_lv__Parameter_Label__c":"PDF Print Theme","simpli_lv__Parameter_Value__c":"striped"},{"attributes":{"type":"simpli_lv__List_View_Config_Parameter__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View_Config_Parameter__c/a033h00000kshdSAAQ"},"simpli_lv__List_View_Config__c":"a013h00000EgkdkAAB","Id":"a033h00000kshdSAAQ","simpli_lv__Parameter_Name__c":"PDFOrientationPortrait","simpli_lv__Parameter_Type__c":"boolean","simpli_lv__Parameter_Label__c":"PDF Print Uses Portrait Orientation","simpli_lv__Parameter_Value__c":"true"},{"attributes":{"type":"simpli_lv__List_View_Config_Parameter__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View_Config_Parameter__c/a033h00000Q7X4vAAF"},"simpli_lv__List_View_Config__c":"a013h00000EgkdkAAB","Id":"a033h00000Q7X4vAAF","simpli_lv__Parameter_Name__c":"RefreshRate","simpli_lv__Parameter_Type__c":"number","simpli_lv__Parameter_Label__c":"Refresh Rate","simpli_lv__Parameter_Value__c":"45"},{"attributes":{"type":"simpli_lv__List_View_Config_Parameter__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View_Config_Parameter__c/a033h00000Q7X4uAAF"},"simpli_lv__List_View_Config__c":"a013h00000EgkdkAAB","Id":"a033h00000Q7X4uAAF","simpli_lv__Parameter_Name__c":"ReturnSize","simpli_lv__Parameter_Type__c":"number","simpli_lv__Parameter_Label__c":"Return Size","simpli_lv__Parameter_Value__c":"100"},{"attributes":{"type":"simpli_lv__List_View_Config_Parameter__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View_Config_Parameter__c/a033h00000kshdUAAQ"},"simpli_lv__List_View_Config__c":"a013h00000EgkdkAAB","Id":"a033h00000kshdUAAQ","simpli_lv__Parameter_Name__c":"SplitColumns","simpli_lv__Parameter_Type__c":"string","simpli_lv__Parameter_Label__c":"Split View Columns"},{"attributes":{"type":"simpli_lv__List_View_Config_Parameter__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View_Config_Parameter__c/a033h00000Q7X4tAAF"},"simpli_lv__List_View_Config__c":"a013h00000EgkdkAAB","Id":"a033h00000Q7X4tAAF","simpli_lv__Parameter_Name__c":"TotalColumnsColor","simpli_lv__Parameter_Type__c":"color","simpli_lv__Parameter_Label__c":"Total Column Color"},{"attributes":{"type":"simpli_lv__List_View_Config_Parameter__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View_Config_Parameter__c/a033h00000Q7X4sAAF"},"simpli_lv__List_View_Config__c":"a013h00000EgkdkAAB","Id":"a033h00000Q7X4sAAF","simpli_lv__Parameter_Name__c":"TotalColumns","simpli_lv__Parameter_Type__c":"string","simpli_lv__Parameter_Label__c":"Total Columns"},{"attributes":{"type":"simpli_lv__List_View_Config_Parameter__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View_Config_Parameter__c/a033h00000kshdRAAQ"},"simpli_lv__List_View_Config__c":"a013h00000EgkdkAAB","Id":"a033h00000kshdRAAQ","simpli_lv__Parameter_Name__c":"ExportHeaderType","simpli_lv__Parameter_Type__c":"boolean","simpli_lv__Parameter_Label__c":"Use API Names For File Export Headers","simpli_lv__Parameter_Value__c":"false"}]},"LastModifiedBy":{"attributes":{"type":"User","url":"/services/data/v53.0/sobjects/User/0053h000000xrj3AAA"},"Name":"Tom Ansley","Id":"0053h000000xrj3AAA"}}],"ListViews":[{"attributes":{"type":"simpli_lv__List_View__c","url":"/services/data/v53.0/sobjects/simpli_lv__List_View__c/a003h00000BWbxlAAD"},"simpli_lv__Describe__c":null,"LastModifiedDate":"2022-01-12T18:29:58.000+0000","LastModifiedBy":{"attributes":{"type":"User","url":"/services/data/v53.0/sobjects/User/0053h000000xrj3AAA"},"Id":"0053h000000xrj3AAA","Name":"Tom Ansley"},"simpli_lv__Label__c":"Interesting Account Query","simpli_lv__Filter_Scope__c":null,"simpli_lv__Custom_Apex_Class__c":"ListViewCustomManual","simpli_lv__Roles_And_Subordinates__c":null,"OwnerId":"0053h000000xrj3AAA","RecordType":{"attributes":{"type":"RecordType","url":"/services/data/v53.0/sobjects/RecordType/0123h000000VDknAAG"},"Id":"0123h000000VDknAAG","Name":"Custom"},"RecordTypeId":"0123h000000VDknAAG","simpli_lv__Territories__c":null,"simpli_lv__Boolean_Filter__c":null,"simpli_lv__Object_Name__c":"Account","simpli_lv__Core_ListView_Id__c":null,"simpli_lv__Groups__c":null,"simpli_lv__Territories_And_Subordinates__c":null,"simpli_lv__Primary_Key__c":"Account:InterestingAccountQuery","simpli_lv__API_Name__c":"InterestingAccountQuery","simpli_lv__Roles__c":null,"simpli_lv__Is_Non_Editable__c":false,"simpli_lv__Subtype__c":"Manual","simpli_lv__All_Internal_Users__c":false,"simpli_lv__Default_Sort_Order__c":null,"simpli_lv__Is_Private__c":false,"Id":"a003h00000BWbxlAAD","simpli_lv__Core_ListView_Query__c":"SELECT Name, NumberOfEmployees, Type, (SELECT Name, Phone, Email, CreatedBy.Name, CreatedBy.Profile.Name FROM Contacts ORDER BY Name)  FROM Account WHERE Id IN (SELECT AccountId FROM Contact WHERE Title = \'SVP, Operations\')","LastModifiedById":"0053h000000xrj3AAA","simpli_lv__Core_ListView_Columns__c":"[{\\"fieldNameOrPath\\":\\"Name\\",\\"type\\":\\"string\\",\\"label\\":\\"Acct Name\\"},{\\"fieldNameOrPath\\":\\"NumberOfEmployees\\",\\"type\\":\\"decimal\\",\\"label\\":\\"Num Empl.\\"},{\\"fieldNameOrPath\\":\\"Type\\",\\"type\\":\\"string\\",\\"label\\":\\"Account Type\\"},{\\"fieldNameOrPath\\":\\"Contacts.Name\\",\\"type\\":\\"string\\",\\"label\\":\\"Contact Name\\"},{\\"fieldNameOrPath\\":\\"Contacts.Phone\\",\\"type\\":\\"string\\",\\"label\\":\\"Phone\\"},{\\"fieldNameOrPath\\":\\"Contacts.Email\\",\\"type\\":\\"string\\",\\"label\\":\\"Email\\"},{\\"fieldNameOrPath\\":\\"Contacts.CreatedBy.Name\\",\\"type\\":\\"string\\",\\"label\\":\\"Created By\\"},{\\"fieldNameOrPath\\":\\"Contacts.CreatedBy.Profile.Name\\",\\"type\\":\\"string\\",\\"label\\":\\"Created By\\"}]"}]}';
		Test.startTest();
            String result = ListViewAdminController.importConfigJSON(jsonConfig);
        Test.stopTest();
        System.debug('RESULT - ' + result);
        System.assert(!result.startsWith('There was an error'));
        System.assert(result.contains('List Views:1:0;'));
        System.assert(result.contains('Configs:1:0;'));
        System.assert(result.contains('Actions:1:0;'));
    }

    /*
    String json = ListViewAdminController.getConfigExportJSON();
    System.debug(LoggingLevel.FINE, json);
    */
    @IsTest
    static void getConfigExportJSONTest()
    {
        ListViewHelper.insertCoreConfiguration();

        Test.startTest();
            String json = ListViewAdminController.getConfigExportJSON();
        Test.stopTest();
        System.assert(!String.isEmpty(json));
    }

    @IsTest
    static void createGlobalConfigTest()
    {
        List_View_Config__c orgWideConfig = ListViewConfigHelper.getListViewConfig('All', 'All');
        delete orgWideConfig;
        
        ListViewHelper.clearCache();

        Test.startTest();

            Boolean result = ListViewAdminController.createGlobalConfig();
            System.assertEquals(true, result);

            orgWideConfig = ListViewConfigHelper.getListViewConfig('All', 'All');
            System.assertNotEquals(null, orgWideConfig);

            //check that IsInitialized exists
            List_View_Config_Parameter__c isInitialized;
            for (List_View_Config_Parameter__c param: orgWideConfig.List_View_Config_Parameters__r)
            {
                if (param.Parameter_Name__c == 'IsInitialized')
                    isInitialized = param;
            }
            System.assertNotEquals(null, isInitialized);

            //delete the IsInitialized param
            delete isInitialized;

            result = ListViewAdminController.createGlobalConfig();
            System.assertEquals(true, result);

            //check that IsInitialized has been recreated
            for (List_View_Config_Parameter__c param: orgWideConfig.List_View_Config_Parameters__r)
            {
                if (param.Parameter_Name__c == 'IsInitialized')
                    isInitialized = param;
            }
            System.assertNotEquals(null, isInitialized);

        Test.stopTest();

    }

    @IsTest
    static void cleanListViewsTest()
    {
        ListViewHelper.insertCoreConfiguration();
        Test.startTest();
            ListViewAdminController.cleanListViews();
        Test.stopTest();
        System.assertEquals(true, true); //actual testing of clean list views happens in ListViewCleanBatchTest
    }
            
    @IsTest
    static void updateOrgWideConfigTest()
    {
        ListViewHelper.insertCoreConfiguration();
    
        Test.startTest();
            
            String allowRefresh = ListViewConfigHelper.getOrgWideConfigParam('AllowAutomaticDataRefresh', 'true');
            System.assertEquals('true', allowRefresh);

            String result = ListViewAdminController.saveOrgWideConfig('[["ExcludedObjectTypes",["AIApplication"]],["AllowAutomaticDataRefresh","false"],["DisplayActionsButton","false"]]');
            System.assertEquals('Ok:', result);

            allowRefresh = ListViewConfigHelper.getOrgWideConfigParam('AllowAutomaticDataRefresh', 'true');
            System.assertEquals('false', allowRefresh);

        Test.stopTest();
        
    }

    @IsTest
    static void getObjectNamesTest()
    {
        ListViewHelper.insertCoreConfiguration();
    
        Test.startTest();
            
            List<ListViewController.SelectOption> objNames = ListViewAdminController.getObjectNames();

            System.assert(objNames.size() > 0);
            Boolean hasAccount = false;
            for (ListViewController.SelectOption option: objNames)
            {
                if (option.value == 'Account')
                    hasAccount = true;
            }
            System.assertEquals(true, hasAccount);

        Test.stopTest();
        
    }

    @IsTest
    static void unScheduleRefreshTest()
    {
        ListViewHelper.insertCoreConfiguration();
    
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');

        Test.startTest();
            
            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewActionHelper.SUCCESS);

    }

    @IsTest
    static void scheduleMinutelyRefreshTest()
    {
        ListViewHelper.insertCoreConfiguration();

        //unschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');
        ListViewAdminController.scheduleRefreshJob();

        //reschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'minutely:5');

        Test.startTest();

            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewActionHelper.SUCCESS);

    }

    @IsTest
    static void scheduleHourlyRefreshTest()
    {
        ListViewHelper.insertCoreConfiguration();
    
        //unschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');
        ListViewAdminController.scheduleRefreshJob();

        //reschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'hourly:20');

        Test.startTest();

            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewActionHelper.SUCCESS);

    }

    @IsTest
    static void scheduleDailyRefreshTest()
    {
        ListViewHelper.insertCoreConfiguration();
    
        //unschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');
        ListViewAdminController.scheduleRefreshJob();

        //reschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'daily:20:5');

        Test.startTest();

            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewActionHelper.SUCCESS);

    }

    @IsTest
    static void scheduleWeeklyRefreshTest()
    {
        ListViewHelper.insertCoreConfiguration();
    
        //unschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');
        ListViewAdminController.scheduleRefreshJob();

        //reschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'weekly:20:5:WED');

        Test.startTest();

            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewActionHelper.SUCCESS);

    }

    @IsTest
    static void scheduleMonthlyRefreshTest()
    {
        ListViewHelper.insertCoreConfiguration();
    
        //unschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');
        ListViewAdminController.scheduleRefreshJob();

        //reschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'monthly:20:5:15');

        Test.startTest();

            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewActionHelper.SUCCESS);

    }
}