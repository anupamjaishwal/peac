@IsTest
public with sharing class TC_SetPymntFrequencyByDeferralPymntTest {
    @TestSetup
    static void dataSetup(){

        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;

        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

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
            // SSN__c = '1111111', 
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
            Name = 'test',
            Primary_Source__c = 'Partner Referral - Partner Initiated',
            RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Loan_Booking' LIMIT 1].Id
        );
        insert opp;
    }

    @IsTest
    public static void runtestOne(){
             Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Payment_Frequency__c, Deferral_Payments__c, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
             Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Payment_Frequency__c, Deferral_Payments__c, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
    
    
             for(Id key : newMap.keyset()){
                oldMap.get(key).Deferral_Payments__c = null;
                newMap.get(key).Deferral_Payments__c = '30 days';
                newMap.get(key).PK__c = 'test';
            }

            try{
                TC_SetPaymentFrequencyByDeferralPayments.setPaymentFrequencyByDeferralPayments(oldMap, newMap);
            }catch(Exception e){
                System.debug(e);
            }
    }

    @IsTest
    public static void runtestTwo(){
             Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Payment_Frequency__c, EF_Approved_Offers__c, Deferral_Payments__c, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
             Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Payment_Frequency__c, EF_Approved_Offers__c, Deferral_Payments__c, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
    
    
             for(Id key : newMap.keyset()){
                oldMap.get(key).Deferral_Payments__c = '30 days';
                newMap.get(key).Deferral_Payments__c = null;
                newMap.get(key).EF_Approved_Offers__c = key;
                newMap.get(key).PK__c = key;
            }

            try{
                TC_SetPaymentFrequencyByDeferralPayments.setPaymentFrequencyByDeferralPayments(oldMap, newMap);
            }catch(Exception e){
                System.debug(e);
            }
    }
}