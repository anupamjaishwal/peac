public class TC_ChangedToDocsRequested {
    public static void changedToDocsRequested (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap, Map<Id, List<Asset__c>> assets, Map<Id, Asset__c> assetsToUpdateById) {
        Set <Id> oppIds = new Set <Id> ();
        for (Opportunity opp : newMap.values ()) {
            if (opp.Probability >= 75 && oldMap.get (opp.Id).Probability < 75) {
                oppIds.add (opp.Id);
                List<Asset__c> oppAssets = assets.get(opp.Id);
                if(oppAssets != null){
                    for(Asset__c oppAsset : oppAssets){
                        Asset__c withOtherChange = assetsToUpdateById.get(oppAsset.Id);
                        Asset__c assetToUpdate = withOtherChange == null? oppAsset: withOtherChange;
                        TC_AssetTriggerHelper.setAssetFields(assetToUpdate, 'after');
                        assetsToUpdateById.put(assetToUpdate.Id, assetToUpdate);
                    }
                }
            }
        }
    }

    // old kept just for reference
    // public static void changedToDocsRequested (Map <Id, Opportunity> oldMap, Map <Id, Opportunity> newMap) {
    //     Set <Id> oppIds = new Set <Id> ();
    //     for (Opportunity opp : newMap.values ()) {
    //         if (opp.Probability >= 75 && oldMap.get (opp.Id).Probability < 75) {
    //             oppIds.add (opp.Id);
    //         }
    //     }
        
    //     if (!oppIds.isEmpty ()) {
    //         List <Opportunity> oppList = new List <Opportunity> ();
    //         List <Asset__c> assetList = new List <Asset__c> ();
    //         for (Opportunity opp : [SELECT Id, (SELECT Id, Cost__c, List_Price__c, Orig_Cost__c, Upfront_County_Tax_Amount__c, Upfront_City_Transit_Tax_Amount__c, Upfront_City_Tax_Amount__c, Upfront_County_Transit_Tax_Amount__c,Upfront_State_Tax_Amount__c, Financed_Trigger__c, Opportunity_Contract_Type__c  FROM Assets__r) FROM Opportunity WHERE Id IN :oppIds]) {
    //             for (Asset__c asset : opp.Assets__r) {
    //                 TC_AssetTriggerHelper.setAssetFields (asset, 'after');
    //                 assetList.add (asset);
    //             }
    //         }
    //         if (!assetList.isEmpty ()) update assetList;
    //     }
    // }
    
}