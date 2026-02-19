trigger SL_PayeeTrigger on Payee__c (after insert , after update) {
        SL_Trigger.dispatchHandler(Payee__c.SObjectType, new SL_PayeeTriggerHandler());
}