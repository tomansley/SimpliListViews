/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   11-05-2020   tom@ansleyllc.com   Initial Version
**/
@IsTest
global class ListViewProcessBatchTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

    static testMethod void listViewProcessBatchTest() {

        Test.startTest();

            Test.setMock(HttpCalloutMock.class, new ListViewProcessBatchTest.ListViewProcessBatchTest_CalloutMock());

            ListViewProcessBatch job = new ListViewProcessBatch(new Set<Id>());
            job = new ListViewProcessBatch();
            job.execute(null);
            job.start(null);

            job.execute(null, [SELECT Id, Name, SObjectType, DeveloperName, CreatedById FROM ListView WHERE SObjectType != null LIMIT 1]);

        Test.stopTest();

        System.assertEquals(5, [SELECT Id FROM List_View__c].size());

    }

    global class ListViewProcessBatchTest_CalloutMock implements HttpCalloutMock  {
   
        //method to send mock respose
        global HTTPResponse respond(HTTPRequest request) {
    
            HTTPResponse wsResponse = new HTTPResponse();

            String body = '';
            System.debug(LoggingLEvel.DEBUG, 'END POINT - ' + request.getEndPoint());
            if (request.getEndpoint().contains('Report/listviews/'))
                body = '{"columns":[{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Name","hidden":false,"label":"Name","selectListItem":"Name","sortDirection":"ascending","sortIndex":0,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Account.Name","hidden":false,"label":"Account Name","selectListItem":"Account.Name","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Title","hidden":false,"label":"Title","selectListItem":"Title","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":"9-0","descendingLabel":"0-9","fieldNameOrPath":"Phone","hidden":false,"label":"Phone","selectListItem":"Phone","sortDirection":null,"sortIndex":null,"sortable":true,"type":"phone"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Email","hidden":false,"label":"Email","selectListItem":"Email","sortDirection":null,"sortIndex":null,"sortable":true,"type":"email"},{"ascendingLabel":"Z-A","descendingLabel":"A-Z","fieldNameOrPath":"Owner.Alias","hidden":false,"label":"Contact Owner Alias","selectListItem":"Owner.Alias","sortDirection":null,"sortIndex":null,"sortable":true,"type":"string"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Id","hidden":true,"label":"Contact ID","selectListItem":"Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"CreatedDate","hidden":true,"label":"Created Date","selectListItem":"CreatedDate","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"LastModifiedDate","hidden":true,"label":"Last Modified Date","selectListItem":"LastModifiedDate","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"SystemModstamp","hidden":true,"label":"System Modstamp","selectListItem":"SystemModstamp","sortDirection":null,"sortIndex":null,"sortable":false,"type":"datetime"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Account.Id","hidden":true,"label":"Account ID","selectListItem":"Account.Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"AccountId","hidden":true,"label":"Account ID","selectListItem":"AccountId","sortDirection":null,"sortIndex":null,"sortable":false,"type":"reference"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"Owner.Id","hidden":true,"label":"User ID","selectListItem":"Owner.Id","sortDirection":null,"sortIndex":null,"sortable":false,"type":"id"},{"ascendingLabel":null,"descendingLabel":null,"fieldNameOrPath":"OwnerId","hidden":true,"label":"Owner ID","selectListItem":"OwnerId","sortDirection":null,"sortIndex":null,"sortable":false,"type":"reference"}],"id":"00B3h000003ZfMY","orderBy":[{"fieldNameOrPath":"Name","nullsPosition":"first","sortDirection":"ascending"},{"fieldNameOrPath":"Id","nullsPosition":"first","sortDirection":"ascending"}],"query":"SELECT Name, Account.Name, Title, Phone, Email, Owner.Alias, Id, CreatedDate, LastModifiedDate, SystemModstamp, Account.Id, AccountId, Owner.Id, OwnerId FROM Contact USING SCOPE mine ORDER BY Name ASC NULLS FIRST, Id ASC NULLS FIRST","scope":"mine","sobjectType":"Contact","whereCondition":{"conditions":[],"conjunction":"and"}}';

            wsResponse.setHeader('Content-Type', 'application/json');
            wsResponse.setBody(body);
            wsResponse.setStatusCode(200);    
            return wsResponse;
        }
    
    }

}