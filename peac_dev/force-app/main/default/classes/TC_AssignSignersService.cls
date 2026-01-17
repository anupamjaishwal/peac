/**
* @description Calls the Assign Signers api which will send an email to the recipients sent in the bean
* SAL-3249
*/
public with sharing class TC_AssignSignersService {

    /**
    * @description Calls the Assign Signers api which will send an email to the recipients sent in the bean
    * SAL-3249
    *@param statusId Id of the docusign status object that the recipients were pulled from.
    *@param requestString List of TC_AssignSignersBean that has been serialized into JSON
    */
    @future(callout=true)
    public static void doCallout(Id statusId, String requestString){

        Signer_Setup_Api__c setting = Signer_Setup_Api__c.getOrgDefaults();

        String status;
        String responseMessage;
        String errorMessage;
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();
        Http http = new Http();
        req.setMethod('POST');
        req.setBody(requestString);
        req.setTimeout(120000);
        if(!Test.isRunningTest()){
            req.setEndpoint(setting.URL__c);
            Blob headerValue = Blob.valueOf(setting.Username__c + ':' + setting.Password__c);
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            req.setHeader('Authorization', authorizationHeader);
            req.setHeader('x-api-key', setting.x_api_key__c);
        }
    
        System.debug('requestBody: ' + req.getBody());
        // extra try catches here to handle this logic differently than the rest
        try {
            MARLIN_IntegrationLog.startDurationTimer();

            resp = http.send(req);
            responseMessage = resp.getBody();
            status = 'Success';
            MARLIN_IntegrationLog.endDurationTimer();

        } catch (Exception e) {

            errorMessage = e.getMessage();
            status = 'Error';

        }finally {
            MARLIN_IntegrationLog.addLog('Assign Signers / Account Setup API', statusId, status, requestString, responseMessage, String.valueOf(resp.getStatusCode()), errorMessage);
            MARLIN_IntegrationLog.insertLogs();
        }
        System.debug ('>>>>> jsonResp: ' + resp);
    }

}