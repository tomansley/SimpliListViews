/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 06-30-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-29-2020   tom.h.ansley@medtronic.com   Initial Version
**/
@isTest
private class ListViewCustomManualTest {
    
    @testSetup
    private static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();

        HelperTest.createManualListViews();

        HelperTest.insertAccount('Test Account 1');
    }

    static testMethod void getListViewDataTest() 
    {
        ListViewAbstract.RowsWrapper rows = ListViewController.getListViewData('', 'simpli_lv__List_View_Config__c', 'ManualListView', '', '', '', -1);

        System.assert(rows != null);
        System.assert(rows.getFieldMetaData() != null);
        System.assert(rows.getFieldMetaData().size() > 0);
        System.assert(rows.getRows() != null);
        System.assert(rows.getRows().size() > 0);
        System.assert(rows.getRowCount() > 0);
        System.assert(rows.getCoreListViewURL() != null);
        System.assert(rows.getDataAsString() != null);
        System.assert(rows.getListView() != null);

        ListViewAbstract.ListViewWrapper listViewWrapper = rows.getListView();
        System.assert(listViewWrapper.getLastModifiedText() != null);
        System.assert(listViewWrapper.getLastModifiedBy() != null);
        System.assert(listViewWrapper.getLastModifiedDate() != null);


        ListViewAbstract.RowWrapper row = rows.rows[0];
        System.assert(row != null);
        System.assert(row.getRowId() != null);
        System.assert(row.getCheckboxId() != null);
        System.assert(row.getFields() != null);
        System.assert(row.getFields().size() > 0);
        System.assert(row.getHighlight() != null);
        System.assert(row.getHighlightColor() != null);

        ListViewAbstract.FieldWrapper field = row.getFields()[0];
        System.assert(field != null);
        System.assert(field.getLabel() != null);
        System.assert(field.getName() != null);
        System.assert(field.getSortIndex() != null);
        System.assert(field.getSortIndexDisplay() != null);
        System.assert(field.getSortDir() != null);
        System.assert(field.getType() != null);
        System.assert(field.getValue() != null);
        System.assert(field.getHasURL() != null);
        System.assert(field.getURL() != null);

    }
}