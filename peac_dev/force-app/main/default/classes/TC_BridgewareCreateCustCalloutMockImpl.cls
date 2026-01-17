public class TC_BridgewareCreateCustCalloutMockImpl implements HttpCalloutMock{
	public HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(200);
        resp.setBody('{"Header":{"NitroApi":"BW.CREATE.CUSTOMER.UDO"},"Response":{"Success":"true","CCAN":1700261,"Messages":["Customer created"],"Errors":[]}}');
        return resp;
       
    }
}