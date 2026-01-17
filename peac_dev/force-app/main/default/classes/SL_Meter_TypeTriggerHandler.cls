public with sharing class SL_Meter_TypeTriggerHandler extends SL_Trigger.baseHandler {
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    Map<Id, Asset__c> assets = new Map<Id, Asset__c>();

    public override void beforeInsert(List<SObject> newList){
        // for(SObject obj : newList){
        //     getLookupMaps(obj);
        // }
        // getInfoFromOthers(new Map<Id, SObject>());
        
        // beforeChangesToSelf(newList, true);
        Map<Id, Opportunity> oppAssetMap = new Map<Id, Opportunity>();
        for(SObject obj : newList){
            Meter_Type__c newMeterType = (Meter_Type__c)obj;
            if(newMeterType.Asset__c <> null){
                oppAssetMap.put(newMeterType.Asset__c, null);
            }
        }
        for(Asset__c ass : [SELECT Id, Opportunity__c, Opportunity__r.StageName FROM Asset__c WHERE Id IN :oppAssetMap.keySet() AND Opportunity__r.StageName = 'Funded/Booked']){
            oppAssetMap.put(ass.Id, ass.Opportunity__r);
        }
        for(SObject obj : newList){
            Meter_Type__c newMeterType = (Meter_Type__c)obj;
            if(newMeterType.Asset__c <> null && oppAssetMap.get(newMeterType.Asset__c) <> null){
                obj.addError('You are not allowed to Create/Edit/Delete  Meter type if the opportunity is booked.');
            }
        }
    }
    
    public override void afterInsert(Map<Id, SObject> newMap){
        // for(SObject obj : newMap.values()){
        //     getLookupMaps(obj);
        // }
        // getInfoFromOthers(newMap);
        // afterChangesToOthers(newMap, true);
    }

    public override void afterDelete(Map<Id, SObject> oldMap){
        for(SObject obj : oldMap.values()){
            getLookupMaps(obj);
        }
        getInfoFromOthers(oldMap);
        Set<Id> oppIdsToCheck = new Set<Id>();
        Map<Id, Opportunity> oppsToUpdateById = new Map<Id, Opportunity>();
        Map<Id, Integer> deletedMTByAssetId = new Map<Id, Integer>();
        for(SObject obj : oldMap.values()){
            Meter_Type__c meterType = (Meter_Type__c)obj;
            Asset__c relatedAsset = assets.get(meterType.Asset__c);
            Integer mtDeletedSoFar = deletedMTByAssetId.get(meterType.Asset__c);
            if(mtDeletedSoFar != null){
                deletedMTByAssetId.put(meterType.Asset__c, mtDeletedSoFar++);
            }else{
                deletedMTByAssetId.put(meterType.Asset__c, 1);
            }
            mtDeletedSoFar = deletedMTByAssetId.get(meterType.Asset__c);
            if(relatedAsset != null && relatedAsset.Opportunity__c != null && relatedAsset.Opportunity__r.CPC__c){
                if(relatedAsset.Total_Meter_Types__c == mtDeletedSoFar){
                    oppIdsToCheck.add(relatedAsset.Opportunity__c);
                }
            }
        }
        if(oppIdsToCheck.size() > 0){
            Set<Id> noNeedToUpdate = new Set<Id>();
            for(Asset__c assetWithMeterType : [SELECT Id, Opportunity__c, Total_Meter_Types__c 
                FROM Asset__c WHERE Opportunity__c IN:oppIdsToCheck AND Total_Meter_Types__c > 0]){
                if(!deletedMTByAssetId.containsKey(assetWithMeterType.Id)){
                    noNeedToUpdate.add(assetWithMeterType.Opportunity__c);
                }
            }
            for(Id idToCheck :oppIdsToCheck){
                if(!noNeedToUpdate.contains(idToCheck)){
                    oppsToUpdateById.put(idToCheck, new Opportunity(Id = idToCheck, CPC__c = false));
                }
            }
        }
        if(oppsToUpdateById.keySet().size() > 0){
            update oppsToUpdateById.values();
        }
    }
    public override void beforeUpdate(Map<Id, SObject> newMap,Map<Id, SObject> oldMap){
       
        Map<Id, Opportunity> oppAssetMap = new Map<Id, Opportunity>();
        for(SObject obj : oldMap.values()){
            Meter_Type__c newMeterType = (Meter_Type__c)obj;
            Meter_Type__c oldMeterType  = (Meter_Type__c)oldMap.get(obj.Id);
            if(oldMeterType.Asset__c <> null){
                oppAssetMap.put(oldMeterType.Asset__c, null);
            }
        }
        for(Asset__c ass : [SELECT Id, Opportunity__c, Opportunity__r.StageName FROM Asset__c WHERE Id IN :oppAssetMap.keySet() AND Opportunity__r.StageName = 'Funded/Booked']){
            oppAssetMap.put(ass.Id, ass.Opportunity__r);
        }
        for(SObject obj : oldMap.values()){
            Meter_Type__c newMeterType = (Meter_Type__c)obj;
            if(newMeterType.Asset__c <> null && oppAssetMap.get(newMeterType.Asset__c) <> null){
                obj.addError('You are not allowed to Create/Edit/Delete  Meter type if the opportunity is booked.');
            }
        }
    }
    
    public override void beforeDelete(Map<Id, SObject> oldMap){
       
        Map<Id, Opportunity> oppAssetMap = new Map<Id, Opportunity>();
        for(SObject obj : oldMap.values()){
            Meter_Type__c oldMeterType  = (Meter_Type__c)oldMap.get(obj.Id);
            if(oldMeterType.Asset__c <> null){
                oppAssetMap.put(oldMeterType.Asset__c, null);
            }
        }
        for(Asset__c ass : [SELECT Id, Opportunity__c, Opportunity__r.StageName FROM Asset__c WHERE Id IN :oppAssetMap.keySet() AND Opportunity__r.StageName = 'Funded/Booked']){
            oppAssetMap.put(ass.Id, ass.Opportunity__r);
        }
        for(SObject obj : oldMap.values()){
            Meter_Type__c newMeterType = (Meter_Type__c)obj;
            if(newMeterType.Asset__c <> null && oppAssetMap.get(newMeterType.Asset__c) <> null){
                obj.addError('You are not allowed to Create/Edit/Delete  Meter type if the opportunity is booked.');
            }
        }
    }

    private void getLookupMaps(SObject obj){
        Meter_Type__c meterType = (Meter_Type__c)obj;
        if(meterType.Id != null){
            // this.childRecords.put(meterType.Id, new List<childObject>());
        }
        if(meterType.Asset__c != null){
            this.assets.put(meterType.Asset__c, new Asset__c());
        }
    }

    private void getInfoFromOthers(Map<Id, SObject> newMap){
        if(newMap.size() > 0){
            for(Meter_Type__c related :[SELECT Id, Asset__r.Total_Meter_Types__c, Asset__r.Opportunity__c,
                Asset__r.Opportunity__r.CPC__c
                FROM Meter_Type__c
                WHERE Id IN :newMap.keySet()]){
                if(related.Asset__c != null){
                    assets.put(related.Asset__c, related.Asset__r);
                }
                // for(childObject contractWithInfo : related.Customer_Contracts__r){
                //     this.childRecords.get(contractWithInfo.Customer__c).add(contractWithInfo);
                // }
                
                // List<Opportunity> relatedOpps = new List<Opportunity>();
                // for(Opportunity opp : related.Opportunities){
                //     relatedOpps.add(opp);
                // }
                // this.opportunities.put(related.Id, relatedOpps);
            }
        }
        if(assets.size() > 0 && checkForMissingInfo(assets.values())){
            assets.putAll([SELECT Id, Total_Meter_Types__c, Opportunity__c,
                Opportunity__r.CPC__c FROM Asset__c WHERE Id IN :assets.keySet()]);
        }
    }

    Boolean checkForMissingInfo(List<SObject> records){
        Boolean isMissingInfo = false;
        for(SObject obj :records){
            if(obj.Id == null){
                isMissingInfo = true;
                break;
            }
        }
        return isMissingInfo;
    }
    
    
}