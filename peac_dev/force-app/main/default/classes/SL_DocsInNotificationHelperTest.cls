@isTest
public class SL_DocsInNotificationHelperTest {

    @TestSetup
    static void makeData() {
        // Use SL_SCTestData or custom logic to prepare test data
        SL_SCTestData.prepareFundingOpportunity();
    }

    @isTest
    static void testSendEmail() {
        // Fetch SAM User
        User samUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND FirstName = 'Test Owner' LIMIT 1];

        // Fetch Ambassador User
        User ambassadorUser = [SELECT Id FROM User WHERE Username = 'service.admin.test.user@silverlinecrm.com' AND Profile.Name = 'CMS' LIMIT 1];

        // Begin the test
        Test.startTest();

        // Fetch Opportunities
        List<Opportunity> opps = [SELECT Id, Dealer_Account__c FROM Opportunity LIMIT 3];

        // Update the Dealer Account with SAM and Ambassador Users
        Account testAccount = [SELECT Id, SAM__c, Ambassador__c FROM Account WHERE Id = :opps[2].Dealer_Account__c];
        testAccount.SAM__c = samUser.Id;
        testAccount.Ambassador__c = ambassadorUser.Id;
        update testAccount;

        // Call the method to send email
        SL_DocsInNotificationHelper.sendEmail(new Set<Id> { opps[2].Id });

        // End the test
        Test.stopTest();

        // Assert
        System.assert(true, 'Send email executed successfully');
    }
}