@isTest
private class ListViewConfigHelperTest {

    @testSetup
    private static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

    @IsTest
    static void setOrgWideConfigTest()
    {
    
        Test.startTest();
            
            ListViewConfigHelper.setOrgWideConfig('List View Objects', 'Test Setting');
            
        Test.stopTest();

        String value = ListViewConfigHelper.getOrgWideConfig('List View Objects');

        System.assert(value == 'Test Setting');
    }

}