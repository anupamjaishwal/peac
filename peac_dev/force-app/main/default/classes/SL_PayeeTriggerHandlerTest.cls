@isTest
public with sharing class SL_PayeeTriggerHandlerTest {
    @TestSetup
    static void makeData(){
        SL_SCTestData.createAccountAndContracts(2, 0);
    }

    @IsTest
    static void insertPayee(){
        List<Account> dealers = [SELECT Id FROM Account ORDER BY Name DESC];
        Test.startTest();
            Payee__c payee = new Payee__c (Dealer__c = dealers[0].Id, Address1__c = 'test', City__c = 'test', State__c = 'MN', Zip__c = '11111', Email__c = 'test@test.com', SL_Vendor_ID__c = 'test');
            insert payee;        
        Test.stopTest();
    }

        @IsTest
    static void updatePayee(){
        List<Account> dealers = [SELECT Id FROM Account ORDER BY Name DESC];

        Payee__c payee = new Payee__c (Dealer__c = dealers[0].Id, Address1__c = 'test', City__c = 'test', State__c = 'MN', Zip__c = '11111', Email__c = 'test@test.com', SL_Vendor_ID__c = 'test');
        insert payee;   

        Test.startTest();
        payee.Dealer__c = dealers[1].Id;
        update payee;
        Test.stopTest();
    }
}