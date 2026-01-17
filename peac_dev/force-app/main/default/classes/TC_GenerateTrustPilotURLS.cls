public class TC_GenerateTrustPilotURLS {
public static Boolean generateTrustPilotURLSRan = false;
    // if deal is Funded/Booked generate trust pilot urls
    public static void generateTrustPilotURLS(Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
        if (generateTrustPilotURLSRan) return;
        
        
        
        Set <Id> fundedIds = new Set <Id> ();
        for (Opportunity opp : newMap.values ()) {
            if (opp.StageName == 'Funded/Booked' && oldMap.get (opp.Id).StageName != 'Funded/Booked' && String.isEmpty (opp.Trustpilot__c)) fundedIds.add (opp.Id);
        }
        if (!fundedIds.isEmpty ()) {
            // flag to turn the integration on and off, becuase there's no test environment
            List <Trust_Pilot_App__c> tp = new List <Trust_Pilot_App__c > ([SELECT ID FROM Trust_Pilot_App__c WHERE Active__c = true]);
            if (!tp.isEmpty ()) {
                generateTrustPilotURLSRan = true;
                System.enqueueJob (new TC_TrustPilotQueueable (fundedIds));
            }
        }
    }
}