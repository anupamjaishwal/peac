public with sharing class SL_InfoleaseContractService {
    public String recordId;

    public SL_InfoleaseIntegrationResponseWrapper updateContract(SL_InfoleaseContractRequestWrapper request, String requestString, String ilEnvironment) {

        SL_InfoleaseIntegrationResponseWrapper respBean;
        SL_InfoleaseUtils util = SL_InfoleaseUtils.getInstance();
        IL10_Flag__c il10Setting = IL10_Flag__c.getValues('GeneralSetting');
        Boolean isIL10 = ilEnvironment == '10' || ilEnvironment == 'C';

        String editrequestJSON;
        if(request != null){
            editrequestJSON = JSON.serializePretty(request, true);
        }else{
            editrequestJSON = requestString;
        }
        editrequestJSON = editrequestJSON.replaceAll('_', '.');
        if(isIL10 && il10Setting.use_IL10__c){
            editrequestJSON = '{"inputs":' + editrequestJSON + '}';
        }
        util.logInfo(editrequestJSON);

        if (editrequestJSON != '') {
            String responseJSON = '';
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
                util.logInfo('updateContract response body\n' + resp.getBody());
                responseJSON = SL_InfoleaseIntegrationResponseWrapper.wrap(resp.getBody());
                if (resp.getStatusCode() == 200) {
                    util.logInfo('updateContract response string\n' + responseJSON);
                    respBean = (SL_InfoleaseIntegrationResponseWrapper) JSON.deserialize(responseJSON, SL_InfoleaseIntegrationResponseWrapper.class);
                    
                } else {
                    util.logError(resp.getStatusCode() + ' - ' + resp.getStatus() + '\n' + resp.getBody());
                    respBean = (SL_InfoleaseIntegrationResponseWrapper) JSON.deserialize(responseJSON, SL_InfoleaseIntegrationResponseWrapper.class);
                    logResults(editrequestJSON, resp.getBody(), resp.getBody(), 'Error', recordId);
                    return null;
                }

            } catch (Exception e) {
                System.debug('SERVICE EXCEPTIONS DUMP: '+e.getMessage());
                logResults(editrequestJSON, responseJSON, SL_InfoleaseConstants.errorOccurred+e.getMessage()+'\n'+SL_InfoleaseConstants.contactAdmin, 'Error', recordId);
                return null;
            }
        } else {
            respBean = new SL_InfoleaseIntegrationResponseWrapper ();
        }
        return respBean;
    }

    public static void logResults(String request, String response, String message, String status, String recordId){
        Boolean isErrorMessage = status == 'Error';
        SL_InfoleaseLoggingUtils.addLog(SL_InfoleaseConstants.contractUpdateJob , recordId, request, response, isErrorMessage? message: '', isErrorMessage);
    }
}