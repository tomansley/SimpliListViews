/**
 * @description       : Class which holds all business logic related to the list view.
 * @author            : tom@ansleyllc.com
 * @last modified on  : 08-09-2024
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-23-2020   tom@ansleyllc.com   Initial Version
 * 2.0   12-15-2021   tom@ansleyllc.com   Pulled out creating types due to different methods for handling types with package names etc.
**/
public with sharing class ListViewBL {

    /**
    * @description Method to validate a list view on insertion
    * @author tom@ansleyllc.com | 10-23-2020 
    * @param newRecords 
    **/
    public static void validate(List<List_View__c> newRecords)
    {
        for (List_View__c lv: newRecords)
        {
            if (lv.RecordTypeId == ListViewHelper.coreRTId)
            {
                if (String.isEmpty(lv.Object_Name__c))
                    lv.addError('Core list views must have an object name');
            
            } else if (lv.RecordTypeId == ListViewHelper.customRTId)
            {
                if (lv.Subtype__c == ListViewHelper.SUBTYPE_MANUAL)
                {
                    Boolean isValid = HelperSchema.isObject(lv.Object_Name__c);
                    if (!isValid)
                        lv.addError('The object name provided is not valid(' + lv.Object_Name__c + '). Provide a valid object API name.');
                }
            }

            if (String.isEmpty(lv.Custom_Apex_Class__c))
            {
                lv.addError('A custom apex class is required and must extend simpli_lv.ListViewAbstract');
            } else {
                try {
                    Type t = HelperSchema.getClassType(lv.Custom_Apex_Class__c);
                    ListViewAbstract lvLogic = (ListViewAbstract) t.newInstance();
                } catch (Exception e) {
                    lv.addError('The custom apex class does not exist or extend ListViewAbstract (' + lv.Custom_Apex_Class__c + ')');
                }

            }

        }
    }

    /**
    * @description Method to set auto-populated fields on the list view on insert
    * @author tom@ansleyllc.com | 10-23-2020 
    * @param newRecords 
    **/
    public static void setFields(List<List_View__c> newRecords)
    {
        Integer index = 0;
        for (List_View__c newRecord: newRecords)
        {
            //API NAME
            if (String.isEmpty(newRecord.API_Name__c))
                newRecord.API_Name__c = newRecord.Label__c.replace(' ', '_').replaceAll('[^a-zA-Z0-9\\s+]', '');
            
            //PRIMARY KEY
            newRecord.Primary_Key__c = ListViewHelper.getPrimaryKey(newRecord);

            //LIST VIEW ID
            if (newRecord.RecordTypeId == ListViewHelper.customRTId)
            {
                 //we have to set the core list view id as it must be unique
                newRecord.Core_ListView_Id__c = String.valueOf(System.now().getTime() + index);
                index++; //index ensures we get a unique value

            } else if (newRecord.RecordTypeId == ListViewHelper.coreRTId) {
                
            }

        }
    }

    /**
    * @description Method to update fields based on provided data.
    * @author tom@ansleyllc.com | 03-26-2021 
    * @param newRecords 
    * @param oldRecords 
    **/
    public static void updateFields(Map<Id, List_View__c> newRecords, Map<Id, List_View__c> oldRecords)
    {
        for (List_View__c newRecord: newRecords.values())
        {
            //UPDATE SOQL QUERY TO UPPER CASE
            if (newRecord.Core_ListView_Query__c != null)
                newRecord.Core_ListView_Query__c = newRecord.Core_ListView_Query__c.replaceAll('(\\r|\\n)+', ' ');
        }

    }

    /**
    * @description Method which sets the core list view Id to the Id of the record IF THE LIST VIEW IS CUSTOM
    *              This has to be done in after insert as we do not have the Id of the record in the before insert.
    * @author tom@ansleyllc.com | 10-23-2020 
    * @param newRecords 
    **/
    public static void updateCoreListViewId(Map<Id, List_View__c> newRecords)
    {
        List<List_View__c> updatedNewRecords = new List<List_View__c>();
        for (List_View__c newRecord: newRecords.values())
        {
            //if we do not have a CORE list view
            if (newRecord.RecordTypeId != ListViewHelper.coreRTId)
            {
                List_View__c lv = new List_View__c(Id = newRecord.Id);
                lv.Core_ListView_Id__c = newRecord.Id;
                updatedNewRecords.add(lv);
            }
        }

        HelperDatabase.updateRecords(updatedNewRecords);
    }

    /**
    * @description Method to create a default config for the list view
    *              if none already exists.
    * @author tom@ansleyllc.com | 10-25-2020 
    * @param newRecords 
    **/
    public static void updateListViewConfigs(Map<Id, List_View__c> newRecords)
    {
        //get all primary keys for list views
        Set<String> primaryKeys = new Set<String>();
        for (List_View__c listView: newRecords.values())
            primaryKeys.add(ListViewHelper.getPrimaryKey(listView));

        //get all configs for list views
        Map<String, List_View_Config__c> configs = ListViewConfigHelper.getListViewConfigs(primaryKeys); 
        
        Map<String, List_View_Config__c> newConfigs = new Map<String, List_View_Config__c>();
        for (List_View__c listView: newRecords.values())
        {
            String primaryKey = ListViewHelper.getPrimaryKey(listView);

            //get list view config
            List_View_Config__c config = configs.get(primaryKey);
            
            //if we have NO config
            if (config == null)
            {

                List_View_Config__c newConfig = new List_View_Config__c();
                newConfig.Name                = listview.API_Name__c;
                newConfig.List_View_Label__c  = listview.Label__c;
                newConfig.List_View_Object__c = listview.Object_Name__c;
                newConfig.Primary_Key__c      = ListViewHelper.getPrimaryKey(listView);

                newConfigs.put(primaryKey, newConfig);

            } 
        
        }

        List<SObject> upsertedConfigs = HelperDatabase.upsertRecords(newConfigs.values() , 'simpli_lv__Primary_Key__c', true);
        Map<String, List_View_Config__c> configsByKey = new Map<String, List_View_Config__c>();
        for (SObject config: upsertedConfigs)
        {
            List_View_Config__c conf = (List_View_Config__c) config;
            configsByKey.put(conf.Primary_Key__c, conf);
        }

        configs.putAll(configsByKey);

        Map<String, List_View_Config_Parameter__c> newParams = new Map<String, List_View_Config_Parameter__c>();
        //now that we have all configs we need to add all parameters
        for (List_View__c listView: newRecords.values())
        {
            String primaryKey = ListViewHelper.getPrimaryKey(listView);

            String objType = null;
            if (listView.RecordTypeId == null || listView.RecordTypeId == ListViewHelper.coreRTId)
                objType = ListViewHelper.CORE_APEX_CLASS;
            else
                objType = listView.Custom_Apex_Class__c;

            //get an apex Type of the object type
            Type t = HelperSchema.getClassType(objType);

            //create a new instance
            ListViewAbstract lvLogic = (ListViewAbstract) t.newInstance();
    
            //set all request information into the apex processing class.
            //lvlogic.setRequestData(listview);

            List<List_View_Config_Parameter__c> params = lvlogic.getConfigParams(configs.get(primaryKey));

            for (List_View_Config_Parameter__c param: params)
                newParams.put(param.Parameter_Name__c, param);

        }

        HelperDatabase.upsertRecords(newParams.values());
        
    }

    public static void deleteListViewConfigs(Map<Id, List_View__c> oldRecords)
    {
        Set<String> primaryKeys = HelperCollection.getStringFieldSet(oldRecords.values(), 'simpli_lv__Primary_Key__c');

        Map<String, List_View_Config__c> configs = ListViewConfigHelper.getListViewConfigs(primaryKeys);
        
        HelperDatabase.deleteRecords(configs.values());

    }
}