trigger TC_PaymentTrigger on Payment__c (after update, after insert, before delete) {
	if (Trigger.isAfter && Trigger.isUpdate){
		TC_PaymentTriggerHelper.updateOpportunityStage (Trigger.oldMap, Trigger.newMap);
		TC_PaymentTriggerHelper.updateOpportunityFields(Trigger.old, Trigger.new);
	}

	if (Trigger.isAfter && Trigger.isInsert){
		TC_PaymentTriggerHelper.updateOpportunityFields(null, Trigger.new);
	}

	if (Trigger.isBefore && Trigger.isDelete){
		TC_PaymentTriggerHelper.validateDelete(Trigger.old);
	}
}