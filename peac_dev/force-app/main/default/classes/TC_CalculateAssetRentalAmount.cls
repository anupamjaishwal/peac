public class TC_CalculateAssetRentalAmount {
public static void calculateAssetRentalAmount (Map <Id, Asset__c> oldMap, List <Asset__c> newList) {
        /*if (TC_RecursiveTriggerHelper.calculateAssetRentalAmount) {
            return;
        } else {
            TC_RecursiveTriggerHelper.calculateAssetRentalAmount = true;
        }*/
        Set <Id> oppIds = new Set <Id> ();
        
        if (newList == null) {
            for (Asset__c asset : oldMap.values ()) {
                oppIds.add (asset.Opportunity__c);
            }
        } else {
            for (Asset__c asset : newList) {
                if (oldMap == null || oldMap.get (asset.Id).List_Price__c != asset.List_Price__c)
                    oppIds.add (asset.Opportunity__c);
            }
        }
        
        TC_CalculateAssetRentalAmt.calculateAssetRentalAmount (oppIds);
    }
}