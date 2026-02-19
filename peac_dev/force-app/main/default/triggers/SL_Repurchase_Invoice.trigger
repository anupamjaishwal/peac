trigger SL_Repurchase_Invoice on Repurchase_Invoice__c (after update) {
    SL_Trigger.dispatchHandler(Repurchase_Invoice__c.SObjectType, new SL_Repurchase_InvoiceTriggerHandler());
}