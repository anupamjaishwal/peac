public without sharing class SL_DnBCallout {
    public static Integer timeout = 120000;
    public static String accessToken = '';
    public static String url = '';

    @AuraEnabled
    public static String getAccessToken(){
        DnB_Credentials__c dnbCredentials = DnB_Credentials__c.getOrgDefaults();
        url = dnbCredentials.URL__c;
        Blob toBeEncoded = Blob.valueOf(dnbCredentials.Consumer_Key__c + ':' + dnbCredentials.Consumer_Secret__c);
        String encodedAuth = EncodingUtil.base64Encode(toBeEncoded);
        DnB_Daily_Pass__mdt dailyPass = [SELECT Id, DeveloperName, Label, Token__c, Granted_Date__c, isExpired__c FROM DnB_Daily_Pass__mdt LIMIT 1];
        if(Test.isRunningTest() && accessToken == 'expiredForTesting'){
            dailyPass.isExpired__c = true;
        }
        if(!dailyPass.isExpired__c && dailyPass.Granted_Date__c.addHours(24) >= Datetime.now()){
            accessToken = dailyPass.Token__c;
        }else{
            HttpRequest requestForToken = new HttpRequest();
            requestForToken.setEndpoint(url + 'v2/token');
            requestForToken.setMethod('POST');
            requestForToken.setHeader('Authorization', 'Basic ' + encodedAuth);
            requestForToken.setBody('{ "grant_type" : "client_credentials" }');
            String jsonResponse = sendRequest(requestForToken, '');
            accessToken = ((tokenResponseWrapper)JSON.deserialize(jsonResponse, tokenResponseWrapper.class)).access_token;
            dailyPass.Token__c = accessToken;
            dailyPass.Granted_Date__c = Datetime.now();
            dailyPass.isExpired__c = false;
            if(System.Site.getSiteId() == null){
                updateToken(dailyPass.DeveloperName, dailyPass.Token__c, dailyPass.Granted_Date__c, dailyPass.isExpired__c);
            }
        }
        return accessToken;
    }

    public static String companyTypeaheadSearch(String companyName){
        DnB_Credentials__c dnbCredentials = DnB_Credentials__c.getOrgDefaults();
        HttpRequest searchRequest = new HttpRequest();
        searchRequest.setEndpoint(dnbCredentials.URL__c + 'v1/search/typeahead?searchTerm=' + 
            EncodingUtil.urlEncode(companyName, 'UTF-8').replaceAll('\\+', '%20') + '&countryISOAlpha2Code=US');
        searchRequest.setMethod('GET');
        //searchRequest.setBody('');
        String jsonResponse = sendRequest(searchRequest, accessToken);
        return jsonResponse;
    }

    @AuraEnabled
    public static string callSearch(String criteria, String cookieToken){
        String result = '';
        try {
            if(cookieToken == ''){
                getAccessToken();
            }else{
                accessToken = cookieToken;
            }
            result = companyTypeaheadSearch(criteria);
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static String sendRequest(HttpRequest theRequest, String accessToken) {
        Http h = new Http();
        theRequest.setHeader('Content-Type', 'application/json');
        theRequest.setTimeout(timeout);
        if(accessToken != ''){
            theRequest.setHeader('Authorization', 'Bearer ' + accessToken);
            //theRequest.setHeader('Authorization', 'Bearer 48I658OWp111s58aozbI7SO5651i');
        }
        system.debug(theRequest);
        system.debug(theRequest.getHeader('Authorization'));
        HttpResponse lRes = h.send(theRequest);
        Integration_Log__c resultsLog = new Integration_Log__c();
        system.debug(lRes);
        if(lRes.getStatusCode() != 200) {
            resultsLog = SL_OnBaseCallout.SL_LogException('DnB API', '', 'Error', theRequest.getBody(), lRes.getBody(), String.valueOf(lRes.getStatusCode()), lRes.getStatus());
            resultsLog.Response_Message__c = 'Status Code: ' + lRes.getStatusCode() + ', Status Message: ' + lRes.getStatus();
        }
        else{
            resultsLog = SL_OnBaseCallout.SL_LogException('DnB API', '', 'Success', theRequest.getBody(), lRes.getBody(), '200', 'OK');
        }
        return lRes.getBody();
    }

    @future
    static void updateToken(String developerName, String theToken, Datetime grantedDate, Boolean isExpired){
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
            Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
            customMetadata.fullName = 'DnB_Daily_Pass.' + developerName;
            customMetadata.label = developerName;
    
            Metadata.CustomMetadataValue tokenMDV = new Metadata.CustomMetadataValue();
            tokenMDV.field = 'Token__c';
            tokenMDV.value = theToken;
            customMetadata.values.add(tokenMDV);
            Metadata.CustomMetadataValue grantedDateMDV = new Metadata.CustomMetadataValue();
            grantedDateMDV.field = 'Granted_Date__c';
            grantedDateMDV.value = grantedDate;
            customMetadata.values.add(grantedDateMDV);
            Metadata.CustomMetadataValue isExpiredMDV = new Metadata.CustomMetadataValue();
            isExpiredMDV.field = 'isExpired__c';
            isExpiredMDV.value = isExpired;
            customMetadata.values.add(isExpiredMDV);
            
            mdContainer.addMetadata(customMetadata);
            SL_RRManageMDT.StandardDeployCallback doNothing = new SL_RRManageMDT.StandardDeployCallback();
            if(!Test.isRunningTest()){
                Metadata.Operations.enqueueDeployment(mdContainer, doNothing);
            }
    }

    public class tokenResponseWrapper{
        public String access_token;
        public Integer expiresIn;

        // public tokenResponseWrapper(){
        //     this.access_token
        // }
    }
    
   
    public static String searchPhone(String duns){
       	HttpRequest req = new HttpRequest();
       	req.setMethod('POST');	
       	String accessToken = getAccessToken();       
        req.setBody('{ "duns": "'+duns+'"}');
        DnB_Credentials__c dnbCredentials = DnB_Credentials__c.getOrgDefaults();
        req.setEndpoint(dnbCredentials.URL__c+'v1/search/criteria');
        String response = sendRequest(req,accessToken);
       System.debug('Reponse Body Phone: '+ response);
        return response;
       
    }

    
    @AuraEnabled(cacheable=true)
    public static List<Account> searchByCCAN(String searchTerm){
        // Make sure the searchTerm is not null or empty
        if (String.isEmpty(searchTerm)) {
            return new List<Account>();
        }
        // Query accounts based on the search term
        return [SELECT Id, Name, CCAN__c,  Business_Phone__c ,Business_Address__c, Business_Address2__c, Business_City__c, Business_Country__c, Business_Zip__c, Business_State__c,  D_B_Revenue__c, DUNS__c , Industry  FROM Account WHERE RecordType.Name = 'End User Account' AND CCAN__c <>'' AND CCAN__c  =:searchTerm];
    }

}