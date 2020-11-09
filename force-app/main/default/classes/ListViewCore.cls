/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 10-29-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-23-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewCore extends ListViewAbstract {

    public override RowsWrapper getData()
    {
        List<SObject> dataRows = ListViewHelper.getListViewData(listview, lvConfig, columnSortData, joinField, joinRecordIds);

        RowsWrapper rowData = handleRowsToWrapper(dataRows, listView, lvConfig, columnSortData);

        return rowData;
    }

    public override List<List_View_Config_Parameter__c> getConfigParams(List_View_Config__c config)
    {
        System.debug(LoggingLevel.DEBUG, 'Entering getConfigParams');
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
        
        if (paramsByName.get('AdditionalFields') == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'AdditionalFields';
            param.Parameter_Type__c   = 'String';
            param.Parameter_Value__c  = '';
            param.Parameter_Label__c  = 'Additional Fields';
            params.add(param);
        } else {
            params.add(paramsByName.get('AdditionalFields'));
        }

        if (paramsByName.get('TotalColumns') == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'TotalColumns';
            param.Parameter_Type__c   = 'String';
            param.Parameter_Value__c  = '';
            param.Parameter_Label__c  = 'Total Columns';
            params.add(param);
        } else {
            params.add(paramsByName.get('TotalColumns'));
        }

        if (paramsByName.get('TotalColumnsColor') == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'TotalColumnsColor';
            param.Parameter_Type__c   = 'Color';
            param.Parameter_Value__c  = '';
            param.Parameter_Label__c  = 'Total Column Color';
            params.add(param);
        } else {
            params.add(paramsByName.get('TotalColumnsColor'));
        }

        if (paramsByName.get('ReturnSize') == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'ReturnSize';
            param.Parameter_Type__c   = 'Number';
            param.Parameter_Value__c  = '100';
            param.Parameter_Label__c  = 'Return Size';
            params.add(param);
        } else {
            params.add(paramsByName.get('ReturnSize'));
        }

        if (paramsByName.get('RefreshRate') == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'RefreshRate';
            param.Parameter_Type__c   = 'Number';
            param.Parameter_Value__c  = '45';
            param.Parameter_Label__c  = 'Refresh Rate';
            params.add(param);
        } else {
            params.add(paramsByName.get('RefreshRate'));
        }

        if (paramsByName.get('AllRows') == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'AllRows';
            param.Parameter_Type__c   = 'Boolean';
            param.Parameter_Value__c  = 'false';
            param.Parameter_Label__c  = 'Include All Rows';
            params.add(param);
        } else {
            params.add(paramsByName.get('AllRows'));
        }

        return params;
    }


    /*
        * Method to take a list of SObjects retrieved using a listviews query and convert the
        * rows into something that front end lightning components can handle.
        */
    private static ListViewAbstract.RowsWrapper handleRowsToWrapper(List<SObject> dataRows, List_View__c listView, 
                                                   ListViewConfigWrapper lvConfig,
                                                   List<ListViewHelper.ColumnSortData> sortData)
    {
        System.debug('Starting ListViewCore.handleRowsToWrapper - ' + System.now().getTime());

        Map<String, ListViewHelper.ColumnSortData> sortDataByFieldName = new Map<String, ListViewHelper.ColumnSortData>();
        for (ListViewHelper.ColumnSortData columnData: sortData)
            sortDataByFieldName.put(columnData.fieldName, columnData);

        ListViewAbstract.RowsWrapper rows = new ListViewAbstract.RowsWrapper(listView);
        
        //get all columns from the list view
        List<Object> allColumns = (List<Object>) JSON.deserializeUntyped(listView.Core_ListView_Columns__c);
        List<Object> columns = new List<Object>();
        Boolean addColumn = true;

        //set the CORE SFDC COLUMN meta data into the rows wrapper
        Integer columnIndex = 1;
        for (Object column: allColumns)
        {
            Map<String, Object> columnData = (Map<String, Object>) column;

            String fieldName = (String) columnData.get('fieldNameOrPath');
            Boolean hidden   = (Boolean) columnData.get('hidden');

            if (!hidden)
            {
                FieldWrapper field = new FieldWrapper((String) columnData.get('label'), 
                                                      (String) columnData.get('type'),
                                                      fieldName,
                                                      columnIndex);

                if (sortDataByFieldName.containsKey(fieldName))
                {
                    field.sortIndex = String.valueOf(sortDataByFieldName.get(fieldName).sortIndex);
                    field.sortDir   = sortDataByFieldName.get(fieldName).sortDirection;
                }

                rows.addFieldMetaData(field);

                columns.add(column);
                columnIndex++;
            }
            
        }

        //set the CUSTOM COLUMN meta data into the rows wrapper
        if (lvConfig != null
            && lvConfig.getParameter('AdditionalFields') != null 
            && lvConfig.getParameter('AdditionalFields').getValue() != null 
            && lvConfig.getParameter('AdditionalFields').getValue() != '' 
            && dataRows.size() > 0)
        {
            //get the field names in a list
            List<String> fields = lvConfig.getParameter('AdditionalFields').getValue().deleteWhitespace().split(',');

            System.debug(LoggingLevel.DEBUG, 'FIELDS - ' + fields);

            //get the object type we are working with
            String objType = HelperSchema.getObjectType(dataRows[0]);

            for (String fieldName: fields)
            {

                HelperSchema.FieldData fieldData = HelperSchema.getFieldData(dataRows[0], fieldName);
                String label = fieldData.label;

                FieldWrapper field = new FieldWrapper(label, 
                                                      fieldData.type.name().toLowerCase(),
                                                      fieldName,
                                                      columnIndex);

                if (sortDataByFieldName.containsKey(fieldName))
                {
                    field.sortIndex = String.valueOf(sortDataByFieldName.get(fieldName).sortIndex);
                    field.sortDir   = sortDataByFieldName.get(fieldName).sortDirection;
                }

                rows.addFieldMetaData(field);

                Map<String, Object> newColumn = new Map<String, Object>();
                newColumn.put('type', fieldData.type.name().toLowerCase());
                newColumn.put('fieldNameOrPath', fieldName);
                newColumn.put('hidden', false);
                newColumn.put('label', label);

                columns.add(newColumn);

                columnIndex++;

            }
        }

        //for each row of data
        for (SObject row: dataRows)
        {

            RowWrapper rowWrapper = new RowWrapper((String.valueOf(row.get('Id'))));
            
            if (HelperSchema.isValidSFDCFieldName(listview.Object_Name__c, 'IsDeleted'))
                rowWrapper.isDeleted = (Boolean) row.get('IsDeleted');
            else
                rowWrapper.isDeleted = false;

            rows.addRow(rowWrapper);

            //for each listview column
            columnIndex = 1;
            for (Object column: columns)
            {
                Map<String, Object> columnData = (Map<String, Object>) column;

                String fieldType = (String) columnData.get('type');
                String fieldName = (String) columnData.get('fieldNameOrPath');
                Boolean hidden   = (Boolean) columnData.get('hidden');

                System.debug(LoggingLevel.DEBUG, 'Field - ' + fieldName + ', Type - ' + fieldType);

                //do not display hidden
                if (hidden) continue;

                HelperSchema.FieldData fieldData = HelperSchema.getFieldData(row, fieldName);

                FieldWrapper field = new FieldWrapper(fieldData.label, 
                                                    String.valueOf(fieldData.value), 
                                                    fieldData.type.name().toLowerCase(),
                                                    fieldName,
                                                    columnIndex);

                if (fieldData.name == 'Name') {
                    if (fieldData.fieldObj != null)
                    {
                        String url = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + String.valueOf(fieldData.fieldObj.get('Id')) + '/view';
                        field.setURL(url);
                    }
                }

                if (sortDataByFieldName.containsKey(fieldName))
                {
                    field.sortIndex = String.valueOf(sortDataByFieldName.get(fieldName).sortIndex);
                    field.sortDir   = sortDataByFieldName.get(fieldName).sortDirection;
                }

                rowWrapper.addField(field);
                columnIndex++;

            }

            if (lvConfig != null)
            rowWrapper.calculateHighlighting(lvConfig.conditions);
        }

        //if totals have been configured
        if (lvConfig != null
            && lvConfig.getParameter('TotalColumns') != null 
            && lvConfig.getParameter('TotalColumns').getValue() != '')
        {

            rows.hasTotalsRow = true;

            System.debug(LoggingLevel.DEBUG, 'Starting total column calculations!');

            String totalColumns = lvConfig.getParameter('TotalColumns').getValue();

            System.debug(LoggingLevel.DEBUG, 'TotalColumns - ' + totalColumns);

            RowWrapper totalWrapper = new RowWrapper('000000000000000000');
            totalWrapper.highlight = true;
            if (lvConfig.getParameter('TotalColumnsColor') != null)
                totalWrapper.highlightColor = lvConfig.getParameter('TotalColumnsColor').getValue();
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

                    FieldWrapper totalField = totalWrapper.getField(fieldWrapper.getName());

                    //if this is the first pass then we will need to create a wrapper 
                    //regardless of whether its a column that is to be calculated.
                    if (totalField == null)
                    {
                        String initValue = '';

                        //for the very first column add the TOTALS string
                        if (totalWrapper.fields.size() == 0) //USE "fields" instead of getFields() to ensure UI works correctly.
                            initValue = 'TOTALS';
                        //for any VALID calculation columns
                        else if (ListViewAbstract.validTotalColumns.contains(fieldWrapper.getType()))
                            initValue = '0';
                        else 
                            initValue = '';

                        totalField = new FieldWrapper(fieldWrapper.getLabel(),  
                                            initValue,
                                            fieldWrapper.getType(),
                                            fieldWrapper.getName(),
                                            fieldWrapper.columnIndex);

                        System.debug(LoggingLevel.DEBUG, 'Added total field - ' + totalField);

                        totalWrapper.addField(totalField);
                    }

                    //see if the field is a column to be totalled
                    if (totalColumns != null && totalColumns.contains(fieldWrapper.getName()))
                    {
                        System.debug(LoggingLevel.DEBUG, 'Found a column to total - ' + fieldWrapper.getName());

                        System.debug(LoggingLevel.DEBUG, 'fieldWrapper.getValue() - ' + fieldWrapper.getValue());
                        System.debug(LoggingLevel.DEBUG, 'fieldWrapper.getType() - ' + fieldWrapper.getType());
                        System.debug(LoggingLevel.DEBUG, 'totalField.value - ' + totalField.value);
                        System.debug(LoggingLevel.DEBUG, 'totalField.getType() - ' + totalField.getType());

                        //if this is a valid column for total calculation and there is a value to calculate
                        if (ListViewAbstract.validTotalColumns.contains(totalField.getType()) && fieldWrapper.getValue() != null && fieldWrapper.getValue() != '')
                        {
                            if (totalField.getType() == 'currency')
                                totalField.value = String.valueOf(Decimal.valueOf(String.valueOf(fieldWrapper.getValue())) + Decimal.valueOf(totalField.value));
                            else
                                totalField.value = String.valueOf(Decimal.valueOf(fieldWrapper.getValue()) + Decimal.valueOf(totalField.value));

                            
                        }
                    }
                }


            }

        }

        System.debug('Ending ListViewCore.handleRowsToWrapper - ' + System.now().getTime());
        return rows;
    }

}