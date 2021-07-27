/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 06-30-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   06-30-2021   tom.h.ansley@medtronic.com   Initial Version
**/
@isTest
private class HelperDateTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

 	@isTest
	static void HelperDateMethodsTest()
	{
		String result = HelperDate.getBatchJobScheduleString(HelperDate.MINUTE, 10);
        System.assert(!String.isEmpty(result));
	}
}