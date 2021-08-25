/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 08-25-2021
 * @last modified by  : tom.h.ansley@medtronic.com
 * 1.0   07-29-2021   tom.h.ansley@medtronic.com   Initial Version
**/
public with sharing class HelperLimits {

    /*
        System.debug(LoggingLevel.DEBUG, 'Result - ' + HelperLimits.hasReachedLimit('DMLStatements'));
     */
    public static Boolean hasReachedLimit(String limitName)
    {
        switch on limitName {
            when 'AggregateQueries' { return (Limits.getAggregateQueries() + 2) > Limits.getLimitAggregateQueries();}
            when 'AsyncCalls' { return (Limits.getAsyncCalls() + 2) > Limits.getLimitAsyncCalls();}
            when 'CPUTime' { return (Limits.getCpuTime() + 2) > Limits.getLimitCpuTime();}
            when 'DMLRows' { return (Limits.getDmlRows() + 2) > Limits.getLimitDmlRows();}
            when 'DMLStatements' { return (Limits.getDmlStatements() + 2) > Limits.getLimitDmlStatements();}
            when 'EmailInvocations' { return (Limits.getEmailInvocations() + 2) > Limits.getLimitEmailInvocations();}
            when 'FutureCalls' { return (Limits.getFutureCalls() + 2) > Limits.getLimitFutureCalls();}
            when 'HeapSize' { return (Limits.getHeapSize() + 2) > Limits.getLimitHeapSize();}
            when 'Queries' { return (Limits.getQueries() + 2) > Limits.getLimitQueries();}
            when 'QueryRows' { return (Limits.getQueryRows() + 2) > Limits.getLimitQueryRows();}
            when 'QueueableJobs' { return (Limits.getQueueableJobs() + 2) > Limits.getLimitQueueableJobs();}
            when 'SOSLQueries' { return (Limits.getSoslQueries() + 2) > Limits.getLimitSoslQueries();}
            when else { throw new ListViewException('Provided name ' + limitName + ' not supported');}
        }
    }
}