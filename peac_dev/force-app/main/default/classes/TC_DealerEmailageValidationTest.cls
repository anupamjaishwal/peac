/**
 * Created by trohweder on 2/19/21.
 * Test for SAL-2233, TC_DealerEmailageValidation
 */
@IsTest
public with sharing class TC_DealerEmailageValidationTest {

    @TestSetup
    public static void createTestDealerAndContact(){

        //had to set because it calls out durring the testing process for dealers
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
        a.Account_Dealer_Status__c = 'Pending';
        a.Business_Phone__c = '8888888888';
        insert a;

        Contact c = new Contact();
        c.FirstName = 'test';
        c.LastName = 'contact';
        c.Emailage_Result__c = 'FAIL';
        c.AccountId = a.Id;
        insert c;

        AccountContactRelation r = [SELECT Id FROM AccountContactRelation WHERE ContactId = :c.Id LIMIT 1];
        r.Roles = 'Primary Contact';
        update r;
    }

    @IsTest
    public static void testErrorGetsThrown(){

        Test.setMock(HttpCalloutMock.class, new TC_BWDealerCalloutMockImpl ());

        Test.startTest();

        Account a = [SELECT Id, Account_Dealer_Status__c FROM Account WHERE Name = 'Test Dealer' LIMIT 1];

        a.Account_Dealer_Status__c = 'Active';

        update a;

        Test.stopTest();

    }


}