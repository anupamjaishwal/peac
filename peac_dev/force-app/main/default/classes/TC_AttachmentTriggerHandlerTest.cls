/** @author : Tamarack Consulting, Inc.
 * @date : 3/31/20
 * @description: 
 *
 */
@IsTest
public with sharing class TC_AttachmentTriggerHandlerTest {

    @TestSetup
    static void setup() {
        Account account = new Account(
                Name = 'TC_AttachmentTriggerHandlerTest',
                Business_City__c = 'Minneapolis',
                Business_State__c = 'MN',
                Business_Address__c = '701 N 3rd St',
                Business_Zip__c = '55401',
                Business_Type__c = 'Proprietorship'
        );
        insert account;
        System.assertNotEquals(null, account.Id);

        Opportunity opportunity = new Opportunity(
                Name = 'TC_AttachmentTriggerHandlerTest',
                StageName = 'Booking',
                CloseDate = Date.today(),
                Tax_ID__c = '123456789',
                Credit_Stips_Completed_Date__c = Date.today(),
                AccountId = account.Id
        );
        Test.startTest();
        insert opportunity;
        Test.stopTest();
        System.assertNotEquals(null, opportunity.Id);
    }

    @IsTest
    static void testConvertBookingSheet() {
        Opportunity opportunity = [SELECT Id FROM Opportunity WHERE Name = 'TC_AttachmentTriggerHandlerTest'];

        Attachment attachment = new Attachment(
                Name = 'Loan Booking Sheet',
                ParentId = opportunity.Id,
                Description = 'This is a booking sheet',
                Body = Blob.valueOf('Booking sheet')
        );
        insert attachment;
    }
}