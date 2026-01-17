public class TC_AccountMarketPositionBatch implements Database.Batchable<sObject> {

    public Database.QueryLocator start(Database.BatchableContext BC) {

        Date nullifyFieldDate = Date.today().addDays (-90);
        String query = 'SELECT Id, Market_Position__c, Market_Position_Last_Populated_Date__c FROM Account WHERE Market_Position_Last_Populated_Date__c <= :nullifyFieldDate AND Market_Position__c != null';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext BC, List<Account> accounts) {
        
        List <Account> updateList = new List <Account> ();
        for (Account acc : accounts) {
            updateList.add (new Account (Id = acc.Id, Market_Position__c = null, Market_Position_Last_Populated_Date__c = null));
        }
        if (!updateList.isEmpty()) update updateList;

    }
    public void finish(Database.BatchableContext BC) {
        System.debug ('TC_AccountMarketPositionBatch Job Completed.');
    }
}