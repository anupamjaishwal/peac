trigger NT_QuoteTrigger on Quote (after insert, after update) {
    NT_QuoteTriggerHandler handler = new NT_QuoteTriggerHandler();

    if (Trigger.isAfter && Trigger.isInsert) {
        handler.afterInsert(Trigger.newMap);
    } else if (Trigger.isAfter && Trigger.isUpdate) {
        handler.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
}