public with sharing class ListViewErrorHelper {

    /*
     * Method to create a usage error record which can be used for debugging purposes.
     */
    @future
    public static void createUsageError(String message) 
    {
        List_View_Error__c error   = new List_View_Error__c();
        error.Running_User__c  = UserInfo.getUserId();
        error.Message__c       = message.replaceAll('\n', ' '); //JSON parser does not like \n

        insert error;

        System.debug(LoggingLevel.ERROR, 'Error record created - ' + error);

    }

    public static void createUsageErrorNonFuture(String message) 
    {
        List_View_Error__c error   = new List_View_Error__c();
        error.Running_User__c  = UserInfo.getUserId();
        error.Message__c       = message.replaceAll('\n', ' '); //JSON parser does not like \n

        insert error;

        System.debug(LoggingLevel.ERROR, 'Error record created - ' + error);

    }

}