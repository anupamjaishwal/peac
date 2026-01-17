@IsTest
public with sharing class TC_OpportunityCustomerTypeDefaultTest {
    
    @TestSetup
    static void setup() {

        Account acc = new Account();
        acc.Name = 'Test';
        acc.Business_Phone__c = '1111111111';
        insert acc;
    }

    @IsTest
    static void testInsert() {

        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test'];

        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Quote';
        opp.CloseDate = System.today() + 5;
        opp.AccountId = acc.Id;
        opp.Portal_User_Id__c = 'B2B-';
        insert opp;

        String customerType = [SELECT Id, CustomerType__c FROM Opportunity LIMIT 1][0].CustomerType__c;
        System.debug('Customer Type: ' + customerType);
    }

    @IsTest
    static void testUpdate() {

        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'Test'];

        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.StageName = 'Quote';
        opp.CloseDate = System.today() + 5;
        opp.AccountId = acc.Id;
        insert opp;

        Test.startTest();
        opp.Portal_User_Id__c = 'B2B-';
        update opp;
        Test.stopTest();

        String customerType = [SELECT Id, CustomerType__c FROM Opportunity LIMIT 1][0].CustomerType__c;
        System.debug('Customer Type: ' + customerType);
    }
}