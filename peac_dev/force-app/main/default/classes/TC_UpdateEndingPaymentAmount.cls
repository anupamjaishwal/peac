public class TC_UpdateEndingPaymentAmount {
    public static void updateEndingPaymentAmount (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        for (Opportunity opp : newMap.values ()) {
            if (opp.Payment_Amount__c != oldMap.get (opp.Id).Payment_Amount__c || opp.of_ending_payments__c != oldMap.get (opp.Id).of_ending_payments__c) {
                if (opp.Payment_Amount__c != null && opp.Payment_Amount__c != 0 && opp.of_ending_payments__c != null && opp.of_ending_payments__c != 0) {
                    opp.Ending_Pymts_in_Advance__c = opp.Payment_Amount__c.setScale(2, RoundingMode.HALF_UP) * opp.of_ending_payments__c;
                } else {
                    opp.Ending_Pymts_in_Advance__c = 0;
                }
                TC_CalculateGrossContract.calculateGrossContract (opp);
            }
        }
    }
}