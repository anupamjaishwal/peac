public class TC_CalculateGrossContract {
public static void calculateGrossContract (Opportunity opp) {
        Decimal numOfPayments = opp.of_Payments__c == null ? 0 : opp.of_Payments__c;
        Decimal firstPayment = 0;
        Decimal endingPayment = 0;
        Decimal paymentAmount = opp.Payment_Amount__c == null ? 0 : opp.Payment_Amount__c;
        if (opp.First_Payment_Amount__c != null && opp.First_Payment_Amount__c != 0 ) {
            numOfPayments--;
            firstPayment = opp.First_Payment_Amount__c.setScale(2, RoundingMode.HALF_UP);
        }
        if (opp.Ending_Pymts_in_Advance__c != null && opp.Ending_Pymts_in_Advance__c != 0 && opp.of_ending_payments__c != null) {
            numOfPayments -= opp.of_ending_payments__c;
            endingPayment = opp.Ending_Pymts_in_Advance__c.setScale(2, RoundingMode.HALF_UP);
        }
        opp.Gross_Contract__c = numOfPayments != 0 && paymentAmount != 0 ? firstPayment + endingPayment + (numOfPayments * paymentAmount.setScale(2, RoundingMode.HALF_UP)) : null;
        if (opp.Equipment_Cost__c != null && opp.Gross_Contract__c != null) {
            opp.Gross_Finance__c = opp.Gross_Contract__c - opp.Equipment_Cost__c;
        } else {
            opp.Gross_Finance__c = 0;
        }
    }
}