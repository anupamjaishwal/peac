global class PEAC_BuyoutPurgeBatch implements Database.Batchable<SObject>, Schedulable {
    
    // Start method: Query records where PurgeDate__c = Today
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        String purgeDateStr = System.Label.PurgeDateLabel;
        Date purgeDate;
        
        if (purgeDateStr == 'TODAY') {
            purgeDate = Date.today();
        } else {
            purgeDate = Date.valueOf(purgeDateStr);
        }
        
        return Database.getQueryLocator([
            SELECT Id 
            FROM Buyout__c 
            WHERE PurgeDate__c = :purgeDate AND Status__c != 'Closed'
        ]);
    }
    
    // Execute method: Delete the records in each batch
    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Buyout__c> recordsToDelete = (List<Buyout__c>)scope;
        
        try {
            if (!recordsToDelete.isEmpty()) {
                delete recordsToDelete;
            }
        } catch (DmlException e) {
            System.debug('Error deleting Buyout__c records: ' + e.getMessage());
        }
    }
    
    // Optional: Post-processing logic
    global void finish(Database.BatchableContext bc) {
        System.debug('Buyout purge batch completed.');
    }
    
    // Schedulable logic: Schedule the batch job
    global void execute(SchedulableContext sc) {
        PEAC_BuyoutPurgeBatch batch = new PEAC_BuyoutPurgeBatch();
        Database.executeBatch(batch, 200); // You can modify batch size if needed
    }
}