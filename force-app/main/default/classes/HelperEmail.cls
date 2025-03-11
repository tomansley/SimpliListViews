/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 03-09-2025
 * @last modified by  : tom@ansleyllc.com
 * 1.0   04-01-2020   tom@ansleyllc.com   Initial Version
 * 2.0   01-06-2022   tom@ansleyllc.com   Added getEmailTemplate(), getEmailTemplates(), sendEmailsFromTemplate() methods.
**/
public with sharing class HelperEmail {

    public static EmailTemplate getEmailTemplate(String devName)
    {
        EmailTemplate template = null;

        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT ApiVersion,
                        Body,
                        BrandTemplateId,
                        Description,
                        DeveloperName,
                        Encoding,
                        FolderId,
                        FolderName,
                        HtmlValue,
                        Id,
                        IsActive,
                        Markup,
                        Name,
                        NamespacePrefix,
                        RelatedEntityType,
                        Subject,
                        TemplateStyle,
                        TemplateType,
                        UiType 
                 FROM EmailTemplate
                 WHERE DeveloperName = :devName
                        AND IsActive = true]);

        List<EmailTemplate> templates = (List<EmailTemplate>) dec.getRecords();

        if (templates.size() > 0)
            template = templates[0];

        return template;        
    }

    public static List<EmailTemplate> getEmailTemplates(String folderName)
    {

        List<EmailTemplate> templates = new List<EmailTemplate>();

        SObjectAccessDecision dec = 
            Security.stripInaccessible(AccessType.READABLE,
                [SELECT Id
                 FROM Folder
                 WHERE Type = 'Email'
                        AND Name = :folderName]);

        List<Folder> folders = (List<Folder>) dec.getRecords();

        if (folders.size() > 0)
        {

            dec = Security.stripInaccessible(AccessType.READABLE,
                    [SELECT Name,
                            DeveloperName
                    FROM EmailTemplate
                    WHERE FolderId = :folders[0].Id]);

            templates = (List<EmailTemplate>) dec.getRecords();
        }

        return templates;
    }

    /**
    * @description Method to send emails based on the provided record Ids and template
    * @author tom@ansleyllc.com | 01-05-2022 
    * @param recordIds the record Ids holding the data used to send the email
    * @param whatIdField the what Id to aid the template creation if one exists.
    * @param templateDevName the dev name of the template to use when rendering the email.
    * @return String the error message if an error occurs, or an empty string.
    **/
    public static String sendEmailsFromTemplate(List<String> recordIds, String whatIdField, String templateDevName)
    {
        String response = '';

        //if empty record ids then return
        if (recordIds.isEmpty()) return response;

        if (recordIds.size() > 1000)
            return 'Cannot send more than 1000 emails in one transaction';

        //ensure we can send the number of emails we are trying to send
        try {
            Messaging.reserveSingleEmailCapacity(recordIds.size());
        } catch (Exception e) {
            response = e.getMessage();
            return response;
        }

        //get the template from the provided dev name
        EmailTemplate template = getEmailTemplate(templateDevName);

        //get the object type we are working with
        String objType = HelperSchema.getObjectTypeFromId(recordIds[0]);

        String soql = 'SELECT Id';
        if (!String.isEmpty(whatIdField))
            soql += ', ' + String.escapeSingleQuotes(whatIdField);
        soql += ' FROM ' + objType + ' WHERE Id IN :recordIds';

        List<SObject> records = Database.query(soql);

        do {
            List<Messaging.Email> emails = new List<Messaging.Email>();
            do {
                //REMOVE record from list
                SObject record = records.remove(0);
                
                //create email message
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setTemplateId(template.Id);  
                message.setSaveAsActivity(false);
                message.setTargetObjectId((String) record.get('Id'));
                if (!String.isEmpty(whatIdField))
                {
                    String whatId = (String) record.get(whatIdField);
                    message.setWhatId(whatId);
                }
                emails.add(message);

            //do this while we have less than 100 emails to send or we have no more records.
            } while (emails.size() < 150 && records.size() > 0);

            try {
                //send the set of maximum 100 emails.
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
            } catch (Exception e) {
                response = e.getMessage();
                return response;
            }
        } while (!records.isEmpty());

        return response;
    }

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

    public static Boolean sendEmail(String toAddress, String emailBody, String emailSubject)
    {
        List<String> toAddresses = new List<String>{toAddress};

        return sendEmails(toAddresses, emailBody, emailSubject);
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