trigger TC_Guarantor on Guarantor__c (before update, before insert, before delete) {
    
    if (Trigger.isBefore) {
        TC_TriggerParams params = new TC_TriggerParams (Trigger.oldMap, Trigger.newMap, Trigger.new);
        TC_LockRuleFactory.getLockRule('Guarantor').doCheck (params);
    }
}