@isTest
public with sharing class SL_DealerPortalShareOppTest {
  private static final String OEG_DEALER_PROFILE = 'OEG Dealer';
  private static final String USERNAME = 'Portal.SL.test.user@silverlinecrm.com';

    @isTest
    static void insertAndUpdate() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Id accId = SL_SCTestData.testAccounts[0].Id;
        User dpUser = SL_SCTestData.createDPUser(accId);
        Map<Id, List<Id>> usersByOppsToShare = new Map<Id, List<Id>>();
        usersByOppsToShare.put(SL_SCTestData.testOpportunities[0].Id, new List<Id>{dpUser.Id});
        Test.startTest();
        System.enqueueJob(new SL_DealerPortalShareOppQ(usersByOppsToShare));
        List<Contract__c> contractsToUpdate = new List<Contract__c>();
    List<Dealer__c> primDealersToUpd = new List<Dealer__c>();
    List<Dealer__c> primDealersToInsert = new List<Dealer__c>();
    List<Dealer__c> primDealersToDelete = new List<Dealer__c>();

        Test.stopTest();
    }

    @isTest
    static void secondConstructor() {
        SL_SCTestData.createAccountAndContracts(3, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        // Id accId = SL_SCTestData.testAccounts[0].Id;
        // User dpUser = SL_SCTestData.createDPUser(accId);
        Test.startTest();
        Opportunity opp = SL_SCTestData.testOpportunities[0];
        SL_SCTestData.testAccounts[1].recordTypeId = SL_SCTestData.DEALER_ACC;
        SL_SCTestData.testAccounts[2].recordTypeId = SL_SCTestData.DEALER_ACC;
        update SL_SCTestData.testAccounts;
        Dealer__c testDealer = new Dealer__c(Opportunity__c = opp.Id, Primary_Dealer__c = true, Dealer__c = SL_SCTestData.testAccounts[1].Id);
        Dealer__c testDealer2 = new Dealer__c(Opportunity__c = opp.Id, Dealer__c = SL_SCTestData.testAccounts[2].Id);
        insert testDealer;
        List<Contract__c> contractsToUpdate = new List<Contract__c>{SL_SCTestData.testContracts[0]};
        List<Dealer__c> primDealersToUpd = new List<Dealer__c>{testDealer};
        List<Dealer__c> primDealersToInsert = new List<Dealer__c>{testDealer2};
        List<Dealer__c> primDealersToDelete = new List<Dealer__c>{testDealer2};
        System.enqueueJob(new SL_DealerPortalShareOppQ(contractsToUpdate, primDealersToUpd, primDealersToInsert, primDealersToDelete));
        Test.stopTest();
    }
}