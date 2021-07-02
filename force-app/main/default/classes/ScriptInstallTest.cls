/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 06-30-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-05-2020   tom.h.ansley@medtronic.com   Initial Version
**/
@isTest
private class ScriptInstallTest {

    @testSetup
    static void createSampleData()
    {
        ListViewHelper.insertCoreConfiguration();
    }

 	@isTest
	static void ScriptInstallTest()
	{
		ScriptInstall postinstall = new ScriptInstall();
        Test.testInstall(postinstall, null);
        Test.testInstall(postinstall,  new Version(1, 0));
        System.assert(true);
	}
}