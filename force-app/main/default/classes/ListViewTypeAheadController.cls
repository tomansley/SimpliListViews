public with sharing class ListViewTypeAheadController {
    
    private static final String TYPE_SOBJ   = 'sobject';
    private static final String TYPE_META   = 'meta';
    private static final String TYPE_SCHEMA = 'schema';

    private static final String SCHEMA_SOBJ = 'SObject';

    @AuraEnabled(cacheable=true)
    public static List<ListViewController.SelectOption> search(String searchType, String searchTerm, String objName, String labelFieldName, String keyFieldName, String whereClause) 
    {
        if (searchTerm == null) searchTerm = '';
        searchTerm = searchTerm.toLowerCase();

        List<ListViewController.SelectOption> options = new List<ListViewController.SelectOption>();

        if (searchType == TYPE_SOBJ)
        {
            String soql = null;

            if(searchTerm == ''){
                if (String.isBlank(whereClause)) {
                    soql = 'SELECT Id, ' + String.escapeSingleQuotes(labelFieldName) + ', ' + String.escapeSingleQuotes(keyFieldName) + ' FROM ' + String.escapeSingleQuotes(objName) + ' LIMIT 100'; 
                } else {
                    soql = 'SELECT Id, ' + String.escapeSingleQuotes(labelFieldName) + ', ' + String.escapeSingleQuotes(keyFieldName) + ' FROM ' + String.escapeSingleQuotes(objName) + ' WHERE ' + whereClause + ' LIMIT 100'; 
                }
            }
            else {
                if (String.isBlank(whereClause)) {
                    soql = 'SELECT Id, ' + String.escapeSingleQuotes(labelFieldName) + ', ' + String.escapeSingleQuotes(keyFieldName) + ' FROM ' + String.escapeSingleQuotes(objName) + ' WHERE ' + labelFieldName + ' LIKE  \'%' + String.escapeSingleQuotes(searchTerm) + '%\' LIMIT 100';
                } else {
                soql = 'SELECT Id, ' + String.escapeSingleQuotes(labelFieldName) + ', ' + String.escapeSingleQuotes(keyFieldName) + ' FROM ' + String.escapeSingleQuotes(objName) + ' WHERE ' + whereClause + ' AND ' + labelFieldName + ' LIKE  \'%' + String.escapeSingleQuotes(searchTerm) + '%\' LIMIT 100';
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

                for (String apiName : objMap.keySet())
                {
                    String label = objMap.get(apiName);
                    if (searchTerm == '')
                        options.add(new ListViewController.SelectOption(apiName, label));         
                    else if (label.toLowerCase().contains(searchTerm))
                        options.add(new ListViewController.SelectOption(apiName, label));         

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

}