public class SL_InfoleaseContractBatchQueueable implements Queueable, Database.AllowsCallouts {
    private List<Contract__c> validContractList;
    private Map<Contract__c, Set<String>> conToFieldsMap;
    private Boolean listMap;

    public SL_InfoleaseContractBatchQueueable(List<Contract__c> validContractList, Map<Contract__c, Set<String>> conToFieldsMap, Boolean listMap) {
        this.validContractList = validContractList;
        this.conToFieldsMap = conToFieldsMap;
        this.listMap = listMap;
    }

    public void execute(QueueableContext context) {
        // SL-2703 Misael Romero
        Integer enqueuedBatchJobs = [SELECT COUNT() FROM AsyncApexJob 
            WHERE JobType='BatchApex' AND ApexClass.Name = 'SL_InfoleaseContractQueueable' AND Status IN ('Processing','Preparing','Queued', 'Holding')];
        if(enqueuedBatchJobs < 1){
            String jobId = Database.executeBatch(new SL_InfoleaseContractQueueable(validContractList, conToFieldsMap, listMap), 
                Integer.valueOf(Label.SL_MaxCalloutsToIL));
        }else{
            List<IL_Update__c> pendingUpdates = new List<IL_Update__c>();
            for(Contract__c updatedContract : listMap? validContractList: new List<Contract__c>(conToFieldsMap.keySet())){
                IL_Update__c pendingUpdate = new IL_Update__c();
                pendingUpdate.Record_Id__c = updatedContract.Id;
                if(!listMap){
                    pendingUpdate.Fields_To_Update__c = String.join(new List<String>(conToFieldsMap.get(updatedContract)), ',');
                }
                pendingUpdates.add(pendingUpdate);
            }
            insert pendingUpdates;
            // if(System.Limits.getQueueableJobs() < System.Limits.getLimitQueueableJobs()) {
            //     System.enqueueJob(new SL_InfoleaseContractBatchQueueable(validContractList, conToFieldsMap, listMap));
            // }else{
            //     throw new AsyncException('Queueable jobs limit has been reached.');
            //     // if we reach this error then we should consider creating a new object in which to store pending 
            //     //  contracts to be sent to InfoLease, so a new batch can pick them up and process them from the 
            //     // finish method of SL_InfoleaseContractQueueable
            // }
        }
        
    }
}