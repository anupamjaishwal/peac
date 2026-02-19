trigger TC_VariablePaymentTrigger on Variable_Payment__c (after insert, after update, after delete, after undelete) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            TC_VariablePaymentTriggerHelper.updateGrossContractOnOpp (null, Trigger.newMap);
            
            TC_VariablePaymentTriggerHelper.updateVariablePaymentCheckBoxOnOpp(trigger.new);
        } else if (Trigger.isUpdate) {
            TC_VariablePaymentTriggerHelper.updateGrossContractOnOpp (Trigger.oldMap, Trigger.newMap);
            TC_VariablePaymentTriggerHelper.updateVariablePaymentCheckBoxOnOpp(trigger.new);
            TC_VariablePaymentTriggerHelper.updateVariablePaymentCheckBoxOnOppDelete(trigger.old);
        } else if (Trigger.isDelete) {
            TC_VariablePaymentTriggerHelper.updateGrossContractOnOpp (Trigger.oldMap, null);
            TC_VariablePaymentTriggerHelper.updateVariablePaymentCheckBoxOnOppDelete(trigger.old);
        }
        
        if(trigger.isUndelete){
            TC_VariablePaymentTriggerHelper.updateVariablePaymentCheckBoxOnOpp(trigger.new);
        }
    }
}