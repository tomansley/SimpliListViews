/**
 * @File Name          : ListViewDeleteBatch.cls
 * @Description        : 
 * @Author             : tom.h.ansley@medtronic.com
 * @Group              : 
 * @Last Modified By   : tom.h.ansley@medtronic.com
 * @Last Modified On   : 10-10-2020
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/11/2020   tom.h.ansley@medtronic.com     Initial Version
**/
public with sharing class ListViewDeleteBatch implements Database.AllowsCallouts, Database.Batchable<SObject>, Database.Stateful, Schedulable {

    private String query = 'SELECT Id FROM List_View__c';
    private final Integer batchSize = 40;
    private Set<Id> listViewIds = null;

    /*
        Simpli_lv.ListViewDeleteBatch b = new Simpli_lv.ListViewDeleteBatch();
        b.execute(null);
    */
    public ListViewDeleteBatch() {
    }

    /*
        * Constructor used to only process those list views who's Ids are provided.
        */
    public ListViewDeleteBatch(Set<Id> listViewIds)
    {
        this.listViewIds = listViewIds;
    }

    /* IMPLEMENTS SCHEDULABLE INTERFACE */
    public void execute(SchedulableContext sc)
    {
        database.executebatch(this, batchSize);
    }
        
    /* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
    public Database.QueryLocator start(Database.BatchableContext BC) 
    {
        Database.QueryLocator locator = null;
        try {

            //get objects that should always be excluded
            String exclObjs = ListViewConfigHelper.getOrgWideConfigParam('ExcludedObjectTypes');
            Set<String> orgWideExcObjs = HelperString.getSetFromString(exclObjs, ',');
            
            if (!orgWideExcObjs.isEmpty())
                query += ' WHERE Object_Name__c IN :orgWideExcObjs';
            else
                query += ' WHERE Object_Name__c = \'FAKENAME\''; //make sure nothing gets deleted.

            if (Test.isRunningTest())
                query += ' LIMIT 1';

            HelperSchema.checkListViewAccessible();

            return Database.getQueryLocator(query);

        } catch (Exception e) {
            String message = 'Exception during ListViewDeleteBatch.start(' + query + ') - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageErrorNonFuture(message);
            Database.setSavepoint();
        }
                
        return null;
    }

    /* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
    public void execute(Database.BatchableContext BC, List<SObject> scope) 
    {
        try {

            HelperDatabase.deleteRecords(scope, 'List_View__c');
            
        } catch (Exception e) {
            String message = 'Exception during ListViewDeleteBatch.execute() - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageErrorNonFuture(message); 
        }
    }
    
    /* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */ 
    public void finish(Database.BatchableContext BC) 
    {
        try {
            //now that all list views have been added/deleted we can update the objects 
            //displayed to the user.
            if (!Test.isRunningTest())
                ListViewHelper.updateListViewObjectsSetting();
        } catch (Exception e) {
            String message = 'Exception during ListViewDeleteBatch.finish() - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageErrorNonFuture(message); 
        }
    }
    
    public class ListViewDeleteBatchException extends Exception { }

}