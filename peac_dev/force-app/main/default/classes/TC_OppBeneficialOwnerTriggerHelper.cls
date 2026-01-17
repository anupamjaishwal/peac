public class TC_OppBeneficialOwnerTriggerHelper {
    
    public static void createBeneficialOwners (Map <Id, Opportunity_Beneficial_Owner__c> newMap) {
        Set <Id> accIds = new Set <Id> ();
        
        Map <Id, Opportunity_Beneficial_Owner__c> oboMapWithAccId = new Map <Id, Opportunity_Beneficial_Owner__c> ([SELECT Id, Opportunity__r.AccountId FROM Opportunity_Beneficial_Owner__c WHERE Id IN :newMap.keySet ()]);
        
        
        for (Opportunity_Beneficial_Owner__c obo : oboMapWithAccId.values()) {
            if (obo.Opportunity__r.AccountId != null) accIds.add (obo.Opportunity__r.AccountId);
        }
        
        if (!accIds.isEmpty()) {
            
            Map <Id, Set <Id>> accConMap = new Map <Id, Set <Id>> ();
            for (Beneficial_Owner__c bo : [SELECT Id, Contact__c, Account__c FROM Beneficial_Owner__c WHERE Account__c IN :accIds]) {
                if (accConMap.get (bo.Account__c) != null) {
                    accConMap.get (bo.Account__c).add (bo.Contact__c);
                } else {
                    accConMap.put (bo.Account__c, new Set <Id> {bo.Contact__c});
                }
            }
            
            List <Beneficial_Owner__c> insertList = new List <Beneficial_Owner__c> ();
            
            for (Opportunity_Beneficial_Owner__c obo : newMap.values ()) {
                if (oboMapWithAccId.get (obo.Id).Opportunity__r.AccountId != null && accConMap.get (oboMapWithAccId.get (obo.Id).Opportunity__r.AccountId) != null && !accConMap.get (oboMapWithAccId.get (obo.Id).Opportunity__r.AccountId).contains (obo.Contact__c)) {
                    insertList.add (new Beneficial_Owner__c (Contact__c = obo.Contact__c
                                                            , Account__c = oboMapWithAccId.get (obo.Id).Opportunity__r.AccountId
                                                            , Ownership_Percent__c = obo.Ownership_Percent__c));
                }
            }
            
            if (!insertList.isEmpty()) insert insertList;
        }
    }
}