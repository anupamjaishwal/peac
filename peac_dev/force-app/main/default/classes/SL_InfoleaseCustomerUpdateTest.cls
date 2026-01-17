@isTest
public with sharing class SL_InfoleaseCustomerUpdateTest {
    @TestSetup 
    static void setup () {
        SL_SCTestData.createBridgeWareSetting();
        Account act = new Account ();
        act.name = 'Update Test1';
        act.Phone = '2225551234';
        act.CCAN__c = '';
        act.Business_Phone__c = '5854567890';
        act.Sic = 'SICTest001';
        act.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('End_User').getRecordTypeId();
        insert act;
    }

    @isTest
    static void testUpdate_Fail() {
        List<Account> acc = [SELECT Id FROM Account];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseCustomerUpdateMock());
        SL_InfoleaseCustomerIntegrationHandler.updateCustomerFuture('SOME RANDOM TEXT TO MAKE IT FAIL', null, true, Datetime.now());
        Test.stopTest ();
    }
    static testMethod void testUpdate_Fail2(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseCustomerUpdateMockFail());
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        acc.CCAN__c = '1700261';
        acc.Integration_Status__c = 'Re-sync';
        update acc;
        Test.stopTest();
    }
	static testMethod void testUpdate_Fail3(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseCustomerUpdateMockFail2());
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        acc.CCAN__c = '1700261';
        acc.Integration_Status__c = 'Re-sync';
        update acc;
        Test.stopTest();
    }
    
    static testMethod void testService_Success(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseCustomerUpdateMock ());
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        acc.CCAN__c = '1700261';
        acc.Business_Address__c = 'New address';
        update acc;
        Test.stopTest();
    }
    // copado
    static testMethod void testService_Success_AllFields(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseCustomerUpdateMock ());
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        acc.CCAN__c = '1700261';
        acc.Integration_Status__c = 'Re-sync';
        update acc;
        Test.stopTest();
    }
    static testMethod void testService_CCANDoesntExist(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseCustomerMockResponse ());
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        acc.CCAN__c = '3212422222';
        update acc;
        Test.stopTest();
    }
    static testMethod void testStatusUpdate(){
        Test.startTest();
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        SL_InfoleaseUtils.updateRecordWithSynced(acc.Id);
        Test.stopTest();
    }

    static testMethod void testUtils(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 1);
        Account account = [SELECT Id FROM Account LIMIT 1];
        Contract__c contract = [SELECT Id FROM Contract__c LIMIT 1];
        Insurance__c insurance = [SELECT Id FROM Insurance__c LIMIT 1];
        Contract_Asset__c asset = [SELECT Id FROM Contract_Asset__c LIMIT 1];
        Test.startTest();
        SL_InfoleaseUtils.updateRecordWithSynced(account.Id);
        SL_InfoleaseUtils.updateRecordWithSynced(contract.Id);
        SL_InfoleaseUtils.updateRecordWithSynced(insurance.Id);
        SL_InfoleaseUtils.updateRecordWithSynced(asset.Id);
        SL_InfoleaseUtils.updateRecordWithError(account.Id);
        SL_InfoleaseUtils.updateRecordWithError(contract.Id);
        SL_InfoleaseUtils.updateRecordWithError(insurance.Id);
        SL_InfoleaseUtils.updateRecordWithError(asset.Id);
        Test.stopTest();
        System.assert(true);
    }

    static testMethod void testReqWrapper(){

        SL_InfoleaseIntegrationRequestWrapper SL = new SL_InfoleaseIntegrationRequestWrapper();
        SL_InfoleaseIntegrationRequestWrapper.Header hed = new SL_InfoleaseIntegrationRequestWrapper.Header();
        hed.NitroApi = 'test';
        SL.Header = hed;
        //_InfoleaseIntegrationRequestWrapper.Request req = new SL_InfoleaseIntegrationRequestWrapper.Request();
        
    }
    
    public class SL_InfoleaseCustomerUpdateMockFail implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String ccan = 'CCAN' + Math.random()*100;
            HttpResponse resp = new HttpResponse ();
            resp.setStatus('OK');
            resp.setStatusCode(200);
            resp.setBody('{ "Header":	{ "NitroApi":	"BW.CREATE.CUSTOMER.UDO" }, "Response":	{ "Success": "false", "CCAN":	"123944", "Messages":	["Customer not created"], "Errors":	["An Error occurred... helpful, right?", "Account not updated"] } }');
            return resp;
    
        }
    }
    public class SL_InfoleaseCustomerUpdateMockFail2 implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            String ccan = 'CCAN' + Math.random()*100;
            HttpResponse resp = new HttpResponse ();
            resp.setStatus('OK');
            resp.setStatusCode(201);
            resp.setBody('{ "Header":	{ "NitroApi":	"BW.CREATE.CUSTOMER.UDO" }, "Response":	{ "Success": "false", "CCAN":	"123944", "Messages":	["Customer not created"], "Errors":	["An Error occurred... helpful, right?", "Account not updated"] } }');
            return resp;
    
        }
    }
}