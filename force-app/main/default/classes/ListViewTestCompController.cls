public with sharing class ListViewTestCompController {
    
    @AuraEnabled(cacheable=true)
    public static ListViewHelper.StandAloneListView getData()
    {
        ListViewHelper.StandAloneListView lv = new ListViewHelper.StandAloneListView();
        lv.data = getRows();
        lv.columns = getColumns();
        return lv;
    }

    //------------------------------------------------------------------------
    // AVAILABLE COLUMN TYPES
    //------------------------------------------------------------------------
    //  id
    //  boolean
    //  double
    //  string
    //  decimal
    //  currency
    //  date
    //  datetime
    //  number
    //  percent
    //  time
    //  picklist
    //  multipicklist
    //  lookup
    //  textarea
    //  rich textarea
    //  url
    //  html
    //  email
    //  phone
    //  integer
    private static List<ListViewHelper.StandAloneColumn> getColumns()
    {
        List<ListViewHelper.StandAloneColumn> columns = new List<simpli_lv.ListViewHelper.StandAloneColumn>();

        ListViewHelper.StandAloneColumn column = new ListViewHelper.StandAloneColumn();
        column.label        = 'Account Name';
        column.name         = 'Name';
        column.type         = 'string';
        column.columnWidth  = '415px';
        columns.add(column);

        column = new ListViewHelper.StandAloneColumn();
        column.label        = 'Account Site';
        column.name         = 'Site';
        column.type         = 'string';
        column.columnWidth  = '305px';
        columns.add(column);

        column = new ListViewHelper.StandAloneColumn();
        column.label        = 'Billing State/Province';
        column.name         = 'BillingState';
        column.type         = 'string';
        column.columnWidth  = '294px';
        columns.add(column);

        column = new ListViewHelper.StandAloneColumn();
        column.label        = 'Last Modified Date';
        column.name         = 'LastModifiedDate';
        column.type         = 'date';
        column.columnWidth  = '175px';
        columns.add(column);

        column = new ListViewHelper.StandAloneColumn();
        column.label        = 'Active';
        column.name         = 'Active';
        column.type         = 'picklist';
        column.columnWidth  = '90px';
        columns.add(column);

        return columns;
    }

    private static List<ListViewHelper.StandAloneRow> getRows()
    {
        List<ListViewHelper.StandAloneRow> rows = new List<ListViewHelper.StandAloneRow>();

        ListViewHelper.StandAloneRow row = new ListViewHelper.StandAloneRow();

        //FIELDS MUST BE IN ORDER OF COLUMNS!
        row.addField('Express Logistics and Transport');
        row.addField('Site 1');
        row.addField('TX');
        row.addField('1673989622000');
        row.addField('No');
        rows.add(row);

        row = new ListViewHelper.StandAloneRow();
        row.addField('Other Logistics');
        row.addField('Other Site 1');
        row.addField('FL');
        row.addField('1674189622000');
        row.addField('Yes');
        rows.add(row);

        return rows;
    }

}