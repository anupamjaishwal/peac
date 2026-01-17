@isTest
public with sharing class TC_LeaseFundingStageTest {
   @testSetup
   static void setup() {
       SL_SCTestData.prepareFundingOpportunity(false);
   }

   @isTest
   static void testFunding() {
        List<Opportunity> opps = [SELECT Id, Name, Account.Account_Billing_Street__c, StageName FROM Opportunity];
        User theAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND FirstName = 'Test Owner' LIMIT 1];
        User u = [SELECT Id FROM User WHERE Username = 'service.admin.test.user@silverlinecrm.com' AND Profile.Name = 'CMS'];
        List<Account> accounts = [SELECT Id, Name FROM Account];
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        Test.startTest();
        System.runAs(theAdmin){
           opps[2] = SL_SCTestData.setFieldValuesForFunding(opps[2], u, theAdmin);
           update opps[2];
       }
       Test.stopTest();
       List<Opportunity> oppsAfter = [SELECT StageName, Interim_Rent__c,
        (SELECT Payee__r.Payee_ID__c FROM Payments__r)
            FROM Opportunity];
       System.Assert.areEqual('Funding', oppsAfter[2].StageName);
       System.Assert.areEqual(1, oppsAfter[2].Payments__r.size(), 'must have generated a payment');
   }

   @isTest
   static void testFundingForXbs() {
        System.debug('testFundingForXbs');
        List<Opportunity> opps = [SELECT Id, Name, Account.Account_Billing_Street__c, StageName FROM Opportunity];
        User theAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND FirstName = 'Test Owner' LIMIT 1];
        User u = [SELECT Id FROM User WHERE Username = 'service.admin.test.user@silverlinecrm.com' AND Profile.Name = 'CMS'];
        List<Account> accounts = [SELECT Id, Name FROM Account];
        List<Contact> contacts = [SELECT Id, Name FROM Contact];
        Test.startTest();
        System.runAs(theAdmin){
           opps[2] = SL_SCTestData.setFieldValuesForFunding(opps[2], u, theAdmin);
           opps[2].Program__c = 'XBS';
           update opps[2];
       }
       Test.stopTest();
       List<Opportunity> oppsAfter = [SELECT StageName, Interim_Rent__c,
        (SELECT Payee__r.Payee_ID__c FROM Payments__r)
            FROM Opportunity];
       System.Assert.areEqual('Funding', oppsAfter[2].StageName);
       System.Assert.areEqual(0, oppsAfter[2].Payments__r.size(), 'will not generate payment because opp is an XBS one');// would need to also create the default xbs payee in test data when we have time
   }

   // old just kept for reference
//    @isTest
//    static void testDocsIn() {
//         List<Opportunity> opps = [SELECT Id, Name, Account.Account_Billing_Street__c, StageName FROM Opportunity];
//         User theAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND FirstName = 'Test Owner' LIMIT 1];
//         List<Account> accounts = [SELECT Id, Name FROM Account];
//         List<Contact> contacts = [SELECT Id, Name FROM Contact];
//         Payee__c payee = new Payee__c(Dealer__c =accounts[4].Id, Contact__c = contacts[4].Id, Payee_ID__c	= '111000005', 
//             Active__c = true, SL_Vendor_ID__c ='900-090-ASD', Payee_Name__c = 'Test Payee' );
//         insert payee;
//         // Payment__c p = new Payment__c(Opportunity__c = opps[2].Id, Payee__c = payee.Id);
//         Test.startTest();
//         System.runAs(theAdmin){
//            opps[2].StageName = 'Docs In';
//            opps[2].Opportunity_Status__c = 'Docs In - Pending review';
//            opps[2].Account_Billing_Street__c = opps[2].Account.Account_Billing_Street__c;
//            opps[2].Billing_Cycle__c = 'January;February';
//            opps[2].Booking_Sheet_Generated__c = true;
//            opps[2].Purchase_Options__c = 'FMV';
//            opps[2].Contract_Type__c = 'TL';
//            opps[2].Branch__c = 'Office Equip Group-OEG';
//            opps[2].Terms__c = 60;
           
//            update opps[2];
//        }
//        Test.stopTest();
//        List<Opportunity> oppsAfter = [SELECT StageName, Interim_Rent__c,
//         (SELECT Payee__r.Payee_ID__c FROM Payments__r)
//             FROM Opportunity];
//        System.Assert.areEqual('Funding', oppsAfter[2].StageName);
//        System.Assert.areEqual(1, oppsAfter[2].Payments__r.size(), 'must have generated a payment');
//    }
}