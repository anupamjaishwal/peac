/**
 * Created by trohweder on 2/22/21.
 * Test for SAL-2221, TC_DealerPrimaryContactValidation
 */

@IsTest
public with sharing class TC_DealerPrimaryContactValidationTest {

    @TestSetup
    public static void createTestDealerAndContact(){

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
        a.RecordType = [SELECT Id FROM RecordType WHERE Name = 'Dealer Account' LIMIT 1];
        a.Name = 'Test Dealer';
        a.Business_Phone__c = '8888888888';
        insert a;

        Account a2 = new Account();
        a2.RecordType = [SELECT Id FROM RecordType WHERE Name = 'Dealer Account' LIMIT 1];
        a2.Name = 'Test Dealer2';
        a2.Business_Phone__c = '8888888899';
        a2.Review_For__c = 'Approval';
        insert a2;

        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.AccountId = a.Id;
        insert c;

        AccountContactRelation r = [SELECT Id FROM AccountContactRelation WHERE ContactId = :c.Id LIMIT 1];
        r.Roles = 'Primary Contact';
        System.debug('AccountContactRelation ' + r);
        update r;
    }

    @IsTest
    public static void testNoPrimaryContact(){

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());

        Account a = [SELECT Id, DM_Review_Status__c FROM Account WHERE Name = 'Test Dealer2' LIMIT 1];

        a.DM_Review_Status__c = 'Submitted for Review';

        update a;

        Test.stopTest();
    }

    @IsTest
    public static void testNoPrimaryContactWithEmail(){

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());

        Account a = [SELECT Id, DM_Review_Status__c FROM Account WHERE Name = 'Test Dealer' LIMIT 1];

        a.DM_Review_Status__c = 'Appealed';

        update a;

        Test.stopTest();
    }

    @IsTest
    public static void testNoPrimaryContactWithValidEmail(){

        Test.startTest();

        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());

        Contact c = [SELECT Id, Email, Validity_Verify__Status__c FROM Contact WHERE LastName='Contact' LIMIT 1];

        c.Validity_Verify__Status__c = 'Invalid';
        c.Email = 'test@testing.com';

        update c;

        Account a = [SELECT Id, DM_Review_Status__c FROM Account WHERE Name = 'Test Dealer' LIMIT 1];

        a.DM_Review_Status__c = 'Appealed';

        update a;

        Test.stopTest();

    }

}