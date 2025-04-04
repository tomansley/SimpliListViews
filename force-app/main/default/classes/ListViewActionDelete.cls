/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @group             : 
 * @last modified on  : 12-17-2024
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   09-08-2020   tom@ansleyllc.com   Initial Version
 * 2.0   12-15-2021   tom@ansleyllc.com   Pulled out creating types due to different methods for handling types with package names etc.
 * 3.0   05-31-2024   tom@ansleyllc.com   Moved class to global so that it could be seen when checking for instanceof by SLVE
**/
global with sharing class ListViewActionDelete  extends ListViewAction {
    
    global ListViewActionDelete() {

    }

    /*
        ListViewActionDelete d = new ListViewActionDelete();
        List<String> recordIds = new List<String>();
        recordIds.add('a003h00000C6MhXAAV');
        d.process(recordIds, new Map<String, Object>());
     */
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
            Type t = HelperSchema.getClassType(objType);

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

            System.debug(LoggingLevel.DEBUG, 'About to delete records');
            System.debug(LoggingLevel.DEBUG, 'deletedObjs - ' + deletedObjs);
            HelperDatabase.deleteRecords(deletedObjs.values());

            if (deletedObjs.size() == 1)
                returnStr += '1 record deleted successfully.';
            else
                returnStr += deletedObjs.size() + ' records deleted successfully.';

        } catch (Exception e) {
            String message = ListViewAction.RESULT_ERROR + ':There was an error deleting the ' + objType + '. Please see a system admin.';
            //if (ListViewConfigHelper.isDebuggingOn())
                message += ' Exception during ListViewActionDelete.process() ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
            returnStr = message;
        }
        return returnStr;
    }
    
}