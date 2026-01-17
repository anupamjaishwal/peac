@isTest
public with sharing class TC_ValidateEmailageResultsTest {
    @TestSetup
    static void dataSetup(){

        Id devRecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Corporate').getRecordTypeId();
        Id devRecordTypeIdPersonal = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId();
        Account act = new Account ();
        act.name = 'Test1';
        act.BillingCity = 'Minneapolis';
        act.BillingCountryCode = 'US';
        act.BillingPostalCode = '55401';
        act.BillingStateCode = 'MN';
        act.BillingStreet = '411 Washington Ave N';
        act.Phone = '2225551234';
        act.Business_Phone__c = '2225551234';
        insert act;

        Opportunity opp = new Opportunity ();
        opp.accountId = act.Id;
        opp.amount = 1000;
        opp.name = 'Test Create Customer Opportunity 1';
        opp.StageName = 'Ready for Booking';
        Date today = Date.today ();
        opp.CloseDate = today;
        
        Test.startTest();
        
        insert opp;

        Contact contact = new Contact();
        contact.FirstName = 'Jeff';
        contact.LastName = 'Test';
        contact.SSN__c = '123456789';
        contact.MailingStateCode = 'NY';
        contact.MailingStreet = '123 Testing Avenue';
        contact.MailingCity = 'Rochester';
        contact.MailingCountryCode = 'US';
        contact.MailingPostalCode = '14625';
        contact.Title = 'CEO';
        contact.Email = 'jefftest@thiscompany.com';
        contact.AccountId = act.Id;
        //contact.Score__c = 792;

        insert contact;
        Guarantor__c cg = new Guarantor__c();
        cg.Contact__c = contact.Id;
        cg.Opportunity__c = opp.Id;
        cg.RecordTypeId = devRecordTypeIdPersonal;
        insert cg;

        Account createCustomerAccount = new Account();
        createCustomerAccount.Name = 'TestCustomerCreate1';
        createCustomerAccount.BillingCity = 'Minneapolis';
        createCustomerAccount.BillingCountryCode = 'US';
        createCustomerAccount.BillingPostalCode = '55401';
        createCustomerAccount.BillingStateCode = 'MN';
        createCustomerAccount.BillingStreet = '411 Washington Ave N';
        createCustomerAccount.Phone = '2225551234';
        createCustomerAccount.DBA__c = 'TestyTestDBA';
        //insert createCustomerAccount;
        Guarantor__c custg = new Guarantor__c();
        //custg.Account__r = createCustomerAccount;
        custg.Account__c = act.Id;
        custg.Opportunity__c = opp.Id;
        custg.RecordTypeId = devRecordTypeId;
        Test.stopTest();
        insert custg;


    }
    @IsTest
    public static void ValidateEmailageResultsTest(){

            List<Opportunity> opp = [SELECT Id, StageName,X_Rate_Factor__c, Equipment_Cost__c,Ready_to_Doc__c  FROM Opportunity];

            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Titling_Fee__c, Delivery_Guarantee_Fee__c, Wire_Fee__c, RecordTypeId, StageName, UPS_Fee__c FROM Opportunity]);
            Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Titling_Fee__c, Delivery_Guarantee_Fee__c, Wire_Fee__c, RecordTypeId, UPS_Fee__c, StageName FROM Opportunity]);

            Map<Id, Contact> primaryContacts = new Map<Id, Contact>();
            Map<Id, Guarantor__c> guarantors = new Map<Id, Guarantor__c>([SELECT Id, Contact__r.Emailage_Result__c, Contact__r.Override_Emailage_Result__c FROM Guarantor__c WHERE Opportunity__c = :opp[0].Id AND Type__c = 'Personal Guarantor' AND Contact__c != NULL]);
            for(Id key : newMap.keyset()){
                newMap.get(key).StageName = 'Booking';
                oldMap.get(key).StageName = 'Funding';
            }
    
            try{
                TC_ValidateEmailageResults.validateEmailageResults(oldMap,newMap, primaryContacts, guarantors);
                }
                catch (Exception e) {
                    System.debug(e.getMessage());
                }
    }
}