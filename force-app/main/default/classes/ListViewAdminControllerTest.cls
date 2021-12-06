/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 12-06-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-18-2021   tom@ansleyllc.com   Initial Version
**/
@isTest
global class ListViewAdminControllerTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();

        HelperTest.insertAccount('Test Account 1');
    }

    @IsTest
    static void getOrgWideConfigTest()
    {
    
        Test.startTest();
            
            ListViewAbstract.ListViewConfigWrapper config = ListViewAdminController.getOrgWideConfig();

            System.assertEquals('All', config.getObject());
            System.assertEquals('All', config.getName());
            System.assertEquals(20, config.getParameters().size());

            ListViewAbstract.ListViewParam param = config.getParameters()[0];
            System.assertNotEquals(param.getReadOnly(), null);
            System.assertNotEquals(param.getListValues(), null);
            System.assertNotEquals(param.getIsListString(), null);

        Test.stopTest();
        
    }

    @IsTest
    static void updateOrgWideConfigTest()
    {
    
        Test.startTest();
            
            String allowRefresh = ListViewConfigHelper.getOrgWideConfigParam('AllowAutomaticDataRefresh');
            System.assertEquals('true', allowRefresh);

            String result = ListViewAdminController.saveOrgWideConfig('[["ExcludedObjectTypes",["AIApplication"]],["AllowAutomaticDataRefresh","false"],["DisplayActionsButton","false"]]');
            System.assertEquals('Ok:', result);

            allowRefresh = ListViewConfigHelper.getOrgWideConfigParam('AllowAutomaticDataRefresh');
            System.assertEquals('false', allowRefresh);

        Test.stopTest();
        
    }

    @IsTest
    static void getObjectNamesTest()
    {
    
        Test.startTest();
            
            List<ListViewController.SelectOption> objNames = ListViewAdminController.getObjectNames();

            System.assert(objNames.size() > 0);
            Boolean hasAccount = false;
            for (ListViewController.SelectOption option: objNames)
            {
                if (option.value == 'Account')
                    hasAccount = true;
            }
            System.assertEquals(true, hasAccount);

        Test.stopTest();
        
    }

    @IsTest
    static void unScheduleRefreshTest()
    {
    
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');

        Test.startTest();
            
            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewAdminController.SUCCESS);

    }

    @IsTest
    static void scheduleMinutelyRefreshTest()
    {
        //unschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');
        ListViewAdminController.scheduleRefreshJob();

        //reschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'minutely:5');

        Test.startTest();

            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewAdminController.SUCCESS);

    }

    @IsTest
    static void scheduleHourlyRefreshTest()
    {
    
        //unschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');
        ListViewAdminController.scheduleRefreshJob();

        //reschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'hourly:20');

        Test.startTest();

            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewAdminController.SUCCESS);

    }

    @IsTest
    static void scheduleDailyRefreshTest()
    {
    
        //unschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');
        ListViewAdminController.scheduleRefreshJob();

        //reschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'daily:20:5');

        Test.startTest();

            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewAdminController.SUCCESS);

    }

    @IsTest
    static void scheduleWeeklyRefreshTest()
    {
    
        //unschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');
        ListViewAdminController.scheduleRefreshJob();

        //reschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'weekly:20:5:WED');

        Test.startTest();

            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewAdminController.SUCCESS);

    }

    @IsTest
    static void scheduleMonthlyRefreshTest()
    {
    
        //unschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'Not Scheduled');
        ListViewAdminController.scheduleRefreshJob();

        //reschedule
        ListViewConfigHelper.setOrgWideConfigParam('RefreshJob', 'monthly:20:5:15');

        Test.startTest();

            String result = ListViewAdminController.scheduleRefreshJob();

        Test.stopTest();
        
        System.assert(result == ListViewAdminController.SUCCESS);

    }
}