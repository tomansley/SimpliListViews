public with sharing class ListViewActionOppsClose extends ListViewAction {
    
    public ListViewActionOppsClose() {

    }

    public override String process(List<String> recordIds, Map<String, Object> fieldValues)
	{
        String returnStr = ListViewAction.RESULT_OK;

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
            HelperSchema.checkObjectUpdateable('Opportunity');

            upsert closedOpps.values();

        } catch (Exception e) {
            String message = 'Exception during ListViewActionOppsClose.process() - ' + e.getMessage() + ' - line: ' + e.getLineNumber() + ' - ' + e.getStackTraceString();
            ListViewErrorHelper.createUsageError(message); 
            returnStr = e.getMessage();
        }
        return returnStr;
    }
    
}