/**
 * Created by trohweder on 2/26/21.
 * Test Coverage for SAL-2224 TC_SetPrimaryContactEmailString
 */

@IsTest
public with sharing class TC_SetPrimaryContactEmailStringTest {

    @TestSetup
    public static void createTestData(){

        //had to set because it calls out during the testing process for dealers
        Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c ();
        setting.Enable_Debug_Log__c = true;
        setting.Mock_Callout__c = true;
        setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
        setting.SetupOwnerId = UserInfo.getOrganizationId ();
        setting.Config_Name__c = 'TEST';
        setting.Mock_Callout_createCustomer__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
        insert setting;

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
        r.Roles = 'Primary Contact;Eauto auto posting';
        update r;

        AccountContactRelation r2 = [SELECT Id FROM AccountContactRelation WHERE ContactId = :c2.Id LIMIT 1];
        r2.Roles = 'Primary Contact';
        update r2;
    }

    @IsTest
    public static void testFieldGettingSet(){

        Test.startTest();

        Account a = [SELECT Id, Rejected_Reason__c FROM Account WHERE Name='Test Dealer'];

        a.Rejected_Reason__c = 'Auto-Rejected';

        update a;

        Account fieldCheck = [SELECT Id, Approved_Reason__c, Dealer_Primary_Contact_Email_String__c FROM Account WHERE Name='Test Dealer'];

        String expectedResult = 'Dealer Primary Contact Name: test contact, Dealer Primary Contact Title: test title\nDealer Primary Contact Name: test2 contact2, Dealer Primary Contact Title: test title2';

        System.assertEquals(expectedResult, fieldCheck.Dealer_Primary_Contact_Email_String__c);
    }


}