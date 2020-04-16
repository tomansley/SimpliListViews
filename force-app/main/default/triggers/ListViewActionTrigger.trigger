trigger ListViewActionTrigger on List_View_Action__c (before insert, after insert, before update, after update) 
{

    if (Trigger.isAfter)
    {
        //insert event
        if (Trigger.isInsert)
        {
            ListViewActionTriggerHandler.onAfterInsert(Trigger.newMap);
        
        } else if (Trigger.isUpdate)
        {
            ListViewActionTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    
    } else if (Trigger.isBefore)
    {
        //insert event
        if (Trigger.isInsert)
        {
            ListViewActionTriggerHandler.onBeforeInsert(Trigger.new);
        
        } else if (Trigger.isUpdate)
        {
            ListViewActionTriggerHandler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
        
    }

}