/**
 * @File Name          : ListViewErrorHelper.cls
 * @Description        : 
 * @Author             : tom.h.ansley@medtronic.com
 * @Group              : 
 * @Last Modified By   : tom.h.ansley@medtronic.com
 * @Last Modified On   : 09-08-2020
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

        HelperDatabase.insertRecord(error, 'Simpli_lv__List_View_Error__c');

        System.debug(LoggingLevel.ERROR, 'Error record created - ' + error);

    }

    public static void createUsageErrorNonFuture(String message) 
    {
        List_View_Error__c error   = new List_View_Error__c();
        error.Running_User__c  = UserInfo.getUserId();
        error.Message__c       = message.replaceAll('\n', ' '); //JSON parser does not like \n

        HelperDatabase.insertRecord(error, 'Simpli_lv__List_View_Error__c');

        System.debug(LoggingLevel.ERROR, 'Error record created - ' + error);

    }

}