@isTest
public with sharing class TC_ChangedToDocsRequestedTest {
    @isTest 
    public static void changedToDocsRequested(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        List<Opportunity> opportunities = SL_SCTestData.testOpportunities;
        // List<Asset__c> assets = SL_SCTestData.testAssets;
        // assets[0].List_Price__c = 0;
        // update assets;
        opportunities[0].Probability = 75;
        Test.startTest();
        update opportunities;
        Test.stopTest();
        // List<Opportunity> oppsAfter = [SELECT Id, Branch__c, Equipment_Cost__c FROM Opportunity];
        List<Asset__c> assetsAfter = [SELECT Id, Cost__c, List_Price__c FROM Asset__c];
        Assert.areEqual(assetsAfter[0].List_Price__c, assetsAfter[0].Cost__c, 'TC_ChangedToDocsRequested sets the cost equals to the List Price');
    }
    
}