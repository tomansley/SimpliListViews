/**
 * @File Name          : ListViewErrorHelper.cls
 * @Description        : 
 * @Author             : tom@ansleyllc.com
 * @Group              : 
 * @Last Modified By   : tom@ansleyllc.com
 * @Last Modified On   : 05-08-2025
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/11/2020   tom@ansleyllc.com     Initial Version
**/
global with sharing class ListViewErrorHelper {

    global static final String TYPE_EXCEPTION = 'Exception';
    global static final String TYPE_LOG = 'Log';

    global static List<List_View_Error__c> logs = new List<List_View_Error__c>(); //holds all debugging logs that we might log before finishing the transaction.

    global static void addLog(String className, String message)
    {
        addLog(TYPE_LOG, className, message);
    }

    global static void addException(String className, String message)
    {
        addLog(TYPE_EXCEPTION, className, message);
    }

    private static void addLog(String type, String className, String message)
    {
        addLog(type, className, message, false);
    }

    /**
    * @description Method to add a log to be processed.
    * @author tom.h.ansley@medtronic.com | 01-11-2022 
    * @param type the type of log. EXCEPTION or LOG
    * @param className the subject of category of the log.
    * @param message the long description of the log.
    * @param force indicates the log should be added regardless of whether debugging is on.
    **/
    global static void addLog(String type, String className, String message, Boolean force)
    {
        if (force || Boolean.valueOf(ListViewConfigHelper.getOrgWideConfigParam(ListViewConfigHelper.DEBUG, 'false')))
        {
            List_View_Error__c log   = new List_View_Error__c();
            log.Running_User__c  = UserInfo.getUserId();
            log.Message__c       = message;
            log.Type__c          = type;
            log.Subtype__c       = className;
            logs.add(log);
        }
    }

    global static void processLogs(Boolean isFuture)
    {
        if (logs.size() > 0)
        {
            if (!isFuture)
            {
                HelperDatabase.insertRecords(logs);
                logs = new List<List_View_Error__c>();
            } else {
                processFutureLogs(JSON.serialize(logs));
            }
        }
    }

    @future
    private static void processFutureLogsFuture(String jsonString)
    {
        List<List_View_Error__c> logs = (List<List_View_Error__c>) JSON.deserialize(jsonString, List<List_View_Error__c>.class);
        HelperDatabase.insertRecords(logs);
    }

    global static void processFutureLogs(String jsonString)
    {
        if (Limits.getFutureCalls() < Limits.getLimitFutureCalls())
            processFutureLogsFuture(jsonString);
    }

    @future
    private static void createFutureUsageErrorFuture(String message)
    {
        System.debug(LoggingLevel.ERROR, 'Error - ' + message);
        if (Limits.getFutureCalls() < Limits.getLimitFutureCalls())
        {
            List_View_Error__c error   = new List_View_Error__c();
            error.Running_User__c  = UserInfo.getUserId();
            error.Message__c       = message;
            error.Type__c          = TYPE_EXCEPTION;
            error = (List_View_Error__c) HelperDatabase.insertRecord(error);
    
            System.debug(LoggingLevel.ERROR, 'Error record created - ' + error);
        }
    }
    /*
     * Method to create a usage error record which can be used for debugging purposes.
     */
    global static void createFutureUsageError(String message)
    {
        if (Limits.getFutureCalls() < Limits.getLimitFutureCalls())
            createFutureUsageErrorFuture(message);
    }

    global static void createNonFutureUsageError(String message) 
    {
        List_View_Error__c error   = new List_View_Error__c();
        error.Running_User__c  = UserInfo.getUserId();
        error.Message__c       = message;
        error.Type__c          = TYPE_EXCEPTION;

        error = (List_View_Error__c) HelperDatabase.insertRecord(error);

        System.debug(LoggingLevel.ERROR, 'Error record created - ' + error);

    }

}