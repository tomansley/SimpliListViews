/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   06-30-2021   tom@ansleyllc.com   Initial Version
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