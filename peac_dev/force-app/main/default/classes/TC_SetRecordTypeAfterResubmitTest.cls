@istest
public with sharing class TC_SetRecordTypeAfterResubmitTest {
    @TestSetup
    static void dataSetup(){
        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            StageName = 'Decision',
            Resubmitted_to_Credit__c = true,
            Credit_Decision__c = false,
            CloseDate = date.today()+100,
            RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId(),
            Name = 'test'
        );
        insert opp;
    }
    @IsTest
    public static void SetRecordTypeAfterResubmitTest(){
      
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Credit_Decision__c, record_type_name__c, Resubmitted_to_Credit__c, StageName, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Credit_Decision__c, record_type_name__c, Resubmitted_to_Credit__c, StageName, Loan_Record_Type__c FROM Opportunity]);

        for(Id key : newMap.keyset()){
            Opportunity o = [SELECT Id, Credit_Decision__c, record_type_name__c, Resubmitted_to_Credit__c, StageName, Loan_Record_Type__c FROM Opportunity where Id = : key];
            system.debug('TEST CLASS'+o);
        }

        TC_SetRecordTypeAfterResubmit.setRecordTypeAfterResubmit(oldMap, newMap);
    }

}