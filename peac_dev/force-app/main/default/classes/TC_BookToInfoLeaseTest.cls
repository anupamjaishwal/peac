@isTest
public with sharing class TC_BookToInfoLeaseTest {
    @TestSetup
    static void dataSetup(){
        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Resubmitted_to_Credit__c = true,
            Credit_Decision__c = false,
            CloseDate = date.today()+100,
            Probability = 80,
            Deferral_Payments__c = '30 days',
            StageName = 'test',
            Auto_Book_to_InfoLease__c = true,
            Name = 'test'
        );
        insert opp;
    }

    @IsTest
    public static void BookToInfoLeaseTest(){

        Opportunity opp = [SELECT Id, StageName, Auto_Book_to_InfoLease__c, EF_Approved_Offers__c, Required_Adv_Payments__c, Loan_Record_Type__c FROM Opportunity];
       
        try{
            TC_BookToInfoLease.bookToInfoLease(new List<Opportunity>{opp});
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