/**
 * @File Name          : ListViewErrorHelper.cls
 * @Description        : 
 * @Author             : tom@ansleyllc.com
 * @Group              : 
 * @Last Modified By   : tom@ansleyllc.com
 * @Last Modified On   : 12-06-2021
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/11/2020   tom@ansleyllc.com     Initial Version
**/
public with sharing class ListViewErrorHelper {

    public static final String TYPE_EXCEPTION = 'Exception';
    public static final String TYPE_LOG = 'Log';

    public static List<List_View_Error__c> logs = new List<List_View_Error__c>(); //holds all debugging logs that we might log before finishing the transaction.

    public static void addLog(String className, String message)
    {
        addLog(TYPE_LOG, className, message);
    }

    public static void addException(String className, String message)
    {
        addLog(TYPE_EXCEPTION, className, message);
    }

    private static void addLog(String type, String className, String message)
    {
        if (Boolean.valueOf(ListViewConfigHelper.getOrgWideConfigParam('Debug')))
        {
            List_View_Error__c log   = new List_View_Error__c();
            log.Running_User__c  = UserInfo.getUserId();
            log.Message__c       = message;
            log.Type__c          = type;
            log.Subtype__c       = className;
            logs.add(log);
        }
    }

    public static void processLogs(Boolean isFuture)
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
    public static void processFutureLogs(String jsonString)
    {
        List<List_View_Error__c> logs = (List<List_View_Error__c>) JSON.deserialize(jsonString, List<List_View_Error__c>.class);
        HelperDatabase.insertRecords(logs);
    }

    /*
     * Method to create a usage error record which can be used for debugging purposes.
     */
    @future
    public static void createFutureUsageError(String message)
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

    public static void createNonFutureUsageError(String message) 
    {
        List_View_Error__c error   = new List_View_Error__c();
        error.Running_User__c  = UserInfo.getUserId();
        error.Message__c       = message;
        error.Type__c          = TYPE_EXCEPTION;

        error = (List_View_Error__c) HelperDatabase.insertRecord(error);

        System.debug(LoggingLevel.ERROR, 'Error record created - ' + error);

    }

}