trigger PEAC_Bank_InformationTrigger on Financial_Bank_Information__c (after insert, after update, before update, before insert, before delete, after delete) {

    if(DeactivateTriggers__c.getAll().get('PEAC_Bank_InformationTrigger') != null && DeactivateTriggers__c.getAll().get('PEAC_Bank_InformationTrigger').IsDeactived__c) return;
    
    SL_Trigger.dispatchHandler(Financial_Bank_Information__c.SObjectType, new PEAC_BankInformationTriggerHandler());
}