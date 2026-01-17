global class TC_UpdateChildDealerAccountsBatch implements Database.Batchable<SObject>, Database.Stateful,Schedulable {
    
    public List<Account> accList = new List<Account>();
    
    public List<Account> parentList = new List<Account>();
    
    global void execute(SchedulableContext SC) {
        if (Test.isRunningTest()) return;
        TC_UpdateChildDealerAccountsBatch obj = new TC_UpdateChildDealerAccountsBatch(); 
        Database.executeBatch(obj, 10);
        
    }
   

    global Iterable<sObject> start(Database.BatchableContext bc) {
        // Query fields from metadata to build dynamic query
        Map<Id, Dealer_Child_Account_Field__mdt> dealerChildAccountFieldMap = queryFieldsFromMetadata();
        List<String> fieldNames = createListFromFieldNames(dealerChildAccountFieldMap);
        // Query all child dealer accounts whose parent is in oldParentMap
        String queryString = 'SELECT Id, ParentId, Update_Child_Records__c, ' + String.join(fieldNames, ',') + ' FROM Account WHERE Is_Dealer__c = TRUE AND Update_Child_Records__c = TRUE AND LastModifiedDate = Today';
        if(isRepRole(TC_UpdateChildDealerAccounts.getUserRoleName())) {
            return new List<Account>();
        }
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> parentAccounts) {
        
        if (parentAccounts.isEmpty()) return;
        System.debug('parentAccounts::'+parentAccounts);
        // Query fields from metadata
        Map<Id, Dealer_Child_Account_Field__mdt> dealerChildAccountFieldMap = queryFieldsFromMetadata();
        List<String> fieldNames = createListFromFieldNames(dealerChildAccountFieldMap);
        
        // Collect parentIds
       Map<Id, Account> parentMap = new Map<Id,Account>();
        for (Account parent : parentAccounts) {
            parentMap.put(parent.Id,parent);
        }
        
        // Query all child accounts for these parents
        Map<Id, List<Account>> parentToChildMap = new Map<Id, List<Account>>();
        for (Account child : Database.query(
            'SELECT Id, ParentId, ' + String.join(fieldNames, ',') + 
            ' FROM Account WHERE ParentId IN :parentAccounts AND Is_Dealer__c = TRUE'
        )) {
            if (!parentToChildMap.containsKey(child.ParentId)) {
                parentToChildMap.put(child.ParentId, new List<Account>());
            }
            parentToChildMap.get(child.ParentId).add(child);
        }
        
        List<Account> accountsToUpdate = new List<Account>();
        
        // Loop through each parent and update children if fields mismatch
        for (Account parent : parentAccounts) {
            List<Account> children = parentToChildMap.get(parent.Id);
            if (children == null || children.isEmpty()) continue;
            
            for (Account child : children) {
                Boolean needsUpdate = false;
                
                for (Dealer_Child_Account_Field__mdt field : dealerChildAccountFieldMap.values()) {
                    String fieldName = field.Field_API_Name__c;
                    
                    if (child.get(fieldName) != parent.get(fieldName)) {
                        child.put(fieldName, parent.get(fieldName));
                        needsUpdate = true;
                    }
                }
                
                if (needsUpdate) {
                    accountsToUpdate.add(child);
                }
            }
        }
        
        // Bulk update child accounts
        if (!accountsToUpdate.isEmpty()) {
            try {
                System.debug('accountsToUpdate::'+accountsToUpdate);
                parentList.addAll(parentAccounts);
                accList.addAll(accountsToUpdate);
            } catch (DmlException e) {
                System.debug('Failed to update child accounts: ' + e.getMessage());
            }
        }
    }


    global void finish(Database.BatchableContext bc) {
        // Skip chaining in tests to satisfy "one executeBatch per test method" rule.
    if (Test.isRunningTest()) return;
        TC_UpdateChildAccountBatch obj = new TC_UpdateChildAccountBatch(accList);
          Database.executeBatch(obj, 10);
        TC_UpdateParentAccountBatch parentObj = new TC_UpdateParentAccountBatch(parentList);
          Database.executeBatch(parentObj, 10);
    }

    // === Helper methods ===
    private static Boolean isRepRole(String roleName) {
        return roleName != null && roleName.containsIgnoreCase('rep');
    }

    private static Map<Id, Dealer_Child_Account_Field__mdt> queryFieldsFromMetadata() {
        return new Map<Id, Dealer_Child_Account_Field__mdt>([
            SELECT Id, Field_API_Name__c FROM Dealer_Child_Account_Field__mdt
        ]);
    }

    private static List<String> createListFromFieldNames(Map<Id, Dealer_Child_Account_Field__mdt> fieldMap) {
        List<String> names = new List<String>();
        for (Dealer_Child_Account_Field__mdt m : fieldMap.values()) {
            names.add(m.Field_API_Name__c);
        }
        return names;
    }
}