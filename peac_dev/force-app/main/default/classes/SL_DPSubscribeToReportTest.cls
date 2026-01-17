@isTest
public with sharing class SL_DPSubscribeToReportTest {
    @isTest
    public static void saveSubscriptions() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        User testUser = SL_SCTestData.testUser;
        Subscribable_Report__mdt anyReport = [SELECT Id, Label, DeveloperName, Report__c, Email_Template__c
            FROM Subscribable_Report__mdt LIMIT 1];
        // Report theActualReport = [SELECT Id, Name, DeveloperName
           // FROM Report WHERE DeveloperName = :anyReport.Report__c LIMIT 1];
        String result1, result2;
        User dpUser = SL_SCTestData.createDPUser(SL_SCTestData.testAccounts[0].Id);
        insert new Report_Subscription__c(Report__c = 'theActualReport.Id', User__c = testUser.Id, 
            Url__c = 'https://fake.url/report/', Frequency__c = 'Daily');
        insert new Report_Subscription__c(Report__c = 'fakeId', User__c = testUser.Id, 
            Url__c = 'https://fake.url/report/', Frequency__c = 'Daily');
        system.debug('dpUser: ' + dpUser);
        List<Report_Subscription__c> testSubscriptions = [SELECT Id, User__c, Report__c FROM Report_Subscription__c LIMIT 2];
        Test.startTest();
        System.runAs(testUser){
            result1 = SL_DPSubscribeToReport.hubExecute('saveSubscriptions', new List<String>{'Service_Passthrough_Ungrouped_Sample_0pH',
            '["' + testUser.Id + '"]', 'Weekly', 'Thursday', '14'});
            result2 = SL_DPSubscribeToReport.hubExecute('getSubscriptionData', new List<String>());
        }
        Test.stopTest();
        System.Assert.areNotEqual('', result1);
        System.Assert.areNotEqual('', result2);
    }
}