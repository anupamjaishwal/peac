@isTest
global class SL_InfoleaseInsuranceUpdateMockFail implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(200);
        resp.setBody('{"Header":{"NitroApi":"BW.UPDATE.INSURANCE"},"Response":{"Success":"false","InsuranceId":"40066-001*001","Messages":["Insurance not updated"],"Errors":["Unable to read IT.INSURANCE for 40066-001*001", "Insurance not updated"]}}');
        return resp;

    }
}