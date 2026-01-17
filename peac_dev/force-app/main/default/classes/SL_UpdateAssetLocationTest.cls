@isTest
public with sharing class SL_UpdateAssetLocationTest {
    @isTest
    static void getCounty(){
        SL_SCTestData.createBridgeWareSetting();
        String result;
        Test.startTest();
        result = SL_UpdateAssetLocation.hubExecute('getCounty', new List<String>{ '38542' });
        Test.StopTest();
        System.assert(String.isNotBlank(result));
    }
    @isTest
    static void saveNewLocation(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 1);
        Contract_Asset__c asset = [SELECT Id FROM Contract_Asset__c LIMIT 1];
        String result, result2;
        Test.startTest();
        result = SL_UpdateAssetLocation.hubExecute('saveNewLocation', new List<String>{ asset.Id, '43', '133', '1999', '301 Main Street',
            '3nd floor', '38542', '' });
        result2 = SL_UpdateAssetLocation.hubExecute('saveNewLocation', new List<String>{ asset.Id, '43', '133', '1999', '301 Main Street',
            '3nd floor', '38542', '2022-09-19' });
        Test.StopTest();
        System.assert(String.isNotBlank(result));
    }
}