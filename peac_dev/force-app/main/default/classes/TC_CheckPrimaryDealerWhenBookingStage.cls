public class TC_CheckPrimaryDealerWhenBookingStage {
    public static Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
public static void checkPrimaryDealerWhenBookingStage (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
        Set <Id> bookingOppIds = new Set <Id> ();
        // only on change to booking stage
        for (Opportunity opp : newMap.values ()) {
            if (!opp.Loan_Record_Type__c && opp.StageName == 'Booking' && opp.StageName != oldMap.get (opp.Id).StageName && opp.Marlin_Business_Group__c != 'IFP' && opp.Marlin_Business_Group__c != 'Franchise') {
                bookingOppIds.add (opp.Id);
            }
        }
        
        if (!bookingOppIds.isEmpty ()) {
            
            List <Opportunity> oppsWithPrimaryDealers = new List <Opportunity > ([SELECT Id, Name, (SELECT Id FROM Brokers__r WHERE Primary_Dealer__c = true) FROM Opportunity WHERE Id IN :bookingOppIds]);
            
            Map <Id, Boolean> hasPrimaryDealer = new Map <Id, Boolean> ();
            
            for (Opportunity opp : oppsWithPrimaryDealers) {
                if (!opp.Brokers__r.isEmpty ()) hasPrimaryDealer.put (opp.Id, true);
            }
            
            for (Id oppId : bookingOppIds) {
                if (hasPrimaryDealer.get (oppId) == null || !hasPrimaryDealer.get (oppId)) {
                    if (config != null && config.Apex_Validations_Active__c) newMap.get (oppId).addError ('Opportunity must have Primary Dealer to enter Booking Stage');
                }
            }
        }
        
    }
}