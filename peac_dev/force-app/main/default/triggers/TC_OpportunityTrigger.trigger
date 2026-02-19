trigger TC_OpportunityTrigger on Opportunity (after insert, after update, before insert, before update) {
    
    if(DeactivateTriggers__c.getAll().get('TC_OpportunityTrigger') != null && DeactivateTriggers__c.getAll().get('TC_OpportunityTrigger').IsDeactived__c) return;
    
    SL_Trigger.dispatchHandler(Opportunity.SObjectType, new TC_OpportunityTriggerHandler());
    
}