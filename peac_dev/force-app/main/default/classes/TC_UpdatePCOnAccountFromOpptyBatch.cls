global class TC_UpdatePCOnAccountFromOpptyBatch implements Database.Batchable<SObject> {
    
    global Database.QueryLocator start(Database.BatchableContext info) {
        String query = 'SELECT Id, Primary_Contact__c, MostRecentOpportunity__c, MostRecentOpportunity__r.Primary_Contact__c';
        query += ' FROM Account WHERE (RecordType.Name = \'End User Account\' OR RecordType.Name = \'Franchisee Account\') AND Primary_Contact__c = null AND MostRecentOpportunity__c != null';
        
        //String query = 'SELECT Id, Primary_Contact__c, (SELECT Id, Primary_Contact__c FROM Opportunities WHERE Primary_Contact__c != null ORDER BY CreatedDate DESC LIMIT 1)';
        //query += ' FROM Account WHERE (RecordType.Name = \'End User Account\' OR RecordType.Name = \'Franchisee Account\') AND Primary_Contact__c = null';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext info, List<Account> scope) {
        
        List<Account> listAccToUpdate = new List<Account>();
        for(Account acc: scope){
            if(acc.MostRecentOpportunity__c != null && acc.MostRecentOpportunity__r.Primary_Contact__c != null){
                Account a = new Account();
                a.Id = acc.Id;
                a.Primary_Contact__c = acc.MostRecentOpportunity__r.Primary_Contact__c;
                listAccToUpdate.add(a);
            }
        }
        
        Database.update(listAccToUpdate, false);
    }
    global void finish(Database.BatchableContext info) {
        
    }
    
}