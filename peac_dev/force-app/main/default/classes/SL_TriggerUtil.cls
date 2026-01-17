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