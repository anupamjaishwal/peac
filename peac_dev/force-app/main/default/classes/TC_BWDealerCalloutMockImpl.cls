@isTest
global class TC_BWDealerCalloutMockImpl implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(201);
        resp.setBody('{ "Header":	{ "NitroApi":	"BW.UPDATE.DEALER.UDO" }, "Response":	{ "Success":	"true", "DealerNumber":	"123944", "Messages":	["Dealer Updated"], "Errors":	[] } }');
        return resp;
    }
}