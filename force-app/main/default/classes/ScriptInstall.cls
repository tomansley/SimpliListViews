/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 11-10-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-10-2020   tom.h.ansley@medtronic.com   Initial Version
**/
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

            //------------------------------------------------------------------------------------
            // Fix issue where some list view actions might not have record types - through v1.60
            //------------------------------------------------------------------------------------
            List<List_View__c> listviews = [SELECT Id, RecordTypeId FROM List_View__c LIMIT 2000];
            List<List_View__c> updatedListViews = new List<List_View__c>();
            for (List_View__c lv: listviews)
            {
                if (lv.RecordTypeId == null || lv.RecordTypeId == '')
                {
                    lv.RecordTypeId = ListViewHelper.coreRTId;
                    updatedListViews.add(lv);
                }
            }

            HelperDatabase.updateRecords(updatedListViews, 'simpli_lv__List_View__c');

            //------------------------------------------------------------------------------------
            // Fix issue where some list view actions might not have record types - through v1.60
            //------------------------------------------------------------------------------------
            List<List_View_Action__c> actions = [SELECT Id, RecordTypeId FROM List_View_Action__c LIMIT 2000];
            List<List_View_Action__c> updatedActions = new List<List_View_Action__c>();
            for (List_View_Action__c action: actions)
            {
                if (action.RecordTypeId == null || action.RecordTypeId == '')
                {
                    action.RecordTypeId = ListViewActionHelper.coreRTId;
                    updatedActions.add(action);
                }
            }

            HelperDatabase.updateRecords(updatedActions, 'simpli_lv__List_View_Action__c');

            //---------------------------------------------------------------------------------
            // Fix issue where config parameter names had spaces. Doh! - through v1.60
            //---------------------------------------------------------------------------------
            List<List_View_Config__c> orgWideConfigs = ListViewConfigHelper.getListViewConfig('All', 'All');  
            
            if (!orgWideConfigs.isEmpty())
            {
                List_View_Config__c orgWideConfig = orgWideConfigs[0];
                
                //put params into a map by name
                Map<String, List_View_Config_Parameter__c> orgParams = new Map<String, List_View_Config_Parameter__c>();
                for (List_View_Config_Parameter__c param: orgWideConfig.List_View_Config_Parameters__r)
                    orgParams.put(param.Parameter_Name__c, param);

                if (orgParams.get('List View Objects') != null) 
                {
                    orgParams.get('List View Objects').Parameter_Name__c = 'ListViewObjects';
                    orgParams.get('List View Objects').Parameter_Label__c = 'List View Objects';
                }

                if (orgParams.get('Excluded Object Types') != null)
                {
                    orgParams.get('Excluded Object Types').Parameter_Name__c = 'ExcludedObjectTypes';
                    orgParams.get('Excluded Object Types').Parameter_Label__c = 'Excluded Object Types';
                }

                if (orgParams.get('Included Object Types') != null) 
                {
                    orgParams.get('Included Object Types').Parameter_Name__c = 'IncludedObjectTypes';
                    orgParams.get('Included Object Types').Parameter_Label__c = 'Included Object Types';
                }

                if (orgParams.get('DisplayActionsButton') == null)
                {
                    List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                    param.List_View_Config__c = orgWideConfig.Id;
                    param.Parameter_Name__c   = 'DisplayActionsButton';
                    param.Parameter_Type__c   = 'Boolean';
                    param.Parameter_Value__c  = 'true';
                    param.Parameter_Label__c  = 'Display Actions Button';
                    orgParams.put(param.Parameter_Name__c, param);
                }
                
                if (orgParams.get('DisplayListViewReprocessingButton') == null)
                {
                    List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                    param.List_View_Config__c = orgWideConfig.Id;
                    param.Parameter_Name__c   = 'DisplayListViewReprocessingButton';
                    param.Parameter_Type__c   = 'Boolean';
                    param.Parameter_Value__c  = 'true';
                    param.Parameter_Label__c  = 'Display List View Reprocessing Button';
                    orgParams.put(param.Parameter_Name__c, param);
                }

                if (orgParams.get('DisplayOriginalListViewButton') == null)
                {
                    List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                    param.List_View_Config__c = orgWideConfig.Id;
                    param.Parameter_Name__c   = 'DisplayOriginalListViewButton';
                    param.Parameter_Type__c   = 'Boolean';
                    param.Parameter_Value__c  = 'true';
                    param.Parameter_Label__c  = 'Display Original List View Button';
                    orgParams.put(param.Parameter_Name__c, param);
                }
                
                if (orgParams.get('DisplaySelectedCount') == null)
                {
                    List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                    param.List_View_Config__c = orgWideConfig.Id;
                    param.Parameter_Name__c   = 'DisplaySelectedCount';
                    param.Parameter_Type__c   = 'Boolean';
                    param.Parameter_Value__c  = 'true';
                    param.Parameter_Label__c  = 'Display Selected Count';
                    orgParams.put(param.Parameter_Name__c, param);
                }
            
                if (orgParams.get('AllowDataExport') == null)
                {
                    List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                    param.List_View_Config__c = orgWideConfig.Id;
                    param.Parameter_Name__c   = 'AllowDataExport';
                    param.Parameter_Type__c   = 'Boolean';
                    param.Parameter_Value__c  = 'true';
                    param.Parameter_Label__c  = 'Allow Data Export';
                    orgParams.put(param.Parameter_Name__c, param);
                }
            
                if (orgParams.get('AllowAutomaticDataRefresh') == null)
                {
                    List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                    param.List_View_Config__c = orgWideConfig.Id;
                    param.Parameter_Name__c   = 'AllowAutomaticDataRefresh';
                    param.Parameter_Type__c   = 'Boolean';
                    param.Parameter_Value__c  = 'true';
                    param.Parameter_Label__c  = 'Allow Automatic Data Refresh';
                    orgParams.put(param.Parameter_Name__c, param);
                }
            
                if (orgParams.get('DisplayRowCount') == null)
                {
                    List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                    param.List_View_Config__c = orgWideConfig.Id;
                    param.Parameter_Name__c   = 'DisplayRowCount';
                    param.Parameter_Type__c   = 'Boolean';
                    param.Parameter_Value__c  = 'true';
                    param.Parameter_Label__c  = 'Display Row Count';
                    orgParams.put(param.Parameter_Name__c, param);
                }

                HelperDatabase.upsertRecords(orgParams.values(), 'simpli_lv__List_View_Config_Parameter__c');
            }
		}

		if(context.isPush()) 
		{
		}
	}

}