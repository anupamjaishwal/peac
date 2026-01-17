@isTest
private class SL_CaseCenterStoredProcedureTest {

    class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"results": [{"CreditScore": "750", "FraudFlag": "No"}]}');
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup
    static void setup() {
        Account acct = new Account(Name = 'Test Acc', Tax_ID__c = '123789654');
        insert acct;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(10),
            AccountId = acct.Id
        );
        insert opp;

        Contact contact = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            SSN__c = '999887777',
            Phone = '7854785555'
        );
        insert contact;

        Guarantor__c g = new Guarantor__c(
            Opportunity__c = opp.Id,
            Priority__c = 1,
            Contact__c = contact.Id
            // Do NOT try to set SSN__c directly if it's a formula field
        );
        insert g;
    }


    @isTest
    static void testExecuteGetCreditExp() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        System.enqueueJob(new SL_CaseCenterStoredProcedureQueueable(new List<String>{'getGdsGetCustCreditExpLoan'},opp.Id, 'Label.PEAC_Initial_Submission'));         
          
        Test.stopTest();

        List<Webservice_Field__c> ws = [SELECT Id FROM Webservice_Field__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(1, ws.size());
    }

    @isTest
    static void testExecuteFraudFlags() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
            SL_CaseCenterStoredProcedure.SL_CaseCenterStoredProcedure(new List<String>{'getGdsGetCustCreditExpLoan', 'getGDSFraudFlags'},opp.Id);
        Test.stopTest();

        List<Webservice_Field__c> ws = [SELECT Id FROM Webservice_Field__c WHERE Opportunity__c = :opp.Id];
        System.assertEquals(2, ws.size());
    }

    @isTest
    static void testBadJsonThrows() {
        try {
            SL_CaseCenterStoredProcedure.convertResponse('', 'key - Field__c', Id.valueOf(UserInfo.getUserId()));
            System.assert(false);
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Invalid input'));
        }
    }

    @isTest
    static void testBadMappingLineThrows() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        try {
            SL_CaseCenterStoredProcedure.buildRequest(opp.Id, 'No-Dash-MappingLine-Here');
            System.assert(false);
        } catch (SL_CaseCenterStoredProcedure.MappingException e) {
            System.assert(e.getMessage().contains('Invalid mapping line'));
        }
    }
}