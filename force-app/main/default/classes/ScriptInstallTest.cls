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
private class ScriptInstallTest {

 	@isTest
	static void ScriptInstallTest()
	{
        Test.startTest();
            ScriptInstall postinstall = new ScriptInstall();
            Test.testInstall(postinstall, null);
            Test.testInstall(postinstall,  new Version(1, 0));
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void ScriptInstall2Test()
    {
        ListViewHelper.insertCoreConfiguration();

        Test.startTest();
            ScriptInstall postinstall = new ScriptInstall();
            Test.testInstall(postinstall, null);
            Test.testInstall(postinstall,  new Version(1, 0));
        Test.stopTest();
        System.assert(true);
    }
}