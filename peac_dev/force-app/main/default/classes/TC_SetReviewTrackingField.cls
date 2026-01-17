public class TC_SetReviewTrackingField {
public static void setReviewTrackingField (Map <Id, Account> oldMap, Map <Id, Account> newMap)  {
        for (Id i : newMap.keySet()) {
            if (newMap.get(i).Review_For__c != oldMap.get (i).Review_For__c ) {
                newMap.get(i).Review_For_Tracking__c = newMap.get(i).Review_For__c;
            }
        }
    }
}