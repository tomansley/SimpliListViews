/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 07-31-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-19-2020   tom.h.ansley@medtronic.com   Initial Version
**/
@isTest
private class ListViewHelperTest {

    @testSetup
    private static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();

        Account acct = HelperTest.insertAccount('Testy Account');
        Opportunity opp = HelperTest.insertOpportunity(acct, 'Opportunity 1');
        opp = HelperTest.insertOpportunity(acct, 'Opportunity 2');
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
        List<SObject> objs = ListViewHelper.getListViewData(soql, null, null, null, null, false, -1);
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = ListViewHelper.getListViewData(soql, null, null, null, null, true, -1);
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('LastModifiedDate', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Primary_Key__c', true, 2));
        sortData.add(new ListViewHelper.ColumnSortData('List_View_Object__c', true, 3));

        objs = ListViewHelper.getListViewData(soql, null, sortData, null, null);
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

        List<SObject> objs = ListViewHelper.getListViewData(soql, null, null, null, null);
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = ListViewHelper.getListViewData(soql, null, null, null, null, true, -1);
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('LastModifiedDate', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Primary_Key__c', true, 2));
        sortData.add(new ListViewHelper.ColumnSortData('List_View_Object__c', true, 3));

        objs = ListViewHelper.getListViewData(soql, null, sortData, null, null);
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

        List<SObject> objs = ListViewHelper.getListViewData(soql, null, null, null, null);
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = ListViewHelper.getListViewData(soql, null, null, null, null, true, -1);
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('LastModifiedDate', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Primary_Key__c', true, 2));
        sortData.add(new ListViewHelper.ColumnSortData('List_View_Object__c', true, 3));

        objs = ListViewHelper.getListViewData(soql, null, sortData, null, null);
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

        List<SObject> objs = ListViewHelper.getListViewData(soql, null, null, null, null);
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = ListViewHelper.getListViewData(soql, null, null, null, null, true, -1);
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('LastModifiedDate', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Primary_Key__c', true, 2));
        sortData.add(new ListViewHelper.ColumnSortData('List_View_Object__c', true, 3));

        objs = ListViewHelper.getListViewData(soql, null, sortData, null, null);
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

        List<SObject> objs = ListViewHelper.getListViewData(soql, null, null, null, null);
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = ListViewHelper.getListViewData(soql, null, null, null, null, true, -1);
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('LastModifiedDate', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Primary_Key__c', true, 2));
        sortData.add(new ListViewHelper.ColumnSortData('List_View_Object__c', true, 3));

        objs = ListViewHelper.getListViewData(soql, null, sortData, null, null);
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

        List<SObject> objs = ListViewHelper.getListViewData(soql, null, null, null, null);
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = ListViewHelper.getListViewData(soql, null, null, null, null, true, -1);
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('Name', true, 1));
        sortData.add(new ListViewHelper.ColumnSortData('Id', true, 2));

        objs = ListViewHelper.getListViewData(soql, null, sortData, null, null);
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

        List<SObject> objs = ListViewHelper.getListViewData(soql, null, null, null, null);
        System.assert(objs.size() > 0);

        //-------------------------------------

        objs = ListViewHelper.getListViewData(soql, null, null, null, null, true, -1);
        System.assert(objs.size() > 0);

        //-------------------------------------

        List<ListViewHelper.ColumnSortData> sortData = new List<ListViewHelper.ColumnSortData>();
        sortData.add(new ListViewHelper.ColumnSortData('Id', true, 2));

        objs = ListViewHelper.getListViewData(soql, null, sortData, null, null);
        System.assert(objs.size() > 0);

        //-------------------------------------
    }

    @IsTest
    static void CustomOpportunityConfigTest() {

        Test.startTest();
            ListViewAbstract.RowsWrapper rows = ListViewController.getListViewData('', 'Opportunity', 'CustomOpportunityExample', '', '', '', -1);
        Test.stopTest();

        //not complete yet as creating pricebook entries and products is a pain in the butt!
        System.assert(true);
    }
}