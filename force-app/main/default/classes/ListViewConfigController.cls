/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 08-11-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   08-11-2021   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewConfigController {

    @AuraEnabled(cacheable=true)
    public static List<ConfigDescription> getOrgWideDescriptions()
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewConfigController.getOrgWideDescriptions');

        return createConfigDescriptions(ListViewConfigDescriptions.TYPE_ORG_WIDE);
    }

    @AuraEnabled(cacheable=true)
    public static List<ConfigDescription> getComponentDescriptions()
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewConfigController.getComponentDescriptions');

        return createConfigDescriptions(ListViewConfigDescriptions.TYPE_COMPONENT);
    }

    @AuraEnabled(cacheable=true)
    public static List<ConfigDescription> getListViewDescriptions()
    {
        System.debug(LoggingLevel.DEBUG, 'Starting ListViewConfigController.getListViewDescriptions');

        return createConfigDescriptions(ListViewConfigDescriptions.TYPE_LIST_VIEW);
    }

    private static List<ConfigDescription> createConfigDescriptions(String type)
    {
        List<ConfigDescription> confDescs = new List<ConfigDescription>();

        List<List_View_Config_Description__mdt> descs = ListViewConfigDescriptions.getDescriptions(type);
        
        for (List_View_Config_Description__mdt dsc: descs)
            confDescs.add(new ConfigDescription(dsc));

        confDescs.sort();
        
        return confDescs;
    }

    public class ConfigDescription implements Comparable
    {

        public ConfigDescription(List_View_Config_Description__mdt description)
        {
            this.name = description.MasterLabel;
            this.label = description.Display_Name__c;
            this.lwcLabel = description.LWC_Component_Label__c;
            this.type     = description.Type__c;
            this.description = description.Long_Description__c;
        }

        @AuraEnabled
        public String name { get;set; }
        @AuraEnabled
        public String label { get;set; }
        @AuraEnabled
        public String description { get;set; }
        @AuraEnabled
        public String lwcLabel { get;set; }
        @AuraEnabled
        public String type { get;set; }

        public Integer compareTo(Object compareTo) {
            ConfigDescription desc2 = (ConfigDescription) compareTo;
            return label.compareTo(desc2.label);
        }

    }
}