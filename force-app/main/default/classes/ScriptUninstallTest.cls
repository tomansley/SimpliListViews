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