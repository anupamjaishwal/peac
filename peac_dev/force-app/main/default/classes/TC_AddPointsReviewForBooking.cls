public class TC_AddPointsReviewForBooking {
public static void addPointsReviewForBooking (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        
        Set <Id> reviewOppIds = new Set <Id> ();
        List <Opportunity> updateList = new List <Opportunity> ();
        // only on change to booking stage
        for (Opportunity opp : newMap.values ()) {
            if (opp.Loan_Record_Type__c && opp.StageName == 'Review for Booking' && opp.StageName != oldMap.get (opp.Id).StageName) {
                Decimal amount;
                if (opp.Renewal_Payoff_Amount__c != null && opp.Renewal_Payoff_Amount__c != 0) {
                    amount = (opp.Loan_Amount__c - opp.Renewal_Payoff_Amount__c) * opp.Max_Fees__c;
                } else {
                    amount = opp.Loan_Amount__c * opp.Max_Fees__c;
                }
                updateList.add (new Opportunity (Id = opp.Id, Loan_Points_Amount__c = amount));
            }
        }
        if (!updateList.isEmpty()) update updateList;
        
        
    }
}