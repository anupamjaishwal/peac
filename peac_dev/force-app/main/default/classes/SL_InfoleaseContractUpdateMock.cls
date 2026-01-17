@isTest
global class SL_InfoleaseContractUpdateMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(200);
        resp.setBody('{"Header":{"NitroApi":"BW.UPDATE.CONTRACT"},"Response":{"Success":"true","ContractNumber":"401-1434807-001","Messages":["Contract updated"],"Errors":[]}}');
        return resp;

    }
}