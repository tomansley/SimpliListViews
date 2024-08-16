/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 08-14-2024
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   10-22-2020   tom@ansleyllc.com   Initial Version
 * 2.0   06-18-2021   tom@ansleyllc.com   Updated getListViewData method to use convenience method
 * 3.0   08-18-2021   tom@ansleyllc.com   Updated strings to static final variables
**/
public with sharing class ListViewCustomToolingQuery extends ListViewCustomToolingAbstract 
{
    
    public static final String DATA_QUERY = 'query';
    public static final String DATA_ROW_SIZE = 'rowsize';
    public static final String DATA_SOBJECT = 'sobject';
    public static final String DATA_ID = 'id';
    public static final String DATA_OBJ_FIELD = 'objfield';

    /*
       ListViewCustomToolingQuery request = new ListViewCustomToolingQuery('tooling', 'query');
       request.setRequestData('query', 'SELECT Application,DurationMilliseconds,Id,Location,LogLength,LogUserId,Operation,Request,StartTime,Status FROM ApexLog ORDER BY StartTime DESC LIMIT 300');
       ListViewToolingAbstract.ListViewToolingResponseData response = request.processRequest();
       Map<String, Map<String, Object>> logsById = (Map<String, Map<String, Object>>) response.responseData;

       ListViewCustomToolingQuery request2 = new ListViewCustomToolingQuery('rest', 'get');
       request2.setRequestData('id', new List<String>(logsById.keySet())[0]);
       request2.setRequestData('objfield', 'Body');
       response = request2.processRequest();
       String logBody = (String) response.responseData;

       System.debug(LoggingLevel.FINE, 'BODY - ' + logBody);

     */
    public ListViewCustomToolingQuery()
    {
        super('query');
    }

    public override String getEndPoint(ListViewCustomToolingRequestData requestData)
    {

        String soql = requestData.data.get(DATA_QUERY);

        soql = ListViewHelper.getCustomListViewQuery(soql, lvConfig, columnSortData, joinField, joinRecordIds);


        String endPoint = URL.getSalesforceBaseUrl().toExternalForm();

        endPoint += '/services/data/v' + HelperREST.getNewestAPIVersion() + '/tooling/query?q=' + EncodingUtil.urlEncode(soql, 'UTF-8');

        System.debug(LoggingLevel.FINE, 'Endpoint returned - ' + endPoint);
        return endPoint;
    }

    public override ListViewAbstract.RowsWrapper handleResponse(String responseStr, ListViewCustomToolingRequestData requestData)
    {
        ListViewAbstract.RowsWrapper rows = handleJSONToWrapper(responseStr);

        return rows;
    }

    public override List<ListViewColumn> getColumnData()
    {

        List<ListViewColumn> listViewColumns = new List<ListViewColumn>();

        //get all columns from the list view
        List<Object> allColumns = (List<Object>) JSON.deserializeUntyped(listView.Core_ListView_Columns__c);

        //get the CORE SFDC COLUMN meta data
        for (Object column: allColumns)
        {
            Map<String, Object> columnData = (Map<String, Object>) column;

            String fieldName = (String) columnData.get('fieldNameOrPath');
            Boolean hidden   = (Boolean) columnData.get('hidden');
            String label     = (String) columnData.get('label');
            String type      = (String) columnData.get('type');

            if (hidden == null || !hidden)
            {
                listViewColumns.add(new ListViewColumn(label, fieldName, type));
            }
            
        }

        return listViewColumns;
    }

    /*
        * Method to take a JSON string returned from the tooling API and convert the
        * rows into something that front end lightning components can handle.
        */
    private ListViewAbstract.RowsWrapper handleJSONToWrapper(String responseStr)
    {
        System.debug(LoggingLevel.FINE, 'Starting ListViewCustomToolingQuery.handleJSONToWrapper - ' + System.now().getTime() + ', Response - ' + responseStr);
        ListViewAbstract.RowsWrapper rows = new ListViewAbstract.RowsWrapper(listView, lvConfig);
        
        //------------------------------------------------------
        //Handle JSON String into list of individual records
        //------------------------------------------------------
        List<Map<String, Object>> apiData = new List<Map<String, Object>>();
        //Map<String, Object> response = null;
        
        Object response = JSON.deserializeUntyped(responseStr);

        //if we get a map back there was no error
        if (response instanceof Map<String, Object>)
        {
            List<Object> records = (List<Object>) ((Map<String, Object>) response).get('records');

            for (Object record: records)
            {
                apiData.add((Map<String, Object>) record);
            }

            //------------------------------------------------------
            //Handle sorting
            //------------------------------------------------------
            Map<String, ListViewHelper.ColumnSortData> sortDataByFieldName = new Map<String, ListViewHelper.ColumnSortData>();
            for (ListViewHelper.ColumnSortData columnData: columnSortData)
                sortDataByFieldName.put(columnData.fieldName, columnData);

            //get all columns from the list view
            List<Object> allColumns = (List<Object>) JSON.deserializeUntyped(listView.Core_ListView_Columns__c);
            List<Object> columns = new List<Object>();
            Boolean addColumn = true;

            //------------------------------------------------------
            //Handle columns
            //------------------------------------------------------
            Integer columnIndex = 1;
            for (Object column: allColumns)
            {
                Map<String, Object> columnData = (Map<String, Object>) column;

                String fieldName = (String) columnData.get('fieldNameOrPath');

                FieldWrapper field = new FieldWrapper((String) columnData.get('label'), 
                                                        (String) columnData.get('type'),
                                                        fieldName,
                                                        columnIndex);

                if (columnData.containsKey('function'))
                    field.setFunction((String) columnData.get('function'));

                if (sortDataByFieldName.containsKey(fieldName))
                {
                    field.sortIndex = String.valueOf(sortDataByFieldName.get(fieldName).sortIndex);
                    field.sortDir   = sortDataByFieldName.get(fieldName).sortDirection;
                }

                rows.addFieldMetaData(field);

                columns.add(column);
                columnIndex++;
            }

            //for each row of data
            for (Integer count = 0; count < apiData.size(); count++)
            {
                Map<String, Object> data = apiData.get(count);

                RowWrapper rowWrapper = new RowWrapper((String) data.get('Id'));
                rowWrapper.isDeleted = false;
                rows.addRow(rowWrapper);

                //for each listview column
                columnIndex = 1;
                for (Object column: columns)
                {
                    Map<String, Object> columnData = (Map<String, Object>) column;

                    String fieldType    = (String) columnData.get('type');
                    String fieldName    = (String) columnData.get('fieldNameOrPath');
                    String label        = (String) columnData.get('label');
                    String function     = (String) columnData.get('function');

                    System.debug(LoggingLevel.FINE, 'Field - ' + fieldName + ', Type - ' + fieldType);

                    //get the value of the field
                    HelperSchema.FieldData fieldData = HelperSchema.getFieldData(data, fieldName, this.lvConfig.getObject());

                    //we need to turn the value into its correct class.
                    Object fieldValue = fieldData.value;
                    System.debug(LoggingLevel.FINE, 'FIELD VALUE --- ' + fieldValue);
                    if (fieldValue instanceof String) 
                        fieldValue = ListViewHelper.getObjectForValue(fieldType, (String) fieldValue);
                    System.debug(LoggingLevel.FINE, 'NEW FIELD VALUE --- ' + fieldValue);

                    FieldWrapper field = new FieldWrapper(label,
                                                        fieldValue, 
                                                        fieldType,
                                                        fieldName,
                                                        columnIndex,
                                                        fieldData.parentObjType);
                    field.objValueId = fieldData.objValueId;
                    field.setFunction(function);

                    if (field.getName() == 'Name' || field.getName() == 'Id' || field.getType() == ListViewHelper.TYPE_LOOKUP) {
                        field.createURL();
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
                && lvConfig.getParameter(ListViewHelper.PARAM_TOTAL_COLUMNS) != null 
                && !String.isEmpty(lvConfig.getParameter(ListViewHelper.PARAM_TOTAL_COLUMNS).getValue()))
            {

                rows.hasTotalsRow = true;

                System.debug(LoggingLevel.FINE, 'Starting total column calculations!');

                String totalColumns = lvConfig.getParameter(ListViewHelper.PARAM_TOTAL_COLUMNS).getValue();

                System.debug(LoggingLevel.FINE, 'TotalColumns - ' + totalColumns);

                RowWrapper totalWrapper = new RowWrapper('000000000000000000');
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

                            //for any VALID calculation columns
                            if (ListViewAbstract.validTotalColumns.contains(fieldWrapper.getType())
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
                            totalField.setFunction(fieldWrapper.getFunction());

                            System.debug(LoggingLevel.FINE, 'Added total field - ' + totalField);

                            totalWrapper.addField(totalField);
                        }

                        //see if the field is a column to be totalled
                        if (totalColumns != null && totalColumns.contains(fieldWrapper.getName()))
                        {
                            System.debug(LoggingLevel.FINE, 'Found a column to total - ' + fieldWrapper.getName());

                            System.debug(LoggingLevel.FINE, 'fieldWrapper.getValue() - ' + fieldWrapper.getValue());
                            System.debug(LoggingLevel.FINE, 'fieldWrapper.getType() - ' + fieldWrapper.getType());
                            System.debug(LoggingLevel.FINE, 'totalField.value - ' + totalField.getValue());
                            System.debug(LoggingLevel.FINE, 'totalField.getType() - ' + totalField.getType());

                            //if this is a valid column for total calculation and there is a value to calculate
                            if (ListViewAbstract.validTotalColumns.contains(totalField.getType()) && !String.isEmpty(fieldWrapper.getValue()))
                            {
                                System.debug(LoggingLevel.FINE, 'We have a valid column value to add to total');
                                System.debug(LoggingLevel.FINE, 'Old value - ' + totalField.getValue());
                                if (totalField.getType() == ListViewHelper.TYPE_CURRENCY)
                                    totalField.setValue(Decimal.valueOf(String.valueOf(fieldWrapper.getValue())) + Decimal.valueOf(totalField.getValue()));
                                else
                                    totalField.setValue(Decimal.valueOf(fieldWrapper.getValue()) + Decimal.valueOf(totalField.getValue()));
                                System.debug(LoggingLevel.FINE, 'New value - ' + totalField.getValue());

                                
                            }
                        }
                    }


                }

            }

        //we had an issue with the request so it returns a list instead of a map
        } else {

            Map<String, Object> errors = (Map<String, Object>) ((List<Object>) response)[0];
            String errorCode = '';
            String message = '';
            for (String responseKey: errors.keySet())
            {
                if (responseKey == 'errorCode')
                    errorCode = (String) errors.get(responseKey);
                else if (responseKey == 'message')
                    message = (String) errors.get(responseKey);
            }
            throw new ListViewException(errorCode + ' - ' + message);

        }

        rows.queryString = ListViewHelper.LATEST_QUERY; //put the query used to get the data into the wrapper for use on the front end (debugging)

        System.debug(LoggingLevel.DEBUG, 'Ending ListViewCustomToolingQuery.handleJSONToWrapper - ' + System.now().getTime());
        return rows;
    }

}