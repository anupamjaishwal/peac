@isTest
public class TC_TrustPilotResponseGenerator implements HttpCalloutMock {
        

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse ();
        res.setHeader('Content-Type', 'application/json');
        res.setStatusCode(200);
        res.setBody([SELECT Body FROM StaticResource WHERE Name = :req.getEndpoint()][0].Body.toString ());
        return res;
    }
}