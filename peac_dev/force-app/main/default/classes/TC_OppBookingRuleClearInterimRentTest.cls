@isTest
public with sharing class TC_OppBookingRuleClearInterimRentTest {
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
            Name = 'test',
            Payment_Frequency__c = 'Monthly',
            Advance_Rental_Amount__c = 100,
            Required_Adv_Payments__c = 0,
            First_Payment_Amount__c = 100,
            Payment_Amount__c = 400,
            Variable_Payment__c = false,
            Payments_In_Arrears__c = false,
            First_Payment_Date__c = date.today()-50,
            Commencement_Date__c = date.today()-30,
            Waive_Interim_Rent__c = true
        );
        insert opp;
    }

    @IsTest
    public static void Test1(){
      
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Payment_Frequency__c, Advance_Rental_Amount__c, 
            Required_Adv_Payments__c, Loan_Record_Type__c, Payment_Amount_w_o_Tax__c FROM Opportunity]);
        oldMap.values()[0].Waive_Interim_Rent__c = true;
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Advance_Rental_Amount__c = 0,
                Required_Adv_Payments__c = 100,
                First_Payment_Amount__c = 200,
                Payment_Amount__c = 500,
                Variable_Payment__c = true,
                Payments_In_Arrears__c = true,
                First_Payment_Date__c = date.today()-30,
                Commencement_Date__c = date.today()-20,
                Payment_Frequency__c = 'Annually',
                Waive_Interim_Rent__c = false,
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('CVG Quote').getRecordTypeId());
            newMap.put(key, o);
        }
        Test.startTest();
        update newMap.values();
        Test.stopTest();

    }

    @IsTest
    public static void Test2(){
        // Opportunity opp = [SELECT Id, Payment_Frequency__c, Advance_Rental_Amount__c, Required_Adv_Payments__c, Loan_Record_Type__c FROM Opportunity];
        // opp.Payment_Frequency__c = 'Variable';
        // update opp;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Payment_Frequency__c, Advance_Rental_Amount__c, 
            Required_Adv_Payments__c, Loan_Record_Type__c, Payment_Amount_w_o_Tax__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                First_Payment_Date__c = date.today()-10,
                Required_Adv_Payments__c = 10,
                First_Payment_Amount__c = 50,
                Variable_Payment__c = true,
                Payments_In_Arrears__c = false,
                of_beginning_payments__c = 1,
                of_ending_payments__c = 1,
                Commencement_Date__c = date.today()-9,
                Payment_Frequency__c = 'Monthly');
            newMap.put(key, o);
        }

        TC_OppBookingRuleClearInterimRent.doAction(oldMap, newMap);
    }

}