trigger FirstAssetOnOpportunity on Asset__c (after insert, after delete) {
    
    // decomissioning this, the work will be done by assetTrigger.trigger
    /*
    FirstAssetOnOpportunity handler = new FirstAssetOnOpportunity();
    
    
    
    if(Trigger.isAfter)
    {
        if(Trigger.isInsert && (!Test.isRunningTest()) )
            handler.onAfterInsert(Trigger.new);
        if(Trigger.isDelete)
            handler.onAfterDelete(Trigger.old);         
    }
   */
    

}