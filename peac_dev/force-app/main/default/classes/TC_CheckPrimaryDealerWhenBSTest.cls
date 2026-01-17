@isTest
public with sharing class TC_CheckPrimaryDealerWhenBSTest {
    @TestSetup
    static void dataSetup(){
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
            Name = 'test'
        );
        insert opp;
    }

    @IsTest
    public static void CheckPrimaryDealerWhenBSTest(){

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
        try{
            TC_CheckPrimaryDealerWhenBookingStage.checkPrimaryDealerWhenBookingStage(oldMap, newMap);
        }
        catch (DmlException e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
        catch (Exception e) {
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
        }
    }
}