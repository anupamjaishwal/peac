@isTest 
public with sharing class SL_RescoreOverToleranceTest {
    @isTest
    public static void callGdsRescore() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        // Test.setMock(HttpCalloutMock.class, new TC_GdsScoreApiCalloutMock());
        Test.startTest();
        Opportunity theOpp = SL_SCTestData.testOpportunities[0];
        System.enqueueJob(new SL_RescoreOverToleranceQ(new List<Id>{theOpp.Id}));
        TC_GdsScoreCtrl.callGdsScore(theOpp.Id);
        TC_GdsScoreCtrl.callDwhStoredProcFraudQuery(theOpp.Id);
        TC_GdsScoreCtrl.DoMarlinNetB2BCalls(new List<Id>{theOpp.Id});
        Test.stopTest();
    }
}