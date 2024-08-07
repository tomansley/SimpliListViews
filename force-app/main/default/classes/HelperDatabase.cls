/**
 * @description       : Helper class to aid in the handling of DML transactions
 * @author            : tom@ansleyllc.com
 * @last modified on  : 08-07-2024
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   09-08-2020   tom@ansleyllc.com   Initial Version
 * 2.0   10-31-2021   tom@ansleyllc.com   Added query() methods.
 * 3.0   12-15-2021   tom@ansleyllc.com   Removed old methods for checking object accessibility.

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

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, database.query(soql));
        
        List<SObject> results = dec.getRecords();

        return results;
    }

    //--------------------------------------------------------------------------------------------------------------------------
    // INSERT
    //--------------------------------------------------------------------------------------------------------------------------

    public static List<SObject> insertRecords(List<SObject> data) 
    {
        return insertRecords(data, true); 
    }

    public static SObject insertRecord(SObject data) 
    {
        if (data != null)
        {
            List<SObject> records = new List<SObject>();
            records.add(data);

            records = insertRecords(records);

            return records[0];
        }
        return null;
    }

    public static List<SObject> insertRecords(List<SObject> data, Boolean allOrNone) 
    {
        if (data == null || data.size() == 0) return new List<SObject>();

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.CREATABLE, data);

        List<Database.SaveResult> results = Database.insert(dec.getRecords(), allOrNone);

        Integer errorCount = 0;
        for (Database.SaveResult result: results)
            errorCount = errorCount + result.getErrors().size();

        try { System.debug(LoggingLevel.DEBUG, 'Inserting(' + HelperSchema.getObjectTypeFromId((Id)data[0].get('Id')) + ') - Total = ' + data.size() + ', Error = ' + errorCount); } catch (Exception e) { }

        data = dec.getRecords();
        
        return data;
    }

    public static List<Database.SaveResult> insertRecordsWithResults(List<SObject> data, Boolean allOrNone) 
    {
        List<Database.SaveResult> results = new List<Database.SaveResult>();

        if (data != null && data.size() > 0)
        {
            SObjectAccessDecision dec = Security.stripInaccessible(AccessType.CREATABLE, data);

            results = Database.insert(dec.getRecords(), allOrNone);
        }

        return results;
    }


    //--------------------------------------------------------------------------------------------------------------------------
    // UPDATE
    //--------------------------------------------------------------------------------------------------------------------------

    public static void updateRecord(SObject data) 
    {
        List<SObject> records = new List<SObject>();
        records.add(data);

        updateRecords(records);
        
    }

    public static void updateRecords(List<SObject> data) 
    {
        updateRecords(data, true); 
    }

    public static void updateRecords(List<SObject> data, Boolean allOrNone) 
    {
        if (data == null || data.size() == 0) return;

        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.UPDATABLE, data);

        List<Database.SaveResult> results = Database.update(dec.getRecords(), allOrNone);
        
        Integer errorCount = 0;
        for (Database.SaveResult result: results)
            errorCount = errorCount + result.getErrors().size();

        try { System.debug(LoggingLevel.DEBUG, 'Updating(' + HelperSchema.getObjectTypeFromId((Id)data[0].get('Id')) + ') - Total = ' + data.size() + ', Error = ' + errorCount); } catch (Exception e) { }

        data = dec.getRecords();

    }

    public static List<Database.SaveResult> updateRecordsWithResults(List<SObject> data, Boolean allOrNone) 
    {
        List<Database.SaveResult> results = new List<Database.SaveResult>();

        if (data != null && data.size() > 0)
        {
            SObjectAccessDecision dec = Security.stripInaccessible(AccessType.UPDATABLE, data);

            results = Database.update(dec.getRecords(), allOrNone);
        }

        return results;
    }


    //--------------------------------------------------------------------------------------------------------------------------
    // UPSERT
    //--------------------------------------------------------------------------------------------------------------------------

    public static SObject upsertRecord(SObject data) 
    {
        if (data != null)
        {
            List<SObject> records = new List<SObject>();
            records.add(data);

            records = upsertRecords(records);

            return records[0];
        }
        return null;
    }

    public static SObject upsertRecord(SObject data, String externalIdField) 
    {
        if (data != null)
        {
            List<SObject> records = new List<SObject>();
            records.add(data);

            records = upsertRecords(records, externalIdField, true);
            
            return records[0];
        }
        return null;
   }

    public static List<SObject> upsertRecords(List<SObject> data) 
    {
        return upsertRecords(data, null, true); 
    }

    public static List<SObject> upsertRecords(List<SObject> data, String externalIdField, Boolean allOrNone) 
    {
        if (data.size() == 0) return data;
        
        SObjectAccessDecision dec = Security.stripInaccessible(AccessType.UPSERTABLE, data);        

        List<Database.UpsertResult> results = null;
        if (externalIdField != null)
        {
            Schema.SObjectField field = HelperSchema.getFieldSchema(HelperSchema.getObjectType(data[0]), externalIdField);
            results = Database.upsert(dec.getRecords(), field, allOrNone);
        } else {    
            results = Database.upsert(dec.getRecords(), allOrNone);
        }

        Integer errorCount = 0;
        for (Database.UpsertResult result: results)
            errorCount = errorCount + result.getErrors().size();

        try { System.debug(LoggingLevel.DEBUG, 'Upserting(' + HelperSchema.getObjectTypeFromId((Id)data[0].get('Id')) + ') - Total = ' + data.size() + ', Error = ' + errorCount); } catch (Exception e) { }
        
        data = dec.getRecords();

        return data;
    }

    /*
     * Method to perform an upsertion without using the stripping core method. This ensures that
     * the returned SObjects are pointing to the same SObjects as the method that called it.
     */
    public static List<Database.UpsertResult> upsertRecordsNoStrip(List<SObject> data, String externalIdField, Boolean allOrNone) 
    {
        if (data.size() == 0) return new List<Database.UpsertResult>();
        
        String objName = HelperSchema.getObjectType(data[0]);
        Schema.DescribeSObjectResult objDesc = HelperSchema.getObjectSchema(objName);
        if (objDesc.isUpdateable() == false || objDesc.isCreateable() == false)
            throw new ListViewException('You do not have update or create permissions on this object - ' + objName);

        List<Database.UpsertResult> results = null;
        if (externalIdField != null)
        {
            Schema.SObjectField field = HelperSchema.getFieldSchema(HelperSchema.getObjectType(data[0]), externalIdField);
            results = Database.upsert(data, field, allOrNone);
        } else {    
            results = Database.upsert(data, allOrNone);
        }

        Integer errorCount = 0;
        for (Database.UpsertResult result: results)
            errorCount = errorCount + result.getErrors().size();

        try { System.debug(LoggingLevel.DEBUG, 'Upserting(' + HelperSchema.getObjectTypeFromId((Id)data[0].get('Id')) + ') - Total = ' + data.size() + ', Error = ' + errorCount); } catch (Exception e) { }
        
        return results;
    }

    //--------------------------------------------------------------------------------------------------------------------------
    // DELETE
    //--------------------------------------------------------------------------------------------------------------------------

    public static void deleteRecords(List<SObject> data) 
    {

        deleteRecords(data, true); 
    }

    public static void deleteRecords(List<SObject> data, Boolean allOrNone) 
    {
        if (data != null && data.size() > 0)
        {
            String objName = HelperSchema.getObjectType(data[0]);
            Schema.DescribeSObjectResult objDesc = HelperSchema.getObjectSchema(objName);

            if (objDesc.isDeletable() == false)
                throw new ListViewException('You do not have delete permissions on this object - ' + objName);

            Database.delete(data, allOrNone);
        }
    }

    public static List<Database.DeleteResult> deleteRecordsWithResults(List<SObject> data, Boolean allOrNone) 
    {
        List<Database.DeleteResult> results = new List<Database.DeleteResult>();

        if (data != null && data.size() > 0)
        {
            String objName = HelperSchema.getObjectType(data[0]);
            Schema.DescribeSObjectResult objDesc = HelperSchema.getObjectSchema(objName);
    
            if (objDesc.isDeletable() == false)
                throw new ListViewException('You do not have delete permissions on this object - ' + objName);
    
            results = Database.delete(data, allOrNone);
        }

        return results;
    }

    public static void deleteRecord(SObject data) 
    {
        List<SObject> records = new List<SObject>();
        records.add(data);

        deleteRecords(records);
    }

}