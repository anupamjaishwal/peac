/**
 * Created by trohweder on 4/8/21.
 */

public with sharing class TC_DwhStoredProcedurePgCalloutMock implements HttpCalloutMock{

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
                '      "Matching_PG1_SSN_Flag" : "0",' +
                '      "Matching_PG2_SSN_Flag" : "0",' +
                '      "Matching_PG1_Email_Flag" : "0",' +
                '      "Matching_PG2_Email_Flag" : "0",' +
                '      "Matching_PG1_Last_Name_Flag" : "0",' +
                '      "Matching_PG2_Last_Name_Flag" : "0",' +
                '      "Customer_Type" : "NEW",' +
                '      "Personal_Info_Match_Flag" : "0",' +
                '      "Fraud_Review_Status" : "Approved",' +
                '      "Fraud_Review_Flag" : "0"' +
                '    }' +
                '  ]' +
                '}');
        res.setStatusCode(200);

        return res;
    }
}