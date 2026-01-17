/**
 * @File Name          : SL_InfoleaseCustomerIntegrationHandler.cls
 * @Description        : Handler class for CCAN Account SF to IL via BW
 * @Author             : Silverline
 * @Group              :
 * @Last Modified By   :
 * @Last Modified On   :
 * @Modification Log   :
 * Ver       Date            Author                 Modification
 * 1.0    10/06/2021      Silverline                Initial Version
 */
public with sharing class SL_InfoleaseCustomerIntegrationHandler {

    public static void updateAllFields(List<Account> customers) {
        if (!System.isFuture() && !System.isBatch()){
            for(Account thisCust : customers){
                EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'Sync in progress. Do not close or refresh this page.', Status__c = 'In Progress', Record_Id__c = thisCust.Id ));
                Datetime syncStartedTimeStamp = Datetime.now();
                updateCustomerFuture(thisCust.Id, null, true, syncStartedTimeStamp);
                updateCustomerFuture(thisCust.Id, null, false, syncStartedTimeStamp);
            }
        }
    }

    public static void updateSpecificFields(Map<Account, Set<String>> accToFieldsMap) {
        if (!System.isFuture() && !System.isBatch()){
            for(Account accRec :accToFieldsMap.keySet()){
            Set<String> changedFieldSet = accToFieldsMap.get(accRec);
            EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'Sync in progress. Do not close or refresh this page.', Status__c = 'In Progress', Record_Id__c = accRec.Id ));
            Datetime syncStartedTimeStamp = Datetime.now();
            updateCustomerFuture(accRec.Id, changedFieldSet, true, syncStartedTimeStamp);
            updateCustomerFuture(accRec.Id, changedFieldSet, false, syncStartedTimeStamp);
        }
    }
    }

    @future (callout=true)
    public static void updateCustomerFuture(String customerId, Set<String> changedFieldSet, Boolean isIL10, Datetime syncStartedTimeStamp) {

        SL_InfoleaseCustomerUpdateHelper customerAPI = new SL_InfoleaseCustomerUpdateHelper(customerId);
        SL_InfoleaseCustomerUpdateService service = new SL_InfoleaseCustomerUpdateService ();

        service.recordId = customerAPI.recordId;
        service.syncStartedTimeStamp = syncStartedTimeStamp;
        if (customerAPI.validate()) {
            if(changedFieldSet == null){
                SL_InfoleaseUpdateCustomerRequestWrapper request = customerAPI.createRequest();
                SL_InfoleaseIntegrationResponseWrapper response = service.updateCustomer(request, null, isIL10);
            }else {
                String requestString = customerAPI.mapSpecificFields(customerId, changedFieldSet);
                SL_InfoleaseIntegrationResponseWrapper response = service.updateCustomer(null, requestString, isIL10);
            }
        }else{
            
            String errorMessage = String.join(customerAPI.getErrorMessages(), ',') ;

            EventBus.publish( new SL_BW_Integration_Status__e(Message__c = SL_InfoleaseConstants.errorOccurred+errorMessage+'\n'+SL_InfoleaseConstants.contactAdmin, Status__c = 'Error', Record_Id__c = customerId ));

            SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.accountUpdateJob , customerId, '','', errorMessage, true);
            SL_InfoleaseLoggingUtils.flush();
            //update account integration status
            try{
                SL_InfoleaseUtils.updateRecordWithError(customerId);
            }catch(Exception e){
                System.debug('Error Updating Status to Error. '+e.getMessage());
            }
            
            return;
        }
    }
}