/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 12-16-2021
 * @last modified by  : tom@ansleyllc.com
**/
@isTest
public with sharing class ListViewErrorHelperTest {
    
    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

    public static testMethod void processLogsNonFutureTest() {
        
        ListViewConfigHelper.setOrgWideConfigParam('Debug', 'true');

        Test.startTest();

            ListViewErrorHelper.addException('ClassName', 'Error message goes here!');

            ListViewErrorHelper.processLogs(false);

        Test.stopTest();
        
        List<List_View_Error__c> logs = [SELECT Id, Subtype__c, Message__c FROM List_View_Error__c];

        System.assertEquals(1, logs.size());

    }

    public static testMethod void processLogsFutureTest() {
        
        ListViewConfigHelper.setOrgWideConfigParam('Debug', 'true');

        Test.startTest();

            ListViewErrorHelper.addException('ClassName', 'Error message goes here!');

            ListViewErrorHelper.processLogs(true);

        Test.stopTest();
        
        List<List_View_Error__c> logs = [SELECT Id, Subtype__c, Message__c FROM List_View_Error__c];

        System.assertEquals(1, logs.size());

    }
}