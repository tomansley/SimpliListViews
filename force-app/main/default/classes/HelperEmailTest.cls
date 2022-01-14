/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-14-2022
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   07-18-2021   tom@ansleyllc.com   Initial Version
**/
@isTest
global class HelperEmailTest {

    @isTest
    static void sendEmailTest()
    {
        Test.startTest();
            Boolean result = HelperEmail.sendEmail('tom@ansleyllc.com', 'Small body', 'Email Subject');
        Test.stopTest();

        System.assertEquals(true, result);
    }


    @isTest(seeAllData = true) //have to do this as you cannot create folders for testing
    static void getEmailTemplatesTest()
    {
        Test.startTest();
            List<EmailTemplate> folders = HelperEmail.getEmailTemplates('SLV Contact Email Folder');
        Test.stopTest();

        System.assertNotEquals(0, folders.size());
    }

    @isTest(seeAllData = true) //have to do this as you cannot create email templates for testing
    static void getEmailTemplateTest()
    {
        Test.startTest();
            EmailTemplate template = HelperEmail.getEmailTemplate('SLV_Template_1_Contact');
        Test.stopTest();

        System.assertNotEquals(null, template);
    }

    @isTest(seeAllData = true) //have to do this as you cannot create email templates for testing
    static void sendEmailsFromTemplateTest()
    {
        Account acct = HelperTest.insertAccount('List View Account');
        Contact cont = HelperTest.insertContact(acct, 'First1', 'Last1', 'testy1@testerson.com');
        List<String> recordIds = new List<String>{cont.Id};

        Test.startTest();
            String result = HelperEmail.sendEmailsFromTemplate(recordIds, 'simpli_lv__Child_Object__c', 'SLV_Test_Coverage_Template_Contact_Child_Obj');
        Test.stopTest();

        System.assertEquals('', result);
    }

    @isTest(seeAllData = true) //have to do this as you cannot create email templates for testing
    static void send1000EmailsFromTemplateTest()
    {
        Account acct = HelperTest.insertAccount('List View Account');
        Contact cont = HelperTest.insertContact(acct, 'First1', 'Last1', 'testy1@testerson.com');
        List<String> recordIds = new List<String>();
        for (Integer index = 0; index < 1100; index++)
            recordIds.add(cont.Id);
        
        Test.startTest();
            String result = HelperEmail.sendEmailsFromTemplate(recordIds, 'simpli_lv__Child_Object__c', 'SLV_Test_Coverage_Template_Contact_Child_Obj');
        Test.stopTest();

        System.assertEquals('Cannot send more than 1000 emails in one transaction', result);
    }

}