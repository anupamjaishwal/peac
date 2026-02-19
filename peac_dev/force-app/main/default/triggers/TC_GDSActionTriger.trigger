trigger TC_GDSActionTriger on GDS_Action__e (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) TC_GDSActionTrigerHelper.processActions (Trigger.new);
}