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
		mail.setHtmlBody('Simpli List Views UnInstalled Successfully');
		Messaging.sendEmail(new Messaging.Email[] { mail });
	}

}