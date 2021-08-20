/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @group             : 
 * @last modified on  : 08-20-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   09-08-2020   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewActionOppsClose extends ListViewAction {
    
    public ListViewActionOppsClose() {

    }

    public override String process(List<String> recordIds, Map<String, Object> fieldValues)
	{
        String returnStr = ListViewAction.RESULT_OK + ':';

        try {

            if (recordIds == null || recordIds.size() == 0) return returnStr;

            System.debug(LoggingLevel.DEBUG, 'Record Ids Size   - ' + recordIds.size());
            System.debug(LoggingLevel.DEBUG, 'Record Ids        - ' + recordIds);
            System.debug(LoggingLevel.DEBUG, 'Field Values Size - ' + fieldValues.size());
            System.debug(LoggingLevel.DEBUG, 'Field Values      - ' + fieldValues);

            Map<String, Opportunity> closedOpps = new Map<String, Opportunity>();

            for (String recordId: recordIds)
            {

                //create a new instance
                Opportunity opp = new Opportunity();

                //set the Id
                opp.Id = ((String) recordId).substringBefore(':');
                opp.CloseDate = System.today();
                opp.StageName = 'Closed Lost';

                closedOpps.put(recordId, opp);
            }

            //security review
            HelperDatabase.upsertRecords(closedOpps.values(), 'Opportunity');

            if (closedOpps.size() == 1)
                returnStr += '1 opportunity updated successfully.';
            else
                returnStr += closedOpps.size() + ' opportunities updated successfully.';


        } catch (Exception e) {
            String message = ListViewAction.RESULT_ERROR + ':There was an error updating the opportunities. Please see a system admin.';
            if (ListViewConfigHelper.isDebuggingOn())
                message += ' Exception during ListViewActionOppsClose.process()  ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createUsageError(message); 
            returnStr = message;
        }
        return returnStr;
    }
    
}