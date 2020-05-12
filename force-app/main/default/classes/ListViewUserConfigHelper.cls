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
            upsert config config.Primary_Key__c;
        
        } else {
            if (config != null)
                delete config;
        }
    }
}