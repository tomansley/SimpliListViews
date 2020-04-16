trigger ListViewActionParameterTrigger on List_View_Action_Parameter__c (before insert, after insert, before update, after update) 
{

    if (Trigger.isAfter)
    {
        //insert event
        if (Trigger.isInsert)
        {
            ListViewActionParameterTriggerHandler.onAfterInsert(Trigger.newMap);
        
        } else if (Trigger.isUpdate)
        {
            ListViewActionParameterTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
        }
    
    } else if (Trigger.isBefore)
    {
        //insert event
        if (Trigger.isInsert)
        {
            ListViewActionParameterTriggerHandler.onBeforeInsert(Trigger.new);
        
        } else if (Trigger.isUpdate)
        {
            ListViewActionParameterTriggerHandler.onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        }
        
    }

}