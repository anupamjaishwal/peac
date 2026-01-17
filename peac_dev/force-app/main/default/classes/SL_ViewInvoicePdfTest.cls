@isTest
public with sharing class SL_ViewInvoicePdfTest {
    @isTest
    static void il9AndIL10() {
        SL_SCTestData.createAccountAndContracts(2,1);
        //SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        contracts[0].Infolease_Environment__c = '9';
        update contracts[0];
        List<Invoice__c> theInvoices = new List<Invoice__c>{
            new Invoice__c(Contract__c = contracts[0].Id,
                    Customer__c = SL_SCTestData.testAccounts[0].Id),
            new Invoice__c(Contract__c = contracts[1].Id,
                    Customer__c = SL_SCTestData.testAccounts[1].Id)
        };
        insert theInvoices;
        String result1, result2;
        Test.startTest();
        result1 = SL_ViewInvoicePdf.hubExecute('generateUrl', new List<String> {theInvoices[0].Id});
        Test.setMock(HttpCalloutMock.class, new osgIL10Mock());
        result2 = SL_ViewInvoicePdf.hubExecute('generateUrl', new List<String> {theInvoices[1].Id});
        SL_ViewInvoicePdf.buildIL9Url(theInvoices[0]);
        Test.stopTest();
        System.Assert.areEqual(true, result1.length() > 0, 'right now only checking that the string has characters');
        System.Assert.areEqual(true, result2.length() > 0, 'right now only checking that the string has characters');
    }

    @isTest
    static void errorCase() {
        SL_SCTestData.createAccountAndContracts(3,1);
        //SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        List<Invoice__c> theInvoices = new List<Invoice__c>{
            new Invoice__c(Contract__c = contracts[2].Id,
                Customer__c = SL_SCTestData.testAccounts[2].Id)
        };
        insert theInvoices;
        String result3;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new osgIL10Mock());
        result3 = SL_ViewInvoicePdf.hubExecute('generateUrl', new List<String> {theInvoices[0].Id});
        Test.stopTest();
        System.Assert.areEqual(true, result3.contains('Test Error message'), 'we should get an error message');
    }

    public class osgIL10Mock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse res = new HTTPResponse();
            if(req.getBody().contains('"NitroApi":"BW.UPDATE.DEALER.UDO"')){
                res.setStatus('OK');
                res.setStatusCode(201);
                res.setBody('{ "Header":	{ "NitroApi":	"BW.UPDATE.DEALER.UDO" }, "Response":	{ "Success":	"true", "DealerNumber":	"123944", "Messages":	["Dealer Updated"], "Errors":	[] } }');
            }else{
                res.setHeader('Content-Type', 'text/plain; charset=utf-8');
                if(req.getEndpoint().contains('1234567893')){// CCAN to test failure
                    res.setStatusCode(404);
                    res.setBody('{"data":null,"succeeded":false,"errors":["test error 1"],"message":"Test Error message"}');
                }else{
                    res.setStatusCode(200);
                    res.setBody('{"data":"TEST64ENCODEDSTRING","succeeded":true,"errors":null,"message":""}');
                }
                return res;
            }
            return res;
        }
    }
}