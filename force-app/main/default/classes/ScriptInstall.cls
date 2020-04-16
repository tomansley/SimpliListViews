global with sharing class ScriptInstall implements InstallHandler {
	
	global void onInstall(InstallContext context) 
	{
		if(context.previousVersion() == null)
		{
			//insert core configuration
			ListViewHelper.insertCoreConfiguration();
			
			//run the batch job once to have all list views brought in
			//if (!Test.isRunningTest())
			//{
			//	SimpliListViewBatch b = new SimpliListViewBatch();
			//	b.execute(null);
			//}

			User u = [Select Id, Email from User where Id =:context.installerID()];   
			String toAddress= u.Email;
			String[] toAddresses = new String[]{toAddress};
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(toAddresses);
			mail.setReplyTo('tom@ansleyllc.com');
			mail.setSenderDisplayName('Simpli List Views');
			mail.setSubject('Simpli List Views Installed Successfully');
			mail.setHtmlBody(getInstallHTMLBody());
			mail.setPlainTextBody(getInstallPlainTextBody());
			Messaging.sendEmail(new Messaging.Email[] { mail });
		
		} else if(context.previousVersion().compareTo(new Version(1,0)) == 0) 
		{
		}

		if(context.isUpgrade())
		{
		}

		if(context.isPush()) 
		{
		}
	}

	private String getInstallPlainTextBody()
	{
		String plainBody = 'Thank you for installing the Simpli List Views package. (Please note the UI app and examples have been designed for use in Lightning.)';
		plainBody += '';
		plainBody += 'Once logged into your SFDC org open the Simpli List Views app where a number of tabs and examples are available.';
		plainBody += '';
		plainBody += 'For those looking to create extensions a github repository is available with code samples to help get them up-to-speed.';
		plainBody += '';
		plainBody += 'Watch the repository for documentation updates as well.';

		return plainBody;
	}

	private String getInstallHTMLBody()
	{
		String htmlBody = '<p>Thank you for installing the Simpli List Views package. (<b>Please note the UI app and examples have been designed for use in Lightning.</b>)</p>';
				htmlBody += '<br/>';
				htmlBody += '<p>Once logged into your SFDC org open the Simpli List Views app where a number of tabs and examples are available.</p>';
				htmlBody += '<br/>';
				htmlBody += '<p>For those looking to create extensions a <a href="https://github.com/tomansley/SimpliExamples">github repository</a> is available with code samples to help get them up-to-speed.</p>';
				htmlBody += '<br/>';
				htmlBody += '<p>Watch the repository for documentation updates as well.</p>';
		return htmlBody;
	}

}