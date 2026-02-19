trigger SL_Case on Case (before insert, before update, after insert, after update) {
    SL_Trigger.dispatchHandler(Case.SObjectType, new SL_CaseTriggerHandler());
}