@isTest
public with sharing class TC_CheckGuarantorSSNsWhenBSTest {
    @TestSetup
    static void dataSetup(){
        Marlin_Configuration__c config = new Marlin_Configuration__c(Apex_Validations_Active__c = true);
        insert config;
        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;
        Account dealer = new Account(Name = 'test dealer 1', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId());
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

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Resubmitted_to_Credit__c = true,
            Credit_Decision__c = false,
            CloseDate = date.today()+100,
            Probability = 80,
            Deferral_Payments__c = '30 days',
            StageName = 'test',
            Name = 'test'
        );
        insert opp;

        Guarantor__c g = new Guarantor__c (Contact__c = c.Id, 
                                           Account__c = acc.Id, 
                                           Opportunity__c = opp.Id,
                                           RecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId()
                                           );
        insert g;
        List<Dealer__c> dealers = new List<Dealer__c>{
            new Dealer__c(Opportunity__c = opp.Id, Primary_Dealer__c = true, Dealer__c = dealer.Id)
        };
        insert dealers;
    }

    @IsTest
    public static void CheckGuarantorSSNsWhenBSTest(){

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, StageName, Deferral_Payments__c, Deferral_Periods__c, EF_Approved_Offers__c, Required_Adv_Payments__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Deferral_Payments__c = '60 days',
                StageName = 'Booking'
                );
            newMap.put(key, o);
        }
        Test.startTest();
        List<Database.SaveResult> oppResults = Database.update(newMap.values(), false);
        Test.stopTest();
        System.assert(oppResults[0].getErrors()[0]?.getMessage().contains('SSN can\'t be less than 9 digits when stage is changed to Booking'));
    }
}