/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 12-16-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   10-23-2020   tom@ansleyllc.com   Initial Version
 * 2.0   06-18-2021   tom@ansleyllc.com   Added offset to allow for larger datasets
 * 3.0   08-18-2021   tom@ansleyllc.com   Updated strings to static final variables
 * 4.0   12-16-2021   tom@ansleyllc.com   Fixed issue where field data type being returned in ALL CAPS!
**/
public with sharing class ListViewCustomManual extends ListViewCustomManualAbstract {

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
        
        if (paramsByName.get('TotalColumns') == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'TotalColumns';
            param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
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
            param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
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
            param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
            param.Parameter_Value__c  = '45';
            param.Parameter_Label__c  = 'Refresh Rate';
            params.add(param);
        } else {
            params.add(paramsByName.get('RefreshRate'));
        }

        if (paramsByName.get('ExportHeaderType') == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'ExportHeaderType';
            param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
            param.Parameter_Value__c  = 'false';
            param.Parameter_Label__c  = 'Use API Names For File Export Headers';
            params.add(param);
        } else {
            params.add(paramsByName.get('ExportHeaderType'));
        }

        if (paramsByName.get('AllRows') == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'AllRows';
            param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
            param.Parameter_Value__c  = 'false';
            param.Parameter_Label__c  = 'Include All Rows';
            params.add(param);
        } else {
            params.add(paramsByName.get('AllRows'));
        }

        if (paramsByName.get('PDFOrientationPortrait') == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'PDFOrientationPortrait';
            param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
            param.Parameter_Value__c  = 'true';
            param.Parameter_Label__c  = 'PDF Print Uses Portrait Orientation';
            params.add(param);
        } else {
            params.add(paramsByName.get('PDFOrientationPortrait'));
        }

        if (paramsByName.get('PDFTheme') == null)
        {      
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = config.Id;
            param.Parameter_Name__c   = 'PDFTheme';
            param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
            param.Parameter_Value__c  = 'striped';
            param.Parameter_Label__c  = 'PDF Print Theme';
            params.add(param);
        } else {
            params.add(paramsByName.get('PDFTheme'));
        }

        return params;
    }

    public override RowsWrapper getData()
    {
        List<SObject> dataRows = ListViewHelper.getListViewData(listview.Core_ListView_Query__c, lvConfig, columnSortData, joinField, joinRecordIds, offset);

        RowsWrapper rowData = handleRowsToWrapper(dataRows, listView, lvConfig, columnSortData);

        return rowData;
    }

    public override List<ListViewColumn> getColumnData()
    {
        SObject exampleRow = null;   

        //try to get a true example row
        List<SObject> objectRows = null;
        
        if (listview.RecordTypeId == ListViewHelper.coreRTId)
            objectRows = ListViewHelper.getListViewData(listview, lvConfig, null, null, null, true, -1);
        else 
            objectRows = ListViewHelper.getListViewData(listview.Core_ListView_Query__c, lvConfig, null, null, null, true, -1);
        
        if (objectRows != null && objectRows.size() > 0) 
        {
            exampleRow = objectRows[0];
        //if no row then use object type (which will not work if there are weird additional fields.)
        } else {
            Type t = Type.forName(listview.Object_Name__c);
            exampleRow = (SObject) t.newInstance();
        }

        List<ListViewColumn> listViewColumns = new List<ListViewColumn>();

        //get all columns from the list view
        List<Object> allColumns = (List<Object>) JSON.deserializeUntyped(listView.Core_ListView_Columns__c);

        //get the CORE SFDC COLUMN meta data
        for (Object column: allColumns)
        {
            Map<String, Object> columnData = (Map<String, Object>) column;

            String fieldName = (String) columnData.get('fieldNameOrPath');
            Boolean hidden   = (Boolean) columnData.get('hidden');

            if (hidden == null || !hidden)
            {
                HelperSchema.FieldData d = HelperSchema.getFieldData(exampleRow, fieldName);
         
                if (d != null && !d.isChildRel)
                    listViewColumns.add(new ListViewColumn(d.label, fieldName, d.type.name().toLowerCase()));
            }
            
        }

        //set the CUSTOM COLUMN meta data into the rows wrapper
        if (lvConfig != null 
            && lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS) != null 
            && lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS).getValue() != null
            && lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS).getValue() != '')
        {
            //get the field names in a list
            List<String> fields = lvConfig.getParameter(ListViewHelper.PARAM_ADD_FIELDS).getValue().deleteWhitespace().split(',');

            System.debug(LoggingLevel.FINE, 'Additional Fields - ' + fields);

            for (String fieldName: fields)
            {
                HelperSchema.FieldData d = HelperSchema.getFieldData(exampleRow, fieldName);
         
                if (d != null)
                    listViewColumns.add(new ListViewColumn(d.label, fieldName, d.type.name().toLowerCase()));
            }
        }

        return listViewColumns;
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
        System.debug(LoggingLevel.FINE, 'Starting ListViewCore.handleRowsToWrapper');

        Map<String, ListViewHelper.ColumnSortData> sortDataByFieldName = new Map<String, ListViewHelper.ColumnSortData>();
        for (ListViewHelper.ColumnSortData columnData: sortData)
            sortDataByFieldName.put(columnData.fieldName, columnData);

        ListViewAbstract.RowsWrapper rows = new ListViewAbstract.RowsWrapper(listView, lvConfig);
        
        //get all columns from the list view
        List<Object> allColumns = (List<Object>) JSON.deserializeUntyped(listView.Core_ListView_Columns__c);
        List<Object> columns = new List<Object>();
        Boolean addColumn = true;

        //set the CORE SFDC COLUMN meta data into the rows wrapper
        Integer columnIndex = 1;
        for (Object column: allColumns)
        {
            Map<String, Object> columnData = (Map<String, Object>) column;

            String fieldName = ((String) columnData.get('fieldNameOrPath'));

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
                    childFields.put(field, popFields.get(field));
                } else {
                    normalFields.put(field, popFields.get(field));
                }
            }

            RowWrapper rowWrapper = new RowWrapper((String.valueOf(row.get('Id'))));
            rowWrapper.isDeleted = false;

            //this for loop ONLY GOES THROUGH NONE CHILD FIELDS
            for (FieldWrapper columnMetaData: rows.getFieldMetaData())
            {
                if (normalFields.keySet().contains(columnMetaData.name.substringBefore('.')))
                {
                    HelperSchema.FieldData fieldData = HelperSchema.getFieldData(row, columnMetaData.name);
    
                    FieldWrapper field = new FieldWrapper(fieldData.label, 
                                                          fieldData.value, 
                                                          fieldData.getType(),
                                                          columnMetaData.name,
                                                          columnMetaData.columnIndex,
                                                          fieldData.parentObjType);

                    field.setIsEditable(fieldData.isEditable);

                    //if field metadata shows its a lookup and the lookup records id is available then set it
                    if (fieldData.objValueId != null)
                    {
                        field.setObjValueId(fieldData.objValueId);
                        field.setFieldObj(fieldData.objValue);
                    } else {
                        field.setObjValueId(rowWrapper.getSalesforceId()); //if this is not a lookup then set its own wrappers SFDC Id
                    }

                    System.debug(LoggingLevel.FINE, 'Field - ' + field);

                    if (ListViewAbstract.validNameColumnNames.contains(field.getName()))  //if the name of the field is in the list identifying a link field
                    {
                        field.createURL();
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
                    else 
                        clonedWrapper.setIsEditable(false); //no cloned wrappers can be editable after the header row.

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
                                                                  fieldData.value, 
                                                                  fieldData.getType(),
                                                                  fieldName,
                                                                  columnMetaData.columnIndex,
                                                                  fieldData.parentObjType);
                            field.longName = columnMetaData.name;

                            if (fieldData.objValueId != null)
                                field.setObjValueId(fieldData.objValueId);
        
                            System.debug(LoggingLevel.FINE, 'Field - ' + field);
        
                            if (ListViewAbstract.validNameColumnNames.contains(fieldData.name)             //if we have the name of the object
                                && fieldData.objValue != null        //if we have field data.
                                && fieldData.value != null)  //if we have a display value
                            {
                                field.setFieldObj(fieldData.objValue);
                                field.createURL();
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
        System.debug(LoggingLevel.DEBUG, 'Ending ListViewCustomManual.handleRowsToWrapper - ' + (System.now().getTime() - startTime));
        return rows;
    }

}