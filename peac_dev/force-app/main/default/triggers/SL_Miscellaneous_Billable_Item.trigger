trigger SL_Miscellaneous_Billable_Item on Miscellaneous_Billable_Item__c (before insert, before update, after insert, after update) {
    SL_Trigger.dispatchHandler(Miscellaneous_Billable_Item__c.SObjectType, new SL_MiscBillableItemTriggerHandler());
}