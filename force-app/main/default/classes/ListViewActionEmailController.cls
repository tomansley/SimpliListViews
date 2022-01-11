/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-11-2022
 * @last modified by  : tom@ansleyllc.com
 * 1.0   01-05-2022   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewActionEmailController {
    
    @AuraEnabled
    public static String processEmails(String templateDevName, String whatId, String recordIdsStr)
    {
        String response = ':success';
        try {

            List<String> recordIds = (List<String>) JSON.deserialize(recordIdsStr, List<String>.class);

            HelperEmail.sendEmailsFromTemplate(recordIds, whatId, templateDevName);

        } catch (Exception e) {
            response = ListViewException.getExtendedString(e) + ':fail';
        }
        return response;
    }

    @AuraEnabled(cacheable=true)
    public static List<ListViewController.SelectOption> getEmailTemplates(String folderName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewActionEmailController.getEmailTemplates(' + folderName + ')');
        List<ListViewController.SelectOption> templatesListOptions = new List<ListViewController.SelectOption>();

        List<EmailTemplate> templates = HelperEmail.getEmailTemplates(folderName);

        for (EmailTemplate template: templates)
            templatesListOptions.add(new ListViewController.SelectOption(template.DeveloperName, template.Name));         

        return templatesListOptions;
    }

    @AuraEnabled(cacheable=true)
    public static EmailTemplate getEmailTemplateDetails(String devName)
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewActionEmailController.getEmailTemplateDetails(' + devName + ')');

        return HelperEmail.getEmailTemplate(devName);
    }



}