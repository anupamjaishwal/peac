public class TC_DefaultGrossFinance {
public static void defaultGrossFinance (List <Opportunity> newList, Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, List <Opportunity> updateList) {
        if (newList != null) {
            for (Opportunity opp : newList) {
                if (!opp.Loan_Record_Type__c && !opp.Variable_Payment__c) opp.Gross_Finance__c = opp.Gross_Contract__c != null && opp.Equipment_Cost__c != null ? opp.Gross_Contract__c - opp.Equipment_Cost__c : null;
            }
        } else if (newMap != null && oldMap != null) {
            for (Opportunity opp : updateList) {
                if (!opp.Loan_Record_Type__c && !opp.Variable_Payment__c && (oldMap.get (opp.Id).Equipment_Cost__c != opp.Equipment_Cost__c || oldMap.get (opp.Id).Gross_Contract__c != opp.Gross_Contract__c)) opp.Gross_Finance__c = (opp.Gross_Contract__c == null ? 0 : opp.Gross_Contract__c) - (opp.Equipment_Cost__c == null ? 0 : opp.Equipment_Cost__c);
            }
        }
        
    }
}