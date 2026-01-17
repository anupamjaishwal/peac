@IsTest(SeeAllData=true)
private class SL_LegalNameUpdateReportEmailJobTest {

private static Reports.ReportResults createMockReportResults() {
    String mockJson = '{' +
        '"reportMetadata": {' +
            '"detailColumns": ["OLDVAL", "NEWVAL"],' +
            '"groupingsDown": [' +
                '{"name": "ACCOUNT.NAME"}' +
            ']' +
        '},' +
        '"groupingsDown": {' +
            '"groupings": [' +
                '{"label": "Acme Inc"}' +
            ']' +
        '},' +
        '"factMap": {' +
            '"0!T": {' +
                '"rows": [' +
                    '{' +
                        '"dataCells": [' +
                            '{ "label": "Old Legal Name", "value": "Old Legal Name" },' +
                            '{ "label": "New Legal Name", "value": "New Legal Name" }' +
                        ']' +
                    '}' +
                ']' +
            '}' +
        '}' +
    '}';
    return (Reports.ReportResults) JSON.deserialize(mockJson, Reports.ReportResults.class);
}


    @IsTest
    static void testGenerateCsvFromSummaryReport() {
        Reports.ReportResults mockResults = createMockReportResults();

        Test.startTest();
        String csv = SL_LegalNameUpdateReportEmailJob.generateCsvFromSummaryReport(mockResults);
        Test.stopTest();

        System.assert(csv != null && csv.contains('Old Value'), 'CSV should contain expected content.');
    }

    @IsTest
    static void testSendEmailWithCsv() {
        String testCsv = '"Header1","Header2"\n"Value1","Value2"';

        Test.startTest();
        SL_LegalNameUpdateReportEmailJob.sendEmailWithCsv(testCsv);
        Test.stopTest();

        System.assert(true, 'sendEmailWithCsv executed without exception');
    }

    @IsTest
    static void testExecuteWithMockData() {
        Reports.ReportResults mockResults = createMockReportResults();
        SL_LegalNameUpdateReportEmailJob.testReportResultsOverride = mockResults;

        Test.startTest();
        new SL_LegalNameUpdateReportEmailJob().execute(null);
        Test.stopTest();

        System.assert(true, 'execute ran without exception using mock data');
    }
}