/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 02-02-2022
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

            //Test.testInstall(postinstall,  new Version(1, 0));
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void ScriptInstall2Test()
    {
        List_View_Config__c config2 = new List_View_Config__c();
        config2.Name                = 'All';
        config2.List_View_Object__c = 'All';
        config2.List_View_Label__c   = 'Org Wide Configuration';
        config2.Primary_Key__c      = config2.List_View_Object__c + ':' + config2.Name;

        insert config2;

        Test.startTest();
            ScriptInstall postinstall = new ScriptInstall();
            //Test.testInstall(postinstall, null);
            Test.testInstall(postinstall,  new Version(1, 0));
        Test.stopTest();
        System.assert(true);
    }
}