/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-23-2020   tom@ansleyllc.com   Initial Version
 * 2.0   06-18-2021   tom@ansleyllc.com   Added offset to allow for larger datasets
 * 3.0   08-18-2021   tom@ansleyllc.com   Updated strings to static final variables
**/
public with sharing class ListViewCustomManualSObjects extends ListViewCustomManualAbstract {

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
        
        return params;
    }

    public override RowsWrapper getData()
    {
        //List<SObject> dataRows = ListViewHelper.getListViewData(listview.Core_ListView_Query__c, lvConfig, columnSortData, joinField, joinRecordIds, offset);

        Map<String,Schema.SobjectType> dataRows = HelperSchema.getAllObjectsByName();

        RowsWrapper rowData = handleRowsToWrapper(dataRows, listView, lvConfig, columnSortData);

        return rowData;
    }

    public override List<ListViewColumn> getColumnData()
    {
        SObject exampleRow = null;   

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

        return listViewColumns;
    }


    /*
        * Method to take a list of schema objects and convert the
        * rows into something that front end lightning components can handle.
        */
    private static ListViewAbstract.RowsWrapper handleRowsToWrapper(Map<String,Schema.SobjectType> dataRows, List_View__c listView, 
                                                                    ListViewConfigWrapper lvConfig,
                                                                    List<ListViewHelper.ColumnSortData> sortData)
    {
        Long startTime = System.now().getTime();
        System.debug(LoggingLevel.FINE, 'Starting ListViewCustomManualSObjects.handleRowsToWrapper');

        Map<String, ListViewHelper.ColumnSortData> sortDataByFieldName = new Map<String, ListViewHelper.ColumnSortData>();
        for (ListViewHelper.ColumnSortData columnData: sortData)
            sortDataByFieldName.put(columnData.fieldName, columnData);

        ListViewAbstract.RowsWrapper rows = new ListViewAbstract.RowsWrapper(listView);
        
        //get all columns from the list view
        List<Object> allColumns = (List<Object>) JSON.deserializeUntyped(listView.Core_ListView_Columns__c);
        List<Object> columns = new List<Object>();
        Boolean addColumn = true;

        //set the COLUMN meta data into the rows wrapper
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
        for (String objName: dataRows.keySet())
        {
            Schema.SobjectType row = dataRows.get(objName);
            System.debug(LoggingLevel.FINE, 'Schema.SobjectType label - ' + row.getDescribe().getLabel());
            
            RowWrapper rowWrapper = new RowWrapper(row.getDescribe().getKeyPrefix());
            rowWrapper.isDeleted = false;

            for (FieldWrapper columnMetaData: rows.getFieldMetaData())
            {
                HelperSchema.FieldData fieldData = getFieldData(row.getDescribe(), columnMetaData.name);

                FieldWrapper field = new FieldWrapper(fieldData.label, 
                                                        fieldData.value, 
                                                        fieldData.type.name(),
                                                        columnMetaData.name,
                                                        columnMetaData.columnIndex,
                                                        fieldData.parentObjType);

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
            
            rows.addRow(rowWrapper);

            if (lvConfig != null)
                rowWrapper.calculateHighlighting(lvConfig.conditions);
        }

        System.debug(LoggingLevel.DEBUG, rows.getDebugString());
        System.debug(LoggingLevel.DEBUG, 'Ending ListViewCustomManualSObjects.handleRowsToWrapper - ' + (System.now().getTime() - startTime));
        return rows;
    }

    private static HelperSchema.FieldData getFieldData(Schema.DescribeSObjectResult row, String fieldName)
    {
        HelperSchema.FieldData field = null;
        if (fieldName == 'Prefix')
            field = new HelperSchema.FieldData('Prefix', 'Prefix', Schema.DisplayType.STRING, row.getKeyPrefix(), null);
        else if (fieldName == 'Label')
            field = new HelperSchema.FieldData('Label', 'Label', Schema.DisplayType.STRING, row.getLabel(), null);
        else if (fieldName == 'LabelPlural')
            field = new HelperSchema.FieldData('LabelPlural', 'LabelPlural', Schema.DisplayType.STRING, row.getLabelPlural(), null);
        else if (fieldName == 'LocalName')
            field = new HelperSchema.FieldData('LocalName', 'LocalName', Schema.DisplayType.STRING, row.getLocalName(), null);
        else if (fieldName == 'Name')
            field = new HelperSchema.FieldData('Name', 'Name', Schema.DisplayType.STRING, row.getName(), null);
        else if (fieldName == 'IsAccessible')
            field = new HelperSchema.FieldData('IsAccessible', 'IsAccessible', Schema.DisplayType.BOOLEAN, row.isAccessible(), null);
        else if (fieldName == 'Prefix')
            field = new HelperSchema.FieldData('Prefix', 'Prefix', Schema.DisplayType.STRING, row.getKeyPrefix(), null);
        else if (fieldName == 'Prefix')
            field = new HelperSchema.FieldData('Prefix', 'Prefix', Schema.DisplayType.STRING, row.getKeyPrefix(), null);
        else if (fieldName == 'Prefix')
            field = new HelperSchema.FieldData('Prefix', 'Prefix', Schema.DisplayType.STRING, row.getKeyPrefix(), null);
        else if (fieldName == 'Prefix')
            field = new HelperSchema.FieldData('Prefix', 'Prefix', Schema.DisplayType.STRING, row.getKeyPrefix(), null);
        else if (fieldName == 'Prefix')
            field = new HelperSchema.FieldData('Prefix', 'Prefix', Schema.DisplayType.STRING, row.getKeyPrefix(), null);
        else if (fieldName == 'Prefix')
            field = new HelperSchema.FieldData('Prefix', 'Prefix', Schema.DisplayType.STRING, row.getKeyPrefix(), null);
        return field;
    }

}