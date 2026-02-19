trigger SL_Contract_Asset on Contract_Asset__c (before insert, before update, after update) {
    SL_Trigger.dispatchHandler(Contract_Asset__c.SObjectType, new SL_Contract_AssetTriggerHandler());
}