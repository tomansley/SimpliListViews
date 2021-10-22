/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-08-2020   tom@ansleyllc.com   Initial Version
 * 2.0   09-08-2020   tom@ansleyllc.com   Fixed bug where record ids were being passed in with row nums. Row nums are now stripped.
**/
public with sharing class ListViewActionUpdate  extends ListViewAction {

    public ListViewActionUpdate() {

    }

    public override String process(List<String> recordIds, Map<String, Object> fieldValues)
    {
        String returnStr = ListViewAction.RESULT_OK + ':';
        String objType = '';
        try {

            if (recordIds == null || recordIds.size() == 0) return ListViewAction.RESULT_OK;

            System.debug(LoggingLevel.FINE, 'Record Ids Size   - ' + recordIds.size());
            System.debug(LoggingLevel.FINE, 'Record Ids        - ' + recordIds);
            System.debug(LoggingLevel.FINE, 'Field Values Size - ' + fieldValues.size());
            System.debug(LoggingLevel.FINE, 'Field Values      - ' + fieldValues);

            //get the type of object from the provided Ids
            objType = HelperSchema.getObjectTypeFromId(recordIds[0]);

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
            String message = ListViewAction.RESULT_ERROR + ':There was an error updating the ' + HelperSchema.getObjectPluralName(objType) + '. Please see a system admin.';
            if (ListViewConfigHelper.isDebuggingOn())
                message += ' Exception during ListViewActionUpdate.process()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createUsageError(message); 
            returnStr = message;
        }
        
        return returnStr;
    }
    
}