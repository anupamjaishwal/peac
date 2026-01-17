@isTest
public with sharing class SL_UpdatePrivateLabelDocTest {
    @isTest
    static void insertAndUpdate() {
        SL_SCTestData.createAccountAndContracts(2, 1);
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Id dealerVendorId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
        Account dealerAccount = SL_SCTestData.testAccounts[1];
        dealerAccount.RecordTypeId = dealerVendorId;
        update dealerAccount;
        Opportunity theOpp = SL_SCTestData.testOpportunities[0];
        theOpp.Dealer_Account__c = dealerAccount.Id;
        update theOpp;
        Set<Id> accountIdsPLD = new Set<Id>();
        accountIdsPLD.add(dealerAccount.Id);
        Test.startTest();
        dealerAccount.Private_Label_Documents__c = true;
        update dealerAccount;
        //System.enqueueJob(new SL_UpdatePrivateLabelDocQ(accountIdsPLD));
        //Database.executeBatch(new SL_UpdatePrivateLabelDocBatch(accountIdsPLD), 50);
        Test.stopTest();
        Account dealerAfter = [SELECT Id, Private_Label_Documents__c FROM Account WHERE Id = :dealerAccount.Id];
        Opportunity oppAfter = [SELECT Id, Private_Label_Documents__c FROM Opportunity WHERE Id = :theOpp.Id];
        System.Assert.areEqual(dealerAfter.Private_Label_Documents__c, oppAfter.Private_Label_Documents__c, 'Private_Label_Documents__c must be the same');
    }
}