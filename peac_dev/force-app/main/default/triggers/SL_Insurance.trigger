trigger SL_Insurance on Insurance__c (before update, after insert, after update, after delete) {
    SL_Trigger.dispatchHandler(Insurance__c.SObjectType, new SL_InsuranceTriggerHandler());
}