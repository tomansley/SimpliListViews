/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-08-2021
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
                String message = 'Exception during ScriptInstall.onInstall()  ' + ListViewException.getExtendedString(e);
                ListViewErrorHelper.createFutureUsageError(message); 
            }
            
            HelperEmail.sendInstallEmail('Installed');

		} else if(context.previousVersion().compareTo(new Version(1,0)) == 0) 
		{
		}

		if(context.isUpgrade())
		{

            List<List_View__c> listviews = [SELECT Id, Primary_Key__c, RecordTypeId FROM List_View__c WHERE RecordType.Name = 'Custom' LIMIT 2000];
            List<List_View__c> newListViews = new List<List_View__c>();
            Boolean hasCampMem = false;
            for (List_View__c lv: listviews)
            {
                if (lv.Primary_Key__c == 'CampaignMember:CampaignMembers')
                    hasCampMem = true;
            }

            if (!hasCampMem)
            {
                List_View__c lv             = new List_View__c();
                lv.Custom_Apex_Class__c     = 'ListViewCustomManual';
                lv.Label__c                 = 'Campaign Members';
                lv.Core_ListView_Columns__c = '[{"fieldNameOrPath":"Name","type":"string","label":"Name"},  {"fieldNameOrPath":"Status","type":"string","label":"Status"},{"fieldNameOrPath":"Type","type":"string","label":"Type"},{"fieldNameOrPath":"Phone","type":"string","label":"Phone"}]';
                lv.Core_ListView_Query__c   = 'SELECT Name, Status, Type, Phone FROM CampaignMember';
                lv.Object_Name__c           = 'CampaignMember';
                lv.RecordTypeId             = ListViewHelper.customRTId;
                lv.Subtype__c               = 'Manual';
        
                newListViews.add(lv);
            }

            HelperDatabase.insertRecords(newListViews, 'simpli_lv__List_View__c');

            //------------------------------------------------------------------------------------
            // Fix issue where some list view actions might not have record types - through v1.60
            //------------------------------------------------------------------------------------
            List<List_View_Action__c> actions = ListViewActionHelper.getListViewActions();
            List<List_View_Action__c> updatedActions = new List<List_View_Action__c>();
            for (List_View_Action__c action: actions)
            {
                if (action.RecordTypeId == null)
                {
                    action.RecordTypeId = ListViewActionHelper.coreRTId;
                    updatedActions.add(action);
                }
            }

            HelperDatabase.updateRecords(updatedActions, 'simpli_lv__List_View_Action__c');

            //---------------------------------------------------------------------------------
            // Fix issue where config parameter names had spaces. Doh! - through v1.60
            //---------------------------------------------------------------------------------
            List_View_Config__c orgWideConfig = ListViewConfigHelper.getListViewConfig('All', 'All');  
            
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
                orgParams.get('Excluded Object Types').Parameter_Type__c = ListViewHelper.TYPE_STRING;
            } else if (orgParams.get('ExcludedObjectTypes') != null) 
            {
                orgParams.get('ExcludedObjectTypes').Parameter_Type__c = ListViewHelper.TYPE_STRING;
            }

            if (orgParams.get('Included Object Types') != null) 
            {
                orgParams.get('Included Object Types').Parameter_Name__c = 'IncludedObjectTypes';
                orgParams.get('Included Object Types').Parameter_Label__c = 'Included Object Types';
                orgParams.get('Included Object Types').Parameter_Type__c = ListViewHelper.TYPE_STRING;
            } else if (orgParams.get('IncludedObjectTypes') != null) 
            {
                orgParams.get('IncludedObjectTypes').Parameter_Type__c = ListViewHelper.TYPE_STRING;
            }


            if (orgParams.get('IsInitialized') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'IsInitialized';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'false';
                param.Parameter_Label__c  = 'Is Initialized';
                orgParams.put(param.Parameter_Name__c, param);
            } else {
                orgParams.get('IsInitialized').Parameter_Value__c  = 'false'; //set to false for every upgrade so that the list views are initialized.
            }

            if (orgParams.get('DisplayActionsButton') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'DisplayActionsButton';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'true';
                param.Parameter_Label__c  = 'Display Actions Button';
                orgParams.put(param.Parameter_Name__c, param);
            }
            
            if (orgParams.get('AllowAdmin') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'AllowAdmin';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'true';
                param.Parameter_Label__c  = 'Display Admin Button';
                orgParams.put(param.Parameter_Name__c, param);
            }
            
            if (orgParams.get('DisplayListViewReprocessingButton') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'DisplayListViewReprocessingButton';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'true';
                param.Parameter_Label__c  = 'Display List View Reprocessing Button';
                orgParams.put(param.Parameter_Name__c, param);
            }

            if (orgParams.get('DisplayOriginalListViewButton') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'DisplayOriginalListViewButton';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'true';
                param.Parameter_Label__c  = 'Display Original List View Button';
                orgParams.put(param.Parameter_Name__c, param);
            }
            
            if (orgParams.get('DisplaySelectedCount') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'DisplaySelectedCount';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'true';
                param.Parameter_Label__c  = 'Display Selected Count';
                orgParams.put(param.Parameter_Name__c, param);
            }
        
            if (orgParams.get('AllowDataExport') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'AllowDataExport';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'true';
                param.Parameter_Label__c  = 'Allow Data Export';
                orgParams.put(param.Parameter_Name__c, param);
            }
        
            if (orgParams.get('AllowAutomaticDataRefresh') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'AllowAutomaticDataRefresh';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'true';
                param.Parameter_Label__c  = 'Allow Automatic Data Refresh';
                orgParams.put(param.Parameter_Name__c, param);
            }
        
            if (orgParams.get('MaxRowsDisplayed') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'MaxRowsDisplayed';
                param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
                param.Parameter_Value__c  = '2500';
                param.Parameter_Label__c  = 'Max Rows Displayed';
                orgParams.put(param.Parameter_Name__c, param);
            }

            if (orgParams.get('QueryPagingSize') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'QueryPagingSize';
                param.Parameter_Type__c   = ListViewHelper.TYPE_NUMBER;
                param.Parameter_Value__c  = '250';
                param.Parameter_Label__c  = 'Query Paging Size';
                orgParams.put(param.Parameter_Name__c, param);
            }

            if (orgParams.get('DisplayRowCount') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'DisplayRowCount';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'true';
                param.Parameter_Label__c  = 'Display Row Count';
                orgParams.put(param.Parameter_Name__c, param);
            }

            if (orgParams.get('AllowInlineEditing') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'AllowInlineEditing';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'true';
                param.Parameter_Label__c  = 'Allow Inline Editing';
                orgParams.put(param.Parameter_Name__c, param);
            }
    
            if (orgParams.get('DisplayTextSearch') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'DisplayTextSearch';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'true';
                param.Parameter_Label__c  = 'Display Text Search';
                orgParams.put(param.Parameter_Name__c, param);
            }

            if (orgParams.get('Debug') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'Debug';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'false';
                param.Parameter_Label__c  = 'Debug';
                orgParams.put(param.Parameter_Name__c, param);
        
            }

            if (orgParams.get('DisplayRecordPopovers') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'DisplayRecordPopovers';
                param.Parameter_Type__c   = ListViewHelper.TYPE_BOOLEAN;
                param.Parameter_Value__c  = 'true';
                param.Parameter_Label__c  = 'Display Record Popovers';
                orgParams.put(param.Parameter_Name__c, param);
        
            }

            if (orgParams.get('ExcludedRecordPopoverTypes') == null)
            {
                List_View_Config_Parameter__c param = new List_View_Config_Parameter__c();
                param.List_View_Config__c = orgWideConfig.Id;
                param.Parameter_Name__c   = 'ExcludedRecordPopoverTypes';
                param.Parameter_Type__c   = ListViewHelper.TYPE_STRING;
                param.Parameter_Value__c  = '';
                param.Parameter_Label__c  = 'Excluded Record Popover Types';
                orgParams.put(param.Parameter_Name__c, param);
        
            }

            HelperDatabase.upsertRecords(orgParams.values(), 'simpli_lv__List_View_Config_Parameter__c');

            //------------------------------------------------------------------------------------
            // Add New, Edit, Clone actions - through v1.63
            //------------------------------------------------------------------------------------
            Boolean hasNew     = false;
            Boolean hasClone   = false;
            Boolean hasEdit    = false;
            Boolean hasDelete  = false;
            Boolean hasEditAll = false;
            Boolean hasHyper   = false;
            Boolean hasMail    = false;
            List_View_Action__c hyperAction = null;
            List_View_Action__c mailAction   = null;
            List<List_View_Action__c> newActions = new List<List_View_Action__c>();
            List<List_View_Action_Parameter__c> newActionParams = new List<List_View_Action_Parameter__c>();
            for (List_View_Action__c action: actions)
            {
                if (action.Label__c == 'New' && action.Apex_Class_Name__c == 'ListViewActionNull')
                {
                    action.Permissions__c = ListViewActionHelper.PERM_CREATE;
                    action.Is_Active__c   = true;
                    hasNew = true;
                } else if (action.Label__c == 'Clone' && action.Apex_Class_Name__c == 'ListViewActionNull')
                {
                    action.Permissions__c = ListViewActionHelper.PERM_CREATE;
                    action.Is_Active__c   = true;
                    hasClone = true;
                } else if (action.Label__c == 'Edit' && action.Apex_Class_Name__c == 'ListViewActionNull')
                {
                    action.Permissions__c = ListViewActionHelper.PERM_EDIT;
                    action.Is_Active__c   = true;
                    hasEdit = true;
                } else if (action.Label__c == 'Edit All' && action.Apex_Class_Name__c == 'ListViewActionNull')
                {
                    action.Permissions__c = ListViewActionHelper.PERM_EDIT;
                    action.Is_Active__c   = true;
                    hasEditAll = true;
                } else if (action.Label__c == 'Delete' && action.Apex_Class_Name__c == 'ListViewActionDelete')
                {
                    action.Permissions__c = ListViewActionHelper.PERM_EDIT;
                    action.Is_Active__c   = true;
                } else if (action.Label__c == 'Update' && action.Apex_Class_Name__c == 'ListViewActionUpdate')
                {
                    action.Permissions__c = ListViewActionHelper.PERM_EDIT;
                    action.Is_Active__c   = true;
                } else if (action.Label__c == 'Set Close Lost' && action.Apex_Class_Name__c == 'ListViewActionOppsClose')
                {
                    action.Permissions__c = ListViewActionHelper.PERM_EDIT;
                    action.Is_Active__c   = true;
                } else if (action.Label__c == 'Go To A Cool App' && action.Apex_Class_Name__c == 'ListViewActionNull')
                {
                    hasHyper = true;
                } else if (action.Label__c == 'Send Email' && action.Apex_Class_Name__c == 'ListViewActionEmail')
                {
                    hasMail = true;
                }
            }
            
            if (!hasHyper)
            {
                hyperAction                     = new List_View_Action__c();
                hyperAction.Apex_Class_Name__c  = 'ListViewActionNull';
                hyperAction.Label__c            = 'Go To A Cool App';
                hyperAction.Object_Type__c      = 'simpli_lv__List_View__c';
                hyperAction.RecordTypeId        = ListViewActionHelper.coreRTId;
                hyperAction.Is_Active__c        = true;

                newActions.add(hyperAction);
            }

            if (!hasMail)
            {
                mailAction                     = new List_View_Action__c();
                mailAction.Apex_Class_Name__c  = 'ListViewActionEmail';
                mailAction.Label__c            = 'Send Email';
                mailAction.Object_Type__c      = 'Contact';
                mailAction.RecordTypeId        = ListViewActionHelper.coreRTId;
                mailAction.Is_Active__c        = true;

                newActions.add(mailAction);
            }

            if (!hasNew)
            {
                List_View_Action__c orgNewAction = new List_View_Action__c();
                orgNewAction.Apex_Class_Name__c  = 'ListViewActionNull';
                orgNewAction.Label__c            = 'New';
                orgNewAction.RecordTypeId        = ListViewActionHelper.coreRTId;
                orgNewAction.Permissions__c      = ListViewActionHelper.PERM_CREATE;
                orgNewAction.Is_Active__c        = true;
        
                newActions.add(orgNewAction);
            }

            if (!hasClone)
            {
                List_View_Action__c orgCloneAction = new List_View_Action__c();
                orgCloneAction.Apex_Class_Name__c  = 'ListViewActionNull';
                orgCloneAction.Label__c            = 'Clone';
                orgCloneAction.RecordTypeId        = ListViewActionHelper.coreRTId;
                orgCloneAction.Permissions__c      = ListViewActionHelper.PERM_CREATE;
                orgCloneAction.Is_Active__c        = true;
        
                newActions.add(orgCloneAction);
            }
    
            if (!hasEdit)
            {
                List_View_Action__c orgEditAction = new List_View_Action__c();
                orgEditAction.Apex_Class_Name__c  = 'ListViewActionNull';
                orgEditAction.Label__c            = 'Edit';
                orgEditAction.RecordTypeId        = ListViewActionHelper.coreRTId;
                orgEditAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;
                orgEditAction.Is_Active__c        = true;
                    
                newActions.add(orgEditAction);
            }

            if (!hasEditAll)
            {
                List_View_Action__c orgEditAllAction = new List_View_Action__c();
                orgEditAllAction.Apex_Class_Name__c  = 'ListViewActionNull';
                orgEditAllAction.Label__c            = 'Edit All';
                orgEditAllAction.RecordTypeId        = ListViewActionHelper.coreRTId;
                orgEditAllAction.Permissions__c      = ListViewActionHelper.PERM_EDIT;
                orgEditAllAction.Is_Active__c        = true;
                            
                newActions.add(orgEditAllAction);
            }

            HelperDatabase.updateRecords(actions, 'simpli_lv__List_View_Action__c');
            HelperDatabase.insertRecords(newActions, 'simpli_lv__List_View_Action__c');

            //Now add parameters
            if (!hasHyper)
            {
                List_View_Action_Parameter__c param = new List_View_Action_Parameter__c();
                param.Field_API_Name__c   = 'URL';
                param.Label__c            = 'URL';
                param.Display_Order__c    = -1;
                param.List_View_Action__c = hyperAction.Id;
                param.Type__c             = ListViewHelper.TYPE_URL;
                param.Default_Value__c    = 'https://appexchange.salesforce.com/appxListingDetail?listingId=a0N3A00000FZ7BDUA1';
        
                newActionParams.add(param);
            }

            if (!hasMail)
            {
                List_View_Action_Parameter__c param = new List_View_Action_Parameter__c();
                param.Field_API_Name__c   = 'Subject';
                param.Label__c            = 'Email Subject';
                param.Display_Order__c    = 1;
                param.List_View_Action__c = mailAction.Id;
                param.Type__c             = ListViewHelper.TYPE_STRING;
                param.Default_Value__c    = '';
        
                newActionParams.add(param);
        
                param                     = new List_View_Action_Parameter__c();
                param.Field_API_Name__c   = 'Body';
                param.Label__c            = 'Email Body';
                param.Display_Order__c    = 2;
                param.List_View_Action__c = mailAction.Id;
                param.Type__c             = ListViewHelper.TYPE_RICH_TEXTAREA;
                param.Default_Value__c    = '';
        
                newActionParams.add(param);
            }

            HelperDatabase.insertRecords(newActionParams, 'simpli_lv__List_View_Action_Parameter__c');

            //send email notifying of the upgrade
            HelperEmail.sendInstallEmail('Upgraded');

		}

	}

}