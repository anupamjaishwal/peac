public class TC_CheckPaymentsWhenBookingStage {
    public static Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
public static void checkPaymentsWhenBookingStage (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
        Set <Id> bookingOppIds = new Set <Id> ();
        // only on change to booking stage
        for (Opportunity opp : newMap.values ()) {
            if (!opp.Manual_Funding__c && !opp.Loan_Record_Type__c && opp.StageName == 'Booking' && opp.StageName != oldMap.get (opp.Id).StageName) {
                bookingOppIds.add (opp.Id);
            }
        }
        
        if (!bookingOppIds.isEmpty ()) {
            List <Opportunity> opps = [SELECT Id, (SELECT Id FROM Payments__r WHERE Payment_Status__c NOT IN ('Payment Confirmed', 'Payment Released', 'Void/Cancelled')) FROM Opportunity WHERE Id IN :bookingOppIds];
            
            for (Opportunity opp : opps) {
                if (config != null && config.Apex_Validations_Active__c && !opp.Payments__r.isEmpty())
                    newMap.get (opp.Id).addError ('There are Payments that have not reached the Payment Acknowledged or Payment Released stage (or been Voided/Cancelled). All Payments must be in those stages before moving to Booking or you must override this requirement by checking the Manual Funding checkbox.');
            }
        }
        
    }
}