/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 08-29-2022
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

        String tme = HelperDate.getStringFromTime(System.now().time());
        System.assert(!String.isEmpty(tme));

	}
}