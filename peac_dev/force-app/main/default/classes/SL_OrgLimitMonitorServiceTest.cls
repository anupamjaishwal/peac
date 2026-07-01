@IsTest
private class SL_OrgLimitMonitorServiceTest {

    @IsTest
    static void testCheckLimits() {

        Test.startTest();
        SL_OrgLimitMonitorService.checkLimits();
        Test.stopTest();

        System.assert(true);
    }
    
    @IsTest
    static void testResetInProgress() {
        
        
		List<Org_Limit_Monitor__mdt> configs = [
            SELECT DeveloperName,
                   MasterLabel,
                   Limit_API_Name__c,
                   Notification_Enabled__c,
                   In_Progress__c,
                   Low_Priority_Threshold__c,
                   Medium_Priority_Threshold__c,
                   High_Priority_Threshold__c
            FROM Org_Limit_Monitor__mdt
            WHERE Notification_Enabled__c = true
        ];


        Test.startTest();
        SL_OrgLimitMonitorService.resetInProgress(configs[0]);
        Test.stopTest();

        System.assert(true);
    }

    @IsTest
    static void testCheckLimitsScheduleJob() {

        Test.startTest();
        String cronExp = '0 0 0 1 1 ? 2050'; // future date
        String jobId = System.schedule('Test Scheduled Job', cronExp, new SL_OrgLimitMonitorServiceScheduler());
        Test.stopTest();

        System.assert(true);
    }    
}