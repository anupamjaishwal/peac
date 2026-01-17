public class TC_SetOpportunityBillingFields {
public static void setOpportunityBillingFields (Opportunity opp, Account acc) {
        opp.Account_Billing_City__c = acc.Account_Billing_City__c;
        opp.Account_Billing_Country__c = acc.Account_Billing_Country__c;
        opp.Account_Billing_State_Province__c = acc.Account_Billing_State_Province__c;
        opp.Account_Billing_Street2__c = acc.Account_Billing_Street2__c;
        opp.Account_Billing_Street__c = acc.Account_Billing_Street__c;
        opp.Account_Billing_Zip_Postal_Code__c = acc.Account_Billing_Zip_Postal_Code__c;
    }
}