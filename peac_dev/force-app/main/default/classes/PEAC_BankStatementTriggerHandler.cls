public with sharing class PEAC_BankStatementTriggerHandler extends SL_Trigger.baseHandler  {
    
    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
    }
    
    public override void beforeInsert(List<SObject> newList){
    }
    
    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        
        FieldChangeTracker.TrackerWrapper trackerDetails = new FieldChangeTracker.TrackerWrapper();
            trackerDetails.newRecordMap = newMap;
            trackerDetails.oldRecordMap = oldMap;
            trackerDetails.objectApiName = 'Bank_Statement__c';
            FieldChangeTracker.trackDetails(trackerDetails);
    }
    
    public override void afterInsert(Map<Id, SObject> newMap){
       // FieldChangeTracker.trackCreateAndDeleteForChilds(newMap,'Bank_Statement__c','Created');
        
    }
    
    public override void beforeDelete(Map<Id, SObject> oldMap) {
        FieldChangeTracker.trackCreateAndDeleteForChilds(oldMap,'Bank_Statement__c','Deleted');
    }
}