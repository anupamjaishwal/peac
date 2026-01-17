@isTest
public with sharing class TC_PopulateAssetListPriceTest {
    @isTest 
    public static void populateAssetListPrice(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        List<Opportunity> opportunities = SL_SCTestData.testOpportunities;
        List<Asset__c> assets = SL_SCTestData.testAssets;
        assets[0].List_Price__c = 0;
        update assets;
        opportunities[0].Equipment_Cost__c = 307;
        Test.startTest();
        update opportunities;
        Test.stopTest();
        List<Opportunity> oppsAfter = [SELECT Id, Branch__c, Equipment_Cost__c FROM Opportunity];
        List<Asset__c> assetsAfter = [SELECT Id, Cost__c FROM Asset__c];
        Assert.areEqual(oppsAfter[0].Equipment_Cost__c, assetsAfter[0].Cost__c, 'TC_PopulateAssetListPrice sets the cost equals to the opp cost if there is just one asset');
    }
    
}