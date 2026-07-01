trigger NT_ModifierTrigger on Modifier__c (before insert, before update) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        NT_ModifierCycleDetectionHandler.checkForCycles(Trigger.new);
    }
}