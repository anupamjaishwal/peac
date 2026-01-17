@isTest
public with sharing class SL_NotificationEmailTest {
    @isTest
    public static void general() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>();
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();
        Opportunity opp1 = SL_SCTestData.testOpportunities[0];
        Opportunity opp2 = opp1.clone(true);
        oldMap.put(opp1.Id, opp1);
        newMap.put(opp2.Id, opp2);
        Test.startTest();
        System.enqueueJob(new SL_NotificationEmailQ(oldMap, newMap, 'Submitted'));
        System.enqueueJob(new SL_NotificationEmailQ(oldMap, newMap, 'Approved'));
        System.enqueueJob(new SL_NotificationEmailQ(oldMap, newMap, 'Rejected'));
        System.enqueueJob(new SL_NotificationEmailQ(oldMap, newMap, 'More Info'));
        System.enqueueJob(new SL_NotificationEmailQ(oldMap, newMap, 'Submitted Loan'));
        Test.stopTest();
    }
}