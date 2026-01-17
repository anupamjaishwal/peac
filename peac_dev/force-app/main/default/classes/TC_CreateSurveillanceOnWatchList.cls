public class TC_CreateSurveillanceOnWatchList {
    public static void createSurveillanceOnWatchList (Map <Id, Account> oldMap, Map <Id, Account> newMap) {
        Set <Id> accIds = new Set <Id> ();
        for (Account acc : newMap.values ()) {
            if ((acc.Account_Dealer_Status__c == 'Watch List') && (oldMap == null || oldMap.get (acc.Id).Account_Dealer_Status__c != 'Watch List')) {
                accIds.add (acc.Id);
            }
        }
        if (!accIds.isEmpty()) {
            Map <Id, Dealer_Surveillance__c> cantCreateSUVRecord = new Map <Id, Dealer_Surveillance__c> ();

            for (Dealer_Surveillance__c suv : [SELECT Id, Account__c  FROM Dealer_Surveillance__c WHERE Status__c != 'Completed']) {
                cantCreateSUVRecord.put (suv.Account__c, suv);
            }

            List <Dealer_Surveillance__c> suvs = new List <Dealer_Surveillance__c> ();

            Date todayDate = Date.today ();

            for (Id accId : accIds) {
                if (cantCreateSUVRecord.get (accId) == null) {
                    suvs.add (new Dealer_Surveillance__c (Account__c = accId
                            , Recommended_Action__c = 'Approved'
                            , Recommended_Next_Review__c = '12 mos'
                            , Review_Date__c = todayDate));
                }
            }

            if (!suvs.isEmpty ()) insert suvs;
        }
    }

}