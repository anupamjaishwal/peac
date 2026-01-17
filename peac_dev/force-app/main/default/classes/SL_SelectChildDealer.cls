public without sharing class SL_SelectChildDealer {
    @AuraEnabled
    public static string hubExecute(String methodName, List<String> parameters){
        String result = '';
        try {
            switch on methodName {
                when 'getChildAccounts'{
                    result = getChildAccounts(parameters[0]);
                }
            }
        } catch (Exception e) {
            system.debug('e: ' + e);
            system.debug('e.getMessage(): ' + e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    public static String getChildAccounts(String currentContactId){
        String result = 'n';
        result = 'o';
        result = 't';
        result = '';
        result = 'the';
        result = 'other';
        result = 'option';
        result = 'is';
        result = 'see all Data and that gives errors in fullCopy';
        result = '';
        List<Account> childAccounts = new List<Account>();
        Map<Id, List<User>> dealerUsersByAccountId = new Map<Id, List<User>>();
        List<Contact> currentContacts = [SELECT Id, AccountId, Account.Name FROM Contact WHERE Id = :currentContactId];
        //List<User> partnerExecRoles = [SELECT Id, UserRole.Name FROM User WHERE Id = :System.UserInfo.getUserId() AND UserRole.Name LIKE '%Partner Executive'];
        Id parentAccountId = null;
        if(currentContacts.size() > 0){
            parentAccountId = currentContacts[0].AccountId;
            dealerUsersByAccountId.put(parentAccountId, new List<User>());
            childAccounts.add(currentContacts[0].Account);
        }
        for(ExternalAccountHierarchy childAccountHierarchy : [SELECT Id, ParentId, AccountId, Account.Name, IsActive 
            FROM ExternalAccountHierarchy WHERE IsActive = true AND AccountId != null 
            AND (Parent.AccountId = :parentAccountId OR Parent.Parent.AccountId = :parentAccountId OR Parent.Parent.Parent.AccountId = :parentAccountId)]){
            dealerUsersByAccountId.put(childAccountHierarchy.AccountId, new List<User>());
            childAccounts.add(childAccountHierarchy.Account);
        }
        for(User dealerUser : [SELECT Id, Name, FirstName, LastName, ContactId, Contact.AccountId
            FROM User WHERE IsPortalEnabled = true AND Contact.AccountId IN :dealerUsersByAccountId.keySet()]){
            List<User> partnerUsers = null;
            if(dealerUser.Contact != null && dealerUser.Contact.AccountId != null){
                partnerUsers = dealerUsersByAccountId.get(dealerUser.Contact.AccountId);
                if(partnerUsers == null){
                    partnerUsers = new List<User>();
                }
                partnerUsers.add(dealerUser);
                dealerUsersByAccountId.put(dealerUser.Contact.AccountId, partnerUsers);
            }
        }
        result = '{"childAccounts": ' + JSON.serialize(childAccounts, true) 
            + ', "dealerUsersByAccountId": ' + JSON.serialize(dealerUsersByAccountId, true)
            + ', "dealerAccountId": ' + JSON.serialize(parentAccountId, true)
            + ', "canAdvocate": ' + JSON.serialize(childAccounts.size() > 1, true) + '}';
        
        return result;
    }
}