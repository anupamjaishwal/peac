public class TC_DefaultGrossContract {
public static void defaultGrossContract (List <Opportunity> newList, Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, List <Opportunity> updateList) {
        if (newList != null) {
            for (Opportunity opp : newList) {
                if (!opp.Loan_Record_Type__c && !opp.Variable_Payment__c) TC_CalculateGrossContract.calculateGrossContract (opp);
            }
        } else if (newMap != null && oldMap != null) {
            for (Opportunity opp : updateList) {
                if (!opp.Loan_Record_Type__c && !opp.Variable_Payment__c && (oldMap.get (opp.Id).of_Payments__c != opp.of_Payments__c || oldMap.get (opp.Id).Payment_Amount__c != opp.Payment_Amount__c || oldMap.get (opp.Id).First_Payment_Amount__c != opp.First_Payment_Amount__c || oldMap.get (opp.Id).Variable_Payment__c != opp.Variable_Payment__c  || oldMap.get (opp.Id).Ending_Pymts_in_Advance__c != opp.Ending_Pymts_in_Advance__c || oldMap.get (opp.Id).of_ending_payments__c  != opp.of_ending_payments__c )) TC_CalculateGrossContract.calculateGrossContract (opp);
            }
        }
    }
}