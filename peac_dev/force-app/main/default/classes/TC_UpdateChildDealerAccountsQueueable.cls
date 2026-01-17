public with sharing class TC_UpdateChildDealerAccountsQueueable implements Queueable, Database.AllowsCallouts {
    
    public Map<Id, Account> childMap;
    public String roleName;

    public TC_UpdateChildDealerAccountsQueueable(Id recordId, Map<Id, Account> childMap) {

        // uncomment this next line in case the code must be quickly reverted, and comment out the remainder of the method
        // this.childMap = new Map<Id, Account>([SELECT Id, ParentId FROM Account WHERE ParentId = :recordId]);

        Integer batchSize;
        try {
            batchSize = Integer.valueOf(Dealer_Child_Account_Update_Setting__mdt.getInstance('Default')?.Batch_Size__c);
        } catch (Exception e) {
            System.debug('Unable to get batch size! Is there a Dealer_Child_Account_Update_Setting__mdt record? Aborting TC_UpdateChildDealerAccountsQueueable!');
            return;
        }
        System.debug('batch size is ' + batchSize);

        this.childMap = childMap; // set this class's childMap to inputted childMap - prevents null error

        // query the child records if it's the first run
        if (childMap == null) {
            this.childMap = new Map<Id, Account>([SELECT Id, ParentId FROM Account WHERE ParentId = :recordId]);
            childMap = new Map<Id, Account>(this.childMap);
            System.debug('childMap was null, set childMap to ' + childMap);
        }

        // split into chunks of batchSize and queue the remaining children
        if (childMap?.size() > batchSize) {
            this.childMap = new Map<Id, Account>();
            List<Account> childMapToList = childMap.values();
            for (Integer i = 0; i < batchSize; i++) {
                Account child = childMapToList.get(i);
                this.childMap.put(child.Id, child);
                childMap.remove(child.Id); // remove from map so it doesn't get queued again
            }
            System.debug('this childMap is ' + this.childMap);
            System.debug('childMap after is ' + childMap);

            System.enqueueJob(new TC_UpdateChildDealerAccountsQueueable(recordId, childMap));
        }
    }

    public void execute(QueueableContext context) {
        TC_UpdateChildDealerAccounts.handleChildren(null, childMap, childMap, '');
    }
}