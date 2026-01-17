public without sharing class SL_DocsInNotificationHelper {
    private static String mockOrgWideEmailId;

    public static void setMockIds(String orgWideEmailId) {
        mockOrgWideEmailId = orgWideEmailId;
    }

    public static void sendEmail(Set<Id> oppIds) {
        System.debug('Entering sendEmail with Opportunity IDs: ' + oppIds);
        List<OrgWideEmailAddress> noreply;
        if (Test.isRunningTest()) {
            noreply = new List<OrgWideEmailAddress>{
                new OrgWideEmailAddress(Id = mockOrgWideEmailId, Address = 'mock@peacsolutions.com', DisplayName = 'Mock No Reply')
            };
        } else {
            noreply = [SELECT Id, Address, DisplayName FROM OrgWideEmailAddress WHERE Address = 'noreply@peacsolutions.com'];
        }

        String baseUrl = System.URL.getOrgDomainUrl().toExternalForm();

        Map<Id, Opportunity> oppWithUsersMap = new Map<Id, Opportunity>([
            SELECT Id, Name, Application__c, Docs_Out__c, Docs_In__c, 
                   Owner.Email, Owner.FirstName, 
                   Dealer_Account__r.SAM__r.Email, 
                   Dealer_Account__r.Ambassador__r.Email
            FROM Opportunity
            WHERE Id IN :oppIds
        ]);

        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

        for (Opportunity opp : oppWithUsersMap.values()) {
            String opportunityLink = baseUrl + '/' + opp.Id;

            String emailBody = '<html><body>';
            emailBody += '<h2 style="color:black; text-align:center; text-decoration:underline;">DOCS IN NOTICE</h2>';
            emailBody += '<p>Hi ' + (opp.Owner.FirstName != null ? opp.Owner.FirstName : 'there') + ',</p>';
            emailBody += '<p><b>Opportunity Name:</b> ' + opp.Name + '</p>';
            emailBody += '<p><b>Application #:</b> ' + (opp.Application__c != null ? opp.Application__c : 'N/A') + '</p>';
            emailBody += '<p><b>Docs Out Time:</b> ' + (opp.Docs_Out__c != null ? opp.Docs_Out__c.format() : 'N/A') + '</p>';
            emailBody += '<p><b><span style="background-color:yellow;">Docs In Time:</span></b> ' + (opp.Docs_In__c != null ? opp.Docs_In__c.format() : 'N/A') + '</p>';
            emailBody += '<br>';
            emailBody += '<p>Thank You<br><a href="' + opportunityLink + '">View Opportunity</a></p>';
            emailBody += '<hr>';
            emailBody += '<p style="font-size:12px; font-style:italic;">Notice: This e-mail message is confidential and is intended only for the use of the individual and/or entity identified in the address line of this message. If you have received this message in error, or are not the named recipient(s), please notify us immediately by telephone (856-359-9111).</p>';
            emailBody += '</body></html>';

            if (opp.Dealer_Account__r != null) {
                if (opp.Dealer_Account__r.SAM__r != null && String.isNotBlank(opp.Dealer_Account__r.SAM__r.Email)) {
                    emailsToSend.add(buildHtmlEmail(opp.Dealer_Account__r.SAM__r.Email, 'Docs In Notice', emailBody, noreply));
                                        System.debug('Email to SAM: ' + opp.Dealer_Account__r.SAM__r.Email);
                }
                if (opp.Dealer_Account__r.Ambassador__r != null && String.isNotBlank(opp.Dealer_Account__r.Ambassador__r.Email)) {
                    emailsToSend.add(buildHtmlEmail(opp.Dealer_Account__r.Ambassador__r.Email, 'Docs In Notice', emailBody, noreply));
                                        System.debug('Email to Ambassador: ' + opp.Dealer_Account__r.Ambassador__r.Email);
                }
            }
            if (String.isNotBlank(opp.Owner.Email)) {
                emailsToSend.add(buildHtmlEmail(opp.Owner.Email, 'Docs In Notice', emailBody, noreply));
                                System.debug('Email to Opportunity Owner: ' + opp.Owner.Email);
            }
        }

        if (!emailsToSend.isEmpty()) {
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailsToSend, false);
            for (Messaging.SendEmailResult result : results) {
                if (!result.isSuccess()) {
                    System.debug('Email failed: ' + result.getErrors()[0].getMessage());
                } else {
                    System.debug('Email sent successfully.');
                }
            }
        } else {
            System.debug('No emails to send.');
        }
    }

    private static Messaging.SingleEmailMessage buildHtmlEmail(String toAddress, String subject, String body, List<OrgWideEmailAddress> noreply) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if (noreply != null && !noreply.isEmpty()) {
            email.setOrgWideEmailAddressId(noreply[0].Id);
        }
        email.setToAddresses(new List<String>{toAddress});
        email.setSubject(subject);
        email.setHtmlBody(body); 
        email.setSaveAsActivity(false);
        return email;
    }
}