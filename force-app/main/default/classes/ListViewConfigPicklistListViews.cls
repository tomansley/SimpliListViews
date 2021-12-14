/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 12-11-2021
 * @last modified by  : tom.h.ansley@medtronic.com
**/
public class ListViewConfigPicklistListViews extends VisualEditor.DynamicPickList{

    VisualEditor.DesignTimePageContext context;

	public ListViewConfigPicklistListViews(VisualEditor.DesignTimePageContext context) {
	    this.context = context;
        //this.context.pageType
        //this.context.entityName
    }
    
    public override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow(null, null);
        return defaultValue;
    }
    
    public override VisualEditor.DynamicPickListRows getValues() {

        VisualEditor.DynamicPickListRows  configPicklist = new VisualEditor.DynamicPickListRows();
        
        Map<Id, List_View__c> listViews = ListViewHelper.getListViewsByType(ListViewHelper.TYPE_ALL, false);

        for (List_View__c listView: listViews.values())
            configPicklist.addRow(new VisualEditor.DataRow(listView.Object_Name__c + ' - ' + listView.Label__c, listView.API_Name__c));

        return configPicklist;
    }

}