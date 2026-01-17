public class TC_TrustPilotService {

    public String accessToken;
    public boolean accessTokenRefreshed = false;
    public Trust_Pilot_App__c tp;
    
    public TC_TrustPilotService () {
        // grab api key, secret, username, password, endpoint urls
        tp = TC_TrustPilotCredWrapper.getTrustPilotApplication ();
        
    }
    
    public String generateInvitation (TC_TrustPilotInvRequestBean reqBean) {
        
        HttpRequest req = new HttpRequest();
		
        req.setEndpoint(tp.Invitation_URL__c + '/' + tp.Business_Id__c + '/invitation-links');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + accessToken);
        req.setMethod('POST');
        req.setBody(JSON.serialize(reqBean));
        
        return doCallout (req, 'url', 'Trust Pilot: Invitation URL', reqBean.oppId);
    }
    
    public String grabAccessToken () {
        
        HttpRequest req = new HttpRequest();
        
        req.setMethod('POST');
		req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode (Blob.valueOf (tp.API_Key__c + ':' + tp.Secret__c)));
        req.setEndpoint(tp.Token_URL__c);
        //req.setBody('grant_type=password&username=' + EncodingUtil.urlEncode('{!$Credential.UserName}','UTF-8') + '&password=' + EncodingUtil.urlEncode('{!$Credential.Password}','UTF-8'));
        req.setBody('grant_type=password&username=' + EncodingUtil.urlEncode(tp.Username__c,'UTF-8') + '&password=' + EncodingUtil.urlEncode(tp.Password__c,'UTF-8'));
 		
        return doCallout (req, 'access_token', 'Trust Pilot: Access Token', null);
    }
    
    public void loadAccessToken () {
        date twoDaysbackDate = Date.Today().addDays(-2) ;
        if(tp.Access_Token_Last_Refresh_Date__c == null || tp.Access_Token_Last_Refresh_Date__c < twoDaysbackDate || String.isBlank(tp.Access_Token__c)){
            accessToken = grabAccessToken ();
            tp.Access_Token__c = accessToken;
            tp.Access_Token_Last_Refresh_Date__c = Date.Today();
            accessTokenRefreshed = true;
        }else{
            accessToken = tp.Access_Token__c;
        }
        system.debug('accessToken****'+accessToken);
    } 
    
    public String doCallout (HttpRequest req, String jsonKey, String integrationName, Id oppId) {
        
        String respValue = '';
        String salesforceError = '';
        String responseStr = '';
        String requestStr = JSON.serialize(req.getBody()); 
        Boolean grabbingAccessToken = integrationName == 'Trust Pilot: Access Token' ? true : false;
        
        HTTPResponse resp = new HTTPResponse ();
        Http http = new Http();

        try {
            System.debug ('Trust Pilot Req: ' + req.getBody());
            resp = http.send(req);
            System.debug ('Trust Pilot Resp: ' + resp.getBody());
            
            if (resp.getStatusCode() == 200) {
                Map <String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resp.getBody());
                respValue = (String) responseMap.get (jsonKey);
                
            }
        } catch (Exception e) {
            salesforceError = String.valueOf (e);
        } finally {
            // need to hide request and sometimes response if getting access token
            if (grabbingAccessToken) {
                if (respValue != null) responseStr = 'Access Token Passed Back';
                requestStr = 'Request Contains Credentials';
            }
            
            MARLIN_IntegrationLog.addLog(integrationName, '', respValue != null && respValue != '' ? 'Success' : 'Failure', requestStr, responseStr, resp.getStatusCode() != null ? String.valueOf (resp.getStatusCode()) : '', salesforceError);
        }
        if(integrationName == 'Trust Pilot: Invitation URL' && accessTokenRefreshed == true)
            update tp;
            
        return respValue;
    }
    
}