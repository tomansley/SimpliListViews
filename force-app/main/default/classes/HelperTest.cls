/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 08-02-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-07-2020   tom.h.ansley@medtronic.com   Initial Version
 * 1.0   07-31-2021   tom.h.ansley@medtronic.com   Added List_View_Label__c field
**/
public with sharing class HelperTest {

    public static Account insertAccount(String name)
    {
		Account acc = new Account(Name = name);
		acc.BillingStreet = '2334 N. Michigan Avenue, Suite 1500';
		acc.BillingCity = 'Chicago';
		acc.BillingState = 'IL';
		acc.BillingPostalCode = '60601';
        acc.BillingCountry = 'USA';
        acc.AnnualRevenue = 125000;
        HelperDatabase.insertRecord(acc, 'Account');
		
		return acc;
    }
    
    public static Opportunity insertOpportunity(Account acct, String name)
    {
		Opportunity opp = new Opportunity(Name = name);
        opp.AccountId = acct.Id;
        opp.StageName = 'Needs Analysis';
        opp.CloseDate = System.today().addDays(-5);
        
        HelperDatabase.insertRecord(opp, 'Opportunity');
		
		return opp;
    }
    
	public static List<List_View__c> createCoreListViews()
	{

        List<List_View__c> simpliListViews = new List<List_View__c>();

		List_View__c simpliListView             = new List_View__c();
		simpliListView.API_Name__c              =  'AllAccounts';
		simpliListView.Object_Name__c           = 'Account';
		simpliListView.Describe__c              = '{"columns":[{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Name","hidden":false,"label":"Account Name","selectListItem":"Name","sortDirection":"ascending","sortIndex":0,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"BillingPostalCode","hidden":false,"label":"Billing Zip/Postal Code","selectListItem":"BillingPostalCode","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"BillingState","hidden":false,"label":"Billing State/Province","selectListItem":"BillingState","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"9-0","descendingLabel":"0-9","fieldNameOrPath":"Phone","hidden":false,"label":"Phone","selectListItem":"Phone","sortDirection":null,"sortIndex":null,"sortable":true,"type":"phone"},{"ascendingLabel":"Low to High","descendingLabel":"High to Low","fieldNameOrPath":"Type","hidden":false,"label":"Type","selectListItem":"toLabel(Type)","sortDirection":null,"sortIndex":null,"sortable":true,"type":"picklist"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Owner.Alias","hidden":false,"label":"Account Owner Alias","selectListItem":"Owner.Alias","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"New to Old","descendingLabel":"Old to New","fieldNameOrPath":"LastModifiedDate","hidden":false,"label":"Last Modified Date","selectListItem":"LastModifiedDate","sortDirection":null,"sortIndex":null,"sortable":true,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Id","hidden":true,"label":"Account ID","selectListItem":"Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"CreatedDate","hidden":true,"label":"Created Date","selectListItem":"CreatedDate","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"SystemModstamp","hidden":true,"label":"System Modstamp","selectListItem":"SystemModstamp","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Owner.Id","hidden":true,"label":"User ID","selectListItem":"Owner.Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"OwnerId","hidden":true,"label":"Owner ID","selectListItem":"OwnerId","sortDirection":null,"sortIndex":null,"sortable":false,"type":"reference"}],"id":"00B150000097DNf","orderBy":[{"fieldNameOrPath":"Name","nullsPosition":"first","sortDirection":"ascending"},{"fieldNameOrPath":"Id","nullsPosition":"first","sortDirection":"ascending"}],"query":"SELECT Name, BillingPostalCode, BillingState, Phone, toLabel(Type), Owner.Alias, LastModifiedDate, Id, CreatedDate, SystemModstamp, Owner.Id, OwnerId FROM Account ORDER BY Name ASC NULLS FIRST, Id ASC NULLS FIRST","scope":"everything","sobjectType":"Account","whereCondition":{"conditions":[],"conjunction":"and"}}';
        simpliListView.Label__c                 = 'All Accounts';
        simpliListView.Primary_Key__c           = 'Account.AllAccounts';
        simpliListView.Core_ListView_Id__c      = '00B3h000003ZfMKEA0';
        simpliListView.Core_ListView_Query__c   = 'SELECT Name, BillingPostalCode, BillingState, Phone, toLabel(Type), Owner.Alias, LastModifiedDate, Id, CreatedDate, SystemModstamp, Owner.Id, OwnerId FROM Account ORDER BY Name ASC NULLS FIRST, Id ASC NULLS FIRST';
        simpliListView.Core_ListView_Columns__c = '[{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Name","hidden":false,"label":"Account Name","selectListItem":"Name","sortDirection":"ascending","sortIndex":0,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"BillingPostalCode","hidden":false,"label":"Billing Zip/Postal Code","selectListItem":"BillingPostalCode","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"BillingState","hidden":false,"label":"Billing State/Province","selectListItem":"BillingState","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"9-0","descendingLabel":"0-9","fieldNameOrPath":"Phone","hidden":false,"label":"Phone","selectListItem":"Phone","sortDirection":null,"sortIndex":null,"sortable":true,"type":"phone"},{"ascendingLabel":"Low to High","descendingLabel":"High to Low","fieldNameOrPath":"Type","hidden":false,"label":"Type","selectListItem":"toLabel(Type)","sortDirection":null,"sortIndex":null,"sortable":true,"type":"picklist"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Owner.Alias","hidden":false,"label":"Account Owner Alias","selectListItem":"Owner.Alias","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"New to Old","descendingLabel":"Old to New","fieldNameOrPath":"LastModifiedDate","hidden":false,"label":"Last Modified Date","selectListItem":"LastModifiedDate","sortDirection":null,"sortIndex":null,"sortable":true,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Id","hidden":true,"label":"Account ID","selectListItem":"Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"CreatedDate","hidden":true,"label":"Created Date","selectListItem":"CreatedDate","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"SystemModstamp","hidden":true,"label":"System Modstamp","selectListItem":"SystemModstamp","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Owner.Id","hidden":true,"label":"User ID","selectListItem":"Owner.Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"OwnerId","hidden":true,"label":"Owner ID","selectListItem":"OwnerId","sortDirection":null,"sortIndex":null,"sortable":false,"type":"reference"}]';
        simpliListView.RecordTypeId             = ListViewHelper.coreRTId;

		simpliListViews.add(simpliListView);

        HelperDatabase.insertRecords(simpliListViews, 'Simpli_lv__List_View__c');

        HelperSchema.checkListViewConfigsAccessible();
		List_View_Config__c config = [SELECT Id FROM List_View_Config__c WHERE Primary_Key__c = 'Account:AllAccounts'];

        List<List_View_Config_Parameter__c> params = new List<List_View_Config_Parameter__c>();

		List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'AdditionalFields';
		param.Parameter_Type__c = 'String';
		param.Parameter_Value__c = 'CreatedBy.Name, Owner.Profile.Name, AnnualRevenue';
		param.List_View_Config__c = config.Id;
        param.Parameter_Label__c  = 'Additional Fields';
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'TotalColumns';
		param.Parameter_Type__c = 'String';
		param.Parameter_Value__c = 'AnnualRevenue';
		param.List_View_Config__c = config.Id;
        param.Parameter_Label__c  = 'Total Columns';
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'TotalColumnsColor';
		param.Parameter_Type__c = 'Color';
		param.Parameter_Value__c = '#E5F0FA';
		param.List_View_Config__c = config.Id;
        param.Parameter_Label__c  = 'Total Column Color';
        params.add(param);
        
        HelperDatabase.insertRecords(params, 'Simpli_lv__List_View_Config_Parameter__c');

        List<List_View_Config_Condition__c> conditions = new List<List_View_Config_Condition__c>();
        
        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = 'AnnualRevenue';
        condition.Highlight_Color__c  = '#000000';
        condition.Operator__c         = 'Equals';
        condition.Order__c            = '1';
        condition.Value__c            = '1000';
        condition.List_View_Config__c = config.Id;

        conditions.add(condition);

        HelperDatabase.insertRecords(conditions, 'Simpli_lv__List_View_Config_Condition__c');

        HelperSchema.checkListViewConfigsAccessible();
		List_View_Config_Parameter__c orgWideConfig = [SELECT Id FROM List_View_Config_Parameter__c WHERE Parameter_Name__c = 'ListViewObjects'];
		orgWideConfig.Parameter_Value__c = '{"Account":"Account"}';
		HelperDatabase.updateRecord(orgWideConfig, 'simpli_lv__List_View_Config_Parameter__c');

		return simpliListViews;
	}

	public static List<List_View__c> createManualListViews()
	{

        List<List_View__c> simpliListViews = new List<List_View__c>();

		List_View__c simpliListView             = new List_View__c();
		simpliListView.Object_Name__c           = 'simpli_lv__List_View_Config__c';
        simpliListView.Label__c                 = 'Manual List View';
        simpliListView.Core_ListView_Query__c   = 'SELECT Name, List_View_Label__c, List_View_Object__c, LastModifiedDate, LastModifiedBy.Name, Primary_Key__c, (SELECT Parameter_Name__c, Parameter_Type__c, Parameter_Label__c, Parameter_Value__c FROM List_View_Config_Parameters__r ORDER BY Parameter_Label__c), (SELECT Field_Name__c, Highlight_Color__c, Operator__c, Order__c, Value__c FROM List_View_Config_Conditions__r ORDER BY Order__c ASC) FROM List_View_Config__c';
        simpliListView.Core_ListView_Columns__c = '[{"fieldNameOrPath":"Name","type":"string","label":"Name"},{"fieldNameOrPath":"simpli_lv__List_View_Object__c","type":"string","label":"Object"},{"fieldNameOrPath":"LastModifiedDate","type":"string","label":"Last Modified"},{"fieldNameOrPath":"LastModifiedBy.Name","type":"string","label":"Last Modified By"},{"fieldNameOrPath":"simpli_lv__Primary_Key__c","type":"string","label":"Primary Key"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Parameters__r.simpli_lv__Parameter_Name__c","type":"string","label":"Parameter Name"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Parameters__r.simpli_lv__Parameter_Type__c","type":"string","label":"Parameter Type"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Parameters__r.simpli_lv__Parameter_Label__c","type":"string","label":"Parameter Label"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Parameters__r.simpli_lv__Parameter_Value__c","type":"string","label":"Parameter Value"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Conditions__r.simpli_lv__Field_Name__c","type":"string","label":"Field Name"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Conditions__r.simpli_lv__Highlight_Color__c","type":"string","label":"Highlight Color"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Conditions__r.simpli_lv__Operator__c","type":"string","label":"Operator"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Conditions__r.simpli_lv__Order__c","type":"string","label":"Order"},{"fieldNameOrPath":"simpli_lv__List_View_Config_Conditions__r.simpli_lv__Value__c","type":"string","label":"Value"}]';
        simpliListView.RecordTypeId             = ListViewHelper.customRTId;
        simpliListView.Custom_Apex_Class__c     = 'ListViewCustomManual';
        simpliListView.SubType__c              = 'Manual';

		simpliListViews.add(simpliListView);

        HelperDatabase.insertRecords(simpliListViews, 'Simpli_lv__List_View__c');

        HelperSchema.checkListViewConfigsAccessible();
		List_View_Config__c config = [SELECT Id FROM List_View_Config__c WHERE Primary_Key__c = 'simpli_lv__List_View_Config__c:ManualListView'];

        List<List_View_Config_Parameter__c> params = new List<List_View_Config_Parameter__c>();

		List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'TotalColumns';
		param.Parameter_Type__c = 'String';
		param.Parameter_Value__c = 'AnnualRevenue';
		param.List_View_Config__c = config.Id;
        param.Parameter_Label__c  = 'Total Columns';
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'TotalColumnsColor';
		param.Parameter_Type__c = 'Color';
		param.Parameter_Value__c = '#E5F0FA';
		param.List_View_Config__c = config.Id;
        param.Parameter_Label__c  = 'Total Column Color';
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'ReturnSize';
		param.Parameter_Type__c = 'Number';
		param.Parameter_Value__c = '100';
		param.List_View_Config__c = config.Id;
        param.Parameter_Label__c  = 'Return Size';
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'RefreshRate';
		param.Parameter_Type__c = 'Number';
		param.Parameter_Value__c = '45';
		param.List_View_Config__c = config.Id;
        param.Parameter_Label__c  = 'Refresh Rate';
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'AllRows';
		param.Parameter_Type__c = 'Boolean';
		param.Parameter_Value__c = 'false';
		param.List_View_Config__c = config.Id;
        param.Parameter_Label__c  = 'All Rows';
        params.add(param);
        
        HelperDatabase.insertRecords(params, 'Simpli_lv__List_View_Config_Parameter__c');

        List<List_View_Config_Condition__c> conditions = new List<List_View_Config_Condition__c>();
        
        List_View_Config_Condition__c condition = new List_View_Config_Condition__c();
        condition.Field_Name__c       = 'List_View_Object__c';
        condition.Highlight_Color__c  = '#000000';
        condition.Operator__c         = 'Equals';
        condition.Order__c            = '1';
        condition.Value__c            = 'Account';
        condition.List_View_Config__c = config.Id;

        conditions.add(condition);

        HelperDatabase.insertRecords(conditions, 'Simpli_lv__List_View_Config_Condition__c');

        HelperSchema.checkListViewConfigsAccessible();
		List_View_Config_Parameter__c orgWideConfig = [SELECT Id FROM List_View_Config_Parameter__c WHERE Parameter_Name__c = 'ListViewObjects'];
		orgWideConfig.Parameter_Value__c = '{"simpli_lv__List_View_Config__c":"Manual List View"}';
		HelperDatabase.updateRecord(orgWideConfig, 'simpli_lv__List_View_Config_Parameter__c');

		return simpliListViews;
	}

	public static List<List_View_Action__c> createListViewActions()
	{
		List<List_View_Action__c> listViewActions = new List<List_View_Action__c>();

		List_View_Action__c delAction = new List_View_Action__c();
		delAction.Label__c            = 'Delete';
        delAction.Object_Type__c      = '';
        delAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		delAction.Apex_Class_Name__c  = 'ListViewActionDelete';

		listViewActions.add(delAction);

		List_View_Action__c updateAction = new List_View_Action__c();
		updateAction.Label__c            = 'Update';
		updateAction.Object_Type__c      = 'Account';
        updateAction.RecordTypeId        = ListViewActionHelper.coreRTId;
		updateAction.Apex_Class_Name__c  = 'ListViewActionUpdate';

		listViewActions.add(updateAction);

        List_View_Action__c oppsCloseUpdateAction = new List_View_Action__c();
        oppsCloseUpdateAction.Apex_Class_Name__c  = 'ListViewActionOppsClose';
        oppsCloseUpdateAction.Label__c            = 'Set Close Lost';
        oppsCloseUpdateAction.Object_Type__c      = 'Opportunity';
        oppsCloseUpdateAction.RecordTypeId        = ListViewActionHelper.coreRTId;

        listViewActions.add(oppsCloseUpdateAction);

        HelperDatabase.insertRecords(listViewActions, 'Simpli_lv__List_View_Action__c');

		List<List_View_Action_Parameter__c> listViewActionParams = new List<List_View_Action_Parameter__c>();

		List_View_Action_Parameter__c actionParam1 = new List_View_Action_Parameter__c();
		actionParam1.Label__c            = 'Account Name';
		actionParam1.Field_API_Name__c   = 'Name';
		actionParam1.List_View_Action__c = updateAction.Id;
		actionParam1.Type__c             = 'STRING';
		actionParam1.Default_Value__c    = 'Test Account Name';
		actionParam1.Placeholder_Text__c = 'Enter an Account Name';

		listViewActionParams.add(actionParam1);

		List_View_Action_Parameter__c actionParam2 = new List_View_Action_Parameter__c();
		actionParam2.Label__c            = 'Industry';
		actionParam2.Field_API_Name__c   = 'Industry';
		actionParam2.List_View_Action__c = updateAction.Id;
		actionParam2.Type__c             = 'STRING';
		actionParam2.Default_Value__c    = 'Electrical';
		actionParam2.Placeholder_Text__c = 'Enter an Industry';

		listViewActionParams.add(actionParam2);

        List_View_Action_Parameter__c actionParam3 = new List_View_Action_Parameter__c();
        actionParam3.Field_API_Name__c   = 'CloseDate';
        actionParam3.Label__c            = 'Close Date';
        actionParam3.Display_Order__c    = 1;
        actionParam3.List_View_Action__c = oppsCloseUpdateAction.Id;
        actionParam3.Placeholder_Text__c = '';
        actionParam3.Type__c             = 'DATE';

        listViewActionParams.add(actionParam3);
        HelperDatabase.insertRecords(listViewActionParams, 'Simpli_lv__List_View_Action_Parameter__c');

		return listViewActions;

	}

}