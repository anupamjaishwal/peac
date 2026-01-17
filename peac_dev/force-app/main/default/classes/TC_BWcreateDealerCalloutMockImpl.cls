/**
 * Created by JeffHeidman on 6/26/2019.
 */

global class TC_BWcreateDealerCalloutMockImpl implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(201);
        resp.setBody('{ "Header":	{ "NitroApi":	"BW.CREATE.DEALER.UDO" }, "Response":	{ "Success":	"true", "DealerNumber":	"123456.7890", "Messages":	["Dealer created"], "Errors":	[] } }');
        return resp;
    }
}