trigger SL_Meter_Type on Meter_Type__c (before insert, after insert, before update, before delete, after delete) {
    SL_Trigger.dispatchHandler(Meter_Type__c.SObjectType, new SL_Meter_TypeTriggerHandler());
}