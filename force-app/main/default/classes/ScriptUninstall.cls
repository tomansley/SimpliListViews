/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 11-05-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   11-05-2020   tom.h.ansley@medtronic.com   Initial Version
**/
global with sharing class ScriptUninstall implements UninstallHandler {
	
	global void onUninstall(UninstallContext context) 
	{
		sendUpdateEmail(context);
	}

	private void sendUpdateEmail(UninstallContext context)
	{
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		List<String> toAddr = new List<String>();
		toAddr.add('tom@ansleyllc.com');
		mail.setToAddresses(toAddr);
		mail.setReplyTo('tom@ansleyllc.com');
		mail.setSenderDisplayName('Simpli List Views UnInstall Update');
        mail.setSubject('Simpli List Views UnInstalled Successfully');
        String htmlBody = 'Simpli List Views UnInstalled Successfully - ';

        Organization org = [SELECT Name, IsSandbox, OrganizationType, Country, PrimaryContact FROM Organization LIMIT 1];

        if (org.IsSandbox)
            htmlBody += 'Sandbox';
        else
            htmlBody += 'Production';

        htmlBody += '<br/></br>' + org.Name + '/' + org.OrganizationType + '/' + org.Country + '/' + org.PrimaryContact;

		mail.setHtmlBody(htmlBody);
		Messaging.sendEmail(new Messaging.Email[] { mail });
	}

}