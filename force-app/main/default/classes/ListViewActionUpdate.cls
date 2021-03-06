/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 09-08-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-08-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewActionUpdate  extends ListViewAction {

    public ListViewActionUpdate() {

    }

    public override String process(List<String> recordIds, Map<String, Object> fieldValues)
    {
        String returnStr = ListViewAction.RESULT_OK + ':';

        try {

            if (recordIds == null || recordIds.size() == 0) return ListViewAction.RESULT_OK;

            System.debug(LoggingLevel.DEBUG, 'Record Ids Size   - ' + recordIds.size());
            System.debug(LoggingLevel.DEBUG, 'Record Ids        - ' + recordIds);
            System.debug(LoggingLevel.DEBUG, 'Field Values Size - ' + fieldValues.size());
            System.debug(LoggingLevel.DEBUG, 'Field Values      - ' + fieldValues);

            //get the type of object from the provided Ids
            String objType = HelperSchema.getObjectTypeFromId((String) recordIds[0]);

            //get an apex Type of the object type
            Type t = Type.forName(objType);

            Map<String, SObject> updatedObjs = new Map<String, SObject>();
            for (String recordId: recordIds)
            {

                //create a new instance
                SObject obj = (SObject) t.newInstance();

                //set the Id
                obj.put('Id', recordId);

                //set all the other fields on the update
                for (String fieldName: fieldValues.keySet())
                {
                    if (fieldValues.get(fieldName) != null && ((String) fieldValues.get(fieldName)) != '')
                        obj.put(fieldName, fieldValues.get(fieldName));
                }
            
                updatedObjs.put(recordId, obj);
            }

            //security review
            for (String fieldName: fieldValues.keySet())
                HelperSchema.checkObjectFieldUpdateable(objType, fieldName);

            HelperDatabase.updateRecords(updatedObjs.values(), objType);

            if (updatedObjs.size() == 1)
                returnStr += '1 record updated successfully.';
            else
                returnStr += updatedObjs.size() + ' records updated successfully.';

        } catch (Exception e) {
            String message = ListViewAction.RESULT_ERROR + ':Exception during ListViewActionUpdate.process() - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageError(message); 
            returnStr = message;
        }
        
        return returnStr;
    }
    
}