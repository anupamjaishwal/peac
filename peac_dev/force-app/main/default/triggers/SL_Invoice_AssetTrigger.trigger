trigger SL_Invoice_AssetTrigger on Invoice_Asset__c (after insert) {
    SL_Trigger.dispatchHandler(Invoice_Asset__c.SObjectType, new SL_InvoiceAssetTriggerHandler());

}