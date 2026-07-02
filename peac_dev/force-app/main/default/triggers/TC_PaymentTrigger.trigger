trigger TC_PaymentTrigger on Payment__c (after update, after insert, before delete) {
	if (Trigger.isAfter && Trigger.isUpdate){
		TC_PaymentTriggerHelper.updateOpportunityStage (Trigger.oldMap, Trigger.newMap);
		TC_PaymentTriggerHelper.updateOpportunityFields(Trigger.old, Trigger.new);
        /*SAL-6227*/
        TC_PaymentTriggerHelper.deleteAssociatedBIIsPaymentMovedToVoidCancelled(Trigger.oldMap, Trigger.newMap);
	}

	if (Trigger.isAfter && Trigger.isInsert){
		TC_PaymentTriggerHelper.updateOpportunityFields(null, Trigger.new);
	}

	if (Trigger.isBefore && Trigger.isDelete){
		TC_PaymentTriggerHelper.validateDelete(Trigger.old);
        /*SAL-6227*/
        TC_PaymentTriggerHelper.deleteAssociatedBIIsOnOpportunity(Trigger.old);
	}
}