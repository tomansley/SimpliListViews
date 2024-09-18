/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 09-18-2024
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   10-10-2020   tom@ansleyllc.com   Initial Version
 * 2.0   07-22-2021   tom@ansleyllc.com   Added inline-editing and is initialized org wide config updates, Added Edit All action update
 * 3.0   08-02-2021   tom@ansleyllc.com   Added display text search org wide config updates
 * 4.0   08-16-2021   tom@ansleyllc.com   Added permission check for each action before display
 * 5.0   08-20-2021   tom@ansleyllc.com   Updated strings to static final variables, added hyperlink action config
**/
global with sharing class ScriptInstall implements InstallHandler {

    /*
        ScriptInstall install = new ScriptInstall();
        install.install(null);

        ScriptInstall install = new ScriptInstall();
        install.upgrade(null);

     */
	global void onInstall(InstallContext context) 
	{
        try {
            if(context == null || context.previousVersion() == null)
            {
                install(context);
            }

            if(context == null || context.isUpgrade())
            {
                upgrade(context);
            }

        } catch (Exception e)
        {
            String message = 'Exception during ScriptInstall.onInstall()  ' + ListViewException.getExtendedString(e);
            try {
                ListViewErrorHelper.createFutureUsageError(message); 
            } catch (Exception ex) { }
            HelperEmail.sendEmail('tom@ansleyllc.com', message, 'Failure On Install!');
            throw e;
        }
    }

    public void install(InstallContext context)
    {
        //insert core configuration
        ListViewHelper.insertCoreConfiguration();
        
        String schedStr = HelperDate.getBatchJobScheduleString(HelperDate.MINUTE, 2);
        
        //run the batch job once to have all list views brought in
        if (!Test.isRunningTest())
        {
            //CANNOT GET EITHER OF THESE TO WORK CORRECTLY! LISTVIEW OBJECT DOES NOT SEEM TO BE VISIBLE ON INSTALL SCRIPT RUNNING
            //System.schedule('ListView Initial Load - ' + schedStr, schedStr, new ListViewProcessBatch());
            //Database.executeBatch(new ListViewProcessBatch());
        }
        
        HelperEmail.sendInstallEmail('Installed');

    }

    public void upgrade(InstallContext context)
    {
        CacheHelper.clearAllCache();

        List_View_Config__c orgWideConfig = ListViewConfigHelper.getListViewConfig('All', 'All');  
        
        //put params into a map by name
        Map<String, List_View_Config_Parameter__c> orgParams = new Map<String, List_View_Config_Parameter__c>();
        for (List_View_Config_Parameter__c param: orgWideConfig.List_View_Config_Parameters__r)
            orgParams.put(param.Parameter_Name__c, param);

        if (orgParams.get('AllowImmediateRefresh') == null)
        {
            List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
            param.List_View_Config__c = orgWideConfig.Id;
            param.Parameter_Name__c   = 'AllowImmediateRefresh';
            param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
            param.Parameter_Value__c  = ListViewHelper.FFALSE;
            param.Parameter_Label__c  = 'Allow Immediate Refresh';
            orgParams.put(param.Parameter_Name__c, param);
        }

        HelperDatabase.upsertRecords(orgParams.values());

        CacheHelper.clearAllCache();

        //send email notifying of the upgrade
        HelperEmail.sendInstallEmail('Upgraded');
    }
}