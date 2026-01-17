@isTest
public with sharing class TC_CreateApprovedOffersTest {
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
            StageName = 'Proposal',
            CloseDate = date.today () + 10,
            Name = 'test',
            Lessor__c = 422,
            Equipment_Cost__c = 100,
            Payment_Frequency__c = 'Monthly',
            Advance_Rental_Amount__c = 100,
            Required_Adv_Payments__c = 0,
            First_Payment_Amount__c = 100,
            Payment_Amount__c = 400,
            Variable_Payment__c = false,
            Payments_In_Arrears__c = false,
            First_Payment_Date__c = date.today()-50,
            Commencement_Date__c = date.today()-30
        );
        insert opp;
    }

    @IsTest
    public static void CreateApprovedOffersTest(){
      
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Purchase_Options__c, Equipment_Cost__c, StageName,Credit_Risk_Grade__c,Payment_Frequency__c, Advance_Rental_Amount__c, Required_Adv_Payments__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                StageName = 'Proposal',
                Lessor__c = 422,
                Equipment_Cost__c = 400,
                Required_Adv_Payments__c = 100,
                First_Payment_Amount__c = 200,
                Payment_Amount__c = 500,
                Variable_Payment__c = true,
                Payments_In_Arrears__c = true,
                First_Payment_Date__c = date.today()-30,
                Commencement_Date__c = date.today()-20,
                Payment_Frequency__c = 'Annually',
            	Deferral_Payments__c = '30 days');
            newMap.put(key, o);
        }

        TC_CreateApprovedOffers.createApprovedOffers(oldMap, newMap.values());
        UPDATE newMap.values();
       
    }
}