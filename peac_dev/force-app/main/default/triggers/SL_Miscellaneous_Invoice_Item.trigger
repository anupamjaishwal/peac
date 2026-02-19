trigger SL_Miscellaneous_Invoice_Item on Miscellaneous_Invoice_Item__c (before insert, before update, after insert, after update) {
    SL_Trigger.dispatchHandler(Miscellaneous_Invoice_Item__c.SObjectType, new SL_MiscInvoiceItemTriggerHandler());
}