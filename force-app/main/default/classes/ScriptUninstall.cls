/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-05-2020   tom@ansleyllc.com   Initial Version
**/
global with sharing class ScriptUninstall implements UninstallHandler {
	
	global void onUninstall(UninstallContext context) 
	{
		HelperEmail.sendInstallEmail('UnInstalled');
	}

}