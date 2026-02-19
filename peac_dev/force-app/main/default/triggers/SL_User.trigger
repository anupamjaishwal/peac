trigger SL_User on User (before insert, before update, after insert, after Update) {
    SL_Trigger.dispatchHandler(User.SObjectType, new SL_UserTriggerHandler());
}