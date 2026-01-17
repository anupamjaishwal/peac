public class TC_CheckForBillingContact {
    public static Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
public static void checkForBillingContact (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        ORE__c ore = ORE__c.getOrgDefaults ();
        if (ore.Bypass__c) return;
        
        Set <Id> oppIds = new Set <Id> ();
        for (Opportunity opp : newMap.values ()) {
            if (!opp.Loan_Record_Type__c && oldMap.get (opp.Id).StageName != opp.StageName && opp.Probability >= 93) oppIds.add (opp.Id);
        }
        if (!oppIds.isEmpty ()) {
            List <OpportunityContactRole> roles = new List <OpportunityContactRole> ([SELECT OpportunityId, Role, IsPrimary  FROM OpportunityContactRole WHERE OpportunityId IN :oppIds]);
            Map <Id, Boolean> hasBilling = new Map <Id, Boolean> ();
            for (OpportunityContactRole role : roles) {
                if (role.Role == 'Billing Contact') hasBilling.put (role.OpportunityId, true);
            }
            
            for (Opportunity opp : newMap.values ()) {
                if (hasBilling.get (opp.Id) == null && opp.StageName != 'Funded/Booked' && config != null && config.Apex_Validations_Active__c) opp.StageName.addError (Label.TC_No_Billing_Contact);
            }
        }
    }
}