public class TC_CheckVariablePayments {
    public static Marlin_Configuration__c config = Marlin_Configuration__c.getOrgDefaults ();
public static void checkVariablePayments (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        ORE__c ore = ORE__c.getOrgDefaults ();
        if (ore.Bypass__c) return;
        
        Set <Id> oppIds = new Set <Id> ();
        for (Opportunity opp : newMap.values ()) {
            if (!opp.Loan_Record_Type__c && oldMap.get (opp.Id).StageName != opp.StageName && opp.Probability >= 95 && !opp.Variable_Payment__c ) oppIds.add (opp.Id);
        }
        if (!oppIds.isEmpty ()) {
            for (Opportunity opp : [SELECT Id, (SELECT Id FROM Variable_Payments__r) FROM Opportunity WHERE Id IN :oppIds]) {
                if (!opp.Variable_Payments__r.isEmpty () && config != null && config.Apex_Validations_Active__c && newMap.get (opp.Id).StageName != 'Funded/Booked' ) {
                    newMap.get(opp.Id).Variable_Payment__c.addError ('Please check the Variable Payment checkbox if variable payments exist on the Opportunity.');
                }
            }
        }
    }
}