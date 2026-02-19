trigger SL_Contract_Attachment on Contract_Attachment__c (before insert, before update, after update) {
    SL_Trigger.dispatchHandler(Contract_Attachment__c.SObjectType, new SL_Contract_AttachmentTriggerHandler());
}