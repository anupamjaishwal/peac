public class TC_UpdateReviewForNull {
    public static void updateReviewForNull (List<Account> newList) {

        for (Account a : newList) {
            if (!String.isEmpty(a.DM_Review_Status__c) && a.DM_Review_Status__c.equals('Completed')) {
                a.Review_For__c=null;
            }
        }
    }
    
    public static void updateReviewForNull (Map<Id, Account> newMap) {

        for (Id i : newMap.keySet()) {
            if (!String.isEmpty(newMap.get(i).DM_Review_Status__c) && newMap.get(i).DM_Review_Status__c.equals('Completed')) {
                newMap.get(i).Review_For__c=null;
            }
        }
    }
}