@isTest
public with sharing class SL_InfoleaseContractUpdateTest {
    @TestSetup
    static void makeData(){
        //insert new Contract_Criteria__c(Maximum_Balance_CBR__c = 15000, SetupOwnerId = UserInfo.getOrganizationId());
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 2);

        Contract__c thisContract = new Contract__c();
        thisContract.Status__c = 'Active';
        thisContract.Name = '100100100-1010';
        thisContract.Delinquency_Status_Code__c = '00';
        insert thisContract;
    }

    static testMethod void testService_Success(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseContractUpdateMock ());
        Contract__c theContract = [SELECT Id, Name FROM Contract__c LIMIT 1];
        theContract.Name = '401-1434807-001';
        theContract.City__c = 'test city';
        theContract.Infolease_Environment__c = '10';
        update theContract;
        SL_InfoleaseIntegrationResponseWrapper.unWrap('{"response": "jsonString" }');
        Test.stopTest();
    }
    static testMethod void testService_Success_AllFields(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseContractUpdateMock());
        Contract__c theContract = [SELECT Id, Name FROM Contract__c LIMIT 1];
        theContract.Name = '401-1434807-001';
        theContract.Integration_Status__c = 'Re-sync';
        theContract.Infolease_Environment__c = '9';
        update theContract;
        Test.stopTest();
    }
    static testMethod void testService_Fail(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseContractUpdateMockFail ());
        Contract__c theContract = [SELECT Id, Name FROM Contract__c LIMIT 1];
        theContract.Integration_Status__c = 'Re-sync';
        update theContract;
        SL_InfoleaseContractService testInstance = new SL_InfoleaseContractService();
        testInstance.updateContract(null, '', '10');
        SL_InfoleaseContractService.logResults('test request', 'test response', 'no message', '200', theContract.Id);
        List<Contract__c> validContractList = new List<Contract__c>{theContract};
        Map<Contract__c, Set<String>> conToFieldsMap = new Map<Contract__c, Set<String>>();
        Database.executeBatch(new SL_InfoleaseContractQueueable(validContractList, conToFieldsMap, true));
        Database.executeBatch(new SL_InfoleaseContractQueueable(validContractList, conToFieldsMap, true));
        System.enqueueJob(new SL_InfoleaseContractBatchQueueable(validContractList, null, true));
        Test.stopTest();
    }
    static testMethod void testService_Fail2(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SL_InfoleaseContractUpdateMockFail2 ());
        SL_InfoleaseContractHandler.updateContractFuture(null, null, '9');
        Test.stopTest();
    }

    static testMethod void testStatusUpdate(){
        Test.startTest();
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        SL_InfoleaseUtils.updateRecordWithSynced(acc.Id);
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
    
    static testMethod void assetTest(){
        List<Contract_Asset__c> assets = [SELECT Id FROM Contract_Asset__c];
        List<Contract_Asset__c> uAssets = new List<Contract_Asset__c>();
        String flag = '1';
        for(Contract_Asset__c ac:assets){
            ac.Serial_Number__c = '455555'+flag;
            flag = ac.Id;
            ac.File_Upload__c = 'Proceeds';
            //ac.Net_Proceeds__c = 1000;
            ac.Net_Sale_Price__c=25000;
            ac.SP_Partner_Location__c='TestText';
        }
        Test.startTest();
        update assets;
        Test.stopTest();
    }
}