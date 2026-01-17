public class TC_CreateOpportunityBeneficialOwners {
public static void createOpportunityBeneficialOwners (Map <Id, Opportunity> newMap) {
        
        Map <Id, List <Opportunity>> accOppMap = new Map <Id, List <Opportunity>> ();
        
        for (Opportunity opp : newMap.values()) {
            if(opp.Loan_Record_Type__c){ // not for Lease apps as per DP-1469
                if (accOppMap.get (opp.AccountId) != null) {
                    accOppMap.get (opp.AccountId).add (opp);
                } else {
                    accOppMap.put (opp.AccountId, new List <Opportunity> {opp});
                }
            }
        }
        
        if (!accOppMap.isEmpty ()) {
            
            List <Opportunity_Beneficial_Owner__c> insertList = new List <Opportunity_Beneficial_Owner__c> ();
            
            for (Beneficial_Owner__c bo : [SELECT Id, Account__c, Contact__c, Ownership_Percent__c FROM Beneficial_Owner__c WHERE Account__c IN :accOppMap.keySet()]) {
                for (Opportunity opp : accOppMap.get (bo.Account__c)) {
                    insertList.add (new Opportunity_Beneficial_Owner__c (Opportunity__c = opp.Id
                                                                         , Contact__c = bo.Contact__c
                                                                         , Ownership_Percent__c = bo.Ownership_Percent__c));
                }
                
            }
            
            if (!insertList.isEmpty()) insert insertList;
        }
        
    }
}