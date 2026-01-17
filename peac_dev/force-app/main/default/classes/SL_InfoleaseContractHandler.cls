public with sharing class SL_InfoleaseContractHandler {
    public static void updateContractInIL(List<Contract__c> validContractList){
        System.debug(validcontractlist);		       
        if (!System.isFuture() && !System.isBatch()){
            SL_InfoleaseContractBatchQueueable queueableJob = new SL_InfoleaseContractBatchQueueable(validContractList, null, true);
            System.enqueueJob(queueableJob);
            // String jobId = Database.executeBatch(new SL_InfoleaseContractQueueable(validContractList,null,true),1);
            /*for(Contract__c thisCon : validContractList){
                EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'Sync in progress. Do not close or refresh this page.', Status__c = 'In Progress', Record_Id__c = thisCon.Id ));
                updateContractFuture(thisCon.Id, null, thisCon.Infolease_Environment__c);
            }*/
        }
    }
    public static void updateSpecificFields(Map<Contract__c, Set<String>> conToFieldsMap) {
        if (!System.isFuture() && !System.isBatch()){
            SL_InfoleaseContractBatchQueueable queueableJob = new SL_InfoleaseContractBatchQueueable(null, conToFieldsMap, false);
            System.enqueueJob(queueableJob);
            //String jobId = Database.executeBatch(new SL_InfoleaseContractQueueable(null,conToFieldsMap,false),1);
            //Contract__c conRec = new List<Contract__c>(conToFieldsMap.keySet())[0];
            /*for(Contract__c conRec : conToFieldsMap.keySet()){
                Set<String> changedFieldSet = conToFieldsMap.get(conRec);
                EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'Sync in progress. Do not close or refresh this page.', Status__c = 'In Progress', Record_Id__c = conRec.Id ));
                updateContractFuture(conRec.Id, changedFieldSet,  conRec.Infolease_Environment__c);
            }*/
        }
    }
    
    //Now on QueueableClass
    @future(callout = true)
    public static void updateContractFuture(String contractId, Set<String> changedFieldSet, String ilEnvironment){
        SL_InfoleaseContractHelper contractAPI = new SL_InfoleaseContractHelper(contractId);
        SL_InfoleaseContractService service = new SL_InfoleaseContractService();

        service.recordId = contractAPI.recordId;

        if (contractAPI.validate()) {
            /*try{
                if(changedFieldSet == null){
                    SL_InfoleaseContractRequestWrapper request = contractAPI.createRequest();
                    String errorMessage = String.join(contractAPI.getErrorMessages(), ',');
                    if(String.isNotEmpty(errorMessage)){
                        publishError(errorMessage, contractId);
                    }else{
                        SL_InfoleaseIntegrationResponseWrapper response = service.updateContract(request, null, ilEnvironment);
                    }
                }else {
                    String requestString = contractAPI.mapSpecificFields(contractId, changedFieldSet);
                    String errorMessage = String.join(contractAPI.getErrorMessages(), ',');
                    if(String.isNotEmpty(errorMessage)){
                        publishError(errorMessage, contractId);
                    }else{
                        SL_InfoleaseIntegrationResponseWrapper response = service.updateContract(null, requestString, ilEnvironment);
                    }
                }
            } catch (Exception e) {
                SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.contractUpdateJob , contractAPI.recordId, '', '', e.getMessage(), true);
                SL_InfoleaseLoggingUtils.flush();
                SL_InfoleaseUtils.updateRecordWithError(contractAPI.recordId);
            }*/
        }else{
            String errorMessage = String.join(contractAPI.getErrorMessages(), ',');
            publishError(errorMessage, contractId);
            return;
        }

    }

    private static void publishError(String errorMessage, Id contractId){
        EventBus.publish( new SL_BW_Integration_Status__e(Message__c = SL_InfoleaseConstants.errorOccurred+errorMessage+'\n'+SL_InfoleaseConstants.contactAdmin, Status__c = 'Error', Record_Id__c = contractId ));
        SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.contractUpdateJob , contractId, '', '', errorMessage, true);
        SL_InfoleaseLoggingUtils.flush();
        SL_InfoleaseUtils.updateRecordWithError(contractId);
    }
}