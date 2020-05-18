public with sharing class ListViewErrorHelper {

    /*
     * Method to create a usage error record which can be used for debugging purposes.
     */
    public static List_View_Error__c createUsageError(String message) 
    {
        List_View_Error__c error   = new List_View_Error__c();
        error.Running_User__c  = UserInfo.getUserId();
        error.Message__c       = message.replaceAll('\n', ' '); //JSON parser does not like \n

        insert error;

        System.debug(LoggingLevel.ERROR, 'Error record created - ' + error);

        return error;
    }
}