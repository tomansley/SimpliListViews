/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 03-14-2025
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   10-22-2021   tom@ansleyllc.com   Initial Version
**/
@isTest
private class HelperRoleTest {

    @testSetup
    static void createSampleData()
    {
                //INSERT USER
		User admin = HelperTest.getUser('Admin', 'Standard2', 'Eastern Sales Team', 'testerson', true);
		User nonAdmin = HelperTest.getUser('NonAdmin', 'Standard2', 'Eastern Sales Team', 'testerson', false);


        System.runAs(admin)
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
            lv.Roles__c                  = 'DirectorDirectSales';
            lv.Roles_And_Subordinates__c = '';
            lv.Groups__c                 = '';

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
            lv.Roles_And_Subordinates__c = 'VPMarketing';
            lv.Groups__c                 = '';

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

            HelperDatabase.insertRecords(listViews);
        }
    }

 	@isTest
	static void singleRoleNegativeTest()
	{
        User usr = [SELECT Id FROM User WHERE LastName = 'NonAdmin' LIMIT 1];
        usr.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'Eastern Sales Team'].Id;
        update usr;

        System.runAs(usr) {

            Test.startTest();
                Map<String, List_View__c> listViews = ListViewHelper.getListViewsByObject('Opportunity');
            Test.stopTest();

            System.assertEquals(1, listViews.size());
        }
	}

    @isTest
	static void singleRolePositiveTest()
	{
        User usr = [SELECT Id FROM User WHERE LastName = 'NonAdmin' LIMIT 1];
        usr.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'Director, Direct Sales'].Id;
        update usr;

        System.runAs(usr) {

            Test.startTest();
                Map<String, List_View__c> listViews = ListViewHelper.getListViewsByObject('Opportunity');
            Test.stopTest();

            System.assertEquals(2, listViews.size());
        }
	}

    @isTest
	static void singleRoleSubordinatePositiveTest()
	{
        User usr = [SELECT Id FROM User WHERE LastName = 'NonAdmin' LIMIT 1];
        usr.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'Marketing Team'].Id;
        update usr;

        System.runAs(usr) {

            Test.startTest();
                Map<String, List_View__c> listViews = ListViewHelper.getListViewsByObject('Opportunity');
            Test.stopTest();

            System.assertEquals(2, listViews.size());
        }
	}

    @isTest
	static void roleSubordinateInGroupPositiveTest()
	{

        User usr = [SELECT Id FROM User WHERE LastName = 'NonAdmin' LIMIT 1];
        usr.UserRoleId = [SELECT Id FROM UserRole WHERE Name = 'Marketing Team'].Id;
        update usr;

        System.runAs(usr) {

            Test.startTest();
                Map<String, List_View__c> listViews = ListViewHelper.getListViewsByObject('Opportunity');
            Test.stopTest();

            System.assertEquals(2, listViews.size());
        }
	}

}