trigger TC_EFApprovedOffer on EF_Approved_Offers__c (before insert, before update, after insert, after update, before delete, after delete) {

    TC_TriggerContext tc = new TC_TriggerContext (Trigger.oldMap, Trigger.newMap, Trigger.new, Trigger.operationType, 'EF_Approved_Offers__c');
    for (String action : TC_TriggerConfiguation.getConfigs (tc)) {
        System.debug ('<<<<< actions: ' + action);
        TC_TriggerActionFactory.getTriggerAction (action).doAction (tc);
    }
}