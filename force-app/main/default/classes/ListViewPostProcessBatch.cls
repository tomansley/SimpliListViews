/**
 * @File Name          : ListViewPostProcessBatch.cls
 * @Description        : 
 * @Author             : tom@ansleyllc.com
 * @Group              : 
 * @Last Modified By   : tom@ansleyllc.com
 * @Last Modified On   : 12-06-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/11/2020   tom@ansleyllc.com     Initial Version
**/
public with sharing class ListViewPostProcessBatch implements Database.AllowsCallouts, Database.Batchable<SObject>, Database.Stateful, Schedulable {

    private String query = 'SELECT Id FROM List_View__c';
    private final Integer batchSize = 40;
    private Set<Id> listViewIds = null;

    /*
        Simpli_lv.ListViewPostProcessBatch b = new Simpli_lv.ListViewPostProcessBatch();
        b.execute(null);
    */
    public ListViewPostProcessBatch() {
    }

    /*
        * Constructor used to only process those list views who's Ids are provided.
        */
    public ListViewPostProcessBatch(Set<Id> listViewIds)
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

            String debug = 'SOQL - ' + query;
            debug += ' Exc Objs - ' + exclObjs;

            System.debug(LoggingLevel.FINE, debug);
            ListViewErrorHelper.addLog('ListViewPostProcessBatch(start)', debug);

            ListViewErrorHelper.processLogs(false);

            return Database.getQueryLocator(query);

        } catch (Exception e) {
            String message = 'Exception during ListViewPostProcessBatch.start(' + query + ')  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(message);
            Database.setSavepoint();
        }
                
        return null;
    }

    /* IMPLEMENTS DATABASE.BATCHABLE INTERFACE */
    public void execute(Database.BatchableContext BC, List<SObject> scope) 
    {
        try {

            SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, scope);

            HelperDatabase.deleteRecords(dec.getRecords(), 'List_View__c');
            
        } catch (Exception e) {
            String message = 'Exception during ListViewPostProcessBatch.execute()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(message); 
        }
        ListViewErrorHelper.processLogs(false);
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
            String message = 'Exception during ListViewPostProcessBatch.finish()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createNonFutureUsageError(message); 
        }

        //finally set isInitialized to true.
        ListViewConfigHelper.setOrgWideConfigParam('IsInitialized', 'true');

        ListViewErrorHelper.processLogs(false);
    }
    
}