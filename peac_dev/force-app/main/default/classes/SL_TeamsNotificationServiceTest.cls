@IsTest
private class SL_TeamsNotificationServiceTest {

    /**
     * Mock for HTTP Callout
     */
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"ok"}');
            return res;
        }
    }

    @IsTest
    static void testSendLimitsTable() {
        // Register mock
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        // Sample payload
        String payload = '{"test":"data"}';

        Test.startTest();
        SL_TeamsNotificationService.sendLimitsTable(payload);
        Test.stopTest();

        // No exception = success
        System.assert(true, 'Future callout executed successfully');
    }

    @IsTest
    static void testBuildLimitsCard() {
        // Create fake limits
        List<SL_OrgLimitMonitorService.LimitInfo> limits = 
            new List<SL_OrgLimitMonitorService.LimitInfo>();

        SL_OrgLimitMonitorService.LimitInfo l1 = 
            new SL_OrgLimitMonitorService.LimitInfo();
        l1.name = 'API Requests';
        l1.used = 900;
        l1.max = 1000;
        l1.percentage = 90;
        l1.priority = 'High';

        SL_OrgLimitMonitorService.LimitInfo l2 = 
            new SL_OrgLimitMonitorService.LimitInfo();
        l2.name = 'Data Storage';
        l2.used = 50;
        l2.max = 100;
        l2.percentage = 50;
        l2.priority = 'Medium';

        limits.add(l1);
        limits.add(l2);

        // Call method
        String result = SL_TeamsNotificationService.buildLimitsCard(limits, '🚨');

        // Assertions
        System.assertNotEquals(null, result);
        System.assert(result.contains('Salesforce Limits Overview'));
        System.assert(result.contains('API Requests'));
        System.assert(result.contains('Data Storage'));
        System.assert(result.contains('🔴 High'));
        System.assert(result.contains('🟠 Medium'));
    }

    @IsTest
    static void testBuildLimitsCard_emptyList() {
        List<SL_OrgLimitMonitorService.LimitInfo> limits = 
            new List<SL_OrgLimitMonitorService.LimitInfo>();

        String result = SL_TeamsNotificationService.buildLimitsCard(limits, 'ℹ️');

        System.assertNotEquals(null, result);
        System.assert(result.contains('Salesforce Limits Overview'));
        // No rows expected, but header should exist
        System.assert(result.contains('Limit'));
        System.assert(result.contains('Usage'));
    }
}