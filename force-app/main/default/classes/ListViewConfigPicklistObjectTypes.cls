/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 12-11-2021
 * @last modified by  : tom.h.ansley@medtronic.com
**/
public class ListViewConfigPicklistObjectTypes extends VisualEditor.DynamicPickList{

    VisualEditor.DesignTimePageContext context;

	public ListViewConfigPicklistObjectTypes(VisualEditor.DesignTimePageContext context) {
	    this.context = context;
        //this.context.pageType
        //this.context.entityName
    }
    
    public override VisualEditor.DataRow getDefaultValue(){
        VisualEditor.DataRow defaultValue = new VisualEditor.DataRow('Account', 'Account');
        return defaultValue;
    }
    
    public override VisualEditor.DynamicPickListRows getValues() {

        VisualEditor.DynamicPickListRows  configPicklist = new VisualEditor.DynamicPickListRows();

        Map<String, String> objectNamesByAPI = HelperSchema.getAllObjectNames();

        List<String> objectAPINames = new List<String>(objectNamesByAPI.keySet());
        objectAPINames.sort();

        for (String apiName: objectAPINames)
            configPicklist.addRow(new VisualEditor.DataRow(apiName, apiName));

        return configPicklist;
    }

}