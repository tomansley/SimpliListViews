/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   09-08-2020   tom@ansleyllc.com   Initial Version
**/
public with sharing class ListViewActionDelete  extends ListViewAction {
    
    public ListViewActionDelete() {

    }

    public override String process(List<String> recordIds, Map<String, Object> fieldValues)
	{
        String returnStr = ListViewAction.RESULT_OK + ':';
        String objType = '';
        try {

            if (recordIds == null || recordIds.size() == 0) return returnStr;

            System.debug(LoggingLevel.DEBUG, 'Record Ids Size   - ' + recordIds.size());
            System.debug(LoggingLevel.DEBUG, 'Record Ids        - ' + recordIds);

            //get the type of object from the provided Ids
            objType = HelperSchema.getObjectTypeFromId(recordIds[0]);

            //get an apex Type of the object type
            Type t = Type.forName(objType);

            //we create a map of deleted objs so that duplicates do not break anything!
            Map<String, SObject> deletedObjs = new Map<String, SObject>();
            for (String recordId: recordIds)
            {

                //create a new instance
                SObject obj = (SObject) t.newInstance();

                //set the Id
                obj.put('Id', recordId.substringBefore(':'));

                deletedObjs.put(recordId.substringBefore(':'), obj);
            }

            HelperDatabase.deleteRecords(deletedObjs.values(), objType);

            if (deletedObjs.size() == 1)
                returnStr += '1 record deleted successfully.';
            else
                returnStr += deletedObjs.size() + ' records deleted successfully.';

        } catch (Exception e) {
            String message = ListViewAction.RESULT_ERROR + ':There was an error deleting the ' + HelperSchema.getObjectPluralName(objType) + '. Please see a system admin.';
            if (ListViewConfigHelper.isDebuggingOn())
                message += ' Exception during ListViewActionDelete.process() ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createUsageError(message); 
            returnStr = message;
        }
        return returnStr;
    }
    
}