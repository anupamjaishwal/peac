public class SL_UpdatePrivateLabelDocBatch implements Database.Batchable<SObject>, Database.Stateful {
    Set<Id> accountIdsPLD;

    public SL_UpdatePrivateLabelDocBatch(Set<Id> accountIdsPLDPassed) {
        accountIdsPLD = accountIdsPLDPassed;
    }

    public Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id, Dealer_Account__r.Private_Label_Documents__c, Private_Label_Documents__c '
            + 'FROM opportunity '
            + 'WHERE Dealer_Account__c IN :accountIdsPLD');
    }
    public void execute(Database.BatchableContext BC, List<SObject> scope){
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        List<Database.SaveResult> allResults = new List<Database.SaveResult>();
        String allErrors = '';
        system.debug('scope size: ' + scope.size());
        for(sObject s : scope){
            Opportunity dealerOpp = (Opportunity)s;
            if(dealerOpp.Dealer_Account__r.Private_Label_Documents__c != dealerOpp.Private_Label_Documents__c){
                dealerOpp.Private_Label_Documents__c = dealerOpp.Dealer_Account__r.Private_Label_Documents__c;
                oppsToUpdate.add(dealerOpp);
            }
        }
        if(oppsToUpdate.size() > 0){
            allResults = Database.update(oppsToUpdate, false);
        }
        for(Database.SaveResult result :allResults){
            if(!result.isSuccess() && Limits.getHeapSize() < Limits.getLimitHeapSize() - 2000){
                System.debug(result.getErrors());
                allErrors += '\r\n' + result.getErrors();
            }
        }
        
    }
    public void finish(Database.BatchableContext BC){
        
    }
}