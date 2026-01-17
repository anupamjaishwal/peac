/**
 * Tests for SL_ReturnAuthorizationHelper
 */

@IsTest
public with sharing class SL_ReturnAuthorizationHelperTest {

    @isTest
    static void testUpdateContractAssets() {
        // Create necessary test data using SL_SCTestData methods
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 2); // Creating 1 insurance with 2 contract assets

        Contract__c contract = [SELECT Id FROM Contract__c LIMIT 1];
        Test.startTest();
        SL_ReturnAuthorizationHelper.updateContractAssets(contract.Id, '2');
        Test.stopTest();
    }


    @isTest
    static void testCheckReturnAuthorizationContractAssets() {
        // Create necessary test data using SL_SCTestData methods
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 2); // Creating 1 insurance with 2 contract assets

        Contract__c contract = [SELECT Id FROM Contract__c LIMIT 1];
        Test.startTest();
        SL_ReturnAuthorizationHelper.checkReturnAuthorizationContractAssets(contract.Id, 'TestBuyoutNoPartial');
        Test.stopTest();
    }


    @isTest
    static void testCheckReturnAuthorizationContractAssetsBuyouts() {
        // Create necessary test data using SL_SCTestData methods
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 2); // Creating 1 insurance with 2 contract assets

		Date currentDate = System.today();        	
        // Create a Buyout__c record with Partial_Buyout__c set to true
        Buyout__c buyout = new Buyout__c(
            Contract__c = SL_SCTestData.testContracts[0].Id,
            Name = 'TestBuyout',
            Partial_Buyout__c = true,
            Quote_Sequence__c = 'TestBuyout',
            Buyout_Amount__c = 1000,
            Buyout_Type__c = '22',
            Date_Quoted__c = currentDate,
            Expiration_Date__c = currentDate.addDays(30)
            
        );
        insert buyout;

        // Create Buyout_Asset__c records linked to the Buyout__c
        List<Buyout_Asset__c> buyoutAssets = new List<Buyout_Asset__c>();
        for (Contract_Asset__c asset : SL_SCTestData.testCAssets) {
            buyoutAssets.add(new Buyout_Asset__c(
                Buyout__c = buyout.Id,
                Contract_Asset__c = asset.Id
            ));
        }
        insert buyoutAssets;
        Contract__c contract = [SELECT Id FROM Contract__c LIMIT 1];
        Buyout__c singleBuyout = [SELECT Id FROM Buyout__c LIMIT 1];
        Test.startTest();
        SL_ReturnAuthorizationHelper.checkReturnAuthorizationContractAssets(contract.Id, 'TestBuyout');
        SL_ReturnAuthorizationHelper.returnAuthorizationRequest(singleBuyout.Id);
        Test.stopTest();
    }
    
    
}