/*
 * Object which is used by the lightning app designer to allow the user to set default values on SImpli UI components.
 * This particular picklist returns ALL configs that are not batch and do not have a parent.
 */
public class ListViewConfigPicklist extends VisualEditor.DynamicPickList{

    VisualEditor.DesignTimePageContext context;

	public ListViewConfigPicklist(VisualEditor.DesignTimePageContext context) {
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