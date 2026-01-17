public with sharing class SL_InfoleaseAssetService {
    public String recordId;

    public SL_InfoleaseIntegrationResponseWrapper updateAsset(SL_InfoleaseAssetRequestWrapper request, String requestString, Boolean isIL10) {
        SL_InfoleaseIntegrationResponseWrapper respBean;
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        SL_InfoleaseUtils util = SL_InfoleaseUtils.getInstance();
        String editrequestJSON;
        if(request != null){
            editrequestJSON = JSON.serializePretty(request, true);
            editrequestJSON = editrequestJSON.replaceAll('_', '.');
        }else{
            editrequestJSON = requestString;
        }
        editrequestJSON = isIL10 && il10Setting.use_IL10__c? '{"inputs": ' + editrequestJSON + '}': editrequestJSON;
        System.debug('editrequestJSON:'+editrequestJSON);
        util.logInfo(editrequestJSON);

        if (editrequestJSON != null) {
            String response = '';
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

                req.setMethod('POST');
                req.setHeader('CONFIG-NAME', util.getServiceSettings().Config_Name__c);
                req.setHeader('Content-Type','application/json');
                req.setBody(editrequestJSON);
                req.setTimeout(120000);

                HttpResponse resp = h.send(req);
                response = resp.getBody();
                util.logInfo('updateAsset response body\n' + resp.getBody());
                String responseJSON = SL_InfoleaseIntegrationResponseWrapper.wrap(resp.getBody());
                System.debug('responseJSON:' + responseJSON);
                if (resp.getStatusCode() == 200) {
                    util.logInfo('updateAsset response string\n' + responseJSON);
                    respBean = (SL_InfoleaseIntegrationResponseWrapper) JSON.deserialize(responseJSON, SL_InfoleaseIntegrationResponseWrapper.class);
                    util.logInfo('SL_InfoleaseIntegrationResponseWrapper ######\n' + respBean);

                    if (respBean.response.response.errors != null && !respBean.response.response.errors.isEmpty ()) {
                        
                        String message = '';
                        for (String error : respBean.response.response.errors) {
                            System.debug('error: '+error);
                            message = message + error +', ';
                        }
                        if (String.isNotBlank(message) && message.contains(',')) message = message.removeEnd (',');
                        SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.AssetUpdateJob , recordId, editrequestJSON, resp.getBody(), message, true);
                        SL_InfoleaseLoggingUtils.flush();

                        //update account integration status
                        SL_InfoleaseUtils.updateRecordWithError(recordId);
                        EventBus.publish( new SL_BW_Integration_Status__e( Message__c = SL_InfoleaseConstants.errorOccurred+message+'\n'+SL_InfoleaseConstants.contactAdmin, Status__c = 'Error', Record_Id__c = recordId));
                        return null;
                    }else{
                        SL_InfoleaseUtils.updateRecordWithSynced(recordId);
                        EventBus.publish( new SL_BW_Integration_Status__e(Message__c = 'Record Synced Successfully.', Status__c = 'Success', Record_Id__c = recordId ));
                        SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.AssetUpdateJob , recordId, editrequestJSON, resp.getBody(), '', false);
                        SL_InfoleaseLoggingUtils.flush();
                    }


                } else {
                    util.logError(resp.getStatusCode() + ' - ' + resp.getStatus() + '\n' + resp.getBody());
                    respBean = (SL_InfoleaseIntegrationResponseWrapper) JSON.deserialize(responseJSON, SL_InfoleaseIntegrationResponseWrapper.class);

                    SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.AssetUpdateJob , recordId, editrequestJSON,resp.getBody(), resp.getBody(), true);
                    SL_InfoleaseLoggingUtils.flush();

                    //update account integration status
                    SL_InfoleaseUtils.updateRecordWithError(recordId);
                    EventBus.publish( new SL_BW_Integration_Status__e(Message__c = SL_InfoleaseConstants.errorOccurred+resp.getBody()+'\n'+SL_InfoleaseConstants.contactAdmin, Status__c = 'Error', Record_Id__c = recordId ));
                    return null;
                }

            } catch (Exception e) {
                EventBus.publish( new SL_BW_Integration_Status__e(Message__c = SL_InfoleaseConstants.errorOccurred+e.getMessage()+'\n'+SL_InfoleaseConstants.contactAdmin, Status__c = 'Error', Record_Id__c = recordId ));
                System.debug('SERVICE EXCEPTIONS DUMP: '+e.getMessage());
                SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.AssetUpdateJob , recordId, editrequestJSON,response, e.getMessage(), true);
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