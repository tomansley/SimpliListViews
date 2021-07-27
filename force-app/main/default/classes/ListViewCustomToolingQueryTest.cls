/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 07-26-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   06-30-2021   tom.h.ansley@medtronic.com   Initial Version
**/
@isTest
global with sharing class ListViewCustomToolingQueryTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();

        HelperTest.insertAccount('Test Account 1');
    }

    @isTest
    static void ListViewCustomToolingTest() {
        
		List_View_Config__c config = [SELECT Id FROM List_View_Config__c WHERE Primary_Key__c = 'ApexLog:ApexLogs'];

		List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
		param.Parameter_Name__c = 'TotalColumns';
		param.Parameter_Type__c = 'String';
		param.Parameter_Value__c = 'DurationMilliseconds';
		param.List_View_Config__c = config.Id;
        param.Parameter_Label__c  = 'Duration';

        insert param;

        Test.startTest();

            Test.setMock(HttpCalloutMock.class, new ListViewCustomToolingQueryTest.ListViewCustomToolingQueryTest_CalloutMock());

            ListViewAbstract.RowsWrapper rows = ListViewController.getListViewData('', 'ApexLog', 'ApexLogs', '', '', '', -1);

        Test.stopTest();

        System.assertEquals(2, rows.getRowCount());

    }

    global class ListViewCustomToolingQueryTest_CalloutMock implements HttpCalloutMock  {
   
        //method to send mock respose
        global HTTPResponse respond(HTTPRequest request) {
    
            HTTPResponse wsResponse = new HTTPResponse();

            String body = '';
            System.debug(LoggingLEvel.DEBUG, 'END POINT - ' + request.getEndPoint());
            if (request.getEndpoint().contains('ApexLog'))
                body = '{"size":240,"totalSize":240,"done":true,"queryLocator":null,"entityTypeName":"ApexLog","records":[{"attributes":{"type":"ApexLog","url":"/services/data/v52.0/tooling/sobjects/ApexLog/07L3h000007BmwnEAC"},"DurationMilliseconds":12514,"Id":"07L3h000007BmwnEAC","LogLength":1367125,"LogUserId":"0053h000000xrj3AAA","Operation":"ApexTestHandler","Request":"Api","StartTime":"2021-06-30T13:30:05.000+0000","Status":"Assertion Failed"},{"attributes":{"type":"ApexLog","url":"/services/data/v52.0/tooling/sobjects/ApexLog/07L3h000007Bn1mEAC"},"DurationMilliseconds":11322,"Id":"07L3h000007Bn1mEAC","LogLength":1380172,"LogUserId":"0053h000000xrj3AAA","Operation":"ApexTestHandler","Request":"Api","StartTime":"2021-06-30T13:40:13.000+0000","Status":"Success"}]}';

            wsResponse.setHeader('Content-Type', 'application/json');
            wsResponse.setBody(body);
            wsResponse.setStatusCode(200);    
            return wsResponse;
        }
    
    }
}