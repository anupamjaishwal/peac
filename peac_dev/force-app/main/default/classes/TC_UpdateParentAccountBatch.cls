global class TC_UpdateParentAccountBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    public List<Account> parentAccounts;
    
    public TC_UpdateParentAccountBatch(List<Account> accList) {
        parentAccounts = new List<Account>();
        parentAccounts = accList;
    }
    
    global Iterable<sObject> start(Database.BatchableContext bc) {
        return this.parentAccounts;
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accList) {
        try {
            TC_RecursiveTriggerHelper.updateChildAccountsOfDealerBefore = true;
            TC_RecursiveTriggerHelper.updateChildAccountsOfDealerAfter = true;
            TC_RecursiveTriggerHelper.avoidUpdateChildDealerRecursion = true;
            for(Account acc : accList) {
                acc.Update_Child_Records__c = false;
            }
            Database.update(accList, false);
            TC_RecursiveTriggerHelper.avoidUpdateChildDealerRecursion = false;
        } catch (DmlException e) {
            System.debug('Failed to update parent accounts: ' + e.getMessage());
        }
    }
    global void finish(Database.BatchableContext bc) {
        
    }
}