/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 11-22-2021
 * @last modified by  : tom.h.ansley@medtronic.com
**/
public with sharing class ListViewProcessScheduled implements Schedulable {

    public ListViewProcessScheduled() {

    }

	/* IMPLEMENTS SCHEDULABLE INTERFACE */
	public void execute(SchedulableContext sc)
	{
        ListViewProcessBatch job = new ListViewProcessBatch(ListViewProcessBatch.TYPE_PERIOD);
		database.executebatch(job, 40);
	}

}