/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 01-11-2022
 * @last modified by  : tom@ansleyllc.com
 * Ver   Date         Author                       Modification
 * 1.0   08-19-2021   tom@ansleyllc.com   Initial Version
 * 2.0   12-15-2021   tom@ansleyllc.com   Removed old methods for checking object accessibility.

**/
public with sharing class ListViewActionEmail  extends ListViewAction {
    
    private static String KEY_API_FIELD_NAME = 'API Field Name';
    private static String KEY_SUBJECT        = 'Subject';
    private static String KEY_BODY           = 'Body';

    public ListViewActionEmail() {

    }

    public override String process(List<String> recordIds, Map<String, Object> fieldValues)
	{
        System.debug(LoggingLevel.FINE, 'Starting ListViewActionEmail.process()');
        String returnStr = ListViewAction.RESULT_OK + ':';

        try {

            if (recordIds == null || recordIds.size() == 0) return returnStr;

            //get the type of object from the provided Ids
            String objType = HelperSchema.getObjectTypeFromId(recordIds[0]);

            System.debug(LoggingLevel.FINE, 'Record Ids Size   - ' + recordIds.size());
            System.debug(LoggingLevel.FINE, 'Record Ids        - ' + recordIds);
            System.debug(LoggingLevel.FINE, 'Object Type       - ' + objType);
            System.debug(LoggingLevel.FINE, 'Field Values');
            for (String key: fieldValues.keySet())
                System.debug(LoggingLevel.FINE, '    ' + key + ' - ' + fieldValues.get(key));

            //check if we have an email field to use
            String fieldName = '';
            String apiFieldName = '';
            if (fieldValues.get(KEY_API_FIELD_NAME) != null)
            {
                apiFieldName = (String) fieldValues.get(KEY_API_FIELD_NAME);
                if (HelperSchema.isValidSFDCFieldName(objType, fieldName))
                    fieldName = apiFieldName;
            } else if (HelperSchema.isValidSFDCFieldName(objType, 'Email'))
            {
                fieldName = 'Email';
            } else  if (HelperSchema.isValidSFDCFieldName(objType, 'Email__c'))
            {
                fieldName = 'Email__c';
            }

            //if we are good with a field name
            if (!String.isEmpty(fieldName)) 
            {

                //1. Create SOQL statement
                String soql = 'SELECT ' + String.escapeSingleQuotes(fieldName) + ' FROM ' + String.escapeSingleQuotes(objType) + ' WHERE Id IN :recordIds';

                SObjectAccessDecision dec = Security.stripInaccessible(AccessType.READABLE, database.query(soql));
        
                List<sObject> objs = dec.getRecords();

                //loop through data getting emails
                List<String> toAddresses = new List<String>();
                for (SObject obj: objs)
                {

                    String email = (String) obj.get(fieldName);

                    if (!String.isEmpty(email))
                    {
                        toAddresses.add(email);
                    }

                }

                Boolean isSent = HelperEmail.sendEmails(toAddresses, (String) fieldValues.get(KEY_BODY), (String) fieldValues.get(KEY_SUBJECT));

                if (isSent)
                    returnStr += 'All emails successfully sent for ' + HelperSchema.getObjectPluralName(objType) + ' using ' + HelperSchema.getFieldLabel(objType, fieldName) + ' field.';
                else
                    returnStr = ListViewAction.RESULT_ERROR + ':There was a problem sending the emails for ' + HelperSchema.getObjectPluralName(objType) + ' using ' + HelperSchema.getFieldLabel(objType, fieldName) + ' field.';
            
            } else if (!String.isEmpty(apiFieldName)) {
                returnStr = 'Could not find the provided email field (' + apiFieldName + ') for the object (' + objType + ') the action is being performed against.';
            } else {
                returnStr = 'Could not find an email field for the provided records. Configure the Send Email action with a chosen email field or ensure the object the action is being performed against (' + objType + ') has either an "Email" or "Email__c" field';
            }

        } catch (Exception e) {
            String message = ListViewAction.RESULT_ERROR + ':There was an error sending the emails. Please see a system admin.';
            if (ListViewConfigHelper.isDebuggingOn())
                message += ' Exception during ListViewActionEmail.process()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createFutureUsageError(message); 
            returnStr = message;
        }
        System.debug(LoggingLevel.FINE, 'Finished ListViewActionEmail.process() with status - ' + returnStr);
        
        return returnStr;
    }
    
}