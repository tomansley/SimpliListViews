/**
 * @description       : Implementation of an action to start flows.
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 08-29-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * Ver   Date         Author                       Modification
 * 1.0   08-29-2021   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class ListViewActionFlow extends ListViewAction {
    
    public static final String RECORD_IDS = 'recordIds';

    private String flowName = null;
    public ListViewActionFlow() {

    }

    public void setFlowName(String flowName)
    {
        this.flowName = flowName;
    }

    public override String process(List<String> recordIds, Map<String, Object> fieldValues)
    {
        String returnStr = ListViewAction.RESULT_OK + ':';
        try {
            if (flowName == null) throw new ListViewException('ListViewActionFlow must have its flow name set before processing');
        
            fieldValues.put(RECORD_IDS, recordIds);
            Flow.Interview flow = Flow.Interview.createInterview(flowName, fieldValues);
            flow.start();

            returnStr += 'Flow successfully started';
        } catch (Exception e) {
            String message = ListViewAction.RESULT_ERROR + ':There was an error starting the flow (' + flowName + '). Please see a system admin.';
            if (ListViewConfigHelper.isDebuggingOn())
                message += ' Exception during ListViewActionFlow.process() ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createUsageError(message); 
            returnStr = message;
        }
        return returnStr;
    }
}