/**
* Created by andrewmayer on 1/29/20.
*/

@isTest public with sharing class TC_GdsScoreApiTest {
    
    private static String CRON_EXP = '0 5 0 * * ?';
    
    @testSetup public static void setupDeal () {
        insert new SL_Trigger_Settings__c(Name = 'default', KillList__c = 'Account');// \nOpportunity
        SL_SCTestData.createAccountAndContracts(5, 1);
        // dealer account Starting
        List<Account> dealerList = SL_SCTestData.testAccounts;
        
        dealerList[0].RecordTypeId = SL_SCTestData.DEALER_ACC;
        dealerList[0].Account_Dealer_Status__c = 'Active';
        dealerList[1].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        dealerList[1].Account_Dealer_Status__c = 'Active';
        dealerList[2].RecordTypeId = SL_SCTestData.DEALER_ACC;
        dealerList[2].Account_Dealer_Status__c = 'Active';
        dealerList[3].RecordTypeId = SL_SCTestData.DEALER_ACC;
        dealerList[3].Account_Dealer_Status__c = 'Watch List';
        dealerList[4].RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        
        for(Account a : dealerList){
            a.Date_Dealer_Approved_Most_Recent__c = Date.today ().addYears(-1).addDays(-1);
            a.Waiting_To_Be_Sent_To_Bridgeware__c = true; // so it doesn't send update through bridgeware
        }
        update dealerList;
        Test.startTest();
        // dealer account Ending
        
        //contact insertion
        List<Contact> contactTest = new List<Contact>();
        Contact c = new Contact();
        c.AccountId = dealerList[4].Id;
        c.FirstName = 'fn';
        c.LastName = 'ln';
        c.Phone = '6666666666';
        c.Email = 'testing2@mailinator.com';
        contactTest.add(c);
        
        Contact dealerContact = new Contact();
        dealerContact.FirstName = 'first';
        dealerContact.LastName = 'last';
        dealerContact.AccountId = dealerList[1].Id;
        dealerContact.Emailage_Result__c = 'FAIL';
        dealerContact.Override_Emailage_Result__c = true;
        dealerContact.Email = 'testing@mailinator.com';
        dealerContact.Phone = '6666666689';
        contactTest.add(dealerContact);
        insert contactTest; 
        Test.stopTest();

        List<Account> testAccs = [SELECT Id, Target_SDR_Campaign__c, CurrentCampaign__c, fml_AccountNeedsCampaignUpdate__c,
            fml_DerivedCampaign__c FROM Account];
        system.debug('testAccs: ' + testAccs[1]);
        system.debug('testAccs: ' + testAccs[4]);
        // creation of opp
        list<opportunity> dealerOpp = new list<opportunity>();        
        Opportunity opp = new Opportunity();
        opp.Name = 'testopp';
        opp.AccountId = dealerList[4].Id;
        opp.StageName = 'test';
        opp.CloseDate = Date.today() + 10;
        dealerOpp.add(opp);
        
        Opportunity opp1 = new Opportunity();
        opp1.Name = 'testopp1';
        opp1.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Booking').getRecordTypeId();
        opp1.AccountId = dealerList[1].Id;
        opp1.StageName = 'test';
        opp1.CloseDate = Date.today() + 10;
        dealerOpp.add(opp1);
        insert dealerOpp;
        
        List<OpportunityContactRole> roles = new List<OpportunityContactRole>();
        OpportunityContactRole role = new OpportunityContactRole();
        role.ContactId = contactTest[0].Id;
        role.OpportunityId = dealerOpp[0].Id;
        role.Role = 'Dealer Primary Contact';
        roles.add(role);
        
        OpportunityContactRole role2 = new OpportunityContactRole();
        role2.ContactId = contactTest[0].Id;
        role2.OpportunityId = dealerOpp[0].Id;
        role2.Role = 'Primary Contact';
        roles.add(role2);
        
        OpportunityContactRole role3 = new OpportunityContactRole();
        role3.ContactId = contactTest[1].Id;
        role3.OpportunityId = dealerOpp[1].Id;
        role3.Role = 'Dealer Primary Contact';
        roles.add(role3);
        
        OpportunityContactRole role4 = new OpportunityContactRole();
        role4.ContactId = contactTest[1].Id;
        role4.OpportunityId = dealerOpp[1].Id;
        role4.Role = 'Primary Contact';
        roles.add(role4);
        
        insert roles;
        
        Dealer__c dealer1 = new Dealer__c();
        
        dealer1.Opportunity__c = dealerOpp[1].Id;
        dealer1.Dealer__c = dealerList[2].Id;
        dealer1.Primary_Dealer__c = false;
        
        insert dealer1;
        Guarantor__c pg = new Guarantor__c(Contact__c = contactTest[0].Id, Opportunity__c = dealerOpp[1].Id);
        insert pg;
        
    }
    // redundant
    @isTest public static void gdsTest () {
        
        Test.setMock(HttpCalloutMock.class, new TC_GdsScoreApiCalloutMock ());
        
        Test.startTest();
        TC_GdsScoreApi.runGdsScore ([SELECT Id FROM Opportunity WHERE Name = 'testopp'][0].Id);
        Test.stopTest();
        
    }
    
    @isTest public static void gdsTestFromPb () {
        
        Test.setMock(HttpCalloutMock.class, new TC_GdsScoreApiCalloutMock ());
        
        Test.startTest();
        Id oppId = [SELECT Id FROM Opportunity WHERE Name = 'testopp'][0].Id;
        TC_GdsScoreCtrl.callGdsPb (new List <Id> {oppId});
        Webservice_Field__c wsf = new Webservice_Field__c(Opportunity__c=oppId);
        insert wsf;
        Test.setMock(HttpCalloutMock.class, new TC_DwhStoredProcedureFraudCalloutMock());
        TC_GdsScoreCtrl.callDwhStoredProcFraudQuery(oppId);
        Test.stopTest();
        
    }
    
    @isTest public static void gdsMarlinAppNetTest () {
        
        Test.setMock(HttpCalloutMock.class, new TC_GdsScoreApiCalloutMock ());
        
        Test.startTest();
        System.schedule('Job Started at ' + String.valueOf(Datetime.now()), CRON_EXP, new TC_GDSScoreMarlinNetAppSchd ());
        Test.stopTest();
        
    }
    
    @isTest public static void gdsTest1 () {
        Test.setMock(HttpCalloutMock.class, new TC_GdsScoreApiCalloutMock ());
        
        Test.startTest();
        TC_GdsScoreApi.runGdsScore ([SELECT Id FROM Opportunity WHERE Name = 'testopp1'][0].Id);
        Test.stopTest();      
    }
}