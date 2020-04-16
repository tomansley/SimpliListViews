@isTest
private class ScriptInstallTest {

	@isTest
	static void ScriptInstallTest()
	{
		ScriptInstall postinstall = new ScriptInstall();
		Test.testInstall(postinstall, null);
	}
}