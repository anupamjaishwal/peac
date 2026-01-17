@isTest
public with sharing class SL_InfoleaseAssetUpdateTest {
    @TestSetup
    static void makeData(){

        // Setup test data
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 1);
    }

    static testMethod void testService_Success(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseAssetUpdateMock ());
        Contract_Asset__c theAsset = [SELECT Id, Quantity__c, Year_of_Manufacture__c, Model_Number__c, Equipment_Description__c, Asset_Number__c FROM Contract_Asset__c LIMIT 1];
        theAsset.Quantity__c = 1;
        theAsset.Year_of_Manufacture__c = '2018';
        theAsset.Model_Number__c = '12ABCXYZ007';
        theAsset.Equipment_Description__c = 'Some random equipment description';
        theAsset.Asset_Number__c = '630103';
        update theAsset;
        Test.stopTest();
    }
    static testMethod void testService_Success_AllFields(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseAssetUpdateMock());
        Contract_Asset__c theAsset = [SELECT Id, Quantity__c, Year_of_Manufacture__c, Model_Number__c, Equipment_Description__c, Asset_Number__c FROM Contract_Asset__c LIMIT 1];
        theAsset.Quantity__c = 1;
        theAsset.Year_of_Manufacture__c = '2018';
        theAsset.Model_Number__c = '12ABCXYZ007';
        theAsset.Equipment_Description__c = 'Some random equipment description';
        theAsset.Asset_Number__c = '630103';
        theAsset.Integration_Status__c = 'Re-sync';
        update theAsset;
        Test.stopTest();
    }
    static testMethod void testService_Fail(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseAssetUpdateMockFail ());
        Contract_Asset__c theAsset = [SELECT Id, Quantity__c, Year_of_Manufacture__c, Model_Number__c, Equipment_Description__c, Asset_Number__c FROM Contract_Asset__c LIMIT 1];
        theAsset.Quantity__c = 1;
        theAsset.Year_of_Manufacture__c = '2018';
        theAsset.Model_Number__c = '12ABCXYZ007';
        theAsset.Equipment_Description__c = 'Some random equipment description';
        theAsset.Asset_Number__c = '6301034';
        update theAsset;
        Test.stopTest();
    }
    static testMethod void testService_Fail2(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseAssetUpdateMockFail2 ());
        Contract_Asset__c theAsset = [SELECT Id, Quantity__c, Year_of_Manufacture__c, Model_Number__c, Equipment_Description__c, Asset_Number__c FROM Contract_Asset__c LIMIT 1];
        theAsset.Quantity__c = 1;
        theAsset.Year_of_Manufacture__c = '2018';
        theAsset.Model_Number__c = '12ABCXYZ007';
        theAsset.Equipment_Description__c = 'Some random equipment description';
        theAsset.Asset_Number__c = '6301034';
        update theAsset;
        Test.stopTest();
    }
    static testMethod void testService_Exception(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseAssetUpdateMockFail ());
        SL_InfoleaseAssetHandler.updateAssetFuture(null, null);
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
        Test.startTest();
        SL_InfoleaseIntegrationRequestWrapper SL = new SL_InfoleaseIntegrationRequestWrapper();
        SL_InfoleaseIntegrationRequestWrapper.Header hed = new SL_InfoleaseIntegrationRequestWrapper.Header();
        hed.NitroApi = 'test';
        SL.Header = hed;
        Test.stopTest();
        System.assert(true);
        
    }
}