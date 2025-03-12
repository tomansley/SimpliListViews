/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 03-02-2025
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   11-19-2020   tom@ansleyllc.com   Initial Version
**/
@isTest
private class ListViewHelperTest {

    @testSetup
    private static void createSampleData()
    {

        ListViewHelper.insertCoreConfiguration();

        Account acct = HelperTest.insertAccount('Testy Account');
        HelperTest.insertContact(acct);
        PriceBookEntry pe = HelperTest.createProductAndEntry('Test Product1', 120);    

        Opportunity opp1 = HelperTest.insertOpportunity(acct, 'Opportunity 1');
        Opportunity opp2 = HelperTest.insertOpportunity(acct, 'Opportunity 2');

        HelperTest.insertOpportunityLineItem(opp1, pe, 1, 1200);
        HelperTest.insertOpportunityLineItem(opp2, pe, 2, 2900);
    }

    @IsTest
    static void getChangedListViewsTest()
    {
        Test.startTest();
          Map<Id, ListView> lvs = ListViewHelper.getChangedListViews(1, UserInfo.getUserId(), 9);
        Test.stopTest();

        System.assert(lvs != null);
    }

    @IsTest
    static void getCoreListViewsByObjectTest()
    {
        Test.startTest();
            List<ListView> lvs = ListViewHelper.getCoreListViews('Account');
        Test.stopTest();

        System.assert(lvs != null);
        System.assertNotEquals(0, lvs.size());
        
    }

    @IsTest
    static void getCoreListViewsByIdsTest()
    {
        Set<Id> lvIds = new Set<Id>();
        List<ListView> acctlvs = ListViewHelper.getCoreListViews('Account');
        lvIds.add(acctlvs[0].Id);

        Test.startTest();
            List<ListView> lvs = ListViewHelper.getCoreListViews(lvIds);
        Test.stopTest();

        System.assert(lvs != null);
        System.assertNotEquals(0, lvs.size());
    }

    @IsTest
    static void getListViewDataSOQLTest1()
    {
        String soql = 'SELECT Name, ' + 
                             'List_View_Object__c, ' + 
                             'List_View_Label__c, ' +
                             'LastModifiedDate, ' + 
                             'LastModifiedBy.Name, ' + 
                             'Primary_Key__c ' + 
                        'FROM List_View_Config__c';

        //(String soql, ListViewAbstract.ListViewConfigWrapper lvConfig, List<ListViewHelper.ColumnSortData> sortData, String joinFieldName, Set<String> joinRecordIds, Boolean example)
        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, false, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('LastModifiedDate', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Primary_Key__c', true, 2));
        sortData.add(new ListViewHelper.ColumnSortData('List_View_Object__c', true, 3));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------

    }

    @IsTest
    static void getListViewDataSOQLTest2()
    {
        String soql = 'SELECT Name, ' + 
                             'List_View_Object__c, ' + 
                             'List_View_Label__c, ' +
                             'LastModifiedDate, ' + 
                             'LastModifiedBy.Name, ' + 
                             'Primary_Key__c ' + 
                        'FROM List_View_Config__c ' +
                        'ORDER BY List_View_Object__c';

        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('LastModifiedDate', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Primary_Key__c', true, 2));
        sortData.add(new ListViewHelper.ColumnSortData('List_View_Object__c', true, 3));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------
    }

    @IsTest
    static void getListViewDataSOQLTest3()
    {
        String soql = 'SELECT Name, ' + 
                             'List_View_Object__c, ' + 
                             'List_View_Label__c, ' +
                             'LastModifiedDate, ' + 
                             'LastModifiedBy.Name, ' + 
                             'Primary_Key__c ' + 
                       'FROM List_View_Config__c ' +
                       'LIMIT 100';

        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('LastModifiedDate', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Primary_Key__c', true, 2));
        sortData.add(new ListViewHelper.ColumnSortData('List_View_Object__c', true, 3));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------
    }

    @IsTest
    static void getListViewDataSOQLTest4()
    {
        String soql = 'SELECT Name, ' + 
                             'List_View_Object__c, ' + 
                             'List_View_Label__c, ' +
                             'LastModifiedDate, ' + 
                             'LastModifiedBy.Name, ' + 
                             'Primary_Key__c ' + 
                        'FROM List_View_Config__c ' +
                        'ORDER BY List_View_Object__c ' +
                        'LIMIT 100';

        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('LastModifiedDate', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Primary_Key__c', true, 2));
        sortData.add(new ListViewHelper.ColumnSortData('List_View_Object__c', true, 3));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------
    }

    @IsTest
    static void getListViewDataSOQLTest5()
    {
        String soql = 'SELECT Name, ' + 
                             'List_View_Object__c, ' + 
                             'List_View_Label__c, ' +
                             'LastModifiedDate, ' + 
                             'LastModifiedBy.Name, ' + 
                             'Primary_Key__c, ' + 
                             '(SELECT Parameter_Name__c, ' + 
                                     'Parameter_Type__c, ' + 
                                     'Parameter_Label__c, ' + 
                                     'Parameter_Value__c ' + 
                                'FROM List_View_Config_Parameters__r ' + 
                                'ORDER BY Parameter_Label__c), ' + 
                             '(SELECT Field_Name__c, ' + 
                                     'Highlight_Color__c, ' + 
                                     'Operator__c, ' + 
                                     'Order__c, ' + 
                                     'Value__c ' + 
                              'FROM List_View_Config_Conditions__r ' + 
                              'ORDER BY Order__c ASC) ' + 
                        'FROM List_View_Config__c';

        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('LastModifiedDate', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Primary_Key__c', true, 2));
        sortData.add(new ListViewHelper.ColumnSortData('List_View_Object__c', true, 3));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------
    }

    @IsTest
    static void getListViewDataSOQLTest6()
    {
        String soql = 'SELECT Name, ' + 
                             'Id, ' + 
                             '(SELECT Name ' + 
                                'FROM Contacts ' + 
                                'ORDER BY Name) ' + 
                        'FROM Account';

        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('Name', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Id', true, 2));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------
    }

    @IsTest
    static void getListViewDataSOQLTest7()
    {
        String soql = 'SELECT Id, ' + 
                             '(SELECT Id ' + 
                                'FROM Contacts ' + 
                                'ORDER BY Name), ' + 
                             '(SELECT Id ' + 
                                'FROM Opportunities ' + 
                                'ORDER BY Name) ' + 
                        'FROM Account';

        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('Id', true, 2));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------
    }

    @IsTest
    static void getListViewDataSOQLTest8()
    {
        String soql = 'SELECT Id FROM Account USING SCOPE everything';

        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('Id', true, 2));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------
    }

    @IsTest
    static void getListViewDataSOQLTest9()
    {
        String soql = 'SELECT Id, ' + 
                             '(SELECT Id ' + 
                                'FROM Contacts ' + 
                                'ORDER BY Name), ' + 
                             '(SELECT Id ' + 
                                'FROM Opportunities ' + 
                                'ORDER BY Name) ' + 
                        'FROM Account ' +
                        'WHERE Id IN (SELECT AccountId ' + 
                                     'FROM Contact ' + 
                                     'WHERE Title = \'SVP, Operations\') ';

        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('Id', true, 2));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------
    }

    @IsTest
    static void getListViewDataSOQLTest10()
    {
        String soql = 'SELECT Id, ' + 
                             '(SELECT Id ' + 
                                'FROM Contacts ' + 
                                'ORDER BY Name), ' + 
                             '(SELECT Id ' + 
                                'FROM Opportunities ' + 
                                'ORDER BY Name) ' + 
                        'FROM Account ' +
                        'WHERE Id IN (SELECT AccountId ' + 
                                     'FROM Contact ' + 
                                     'WHERE Title = \'SVP, Operations\') ' +
                        'ORDER BY Id';

        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('Id', true, 2));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------
    }

    @IsTest
    static void getListViewDataSOQLTest11()
    {
        String soql = 'SELECT Name, ' + 
                             'StageName, ' + 
                             'CloseDate, ' + 
                             'ExpectedRevenue, ' + 
                             'Account.Name, ' + 
                             'Account.Type, ' + 
                             'Account.Industry, ' + 
                             'Pricebook2.Name, ' +
                             'PriceBook2.IsActive, ' +
                             '(SELECT Name, ' +
                                     'ListPrice, ' + 
                                     'Product2.Name, ' +
                                     'Product2.ProductCode, ' +
                                     'Product2.LastModifiedBy.Name, ' +
                                     'Quantity, ' +
                                     'TotalPrice ' +
                              'FROM OpportunityLineItems) ' +
                      'FROM Opportunity ' +
                      'WHERE HasOpportunityLineItem = true ' +
                            'AND IsWon = false ' +
                            'AND IsClosed = false';

        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('Id', true, 2));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);

        //-------------------------------------
    }

    @IsTest
    static void CustomOpportunityConfigTest() {

        Test.startTest();
            ListViewAbstract.RowsWrapper rows = ListViewController.getListViewData('', ListViewHelper.MODE_APP, 'Opportunity', 'CustomOpportunityExample', '', '', '', -1, '');
        Test.stopTest();

        //not complete yet as creating pricebook entries and products is a pain in the butt!
        System.assert(true);
    }

    @IsTest
    static void getListViewDataSOQLTest12()
    {
        String soql = 'SELECT Name, ' + 
                             'BillingCity, ' + 
                             'BillingState, ' + 
                             'BillingCountry ' + 
                        'FROM Account ' +
                        'WHERE BillingCountry = \'USA\'';

        List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
        System.assert(objs.size() > 0);

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));
        System.assert(objs.size() > 0);

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('BillingCity', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('BillingState', true, 2));

        objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));
        System.assert(objs.size() > 0);
    }

    private static Boolean runSOQLTest(Integer index) {

        List<String> soqlStatements = new List<String>();
        soqlStatements.add('SELECT Account.Name, Contact.FirstName, Contact.LastName FROM Contact WHERE Account.Industry = \'Technology\' AND Contact.LeadSource = \'Web\'');
        soqlStatements.add('SELECT Opportunity.Name, Account.Name, Account.Industry FROM Opportunity WHERE Opportunity.StageName = \'Closed Won\' AND Account.Type = \'Customer\'');
        soqlStatements.add('SELECT Case.CaseNumber, Account.Name, Contact.Email FROM Case WHERE Case.Priority = \'High\' AND Account.Industry = \'Healthcare\'');
        soqlStatements.add('SELECT Asset.Name, Account.Name, Contact.Email FROM Asset WHERE Asset.Status = \'Installed\' AND Account.Type = \'Customer\'');
        soqlStatements.add('SELECT Campaign.Name, Opportunity.Name, Account.Name FROM Opportunity WHERE Campaign.IsActive = true AND Opportunity.IsClosed = false');
        soqlStatements.add('SELECT Contract.ContractNumber, Account.Name FROM Contract WHERE Contract.Status = \'Activated\' AND Account.Type = \'Customer\'');
        soqlStatements.add('SELECT Event.Subject, Account.Name FROM Event WHERE Event.ActivityDate > TODAY AND Account.Industry = \'Financial Services\'');
        soqlStatements.add('SELECT Order.OrderNumber, Account.Name, Contract.ContractNumber FROM Order WHERE Order.Status = \'Activated\' AND Account.Type = \'Customer\'');
        soqlStatements.add('SELECT Product2.Name, PricebookEntry.UnitPrice, Pricebook2.Name FROM PricebookEntry WHERE Product2.Family = \'Hardware\' AND Pricebook2.IsActive = true');
        soqlStatements.add('SELECT Quote.Name, Opportunity.Name, Account.Name FROM Quote WHERE Quote.Status = \'Accepted\' AND Opportunity.StageName = \'Closed Won\'');
        soqlStatements.add('SELECT User.Name, Profile.Name, UserRole.Name FROM User WHERE Profile.Name = \'System Administrator\' AND UserRole.DeveloperName LIKE \'VP%\'');
        soqlStatements.add('SELECT CampaignMember.Status, Contact.Name, Campaign.Name FROM CampaignMember WHERE Contact.LeadSource = \'Partner Referral\' AND Campaign.IsActive = true');
        soqlStatements.add('SELECT OpportunityLineItem.Quantity, Product2.Name, Opportunity.Name FROM OpportunityLineItem WHERE Product2.Family = \'Software\' AND Opportunity.IsClosed = false');
        soqlStatements.add('SELECT Contact.Name, Account.Name, AccountContactRole.Role FROM AccountContactRole WHERE AccountContactRole.Role = \'Decision Maker\' AND Account.Industry = \'Technology\'');
        soqlStatements.add('SELECT Case.Subject, Contact.Name, Account.Name FROM Case WHERE Case.Origin = \'Phone\' AND Contact.Department = \'IT\'');
        soqlStatements.add('SELECT Product2.Name, Product2.Family, PricebookEntry.UnitPrice FROM PricebookEntry WHERE Product2.IsActive = true AND PricebookEntry.IsActive = true');
        soqlStatements.add('SELECT User.Name, UserRole.Name, Profile.Name FROM User WHERE UserRole.Name LIKE \'%Sales%\' AND Profile.Name = \'Standard User\'');
        soqlStatements.add('SELECT Case.CaseNumber, Account.Name, Asset.Name FROM Case WHERE Case.Status = \'Working\' AND Asset.Status = \'Installed\'');
        soqlStatements.add('SELECT Quote.Name, Opportunity.Name, Contact.Name FROM Quote WHERE Quote.ExpirationDate > TODAY AND Opportunity.IsClosed = false');
        soqlStatements.add('SELECT User.Name, UserRole.Name, Profile.Name FROM User WHERE UserRole.DeveloperName LIKE \'Sales%\' AND Profile.UserLicense.Name = \'Salesforce\'');
        soqlStatements.add('SELECT ContentVersion.Title, ContentDocument.FileType FROM ContentVersion WHERE ContentDocument.FileExtension = \'docx\' AND Owner.Department = \'Marketing\'');
        soqlStatements.add('SELECT Account.Name, Owner.Email, Opportunity.Name FROM Opportunity WHERE Account.BillingState = \'CA\'');
        soqlStatements.add('SELECT Asset.Name, Product2.Name, Account.Name FROM Asset WHERE Product2.Family = \'Hardware\' AND Account.Industry = \'Manufacturing\'');
        soqlStatements.add('SELECT Event.Subject, Account.Name, Owner.Name FROM Event WHERE Event.IsAllDayEvent = true AND Account.Type = \'Customer\'');
        soqlStatements.add('SELECT Holiday.Name, Holiday.ActivityDate FROM Holiday WHERE Holiday.IsRecurrence = true');
        soqlStatements.add('SELECT LoginHistory.LoginTime, LoginHistory.Browser FROM LoginHistory');
        soqlStatements.add('SELECT MessagingEndUser.Name, MessagingChannel.DeveloperName, MessagingSession.Status FROM MessagingSession WHERE MessagingEndUser.MessagingPlatformKey LIKE \'%+1%\' AND MessagingChannel.MessageType = \'Text\'');
        soqlStatements.add('SELECT PricebookEntry.UnitPrice, Product2.Name, Pricebook2.Name FROM PricebookEntry WHERE Product2.IsActive = true AND Pricebook2.IsStandard = false');
        soqlStatements.add('SELECT QuoteLineItem.Quantity, Product2.Name, Quote.Name FROM QuoteLineItem WHERE Product2.Family = \'Services\' AND Quote.Status = \'Draft\'');
        soqlStatements.add('SELECT Site.Name, Site.Status FROM Site WHERE Site.Status = \'Active\'');
        soqlStatements.add('SELECT Order.Id FROM Order Order By Order.Id');
        String soql = '';
        try {
            soql = soqlStatements.get(index);

            List<SObject> objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null));
            objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, null, null, null, true, -1));

            List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
            sortData.add(new ListViewHelper.ColumnSortData('Industry', true, 1));
            sortData.add(new ListViewHelper.ColumnSortData('AnnualRevenue', true, 2));

            objs = Database.query(ListViewHelper.getCustomListViewQuery(soql, null, sortData, null, null));

        } catch(Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception thrown - ' + e.getMessage() + ' - ' + e.getStackTraceString());
            System.debug(LoggingLevel.ERROR, 'SOQL Testing - ' + index + ' - ' + soql);
            return false;
        }

        return true;
    }

    @IsTest
    static void getListViewDataSOQLListTest0()
    {
        System.Assert(runSOQLTest(0));
    }

    @IsTest
    static void getListViewDataSOQLListTest1()
    {
        System.Assert(runSOQLTest(1));
    }

    @IsTest
    static void getListViewDataSOQLListTest2()
    {
        System.Assert(runSOQLTest(2));
    }

    @IsTest
    static void getListViewDataSOQLListTest3()
    {
        System.Assert(runSOQLTest(3));
    }

    @IsTest
    static void getListViewDataSOQLListTest4()
    {
        System.Assert(runSOQLTest(4));
    }

    @IsTest
    static void getListViewDataSOQLListTest5()
    {
        System.Assert(runSOQLTest(5));
    }

    @IsTest
    static void getListViewDataSOQLListTest6()
    {
        System.Assert(runSOQLTest(6));
    }

    @IsTest
    static void getListViewDataSOQLListTest7()
    {
        System.Assert(runSOQLTest(7));
    }

    @IsTest
    static void getListViewDataSOQLListTest8()
    {
        System.Assert(runSOQLTest(8));
    }

    @IsTest
    static void getListViewDataSOQLListTest9()
    {
        System.Assert(runSOQLTest(9));
    }

    @IsTest
    static void getListViewDataSOQLListTest10()
    {
        System.Assert(runSOQLTest(10));
    }

    @IsTest
    static void getListViewDataSOQLListTest11()
    {
        System.Assert(runSOQLTest(11));
    }

    @IsTest
    static void getListViewDataSOQLListTest12()
    {
        System.Assert(runSOQLTest(12));
    }

    @IsTest
    static void getListViewDataSOQLListTest13()
    {
        System.Assert(runSOQLTest(13));
    }

    @IsTest
    static void getListViewDataSOQLListTest14()
    {
        System.Assert(runSOQLTest(14));
    }

    @IsTest
    static void getListViewDataSOQLListTest15()
    {
        System.Assert(runSOQLTest(15));
    }

    @IsTest
    static void getListViewDataSOQLListTest16()
    {
        System.Assert(runSOQLTest(16));
    }

    @IsTest
    static void getListViewDataSOQLListTest17()
    {
        System.Assert(runSOQLTest(17));
    }

    @IsTest
    static void getListViewDataSOQLListTest18()
    {
        System.Assert(runSOQLTest(18));
    }

    @IsTest
    static void getListViewDataSOQLListTest19()
    {
        System.Assert(runSOQLTest(19));
    }

    @IsTest
    static void getListViewDataSOQLListTest20()
    {
        System.Assert(runSOQLTest(20));
    }

    @IsTest
    static void getListViewDataSOQLListTest21()
    {
        System.Assert(runSOQLTest(21));
    }

    @IsTest
    static void getListViewDataSOQLListTest22()
    {
        System.Assert(runSOQLTest(22));
    }

    @IsTest
    static void getListViewDataSOQLListTest23()
    {
        System.Assert(runSOQLTest(23));
    }

    @IsTest
    static void getListViewDataSOQLListTest24()
    {
        System.Assert(runSOQLTest(24));
    }

    @IsTest
    static void getListViewDataSOQLListTest25()
    {
        System.Assert(runSOQLTest(25));
    }

    @IsTest
    static void getListViewDataSOQLListTest26()
    {
        System.Assert(runSOQLTest(26));
    }

    @IsTest
    static void getListViewDataSOQLListTest27()
    {
        System.Assert(runSOQLTest(27));
    }

    @IsTest
    static void getListViewDataSOQLListTest28()
    {
        System.Assert(runSOQLTest(28));
    }

    @IsTest
    static void getListViewDataSOQLListTest29()
    {
        System.Assert(runSOQLTest(29));
    }

    @IsTest
    static void getListViewDataSOQLListTest30()
    {
        System.Assert(runSOQLTest(30));
    }

}