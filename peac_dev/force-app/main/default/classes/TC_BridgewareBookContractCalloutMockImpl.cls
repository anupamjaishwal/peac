/*
* @author : sfdcdev, Tamarack Consulting, Inc.
* @date : 02/15/2018
* @description: Mock class.
*
* © Copyright 2003 - 2018 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

global class TC_BridgewareBookContractCalloutMockImpl implements HttpCalloutMock {
    //protected Integer code;
    //protected String status;
    //protected String body;
    //protected Map<String, String> responseHeaders;

    //public BridgewareBookContractCalloutMockImpl(Integer code, String status, String body, Map<String, String> responseHeaders) {
    //    this.code = code;
    //    this.status = status;
    //    this.body = body;
    //    this.responseHeaders = responseHeaders;
    //}

    // Create a fake response.
    // Set response values, and 
    // return response.

    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse resp = new HttpResponse ();
        resp.setStatus('OK');
        resp.setStatusCode(201);
        resp.setBody('{"ResponseMessageCode": 3,"ResponseMessageDesc": "Buy cheese and bread for breakfast."}');
        return resp;
       
    }
}