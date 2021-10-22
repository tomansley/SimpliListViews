/**
 * @description       : Helper class to aid in the handling of DML transactions
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   09-08-2020   tom@ansleyllc.com   Initial Version
**/
public with sharing class HelperDatabase {

    //--------------------------------------------------------------------------------------------------------------------------
    // INSERT
    //--------------------------------------------------------------------------------------------------------------------------

    public static void insertRecords(List<SObject> data, String objAPIName) 
    {

        insertRecords(data, objAPIName, true); 
    }

    public static void insertRecords(List<SObject> data, String objAPIName, Boolean allOrNone) 
    {

        HelperSchema.checkObjectPermissions(objAPIName, HelperSchema.CREATABLE);

        Database.insert(data, allOrNone);
    }

    public static void insertRecord(SObject data, String objAPIName) 
    {
        List<SObject> records = new List<SObject>();
        records.add(data);

        insertRecords(records, objAPIName);
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

        HelperSchema.checkObjectPermissions(objAPIName, HelperSchema.UPDATEABLE);

        Database.update(data, allOrNone);
        
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

        HelperSchema.checkObjectPermissions(objAPIName, HelperSchema.CREATABLE);
        HelperSchema.checkObjectPermissions(objAPIName, HelperSchema.UPDATEABLE);

        if (externalIdField != null)
        {
            Schema.SObjectField field = HelperSchema.getFieldSchema(objAPIName, externalIdField);
            Database.upsert(data, field, allOrNone);
        } else 
            Database.upsert(data, allOrNone);
        
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