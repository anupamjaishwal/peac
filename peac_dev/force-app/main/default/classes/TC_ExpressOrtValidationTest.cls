@isTest
public with sharing class TC_ExpressOrtValidationTest {
    @TestSetup
    static void makeData(){
        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;
        
        Account acc = new Account();
        acc.Name = 'Test';
        acc.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'End User Account'][0].Id;
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.Id;
        opp.StageName = 'Decision';
        opp.CloseDate = Date.today().addDays(7);
        opp.Primary_Source__c = 'Customer Inbound - Call';
        opp.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Express Decision'][0].Id;
        
        Test.startTest();
        insert opp;
        Test.stopTest();
    }

    @isTest public static void ExpressOrtValidationTest1(){
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Equipment_Cost__c, Opportunity_Funding_Type__c, PUT_Amount__c, Beginning_Maintenance_Fee_Amount__c, Sales_Leaseback__c, Escalation_Rate__c,Num_Pass_Thru_Fees__c,First_12_Months_Free__c,RecordTypeId, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);

        for(Id key : newMap.keyset()){
            newMap.get(key).Escalation_Rate__c = 30;
            newMap.get(key).First_12_Months_Free__c = true;
            newMap.get(key).Num_Pass_Thru_Fees__c = 100;
            newMap.get(key).Sales_Leaseback__c = true;
            newMap.get(key).Beginning_Maintenance_Fee_Amount__c = 100;
            newMap.get(key).PUT_Amount__c = 1000;
            newMap.get(key).Equipment_Cost__c = 1000;
            newMap.get(key).Opportunity_Funding_Type__c = 'Delivery Guarantee';
        }

        Test.startTest();
        System.Database.update(newMap.values(), false);
        Test.stopTest();
    }
}