trigger SL_Opportunity on Opportunity (before insert, before update) {
    SL_Trigger.dispatchHandler(Opportunity.SObjectType, new SL_OpportunityTriggerHandler());
}