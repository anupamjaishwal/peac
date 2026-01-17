@isTest
global class SL_InfoleaseAssetUpdateMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(200);
        resp.setBody('{"Header":{"NitroApi":"BW.UPDATE.ASSET"},"Response":{"Success":"true","AssetNumber":"630103","Messages":["Asset updated"],"Errors":[]}}');
        return resp;

    }
}