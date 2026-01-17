public class TC_DealerAccountSendToBWBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {
    
    // grab dealer accounts ready to be sent Bridgeware. These are generated from the TC_DealerSurveillanceBatch
  public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug('>>> Start TC_DealerSurveillanceSendToBWBatch');
        
        String query = 'SELECT Id FROM Account WHERE Waiting_To_Be_Sent_To_Bridgeware__c = true';
      return Database.getQueryLocator(query);
    }
    
    public void execute (Database.BatchableContext bc, List<Account> accs) {
        
        List <Account> updateList = new List <Account> ();
        
        for (Account acc: accs) {
            TC_BWUpdateDealerCtrl.updateDealerNonFuture (acc.Id);
            updateList.add (new Account (Id = acc.Id , Waiting_To_Be_Sent_To_Bridgeware__c = false));
        }
        
        if (!updateList.isEmpty()) update updateList;
         
        
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('>>> Finish TC_DealerSurveillanceSendToBWBatch');
    }
}