/**
 * @description       : Helper class for list view user configuration
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 10-20-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-08-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewUserConfigHelper {
    
    public static Map<String, Map<String, List_View_User_Config__c>> currentUsersConfigs = null;

    /*
     * Method which retrieves, for the currently running user, all list view configuration
     * for the user. The returned map has a key which is the component name. Each value for
     * a given component name holds a map where the key is the name of the config and the
     * value is the config record itself. 
     */
    public static Map<String, Map<String, List_View_User_Config__c>> getCurrentUserConfigs() 
    {
        HelperSchema.checkListViewUserConfigsAccessible();

        List<List_View_User_Config__c> configs = [SELECT Ltn_Component_Name__c,
                                                         Name__c,
                                                         Primary_Key__c,
                                                         User__c,
                                                         Value__c
                                                  FROM List_View_User_Config__c
                                                  WHERE User__c = :UserInfo.getUserId()];

        currentUsersConfigs = new Map<String, Map<String, List_View_User_Config__c>>();
        for (List_View_User_Config__c config: configs)
        {
            Map<String, List_View_User_Config__c> compConfigs = currentUsersConfigs.get(config.Ltn_Component_Name__c);
            if (compConfigs == null)
            {
                compConfigs = new Map<String, List_View_User_Config__c>();
                currentUsersConfigs.put(config.Ltn_Component_Name__c, compConfigs);
            }
            compConfigs.put(config.Name__c, config);
        }

        return currentUsersConfigs;
    }

    /*
     * Method which, given a component name and a config name returns the associated value.
     */
    public static List_View_User_Config__c getCurrentUserConfig(String compName, String configName)
    {
        if (currentUsersConfigs == null)
            getCurrentUserConfigs();

        Map<String, List_View_User_Config__c> compConfig = currentUsersConfigs.get(compName);

        if (compConfig == null) return null;

        List_View_User_Config__c config = compConfig.get(configName);

        if (config == null) return null;

        return config;
    }

    /*
     * Method which, given a component name returns all the CURRENT USERS sort configuration for the component
     */
    public static List<List_View_User_Config__c> getCurrentUserCompSortConfigs(String compName)
    {
        if (currentUsersConfigs == null)
            getCurrentUserConfigs();

        Map<String, List_View_User_Config__c> compConfig = currentUsersConfigs.get(compName);

        if (compConfig == null) return new List<List_View_User_Config__c>();

        List<List_View_User_Config__c> sortConfigs = new List<List_View_User_Config__c>();
        for (List_View_User_Config__c config: compConfig.values())
        {
            if (config.Name__c.contains('sortOrder'))
                sortConfigs.add(config);
        }

        return sortConfigs;
    }

    /*
     * Method which, given a component name returns all associated configs.
     */
    public static Map<String, List_View_User_Config__c> getCurrentUserCompConfig(String compName)
    {
        if (currentUsersConfigs == null)
            getCurrentUserConfigs();

        Map<String, List_View_User_Config__c> compConfig = currentUsersConfigs.get(compName);

        if (compConfig == null) return new Map<String, List_View_User_Config__c>();

        return compConfig;
    }

    @future
    public static void updateSortConfigValue(String compName, String sortStr, String objectName, String listviewName)
    {
        updateCurrentUserConfigValue(compName, 'sortOrder:' + objectName + ':' + listviewName, sortStr);
    }

    /*
     * Method to update a config value for a given component for the current user.
     */
    public static void updateCurrentUserConfigValue(String compName, String configName, String value)
    {
        if (currentUsersConfigs == null)
            getCurrentUserConfigs();

        List_View_User_Config__c config = getCurrentUserConfig(compName, configName);

        if (value != null && value != '')
        {
            if (config == null)
            {
                config = new List_View_User_Config__c();
                config.Ltn_Component_Name__c = compName;
                config.Name__c               = configName;
                config.User__c               = UserInfo.getUserId();
                config.Value__c              = value;
                config.Primary_Key__c        = compName + ':' + configName + ':' + config.User__c;
            } else {
                config.Value__c = value;
            }
            HelperDatabase.upsertRecord(config, 'simpli_lv__List_View_User_Config__c', 'simpli_lv__Primary_Key__c');

            //update the current users config
            Map<String, List_View_User_Config__c> compConfigs = currentUsersConfigs.get(config.Ltn_Component_Name__c);
            if (compConfigs == null)
            {
                compConfigs = new Map<String, List_View_User_Config__c>();
                currentUsersConfigs.put(config.Ltn_Component_Name__c, compConfigs);
            }
            compConfigs.put(config.Name__c, config);

        } else {
            if (config != null)
                HelperDatabase.deleteRecord(config, 'simpli_lv__List_View_User_Config__c');
        }
    }
}