public class BriteVerifyService {

    public static BriteVerifyResponse verifyCallout(String emailParameter) {
        HttpRequest req = new HttpRequest();
        BriteVerifyResponse responseBean = new BriteVerifyResponse();
        HttpResponse res = new HttpResponse();
        
        try {
            List<NamedCredential> bvNamedCredential = new List<NamedCredential>([SELECT Endpoint FROM NamedCredential WHERE DeveloperName = 'BriteVerify_API']);
            String bvEndpoint = bvNamedCredential[0].Endpoint;
            req.setEndpoint(bvEndpoint + + '&address=' + emailParameter);
            req.setMethod('POST');
            req.setTimeout(60000);
            Http http = new Http();
            res = http.send(req);
            responseBean = (BriteVerifyResponse) JSON.deserialize(res.getBody(), BriteVerifyResponse.class);
        } catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            throw new BriteVerifyServiceException(e.getMessage());
        }
        
        return responseBean;
    }
    
    public class BriteVerifyServiceException extends Exception {}
    
}