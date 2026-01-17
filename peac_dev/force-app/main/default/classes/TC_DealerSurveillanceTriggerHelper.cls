public class TC_DealerSurveillanceTriggerHelper {
    
    public static Boolean isCompleting = false;

     // Define constant map of threshold ranks
    public static final Map<String, Integer> THRESHOLD_RANKS = new Map<String, Integer>{
        'Portfolio Threshold $250K'  => 1,
        'Portfolio Threshold $500K' => 2,
        'Portfolio Threshold $1MM'  => 3,
        'Portfolio Threshold $2.5MM'=> 4,
        'Portfolio Threshold $5MM'  => 5,
        'Portfolio Threshold $10MM' => 6
    };


    public static void stampFields (List <Dealer_Surveillance__c> newList) {
        Set <Id> accIds = new Set <Id> ();
        
        
        for (Dealer_Surveillance__c suv : newList) {
            accIds.add (suv.Account__c);
        }
        
        Map <Id, Account> accs = new Map <Id, Account> ([SELECT Id, Actual_Vs_Projected_Loss__c, Account_Total_Past_Due_Percentage__c, Net_Investment__c  FROM Account WHERE Id IN :accIds]);
        
        for (Dealer_Surveillance__c suv : newList) {
            suv.Actual_Vs_Projected_Loss__c = accs.get (suv.Account__c).Actual_Vs_Projected_Loss__c;
            suv.Total_Past_Due__c = accs.get (suv.Account__c).Account_Total_Past_Due_Percentage__c;            
        }
        
    }
	
    public static void checkForNonCompleteSurveillances (List <Dealer_Surveillance__c> newList) {
        Set <Id> dealerIds = new Set <Id> ();
        
        for (Dealer_Surveillance__c suv : newList) {
            dealerIds.add (suv.Account__c );
        }
        
        Map <Id, Dealer_Surveillance__c> cantCreateSUVRecord = new Map <Id, Dealer_Surveillance__c> ();
            
		for (Dealer_Surveillance__c suv : [SELECT Id, Account__c  FROM Dealer_Surveillance__c WHERE Status__c != 'Completed']) {
			cantCreateSUVRecord.put (suv.Account__c, suv);
		}
        
        for (Dealer_Surveillance__c suv : newList) {
            if (cantCreateSUVRecord.get (suv.Account__c) != null && suv.Review_Type__c != 'Portfolio Threshold') {
                suv.addError ('Cannot create a new surveillance record if there is an existing surveillance record that is not in the "Complete" status');
            }
        }
        
    }

    
        
    public static void checkModels (List <Dealer_Surveillance__c> newList) {
        DealerReviewer reviewer = new DealerReviewer ();
        reviewer.reviewSurveillances(newList);        
    }

    
    public static void completeSUV(Map<Id, Dealer_Surveillance__c> newMap, Map<Id, Dealer_Surveillance__c> oldMap) {
        if (isCompleting) return;

        try {
            isCompleting = true;

            Map<Id, String> completedThresholdByAccount = new Map<Id, String>();

            for (Dealer_Surveillance__c ds : newMap.values()) {
                Dealer_Surveillance__c oldDS = oldMap.get(ds.Id);

                if (ds.Review_Type__c == 'Portfolio Threshold' &&
                    ds.Status__c == 'Completed' &&
                    oldDS.Status__c != 'Completed') {

                    if (ds.Account__c != null && ds.Dealer_Surveillance__c != null) {
                        completedThresholdByAccount.put(ds.Account__c, ds.Dealer_Surveillance__c);
                    }
                }
            }

            if (completedThresholdByAccount.isEmpty()) return;

            List<Dealer_Surveillance__c> toUpdate = new List<Dealer_Surveillance__c>();

            List<Dealer_Surveillance__c> relatedRecords = [
                SELECT Id, Account__c, Status__c, Dealer_Surveillance__c
                FROM Dealer_Surveillance__c
                WHERE Account__c IN :completedThresholdByAccount.keySet() AND ID NOT IN :newMap.keySet()
                AND Status__c != 'Completed'
            ];

            for (Dealer_Surveillance__c ds : relatedRecords) {
                if (newMap.containsKey(ds.Id)) {
                    continue;
                }

                String completedThreshold = completedThresholdByAccount.get(ds.Account__c);

                if (ds.Dealer_Surveillance__c != null &&
                    THRESHOLD_RANKS.containsKey(ds.Dealer_Surveillance__c) &&
                    THRESHOLD_RANKS.containsKey(completedThreshold)) {

                    Integer dsRank = THRESHOLD_RANKS.get(ds.Dealer_Surveillance__c);
                    Integer completedRank = THRESHOLD_RANKS.get(completedThreshold);

                    if (dsRank < completedRank) {
                        ds.Status__c = 'Completed';
                        toUpdate.add(ds);
                    }
                }
            }

            if (!toUpdate.isEmpty()) {
                update toUpdate;
            }

        } finally {
            isCompleting = false;
        }
    }



}