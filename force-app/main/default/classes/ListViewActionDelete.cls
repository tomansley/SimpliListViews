/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 02-17-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-08-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewActionDelete  extends ListViewAction {
    
    public ListViewActionDelete() {

    }

    public override String process(List<String> recordIds, Map<String, Object> fieldValues)
	{
        String returnStr = ListViewAction.RESULT_OK + ':';

        try {

            if (recordIds == null || recordIds.size() == 0) return returnStr;

            System.debug(LoggingLevel.DEBUG, 'Record Ids Size   - ' + recordIds.size());
            System.debug(LoggingLevel.DEBUG, 'Record Ids        - ' + recordIds);

            //get the type of object from the provided Ids
            String objType = HelperSchema.getObjectTypeFromId(((String) recordIds[0]).substringBefore(':'));

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
            String message = ListViewAction.RESULT_ERROR + ':Exception during ListViewActionDelete.process() - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageError(message); 
            returnStr = message;
        }
        return returnStr;
    }
    
}