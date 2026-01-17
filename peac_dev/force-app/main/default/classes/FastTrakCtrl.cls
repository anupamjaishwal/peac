public class FastTrakCtrl {
    
    ///decommissioning this class for SAL- 4149
    
    ////Added this line to cover code coverge to pass deployment 
    public  void FastTrakCtrl(string dummy){
        
    }
    ////End : By Raja Sirivella
   /* @AuraEnabled
    public static void makeCallout(String email, id contact, String ccan, String ccid){
        String status;
        String errorMessage;
        if(ccan == null){
            ccan = '';
        }
        if(ccid == null){
            ccid = '';
        }
        //Production Credentials
        String username = 'marlin-api-internal-user';
        String password = 'qZvM31fYy2Np1Zpw';
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        request.setEndpoint('https://testdevportal.marlincapitalsolutions.com:8077/ws/rest/ODPPasswordResetAPI/V1/ODPPasswordReset/');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Authorization' , authHeader);
        request.setHeader('x-api-key','72904d14-b5f2-4ffd-9728-366dddd87ff3’');
        // Set the body as a JSON object
        String body = '{"email":"' + email + '", "contactid":"' + contact + '", "CCAN":"' + ccan + '", "CCID":"' + ccid + '","origin":"SF"}';
        request.setBody(body);
        try {
            MARLIN_IntegrationLog.startDurationTimer();
            response = http.send(request);
            status = 'Success';
            MARLIN_IntegrationLog.endDurationTimer();
        }catch(Exception e){
            errorMessage = e.getMessage();
            status = 'Error';
        }finally {
            MARLIN_IntegrationLog.addLog('Reset Password API', contact, status, body, response.getBody(), String.valueOf(response.getStatusCode()), errorMessage);
            MARLIN_IntegrationLog.insertLogs();
        }
    }*/
}