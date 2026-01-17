/** @author : Northteq Consulting, Inc.
* @date : 11/10/20
* @description: Do Not Sync to Marketo Batch class
*
*/
public class TC_DNSMarketoBatchable implements Database.Batchable<sObject> {
    
    public Database.QueryLocator start(Database.BatchableContext ctx) {
        
        Integer numDays = Integer.valueOf(Marlin_Configuration__c.getOrgDefaults().DNS_Marketo_Timer__c);
        
        Date Low = Date.today().addDays(-numDays) ; 
        Date High = Date.today().addDays(-numDays+1) ;
        
		System.debug('Low =' + Low + ' High = ' + High);
        
        String query = 'SELECT Id, AccountId, Application_Status__c, Decision_Date__c FROM Opportunity WHERE Application_Status__c = \'Rejected\' AND Decision_Date__c >= :Low AND Decision_Date__c < :High';
        System.debug(query);
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext ctx, List<Opportunity> opportunities) {
        
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            accountIds.add(opp.AccountId);
        }
        
        List<Contact> contacts = [SELECT Id, Do_Not_Sync_to_Marketo__c FROM Contact WHERE AccountId IN :accountIds AND Do_Not_Sync_to_Marketo__c = FALSE];
        
        for (Contact thisContact : contacts) {
            thisContact.Do_Not_Sync_to_Marketo__c = true;
           System.debug('Contact ='+contacts); 
        }
        
        if (contacts.size() > 0) {
            update contacts;
        }
    }
    
    public void finish(Database.BatchableContext ctx) {
    }
}