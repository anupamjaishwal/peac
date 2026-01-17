@isTest
global class SL_InfoleaseAssetUpdateMockFail implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(200);
        resp.setBody('{"Header":{"NitroApi":"BW.UPDATE.ASSET"},"Response":{"Success":"false","AssetNumber":"6301034","Messages":["Asset not updated"],"Errors":["Unable to read AS.MASTER for 6301034", "Asset not updated"]}}');
        return resp;

    }
}