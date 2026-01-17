public class TC_VariablePaymentsDefaultGrossContract {
public static void variablePaymentsDefaultGrossContract (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        Set <Id> oppIds = new Set <Id> ();
        
        for (Opportunity opp : newMap.values ()) {
            if (!opp.Loan_Record_Type__c && opp.Variable_Payment__c && ((opp.Variable_Payment__c != oldMap.get (opp.Id).Variable_Payment__c) || (opp.Ending_Pymts_in_Advance__c != oldMap.get (opp.Id).Ending_Pymts_in_Advance__c ))) {
                oppIds.add (opp.Id);
            }
        }
        
        System.debug ('>>>>> oppIds: ' + oppIds);
        if (!oppIds.isEmpty ()) {
            for (Opportunity opp : [SELECT Id, Gross_Contract__c, Equipment_Cost__c, Ending_Pymts_in_Advance__c,(SELECT Id, Total__c, of_payments__c, Payment_Amount__c FROM Variable_Payments__r) FROM Opportunity WHERE Id IN :oppIds]) {
                Decimal numOfPayments = 0;
                Decimal sumPaymentAmount = newMap.get (opp.Id).Ending_Pymts_in_Advance__c != null ? newMap.get (opp.Id).Ending_Pymts_in_Advance__c : 0;
                for (Variable_Payment__c vp : opp.Variable_Payments__r) {
                    if (vp.of_payments__c != null) numOfPayments += vp.of_payments__c ;
                    if (vp.of_payments__c != null && vp.Payment_Amount__c != null) sumPaymentAmount += vp.of_payments__c * vp.Payment_Amount__c;
                }
                System.debug ('>>>>> sumPaymentAmount: ' + sumPaymentAmount);
                newMap.get (opp.Id).Gross_Contract__c = sumPaymentAmount;
                newMap.get (opp.Id).Variable_Payments_of_Payments__c = numOfPayments;
                newMap.get (opp.Id).Gross_Finance__c = sumPaymentAmount - (opp.Equipment_Cost__c != null ? opp.Equipment_Cost__c : 0);
                //updateList.add (new Opportunity (Id = opp.Id, Gross_Finance__c = sumPaymentAmount, Variable_Payments_of_Payments__c = numOfPayments));
            }
            
            //if (!updateList.isEmpty ()) update updateList;
        }
        
    }
}