@RestResource(urlMapping='/v1/request/*')
global with sharing class WebServiceListViewRequest {

    /*
     * Web service which gets all ListViewAnything list views

     {"parameters":{"valuesMap":"AllOrNone$$true$$$DMLType$$insert","action":"Import:simpli_lv_ent.ListViewActionImportAll:Core:null","recordIds":"001aj00000JB03OAAT,001aj00000JB03QAAT,001aj00000JB03NAAT"},"name":"runAction"}
     {"parameters":{"valuesMap":"AllOrNone$$true$$$DMLType$$insert","action":"Delete:ListViewActionDelete:Core:null","recordIds":"001aj00000JB03OAAT,001aj00000JB03QAAT,001aj00000JB03NAAT"},"name":"runAction"}

        String jsonStr = '{"parameters":{"valuesMap":"AllOrNone$$true$$$DMLType$$insert","action":"Delete:ListViewActionDelete:Core:null","recordIds":"001aj00000JB03OAAT,001aj00000JB03QAAT,001aj00000JB03NAAT"},"name":"runAction"}';
        RestContext.request = new RestRequest();
        RestContext.request.requestBody = Blob.valueOf(jsonStr);
        WebServiceListViewRequest.makeRequest();

     */
    @HttpPost
    global static Response makeRequest()
    {
        System.debug(LoggingLevel.DEBUG, 'WebServiceListViewRequest.makeRequest');

        Response resp = new Response();
        resp.statusCode = 200;

        String requestJSON = RestContext.request.requestBody.toString();

        System.debug(LoggingLevel.DEBUG, 'requestJSON - ' + requestJSON);

        Request request = (Request) JSON.deserialize(requestJSON, Request.class);

        if (request.name == 'getListViewData')
        {
            String query = request.parameters.get('query');
            Set<String> columns = HelperString.getSetFromString(request.parameters.get('columnNames'), ';');
            List<SObject> rows = Database.query(query);

            Data lv = new Data();
            for (SObject row: rows)
            {
                Row r = new Row((String) row.get('Id'));
                
                for (String fieldName: columns)
                {
                    System.debug(LoggingLevel.ERROR, 'fieldName - ' + fieldName);
                    HelperSchema.FieldData fData = HelperSchema.getFieldData(row, fieldName);
                    if (fData != null)
                    {
                        System.debug(LoggingLevel.ERROR, fData.getDebugString());
                        Field f = new Field();
                        f.name = fieldName;
                        f.value = String.valueOf(fData.value);
                        f.type = fData.getType();

                        if (fData.value instanceof DateTime) 
                            f.value = String.valueOf(((DateTime) fData.value).getTime());
                        else
                            f.value = String.valueOf(fData.value);

                        r.addField(f);
                    }
                }

                lv.addRow(r);
            }

            resp.data = lv;
        /*
        } else if (request.name == 'getListViewObjects') {
            List<ListViewController.SelectOption> options = ListViewController.getListViewObjects(request.parameters.get('incObjects'),
                                                                                                  request.parameters.get('excObjects'));
            resp.listViewObjects = options;

        } else if (request.name == 'getObjectListViews') {
            List<ListViewController.SelectOption> options = ListViewController.getObjectListViews(request.parameters.get('objectName'));
            resp.objectListViews = options;
*/
        } else if (request.name == 'runAction') { 
            String response = ListViewActionHelper.processVirtualAction(request.parameters.get('action'), 
                                                                        request.parameters.get('recordIds'), 
                                                                        request.parameters.get('valuesMap'));
            //if we have an error then wrapit in a JSON
            if (response.startsWith(ListViewAction.RESULT_ERROR + ':'))
                response = '{"error":"' + response.removeStart(ListViewAction.RESULT_ERROR + ':') + '"}';
            //response = response.replace('"', '\\"'); //need to encode so that it can be deserialized on the other side
            resp.runActionResponse = '{"response":"' + response + '"}';
        }

        HelperString.debug(resp, 'RESPONSE');
        return resp;
    }

    global class Request {
        global String name {get; set;}
        global Map<String, String> parameters {get; set;}
        global Request() {
            parameters = new Map<String, String>();
        }
    }

    global class Response {
        global Integer statusCode {get; set;}           //the general status of performing the requested operation
        global String errorMessage {get; set;}          //error message if a catastrophic event occurs
        global String runActionResponse {get; set;}     //response from running an action
        global String responseJSON {get; set;}          //NOT USED CURRENTLY
        global Columns columns {get; set;}              //used to hold column data when getting list view data
        global Data data {get; set;}                    //used to hold data when getting list view data.
        global List<ListViewController.SelectOption> objects {get; set;}            //NOT USED CURRENTLY
        global List<ListViewController.SelectOption> objectListViews {get; set;}    //NOT USED CURRENTLY
        global List<ListViewController.SelectOption> listViewObjects {get; set;}    //NOT USED CURRENTLY
    }
    
    private class Columns {
        private List<Column> columns {get; set;}

        private Columns() {
            columns = new List<Column>();
        }

        private void addColumn(Column column) {
            columns.add(column);
        }
    }

    private class Column {
        private String label {get; set;}
        private String columnWidth {get; set;}
        private String name {get; set;}
    }

    private class Data {
        private List<Row> rows {get; set;}

        private Data() {
            rows = new List<Row>();
        }

        private void addRow(Row row) {
            rows.add(row);
        }
    }

    private class Row {
        private String sfdcId {get; set;}
        private List<Field> fields {get; set;}

        private Row(String rowId) {
            fields = new List<Field>();
            this.sfdcId         = rowId;
        }

        private void addField(Field field) {
            fields.add(field);
        }
    }

    private class Field {
        private String name {get; set;}
        private String value {get; set;}
        private String type {get; set;}
    }
}