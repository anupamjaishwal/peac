public with sharing class TC_GdsAutoPgApiCalloutMock implements HttpCalloutMock{
    public HttpResponse respond(HttpRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setStatusCode(200);

        if (req.getEndpoint().containsIgnoreCase('Dataview360')) {
            res.setBody([SELECT Body FROM StaticResource WHERE Name = 'gdsAutoPG_ResponseTest'][0].Body.toString ());
        } 

        return res;

    }
}