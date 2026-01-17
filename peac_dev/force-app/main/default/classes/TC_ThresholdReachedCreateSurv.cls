public class TC_ThresholdReachedCreateSurv {
public static void thresholdReachedCreateSurv (Map <Id, Account> oldMap, Map <Id, Account> newMap) {
        
        // throw values in maps so we don't have to loop inside of a loop
        Map <String, String> thresholdMap = new Map <String, String> ();
        Map <String, Id> accIdRefMap = new Map <String, Id> ();
        
        for (Account acc : newMap.values ()) {
            if (acc.Net_Investment__c!= null && (oldMap == null || acc.Net_Investment__c != oldMap.get (acc.Id).Net_Investment__c)) {
                String thresh = TC_ValueToThreshold.valueToThreshold (acc.Net_Investment__c);
                if (thresh != null) {
                    String key = TC_CreateThresholdKey.createThresholdKey (acc.Id, thresh);
                    thresholdMap.put (key, thresh);
                    accIdRefMap.put (key, acc.Id);
                } 
            }
                
        }
        
        if (accIdRefMap.isEmpty() || thresholdMap.isEmpty()) return;
        
        for (Dealer_Surveillance__c surv : [SELECT Id, Account__c, Dealer_Surveillance__c FROM Dealer_Surveillance__c WHERE Account__c IN :accIdRefMap.values() AND Review_Type__c = 'Portfolio Threshold' AND Dealer_Surveillance__c Like 'Portfolio Threshold %']) {
            List <String> splitName = surv.Dealer_Surveillance__c.split (' ');
            if (splitName.size() == 3) {
                String thresh = splitName[2];
                String key = TC_CreateThresholdKey.createThresholdKey (surv.Account__c, thresh);
                if (thresholdMap.get (key) != null) {
                    thresholdMap.remove (key);
                }
            }
        }
        
        if (thresholdMap.isEmpty ()) return;
        
        List <Dealer_Surveillance__c> insertList = new List <Dealer_Surveillance__c> ();
        
        for (String key : thresholdMap.keySet ()) {
            insertList.add (new Dealer_Surveillance__c (Account__c = accIdRefMap.get (key)
                                                       , Dealer_Surveillance__c = 'Portfolio Threshold ' + thresholdMap.get (key)
                                                       , Review_Type__c = 'Portfolio Threshold'
                                                       , Status__c = 'In Queue'));
        }
        
        insert insertList;
        

    }
}