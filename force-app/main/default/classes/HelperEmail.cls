/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
**/
public with sharing class HelperEmail {

    public static void sendInstallEmail(String type)
    {
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> toAddr = new List<String>();
            toAddr.add('tom@ansleyllc.com');
            String subject = 'Simpli List Views ' + type + ' Successfully';
            String htmlBody = 'Simpli List Views ' + type + ' Successfully - ';

            Organization org = [SELECT Name, IsSandbox, OrganizationType, Country, PrimaryContact FROM Organization LIMIT 1];

            if (org.IsSandbox)
                htmlBody += 'Sandbox';
            else
                htmlBody += 'Production';

            htmlBody += '<br/></br>' + org.Name + '/' + org.OrganizationType + '/' + org.Country + '/' + org.PrimaryContact;

            sendEmails(toAddr, htmlBody, subject);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error creating emails');
        }
	}

    /*
     * Method which sends an email to a list of addresses with the given body and subject.
     * The method returns whether the emails were submitted successfully or not. Note that
     * a body and subject are required and the number of email addresses cannot exceed 100
     */
    public static Boolean sendEmails(List<String> toAddresses, String emailBody, String emailSubject)
    {
    	
    	Boolean isSent = true;
    	
    	try {
    		
    		if (String.isEmpty(emailSubject)) throw new ListViewException('An email subject is required when sending an email');
    		if (String.isEmpty(emailBody)) throw new ListViewException('An email body is required when sending an email');
    		if (toAddresses == null || toAddresses.size() == 0 || toAddresses.size() > 100) throw new ListViewException('The number of email addresses used when sending an email cannot be 0 or more than 100');
    		
			Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			mail.setToAddresses(toAddresses);
			mail.setSubject(emailSubject);
			mail.setHTMLBody(emailBody);
	
			String debug = '\n\n----- Email Sent -----\n';
			debug       += 'Email Addresses - ' + toAddresses + '\n';
			debug       += 'Email Subject   - ' + emailSubject + '\n';
			debug       += 'Email Body      - ' + emailBody + '\n';
			debug       += '-----            -----\n';

			System.debug(LoggingLevel.FINE, debug);

			//if we are not in a sandbox and not running a test then send emails
			if (!Test.isRunningTest())
				Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
					
    	} catch (Exception e)
    	{
    		isSent = false;

			System.debug(LoggingLevel.ERROR, 'Exception thrown - ' + e.getMessage() + '\n\n' + e.getStackTraceString() + '\n\n');
			
    	}			
		return isSent;
    }

}