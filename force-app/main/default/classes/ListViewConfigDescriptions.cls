/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 04-05-2022
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-10-2021   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewConfigDescriptions {

    public static String TYPE_ALL        = 'All';
    public static String TYPE_ORG_WIDE   = 'Org Wide';
    public static String TYPE_COMPONENT  = 'Component';
    public static String TYPE_LIST_VIEW  = 'List View';

    public static String getLongDescriptionCache(String name)
    {
        List<List_View_Config_Description__mdt> descs = (List<List_View_Config_Description__mdt>) HelperMetadata.getCustomMetaData('List View Config Description');
        for (List_View_Config_Description__mdt dsc: descs)
        {
            if (name == dsc.MasterLabel)
                return dsc.Long_Description__c;
        }
        return '';
    }

    public static String getLongDescription(String name)
    {
        return CacheConfigDescription.get(name);
    }
    
    public static List<List_View_Config_Description__mdt> getDescriptionsCache(String type)
    {
        List<List_View_Config_Description__mdt> response = new List<List_View_Config_Description__mdt>();

        List<List_View_Config_Description__mdt> descs = (List<List_View_Config_Description__mdt>) HelperMetadata.getCustomMetaData('List View Config Description');
        for (List_View_Config_Description__mdt dsc: descs)
        {
            if (dsc.Type__c.contains(type) || type == ListViewConfigDescriptions.TYPE_ALL)
                response.add(dsc);
        }
        return response;
    }

    public static List<List_View_Config_Description__mdt> getDescriptions(String type)
    {
        return CacheConfigDescriptions.get(type);
    }

}