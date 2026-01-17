@IsTest
public with sharing class TC_ResubmissionToCreditDetailsTest {
    
    @TestSetup
    static void setup(){
        
        Account acc = new Account();
        acc.Name = 'test';
        acc.Business_Phone__c = '1111111111';
        acc.RecordTypeId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        acc.Business_Address__c = '123 Street Ave N';
        acc.Business_City__c = 'Minneapolis';
        acc.Business_State__c = 'MN';
        acc.Business_Zip__c = '55401';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = 'test';
        opp.CloseDate = System.today();
        opp.StageName = 'Decision';
        opp.Opportunity_Status__c = 'Credit - In Queue';
        opp.AccountId = acc.Id;
        opp.Equipment_Cost__c = 12345;
        opp.Equipment_Description__c = 'test';
        opp.Terms__c = 60;
        Test.startTest();
        insert opp;
        Test.stopTest();

        Resubmission_to_Credit_Details__c rcd = new Resubmission_to_Credit_Details__c();
        rcd.Opportunity__c = opp.Id;
        rcd.Appeal_Type__c = '1st';
        insert rcd;
        
        Resubmission_to_Credit_Details__c rcd1 = new Resubmission_to_Credit_Details__c();
        rcd1.Opportunity__c = opp.Id;
        rcd1.Appeal_Type__c = '2nd';
        insert rcd1;
    }

    @IsTest
    static void test() {

        Opportunity opp = [SELECT Id, Name, Credit_Decision__c FROM Opportunity WHERE Name = 'test'];
        opp.Credit_Decision__c = true;
        Test.startTest();
        update opp;
        Test.stopTest();
    }
}