/**
 * @description       : Implementation of an action to start flows.
 * @author            : tom@ansleyllc.com
 * @last modified on  : 10-22-2021
 * @last modified by  : tom@ansleyllc.com
 * Ver   Date         Author                       Modification
 * 1.0   08-29-2021   tom@ansleyllc.com   Initial Version
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
        System.debug(LoggingLevel.FINE, 'Processing ListViewActionFlow with flow name - ' + flowName);
        String returnStr = ListViewAction.RESULT_OK + ':';
        try {
            if (flowName == null) throw new ListViewException('ListViewActionFlow must have its flow name set before processing');
        
            //check if flow has a namespace as if it does we call Flows slightly differently.
            String namespace = null;
            if (flowName.contains('__'))
            {
                namespace = flowName.substringBefore('__');
                flowName = flowName.substringAfter('__');
            }
            fieldValues.put(RECORD_IDS, recordIds);

            Flow.Interview flowInt = null;
            if (String.isEmpty(namespace)) //flow name has NO namespace
                flowInt = Flow.Interview.createInterview(flowName, fieldValues);
            else //flow name HAS namespace
                flowInt = Flow.Interview.createInterview(namespace, flowName, fieldValues);

            flowInt.start();

            returnStr += 'Flow successfully started';
        } catch (Exception e) {
            System.debug(LoggingLevel.FINE, 'Error found - ' + e.getMessage() + ', stack - ' + e.getStackTraceString());
            String message = ListViewAction.RESULT_ERROR + ':There was an error starting the flow (' + flowName + '). Please see a system admin.';
            if (ListViewConfigHelper.isDebuggingOn())
                message += ' Exception during ListViewActionFlow.process() ' + ListViewException.getExtendedString(e);
            ListViewErrorHelper.createUsageError(message); 
            returnStr = message;
        }
        System.debug(LoggingLevel.FINE, 'Finished processing ListViewActionFlow with flow name - ' + flowName);
        return returnStr;
    }
}