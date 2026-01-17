@isTest
public with sharing class TC_SetBillingPrimaryContactInfoTest {
    @isTest
    static void setBillingPrimaryContactInfo() {
        Id dealerVendorId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
        Id endUserAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        Id tfgDocsId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('TFG_Docs').getRecordTypeId();
        SL_SCTestData.createAccountAndContracts(2, 1);
        List<Account> accounts = SL_SCTestData.testAccounts;
        accounts[0].RecordTypeId = dealerVendorId;
        accounts[1].RecordTypeId = endUserAccountId;
        Integer queriesConsumed = 0;
        update accounts;
        Test.startTest();
        SL_SCTestData.createOpportunitiesAndAssets(accounts[1].Id, 1, 1);
        List<Opportunity> opportunities = SL_SCTestData.testOpportunities;
        insert new List<OpportunityContactRole>{new OpportunityContactRole(Role = 'Primary Contact', ContactId = SL_SCTestData.testContacts[0].Id, IsPrimary = true, OpportunityId = opportunities[0].Id),
            new OpportunityContactRole(Role = 'Billing Contact', ContactId = SL_SCTestData.testContacts[1].Id, IsPrimary = false, OpportunityId = opportunities[0].Id)};
        queriesConsumed = System.Limits.getQueries() - queriesConsumed;
        opportunities[0].StageName = 'Decision';
        opportunities[0].Opportunity_Status__c = 'Credit - In Queue';
        opportunities[0].RecordTypeId = tfgDocsId;
        opportunities[0].Credit_Decision__c = false;
        opportunities[0].Resubmitted_to_Credit__c = true;
        update opportunities;
        System.debug('queries after update Opportunity: ' + System.Limits.getQueries());
        queriesConsumed = System.Limits.getQueries() - queriesConsumed;
        Test.stopTest();
        List<Opportunity> oppsAfter = [SELECT Id, Primary_Contact__c, Billing_Contact__c FROM Opportunity];
        System.assertEquals(SL_SCTestData.testContacts[0].Id, oppsAfter[0].Primary_Contact__c);
        System.assertEquals(SL_SCTestData.testContacts[1].Id, oppsAfter[0].Billing_Contact__c);
    }
}