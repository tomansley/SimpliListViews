/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 12-03-2021
 * @last modified by  : tom@ansleyllc.com
**/
public class ListViewConfigPicklistListViews extends VisualEditor.DynamicPickList{

    VisualEditor.DesignTimePageContext context;

	public ListViewConfigPicklistListViews(VisualEditor.DesignTimePageContext context) {
	    this.context = context;
        //this.context.pageType
        //this.context.entityName
    }
    
    public override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('', '');
        return defaultValue;
    }
    
    public override VisualEditor.DynamicPickListRows getValues() {

        //Set<String> apiNames = new Set<String>();

        VisualEditor.DynamicPickListRows  configPicklist = new VisualEditor.DynamicPickListRows();
        //we need to add example list views that might not exist yet during install.
        //configPicklist.addRow(new VisualEditor.DataRow('Campaign Member - CampaignMember', 'CampaignMembers'));
        //apiNames.add('CampaignMembers');
        //configPicklist.addRow(new VisualEditor.DataRow('PriceBookEntry - Standard', 'PricebookStandard'));       
        //apiNames.add('PricebookStandard');
        
        Map<Id, List_View__c> listViews = ListViewHelper.getListViewsByType(ListViewHelper.TYPE_ALL, false);

        for (List_View__c listView: listViews.values())
        {
            //if (!apiNames.contains(listView.API_Name__c))
                configPicklist.addRow(new VisualEditor.DataRow(listView.Object_Name__c + ' - ' + listView.Label__c, listView.API_Name__c));
        }
        configPicklist.addRow(new VisualEditor.DataRow('', ''));

        return configPicklist;
    }
}