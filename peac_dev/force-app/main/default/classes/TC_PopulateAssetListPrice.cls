public class TC_PopulateAssetListPrice {
    public static void populateAssetListPrice (Opportunity opp, List<String> fieldsChanged, Map<Id, List<Asset__c>> assets, Map<Id, Asset__c> assetsToUpdateById) {
        
        if (fieldsChanged != null && fieldsChanged.contains('Equipment_Cost__c') 
            && TC_AssetTriggerHelper.canUpdateAssetWithEquipmentCost (isSalesProfile(opp.Opportunity_CurrentUser_Profile__c), opp)
            && opp.Number_of_Assets__c == 1
            && System.UserInfo.getFirstName() != 'User' && System.UserInfo.getLastName() != 'Bhoomi'){
            List<Asset__c> oppAssets = assets.get(opp.Id);
            if(oppAssets != null){
                Asset__c withOtherChange = assetsToUpdateById.get(oppAssets[0].Id);
                Asset__c assetToUpdate = withOtherChange == null? oppAssets[0]: withOtherChange;
                if(opp.Equipment_Cost__c != assetToUpdate.Cost__c){
                    assetToUpdate.Cost__c = opp.Equipment_Cost__c;
                    assetsToUpdateById.put(assetToUpdate.Id, assetToUpdate);
                }
            }
        }
    }

    public static Boolean isSalesProfile(String profileName){
        return profileName.containsIgnoreCase('rep') || profileName.containsIgnoreCase('manager') || profileName.containsIgnoreCase('mgr');
    }

    // old kept just for reference
    // public static void populateAssetListPrice (Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
    //     Set <Id> oppIds1 = new Set <Id> ();
    //     Set <Id> oppIds = new Set <Id> ();
        
    //     for (Opportunity opp : newMap.values ()) {
    //         if (opp.Equipment_Cost__c != oldMap.get (opp.Id).Equipment_Cost__c) oppIds1.add (opp.Id);
    //     }
        
    //     if (!oppIds1.isEmpty()) {
    //         Boolean isSalesUser = TC_AssetTriggerHelper.checkIfSalesUser ();
    //         System.debug ('>>>>> is sales user: ' + isSalesUser);
    //         for (Opportunity opp : newMap.values ()) {
    //             System.debug ('>>>>> TC_AssetTriggerHelper.canUpdateAssetWithEquipmentCost (isSalesUser, opp): ' + TC_AssetTriggerHelper.canUpdateAssetWithEquipmentCost (isSalesUser, opp));
    //             if (TC_AssetTriggerHelper.canUpdateAssetWithEquipmentCost (isSalesUser, opp) && opp.Equipment_Cost__c != oldMap.get (opp.Id).Equipment_Cost__c) oppIds.add (opp.Id);
    //         }
    //     }
    //     if (!oppIds.isEmpty ()) {
    //         List <Asset__c> assets = new List <Asset__c> ();
    //         for (Opportunity opp : [SELECT Id, Equipment_Cost__c, (SELECT Id, Cost__c,Opportunity_Contract_Type__c FROM Assets__r) FROM Opportunity WHERE Id IN :oppIds]) {
    //             if (!opp.Assets__r.isEmpty () && opp.Assets__r.size () == 1 && opp.Equipment_Cost__c != opp.Assets__r[0].Cost__c) 
    //                 assets.add (new Asset__c (Id = opp.Assets__r[0].Id, Cost__c = opp.Equipment_Cost__c));
    //         }
            
    //         if (!assets.isEmpty ()) update assets;
            
    //     }
    // }
    
}