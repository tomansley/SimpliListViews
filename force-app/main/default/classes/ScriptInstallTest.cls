/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 11-05-2020
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
		ScriptInstall postinstall = new ScriptInstall();
        Test.testInstall(postinstall, null);
        
        System.assert(true);
	}
}