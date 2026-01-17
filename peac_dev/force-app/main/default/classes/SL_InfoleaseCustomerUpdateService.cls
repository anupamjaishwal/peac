/**
 * @File Name          : SL_InfoleaseCustomerUpdateService.cls
 * @Description        : Service class for CCAN Account Update SF to IL via BW
 * @Author             : Silverline
 * @Group              :
 * @Last Modified By   :
 * @Last Modified On   :
 * @Modification Log   :
 * Ver       Date            Author                 Modification
 * 1.0    10/06/2021      Silverline                Initial Version
 */
public with sharing class SL_InfoleaseCustomerUpdateService {

    public String recordId;
    public Datetime syncStartedTimeStamp;

    public SL_InfoleaseIntegrationResponseWrapper updateCustomer(SL_InfoleaseUpdateCustomerRequestWrapper request, String requestString, Boolean isIL10) {
        SL_InfoleaseIntegrationResponseWrapper respBean;
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        system.debug('request:'+JSON.serialize(request));
        SL_InfoleaseUtils util = SL_InfoleaseUtils.getInstance();
        String editrequestJSON;
        if(request != null){
            editrequestJSON = JSON.serializePretty(request, true);
        }else{
            editrequestJSON = requestString;
        }
        editrequestJSON = isIL10 && il10Setting.use_IL10__c? '{"inputs": ' + editrequestJSON + '}': editrequestJSON;
        System.debug('editrequestJSON:'+editrequestJSON);
        util.logInfo(editrequestJSON);

        String response = '';

        if (editrequestJSON != '') {
            try {
                Http h = new Http ();
                HttpRequest req = new HttpRequest ();

                if (util.getServiceSettings().Mock_Callout__c && !String.isEmpty(util.getServiceSettings().Mock_Callout_createCustomer__c)) {
                    Blob headerValue = Blob.valueOf('username' + ':' + 'password');
                    String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
                    req.setHeader('Authorization', authorizationHeader);
                    req.setEndpoint(util.getServiceSettings().Mock_Callout_createCustomer__c);

                } else {
                    if(isIL10 && il10Setting.use_IL10__c){
                        TC_BWUtility.requestToIL10(req);
                    }else{
                        req.setEndpoint('callout:Bridgeware'+'/subroutine');
                    }
                }
                System.debug('editrequestJSON: '+editrequestJSON);
                req.setMethod('POST');
                req.setHeader('CONFIG-NAME', util.getServiceSettings().Config_Name__c);
                req.setHeader('Content-Type','application/json');
                req.setBody(editrequestJSON);
                req.setTimeout(120000);

                HttpResponse resp = h.send(req);

                util.logInfo('createCustomer response body\n' + resp.getBody());
                response = resp.getBody();
                String responseJSON = SL_InfoleaseIntegrationResponseWrapper.wrap(resp.getBody());
                System.debug('responseJSON:' + responseJSON);
                if (resp.getStatusCode() == 200) {
                    util.logInfo('updateCustomer response string\n' + responseJSON);
                    respBean = (SL_InfoleaseIntegrationResponseWrapper) JSON.deserialize(responseJSON, SL_InfoleaseIntegrationResponseWrapper.class);
                    util.logInfo('SL_InfoleaseIntegrationResponseWrapper ######\n' + respBean);

                    if(respBean.response.Response.errors != null && !respBean.response.Response.errors.isEmpty ()) {
                        Boolean isBecauseCcanNotThere = false;
                        String message = '';
                        for(String error : respBean.response.Response.errors){
                            message += error + ',';
                            if(error.containsIgnoreCase('Customer Credit Account Number (') && error.containsIgnoreCase(') does not exist')){
                                isBecauseCcanNotThere = true;
                            }
                        }
                        if(String.isNotBlank(message) && message.contains(',')) message = message.removeEnd (',');
                        
                        SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.accountUpdateJob , recordId, editrequestJSON,resp.getBody(), message, true);
                        SL_InfoleaseLoggingUtils.flush();
                        if(!isBecauseCcanNotThere){
                            Integer logsCreatedByAccount = [SELECT COUNT() FROM IL_Integration_Logs__c WHERE Record_Id__c = :recordId AND CreatedDate >= :syncStartedTimeStamp];
                            if(logsCreatedByAccount == 2){
                                SL_InfoleaseUtils.updateRecordWithError(recordId);
                                EventBus.publish( new SL_BW_Integration_Status__e(Message__c = SL_InfoleaseConstants.errorOccurred+message+'\n'+SL_InfoleaseConstants.contactAdmin, Status__c = 'Error', Record_Id__c = recordId ));
                            }
                        }
                        return null;
                    }else{
                        SL_InfoleaseUtils.updateRecordWithSynced(recordId);
                        EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'Record Synced Successfully.', Status__c = 'Success', Record_Id__c = recordId ));
                        SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.accountUpdateJob , recordId, editrequestJSON, resp.getBody(), '', false);
                        SL_InfoleaseLoggingUtils.flush();
                    }


                } else {
                    util.logError(resp.getStatusCode() + ' - ' + resp.getStatus() + '\n' + resp.getBody());
                    
                    respBean = (SL_InfoleaseIntegrationResponseWrapper) JSON.deserialize(responseJSON, SL_InfoleaseIntegrationResponseWrapper.class);

                    SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.accountUpdateJob , recordId, editrequestJSON, resp.getBody(), resp.getBody(), true);
                    SL_InfoleaseLoggingUtils.flush();

                    //update account integration status
                    SL_InfoleaseUtils.updateRecordWithError(recordId);
                    EventBus.publish( new SL_BW_Integration_Status__e(Message__c = SL_InfoleaseConstants.errorOccurred+resp.getBody()+'\n'+SL_InfoleaseConstants.contactAdmin, Status__c = 'Error', Record_Id__c = recordId ));
                    return null;
                }

            } catch (Exception e) {
                EventBus.publish( new SL_BW_Integration_Status__e(Message__c = SL_InfoleaseConstants.errorOccurred+e.getMessage()+'\n'+SL_InfoleaseConstants.contactAdmin, Status__c = 'Error', Record_Id__c = recordId ));
                SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.accountUpdateJob , recordId, editrequestJSON, response, e.getMessage(), true);
                    SL_InfoleaseLoggingUtils.flush();

                    //update account integration status
                    SL_InfoleaseUtils.updateRecordWithError(recordId);
                    return null;
            }
        } else {
            respBean = new SL_InfoleaseIntegrationResponseWrapper ();
        }
        return respBean;
    }
}