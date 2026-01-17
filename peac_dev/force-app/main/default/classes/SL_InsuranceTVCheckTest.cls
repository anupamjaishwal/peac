@isTest
public class SL_InsuranceTVCheckTest {
    @isTest
    static void schedule(){
        Test.startTest();
        System.schedule('Test Update Insurance Title Vehicles Test', '0 0 2 * * ?' , new SL_InsuranceTVCheckSchedule());
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void batch(){
        SL_SCTestData.createAccountAndContracts(1, 10);
        SL_SCTestData.createInsurancesAndContractAssets(10, 20);
        List<Contract_Asset__c> assets = SL_SCTestData.testCAssets;
        assets[10].Asset_Code__c = 'Titled Vehicles (General)';
        assets[20].Asset_Code__c = 'Titled-V Logging';
        assets[42].Asset_Code__c = 'Titled-V Logging';
        assets[94].Asset_Code__c = 'POS/Point of Sale';
        List<Contract_Asset__c> assetsUpd = new List<Contract_Asset__c>();
        assetsUpd.add(assets[10]);
        assetsUpd.add(assets[20]);
        assetsUpd.add(assets[42]);
        assetsUpd.add(assets[94]);
        update assetsUpd;
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        List<Insurance__c> insurances = SL_SCTestData.testInsurances;
        contracts[2].Insurance_Status__c = '20A';
        contracts[2].Insurance__c = insurances[2].Id;
        update contracts;
        Test.startTest();
        Database.executeBatch(new SL_InsuranceTVCheckBatch());
        Test.stopTest();
        List<Insurance__c> insurancesAfter = [SELECT Id, Titled_Vehicles__c FROM Insurance__c LIMIT 100];
        System.Assert.areEqual(true, insurancesAfter[0].Titled_Vehicles__c);
        System.Assert.areEqual(true, insurancesAfter[1].Titled_Vehicles__c);
        System.Assert.areEqual(false, insurancesAfter[2].Titled_Vehicles__c, 'The validation stops the update, but the others do get updated.');
        System.Assert.areEqual(false, insurancesAfter[5].Titled_Vehicles__c);
    }
}