trigger TC_CheckListWithAttachmentsTrigger on TC_Origination__Checklist_Item_with_Attachments__c (after insert, after update, before insert) {
    
    if(trigger.isAfter && trigger.isUpdate){
        TC_CheckListWithAttachmentsTriggerHelper.UpadateChecklist(Trigger.new, Trigger.oldMap);
    }
    
    TC_TriggerContext tc = new TC_TriggerContext (Trigger.oldMap, Trigger.newMap, Trigger.new, Trigger.operationType, 'ChecklistItem');
    for (String action : TC_TriggerConfiguation.getConfigs (tc)) {
        TC_TriggerActionFactory.getTriggerAction (action).doAction (tc);
    }
        
           
    
}