/**
 * @description API Mock for the Assign Signers API testing
 * SAL-3249
 */
public with sharing class TC_AssignSignersAPICalloutMock implements HttpCalloutMock{
    /**
     * @description Mock endpoint for TC_AssignSignersAPITest
     * SAL-3249
     * @param req takes in any HttpRequest
     * @return res returns a successful HttpResponse
     */
    public HttpResponse respond(HttpRequest req) {

        //Make sure method is correct
        System.assertEquals('POST', req.getMethod());

        //Create response
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);

        return res;
    }
}