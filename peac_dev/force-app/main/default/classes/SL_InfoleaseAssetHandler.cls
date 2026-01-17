public with sharing class SL_InfoleaseAssetHandler {
    public static void updateAllFields(List<Contract_Asset__c> validAssetList){
        if (!System.isFuture() && !System.isBatch()){
            for(Contract_Asset__c theAsset: validAssetList){
                EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'Sync in progress. Do not close or refresh this page.', Status__c = 'In Progress', Record_Id__c = theAsset.Id ));
                updateAssetFuture(theAsset.Id, null);
            }
        }
    }
    public static void updateSpecificFields(Map<Contract_Asset__c, Set<String>> assToFieldsMap) {
        if (!System.isFuture() && !System.isBatch()){
            for(Contract_Asset__c theAsset: assToFieldsMap.keySet()){
                Set<String> changedFieldSet = assToFieldsMap.get(theAsset);
                EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'Sync in progress. Do not close or refresh this page.', Status__c = 'In Progress', Record_Id__c = theAsset.Id ));
                updateAssetFuture(theAsset.Id, changedFieldSet);
            }
        }
    }

    @future(callout = true)
    public static void updateAssetFuture(String assetId, Set<String> changedFieldSet){
        SL_InfoleaseAssetHelper assetAPI = new SL_InfoleaseAssetHelper(assetId);
        SL_InfoleaseAssetService service = new SL_InfoleaseAssetService();

        service.recordId = AssetAPI.recordId;
        Boolean isIL10 = false;
        if(assetId != null){
            Contract_Asset__c theAsset = [SELECT Contract__r.Infolease_Environment__c FROM Contract_Asset__c  WHERE Id = :assetId];
            if(theAsset.Contract__r != null){
                isIL10 = TC_BWUtility.isIL10Record(theAsset.Contract__r);
            }
        }
        if (AssetAPI.validate()) {
            try {
                if(changedFieldSet == null){
                    SL_InfoleaseAssetRequestWrapper request = assetAPI.createRequest();
                    SL_InfoleaseIntegrationResponseWrapper response = service.updateAsset(request, null, isIL10);
                }else{
                    String requestString = assetAPI.mapSpecificFields(assetId, changedFieldSet);
                    SL_InfoleaseIntegrationResponseWrapper response = service.updateAsset(null, requestString, isIL10);
                }
                
            } catch (Exception e) {
                SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.AssetUpdateJob , AssetAPI.recordId, '', '', e.getMessage(), true);
                SL_InfoleaseLoggingUtils.flush();
                //update Asset integration status
                SL_InfoleaseUtils.updateRecordWithError(AssetAPI.recordId);
            }
        }else{
            String errorMessage = String.join(AssetAPI.getErrorMessages(), ',') ;

            EventBus.publish( new SL_BW_Integration_Status__e(Message__c = SL_InfoleaseConstants.errorOccurred+errorMessage+'\n'+SL_InfoleaseConstants.contactAdmin, Status__c = 'Error', Record_Id__c = assetId ));

            SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.AssetUpdateJob , AssetAPI.recordId, '', '', errorMessage, true);
            SL_InfoleaseLoggingUtils.flush();
            //update Asset integration status
            try{
                SL_InfoleaseUtils.updateRecordWithError(AssetAPI.recordId);
            }catch(Exception e){
                System.debug('Error Updating Status to Error. '+e.getMessage());
            }
            return;
        }

    }
}