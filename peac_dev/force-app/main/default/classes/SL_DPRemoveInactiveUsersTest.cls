@isTest
public with sharing class SL_DPRemoveInactiveUsersTest {
    @testSetup
    static void setup(){
        Test.startTest();
        SL_SCTestData.createAccountAndContracts(2, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        user dpUser = SL_SCTestData.createDPDataForUser(SL_SCTestData.testAccounts[1]);
        Test.stopTest();
        Contract__c theContract = SL_SCTestData.testContracts[0];
        Opportunity theOpp = SL_SCTestData.testOpportunities[0];
        theContract.Dealer_User__c = dpUser.Id;
        theOpp.Dealer_User__c = dpUser.Id;
        update theContract;
        update theOpp;
    }
    @isTest
    public static void scenario1() {
        Test.startTest();
        List<Contract__c> contractsBefore = [SELECT Id, Name, Dealer_User__c, Dealer_User__r.IsPrmSuperUser, Dealer_User__r.IsActive FROM Contract__c];
        user dpUser = contractsBefore[0].Dealer_User__r;
        dpUser.IsActive = false;
        update dpUser;
        Database.ExecuteBatch(new SL_DPRemoveInactiveUsers());
        Test.stopTest();
        List<Contract__c> contractsAfter = [SELECT Id, Name, Dealer_User__c FROM Contract__c];
        List<Opportunity> oppsAfter = [SELECT Id, Name, Dealer_User__c FROM Opportunity];
        System.Assert.areEqual(null, contractsAfter[0].Dealer_User__c, 'since user is inactive Dealer User field is cleared');
        System.Assert.areEqual(null, oppsAfter[0].Dealer_User__c, 'since user is inactive Dealer User field is cleared');
    }
    
    @isTest
    public static void justSchedule() {
        Test.startTest();
        System.schedule('DP remove inactive just test', '0 0 3 * * ?' , new SL_DPRemoveInactiveUsers());
        Test.stopTest();
    }
}