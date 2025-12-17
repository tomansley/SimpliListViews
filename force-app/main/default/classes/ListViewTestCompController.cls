public with sharing class ListViewTestCompController {
    
    @AuraEnabled(cacheable=true)
    public static ListViewHelper.StandAloneListView getData()
    {
        ListViewHelper.StandAloneListView lv = new ListViewHelper.StandAloneListView();
        lv.columns = getColumns();
        lv.data = getRows(lv.columns);
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
        column.columnIndex  = '0';
        column.label        = 'Account Name';
        column.name         = 'Name';
        column.type         = 'string';
        column.columnWidth  = '415';
        columns.add(column);

        column = new ListViewHelper.StandAloneColumn();
        column.columnIndex  = '1';
        column.label        = 'Account Site';
        column.name         = 'Site';
        column.type         = 'string';
        column.columnWidth  = '305';
        columns.add(column);

        column = new ListViewHelper.StandAloneColumn();
        column.columnIndex  = '2';
        column.label        = 'Billing State/Province';
        column.name         = 'BillingState';
        column.type         = 'string';
        column.columnWidth  = '294';
        columns.add(column);

        column = new ListViewHelper.StandAloneColumn();
        column.columnIndex  = '3';
        column.label        = 'Last Modified Date';
        column.name         = 'LastModifiedDate';
        column.type         = 'date';
        column.columnWidth  = '175';
        columns.add(column);

        column = new ListViewHelper.StandAloneColumn();
        column.columnIndex  = '4';
        column.label        = 'Active';
        column.name         = 'Active';
        column.type         = 'picklist';
        column.columnWidth  = '90';
        columns.add(column);

        return columns;
    }

    private static List<ListViewHelper.StandAloneRow> getRows(List<ListViewHelper.StandAloneColumn> columns)
    {
        List<ListViewHelper.StandAloneRow> rows = new List<ListViewHelper.StandAloneRow>();

        ListViewHelper.StandAloneRow row = new ListViewHelper.StandAloneRow(columns);

        //FIELDS MUST BE IN ORDER OF COLUMNS!
        row.addField('Express Logistics and Transport', columns[0]);
        row.addField('Site 1', columns[1]);
        row.addField('TX', columns[2]);
        row.addField('1673989622000', columns[3]);
        row.addField('No', columns[4]);
        rows.add(row);

        row = new ListViewHelper.StandAloneRow();
        row.addField('Other Logistics', columns[0]);
        row.addField('Other Site 1', columns[1]);
        row.addField('FL', columns[2]);
        row.addField('1674189622000', columns[3]);
        row.addField('Yes', columns[4]);
        rows.add(row);

        return rows;
    }

}