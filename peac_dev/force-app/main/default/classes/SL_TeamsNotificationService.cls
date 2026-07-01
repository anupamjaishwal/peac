public with sharing class SL_TeamsNotificationService {

    @future(callout=true)
    public static void sendLimitsTable(String payload) {
        Http h = new Http();
        HttpRequest req = new HttpRequest();

        req.setEndpoint('callout:Limits_Alerts_Channel');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(payload);

        HttpResponse res = h.send(req);
        System.debug('Teams status: ' + res.getStatus() + ' body: ' + res.getBody());
    }

    /**
     * Builds a Teams-compatible Adaptive Card using ColumnSet (NOT Table)
     */
    public static String buildLimitsCard(
        List<SL_OrgLimitMonitorService.LimitInfo> limits,
        String titleIcon
    ) {

        List<Object> body = new List<Object>();

        // Title
        body.add(new Map<String, Object>{
            'type' => 'TextBlock',
            'text' => titleIcon + ' Salesforce Limits Overview',
            'weight' => 'Bolder',
            'size' => 'Large',
            'wrap' => true
        });

        // Header row
        body.add(buildRow('Limit', 'Usage', '%', 'Priority', true));

        // Data rows
        for (SL_OrgLimitMonitorService.LimitInfo l : limits) {

            String priorityEmoji =
                l.priority == 'High' ? '🔴' :
                l.priority == 'Medium' ? '🟠' :
                l.priority == 'Low' ? '🟡' : '⚪';

            body.add(buildRow(
                l.name,
                l.used + ' / ' + l.max,
                String.valueOf(l.percentage),
                priorityEmoji + ' ' + l.priority,
                false
            ));
        }
        // Spacer
        body.add(new Map<String, Object>{
            'type' => 'TextBlock',
            'text' => ' ',
            'spacing' => 'Medium'
        });
        // Footer
        body.add(new Map<String, Object>{
            'type' => 'TextBlock',
            'text' => '_If this issue is already being addressed, you can mark it as “In Progress” in Org Limit Monitors custom metadata to stop further notifications._',
            'weight' => 'default',
            'size' => 'default',
            'wrap' => true
        });

        Map<String, Object> card = new Map<String, Object>{
            'type' => 'message',
            'attachments' => new List<Object>{
                new Map<String, Object>{
                    'contentType' => 'application/vnd.microsoft.card.adaptive',
                    'content' => new Map<String, Object>{
                        '$schema' => 'https://adaptivecards.io/schemas/adaptive-card.json',
                        'type' => 'AdaptiveCard',
                        'version' => '1.4',
                        'msteams' => new Map<String, Object>{ 'width' => 'Full' },
                        'body' => body
                    }
                }
            }
        };

        return JSON.serialize(card);
    }

    // Build a row using ColumnSet (Teams-compatible)
    private static Map<String, Object> buildRow(
        String c1,
        String c2,
        String c3,
        String c4,
        Boolean isHeader
    ) {

        String weight = isHeader ? 'Bolder' : 'Default';

        return new Map<String, Object>{
            'type' => 'ColumnSet',
            'separator' => true,
            'columns' => new List<Object>{
                buildColumn(c1, weight, String.valueof(2)),
                buildColumn(c2, weight, String.valueof(1)),
                buildColumn(c3, weight, String.valueof(1)),
                buildColumn(c4, weight, String.valueof(1))
            }
        };
    }

    private static Map<String, Object> buildColumn(String text, String weight, String width ) {
        return new Map<String, Object>{
            'type' => 'Column',
            'width' => width,
            'items' => new List<Object>{
                new Map<String, Object>{
                    'type' => 'TextBlock',
                    'text' => text,
                    'wrap' => true,
                    'weight' => weight
                }
            }
        };
    }
}