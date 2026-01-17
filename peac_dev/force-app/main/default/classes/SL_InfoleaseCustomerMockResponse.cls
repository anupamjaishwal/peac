public with sharing class SL_InfoleaseCustomerMockResponse implements HttpCalloutMock{

    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(200);
        resp.setBody('{"Header":{"NitroApi":"BW.UPDATE.CUSTOMER.UDO"},"Response":{"Success":"false","Ccan":"3212422222","Messages":["Customer not updated"],"Errors":["Customer Credit Account Number (3212422222) does not exist.", "Ccan not updated"]}}');
        return resp;
       
    }
}