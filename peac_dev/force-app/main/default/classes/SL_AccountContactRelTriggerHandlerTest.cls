@IsTest

public with sharing class SL_AccountContactRelTriggerHandlerTest {

    @IsTest static void ACRtest() {

         // PermissionSet ps = new PermissionSet(Label = 'Dealer e-Automate Access', Name = 'Dealer_eAutomate_Access');
         // insert ps;
        
        Account a = new Account();
        a.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dealer_Vendor' LIMIT 1].Id;
        a.Name = 'Test Dealer';
        a.Business_Phone__c = '8888888888';
        a.Account_Dealer_Status__c = 'Pending';
        insert a;
        
        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        c.Title = 'test title';
        insert c;

        Contact c2 = new Contact();
        c2.FirstName = 'test2';
        c2.LastName = 'contact2';
        c2.AccountId = a.Id;
        c2.Title = 'test title2';
        insert c2;

        AccountContactRelation r = [SELECT Id FROM AccountContactRelation WHERE ContactId = :c.Id LIMIT 1];
        r.Roles = 'Eauto auto posting';
        update r;

        AccountContactRelation r2 = [SELECT Id FROM AccountContactRelation WHERE ContactId = :c2.Id LIMIT 1];
        r2.Roles = 'Primary Contact';
        update r2;
        
		r.Roles = null;
        update r;
    }
}