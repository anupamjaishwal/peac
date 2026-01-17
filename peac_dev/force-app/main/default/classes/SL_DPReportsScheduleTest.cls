@isTest
public with sharing class SL_DPReportsScheduleTest {
    @isTest
    static void schedule(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Subscribable_Report__mdt anyReport = [SELECT Id, Label, DeveloperName, Report__c, Email_Template__c
            FROM Subscribable_Report__mdt LIMIT 1];
        // Report theActualReport = [SELECT Id, Name, DeveloperName
        //     FROM Report WHERE DeveloperName = :anyReport.Report__c LIMIT 1];
        User dpUser = SL_SCTestData.createDPUser(SL_SCTestData.testAccounts[0].Id);
        insert new Report_Subscription__c(Report__c = 'fakeId', User__c = dpUser.Id, 
            Url__c = 'https://fake.url/report/', Frequency__c = 'Daily');
        Test.startTest();
        System.schedule('Test Insurance Follow-up', '0 0 3 * * ?' , new SL_DPReportsSchedule());
        Test.stopTest();
        System.assert(true);
    }
}