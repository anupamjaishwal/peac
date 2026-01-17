@isTest
public with sharing class TC_EmailUtilTest {
    @TestSetup
    static void makeData(){
        Account acc = new Account();
        acc.Name = 'testacc';
        acc.Business_Phone__c = '1111111111';
        insert acc;
    }

    @IsTest
    static void testApproved() {
        Test.startTest();

        try {
            List<Messaging.SendEmailResult> sentCustomerVerifyEmail = TC_EmailUtil.sendEmailNotification(new List<String>{'test@test.com'}, null, null, null, 'subject', 'body', null, null, null);

        } catch (Exception e) {
            System.debug(e.getStackTraceString());
            System.debug(e.getMessage());
        }

        Test.stopTest();
    }
}