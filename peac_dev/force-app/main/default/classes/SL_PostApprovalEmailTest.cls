@isTest
public with sharing class SL_PostApprovalEmailTest {
    @isTest
    public static void sendIt() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Account theAccount = SL_SCTestData.testAccounts[0];
        theAccount.Name = 'changed name 123';
        Test.startTest();
        update theAccount;
        //System.enqueueJob(new SL_PostApprovalEmailQ(new List<Id> {theAccount.Id}));
        Test.stopTest();

    }
}