global with sharing class SL_LegalNameUpdateReportEmailJob implements Schedulable {

    private static Map<String, String> apiNameToLabelMap = new Map<String, String>{
        'ACCOUNT.NAME'       => 'Account Name',
        'CREATED'            => 'Edited By',
        'CREATED_DATE'       => 'Edit Date',
        'FIELD_KEY'          => 'Field / Event',
        'OLDVAL'             => 'Old Value',
        'NEWVAL'             => 'New Value',
        'ACCOUNT_OWNER'      => 'Account Owner',
        'ACCOUNT.CCAN__C'    => 'CCAN'
    };

    @TestVisible
    private static Reports.ReportResults testReportResultsOverride;

    global void execute(SchedulableContext sc) {
        try {
            Reports.ReportResults results;


                Report report = [SELECT Id FROM Report WHERE DeveloperName = 'Legal_Name_Updates_made_by_Credit' LIMIT 1];
                results = Reports.ReportManager.runReport(report.Id, true);
            

            String csvData = generateCsvFromSummaryReport(results);

            // Uncomment in production
            sendEmailWithCsv(csvData);

        } catch (Exception e) {
            System.debug('Error generating or sending report: ' + e.getMessage());
        }
    }

    @TestVisible
    private static String generateCsvFromSummaryReport(Reports.ReportResults results) {
        String csv = '';

        List<Reports.GroupingInfo> groupingInfos = results.getReportMetadata().getGroupingsDown();
        List<String> groupingHeaders = new List<String>();

        for (Reports.GroupingInfo g : groupingInfos) {
            String key = g.getName().toUpperCase();
            String label = apiNameToLabelMap.containsKey(key) ? apiNameToLabelMap.get(key) : g.getName();
            groupingHeaders.add('"' + label.replace('"', '""') + '"');
        }

        List<String> detailColumns = results.getReportMetadata().getDetailColumns();
        List<String> detailHeaders = new List<String>();

        for (String apiName : detailColumns) {
            String key = apiName.toUpperCase();
            String label = apiNameToLabelMap.containsKey(key) ? apiNameToLabelMap.get(key) : apiName;
            detailHeaders.add('"' + label.replace('"', '""') + '"');
        }

        List<String> headers = new List<String>();
        headers.addAll(groupingHeaders);
        headers.addAll(detailHeaders);
        csv += String.join(headers, ',') + '\n';

        Map<String, Reports.ReportFact> factMap = results.getFactMap();

        for (String key : factMap.keySet()) {
            if (!key.endsWith('!T')) continue;

            Reports.ReportFact baseFact = factMap.get(key);
            Reports.ReportFactWithDetails fact =
                (baseFact instanceof Reports.ReportFactWithDetails)
                ? (Reports.ReportFactWithDetails)baseFact
                : null;

            if (fact == null || fact.getRows() == null) continue;

            List<Reports.ReportDetailRow> rows = fact.getRows();
            String groupingLabel = getGroupingLabelFromKey(key, results);

            for (Reports.ReportDetailRow row : rows) {
                List<String> rowValues = new List<String>();
                rowValues.add('"' + groupingLabel.replace('"', '""') + '"');

                for (Reports.ReportDataCell cell : row.getDataCells()) {
                    String val = '';
                    if (cell.getLabel() != null) {
                        if (cell.getLabel() == '-' && cell.getValue() == null) {
                            val = '';
                        } else {
                            val = cell.getLabel();
                        }
                    }
                    rowValues.add('"' + val.replace('"', '""') + '"');
                }

                csv += String.join(rowValues, ',') + '\n';
            }
        }

        return csv;
    }

    private static String getGroupingLabelFromKey(String key, Reports.ReportResults results) {
        if (!key.contains('!')) return '';

        String groupIndexStr = key.split('!')[0];
        Integer groupIndex;
        try {
            groupIndex = Integer.valueOf(groupIndexStr);
        } catch (Exception e) {
            return '';
        }

        List<Reports.GroupingValue> groupings = results.getGroupingsDown().getGroupings();
        if (groupings != null && groupings.size() > groupIndex) {
            Reports.GroupingValue grouping = groupings[groupIndex];
            return grouping != null && grouping.getLabel() != null ? grouping.getLabel() : '';
        }

        return '';
    }


    @TestVisible @future
    public static void sendEmailWithCsv(String csvContent) {
        System.debug('csvContent '+ csvContent);
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.setFileName('Legal Name Updates made by Credit report.csv');
        attachment.setContentType('text/csv');
        attachment.setBody(Blob.valueOf(csvContent));

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] { 'internalservicing@peacsolutions.com' });
        email.setSubject('Legal Name Updates made by Credit report');
        email.setPlainTextBody('Attached is the weekly Legal Name Updates made by Credit report.');
        email.setFileAttachments(new Messaging.EmailFileAttachment[] { attachment });

        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
    }
}