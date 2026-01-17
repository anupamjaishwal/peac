/**
 * Created by jhber on 3/6/2019.
 */

@isTest
public with sharing class TC_BWcreateDealerTest {

    @TestSetup static void setup () {
        SL_SCTestData.createBridgeWareSetting();
        Account act = new Account ();
        act.name = 'TestDealer1';
        act.BillingCity = 'Minneapolis';
        act.BillingCountryCode = 'US';
        act.BillingPostalCode = '55401';
        act.BillingStateCode = 'MN';
        act.BillingStreet = '411 Washington Ave N';
        act.Phone = '2225551234';
        act.Business_Phone__c = '5854121234';
        insert act;

        Contact contact = new Contact();
        contact.FirstName = 'Jeff';
        contact.LastName = 'Test';
        contact.SSN__c = '123456789';
        contact.MailingStateCode = 'NY';
        contact.MailingStreet = '123 Testing Avenue';
        contact.MailingCity = 'Rochester';
        contact.MailingCountryCode = 'US';
        contact.MailingPostalCode = '14625';
        contact.Title = 'CEO';
        contact.Email = 'jefftest@thiscompany.com';
        contact.AccountId = act.Id;
        //contact.Score__c = 792;

        insert contact;
    }

    @isTest
    static void testCreateDealer() {

        Account account = [SELECT Id, Name FROM Account LIMIT 1];

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_BWcreateDealerCalloutMockImpl ());
        TC_BWcreateDealerCtrl.createDealer(account.Id);
        Test.stopTest ();
    }
}