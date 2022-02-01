/*
 * Utility class to run batch jobs against a set of records. The processing must be simple. The class should typically be used for system administrative tasks.
 * Note that currently this class does not allow fields to be set on update.
 *
 * Example uses of the class might include - 
 *
 *     1. All/Some records in a table need to be "touched" to have a trigger run against them to update information.
 *     2. All/Some records in a table need to be deleted.
 *
 * There are currently 4 variables that can or need to be passed into the class constructor
 *
 *     "Object Type"    : The Apex API class name of the table that is to be processed. i.e. Account
 *     "Operation"      : The operation being performed when running the batch job. i.e. update or delete
 *     "Batch Size"     : The number of records per batch that should be processed at a time. If no batch size is provided it is defaulted to 200.
 *     "SOQL Statement" : A SOQL statement identifying the criteria and object type if more complex logic is required to find the records to process.
 *
 * Example anonymous code blocks for how to run the class are as follows -
 *
 * Example 1 - Delete all contacts with a batch size of 100
 *      
 *     Map<String, Object> vars = new Map<String, Object>();
 *     vars.put(HelperBatch.VAR_OBJECT_TYPE, 'Contact');
 *     vars.put(HelperBatch.VAR_BATCH_SIZE, 100);
 *     vars.put(HelperBatch.VAR_OPERATION, HelperBatch.OPER_DELETE);
 *
 *     HelperBatch job = new HelperBatch(vars);
 *     job.execute(null);
 *
 * Example 2 - Touch all Event records that do not have an internal organizationDelete with a batch size of 40
 *      
 *     Map<String, Object> vars = new Map<String, Object>();
 *     vars.put(HelperBatch.VAR_SOQL_STATEMENT, 'SELECT Id FROM Event WHERE Internal_Organization__c = null');
 *     vars.put(HelperBatch.VAR_BATCH_SIZE, 40);
 *     vars.put(HelperBatch.VAR_OPERATION, HelperBatch.OPER_UPDATE);
 *
 *     HelperBatch job = new HelperBatch(vars);
 *     job.execute(null);
 *
 */
public with sharing class HelperBatch implements Database.AllowsCallouts, Database.Batchable<SObject>,Database.Stateful, Schedulable {

    public static final String OPER_UPDATE = 'update';
    public static final String OPER_DELETE = 'delete';
    public static final String OPER_INSERT = 'insert';

    private String query = 'SELECT Id FROM $$SObjectType$$'; //the query used to retrieve data for each batch job.
    private String debug = null; //holds debugging inforamtion during processing
    private String sObjType = null; //the SObject type that will be processed. This is the API name of the custom object
    private Integer batchSize = 200; //the number of records processed per batch
    private String operation = OPER_UPDATE; //the operation that is being performed on the records
    private Boolean hardDelete = false; //determine whether we should delete records from recycle bin.
    private Map < String, Object > fieldValues = new Map < String, Object > (); //API field names and their corresponding values that will be updated in all processed records.

    public static final String VAR_OBJECT_TYPE = 'Object Type';
    public static final String VAR_SOQL_STATEMENT = 'SOQL Statement';
    public static final String VAR_BATCH_SIZE = 'Batch Size';
    public static final String VAR_OPERATION = 'Operation';
    public static final String VAR_FIELD_UPDATES = 'Field Updates';
    public static final String VAR_HARD_DELETE = 'Hard Delete';


    public HelperBatch() {}

    public HelperBatch(Map < String, Object > vars) 
    {
        setVariables(vars);
    }

    public void setVariables(Map < String, Object > vars) 
    {
        for (String key: vars.keySet()) 
        {
            if (key == VAR_OBJECT_TYPE)
                sObjType = (String) vars.get(key);
            else if (key == VAR_SOQL_STATEMENT)
                query = (String) vars.get(key);
            else if (key == VAR_BATCH_SIZE)
                batchSize = (Integer) vars.get(key);
            else if (key == VAR_OPERATION)
                operation = (String) vars.get(key);
            else if (key == VAR_FIELD_UPDATES)
                fieldValues = (Map < String, Object > ) vars.get(key);
            else if (key == VAR_HARD_DELETE)
                hardDelete = (Boolean) vars.get(key);
        }
    }

    /* IMPLEMENTS SCHEDULABLE INTERFACE */
    public void execute(SchedulableContext sc) 
    {
        database.executebatch(this, batchSize);
    }

    /* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
    public Database.QueryLocator start(Database.BatchableContext BC) 
    {
        if (sObjType != null)
            query = query.replace('$$SObjectType$$', sObjType);

        System.debug(LoggingLevel.DEBUG, 'SOQL Statement - ' + query);

        return Database.getQueryLocator(query);
    }

    /* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
    public void execute(Database.BatchableContext BC, List < SObject > scope) 
    {

        debug = '\n\n---------------------------------------------------------------------------------\n';
        debug += ' Batch Size     - ' + scope.size() + '\n';
        debug += ' SObject Type   - ' + sObjType + '\n';
        debug += ' SOQL Statement - ' + query + '\n\n';
        debug += ' Operation      - ' + operation + '\n\n';

        if (operation == OPER_INSERT) 
        {

            Database.SaveResult[] saveResults = Database.insert(scope, false);

            for (Database.SaveResult sr: saveResults) {
                if (!sr.isSuccess()) debug += 'Insert failed - ' + sr.getErrors()[0] + ' - ' + sr.getErrors()[0].getFields() + '\n';
            }

        } else if (operation == OPER_UPDATE) {

            //set field values if there are any
            if (fieldValues.size() > 0) {
                //for all records being processed
                for (SObject record: scope) {
                    //for all fields that need to be set
                    for (String field: fieldValues.keySet())
                        record.put(field, fieldValues.get(field));
                }
            }

            Database.SaveResult[] saveResults = Database.update(scope, false);

            for (Database.SaveResult sr: saveResults) {
                if (!sr.isSuccess()) debug += 'Update failed - ' + sr.getErrors()[0] + ' - ' + sr.getErrors()[0].getFields() + '\n';
            }


        } else if (operation == OPER_DELETE) {

            Database.DeleteResult[] deleteResults = Database.delete(scope, false);
            for (Database.DeleteResult dr: deleteResults) {
                if (!dr.isSuccess()) debug += 'Update failed - ' + dr.getErrors()[0] + ' - ' + dr.getErrors()[0].getFields() + '\n';
            }

        }

        if (hardDelete) 
        {
            Database.emptyRecycleBin(scope);
        }

        debug += '---------------------------------------------------------------------------------\n\n';
        System.debug(LoggingLevel.DEBUG, debug);

    }

    /* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
    public void finish(Database.BatchableContext BC) {}

}