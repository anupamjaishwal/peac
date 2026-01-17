@isTest private class TC_LeadConversionAutoBatchSchdTest {
    private static String CRON_EXP = '0 5 0 * * ? 2023';

    @testSetup static void setupData () {
        TC_LeadTestHelper.insertLead ();
        TC_LeadTestHelper.insertDupeAccountContact ();
    }

    static testmethod void autoLeadConversionTest () {
/*
        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('LeadMappingMockTest');
        mock.setStatusCode(200);
        mock.setHeader('Content-Type', 'text/xml');
        mock.setHeader('SOAPAction', 'test');*/

        Lead l = [Select Id FROM Lead WHERE Company = 'CompanyBatchTest'][0];

        Test.setCreatedDate(l.Id, Datetime.NOW().addMinutes(-100));
        //Test.setMock(HttpCalloutMock.class, mock);
        Test.startTest();
        TC_LeadConversionAutoBatchSchd s = new TC_LeadConversionAutoBatchSchd ();
        System.schedule('Job Started At ' + String.valueOf(Datetime.now()), CRON_EXP, s);
		TC_LeadConversionAutoBatch.Pair pair = new TC_LeadConversionAutoBatch.Pair ('test','test');
        
        Test.stopTest();
    }
}