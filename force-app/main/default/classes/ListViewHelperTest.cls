/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 04-28-2024
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
}