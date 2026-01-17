public class TC_SentrySurveillanceDocFeeImpl implements TC_DocFeeRule {
    // Sentry Surveillance	770592.0400	$119 for new customers and $50 for previous customers (based on having done business with Marlin in past - use last booked date?)
    public Map <Id, Decimal> runDocFeeRule (Set <Id> oppIds) {
        
        Map <Id, Decimal> results = new Map <Id, Decimal> ();
        
     /*   for (Opportunity opp : [SELECT Id
                                , (SELECT Dealer__r.Name, Dealer__r.Dealer_Number__c, Dealer__c FROM Brokers__r WHERE Primary_Dealer__c = true)
                                , Account.Account_Dealer_Last_Booked__c 
                                FROM Opportunity
                                WHERE Id IN :oppIds]) {
        	Decimal docFee = null;
                                    
                                    
			if (!opp.Brokers__r.isEmpty () && opp.Brokers__r[0].Dealer__c != null && opp.Brokers__r[0].Dealer__r.Dealer_Number__c == '770592.0400') {
                if (opp.Account.Account_Dealer_Last_Booked__c != null) {
                    docFee = 50; // existing customer
                } else {
                    docFee = 119; // new customer
                }                          
			}
			results.put (opp.Id, docFee);
		}*/
        
        return results;
    }
}