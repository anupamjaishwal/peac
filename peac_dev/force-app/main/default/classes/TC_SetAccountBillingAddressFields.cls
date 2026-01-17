public class TC_SetAccountBillingAddressFields {
public static void setAccountBillingAddressFields (List <Opportunity> newList) {
        ORE__c ore = ORE__c.getOrgDefaults ();
        if (!ore.Bypass__c) {
            
            Set <Id> accIds = new Set <Id> ();
            for (Opportunity opp : newList) {
                if (opp.AccountId != null) accIds.add (opp.AccountId);
            }
            
            Map <Id, Account> accMap = new Map <Id, Account> ([SELECT Id, Account_Billing_City__c, Account_Billing_Country__c, Account_Billing_State_Province__c, Account_Billing_Street__c, Account_Billing_Street2__c, Account_Billing_Zip_Postal_Code__c FROM Account WHERE Id IN :accIds]);
            
            for (Opportunity opp : newList) {
                Account acc = accMap.get (opp.AccountId);
                if (opp.AccountId != null && acc != null){
                    TC_AccountTriggerHelper.setOpportunityBillingFields(opp, acc);
                }
            }
        }
    }
}