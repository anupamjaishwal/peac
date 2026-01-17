@isTest
private class TC_LeadConversionAutoBatchTest {
    
    private static String CRON_EXP = '0 5 0 * * ? 2023';
    
    @testSetup static void setupData () {
        TC_LeadTestHelper.insertLead ();
    }
    
    static testmethod void test () {
    
        Lead l = [Select Id FROM Lead WHERE Company = 'CompanyBatchTest'][0];
        Test.setCreatedDate(l.Id, Datetime.NOW().addMinutes(-100));
        
        Test.startTest();
        TC_LeadConversionAutoBatchSchd s = new TC_LeadConversionAutoBatchSchd ();
        System.schedule('Job Started At ' + String.valueOf(Datetime.now()), CRON_EXP, s);
        
        Test.stopTest();
    }
}