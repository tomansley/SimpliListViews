/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 08-23-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-10-2021   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewConfigDescriptions {

    public static String TYPE_ALL        = 'All';
    public static String TYPE_ORG_WIDE   = 'Org Wide';
    public static String TYPE_COMPONENT  = 'Component';
    public static String TYPE_LIST_VIEW  = 'List View';

    public static Map<String, List_View_Config_Description__mdt> descriptions = null;

    private static void populateDescriptions()
    {
        if (descriptions == null)
        {
            List<SObject> descs = HelperMetadata.getMetaData('List View Config Description');
            descriptions = new Map<String, List_View_Config_Description__mdt>();
            for (SObject dsc: descs)
                descriptions.put(((List_View_Config_Description__mdt) dsc).MasterLabel, (List_View_Config_Description__mdt) dsc);
        }
    }

    public static String getLongDescription(String name)
    {
        populateDescriptions();
        if (descriptions.get(name) != null)
            return descriptions.get(name).Long_Description__c;
        else 
            return '';
    }

    public static List<List_View_Config_Description__mdt> getDescriptions(String type)
    {
        populateDescriptions();
        List<List_View_Config_Description__mdt> descs = new List<List_View_Config_Description__mdt>();
        for (List_View_Config_Description__mdt dsc: descriptions.values())
        {
            if (dsc.Type__c.contains(type) || type == TYPE_ALL)
                descs.add(dsc);
        }

        return descs;
    }

}