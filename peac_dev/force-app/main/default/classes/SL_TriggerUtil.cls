public with sharing class SL_TriggerUtil {
    public static void findChangedFields(Id recordId,SObject newRecord, SObject oldRecord, Map<Id, List<String>> fieldsChangedById, List<String> fieldsToCheck) {
        for(String fieldToCheck : fieldsToCheck){
            if(newRecord.get(fieldToCheck) != oldRecord.get(fieldToCheck)){
                List<String> existingFields = fieldsChangedById.get(recordId);
                if(existingFields == null){
                    existingFields = new List<String>();
                }
                existingFields.add(fieldToCheck);
                fieldsChangedById.put(recordId, existingFields);
            }
        }
    }
    //SAL-5692 Expo: Opportunity Refactor
    public static void identifyChangedFieldsBulk(Map<Id, Asset__c> oldMap, Map<Id, Asset__c> newMap, Map<Id, List<String>> fieldsChangedById, List<String> fieldsToCheck) {
        for(Id assetId : newMap.keySet()){
            for(String fieldToCheck : fieldsToCheck){
                if(newMap.get(assetId).get(fieldToCheck) != oldMap.get(assetId).get(fieldToCheck)){
                    if(fieldsChangedById.get(assetId) == null){
                        fieldsChangedById.put(assetId, new List<String>{fieldToCheck});
                    }else{
                        fieldsChangedById.get(assetId).add(fieldToCheck);
                    }
                }
            }
        }
    }

    public static Boolean checkForMissingInfo(List<SObject> records){
        Boolean isMissingInfo = false;
        for(SObject obj :records){
            if(obj?.Id == null){
                isMissingInfo = true;
                break;
            }
        }
        return isMissingInfo;
    }
}