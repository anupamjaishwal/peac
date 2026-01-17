/**
 * Created by tamarack on 12/26/19.
 */

public with sharing class GoogleGeoCodeService {

    public static GoogleGeoCodeResponse googleGeoCodeCallout(String addressParameter) {

        HttpRequest req = new HttpRequest();
        GoogleGeoCodeResponse responseBean = new GoogleGeoCodeResponse();
        HttpResponse res = new HttpResponse();

        try {
            List<NamedCredential> googleNamedCredential = new List<NamedCredential>([SELECT Endpoint FROM NamedCredential WHERE DeveloperName = 'Google_Maps_API']);
            String googleEndpoint = googleNamedCredential[0].Endpoint;

            req.setEndpoint(googleEndpoint + '&address=' + addressParameter);
            req.setMethod('GET');
            Http http = new Http();
            res = http.send(req);
            
            responseBean = (GoogleGeoCodeResponse) JSON.deserialize(res.getBody(), GoogleGeoCodeResponse.class);
        } catch (Exception e) {
            System.debug('google error' + e.getStackTraceString());
        }

        return responseBean;

    }

}