public without sharing class SL_ExternalAccountHierarchyService {

    // Method to retrieve the full hierarchy using External Account Hierarchy
    public static List<Account> getAccountHierarchy(Id accountId) {
        // List to hold all Account records in the hierarchy
        List<Account> accountsList = new List<Account>();
        Account originAccount = [SELECT Id, Name, Dealer_Number__c FROM Account WHERE Id = :accountId LIMIT 1];
        accountsList.add(originAccount);

        Set<Id> idSet = new Set<Id>();
        idSet.add(originAccount.Id);
    
        
        // Add all child accounts from the External Account Hierarchy
        getChildAccounts(idSet, accountsList);
        
        // Add all parent accounts (up the hierarchy) from the External Account Hierarchy
        //getParentAccounts(accountId, hierarchy);
        
        return accountsList;
    }
    
    // Recursive method to retrieve child accounts from the External Account Hierarchy
    private static void getChildAccounts(Set<Id> accountIds, List<Account> accountsList) {
        // Set to hold child account IDs from all levels
        Set<Id> childAccountIds = new Set<Id>();
    
        // Query the External Account Hierarchy to find children of the given accounts
        List<ExternalAccountHierarchy> externalChildsHierarchy = [
            SELECT AccountId 
            FROM ExternalAccountHierarchy 
            WHERE Parent.AccountID IN :accountIds
        ];
    
        if (externalChildsHierarchy.size() > 0) {
            // Collect all child Account IDs from the External Account Hierarchy relationships
            for (ExternalAccountHierarchy eah : externalChildsHierarchy) {
                childAccountIds.add(eah.AccountId);
            }
            
            // If we have child Account IDs, query for those Account records in bulk
            if (childAccountIds.size() > 0) {
                List<Account> childAccounts = [
                    SELECT Id, Name , Dealer_Number__c
                    FROM Account 
                    WHERE Id IN :childAccountIds
                ];
                
                // Add the found child accounts to the list
                accountsList.addAll(childAccounts);
    
                // Recursively add more child accounts if any exist
                getChildAccounts(childAccountIds, accountsList);
            }
        }
    }
    
    
    // Recursive method to retrieve parent accounts from the External Account Hierarchy
    /*private static void getParentAccounts(Id accountId, List<Account> hierarchy) {
        List<ExternalAccountHierarchy> parentHierarchy = [
            SELECT ParentId, AccountId 
            FROM ExternalAccountHierarchy 
            WHERE AccountId = :accountId
        ];
        
        for (ExternalAccountHierarchy eah : parentHierarchy) {
            hierarchy.add([SELECT Id, Name FROM Account WHERE Id = :eah.ParentId LIMIT 1]);
            // Recursively move up the hierarchy to get the parent accounts
            getParentAccounts(eah.ParentId, hierarchy);
        }
    }*/
}