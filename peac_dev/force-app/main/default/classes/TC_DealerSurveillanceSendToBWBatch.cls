public class TC_DealerSurveillanceSendToBWBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    // grab dealer surveillences ready to be sent Bridgeware. These are generated from the TC_DealerSurveillanceBatch
	public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('>>> Start TC_DealerSurveillanceSendToBWBatch');
        
        String query = 'SELECT Name, Account__c, Review_Date__c, Review_Type__c, Next_Scheduled_Review__c, Status__c, Additional_Review_Comments__c, Id, Waiting_To_Be_Sent_To_Bridgeware__c  FROM Dealer_Surveillance__c WHERE Waiting_To_Be_Sent_To_Bridgeware__c = TRUE AND Created_via_Backfill_Job__c = false';
    	return Database.getQueryLocator(query);
    }
    
    public void execute (Database.BatchableContext bc, List<Dealer_Surveillance__c> survs) {
        System.debug('>>> Execute TC_DealerSurveillanceSendToBWBatch');
        List <Dealer_Surveillance__c> updateList = new List <Dealer_Surveillance__c> ();
        
        // calls api in loop, due to no bulk api
        for (Dealer_Surveillance__c surv : survs) {
            TC_BWupdateDealerSurveillanceCtrl.updateDealerSurveillance (surv);
            updateList.add (new Dealer_Surveillance__c (Id = surv.Id
                                                       , Waiting_To_Be_Sent_To_Bridgeware__c = false));
        }
        
        if (!updateList.isEmpty()) update updateList;
        
        
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('>>> Finish TC_DealerSurveillanceSendToBWBatch');
    }
}