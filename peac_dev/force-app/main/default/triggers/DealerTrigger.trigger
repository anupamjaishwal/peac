trigger DealerTrigger on Dealer__c (after insert,before delete, after update, before update, before insert, after delete) {
    // Dealer lock validations
    SL_Trigger.dispatchHandler(Dealer__c.SObjectType, new DealerTriggerHandler());

    /*
    if (Trigger.isBefore) {
        TC_TriggerParams params = new TC_TriggerParams (Trigger.oldMap, Trigger.newMap, Trigger.new);
        TC_LockRuleFactory.getLockRule('Dealer').doCheck (params);
    }
    
    if(trigger.isAfter){
        if(trigger.isInsert){
            DealerTriggerHandler.checkDealerOpty(Trigger.new);
            DealerTriggerHandler.addProgram(Trigger.new);
            //DealerTriggerHandler.solicitEndUser(Trigger.new);
            DealerTriggerHandler.populateFieldsOnOpportunity(Trigger.new);
        }
        if(trigger.isUpdate){
            DealerTriggerHandler.checkDealerOpty(Trigger.new);
            DealerTriggerHandler.populateFieldsOnOpportunity(Trigger.new);
        }

        /* Run credit decision rules
        if (Trigger.isUpdate) {
            TC_CreditDecision.runRules(Trigger.oldMap, Trigger.newMap);
        } else if (Trigger.isInsert) {
            TC_CreditDecision.runRules(null, Trigger.newMap);
        }

    }
    if(trigger.isBefore){
        if(trigger.isDelete){
            DealerTriggerHandler.deleteDealerinfoOnOpportunity(Trigger.old);
            DealerTriggerHandler.deleteFieldsOnOpportunity(Trigger.old);
        }
    }*/ 
}