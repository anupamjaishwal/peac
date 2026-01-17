/** @author : Tamarack Consulting, Inc.
 * @date : 12/21/20
 * @description: 
 *
 */
public with sharing class TC_DwhStoredProcedureService {

    public static String doCallout (String reqStr, Id recId, String credentialLabel
    ) {
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();
        Http http = new Http();

        String logName;
        switch on credentialLabel
        {
            when 'Default'{
                logName = 'DWH Stored Procedure Callout getPortalCustCreditExp';
            }
            when 'Fraud'{
                logName = 'DWH Stored Procedure Callout DFI';
            }
        }
        String recordId = recId;
        String requestMessage = reqStr;
        String responseMessage;
        String status;
        String errorMessage;

        //Get api authentication info from custom metadata
        TC_DwhStoredProcedureCredential__mdt authInfo = [SELECT Id, Endpoint__c, Password__c, Username__c, x_api_key__c
        FROM TC_DwhStoredProcedureCredential__mdt WHERE Label = :credentialLabel LIMIT 1];

        String respStr = '';
        String salesforceError = '';
        req.setEndpoint(authInfo.Endpoint__c);
        req.setMethod('POST');
        req.setBody(reqStr);
        req.setTimeout(120000);
        Blob headerValue = Blob.valueOf(authInfo.Username__c + ':' + authInfo.Password__c);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('x-api-key', authInfo.x_api_key__c);

        System.debug('requestBody: ' + req.getBody());
        // extra try catches here to handle this logic differently than the rest
        try {
            MARLIN_IntegrationLog.startDurationTimer();

            resp = http.send(req);
            respStr = resp.getBody();
            responseMessage = respStr;
            status = 'Success';
            MARLIN_IntegrationLog.endDurationTimer();

        } catch (Exception e) {
            errorMessage = e.getMessage();
            status = 'ERROR';

        }finally {
            MARLIN_IntegrationLog.addLog(logName, recordId, status, requestMessage, responseMessage, '', errorMessage);
           	//MARLIN_IntegrationLog.insertLogs();
        }
        System.debug ('>>>>> jsonResp: ' + resp);
        return respStr;
    }
}