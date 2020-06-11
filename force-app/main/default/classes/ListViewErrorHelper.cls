/**
 * @File Name          : ListViewErrorHelper.cls
 * @Description        : 
 * @Author             : tom.h.ansley@medtronic.com
 * @Group              : 
 * @Last Modified By   : tom.h.ansley@medtronic.com
 * @Last Modified On   : 6/11/2020, 8:29:18 AM
 * @Modification Log   : 
 * Ver       Date            Author      		    Modification
 * 1.0    6/11/2020   tom.h.ansley@medtronic.com     Initial Version
**/
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

        HelperSchema.checkObjectCreatable('List_View_Error__c');

        insert error;

        System.debug(LoggingLevel.ERROR, 'Error record created - ' + error);

    }

    public static void createUsageErrorNonFuture(String message) 
    {
        List_View_Error__c error   = new List_View_Error__c();
        error.Running_User__c  = UserInfo.getUserId();
        error.Message__c       = message.replaceAll('\n', ' '); //JSON parser does not like \n

        HelperSchema.checkObjectCreatable('List_View_Error__c');

        insert error;

        System.debug(LoggingLevel.ERROR, 'Error record created - ' + error);

    }

}