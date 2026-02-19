/**
 * Created by andrewmayer on 9/28/20.
 */

trigger TC_ContactTrigger on Contact (before insert, before update, before delete, after insert, after update, after delete) {

    if(DeactivateTriggers__c.getAll().get('TC_ContactTrigger') != null && DeactivateTriggers__c.getAll().get('TC_ContactTrigger').IsDeactived__c) return;
   

    TC_TriggerContext tc = new TC_TriggerContext (Trigger.oldMap, Trigger.newMap, Trigger.new, Trigger.operationType, 'Contact');
    for (String action : TC_TriggerConfiguation.getConfigs (tc)) {
        TC_TriggerActionFactory.getTriggerAction (action).doAction (tc);
    }
}