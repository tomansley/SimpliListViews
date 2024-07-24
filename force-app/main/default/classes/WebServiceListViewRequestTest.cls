@isTest
public with sharing class WebServiceListViewRequestTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();

        HelperTest.createCoreListViews();
    }

    @isTest
	static void searchSchemaTest()
	{
        Test.startTest();

            List<ListViewController.SelectOption> options = ListViewTypeAheadController.search('schema', 'Acc', 'SObject', 'Label', 'Name', null);
            System.assert(options.size() > 0);

            options = ListViewTypeAheadController.search('schema', 'Contact', 'SObject', 'Label', 'Name', 'simpli_lv__Object_Name__c NOT IN [\'Contact\']');

            Test.stopTest();
    }

    public class WebServiceListViewRequestTest_CalloutMock implements HttpCalloutMock  {
   
        //method to send mock respose
        public HTTPResponse respond(HTTPRequest request) {
    
            HTTPResponse wsResponse = new HTTPResponse();

            String body = '';
            System.debug(LoggingLEvel.DEBUG, 'END POINT - ' + request.getEndPoint());
            if (request.getEndpoint().contains('Account/listviews/'))
                body = '{"Columns":{"columns":[{"width":"width: 415px;","name":"Name","label":"Account Name"},{"width":"width: 305px;","name":"Site","label":"Account Site"},{"width":"width: 294px;","name":"BillingState","label":"Billing State/Province"},{"width":"width: 175px;","name":"LastModifiedDate","label":"Last Modified Date"},{"width":"width: 90px;","name":"simpli_lv__Active__c","label":"Active"}]},"Data":{"rows":[{"fields":{"simpli_lv__Active__c":{"value":"No","type":"picklist","name":"simpli_lv__Active__c"},"LastModifiedDate":{"value":"1673989622000","type":"datetime","name":"LastModifiedDate"},"BillingState":{"value":"TX","type":"string","name":"BillingState"},"Site":{"value":"Other Site 1","type":"string","name":"Site"},"Name":{"value":"Express Logistics and Transport","type":"string","name":"Name"}}},{"fields":{"simpli_lv__Active__c":{"value":"Yes","type":"picklist","name":"simpli_lv__Active__c"},"LastModifiedDate":{"value":"1694531622000","type":"datetime","name":"LastModifiedDate"},"BillingState":{"value":"CA","type":"string","name":"BillingState"},"Site":{"value":"2","type":"string","name":"Site"},"Name":{"value":"Grand Hotels & Resorts","type":"string","name":"Name"}}},{"fields":{"simpli_lv__Active__c":{"value":"Yes","type":"picklist","name":"simpli_lv__Active__c"},"LastModifiedDate":{"value":"1636134215000","type":"datetime","name":"LastModifiedDate"},"BillingState":{"value":"TX","type":"string","name":"BillingState"},"Site":{"value":"Tom Site","type":"string","name":"Site"},"Name":{"value":"United Oil & Gas Corp.","type":"string","name":"Name"}}},{"fields":{"simpli_lv__Active__c":{"value":"Yes","type":"picklist","name":"simpli_lv__Active__c"},"LastModifiedDate":{"value":"1636134215000","type":"datetime","name":"LastModifiedDate"},"BillingState":{"value":"Singapore","type":"string","name":"BillingState"},"Site":{"value":"","type":"string","name":"Site"},"Name":{"value":"United Oil & Gas, Singapore","type":"string","name":"Name"}}},{"fields":{"simpli_lv__Active__c":{"value":"Yes","type":"picklist","name":"simpli_lv__Active__c"},"LastModifiedDate":{"value":"1636134215000","type":"datetime","name":"LastModifiedDate"},"BillingState":{"value":"UK","type":"string","name":"BillingState"},"Site":{"value":"","type":"string","name":"Site"},"Name":{"value":"United Oil & Gas, UK","type":"string","name":"Name"}}},{"fields":{"simpli_lv__Active__c":{"value":"Yes","type":"picklist","name":"simpli_lv__Active__c"},"LastModifiedDate":{"value":"1638676869000","type":"datetime","name":"LastModifiedDate"},"BillingState":{"value":"CA","type":"string","name":"BillingState"},"Site":{"value":"Site Test","type":"string","name":"Site"},"Name":{"value":"University of Arizona","type":"string","name":"Name"}}}]}}';

            wsResponse.setHeader('Content-Type', 'application/json');
            wsResponse.setBody(body);
            wsResponse.setStatusCode(200);    
            return wsResponse;
        }
    
    }

}