/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 02-04-2025
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   10-23-2020   tom@ansleyllc.com   Initial Version
 * 2.0   06-18-2021   tom@ansleyllc.com   Added offset to allow for larger datasets
 * 3.0   07-27-2021   tom@ansleyllc.com   Minor changes to allow fields/rows to handle inline-editing
 * 4.0   08-18-2021   tom@ansleyllc.com   Updated strings to static final variables
 * 5.0   12-16-2021   tom@ansleyllc.com   Fixed issue where field data type being returned in ALL CAPS!
 * 6.0   12-15-2021   tom@ansleyllc.com   Pulled out creating types due to different methods for handling types with package names etc.
**/
public with sharing class ListViewCore extends ListViewAbstract {

    public override RowsWrapper getData()
    {
        List<SObject> dataRows = ListViewHelper.getCoreListViewData(listview, lvConfig, columnSortData, joinField, joinRecordIds, this.isShell, offset, textSearchStr);

        RowsWrapper rowData = handleRowsToWrapper(pageName, dataRows, listView, lvConfig, columnSortData, ListViewHelper.offset, isShell);
        rowData.setCompType(compType);
        if (lvConfig.getParameter(ListViewHelper.PARAM_RETURN_SIZE) != null && !String.isEmpty(lvConfig.getParameter(ListViewHelper.PARAM_RETURN_SIZE).getValue()))
            rowData.listView.rowLimit = Integer.valueOf(lvConfig.getParameter(ListViewHelper.PARAM_RETURN_SIZE).getValue());
        else
            rowData.listView.rowLimit = 250;

        return rowData;
    }

    public override String getQuery()
    {
        return ListViewHelper.getCoreListViewQuery(listview, lvConfig, columnSortData, joinField, joinRecordIds, this.isShell, offset);
    }

    public override List<List_View_Config_Parameter__c> getConfigParams(List_View_Config__c config)
    {
        System.debug(LoggingLevel.FINE, 'Entering getConfigParams');
        List<List_View_Config_Parameter__c> params = new List<List_View_Config_Parameter__c>();

        Map<String, List_View_Config_Parameter__c> paramsByName = new Map<String, List_View_Config_Parameter__c>(); 
        
        if (config.List_View_Config_Parameters__r != null)
        {
            for (List_View_Config_Parameter__c param: config.List_View_Config_Parameters__r)
            {
                paramsByName.put(param.Parameter_Name__c, param); //map to determine parameter existence
                params.add(param); //list returned with ALL params
            }
        }
        
        if (paramsByName.get(ListViewHelper.PARAM_ADD_FIELDS) == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_ADD_FIELDS;
            param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
            param.Parameter_Value__c  = '';
            param.Parameter_Label__c  = 'Additional Fields';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_ADD_FIELDS));
        }

        if (paramsByName.get(ListViewHelper.PARAM_TOTAL_COLUMNS) == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_TOTAL_COLUMNS;
            param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
            param.Parameter_Value__c  = '';
            param.Parameter_Label__c  = 'Total Columns';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_TOTAL_COLUMNS));
        }

        if (paramsByName.get(ListViewHelper.PARAM_TOTAL_COLUMN_COLOR) == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_TOTAL_COLUMN_COLOR;
            param.Parameter_Type__c   = 'Color';
            param.Parameter_Value__c  = '';
            param.Parameter_Label__c  = 'Total Column Color';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_TOTAL_COLUMN_COLOR));
        }

        if (paramsByName.get(ListViewHelper.PARAM_RETURN_SIZE) == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_RETURN_SIZE;
            param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
            param.Parameter_Value__c  = '100';
            param.Parameter_Label__c  = 'Return Size';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_RETURN_SIZE));
        }

        if (paramsByName.get(ListViewHelper.PARAM_REFRESH_RATE) == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_REFRESH_RATE;
            param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
            param.Parameter_Value__c  = '45';
            param.Parameter_Label__c  = 'Refresh Rate';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_REFRESH_RATE));
        }

        if (paramsByName.get(ListViewHelper.PARAM_SINGLE_CLICK_REFRESH) == null)
        {        
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_SINGLE_CLICK_REFRESH;
            param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
            param.Parameter_Value__c  = ListViewHelper.FFALSE;
            param.Parameter_Label__c  = 'Single Click For Automatic Data Refresh';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_SINGLE_CLICK_REFRESH));
        }

        if (paramsByName.get(ListViewHelper.PARAM_EXPORT_HEADER_TYPE) == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_EXPORT_HEADER_TYPE;
            param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
            param.Parameter_Value__c  = ListViewHelper.FFALSE;
            param.Parameter_Label__c  = 'Use API Names For File Export Headers';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_EXPORT_HEADER_TYPE));
        }

        if (paramsByName.get(ListViewHelper.PARAM_ALL_ROWS) == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_ALL_ROWS;
            param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
            param.Parameter_Value__c  = ListViewHelper.FFALSE;
            param.Parameter_Label__c  = 'Include All Rows';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_ALL_ROWS));
        }

        if (paramsByName.get(ListViewHelper.PARAM_PDF_ORIENT_PORTRAIT) == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_PDF_ORIENT_PORTRAIT;
            param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
            param.Parameter_Value__c  = ListViewHelper.TTRUE;
            param.Parameter_Label__c  = 'PDF Print Uses Portrait Orientation';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_PDF_ORIENT_PORTRAIT));
        }

        if (paramsByName.get(ListViewHelper.PARAM_PDF_THEME) == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_PDF_THEME;
            param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
            param.Parameter_Value__c  = 'striped';
            param.Parameter_Label__c  = 'PDF Print Theme';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_PDF_THEME));
        }

        if (paramsByName.get(ListViewHelper.PARAM_SPLIT_COLUMNS) == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = ListViewHelper.PARAM_SPLIT_COLUMNS;
            param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
            param.Parameter_Value__c  = '';
            param.Parameter_Label__c  = 'Split View Columns';
            params.add(param);
        } else {
            params.add(paramsByName.get(ListViewHelper.PARAM_SPLIT_COLUMNS));
        }

        return params;
    }

    public override List<ListViewColumn> getColumnData()
    {
        SObject exampleRow = null;   

        //try to get a true example row
        List<SObject> objectRows = null;
        
        //if (listview.RecordTypeId == ListViewHelper.coreRTId)
            objectRows = ListViewHelper.getCoreListViewData(listview, lvConfig, null, null, null, true, -1, '');
        //else 
        //    objectRows = ListViewHelper.getListViewData(listview.Core_ListView_Query__c, lvConfig, null, null, null, true, -1);
        
        if (objectRows != null && objectRows.size() > 0) 
        {
            exampleRow = objectRows[0];
        //if no row then use object type (which will not work if there are weird additional fields.)
        } else {
            Type t = HelperSchema.getClassType(listview.Object_Name__c);
            exampleRow = (SObject) t.newInstance();
        }

        List<ListViewColumn> listViewColumns = new List<ListViewColumn>();

        //get all columns from the list view
        Map<String, ListViewHelper.StandardColumn> cols = ListViewHelper.getColumnsFromJSON(listView.Core_ListView_Columns__c);

        //get the CORE SFDC COLUMN meta data
        for (ListViewHelper.StandardColumn column: cols.values())
        {
            if (column.hidden == null || !column.hidden)
            {
                HelperSchema.FieldData d = HelperSchema.getFieldData(exampleRow, column.fieldNameOrPath);
         
                if (d != null && !d.isChildRel)
                    listViewColumns.add(new ListViewColumn(d.label, column.fieldNameOrPath, d.getType()));
            }
            
        }

        //set the CUSTOM COLUMN meta data into the rows wrapper
        List<String> fields = new List<String>();
        if (lvConfig != null 
            && lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS) != null 
            && lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS).getValue() != null
            && lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS).getValue() != '')
        {
            //get the field names in a list
            fields = lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS).getValue().deleteWhitespace().split(',');

        } else if (config != null
            && !config.List_View_Config_Parameters__r.isEmpty())
        {
            String fieldStr = '';
            for (List_View_Config_Parameter__c param: config.List_View_Config_Parameters__r)
            {
                if (param.Parameter_Name__c == ListViewHelper.PARAM_ADD_FIELDS)
                {
                    fieldStr = param.Parameter_Value__c != null ? param.Parameter_Value__c : '';
                    break;
                }
            }

            //get the field names in a list
            fields = fieldStr.deleteWhitespace().split(',');
        }

        if (!fields.isEmpty())
        {
            System.debug(LoggingLevel.FINE, 'Additional Fields - ' + fields);

            for (String fieldName: fields)
            {
                HelperSchema.FieldData d = HelperSchema.getFieldData(exampleRow, fieldName);
         
                if (d != null)
                    listViewColumns.add(new ListViewColumn(d.label, fieldName, d.getType()));
            }
        

        }

        return listViewColumns;
    }

    /*
        * Method to take a list of SObjects retrieved using a listviews query and convert the
        * rows into something that front end lightning components can handle.
        */
    private static ListViewAbstract.RowsWrapper handleRowsToWrapper(String pageName,
                                                                    List<SObject> dataRows, 
                                                                    List_View__c listView, 
                                                                    ListViewConfigWrapper lvConfig,
                                                                    List<ListViewHelper.ColumnSortData> sortData,
                                                                    Integer offset,
                                                                    Boolean isShell)
    {
        Long startTime = System.now().getTime();
        System.debug(LoggingLevel.FINE, 'Starting ListViewCore.handleRowsToWrapper - ' + startTime);

        Map<String, ListViewHelper.ColumnSortData> sortDataByFieldName = new Map<String, ListViewHelper.ColumnSortData>();
        for (ListViewHelper.ColumnSortData columnData: sortData)
            sortDataByFieldName.put(columnData.fieldName, columnData);

        ListViewAbstract.RowsWrapper rows = new ListViewAbstract.RowsWrapper(listView, lvConfig);
        rows.listView.offset = offset;
        
        //get all columns from the list view
        Map<String, ListViewHelper.StandardColumn> cols = ListViewHelper.getColumnsFromJSON(listView.Core_ListView_Columns__c);

        List<ListViewHelper.StandardColumn> columns = new List<ListViewHelper.StandardColumn>();
        Boolean addColumn = true;

        //set the CORE SFDC COLUMN meta data into the rows wrapper
        Integer columnIndex = 1;
        for (ListViewHelper.StandardColumn column: cols.values())
        {

            if (dataRows.size() > 0 && !column.hidden)
            {

                HelperSchema.FieldData fieldData = HelperSchema.getFieldData(dataRows[0], column.fieldNameOrPath);

                FieldWrapper field = new FieldWrapper(fieldData.label, 
                                                      fieldData.getType(),
                                                      column.fieldNameOrPath,
                                                      columnIndex);

                if (sortDataByFieldName.containsKey(column.fieldNameOrPath))
                {
                    field.sortIndex = String.valueOf(sortDataByFieldName.get(column.fieldNameOrPath).sortIndex);
                    field.sortDir   = sortDataByFieldName.get(column.fieldNameOrPath).sortDirection;
                }

                rows.addFieldMetaData(field);

                columns.add(column);
                columnIndex++;
            }
            
        }

        //set the CUSTOM COLUMN meta data into the rows wrapper
        if (lvConfig != null
            && lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS) != null 
            && lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS).getValue() != null 
            && lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS).getValue() != '' 
            && dataRows.size() > 0)
        {
            //get the field names in a list
            List<String> fields = lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS).getValue().deleteWhitespace().split(',');

            System.debug(LoggingLevel.FINE, 'FIELDS - ' + fields);

            for (String fieldName: fields)
            {
                HelperSchema.FieldData fieldData = HelperSchema.getFieldData(dataRows[0], fieldName);
                String label = fieldData.label;
                String parentObjType = fieldData.parentObjType;

                FieldWrapper field = new FieldWrapper(label, 
                                                    fieldData.getType(),
                                                    fieldName,
                                                    columnIndex);
                field.setParentObjType(parentObjType);

                if (sortDataByFieldName.containsKey(fieldName))
                {
                    field.sortIndex = String.valueOf(sortDataByFieldName.get(fieldName).sortIndex);
                    field.sortDir   = sortDataByFieldName.get(fieldName).sortDirection;
                }

                rows.addFieldMetaData(field);

                ListViewHelper.StandardColumn newColumn = new ListViewHelper.StandardColumn();
                newColumn.type = fieldData.getType();
                newColumn.fieldNameOrPath = fieldName.removeStart(listView.Object_Name__c + '.'); //must remove the object name if its present. i.e. If we are looking for Account.Name on the Account just make it Name
                newColumn.hidden = false;
                newColumn.label = label;

                columns.add(newColumn);

                columnIndex++;
            }
        }

        //get all preset column widths
        List_View_User_Config__c columnWidths = ListViewUserConfigHelper.getCurrentUserConfigByName(pageName, 'columnWidths:' + listView.Primary_Key__c);
        Map<Integer, String> widthsByIndex = new Map<Integer, String>();
        if (columnWidths != null && !String.isEmpty(columnWidths.Value__c))
        {
            List<String> columnWidthsStr = columnWidths.Value__c.split(';');  

            for (String columnWidthStr: columnWidthsStr)
            {
                List<String> values = columnWidthStr.split(':');
                widthsByIndex.put(Integer.valueOf(values[0]), values[1]);
            }

            for (ListViewAbstract.FieldWrapper column: rows.getFieldMetaData())
            {
                column.columnWidth = widthsByIndex.get(column.columnIndex);
            }    
        }

        //for each row of data
        for (SObject row: dataRows)
        {

            RowWrapper rowWrapper = new RowWrapper((String.valueOf(row.get('Id'))), rows);
            
            if (HelperSchema.isValidSFDCFieldName(listview.Object_Name__c, 'IsDeleted'))
                rowWrapper.isDeleted = (Boolean) row.get('IsDeleted');
            else
                rowWrapper.isDeleted = false;

            rowWrapper.recordTypeId = HelperSchema.getRecordTypeId(row);

            rows.addRow(rowWrapper);

            //for each listview column
            columnIndex = 1;
            for (ListViewHelper.StandardColumn column: columns)
            {
                //do not display hidden
                if (column.hidden) continue;

                HelperSchema.FieldData fieldData = HelperSchema.getFieldData(row, column.fieldNameOrPath);

                System.debug(LoggingLevel.FINE, 'Field Data - ' + fieldData);

                String fieldDataType = fieldData.getType();
                String parentObjType = fieldData.parentObjType;

                System.debug(LoggingLevel.FINE, 'Parent Obj Type - ' + parentObjType + ', Field Data Type - ' + fieldDataType + ', Value - ' + fieldData.value);

                FieldWrapper field = new FieldWrapper(fieldData.label, 
                                                    fieldData.value,
                                                    fieldDataType,
                                                    column.fieldNameOrPath,
                                                    columnIndex,
                                                    parentObjType);
                if (fieldData.objValueId != null)
                    field.setObjValueId(fieldData.objValueId);

                field.setIsEditable(fieldData.isEditable);

                //also set the editable state into the column data
                if (rows.getFieldMetaData(field.getName()) != null)
                    rows.getFieldMetaData(field.getName()).setIsEditable(fieldData.isEditable);

                System.debug(LoggingLevel.FINE, 'Field - ' + field);

                if ((ListViewAbstract.validNameColumnNames.contains(fieldData.name)             //if we have the name of the object
                    || parentObjType == 'Task' && fieldData.name == 'Subject')
                    && fieldData.objValue != null        //if we have field data.
                    && fieldData.value != null)  //if we have a display value
                {
                    field.setFieldObj(fieldData.objValue);
                    field.createURL();
                }

                if (sortDataByFieldName.containsKey(column.fieldNameOrPath))
                {
                    field.sortIndex = String.valueOf(sortDataByFieldName.get(column.fieldNameOrPath).sortIndex);
                    field.sortDir   = sortDataByFieldName.get(column.fieldNameOrPath).sortDirection;
                }

                rowWrapper.addField(field);
                columnIndex++;

            }

            if (lvConfig != null && !isShell) {
                rowWrapper.calcRowCSS(lvConfig);
            } else {
                System.debug(LoggingLevel.DEBUG, 'No LV Config');
            }
        }

        //if totals have been configured and we are not paging.
        if (lvConfig != null
            && lvConfig.getParameter(ListViewHelper.PARAM_TOTAL_COLUMNS) != null 
            && !String.isEmpty(lvConfig.getParameter(ListViewHelper.PARAM_TOTAL_COLUMNS).getValue())
            && offset == -1
            && !isShell)
        {

            rows.hasTotalsRow = true;

            System.debug(LoggingLevel.DEBUG, 'Starting total column calculations!');

            String totalColumns = lvConfig.getParameter(ListViewHelper.PARAM_TOTAL_COLUMNS).getValue();

            System.debug(LoggingLevel.DEBUG, 'TotalColumns - ' + totalColumns);

            RowWrapper totalWrapper = new RowWrapper('000000000000000000', rows);
            totalWrapper.highlight = true;
            if (lvConfig.getParameter(ListViewHelper.PARAM_TOTAL_COLUMN_COLOR) != null)
                totalWrapper.highlightColor = lvConfig.getParameter(ListViewHelper.PARAM_TOTAL_COLUMN_COLOR).getValue();
            else
                totalWrapper.highlightColor = '#FFFFFF';
            totalWrapper.isTotals = true;

            rows.addRow(totalWrapper);

            //for each row of data
            for (RowWrapper rowWrapper: rows.getRows())
            {

                if (rowWrapper.getIsTotals()) continue;

                List<FieldWrapper> fields = rowWrapper.getFields();

                //for each field
                for (FieldWrapper fieldWrapper: fields)
                {

                    FieldWrapper totalField = totalWrapper.getField(fieldWrapper.getName() + ':' + fieldWrapper.columnIndex);

                    //if this is the first pass then we will need to create a wrapper 
                    //regardless of whether its a column that is to be calculated.
                    if (totalField == null)
                    {
                        String initValue = '';

                        //for the very first column add the TOTALS string
                        if (totalWrapper.fields.size() == 0) //USE "fields" instead of getFields() to ensure UI works correctly.
                            initValue = 'TOTALS';
                        //for any VALID calculation columns
                        else if (ListViewAbstract.validTotalColumns.contains(fieldWrapper.getType())
                                && totalColumns.contains(fieldWrapper.getName()))
                            initValue = '0';
                        else 
                            initValue = '';

                        totalField = new FieldWrapper(fieldWrapper.getLabel(),  
                                                      initValue,
                                                      fieldWrapper.getType(),
                                                      fieldWrapper.getName(),
                                                      fieldWrapper.columnIndex,
                                                      '');
                        totalField.setIsTotalsRow(true);

                        System.debug(LoggingLevel.DEBUG, 'Added total field - ' + totalField);

                        totalWrapper.addField(totalField);
                    }

                    //see if the field is a column to be totalled
                    if (totalColumns != null && totalColumns.contains(fieldWrapper.getName()))
                    {
                        System.debug(LoggingLevel.DEBUG, 'Found a column to total - ' + fieldWrapper.getName());

                        System.debug(LoggingLevel.DEBUG, 'fieldWrapper            - ' + fieldWrapper);
                        System.debug(LoggingLevel.DEBUG, 'fieldWrapper.getValue() - ' + fieldWrapper.getValue());
                        System.debug(LoggingLevel.DEBUG, 'fieldWrapper.getType()  - ' + fieldWrapper.getType());
                        System.debug(LoggingLevel.DEBUG, 'totalField.value        - ' + totalField.getValue());
                        System.debug(LoggingLevel.DEBUG, 'totalField.getType()    - ' + totalField.getType());

                        //if this is a valid column for total calculation and there is a value to calculate
                        if (ListViewAbstract.validTotalColumns.contains(totalField.getType().toLowerCase()) && !String.isEmpty(fieldWrapper.getValue()))
                        {
                            System.debug(LoggingLevel.DEBUG, 'This is a valid column');
                            if (String.isEmpty(totalField.getValue()))
                                totalField.setValue(0);
                            if (totalField.getType() == ListViewHelper.TYPE_CURRENCY)
                            {
                                System.debug(LoggingLevel.DEBUG, 'This is a currency field');
                                Decimal total = Decimal.valueOf(fieldWrapper.getValue()) + Decimal.valueOf(totalField.getValue());
                                totalField.setValue(total);
                            } else {
                                totalField.setValue(Decimal.valueOf(fieldWrapper.getValue()) + Decimal.valueOf(totalField.getValue()));
                            }
                            System.debug(LoggingLevel.DEBUG, 'Total is now - ' + totalField.getValue());
                            
                        }
                    }
                }


            }

        }

        rows.queryString = ListViewHelper.LATEST_QUERY; //put the query used to get the data into the wrapper for use on the front end (debugging)

        System.debug(LoggingLevel.DEBUG, rows.getDebugString());
        System.debug(LoggingLevel.DEBUG, 'Ending ListViewCore.handleRowsToWrapper - ' + (System.now().getTime() - startTime));
        return rows;
    }

}