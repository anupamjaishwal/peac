@isTest
global class SL_InfoleaseContractUpdateMockFail implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(200);
        resp.setBody('{"Header":{"NitroApi":"BW.UPDATE.CONTRACT"},"Response":{"Success":"false","ContractNumber":"401-143e33","Messages":["Contract not updated"],"Errors":["Unable to read LS.MASTER for 401-143e33", "Contract not updated"]}}');
        return resp;

    }
}