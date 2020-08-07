/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 08-07-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-07-2020   tom.h.ansley@medtronic.com   Initial Version
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
		insert acc;
		
		return acc;
    }
    
    public static Opportunity insertOpportunity(Account acct, String name)
    {
		Opportunity opp = new Opportunity(Name = name);
        opp.AccountId = acct.Id;
        opp.StageName = 'Needs Analysis';
        opp.CloseDate = System.today().addDays(-5);
        
		insert opp;
		
		return opp;
    }
    
	public static List<List_View__c> createListViews()
	{
		List<List_View__c> simpliListViews = new List<List_View__c>();

		List_View__c simpliListView           = new List_View__c();
		simpliListView.API_Name__c            = 'AllAccounts';
		simpliListView.Object_Name__c         = 'Account';
		simpliListView.Describe__c            = '{"columns":[{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Name","hidden":false,"label":"Account Name","selectListItem":"Name","sortDirection":"ascending","sortIndex":0,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"BillingPostalCode","hidden":false,"label":"Billing Zip/Postal Code","selectListItem":"BillingPostalCode","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"BillingState","hidden":false,"label":"Billing State/Province","selectListItem":"BillingState","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"9-0","descendingLabel":"0-9","fieldNameOrPath":"Phone","hidden":false,"label":"Phone","selectListItem":"Phone","sortDirection":null,"sortIndex":null,"sortable":true,"type":"phone"},{"ascendingLabel":"Low to High","descendingLabel":"High to Low","fieldNameOrPath":"Type","hidden":false,"label":"Type","selectListItem":"toLabel(Type)","sortDirection":null,"sortIndex":null,"sortable":true,"type":"picklist"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Owner.Alias","hidden":false,"label":"Account Owner Alias","selectListItem":"Owner.Alias","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"New to Old","descendingLabel":"Old to New","fieldNameOrPath":"LastModifiedDate","hidden":false,"label":"Last Modified Date","selectListItem":"LastModifiedDate","sortDirection":null,"sortIndex":null,"sortable":true,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Id","hidden":true,"label":"Account ID","selectListItem":"Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"CreatedDate","hidden":true,"label":"Created Date","selectListItem":"CreatedDate","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"SystemModstamp","hidden":true,"label":"System Modstamp","selectListItem":"SystemModstamp","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Owner.Id","hidden":true,"label":"User ID","selectListItem":"Owner.Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"OwnerId","hidden":true,"label":"Owner ID","selectListItem":"OwnerId","sortDirection":null,"sortIndex":null,"sortable":false,"type":"reference"}],"id":"00B150000097DNf","orderBy":[{"fieldNameOrPath":"Name","nullsPosition":"first","sortDirection":"ascending"},{"fieldNameOrPath":"Id","nullsPosition":"first","sortDirection":"ascending"}],"query":"SELECT Name, BillingPostalCode, BillingState, Phone, toLabel(Type), Owner.Alias, LastModifiedDate, Id, CreatedDate, SystemModstamp, Owner.Id, OwnerId FROM Account ORDER BY Name ASC NULLS FIRST, Id ASC NULLS FIRST","scope":"everything","sobjectType":"Account","whereCondition":{"conditions":[],"conjunction":"and"}}';
        simpliListView.Label__c               = 'All Accounts';
        simpliListView.Primary_Key__c         = 'Account.AllAccounts';
        simpliListView.Core_ListView_Id__c    = '00B3h000003ZfMKEA0';
        simpliListView.Core_ListView_Query__c = 'SELECT Name, BillingPostalCode, BillingState, Phone, toLabel(Type), Owner.Alias, LastModifiedDate, Id, CreatedDate, SystemModstamp, Owner.Id, OwnerId FROM Account ORDER BY Name ASC NULLS FIRST, Id ASC NULLS FIRST';
        simpliListView.Core_ListView_Columns__c = '[{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Name","hidden":false,"label":"Account Name","selectListItem":"Name","sortDirection":"ascending","sortIndex":0,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"BillingPostalCode","hidden":false,"label":"Billing Zip/Postal Code","selectListItem":"BillingPostalCode","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"BillingState","hidden":false,"label":"Billing State/Province","selectListItem":"BillingState","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"9-0","descendingLabel":"0-9","fieldNameOrPath":"Phone","hidden":false,"label":"Phone","selectListItem":"Phone","sortDirection":null,"sortIndex":null,"sortable":true,"type":"phone"},{"ascendingLabel":"Low to High","descendingLabel":"High to Low","fieldNameOrPath":"Type","hidden":false,"label":"Type","selectListItem":"toLabel(Type)","sortDirection":null,"sortIndex":null,"sortable":true,"type":"picklist"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Owner.Alias","hidden":false,"label":"Account Owner Alias","selectListItem":"Owner.Alias","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"New to Old","descendingLabel":"Old to New","fieldNameOrPath":"LastModifiedDate","hidden":false,"label":"Last Modified Date","selectListItem":"LastModifiedDate","sortDirection":null,"sortIndex":null,"sortable":true,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Id","hidden":true,"label":"Account ID","selectListItem":"Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"CreatedDate","hidden":true,"label":"Created Date","selectListItem":"CreatedDate","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"SystemModstamp","hidden":true,"label":"System Modstamp","selectListItem":"SystemModstamp","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Owner.Id","hidden":true,"label":"User ID","selectListItem":"Owner.Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"OwnerId","hidden":true,"label":"Owner ID","selectListItem":"OwnerId","sortDirection":null,"sortIndex":null,"sortable":false,"type":"reference"}]';

		simpliListViews.add(simpliListView);

		insert simpliListViews;

		List_View_Config__c config = new List_View_Config__c();
		config.Name                = 'AllAccounts';
		config.List_View_Object__c = 'Account';

		insert config;

        List<List_View_Config_Parameter__c> params = new List<List_View_Config_Parameter__c>();

		List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'AdditionalFields';
		param.Parameter_Type__c = 'String';
		param.Parameter_Value__c = 'CreatedBy.Name, Owner.Profile.Name, AnnualRevenue';
		param.List_View_Config__c = config.Id;
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'TotalColumns';
		param.Parameter_Type__c = 'String';
		param.Parameter_Value__c = 'AnnualRevenue';
		param.List_View_Config__c = config.Id;
        params.add(param);
        
        param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'TotalColumnsColor';
		param.Parameter_Type__c = 'String';
		param.Parameter_Value__c = '#E5F0FA';
		param.List_View_Config__c = config.Id;
        params.add(param);
        
        insert params;

		List_View_Config_Parameter__c orgWideConfig = [SELECT Id FROM List_View_Config_Parameter__c WHERE Parameter_Name__c = 'List View Objects'];
		orgWideConfig.Parameter_Value__c = '{"Account":"Account"}';
		update orgWideConfig;

		return simpliListViews;
	}

	public static List<List_View_Action__c> createListViewActions()
	{
		List<List_View_Action__c> listViewActions = new List<List_View_Action__c>();

		List_View_Action__c delAction = new List_View_Action__c();
		delAction.Label__c           = 'Delete';
		delAction.Object_Type__c     = '';
		delAction.Apex_Class_Name__c = 'ListViewActionDelete';

		listViewActions.add(delAction);

		List_View_Action__c updateAction = new List_View_Action__c();
		updateAction.Label__c           = 'Update';
		updateAction.Object_Type__c     = 'Account';
		updateAction.Apex_Class_Name__c = 'ListViewActionUpdate';

		listViewActions.add(updateAction);

        List_View_Action__c oppsCloseUpdateAction = new List_View_Action__c();
        oppsCloseUpdateAction.Apex_Class_Name__c = 'ListViewActionOppsClose';
        oppsCloseUpdateAction.Label__c           = 'Set Close Lost';
        oppsCloseUpdateAction.Object_Type__c     = 'Opportunity';

        listViewActions.add(oppsCloseUpdateAction);

		insert listViewActions;

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
		insert listViewActionParams;

		return listViewActions;

	}

}