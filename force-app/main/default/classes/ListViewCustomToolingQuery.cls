/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 06-30-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-22-2020   tom.h.ansley@medtronic.com   Initial Version
 * 2.0   06-18-2021   tom.h.ansley@medtronic.com   Updated getListViewData method to use convenience method
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

       System.debug(LoggingLevel.DEBUG, 'BODY - ' + logBody);

     */
    public ListViewCustomToolingQuery()
    {
        super('query');
    }

    public override String getEndPoint(ListViewCustomToolingRequestData requestData)
    {

        String soql = requestData.data.get(DATA_QUERY);

        soql = ListViewHelper.getSOQLQuery(soql, lvConfig, columnSortData, joinField, joinRecordIds);


        String endPoint = URL.getSalesforceBaseUrl().toExternalForm();

        endPoint += '/services/data/v' + HelperREST.getNewestAPIVersion() + '/tooling/query?q=' + EncodingUtil.urlEncode(soql, 'UTF-8');

        System.debug(LoggingLevel.DEBUG, 'Endpoint returned - ' + endPoint);
        return endPoint;
    }

    public override ListViewAbstract.RowsWrapper handleResponse(String responseStr, ListViewCustomToolingRequestData requestData)
    {
        ListViewAbstract.RowsWrapper rows = handleJSONToWrapper(responseStr);

        return rows;
    }

    /*
        * Method to take a JSON string returned from the tooling API and convert the
        * rows into something that front end lightning components can handle.
        */
    private ListViewAbstract.RowsWrapper handleJSONToWrapper(String responseStr)
    {
        System.debug('Starting ListViewCustomToolingQuery.handleJSONToWrapper - ' + System.now().getTime());
        ListViewAbstract.RowsWrapper rows = new ListViewAbstract.RowsWrapper(listView);
        
        //------------------------------------------------------
        //Handle JSON String into list of individual records
        //------------------------------------------------------
        List<Map<String, Object>> logData = new List<Map<String, Object>>();

        Map<String, Object> logs = (Map<String, Object>) JSON.deserializeUntyped(responseStr);
        List<Object> records = (List<Object>) logs.get('records');

        for (Object record: records)
        {
            logData.add((Map<String, Object>) record);
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
        for (Integer count = 0; count < logData.size(); count++)
        {
            Map<String, Object> log = logData.get(count);

            RowWrapper rowWrapper = new RowWrapper((String) log.get('Id'));
            rowWrapper.isDeleted = false;
            rows.addRow(rowWrapper);

            //for each listview column
            columnIndex = 1;
            for (Object column: columns)
            {
                Map<String, Object> columnData = (Map<String, Object>) column;

                String fieldType = (String) columnData.get('type');
                String fieldName = (String) columnData.get('fieldNameOrPath');
                String label     = (String) columnData.get('label');

                System.debug(LoggingLevel.DEBUG, 'Field - ' + fieldName + ', Type - ' + fieldType);

                FieldWrapper field = new FieldWrapper(label, 
                                                    String.valueOf(log.get(fieldName)), 
                                                    fieldType,
                                                    fieldName,
                                                    columnIndex);

                                                    

                if (fieldName == 'Id') {
                    String url = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/setup/ApexDebugLogDetail/page?address=%2Fp%2Fsetup%2Flayout%2FApexDebugLogDetailEdit%2Fd%3Fapex_log_id%3D' + String.valueOf(log.get(fieldName));
                    field.urlTarget = '_blank';
                    field.setURL(url);
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
            && !String.isEmpty(lvConfig.getParameter('TotalColumns').getValue()))
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
                        if (ListViewAbstract.validTotalColumns.contains(totalField.getType()) && !String.isEmpty(fieldWrapper.getValue()))
                        {
                            System.debug(LoggingLevel.DEBUG, 'We have a valid column value to add to total');
                            System.debug(LoggingLevel.DEBUG, 'Old value - ' + totalField.value);
                            if (totalField.getType() == 'currency')
                                totalField.value = String.valueOf(Decimal.valueOf(String.valueOf(fieldWrapper.getValue())) + Decimal.valueOf(totalField.value));
                            else
                                totalField.value = String.valueOf(Decimal.valueOf(fieldWrapper.getValue()) + Decimal.valueOf(totalField.value));
                            System.debug(LoggingLevel.DEBUG, 'New value - ' + totalField.value);

                            
                        }
                    }
                }


            }

        }

        System.debug('Ending ListViewCustomToolingQuery.handleJSONToWrapper - ' + System.now().getTime());
        return rows;
    }

}