@isTest
public with sharing class SL_EmailAlertsFormerWorkFlowsTest {
    @isTest
    public static void sendIt() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        List<Opportunity> opps = SL_SCTestData.testOpportunities;
        opps[0].Application_Status__c = 'Automatically Approved';
        opps[0].Application__c = '03310636';
        opps[0].Credit_Decision__c = true;
        Test.startTest();
        update opps[0];
        Test.stopTest();

    }
}