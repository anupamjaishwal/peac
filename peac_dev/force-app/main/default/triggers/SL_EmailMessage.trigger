trigger SL_EmailMessage on EmailMessage (before insert, before update, after insert, after update) {
    SL_Trigger.dispatchHandler(EmailMessage.SObjectType, new SL_EmailMessageTriggerHandler());
}