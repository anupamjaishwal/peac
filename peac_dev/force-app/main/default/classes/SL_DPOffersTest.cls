@isTest
public with sharing class SL_DPOffersTest {
    @isTest
    public static void getAssets() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Account acc = SL_SCTestData.testAccounts[0];
        SL_SCTestData.createOpportunitiesAndAssets(acc.Id, 1, 1);
        Opportunity opp = SL_SCTestData.testOpportunities[0];
        String result1;
        Test.startTest();
        result1 = SL_DPOffers.hubExecute('getAssets', new List<String>{opp.Id});
        Test.stopTest();
        system.debug(result1);
        System.Assert.isTrue(result1.contains(String.valueOf(SL_SCTestData.testAssets[0].Id)), 'the call should return a field of Opportunity plus related assets');
    }
}