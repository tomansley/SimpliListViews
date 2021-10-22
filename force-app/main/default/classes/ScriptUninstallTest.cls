/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-05-2020   tom@ansleyllc.com   Initial Version
**/
@isTest
private class ScriptUninstallTest {

	@isTest
	static void testUninstallScript() 
	{
		Id UninstallerId = UserInfo.getUserId();
		Test.testUninstall(new ScriptUninstall());

		System.assert(true);
	}
}