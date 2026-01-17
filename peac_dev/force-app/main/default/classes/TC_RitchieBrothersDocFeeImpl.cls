public class TC_RitchieBrothersDocFeeImpl implements TC_DocFeeRule {
    //Ritchie Brothers	855331.7237	$0 for non-titled assets; titled assets are $399 for first asset and $199 for additional assets
    public Map <Id, Decimal> runDocFeeRule (Set <Id> oppIds) {
        Map <Id, Decimal> results = new Map <Id, Decimal> ();
        
        for (Opportunity opp : [SELECT Id
                                , (SELECT Account__r.Name, Account__r.Dealer_Number__c, Account__c FROM Brokers1__r WHERE Primary_Broker__c = true)
                                , (SELECT Id, Is_Titled__c  FROM Assets__r WHERE Is_Titled__c = true)
                                FROM Opportunity
                                WHERE Id IN :oppIds]) {
                                    
        	Decimal docFee = null;
                                    
			if (!opp.Brokers1__r.isEmpty () && opp.Brokers1__r[0].Account__c != null && opp.Brokers1__r[0].Account__r.Dealer_Number__c == '855331.7237') {
				docFee = 0;
                for (Asset__c asset : opp.Assets__r) {
                    if (docFee == 0) {
                        docFee+=399;
                    } else {
                        docFee+=199;
                    }
                }                      
			}
			results.put (opp.Id, docFee);
        }
        return results;
    }
}