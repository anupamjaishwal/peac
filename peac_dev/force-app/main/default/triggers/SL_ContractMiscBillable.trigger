trigger SL_ContractMiscBillable on Contract_Misc_Billable__c (after insert, after update, after delete) {
    SL_Trigger.dispatchHandler(Contract__c.SObjectType, new SL_ContractMiscBillableTriggerHandler());
}