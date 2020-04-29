global with sharing class ScriptInstall implements InstallHandler {

	global void onInstall(InstallContext context) 
	{
		if(context.previousVersion() == null)
		{
			//insert core configuration
			ListViewHelper.insertCoreConfiguration();
			
			//run the batch job once to have all list views brought in
			if (!Test.isRunningTest())
			{
				ListViewProcessBatch b = new ListViewProcessBatch();
				b.execute(null);
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