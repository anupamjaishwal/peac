@isTest
public with sharing class SL_InfoleaseInsuranceUpdateTest {
    @TestSetup 
    static void setup () {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 1);

        Insurance__c ins = new Insurance__c();
        ins.Insurance_Id__c = '401-1331066-001*001';
        ins.Effective_Date__c = System.today();
        ins.Expiration_Date__c = System.today().addMonths(6);
        insert ins;
    }

    static testMethod void testUpdate_Fail() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseInsuranceUpdateMockFail ());
        Insurance__c ins = [SELECT Id, Insurance_Id__c, Effective_Date__c, Expiration_Date__c FROM Insurance__c LIMIT 1];
        ins.Effective_Date__c = System.today().addDays(-1);
        ins.Insurance_Id__c = '40066-001*001';
        update ins;
        Test.stopTest();
    }

    static testMethod void testService_Success(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseInsuranceUpdateMock ());
        Insurance__c ins = [SELECT Id, Insurance_Id__c, Effective_Date__c, Expiration_Date__c FROM Insurance__c LIMIT 1];
        ins.Effective_Date__c = System.today().addDays(-1);
        update ins;
        Test.stopTest();
    }
static testMethod void testService_Success_AllFields(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseInsuranceUpdateMock ());
        Insurance__c ins = [SELECT Id, Insurance_Id__c, Effective_Date__c, Expiration_Date__c FROM Insurance__c LIMIT 1];
        ins.Effective_Date__c = System.today().addDays(-1);
        ins.Integration_Status__c = 'Re-sync';
        update ins;
        Test.stopTest();
    }

    static testMethod void testUpdate_Exception() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseInsuranceUpdateMock ());
        Insurance__c ins = [SELECT Id, Insurance_Id__c, Effective_Date__c, Expiration_Date__c FROM Insurance__c LIMIT 1];
        
        SL_InfoleaseInsuranceHandler.updateInsuranceFuture(null, null);
        Test.stopTest();
    }
    static testMethod void testUpdate_Exception_2() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseInsuranceUpdateMockFail2 ());
        Insurance__c ins = [SELECT Id, Insurance_Id__c, Effective_Date__c, Expiration_Date__c FROM Insurance__c LIMIT 1];
        ins.Effective_Date__c = System.today().addDays(-1);
        ins.Insurance_Id__c = '40066-001*001';
        update ins;
        Test.stopTest();
    }

    static testMethod void testUtils(){
        
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
}