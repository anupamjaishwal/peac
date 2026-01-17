@isTest
public class SL_Contract_AssetTriggerHandlerTest {
    @isTest
    static void updateInsurance() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1,3);

        Insurance__c insurance = [SELECT Id FROM Insurance__c];
        Contract__c contract = [SELECT Id, Name, Insurance__c FROM Contract__c];
        contract.Insurance__c = insurance.Id;
        update contract;
        List<Contract_Asset__c> assets = [SELECT Id, Insurance__c, Contract__c, Titled_Asset__c FROM Contract_Asset__c];
        assets[0].Titled_Asset__c = null;
        assets[1].Titled_Asset__c = 'N';
        assets[2].Titled_Asset__c = 'Y';
        assets[0].Insurance__c = null;
        assets[1].Insurance__c = null;
        assets[2].Insurance__c = null;
        assets[0].Equipment_Received_Date__c = Date.Today();
        assets[1].Equipment_Recycled_Date__c = Date.Today();
        assets[2].Equipment_Sale_Date__c = Date.Today();
        assets[0].Serial_Number__c = '455555';
        assets[0].File_Upload__c = 'Proceeds';
        //assets[0].Net_Proceeds__c = 1000;
        assets[0].Net_Sale_Price__c=25000;
        assets[0].SP_Partner_Location__c='TestText';
        Test.startTest();
        update assets;
        Test.stopTest();
        List<Contract_Asset__c> assetsUpdated = [SELECT Id, Insurance__c, Contract__c, Titled_Asset__c FROM Contract_Asset__c WHERE Insurance__c = :insurance.Id];
        System.assertEquals(2, assetsUpdated.size());
    }

    @isTest
    static void updateStatus() {
        
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1,3);
        List<Contract_Asset__c> assets = new List<Contract_Asset__c>();
        Contract__c contract = [SELECT Id, Name, Insurance__c FROM Contract__c];

        Contract_Asset__c newAsset1 = new Contract_Asset__c();
        newAsset1.Contract__c = contract.Id;
        newAsset1.Titled_Asset__c = 'Y';
        newAsset1.Insurance__c = null;
        newAsset1.File_Upload__c = 'Condition';
        newAsset1.Equipment_Received_Date__c = Date.Today();
        newAsset1.Serial_Number__c = '147895463';
        newAsset1.SP_Partner_Location__c='TestText';
        newAsset1.SP_Mfg_Make__c='TestText';
        assets.add(newAsset1);


        Contract_Asset__c newAsset2 = new Contract_Asset__c();
        newAsset2.Contract__c = contract.Id;
        newAsset2.Titled_Asset__c = 'Y';
        newAsset2.Insurance__c = null;
        newAsset2.File_Upload__c = 'Condition';
        newAsset2.Equipment_Recycled_Date__c = Date.Today();
        newAsset2.Equipment_Received_Date__c = null;
        newAsset2.Serial_Number__c = '247895463';
        newAsset2.SP_Partner_Location__c='TestText';
        newAsset2.SP_Mfg_Make__c='TestText';
        assets.add(newAsset2);

        Contract_Asset__c newAsset3 = new Contract_Asset__c();
        newAsset3.Contract__c = contract.Id;
        newAsset3.Titled_Asset__c = 'Y';
        newAsset3.Insurance__c = null;
        newAsset3.File_Upload__c = 'Condition';
        newAsset3.Sold__c = Date.Today();
        newAsset3.Equipment_Received_Date__c = null;
        newAsset3.Serial_Number__c = '347895463';
        newAsset3.SP_Partner_Location__c='TestText';
        newAsset3.SP_Mfg_Make__c='TestText';
        assets.add(newAsset3);


        Test.startTest();
        try{
            insert assets;
        }
        catch(Exception e){}
        
        Test.stopTest();
    }
   
    
    @isTest
    static void testUpdateServiceProvider() {
        // Create test data
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 3);

        // Retrieve the 'Service Provider' record type ID
        String ServProvRecordTypeID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Service Provider').getRecordTypeId();

        // Create service provider accounts
        Account serviceProvider1 = new Account(Name = 'Service Provider 1', RecordTypeId = ServProvRecordTypeID);
        Account serviceProvider2 = new Account(Name = 'Service Provider 2', RecordTypeId = ServProvRecordTypeID);
        insert serviceProvider1;
        insert serviceProvider2;

        // Create locations with service providers
        Schema.Location location1 = new Schema.Location(Name = 'Location 1', Service_Provider__c = serviceProvider1.Id, Is_Active__c = true);
        Schema.Location location2 = new Schema.Location(Name = 'Location 2', Service_Provider__c = serviceProvider2.Id, Is_Active__c = true);
        insert location1;
        insert location2;

        // Retrieve the created contract
        List<Contract__c> contracts = SL_SCTestData.testContracts;

        // Create contract assets with initial location
        Contract_Asset__c asset1 = new Contract_Asset__c(Contract__c = contracts[0].Id, Location__c = location1.Id);
        Contract_Asset__c asset2 = new Contract_Asset__c(Contract__c = contracts[0].Id, Location__c = location1.Id);
        insert asset1;
        insert asset2;

        // Update assets to change Location__c
        asset1.Location__c = location2.Id;
        asset2.Location__c = location2.Id;

        // Create oldMap with original asset values
        Map<Id, SObject> oldMap = new Map<Id, SObject>();
        oldMap.put(asset1.Id, asset1.clone(false, true, true, true));
        oldMap.put(asset2.Id, asset2.clone(false, true, true, true));

        // Perform the update within a test context
        Test.startTest();
        update new List<Contract_Asset__c>{asset1, asset2};
        Test.stopTest();

        // Verify that Service_Provider__c is updated correctly
        List<Contract_Asset__c> updatedAssets = [SELECT Id, Service_Provider__c FROM Contract_Asset__c WHERE Id IN :new List<Id>{asset1.Id, asset2.Id}];
        for (Contract_Asset__c asset : updatedAssets) {
            System.assertEquals(serviceProvider2.Id, asset.Service_Provider__c);
        }
    }
}