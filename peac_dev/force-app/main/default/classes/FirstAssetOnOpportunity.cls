public class FirstAssetOnOpportunity {
    
    // public void onAfterInsert(List<Asset__c> Asset)
	// {
	// 	updateFirstAsset(Asset);
	// }
	
	// public void onAfterDelete(List<Asset__c> Asset)
	// {
	// 	updateFirstAsset(Asset);
	// }
	
	public static void updateFirstAsset(List<Asset__c> deletedFirstAssets, Map<Id, Opportunity> opps, Map<Id, Asset__c> assetsToUpdateById){
		Set<Id> oppIds = new Set<Id>();
		for(Asset__c deletedAsset : deletedFirstAssets){
			Opportunity relatedOpp = opps.get(deletedAsset.Opportunity__c);
			if(relatedOpp != null && relatedOpp.Number_of_Assets__c > 0){
				oppIds.add(deletedAsset.Opportunity__c);
			}
		}
		if(oppIds.size() > 0){
			for(AggregateResult firstAssetByOpp : [SELECT Opportunity__c, MIN(Id) firstId FROM Asset__c WHERE First_Record__c = false AND Opportunity__c In :oppIds GROUP BY Opportunity__c]){
				Id newFirstAssetId = (Id)firstAssetByOpp.get('firstId');
				Asset__c toUpdate = assetsToUpdateById.get(newFirstAssetId);
				if(toUpdate == null){
					toUpdate = new Asset__c(Id = newFirstAssetId);
				}
				toUpdate.First_Record__c = true;
				assetsToUpdateById.put(toUpdate.Id, toUpdate);
			}
		}
		
		// Set<Id> setOpportunity = new Set<id>();
		// Map<Id,Asset__c> mapOppIdToAssetId = new Map<Id,Asset__c>();
		// for(Asset__c obj : Asset)
		// {
		// 	if(obj.Opportunity__c!=null)
		// 		setOpportunity.add(obj.Opportunity__c);
		// }
		
		// for(Asset__c obj : [select Id, Opportunity__c FROM Asset__c WHERE Opportunity__c In : setOpportunity ORDER BY CreatedDate DESC])
		// 	mapOppIdToAssetId.put(obj.Opportunity__c, new Asset__c(id = obj.Id, First_Record__c = true));
		// update mapOppIdToAssetId.values();
	}

}