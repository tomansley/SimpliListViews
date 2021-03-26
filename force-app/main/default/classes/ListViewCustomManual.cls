/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 03-26-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-23-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewCustomManual extends ListViewCustomManualAbstract {

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

    public override RowsWrapper getData()
    {
        List<SObject> dataRows = ListViewHelper.getListViewData(listview.Core_ListView_Query__c, lvConfig, columnSortData, joinField, joinRecordIds);

        RowsWrapper rowData = handleRowsToWrapper(dataRows, listView, lvConfig, columnSortData);

        return rowData;
    }

    /*
        * Method to take a list of SObjects retrieved using a listviews query and convert the
        * rows into something that front end lightning components can handle.
        */
    private static ListViewAbstract.RowsWrapper handleRowsToWrapper(List<SObject> dataRows, List_View__c listView, 
                                                   ListViewConfigWrapper lvConfig,
                                                   List<ListViewHelper.ColumnSortData> sortData)
    {
        Long startTime = System.now().getTime();
        System.debug('Starting ListViewCore.handleRowsToWrapper');

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

            String fieldName = ((String) columnData.get('fieldNameOrPath')).toLowerCase();

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

        System.debug(LoggingLevel.FINE, 'SObject row count - ' + dataRows.size());
        //for each row of data
        for (SObject row: dataRows)
        {
            System.debug(LoggingLevel.FINE, 'SObject row Id - ' + row.Id);
            
            Map<String,Object> popFields = row.getPopulatedFieldsAsMap(); //a map of all populated fields 
            Map<String,Object> normalFields = new Map<String, Object>(); //a map of all NON-CHILD fields
            Map<String,Object> childFields = new Map<String, Object>(); //a map of all CHILD fields
            for (String field: popFields.keySet())
            {
                //if its a relationship field
                if (popFields.get(field) instanceof List<SObject>)
                {
                    childFields.put(field.toLowerCase(), popFields.get(field));
                } else {
                    normalFields.put(field.toLowerCase(), popFields.get(field));
                }
            }

            RowWrapper rowWrapper = new RowWrapper((String.valueOf(row.get('Id'))));
            rowWrapper.isDeleted = false;

            //this for loop ONLY GOES THROUGH NONE CHILD FIELDS
            for (FieldWrapper columnMetaData: rows.getFieldMetaData())
            {
                if (normalFields.keySet().contains(columnMetaData.name.substringBefore('.').toLowerCase()))
                {
                    HelperSchema.FieldData fieldData = HelperSchema.getFieldData(row, columnMetaData.name);

                    FieldWrapper field = new FieldWrapper(fieldData.label, 
                                                        String.valueOf(fieldData.value), 
                                                        fieldData.type.name().toLowerCase(),
                                                        columnMetaData.name,
                                                        columnMetaData.columnIndex);

                    if (fieldData.name.toLowerCase() == 'name') {
                        if (fieldData.fieldObj != null)
                        {
                            String url = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/' + String.valueOf(fieldData.fieldObj.get('Id')) + '/view';
                            field.setURL(url);
                        }
                    }

                    if (sortDataByFieldName.containsKey(columnMetaData.name))
                    {
                        field.sortIndex = String.valueOf(sortDataByFieldName.get(columnMetaData.name).sortIndex);
                        field.sortDir   = sortDataByFieldName.get(columnMetaData.name).sortDirection;
                    }

                    rowWrapper.addField(field);
                
                }

            }

            //now go through all CHILD FIELDS
            Boolean hasChildRow = false;
            for (String childFieldKey: childFields.keySet())
            {
                //get children
                List<SObject> children = (List<SObject>) childFields.get(childFieldKey);

                Boolean deleteHeaderData = false;
                for (SObject child: children)
                {
                    RowWrapper clonedWrapper = rowWrapper.cloneWrapper(deleteHeaderData);
                    rows.addRow(clonedWrapper);

                    if (deleteHeaderData == false) 
                        deleteHeaderData = true; //once we have cloned the first wrapper with all fields this ensures all other rows have their header fields removed.

                    //this for loop ONLY GOES THROUGH CHILD FIELDS
                    for (FieldWrapper columnMetaData: rows.getFieldMetaData())
                    {
                        if (columnMetaData.name.contains(childFieldKey))
                        {
                            hasChildRow = true;
                            columnMetaData.isSortable = false; //set the column to not be sortable
                            String fieldName = columnMetaData.name.removeStart(childFieldKey + '.');
                            HelperSchema.FieldData fieldData = HelperSchema.getFieldData(child, fieldName);

                            FieldWrapper field = new FieldWrapper(fieldData.label, 
                                                                String.valueOf(fieldData.value), 
                                                                fieldData.type.name().toLowerCase(),
                                                                fieldName,
                                                                columnMetaData.columnIndex);

                            if (fieldData.name.toLowerCase() == 'name') {
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

                            clonedWrapper.addField(field);
                        
                            if (lvConfig != null)
                                clonedWrapper.calculateHighlighting(lvConfig.conditions);
                        }
                    }
                }
            }
            
            if (!hasChildRow) 
            {
                rows.addRow(rowWrapper);

                if (lvConfig != null)
                    rowWrapper.calculateHighlighting(lvConfig.conditions);
            }
        }

        System.debug(LoggingLevel.DEBUG, rows.getDebugString());
        System.debug('Ending ListViewCore.handleRowsToWrapper - ' + (System.now().getTime() - startTime));
        return rows;
    }

}