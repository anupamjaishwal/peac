@isTest
global class SL_InfoleaseCustomerUpdateMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        String ccan = 'CCAN' + Math.random()*100;
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(201);
        resp.setBody('{ "Header":	{ "NitroApi":	"BW.CREATE.CUSTOMER.UDO" }, "Response":	{ "Success":	"true", "CCAN":	"123944", "Messages":	["Customer created"], "Errors":	[] } }');
        return resp;

    }
}