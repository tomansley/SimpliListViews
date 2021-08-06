/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 08-04-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-05-2020   tom.h.ansley@medtronic.com   Initial Version
**/
global with sharing class ScriptUninstall implements UninstallHandler {
	
	global void onUninstall(UninstallContext context) 
	{
		HelperEmail.sendInstallEmail('UnInstalled');
	}

}