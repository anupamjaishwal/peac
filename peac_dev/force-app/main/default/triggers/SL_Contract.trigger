trigger SL_Contract on Contract__c (before insert, before update, after insert, after update, after delete) {
    SL_Trigger.dispatchHandler(Contract__c.SObjectType, new SL_ContractTriggerHandler());
}