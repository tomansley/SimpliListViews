global with sharing class ScriptInstall implements InstallHandler {

	global void onInstall(InstallContext context) 
	{
		if(context.previousVersion() == null)
		{
            try {
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
            } catch (Exception e) {
                String message = 'Exception during ScriptInstall.onInstall() - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
                ListViewErrorHelper.createUsageError(message); 
            }
            
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

}