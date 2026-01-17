public class SL_Contract_AssetTriggerHandler extends SL_Trigger.baseHandler {
    public override void beforeInsert(List<SObject> newList){
        List<Contract_Asset__c> assetList = new List<Contract_Asset__c>();
        for(SObject theObject :newList){
            assetList.add((Contract_Asset__c)theObject);
        }
        beforeChangesToSelf(assetList);

        for(Contract_Asset__c asset :assetList){
            if(asset.Status2__c != null){
                asset.Status_Date__c = Date.Today();
            }
        }
    }

    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        // checkUpdatedFields(oldMap, newMap);
        List<Contract_Asset__c> assetList = new List<Contract_Asset__c>();
        for (Id assetId :newMap.keySet()){
            assetList.add((Contract_Asset__c)newMap.get(assetId));
        }
        beforeChangesToSelf(assetList);
        updateServiceProvider(assetList, oldMap);
        dataLoaderConditionProceedsCheck(assetList);
        for(Contract_Asset__c asset :assetList){
            Contract_Asset__c oldRecord = (Contract_Asset__c)oldMap.get(asset.Id);
            if(asset.Status2__c != oldRecord.Status2__c){
                asset.Status_Date__c = Date.Today();
            }
        }
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        System.debug('### AFTER UPDATE: '+ System.isFuture() + '    '+System.isBatch());
        //push to Bridgeware to Sync with Infolease
        if(!SL_InfoleaseUtils.isRecursive && !System.isFuture() && !System.isBatch()){
            Map <Id, Contract_Asset__c> oldMapAsset = new Map <Id, Contract_Asset__c>();
            Map <Id, Contract_Asset__c> newMapAsset = new Map <Id, Contract_Asset__c>();
            for (SObject theObj : oldMap.values()){
                oldMapAsset.put(theObj.Id, (Contract_Asset__c)theObj);
                newMapAsset.put(theObj.Id, ((Contract_Asset__c)newMap.get(theObj.Id)));
            }
            SL_InfoleaseAssetController.updateAsset(oldMapAsset, newMapAsset);
        }
        //Must alway be last in afterUpdate processes
       	turnoffUpload(newMap);
    }

    private void beforeChangesToSelf(List<Contract_Asset__c> newList){
        Map<Id, Contract__c> contracts = new Map<Id, Contract__c>();
        List<Contract_Asset__c> childrenOfContract = new List<Contract_Asset__c>();
        for (Contract_Asset__c asset :newList){
            if(asset.Contract__c != null){
                contracts.put(asset.Contract__c, new Contract__c());
                childrenOfContract.add(asset);
            }
            conditionStatusUpdate(asset);
        }
        contracts.putAll([SELECT Insurance__c FROM Contract__c WHERE Id IN :contracts.keySet()]);
        for (Contract_Asset__c asset :childrenOfContract){
            Contract__c contract = contracts.get(asset.Contract__c);
            if(contract.Insurance__c != null && asset.Titled_Asset__c != 'Y' && asset.Insurance__c != contract.Insurance__c){
                asset.Insurance__c= contract.Insurance__c;
            }
        }
    }
    
    private void dataLoaderConditionProceedsCheck(List<Contract_Asset__c> assetList){        
		boolean duplicateFlag = false;        
        List<Contract_Asset__c> duplicateDetected = new List<Contract_Asset__c>(); 
        for(Contract_Asset__c ca:assetList){
            if(ca.File_Upload__c == 'Condition'||ca.File_Upload__c == 'Proceeds'){
                for(Contract_Asset__c assetControl:assetList){
                    if(ca.Id<>assetControl.Id){
                        if(ca.Serial_Number__c==assetControl.Serial_Number__c){
                            duplicateFlag = true;
                            duplicateDetected.add(assetControl);
                        }
                    }
                }
                if(duplicateFlag == true){
                    duplicateDetected.add(ca);
                    duplicateFlag = false;
                }
            }
        }
        if(duplicateDetected.size()>0){
            for(Contract_Asset__c errorPost:duplicateDetected){
                errorPost.addError('There are more than one contract assets with this Serial Number, we cannot update this record');
            }
        }
    }
    private void conditionStatusUpdate(Contract_Asset__c ca){
        if(ca.File_Upload__c == 'Condition'){
            ca.Condition_Updated__c = Date.Today();       
        	if(ca.Equipment_Received_Date__c <> NULL && ca.Equipment_Recycled_Date__c == NULL && ca.Sold__c == NULL){
            	ca.Status2__c = 'Equipment Received';
        	}else if(ca.Equipment_Received_Date__c <> NULL && ca.Equipment_Recycled_Date__c <> NULL && ca.Sold__c == NULL){
            	ca.Status2__c = 'Recycled';
        	}else if(ca.Equipment_Received_Date__c <> NULL && ca.Equipment_Recycled_Date__c == NULL && ca.Sold__c <> NULL){
            	ca.Status2__c = 'Sold';
        	}            
        }
        if(ca.File_Upload__c == 'Proceeds')
        {
            ca.Status2__c = 'Proceeds Received';
            ca.Proceeds_Received_Date__c = Date.Today();
        }
    }
    
    private void turnoffUpload (Map<Id, SObject> uploadList){
        //Must alway be last in afterUpdate processes
        
        List<Contract_Asset__c> updateList = new List<Contract_Asset__c>();
        for(SObject obj : uploadList.values()){
            Contract_Asset__c ca = (Contract_Asset__c) obj;
            if(ca.File_Upload__c == 'Proceeds'||ca.File_Upload__c=='Condition'){
				Contract_Asset__c ca2 = new Contract_Asset__c();
                ca2.Id = ca.Id;
                ca2.File_Upload__c = null;
                updateList.add(ca2);
            }
        }
        if(updateList.size()>0){
            update updateList;            
        }
    }

    private static void updateServiceProvider(List<Contract_Asset__c> assetList, Map<Id, SObject> oldMap) {
        Set<Id> locationIds = new Set<Id>();
        for (Contract_Asset__c asset : assetList) {
            Contract_Asset__c oldRecord = (Contract_Asset__c)oldMap.get(asset.Id);
            if (asset.Location__c != oldRecord.Location__c) {
                locationIds.add(asset.Location__c);
            }
        }

        if (!locationIds.isEmpty()) {
            Map<Id, Schema.Location> locations = new Map<Id, Schema.Location>();
            for (Schema.Location l : [SELECT Id, Service_Provider__c FROM Location WHERE Id IN :locationIds]) {
                locations.put(l.Id, l);
            }

            for (Contract_Asset__c asset : assetList) {
                if (locations.containsKey(asset.Location__c)) {
                    asset.Service_Provider__c = locations.get(asset.Location__c).Service_Provider__c;
                }
            }
        }
    }

}