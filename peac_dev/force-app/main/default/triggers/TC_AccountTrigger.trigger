trigger TC_AccountTrigger on Account (before insert, before update, after update, after insert) {

    SL_Trigger.dispatchHandler(Account.SObjectType, new TC_AccountTriggerHandler());
    
}