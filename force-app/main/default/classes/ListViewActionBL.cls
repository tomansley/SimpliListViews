/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 03-24-2025
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   10-31-2020   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewActionBL {
    
    private static final Set<String> bogusClassNames = new Set<String>{'ListViewActionNull', 'ListViewActionLWC', 'ListViewActionPDF', 'ListViewActionMassCreate', 'ListViewActionCreate', 'ListViewActionClone', 'ListViewActionEdit', 'ListViewActionEditAll', 'ListViewActionHyperLink' };
    /*
     * Method to set the primary key of the action based on the following -
     */
    public static void setPrimaryKey(List<List_View_Action__c> newRecords) 
    {
        for (List_View_Action__c newRecord: newRecords)
        {
            newRecord.Primary_Key__c = ListViewActionHelper.getPrimaryKey(newRecord);
            System.debug('Action pkey - ' + newRecord.Primary_Key__c);
        }
    }

    /*
     * Method to validate the action
     */
    public static void validate(List<List_View_Action__c> newRecords)
    {

        for (List_View_Action__c action: newRecords)
        {
            if (action.Object_Type__c != null && !HelperSchema.isValidSFDCObjectName(action.Object_Type__c))
                action.addError('Invalid object type (' + action.Object_Type__c + ') provided for list view action.');

            if (action.RecordTypeId == ListViewActionHelper.customRTId && action.Subtype__c == null)
                action.addError('Custom actions must have a subtype.');
            
            if (action.RecordTypeId == ListViewActionHelper.coreRTId && action.Subtype__c != null)
                action.addError('Core actions cannot have a subtype.');

            if (action.RecordTypeId == ListViewActionHelper.customRTId 
                    && action.Subtype__c == 'Manual' 
                    && action.Object_Type__c == null 
                    && action.Is_Hyperlink__c == false 
                    && action.Is_Flow__c == false)
                action.addError('Custom actions of subtype "Manual" must have an object type if they are not of type hyperlink or flow.');

            if (action.RecordTypeId == ListViewActionHelper.coreRTId 
                    && action.Apex_Class_Name__c == 'ListViewActionMassCreate'
                    && !String.isEmpty(action.Mass_Create_List_View_Name__c)
                    && String.isEmpty(action.Object_Type__c))
                action.addError('For mass create actions, if using a specific list view name the object type must be provided.');

            if (String.isEmpty(action.Apex_Class_Name__c))
            {
                action.addError('An apex class is required and must extend simpli_lv.ListViewAction');
            } else {
                
                //CLASS AND CONSTRUCTOR MUST BE GLOBAL FOR THIS TO WORK
                if (!bogusClassNames.contains(action.Apex_Class_Name__c))
                {
                    try {
                        Type t = HelperSchema.getClassType(action.Apex_Class_Name__c);
                        Object lvLogic = t.newInstance();

                        if (!(lvLogic instanceof simpli_lv.ListViewAction))
                            action.addError('The apex class does not extend simpli_lv.ListViewAction (' + action.Apex_Class_Name__c + ')');

                    } catch (Exception e) {
                        System.debug(LoggingLevel.DEBUG, ListViewException.getExtendedString(e));
                        action.addError('The apex class cannot be found (' + action.Apex_Class_Name__c + ')');
                    }
                }
            }
    
        }

    }

}