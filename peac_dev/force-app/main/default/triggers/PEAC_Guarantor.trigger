trigger PEAC_Guarantor on Guarantor__c (after insert, after update, before update, before insert, before delete) {
    
    if (Trigger.isBefore) {
        TC_TriggerParams params = new TC_TriggerParams (Trigger.oldMap, Trigger.newMap, Trigger.new);
        TC_LockRuleFactory.getLockRule('Guarantor').doCheck (params);
    }
    
    if(DeactivateTriggers__c.getAll().get('PEAC_Guarantor') != null && DeactivateTriggers__c.getAll().get('PEAC_Guarantor').IsDeactived__c) return;
    SL_Trigger.dispatchHandler(Guarantor__c.SObjectType, new PEAC_GuarantorHandler());
}