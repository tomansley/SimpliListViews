/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 05-11-2022
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-08-2020   tom@ansleyllc.com   Initial Version
 * 2.0   09-08-2020   tom@ansleyllc.com   Fixed bug where record ids were being passed in with row nums. Row nums are now stripped.
 * 3.0   12-15-2021   tom@ansleyllc.com   Removed old methods for checking object accessibility.
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

            //get the type of object from the provided Ids
            objType = HelperSchema.getObjectTypeFromId(recordIds[0]);

            System.debug(LoggingLevel.FINE, 'Record Ids Size   - ' + recordIds.size());
            System.debug(LoggingLevel.FINE, 'Record Ids        - ' + recordIds);
            System.debug(LoggingLevel.FINE, 'Field Values Size - ' + fieldValues.size());
            System.debug(LoggingLevel.FINE, 'Field Values      - ' + fieldValues);
            System.debug(LoggingLevel.FINE, 'Object Type       - ' + objType);

            Map<String, String> strFieldValues = new Map<String, String>();

            for (String fieldName: fieldValues.keySet())
            {
                String fieldValue = (String) fieldValues.get(fieldName);
                if (recordIds.size() == 1 || !String.isEmpty(fieldValue))
                {
                    strFieldValues.put(fieldName, fieldValue); //cast to string
                }
            }

            Map<String, Map<String, String>> rowValues = new Map<String, Map<String, String>>();
            for (String recordId: recordIds)
                rowValues.put(recordId, strFieldValues);

            Map<String,SObject> updatedObjs = ListViewHelper.updateRecords(ListViewHelper.PROC_TYPE_UPDATE, objType, rowValues);
            
            if (updatedObjs.size() == 1)
                returnStr += '1 record updated successfully.';
            else
                returnStr += updatedObjs.size() + ' records updated successfully.';

        } catch (Exception e) {
            String message = ListViewAction.RESULT_ERROR + ':There was an error updating the object of type ' + objType + '. Please see a system admin.';
            if (ListViewConfigHelper.isDebuggingOn())
                message += ' Exception during ListViewActionUpdate.process()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
            returnStr = message;
            System.debug(LoggingLevel.DEBUG, message);
        }
        
        return returnStr;
    }
    
}