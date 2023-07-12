public with sharing class ListViewTypeAheadController {
    
    @AuraEnabled(cacheable=true)
    public static List<ListViewController.SelectOption> search(String searchTerm, String objName, String labelFieldName, String keyFieldName, String whereClause) {
        String soql = null;

        if(searchTerm == null || searchTerm == ''){
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

        List<ListViewController.SelectOption> options = new List<ListViewController.SelectOption>();

        for (SObject record : recordList)
            options.add(new ListViewController.SelectOption(record.get(keyFieldName).toString(), record.get(labelFieldName).toString()));         

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