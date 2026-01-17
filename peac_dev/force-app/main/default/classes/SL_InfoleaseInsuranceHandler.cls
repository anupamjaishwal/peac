public with sharing class SL_InfoleaseInsuranceHandler {
    public static void updateAllFields(List<Insurance__c> validInsuranceList){
        if (!System.isFuture() && !System.isBatch()){
            for(Insurance__c thisIns : validInsuranceList){
                EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'Sync in progress. Do not close or refresh this page.', Status__c = 'In Progress', Record_Id__c = thisIns.Id ));
                updateInsuranceFuture(thisIns.Id, null);
            }
        }
    }

    public static void updateSpecificFields(Map<Insurance__c, Set<String>> insToFieldsMap) {
        if (!System.isFuture() && !System.isBatch()){
            for(Insurance__c insRec: insToFieldsMap.keySet()){
            Set<String> changedFieldSet = insToFieldsMap.get(insRec);
            EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'Sync in progress. Do not close or refresh this page.', Status__c = 'In Progress', Record_Id__c = insRec.Id ));
            updateInsuranceFuture(insRec.Id, changedFieldSet);
        }
    }
    }

    @future(callout = true)
    public static void updateInsuranceFuture(String insuranceId, Set<String> changedFieldSet){
        SL_InfoleaseInsuranceHelper insuranceAPI = new SL_InfoleaseInsuranceHelper(insuranceId);
        SL_InfoleaseInsuranceService service = new SL_InfoleaseInsuranceService();

        service.recordId = insuranceAPI.recordId;

        if (insuranceAPI.validate()) {            
            //try {
                if(changedFieldSet == null){
                    SL_InfoleaseInsuranceRequestWrapper request = insuranceAPI.createRequest();
                    SL_InfoleaseIntegrationResponseWrapper response = service.updateInsurance(request, null);
                }else {
                    String requestString = insuranceAPI.mapSpecificFields(insuranceId, changedFieldSet);
                    SL_InfoleaseIntegrationResponseWrapper response = service.updateInsurance(null, requestString);
                }
                
            /*} catch (Exception e) {
                SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.insuranceUpdateJob , insuranceAPI.recordId, '', '', e.getMessage(), true);
                SL_InfoleaseLoggingUtils.flush();
                //update insurance integration status
                SL_InfoleaseUtils.updateRecordWithError(insuranceAPI.recordId);
            }*/
        }else{
            String errorMessage = String.join(insuranceAPI.getErrorMessages(), ',') ;
            EventBus.publish( new SL_BW_Integration_Status__e(Message__c = SL_InfoleaseConstants.errorOccurred+errorMessage+'\n'+SL_InfoleaseConstants.contactAdmin, Status__c = 'Error', Record_Id__c = insuranceId ));

            SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.insuranceUpdateJob , insuranceAPI.recordId, '', '', errorMessage, true);
            SL_InfoleaseLoggingUtils.flush();
            //update insurance integration status
            SL_InfoleaseUtils.updateRecordWithError(insuranceAPI.recordId);
            return;
        }

    }
}