/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-11-2021   tom@ansleyllc.com   Initial Version
**/
@isTest
public with sharing class ListViewConfigControllerTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

    @IsTest
    static void getOrgWideDescriptionsTest()
    {
        Test.startTest();

            List<ListViewConfigController.ConfigDescription> orgWideDescs = ListViewConfigController.getOrgWideDescriptions();

        Test.stopTest();
    
        System.assert(orgWideDescs != null);
        System.assert(orgWideDescs.size() > 0);

    }

    @IsTest
    static void getComponentDescriptionsTest()
    {
        Test.startTest();

            List<ListViewConfigController.ConfigDescription> compDescs = ListViewConfigController.getComponentDescriptions();

        Test.stopTest();
    
        System.assert(compDescs != null);
        System.assert(compDescs.size() > 0);

    }

    @IsTest
    static void getListViewDescriptionsTest()
    {
        Test.startTest();

            List<ListViewConfigController.ConfigDescription> lvDescs = ListViewConfigController.getListViewDescriptions();

        Test.stopTest();
    
        System.assert(lvDescs != null);
        System.assert(lvDescs.size() > 0);

    }
}