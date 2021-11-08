/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-08-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   10-22-2021   tom@ansleyllc.com   Initial Version
**/
@isTest
private class HelperLimitsTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

 	@isTest
	static void limitsTest()
	{
        //Test.startTest();
            String limitStr = HelperLimits.getLimitsString();
            System.debug(LoggingLevel.DEBUG, limitStr);

            System.assertEquals(false, HelperLimits.hasReachedLimit('DMLRows'));

            Boolean isException = false;
            try {
                HelperLimits.hasReachedLimit('FakeName');
            } catch (ListViewException e) {
                isException = true;
            }
            System.assert(isException);

            Integer count = HelperLimits.getCurrentLimitCount('DMLStatements');
            System.assert(count > 0);

        //Test.stopTest();
    }

}