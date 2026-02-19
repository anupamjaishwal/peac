trigger TC_PayoffTrigger on Payoff__c (after insert, after update, after delete) {
    if (Trigger.isAfter){
        if (Trigger.isDelete) {
            TC_PayoffTriggerHelper.updatePayoffTotalsOnOpp (Trigger.oldMap, null);
            TC_PayoffTriggerHelper.unsetPayoffExistFlagOnOpportunity (Trigger.oldMap);
        }
        if (Trigger.isInsert) {
            TC_PayoffTriggerHelper.updatePayoffTotalsOnOpp (null, Trigger.newMap);
            TC_PayoffTriggerHelper.setPayoffExistFlagOnOpportunity (Trigger.newMap);
        }

        if (Trigger.isUpdate) TC_PayoffTriggerHelper.updatePayoffTotalsOnOpp (Trigger.oldMap, Trigger.newMap);
    } 
}