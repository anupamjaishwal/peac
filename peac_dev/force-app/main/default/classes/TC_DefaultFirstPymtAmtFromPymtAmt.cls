public class TC_DefaultFirstPymtAmtFromPymtAmt {
public static void defaultFirstPaymentAmountFromPaymentAmount (List <Opportunity> newList, Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, List <Opportunity> updateList) {
        if (newList != null) {
            for (Opportunity opp : newList) {
                if (!opp.Variable_Payment__c) opp.First_Payment_Amount__c = opp.Payment_Amount__c;
                //opp.Ending_Pymts_in_Advance__c = opp.Payment_Amount__c; commented out due to ending payment  getting with number of ending payments
                opp.Ending_Pymts_in_Advance__c = (opp.of_ending_payments__c != null && opp.of_ending_payments__c != 0 ? opp.Payment_Amount__c : 0);
            }
        } else if (newMap != null && oldMap != null) {
            for (Opportunity opp : updateList) {
                if (!opp.Variable_Payment__c && (oldMap.get (opp.Id).Payment_Amount__c != opp.Payment_Amount__c || oldMap.get (opp.Id).Variable_Payment__c != opp.Variable_Payment__c) && opp.First_Payment_Amount__c == oldMap.get (opp.Id).First_Payment_Amount__c) opp.First_Payment_Amount__c = opp.Payment_Amount__c;
                if (!opp.Variable_Payment__c && (oldMap.get (opp.Id).Payment_Amount__c != opp.Payment_Amount__c || oldMap.get (opp.Id).Variable_Payment__c != opp.Variable_Payment__c) && opp.Ending_Pymts_in_Advance__c == oldMap.get (opp.Id).Ending_Pymts_in_Advance__c) opp.Ending_Pymts_in_Advance__c = opp.Payment_Amount__c;
                if ((oldMap.get (opp.Id).Payment_Amount__c != opp.Payment_Amount__c || oldMap.get (opp.Id).Variable_Payment__c != opp.Variable_Payment__c)&& opp.Ending_Pymts_in_Advance__c == oldMap.get (opp.Id).Ending_Pymts_in_Advance__c)
                    opp.Ending_Pymts_in_Advance__c = (opp.of_ending_payments__c != null && opp.of_ending_payments__c != 0 ? opp.Payment_Amount__c : 0);
            }
        }
        
    }
}