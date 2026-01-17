@isTest
global class SL_InfoleaseInsuranceUpdateMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(200);
        resp.setBody('{"Header":{"NitroApi":"BW.UPDATE.INSURANCE"},"Response":{"Success":"true","InsuranceId":"401-1331066-001*001","Messages":["Insurance updated"],"Errors":[]}}');
        return resp;

    }
}