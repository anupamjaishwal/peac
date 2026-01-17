public with sharing class PEAC_BankInformationTriggerHandler extends SL_Trigger.baseHandler  {
    
    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
    }
    
    public override void beforeInsert(List<SObject> newList){
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        
       /* FieldChangeTracker.TrackerWrapper trackerDetails = new FieldChangeTracker.TrackerWrapper();
        trackerDetails.newRecordMap = newMap;
        trackerDetails.oldRecordMap = oldMap;
        trackerDetails.objectApiName = 'Financial_Bank_Information__c';
        FieldChangeTracker.trackDetails(trackerDetails);*/
    }
    
    public override void afterInsert(Map<Id, SObject> newMap){
       // FieldChangeTracker.trackCreateAndDeleteForChilds(newMap,'Financial_Bank_Information__c','Created');
        PEAC_BankInformationTriggerHelper.setIndicator(newMap);
    }
    
    public override void beforeDelete(Map<Id, SObject> oldMap) {
       // FieldChangeTracker.trackCreateAndDeleteForChilds(oldMap,'Financial_Bank_Information__c','Deleted');
    }

    public override void afterDelete(Map<Id, SObject> oldMap) {
       // FieldChangeTracker.trackCreateAndDeleteForChilds(oldMap,'Financial_Bank_Information__c','Deleted');
       PEAC_BankInformationTriggerHelper.setIndicator(oldMap);
    }
}