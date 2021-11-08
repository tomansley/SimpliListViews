/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-02-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   10-22-2021   tom@ansleyllc.com   Initial Version
**/
@isTest
private class HelperGroupTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();

        //now add special list views with groups/roles etc.
        List<List_View__c> listViews = new List<List_View__c>(); 

        List_View__c lv              = new List_View__c();
        lv.Custom_Apex_Class__c      = 'ListViewCustomManual';
        lv.Label__c                  = 'Group Custom Opportunity Example 1';
        lv.Core_ListView_Columns__c  = '[{"fieldNameOrPath": "Name","type": "string","label": "Opp Name"},{"fieldNameOrPath": "StageName","type": "string","label": "Stage"},{"fieldNameOrPath": "CloseDate","type": "date","label": "Close Date"},{"fieldNameOrPath": "ExpectedRevenue","type": "currency","label": "Revenue"},{"fieldNameOrPath": "Account.Name","type": "string","label": "Acct Name"},{"fieldNameOrPath": "Account.Type","type": "string","label": "Acct Type"},{"fieldNameOrPath": "Account.Industry","type": "string","label": "Acct Industry"},{"fieldNameOrPath": "PriceBook2.Name","type": "string","label": "Price Book"},{"fieldNameOrPath": "PriceBook2.IsActive","type": "string","label": "PB Active"},{"fieldNameOrPath": "OpportunityLineItems.Name","type": "string","label": "LI Name"},{"fieldNameOrPath": "OpportunityLineItems.ListPrice","type": "currency","label": "Price"},{"fieldNameOrPath": "OpportunityLineItems.Product2.ProductCode","type": "string","label": "Prod Code"},{"fieldNameOrPath": "OpportunityLineItems.Product2.LastModifiedBy.Name","type": "string","label": "Last Modified"},{"fieldNameOrPath": "OpportunityLineItems.Quantity","type": "decimal","label": "Quantity"},{"fieldNameOrPath": "OpportunityLineItems.TotalPrice","type": "currency","label": "Total"}]';
        lv.Core_ListView_Query__c    = 'SELECT Name, StageName, CloseDate, ExpectedRevenue, Account.Name, Account.Type, Account.Industry, Pricebook2.Name, PriceBook2.IsActive, (SELECT Name, ListPrice, Product2.Name, Product2.ProductCode, Product2.LastModifiedBy.Name, Quantity, TotalPrice FROM OpportunityLineItems) FROM Opportunity WHERE HasOpportunityLineItem = true AND IsWon = false AND IsClosed = false';
        lv.Object_Name__c            = 'Opportunity';
        lv.RecordTypeId              = ListViewHelper.customRTId;
        lv.Subtype__c                = 'Manual';
        lv.Roles__c                  = '';
        lv.Roles_And_Subordinates__c = '';
        lv.Groups__c                 = 'Group1';

        listViews.add(lv);

        lv                           = new List_View__c();
        lv.Custom_Apex_Class__c      = 'ListViewCustomManual';
        lv.Label__c                  = 'Group Custom Opportunity Example 2';
        lv.Core_ListView_Columns__c  = '[{"fieldNameOrPath": "Name","type": "string","label": "Opp Name"},{"fieldNameOrPath": "StageName","type": "string","label": "Stage"},{"fieldNameOrPath": "CloseDate","type": "date","label": "Close Date"},{"fieldNameOrPath": "ExpectedRevenue","type": "currency","label": "Revenue"},{"fieldNameOrPath": "Account.Name","type": "string","label": "Acct Name"},{"fieldNameOrPath": "Account.Type","type": "string","label": "Acct Type"},{"fieldNameOrPath": "Account.Industry","type": "string","label": "Acct Industry"},{"fieldNameOrPath": "PriceBook2.Name","type": "string","label": "Price Book"},{"fieldNameOrPath": "PriceBook2.IsActive","type": "string","label": "PB Active"},{"fieldNameOrPath": "OpportunityLineItems.Name","type": "string","label": "LI Name"},{"fieldNameOrPath": "OpportunityLineItems.ListPrice","type": "currency","label": "Price"},{"fieldNameOrPath": "OpportunityLineItems.Product2.ProductCode","type": "string","label": "Prod Code"},{"fieldNameOrPath": "OpportunityLineItems.Product2.LastModifiedBy.Name","type": "string","label": "Last Modified"},{"fieldNameOrPath": "OpportunityLineItems.Quantity","type": "decimal","label": "Quantity"},{"fieldNameOrPath": "OpportunityLineItems.TotalPrice","type": "currency","label": "Total"}]';
        lv.Core_ListView_Query__c    = 'SELECT Name, StageName, CloseDate, ExpectedRevenue, Account.Name, Account.Type, Account.Industry, Pricebook2.Name, PriceBook2.IsActive, (SELECT Name, ListPrice, Product2.Name, Product2.ProductCode, Product2.LastModifiedBy.Name, Quantity, TotalPrice FROM OpportunityLineItems) FROM Opportunity WHERE HasOpportunityLineItem = true AND IsWon = false AND IsClosed = false';
        lv.Object_Name__c            = 'Opportunity';
        lv.RecordTypeId              = ListViewHelper.customRTId;
        lv.Subtype__c                = 'Manual';
        lv.Roles__c                  = '';
        lv.Roles_And_Subordinates__c = '';
        lv.Groups__c                 = 'Group2,Group3';

        listViews.add(lv);

        lv                           = new List_View__c();
        lv.Custom_Apex_Class__c      = 'ListViewCustomManual';
        lv.Label__c                  = 'Group Custom Opportunity Example 3';
        lv.Core_ListView_Columns__c  = '[{"fieldNameOrPath": "Name","type": "string","label": "Opp Name"},{"fieldNameOrPath": "StageName","type": "string","label": "Stage"},{"fieldNameOrPath": "CloseDate","type": "date","label": "Close Date"},{"fieldNameOrPath": "ExpectedRevenue","type": "currency","label": "Revenue"},{"fieldNameOrPath": "Account.Name","type": "string","label": "Acct Name"},{"fieldNameOrPath": "Account.Type","type": "string","label": "Acct Type"},{"fieldNameOrPath": "Account.Industry","type": "string","label": "Acct Industry"},{"fieldNameOrPath": "PriceBook2.Name","type": "string","label": "Price Book"},{"fieldNameOrPath": "PriceBook2.IsActive","type": "string","label": "PB Active"},{"fieldNameOrPath": "OpportunityLineItems.Name","type": "string","label": "LI Name"},{"fieldNameOrPath": "OpportunityLineItems.ListPrice","type": "currency","label": "Price"},{"fieldNameOrPath": "OpportunityLineItems.Product2.ProductCode","type": "string","label": "Prod Code"},{"fieldNameOrPath": "OpportunityLineItems.Product2.LastModifiedBy.Name","type": "string","label": "Last Modified"},{"fieldNameOrPath": "OpportunityLineItems.Quantity","type": "decimal","label": "Quantity"},{"fieldNameOrPath": "OpportunityLineItems.TotalPrice","type": "currency","label": "Total"}]';
        lv.Core_ListView_Query__c    = 'SELECT Name, StageName, CloseDate, ExpectedRevenue, Account.Name, Account.Type, Account.Industry, Pricebook2.Name, PriceBook2.IsActive, (SELECT Name, ListPrice, Product2.Name, Product2.ProductCode, Product2.LastModifiedBy.Name, Quantity, TotalPrice FROM OpportunityLineItems) FROM Opportunity WHERE HasOpportunityLineItem = true AND IsWon = false AND IsClosed = false';
        lv.Object_Name__c            = 'Opportunity';
        lv.RecordTypeId              = ListViewHelper.customRTId;
        lv.Subtype__c                = 'Manual';
        lv.Roles__c                  = '';
        lv.Roles_And_Subordinates__c = '';
        lv.Groups__c                 = 'Group4';

        listViews.add(lv);

        for (Integer index = 10; index < 110; index++)
        {
            lv                           = new List_View__c();
            lv.Custom_Apex_Class__c      = 'ListViewCustomManual';
            lv.Label__c                  = 'Group Custom Opportunity Example ' + index;
            lv.Core_ListView_Columns__c  = '[{"fieldNameOrPath": "Name","type": "string","label": "Opp Name"},{"fieldNameOrPath": "StageName","type": "string","label": "Stage"},{"fieldNameOrPath": "CloseDate","type": "date","label": "Close Date"},{"fieldNameOrPath": "ExpectedRevenue","type": "currency","label": "Revenue"},{"fieldNameOrPath": "Account.Name","type": "string","label": "Acct Name"},{"fieldNameOrPath": "Account.Type","type": "string","label": "Acct Type"},{"fieldNameOrPath": "Account.Industry","type": "string","label": "Acct Industry"},{"fieldNameOrPath": "PriceBook2.Name","type": "string","label": "Price Book"},{"fieldNameOrPath": "PriceBook2.IsActive","type": "string","label": "PB Active"},{"fieldNameOrPath": "OpportunityLineItems.Name","type": "string","label": "LI Name"},{"fieldNameOrPath": "OpportunityLineItems.ListPrice","type": "currency","label": "Price"},{"fieldNameOrPath": "OpportunityLineItems.Product2.ProductCode","type": "string","label": "Prod Code"},{"fieldNameOrPath": "OpportunityLineItems.Product2.LastModifiedBy.Name","type": "string","label": "Last Modified"},{"fieldNameOrPath": "OpportunityLineItems.Quantity","type": "decimal","label": "Quantity"},{"fieldNameOrPath": "OpportunityLineItems.TotalPrice","type": "currency","label": "Total"}]';
            lv.Core_ListView_Query__c    = 'SELECT Name, StageName, CloseDate, ExpectedRevenue, Account.Name, Account.Type, Account.Industry, Pricebook2.Name, PriceBook2.IsActive, (SELECT Name, ListPrice, Product2.Name, Product2.ProductCode, Product2.LastModifiedBy.Name, Quantity, TotalPrice FROM OpportunityLineItems) FROM Opportunity WHERE HasOpportunityLineItem = true AND IsWon = false AND IsClosed = false';
            lv.Object_Name__c            = 'Opportunity';
            lv.RecordTypeId              = ListViewHelper.customRTId;
            lv.Subtype__c                = 'Manual';
            lv.Roles__c                  = '';
            lv.Roles_And_Subordinates__c = '';
            lv.Groups__c                 = 'Group' + index;

            listViews.add(lv);
        }

        HelperDatabase.insertRecords(listViews, 'Simpli_lv__List_View__c');

    }

 	@isTest
	static void singleGroupNegativeTest()
	{

        //INSERT USER
		User usr = HelperTest.insertUser('Testerson', 'Standard2', 'testerson', true);

        //INSERT GROUP
        Group grp                  = new Group();
        grp.Name                   = 'Single Group Test';
        grp.DeveloperName          = 'Group1';
        grp.DoesIncludeBosses      = true;
        grp.DoesSendEmailToMembers = false;
        grp.Type                   = 'Regular'; //Role, RoleAndSubordinates, Organization
    
        insert grp;

        System.runAs(usr) {

            Test.startTest();
                Map<String, List_View__c> listViews = ListViewHelper.getListViewsByObject('Opportunity');
            Test.stopTest();

            System.assertEquals(1, listViews.size());
        }
	}

    @isTest
	static void singleGroupPositiveTest()
	{

        //INSERT USER
		User usr = HelperTest.insertUser('Testerson', 'Standard2', 'testerson', true);

        //INSERT GROUP
        Group grp                  = new Group();
        grp.Name                   = 'Single Group Test';
        grp.DeveloperName          = 'Group1';
        grp.DoesIncludeBosses      = true;
        grp.DoesSendEmailToMembers = false;
        grp.Type                   = 'Regular'; //Role, RoleAndSubordinates, Organization
    
        insert grp;

        //INSERT GROUP MEMBER
        GroupMember member = new GroupMember();
        member.GroupId = grp.Id;
        member.UserOrGroupId = usr.Id;

        insert member;


        System.runAs(usr) {

            Test.startTest();
                Map<String, List_View__c> listViews = ListViewHelper.getListViewsByObject('Opportunity');
            Test.stopTest();

            System.assertEquals(2, listViews.size());
        }
	}

    @isTest
	static void multiGroupNegativeTest()
	{

        //INSERT USER
		User usr = HelperTest.insertUser('Testerson', 'Standard2', 'testerson', true);

        //INSERT GROUP
        List<Group> groups = new List<Group>();
        
        Group grp                  = new Group();
        grp.Name                   = 'Single Group Test';
        grp.DeveloperName          = 'Group2';
        grp.DoesIncludeBosses      = true;
        grp.DoesSendEmailToMembers = false;
        grp.Type                   = 'Regular'; //Role, RoleAndSubordinates, Organization
    
        groups.add(grp);

        grp                        = new Group();
        grp.Name                   = 'Single Group Test';
        grp.DeveloperName          = 'Group3';
        grp.DoesIncludeBosses      = true;
        grp.DoesSendEmailToMembers = false;
        grp.Type                   = 'Regular'; //Role, RoleAndSubordinates, Organization
    
        groups.add(grp);

        System.runAs(usr) {

            Test.startTest();
                Map<String, List_View__c> listViews = ListViewHelper.getListViewsByObject('Opportunity');
            Test.stopTest();

            System.assertEquals(1, listViews.size());
        }
    }

    @isTest
	static void multiGroupPositiveTest()
	{

        //INSERT USER
		User usr = HelperTest.insertUser('Testerson', 'Standard2', 'testerson', true);

        //INSERT GROUP
        List<Group> groups = new List<Group>();
        
        Group grp                  = new Group();
        grp.Name                   = 'Single Group Test';
        grp.DeveloperName          = 'Group2';
        grp.DoesIncludeBosses      = true;
        grp.DoesSendEmailToMembers = false;
        grp.Type                   = 'Regular'; //Role, RoleAndSubordinates, Organization
    
        groups.add(grp);

        grp                        = new Group();
        grp.Name                   = 'Single Group Test';
        grp.DeveloperName          = 'Group3';
        grp.DoesIncludeBosses      = true;
        grp.DoesSendEmailToMembers = false;
        grp.Type                   = 'Regular'; //Role, RoleAndSubordinates, Organization
    
        groups.add(grp);

        insert groups;

        //INSERT GROUP MEMBER
        GroupMember member = new GroupMember();
        member.GroupId = grp.Id;
        member.UserOrGroupId = usr.Id;

        insert member;


        System.runAs(usr) {

            Test.startTest();
                Map<String, List_View__c> listViews = ListViewHelper.getListViewsByObject('Opportunity');
            Test.stopTest();

            System.assertEquals(2, listViews.size());
        }
    }

    @isTest
	static void groupInGroupTest()
	{
        //INSERT USER
		User usr = HelperTest.insertUser('Testerson', 'Standard2', 'testerson', true);

        //INSERT GROUPS
        List<Group> groups = new List<Group>();
        
        Group grp5                  = new Group();
        grp5.Name                   = 'Single Group Test';
        grp5.DeveloperName          = 'Group5';
        grp5.DoesIncludeBosses      = true;
        grp5.DoesSendEmailToMembers = false;
        grp5.Type                   = 'Regular'; //Role, RoleAndSubordinates, Organization
    
        groups.add(grp5);

        Group grp4                 = new Group();
        grp4.Name                   = 'Single Group Test';
        grp4.DeveloperName          = 'Group4';
        grp4.DoesIncludeBosses      = true;
        grp4.DoesSendEmailToMembers = false;
        grp4.Type                   = 'Regular'; //Role, RoleAndSubordinates, Organization
    
        groups.add(grp4);

        insert groups;

        //INSERT GROUP MEMBERS
        List<GroupMember> members = new List<GroupMember>();
        
        //INSERT GROUP AS MEMBER OF GROUP
        GroupMember member = new GroupMember();
        member.GroupId = grp4.Id;
        member.UserOrGroupId = grp5.Id;

        members.add(member);

        //INSERT USER AS MEMBER
        member = new GroupMember();
        member.GroupId = grp5.Id;
        member.UserOrGroupId = usr.Id;

        members.add(member);

        insert members;

        System.runAs(usr) {

            Test.startTest();
                Map<String, List_View__c> listViews = ListViewHelper.getListViewsByObject('Opportunity');
            Test.stopTest();

            System.assertEquals(2, listViews.size());
        }
    }

    @isTest
	static void groupInGroupInGroupTest()
	{
        //INSERT USER
		User usr = HelperTest.insertUser('Testerson', 'Standard2', 'testerson', true);

        //INSERT GROUPS
        List<Group> groups = new List<Group>();
        
        Group grp6                  = new Group();
        grp6.Name                   = 'Single Group Test';
        grp6.DeveloperName          = 'Group6';
        grp6.DoesIncludeBosses      = true;
        grp6.DoesSendEmailToMembers = false;
        grp6.Type                   = 'Regular'; //Role, RoleAndSubordinates, Organization
    
        groups.add(grp6);

        Group grp5                  = new Group();
        grp5.Name                   = 'Single Group Test';
        grp5.DeveloperName          = 'Group5';
        grp5.DoesIncludeBosses      = true;
        grp5.DoesSendEmailToMembers = false;
        grp5.Type                   = 'Regular'; //Role, RoleAndSubordinates, Organization
    
        groups.add(grp5);

        Group grp4                 = new Group();
        grp4.Name                   = 'Single Group Test';
        grp4.DeveloperName          = 'Group4';
        grp4.DoesIncludeBosses      = true;
        grp4.DoesSendEmailToMembers = false;
        grp4.Type                   = 'Regular'; //Role, RoleAndSubordinates, Organization
    
        groups.add(grp4);

        insert groups;

        //INSERT GROUP MEMBERS
        List<GroupMember> members = new List<GroupMember>();
        
        //INSERT GROUP AS MEMBER OF GROUP
        GroupMember member = new GroupMember();
        member.GroupId = grp4.Id;
        member.UserOrGroupId = grp5.Id;

        members.add(member);

        //INSERT GROUP AS MEMBER OF GROUP AS MEMBER OF GROUP
        member = new GroupMember();
        member.GroupId = grp5.Id;
        member.UserOrGroupId = grp6.Id;

        members.add(member);

        //INSERT USER AS MEMBER
        member = new GroupMember();
        member.GroupId = grp6.Id;
        member.UserOrGroupId = usr.Id;

        members.add(member);

        insert members;

        System.runAs(usr) {

            Test.startTest();
                Map<String, List_View__c> listViews = ListViewHelper.getListViewsByObject('Opportunity');
            Test.stopTest();

            System.assertEquals(2, listViews.size());
        }
    }
}