/**
 * @description       : 
 * @author            : tom@ansleyllc.com
 * @last modified on  : 11-08-2021
 * @last modified by  : tom@ansleyllc.com
 * Modifications Log 
 * Ver   Date         Author              Modification
 * 1.0   07-29-2021   tom@ansleyllc.com   Initial Version
 * 2.0   11-04-2021   tom@ansleyllc.com   Added logDebugging() and getCurrentLimitCount() methods
**/
public with sharing class HelperLimits {

    /**
    * @description Method to get the current count for a given limit.
    * @author tom@ansleyllc.com | 11-04-2021 
    * @param limitName 
    * @return Integer 
    **/
    public static Integer getCurrentLimitCount(String limitName)
    {
        Integer count = null;
        switch on limitName {
            when 'AggregateQueries' { count = Limits.getAggregateQueries(); }
            when 'AsyncCalls' { count = Limits.getAsyncCalls(); }
            when 'Callouts' { count = Limits.getCallouts(); }
            when 'CPUTime' { count = Limits.getCpuTime(); }
            when 'DMLRows' { count = Limits.getDmlRows(); }
            when 'EmailInvocations' { count = Limits.getEmailInvocations(); }
            when 'FutureCalls' { count = Limits.getFutureCalls(); }
            when 'HeapSize' { count = Limits.getHeapSize(); }
            when 'Queries' { count = Limits.getQueries(); }
            when 'QueryRows' { count = Limits.getQueryRows(); }
            when 'QueueableJobs' { count = Limits.getQueueableJobs(); }
            when 'SOSLQueries' { count = Limits.getSoslQueries(); }
            when 'DMLStatements' { count = Limits.getDmlStatements(); }
            when else { throw new ListViewException('Provided name ' + limitName + ' not supported'); }
        }

        return count;
        
    }
    
    /*
        System.debug(LoggingLevel.DEBUG, 'Result - ' + HelperLimits.hasReachedLimit('DMLStatements'));
     */
    public static Boolean hasReachedLimit(String limitName)
    {
        switch on limitName {
            when 'AggregateQueries' { return (Limits.getAggregateQueries() + 2) > Limits.getLimitAggregateQueries(); }
            when 'AsyncCalls' { return (Limits.getAsyncCalls() + 2) > Limits.getLimitAsyncCalls(); }
            when 'Callouts' { return (Limits.getCallouts() + 2) > Limits.getLimitCallouts(); }
            when 'CPUTime' { return (Limits.getCpuTime() + 2) > Limits.getLimitCpuTime(); }
            when 'DMLRows' { return (Limits.getDmlRows() + 2) > Limits.getLimitDmlRows(); }
            when 'EmailInvocations' { return (Limits.getEmailInvocations() + 2) > Limits.getLimitEmailInvocations(); }
            when 'FutureCalls' { return (Limits.getFutureCalls() + 2) > Limits.getLimitFutureCalls(); }
            when 'HeapSize' { return (Limits.getHeapSize() + 2) > Limits.getLimitHeapSize(); }
            when 'Queries' { return (Limits.getQueries() + 2) > Limits.getLimitQueries(); }
            when 'QueryRows' { return (Limits.getQueryRows() + 2) > Limits.getLimitQueryRows(); }
            when 'QueueableJobs' { return (Limits.getQueueableJobs() + 2) > Limits.getLimitQueueableJobs(); }
            when 'SOSLQueries' { return (Limits.getSoslQueries() + 2) > Limits.getLimitSoslQueries(); }
            when 'DMLStatements' { return (Limits.getDmlStatements() + 2) > Limits.getLimitDmlStatements(); }
            when else { throw new ListViewException('Provided name ' + limitName + ' not supported'); }
        }
    }

    public static String getLimitsString()
    {
        String debug = '\n\n----------- LIMITS -----------\n';
        debug += 'AggregateQueries - Used ' + Limits.getAggregateQueries() + ' of ' + Limits.getLimitAggregateQueries() + '\n';
        debug += 'AsyncCalls - Used ' + Limits.getAsyncCalls() + ' of ' + Limits.getLimitAsyncCalls() + '\n';
        debug += 'CPUTime - Used ' + Limits.getCpuTime() + ' of ' + Limits.getLimitCpuTime() + '\n';
        debug += 'DMLRows - Used ' + Limits.getDmlRows() + ' of ' + Limits.getLimitDmlRows() + '\n';
        debug += 'EmailInvocations - Used ' + Limits.getEmailInvocations() + ' of ' + Limits.getLimitEmailInvocations() + '\n';
        debug += 'FutureCalls - Used ' + Limits.getFutureCalls() + ' of ' + Limits.getLimitFutureCalls() + '\n';
        debug += 'HeapSize - Used ' + Limits.getHeapSize() + ' of ' + Limits.getLimitHeapSize() + '\n';
        debug += 'Queries - Used ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries() + '\n';
        debug += 'QueryRows - Used ' + Limits.getQueryRows() + ' of ' + Limits.getLimitQueryRows() + '\n';
        debug += 'QueueableJobs - Used ' + Limits.getQueueableJobs() + ' of ' + Limits.getLimitQueueableJobs() + '\n';
        debug += 'SOSLQueries - Used ' + Limits.getSoslQueries() + ' of ' + Limits.getLimitSoslQueries() + '\n';
        debug += 'DMLStatements - Used ' + Limits.getDmlStatements() + ' of ' + Limits.getLimitDmlStatements() + '\n';
        debug+= '------------------------------\n';
        return debug;
    }
}