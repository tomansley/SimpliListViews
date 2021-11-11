/**
 * @description       : Helper class to aid in the handling of DML transactions
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-11-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   09-08-2020   tom@ansleyllc.com   Initial Version
 * 2.0   10-31-2021   tom@ansleyllc.com   Added query() methods.
**/
public with sharing class HelperDatabase {

    /**
    * @description Method that returns a single SObject given the object name and fields as well as the record Id
    * @author tom.h.ansley@medtronic.com | 10-31-2021 
    * @param objAPIName the API name of the object to be returned.
    * @param fieldAPINames the list of field API names to be returned on the SObject
    * @param recordId unique record Id identifying the record to be returned.
    * @return SObject the populated SObject or null if the record could not be found.
    **/
    public static SObject query(String objAPIName, List<String> fieldAPINames, String recordId)
    {
        System.debug(LoggingLevel.DEBUG, 'Calling query(' + objAPIName + ',' + fieldAPINames + ',' + recordId + ')');
        SObject result = null;
        List<String> recordIds = new List<String>{ recordId };
        List<SObject> records = query(objAPIName, fieldAPINames, recordIds);
        if (!records.isEmpty())
            result = records[0];

        return result;
    }

    /**
    * @description Method that returns a list of SObjects given the objects name and fields as well as the record Ids
    * @author tom.h.ansley@medtronic.com | 10-31-2021 
    * @param objAPIName the API name of the objects to be returned.
    * @param fieldAPINames the list of field API names to be returned on the SObjects
    * @param recordId the unique record Ids identifying the records to be returned.
    * @return List<SObject> the populated SObjects or an empty list if the records could not be found.
    **/
    public static List<SObject> query(String objAPIName, List<String> fieldAPINames, List<String> recordIds)
    {
        if (String.isEmpty(objAPIName)) throw new ListViewException('An object API name must be provided when using HelperDatabase.query() methods.');
        if (fieldAPINames.isEmpty()) throw new ListViewException('At least one field must be provided when using HelperDatabase.query() methods.');
        if (recordIds.isEmpty()) throw new ListViewException('At least one record Id must be provided when using HelperDatabase.query() methods.');

        String soql = 'SELECT ';
        for (String fieldName: fieldAPINames)
            soql += fieldName + ', ';
        soql = soql.removeEnd(', ');
        soql += ' FROM ' + objAPIName;
        soql += ' WHERE Id IN (';
        for (String recordId: recordIds)
            soql += '\'' + recordId + '\'' + ',';
        soql = soql.removeEnd(',') + ')';

        System.debug(Logginglevel.DEBUG, 'SOQL - ' + soql);

        List<SObject> results = Database.query(soql);

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, results);
        return dec.getRecords();
    }

    //--------------------------------------------------------------------------------------------------------------------------
    // INSERT
    //--------------------------------------------------------------------------------------------------------------------------

    public static void insertRecord(SObject data, String objAPIName) 
    {
        List<SObject> records = new List<SObject>();
        records.add(data);

        insertRecords(records, objAPIName);
    }

    public static void insertRecords(List<SObject> data, String objAPIName) 
    {
        insertRecords(data, objAPIName, true); 
    }

    public static void insertRecords(List<SObject> data, String objAPIName, Boolean allOrNone) 
    {
        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.CREATABLE, data);

        Database.insert(dec.getRecords(), allOrNone);
    }

    //--------------------------------------------------------------------------------------------------------------------------
    // UPDATE
    //--------------------------------------------------------------------------------------------------------------------------

    public static void updateRecord(SObject data, String objAPIName) 
    {
        List<SObject> records = new List<SObject>();
        records.add(data);

        updateRecords(records, objAPIName);
        
    }

    public static void updateRecords(List<SObject> data, String objAPIName) 
    {
        updateRecords(data, objAPIName, true); 
    }

    public static void updateRecords(List<SObject> data, String objAPIName, Boolean allOrNone) 
    {
        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.UPDATABLE, data);

        Database.update(dec.getRecords(), allOrNone);
    }


    //--------------------------------------------------------------------------------------------------------------------------
    // UPSERT
    //--------------------------------------------------------------------------------------------------------------------------

    public static void upsertRecord(SObject data, String objAPIName) 
    {
        List<SObject> records = new List<SObject>();
        records.add(data);

        upsertRecords(records, objAPIName);
    }

    public static void upsertRecord(SObject data, String objAPIName, String externalIdField) 
    {
        List<SObject> records = new List<SObject>();
        records.add(data);

        upsertRecords(records, objAPIName, externalIdField, true);
        
    }

    public static void upsertRecords(List<SObject> data, String objAPIName) 
    {
        upsertRecords(data, objAPIName, null, true); 
    }

    public static void upsertRecords(List<SObject> data, String objAPIName, String externalIdField, Boolean allOrNone) 
    {

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.UPSERTABLE, data);

        if (externalIdField != null)
        {
            Schema.SObjectField field = HelperSchema.getFieldSchema(objAPIName, externalIdField);
            Database.upsert(dec.getRecords(), field, allOrNone);
        } else 
            Database.upsert(dec.getRecords(), allOrNone);
        
    }

    //--------------------------------------------------------------------------------------------------------------------------
    // DELETE
    //--------------------------------------------------------------------------------------------------------------------------

    public static void deleteRecords(List<SObject> data, String objAPIName) 
    {

        deleteRecords(data, objAPIName, true); 
    }

    public static void deleteRecords(List<SObject> data, String objAPIName, Boolean allOrNone) 
    {

        HelperSchema.checkObjectPermissions(objAPIName, HelperSchema.DELETABLE);

        Database.delete(data, allOrNone);
    }

    public static void deleteRecord(SObject data, String objAPIName) 
    {
        List<SObject> records = new List<SObject>();
        records.add(data);

        deleteRecords(records, objAPIName);
    }

}