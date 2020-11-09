/**
 * @description       : 
 * @author            : tom.h.ansley@medtronic.com
 * @last modified on  : 10-23-2020
 * @last modified by  : tom.h.ansley@medtronic.com
 * Modifications Log 
 * Ver   Date         Author                       Modification
 * 1.0   10-23-2020   tom.h.ansley@medtronic.com   Initial Version
**/
trigger ListViewTrigger on List_View__c (before insert, after insert, before update, after update) 
{

    if (Trigger.isAfter)
    {
        //insert event
        if (Trigger.isInsert)
        {
            ListViewTriggerHandler.onAfterInsert(Trigger.newMap);
        
        } else if (Trigger.isUpdate)
        {
            ListViewTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    
    } else if (Trigger.isBefore)
    {
        //insert event
        if (Trigger.isInsert)
        {
            ListViewTriggerHandler.onBeforeInsert(Trigger.new);
        
        } else if (Trigger.isUpdate)
        {
            ListViewTriggerHandler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
        
    }

}