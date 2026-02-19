trigger TC_Lead on Lead (before insert, before update, after insert, after update) {
     if(DeactivateTriggers__c.getAll().get('TC_Lead') != null && DeactivateTriggers__c.getAll().get('TC_Lead').IsDeactived__c) return;
    TC_TriggerContext tc = new TC_TriggerContext (Trigger.oldMap, Trigger.newMap, Trigger.new, Trigger.operationType, 'Lead');
    for (String action : TC_TriggerConfiguation.getConfigs (tc)) {
        TC_TriggerActionFactory.getTriggerAction (action).doAction (tc);
    }
    
    if (Trigger.isUpdate && Trigger.isAfter) {
        System.debug ('@@@@@ TC_Lead Trigger');
        TC_LeadTriggerHelper.afterUpdate (Trigger.oldMap, Trigger.newMap);
    }

}