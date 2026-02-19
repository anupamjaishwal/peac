trigger PEAC_Bank_StatementTrigger on Bank_Statement__c(after insert, after update, before update, before insert, before delete) {

    if(DeactivateTriggers__c.getAll().get('PEAC_Bank_StatementTrigger ') != null && DeactivateTriggers__c.getAll().get('PEAC_Bank_StatementTrigger ').IsDeactived__c) return;
    
    SL_Trigger.dispatchHandler(Bank_Statement__c.SObjectType, new PEAC_BankStatementTriggerHandler());
}