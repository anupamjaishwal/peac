/** @author : Northteq Consulting, Inc.
 * @date : 11/11/20
 * @description: Created as a replacement for the testSetApprovalMergeFields test in TC_OpportunityTriggerHelperTest
 *
 */
@IsTest
public with sharing class TC_TestSetApprovalMergeFields {

    @TestSetup
    static void setup() {
        Account account = new Account(Name = 'test account', Business_Phone__c = '1234567890');
        insert account;

        Contact contact = new Contact(
                FirstName = 'Joe',
                LastName = 'Smith',
                AccountId = account.Id,
                MailingStreet = '701 N 3rd St',
                MailingCity = 'Minneapolis',
                MailingState = 'Minnesota',
                MailingPostalCode = '55401',
                SSN__c = '666000000',
                Email = 'sfdc@northteq.com'
        );
        insert contact;

        Opportunity opportunity = new Opportunity(
        AccountId = account.Id,
        Name = 'testSetApprovalMergeFields',
        StageName = 'Decision',
        CloseDate = Date.today(),
        Application__c = '12345'
        );
        Test.startTest();
        insert opportunity;
        Test.stopTest();
    }

    @IsTest
    static void test() {

        Contact contact = [SELECT Id FROM Contact WHERE FirstName = 'Joe'];
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Name = 'testSetApprovalMergeFields'];

        Guarantor__c guarantor = new Guarantor__c(
        Opportunity__c = opportunity.Id,
        Contact__c = contact.Id
        );
        insert guarantor;

        opportunity.Application_Status__c = 'Automatically Approved';
        Test.startTest();
        update opportunity;
        Test.stopTest();
    }
}