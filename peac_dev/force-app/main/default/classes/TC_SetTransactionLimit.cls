public class TC_SetTransactionLimit {
    public static void setTransactionLimit(Map<Id, Account> oldMap, List<Account> newList) {

        for (Account acc : newList) {
            if ((acc.Id == null && acc.Authorized_Seller__c == '1') ||
                    (acc.Id != null && acc.Authorized_Seller__c != oldMap.get(acc.Id).Authorized_Seller__c && acc.Authorized_Seller__c == '1')) {
                acc.Transaction_Limit__c = '$20K';
            }
        }

    }
    public static void setTransactionLimit(Map<Id, Account> oldMap, Map<Id, Account> newMap) {

        for (Id i : newMap.keySet()) {
            if (newMap.get(i).Authorized_Seller__c != oldMap.get(i).Authorized_Seller__c && newMap.get(i).Authorized_Seller__c == '1') {
                newMap.get(i).Transaction_Limit__c = '$20K';
            }
        }

    }
}