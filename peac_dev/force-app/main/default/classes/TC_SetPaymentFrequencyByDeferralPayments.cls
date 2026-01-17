public class TC_SetPaymentFrequencyByDeferralPayments {
public static void setPaymentFrequencyByDeferralPayments (Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        
        // If Deferral Payments is not null, then set Payment Frequency to 'Monthly'
        // Else if Deferral Payments is null and EF_Approved_Offers__c is not null, then set Payment Frequency to 'Variable'
        
        for (Opportunity opp : newMap.values()) {
            
            // Check if the Deferral Payments field has changed to prevent unnecessary processing
            if (opp.Deferral_Payments__c <> oldMap.get(opp.Id).Deferral_Payments__c) {
                
                if (opp.Deferral_Payments__c <> null) {
                    opp.Payment_Frequency__c = 'Variable';
                } else if (opp.Deferral_Payments__c == null && opp.EF_Approved_Offers__c <> null) {
                    opp.Payment_Frequency__c = 'Monthly';
                }
            }
        }
    }
}