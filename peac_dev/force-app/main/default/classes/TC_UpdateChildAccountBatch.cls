global class TC_UpdateChildAccountBatch implements Database.Batchable<SObject>, Database.Stateful {
    
    public List<Account> childAccounts;
    
    public TC_UpdateChildAccountBatch(List<Account> accList) {
        childAccounts = new List<Account>();
        childAccounts = accList;
    }
    
    global Iterable<sObject> start(Database.BatchableContext bc) {
        return this.childAccounts;
    }
    
    global void execute(Database.BatchableContext bc, List<Account> accList) {
         try {
                TC_RecursiveTriggerHelper.updateChildAccountsOfDealerBefore = true;
                TC_RecursiveTriggerHelper.updateChildAccountsOfDealerAfter = true;
                Database.update(accList, false);
            } catch (DmlException e) {
                System.debug('Failed to update child accounts: ' + e.getMessage());
            }
    }
    global void finish(Database.BatchableContext bc) {
        
    }
}