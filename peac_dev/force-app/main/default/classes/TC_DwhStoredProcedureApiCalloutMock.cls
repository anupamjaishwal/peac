/**
 * Created by trohweder on 12/29/20.
 */

public with sharing class TC_DwhStoredProcedureApiCalloutMock implements HttpCalloutMock{

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
                '      "Customer_CCAN" : "1719232",' +
                '      "Lease_OnBalanceSheet_Total_Exposure" : 0.0,' +
                '      "Existing_Loan_Customer" : "0",' +
                '      "Lease_Active_Contracts_Payments_Made" : 0,' +
                '      "Lease_Disposed_Contracts_Payments_Made" : 0,' +
                '      "Lease_Gain_Loss_Check" : "0",' +
                '      "Lease_Curr_61_Plus_Delin" : 0,' +
                '      "Lease_Ever_91_Plus_Delin" : 0,' +
                '      "Lease_Active_Contracts_Past_31" : 0,' +
                '      "Loan_Total_Charge_Off_Count" : 0,' +
                '      "Loan_Curr_15_Plus_Days_Delin" : 0,' +
                '      "Prior_PG_On_App" : 0,' +
                '      "COVID_Restructure" : 0,' +
                '      "UD_DEALER_PREFERRED" : "null",' +
                '      "UD_DEALER_CLASSIFICATION" : "null"' +
                '    }' +
                '  ]' +
                '}');
        res.setStatusCode(200);

        return res;
    }
}