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

            Map<String, Opportunity> closedOpps = new Map<String, Opportunity>();

            for (String recordId: recordIds)
            {

                //create a new instance
                Opportunity opp = new Opportunity();

                //set the Id
                opp.Id = recordId;
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
            String message = ListViewAction.RESULT_ERROR + ':Exception during ListViewActionOppsClose.process() - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageError(message); 
            returnStr = message;
        }
        return returnStr;
    }
    
}