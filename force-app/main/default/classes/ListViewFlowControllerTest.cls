/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-05-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   11-05-2020   tom@ansleyllc.com   Initial Version
**/
@IsTest
global class ListViewFlowControllerTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

    static testMethod void listViewFlowControllerTest() {

        Test.startTest();

        ApexPages.currentPage().getParameters().put('recordIds', '"0013h000007JTggAAG","0013h000007JTghAAG","0013h000007JTgcAAG"');
        ListViewFlowController controller = new ListViewFlowController();

        Test.stopTest();

        System.assert(controller.recordIds != null);

    }

}