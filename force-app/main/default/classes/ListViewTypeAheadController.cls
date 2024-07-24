public with sharing class ListViewTypeAheadController {
    
    private static final String TYPE_SOBJ   = 'sobject';
    private static final String TYPE_META   = 'meta';
    private static final String TYPE_SCHEMA = 'schema';

    private static final String SCHEMA_SOBJ = 'SObject';

    @AuraEnabled(cacheable=true)
    public static List<ListViewController.SelectOption> search(String searchType, String searchTerm, String objName, String labelFieldName, String keyFieldName, String whereClauseJSON) 
    {
        System.debug(LoggingLevel.DEBUG, 'Starting search(' + searchType + ', ' + searchTerm + ', ' + objName + ', ' + labelFieldName + ', ' + keyFieldName + ', ' + whereClauseJSON + ')');
        if (searchTerm == null) searchTerm = '';
        searchTerm = searchTerm.toLowerCase();

        List<ListViewController.SelectOption> options = new List<ListViewController.SelectOption>();

        if (searchType == TYPE_SOBJ)
        {
            String soql = null;

            if(searchTerm == ''){
                if (String.isBlank(whereClauseJSON)) {
                    soql = 'SELECT Id, ' + String.escapeSingleQuotes(labelFieldName) + ', ' + String.escapeSingleQuotes(keyFieldName) + ' FROM ' + String.escapeSingleQuotes(objName) + ' LIMIT 100'; 
                } else {
                    WhereClause clause = (WhereClause) JSON.deserialize(whereClauseJSON, WhereClause.class);
                    String whereStatement = clause.getWhereClause();
                    soql = 'SELECT Id, ' + String.escapeSingleQuotes(labelFieldName) + ', ' + String.escapeSingleQuotes(keyFieldName) + ' FROM ' + String.escapeSingleQuotes(objName) + ' WHERE ' + whereStatement + ' LIMIT 100'; 
                }
            }
            else {
                if (String.isBlank(whereClauseJSON)) {
                    soql = 'SELECT Id, ' + String.escapeSingleQuotes(labelFieldName) + ', ' + String.escapeSingleQuotes(keyFieldName) + ' FROM ' + String.escapeSingleQuotes(objName) + ' WHERE ' + String.escapeSingleQuotes(labelFieldName) + ' LIKE  \'%' + String.escapeSingleQuotes(searchTerm) + '%\' LIMIT 100';
                } else {
                    WhereClause clause = (WhereClause) JSON.deserialize(whereClauseJSON, WhereClause.class);
                    String whereStatement = clause.getWhereClause();
                    soql = 'SELECT Id, ' + String.escapeSingleQuotes(labelFieldName) + ', ' + String.escapeSingleQuotes(keyFieldName) + ' FROM ' + String.escapeSingleQuotes(objName) + ' WHERE ' + whereStatement + ' AND ' + String.escapeSingleQuotes(labelFieldName) + ' LIKE  \'%' + String.escapeSingleQuotes(searchTerm) + '%\' LIMIT 100';
                }
            }
            
            System.debug(LoggingLevel.DEBUG, 'SOQL - ' + soql);
            SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, database.query(soql));
            List<SObject> recordList = dec.getRecords();

            for (SObject record : recordList)
                options.add(new ListViewController.SelectOption(record.get(keyFieldName).toString(), record.get(labelFieldName).toString()));         
        
        } else if (searchType == TYPE_SCHEMA)
        {
            
            //searching for SObjects
            if (objName == SCHEMA_SOBJ)
            {
                Map<String, String> objMap = HelperSchema.getAllObjectNames();

                Boolean hasWhereClause = String.isBlank(whereClauseJSON) ? false : true;
                Boolean isInc = null;
                Set<String> objs =  null;

                if (hasWhereClause)
                {
                    WhereClause clause = (WhereClause) JSON.deserialize(whereClauseJSON, WhereClause.class);
                    String whereStatement = clause.getWhereClause();

                    if (clause.operator == 'NOT IN')
                        isInc = false;
                    else 
                        isInc = true;

                    objs = clause.getValuesList();
                }

                for (String apiName : objMap.keySet())
                {
                    if (!hasWhereClause || (hasWhereClause 
                    && ((isInc && objs.contains(apiName.toLowerCase()))
                        || (!isInc && !objs.contains(apiName.toLowerCase())))))
                    {
                        String label = objMap.get(apiName);
                        if (searchTerm == '')                        
                            options.add(new ListViewController.SelectOption(apiName, label));
                        else if (label.toLowerCase().contains(searchTerm))
                            options.add(new ListViewController.SelectOption(apiName, label));         
                    }

                    if (options.size() > 30) break;
                }
            //searching for fields within an SObject
            } else {

            } 
        }

        options.sort();

        ListViewErrorHelper.processLogs(true);

        return options;
    }

    @AuraEnabled
    public static String getRecordName(String selectedId, String objName, String labelFieldName){
        
        String soql = 'SELECT Id, ' + String.escapeSingleQuotes(labelFieldName) + ' FROM ' + String.escapeSingleQuotes(objName) + ' WHERE Id = \'' + String.escapeSingleQuotes(selectedId) + '\'';

        return (String) Database.query(soql)[0].get(String.escapeSingleQuotes(labelFieldName));
    }

    public class WhereClause {

        public String field {get; set;}
        public String operator {get; set;}
        public String values {get; set;}

        public String getWhereClause()
        {
            String response = '';
            values = String.escapeSingleQuotes(values);
            values = values.replace('"', '\'');

            if (operator == 'IN' || operator == 'NOT IN') {
                response = String.escapeSingleQuotes(field) + ' ' + String.escapeSingleQuotes(operator) + ' [' + values + ']';
            } else {
                response = String.escapeSingleQuotes(field) + ' ' + String.escapeSingleQuotes(operator) + ' \'' + values + '\'';
            }
            return response;
        }

        public Set<String> getValuesList()
        {
            values = values.remove('"');
            return HelperString.getSetFromString(values, ',', true);

        }
    }
}