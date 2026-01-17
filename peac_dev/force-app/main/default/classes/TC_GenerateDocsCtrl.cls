public with sharing class TC_GenerateDocsCtrl {
    private static Opportunity opp;
    private static List<Signer> signers = new List<Signer>();

    @AuraEnabled
    public static String generateDocuments(String recordId) {
        getData(recordId);
        processData();
        return getRedirectString();
    }

    private static void getData(String recordId) {
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id,
                                                                    AccountId,
                                                                    DocGen_Formula__c,
                                                                    Primary_Contact__c,
                                                                    Primary_Contact__r.Name, 
                                                                    Primary_Contact__r.Email,
                                                                    Workflow_Type__c,
                                                                    (SELECT Id, 
                                                                            Contact_Name__c, 
                                                                            Email__c
                                                                    FROM Guarantor__r
                                                                    WHERE RecordTypeId = :Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId()
                                                                    ORDER BY CreatedDate ASC) 
                                                            FROM Opportunity 
                                                            WHERE Id = :recordId]);
        if(oppList?.isEmpty() == false) {
            opp = oppList[0];
        }
    }

    private static void processData() {
        Integer i = 1;
        if(opp.Guarantor__r?.size() > 0) {
            for(Guarantor__c g : opp.Guarantor__r) {
                if(i > 1) {
                    return;
                }
                signers.add(new Signer(g.Contact_Name__c, g.Email__c));
                i++;
            }
        } else if(opp.Primary_Contact__c != null) {
            signers.add(new Signer(opp.Primary_Contact__r?.Name, opp.Primary_Contact__r?.Email));
        }
    }

    private static String getRedirectString() {
        String url = '/apex/loop__looplus?&eid=' + opp.Id + '&accountId=' + opp.AccountId;
        url += '&filter=' + getFilter();
        url += '&filtertype=' + getFilterType();
        if(opp.Workflow_Type__c == 'Simple') {
            url += getSignerUrlString();
        }
        System.debug('URL: ' + url);
        return url;
    }

    private static String getFilter() {
        return (!String.isBlank(opp.DocGen_Formula__c) ? opp.DocGen_Formula__c : 'Simple');
    }

    private static String getFilterType() {
        return (!String.isBlank(opp.DocGen_Formula__c) ? '' : 'doesnotcontain');
    }

    private static String getSignerUrlString() {
        String signerUrl;
        Integer i = 1;
        if(signers?.isEmpty() == false) {
            System.debug('Signers not empty');
            signerUrl = '&';
            for(Signer s : signers) {
                System.debug('Signer' + i + ': ' + s); 
                if(i == 2) {
                    signerUrl += '&';
                }
                signerUrl += 'Signer' + i + '_name=' + urlEncode(s.name);
                signerUrl += '&Signer' + i + '_email=' + urlEncode(s.email);
                i++;
            }
        } else {
            throw new AuraHandledException('Signer 1 required. Please ensure there is at least one related personal guarantor or selected primary contact.');
        }
        return (signerUrl == null ? '' : signerUrl);
    }

    private static String urlEncode(String value) {
        return value == null ? '' : EncodingUtil.urlEncode(value, 'UTF-8');
    }

    private class Signer {
        String name;
        String email;

        public Signer(String name, String email) {
            this.name = name != null ? name : '';
            this.email = email != null ? email : '';
        }
    }
}