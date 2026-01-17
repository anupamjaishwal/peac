public class SL_CollectionAssignmentBatchNew implements Database.Batchable<SObject>, Database.Stateful {
    
    
    public SL_CollectionAssignmentBatchNew(Boolean isFirstDataLoad){
        // SL-2792  deprecated
    }


    public Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id FROM Contract__c WHERE Id = null'); 
    }
    public void execute(Database.BatchableContext BC, List<SObject> scope){
        
    }
    public void finish(Database.BatchableContext BC){
        
    }

}