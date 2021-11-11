/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-10-2021
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

        VisualEditor.DynamicPickListRows  configPicklist = new VisualEditor.DynamicPickListRows();

        //only get NON-batch configs

        Map<Id, List_View__c> listViews = ListViewHelper.getListViewsByType(ListViewHelper.TYPE_ALL);

        for (List_View__c listView: listViews.values())
        {
            configPicklist.addRow(new VisualEditor.DataRow(listView.Object_Name__c + ' - ' + listView.Label__c, listView.API_Name__c));
        }
        return configPicklist;
    }
}