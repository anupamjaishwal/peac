/**
 * Created by trohweder on 4/8/21.
 */

public with sharing class TC_DwhStoredProcedureFraudCalloutMock implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest req) {
        //Make sure method is correct
        System.assertEquals('POST', req.getMethod());

        //Create response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{' +
                '  "status" : true,' +
                '  "message" : "success",' +
                '  "results" : [' +
                '    {' +
                '      "Business_Location_City_Flag" : "0",' +
                '      "Business_Location_State_Flag" : "0",' +
                '      "Business_Location_Zip_Flag" : "0",' +
                '      "Matching_Business_Phone_Flag" : "0",' +
                '      "Business_Info_Match_Flag" : "0",' +
                '      "Customer_Type" : "NEW",' +
                '      "Fraud_Review_Status" : "Approved",' +
                '      "Fraud_Review_Flag" : "0"' +
                '    }' +
                '  ]' +
                '}');
        res.setStatusCode(200);

        return res;
    }
}