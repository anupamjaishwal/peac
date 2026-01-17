@isTest
public with sharing class TC_ValidateEmailsForFundingTest {
   
    @TestSetup
    static void dataSetup(){
        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Account dealer = new Account(
            Name = 'dealer',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId()
        );
        insert dealer;
        
        Contact c = new Contact (
            AccountId = acc.Id, 
            FirstName = 'test', 
            LastName = 'contact', 
            MailingStreet = 'test', 
            MailingCity = 'test', 
            MailingStateCode = 'MN', 
            MailingPostalCode = '11111', 
            MailingCountry='United States', 
            Phone='5555555555',
            Title = 'title', 
            SSN__c = '111111111', 
            BirthDate = Date.today (), 
            Email = 'test123@test.com'
        );
        insert c;

        Contact dc = new Contact (
            AccountId = dealer.Id, 
            FirstName = 'dealer test', 
            LastName = 'dealer contact', 
            MailingStreet = 'dealer test', 
            MailingCity = 'dealer test', 
            MailingStateCode = 'MN', 
            MailingPostalCode = '11190', 
            MailingCountry='United States', 
            Phone='1234555555',
            Title = 'Mr', 
            SSN__c = '156431111', 
            BirthDate = Date.today () - 365, 
            Email = 'testdealer123@test.com'
        );
        insert dc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            StageName = 'test',
            CloseDate = date.today () + 10,
            Name = 'test'
        );
        Test.startTest();
        insert opp;
        Test.stopTest();
        Dealer__c d = new Dealer__c(Opportunity__c = opp.Id, Dealer__c = dealer.Id, Primary_Dealer__c = false);
        insert d;
    }

    @IsTest
    public static void validateEmailsForFundingTest(){
        Opportunity opp = [SELECT Id, Branch__c, Docs_In__c, Ready_to_Doc__c, Loan_Record_Type__c FROM Opportunity LIMIT 1];
        Contact c =  [SELECT Id FROM Contact WHERE Email = 'test123@test.com' LIMIT 1];
        Contact dc =  [SELECT Id FROM Contact WHERE Email = 'testdealer123@test.com' LIMIT 1];

        OpportunityContactRole ocr = new OpportunityContactRole(ContactId = c.Id, OpportunityId = opp.Id, role = 'Primary Contact') ;
        insert ocr;
        OpportunityContactRole odcr = new OpportunityContactRole(ContactId = dc.Id, OpportunityId = opp.Id, role = 'Dealer Primary Contact') ;
        insert odcr;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Branch__c, Docs_In__c, Ready_to_Doc__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Branch__c = oldMap.get(key).Branch__c,
                Docs_In__c = Date.Today(),
                Ready_to_Doc__c = 'Yes');
            newMap.put(key, o);
        }

        TC_ValidateEmailsForFunding.validateEmailsForFunding(oldMap, newMap);
    }

    @IsTest
    public static void validateEmailsForFundingTest_WithoutRoles(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Branch__c, Docs_In__c, Ready_to_Doc__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Branch__c = oldMap.get(key).Branch__c,
                Docs_In__c = Date.Today(),
                Ready_to_Doc__c = 'Yes');
            newMap.put(key, o);
        }

        TC_ValidateEmailsForFunding.validateEmailsForFunding(oldMap, newMap);
    }

}