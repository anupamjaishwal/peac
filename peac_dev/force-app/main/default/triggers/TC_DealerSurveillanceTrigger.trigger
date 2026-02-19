trigger TC_DealerSurveillanceTrigger on Dealer_Surveillance__c (before insert, before update, after update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            TC_DealerSurveillanceTriggerHelper.checkForNonCompleteSurveillances (Trigger.new);
            TC_DealerSurveillanceTriggerHelper.stampFields (Trigger.new);
        }
        TC_DealerSurveillanceTriggerHelper.checkModels(Trigger.new);
    }

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            TC_DealerSurveillanceTriggerHelper.completeSUV(Trigger.newMap,  Trigger.oldMap);
        }
    }
}