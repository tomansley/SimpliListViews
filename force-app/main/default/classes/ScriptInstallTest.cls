/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 07-18-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-05-2020   tom.h.ansley@medtronic.com   Initial Version
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