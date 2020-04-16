public with sharing class ListViewActionBL {
    
    /*
     * Method to set the primary key of the action based on the following -
     */
    public static void setPrimaryKey(List<List_View_Action__c> newRecords) 
    {
        for (List_View_Action__c newRecord: newRecords)
        {
            newRecord.Primary_Key__c = newRecord.Label__c.deleteWhitespace() + ':' + newRecord.Object_Type__c;
        }
    }

    /*
     * Method to ensure the object type is valid
     */
    public static void validateObjectType(List<List_View_Action__c> newRecords)
    {

        for (List_View_Action__c action: newRecords)
        {
            if (action.Object_Type__c != null && !HelperSchema.isValidSFDCObjectName(action.Object_Type__c))
                throw new ListViewActionException('Invalid object type (' + action.Object_Type__c + ') provided for list view action.');
        }

    }

    public class ListViewActionException extends Exception {}

}