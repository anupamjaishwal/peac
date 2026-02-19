trigger AccountContactRelTrigger on AccountContactRelation (before insert, after update, after delete) {
    
     if(DeactivateTriggers__c.getAll().get('AccountContactRelTrigger') != null && DeactivateTriggers__c.getAll().get('AccountContactRelTrigger').IsDeactived__c) return;
    TC_AccountContactRelTriggerHandler.checkNumberOfACRs(Trigger.new, Trigger.oldMap, Trigger.operationType);
        
}