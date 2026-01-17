public class TC_CalculateAssetCost {
public static void calculateAssetCost (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
        Set <Id> oppIds = new Set <Id> ();
        
        for (Opportunity opp : newMap.values ()) {
            if (opp.Probability >= 75 && oldMap.get (opp.Id).Probability <75) {
                oppIds.add (opp.Id);
            }
        }
        
        if (!oppIds.isEmpty ()) {
            List <Opportunity> oppAssets = new List <Opportunity> ([SELECT Id, Gross_Contract__c, (SELECT Id, Cost__c,Opportunity_Contract_Type__c  FROM Assets__r) FROM Opportunity WHERE Id IN :oppIds]);
            if (!oppAssets.isEmpty ()) {
                for (Opportunity opp : oppAssets) {
                    Decimal cost = 0;
                    for (Asset__c asset : opp.Assets__r) {
                        if (asset.Cost__c  != null) cost += asset.Cost__c ;
                    }
                    
                    if (opp.Assets__r.isEmpty () && newMap.get (opp.Id).Equipment_Cost__c != null) cost = newMap.get (opp.Id).Equipment_Cost__c;
                    
                    if (newMap != null && newMap.get (opp.Id)!= null) newMap.get (opp.Id).Gross_Finance__c = opp.Gross_Contract__c != null ? opp.Gross_Contract__c - cost : 0 - cost;
                    if (newMap != null && newMap.get (opp.Id)!= null) newMap.get (opp.Id).Equipment_Cost__c = cost;
                    
                }
            }
            
        }
    }
}