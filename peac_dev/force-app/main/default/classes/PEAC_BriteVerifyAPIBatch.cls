global without sharing class PEAC_BriteVerifyAPIBatch
    implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    global Integer maxRecordsToProcess;

    global Integer totalScopes = 0;
    global Integer totalContactsSeen = 0;
    global Integer totalContactsUpdated = 0;

    global List<Id> executedContactIds = new List<Id>();
    global List<Id> updatedContactIds  = new List<Id>(); 

    @TestVisible private static Boolean useMockBriteVerifyInTests = false;
    @TestVisible private static String  mockBriteVerifyStatus     = 'Accept_All';
    

    global PEAC_BriteVerifyAPIBatch(Integer maxRecordsToProcess) {
        this.maxRecordsToProcess = maxRecordsToProcess;
    }

    global Database.QueryLocator start(Database.BatchableContext bc) {
        String q =
            'SELECT Id, Email ' +
            'FROM Contact ' +
            'WHERE Email != null ' +
            'AND Final_E_mail_Validity_Result__c = null ' +
            'AND (Validity_Verify__Checked__c = false OR Validity_Verify__Checked__c = null) ' +
            'ORDER BY Id ' +
            'LIMIT ' + String.valueOf(maxRecordsToProcess);

        return Database.getQueryLocator(q);
    }

    global void execute(Database.BatchableContext bc, List<Contact> scope) {
        totalScopes++;
        totalContactsSeen += scope.size();

        List<Contact> toUpdate = new List<Contact>();

        for (Contact c : scope) {
            executedContactIds.add(c.Id);

            try {
                List<BriteVerifyResponse> resps;

                if (Test.isRunningTest() && useMockBriteVerifyInTests) {
                    BriteVerifyResponse r = new BriteVerifyResponse();
                    r.status = mockBriteVerifyStatus;
                    resps = new List<BriteVerifyResponse>{ r };
                } else {
                    resps = TC_ContactRelatedObjUpdate.runBriteVerifyCheck(new Set<String>{ c.Email });
                }

                if (!resps.isEmpty() && resps[0] != null && String.isNotBlank(resps[0].status)) {
                    Contact upd = new Contact(Id = c.Id);
                    upd.Validity_Verify__Checked__c = true;
                    upd.Validity_Verify__Status__c = resps[0].status; 
                    upd.Validity_Verify__Timestamp__c = System.now();
                    toUpdate.add(upd);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN,
                    'BriteVerify failed for ContactId=' + c.Id + ' Email=' + c.Email +
                    ' Err=' + e.getMessage());
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.SaveResult[] srList = Database.update(toUpdate, false);

            for (Integer i = 0; i < srList.size(); i++) {
                if (srList[i].isSuccess()) {
                    totalContactsUpdated++;
                    updatedContactIds.add(toUpdate[i].Id);
                } else {
                    String errMsg = (srList[i].getErrors().isEmpty())
                        ? 'unknown'
                        : srList[i].getErrors()[0].getMessage();

                    System.debug(LoggingLevel.WARN,
                        'DML failed for ContactId=' + toUpdate[i].Id + ' Err=' + errMsg);
                }
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, '=== PEAC_BriteVerifyAPIBatch Summary ===');
        System.debug(LoggingLevel.INFO, 'Scopes executed: ' + totalScopes);
        System.debug(LoggingLevel.INFO, 'Contacts processed (looped): ' + totalContactsSeen);
        System.debug(LoggingLevel.INFO, 'Contacts successfully updated: ' + totalContactsUpdated);

        System.debug(LoggingLevel.INFO, 'Executed Contact IDs count: ' + executedContactIds.size());
        debugIdsInChunks('Executed Contact IDs', executedContactIds);

        System.debug(LoggingLevel.INFO, 'Updated (DML-success) Contact IDs count: ' + updatedContactIds.size());
        debugIdsInChunks('Updated (DML-success) Contact IDs', updatedContactIds);
    }

    private static void debugIdsInChunks(String label, List<Id> ids) {
        Integer chunkSize = 50;

        for (Integer i = 0; i < ids.size(); i += chunkSize) {
            Integer endIdx = Math.min(i + chunkSize, ids.size());

            List<String> chunk = new List<String>();
            for (Integer j = i; j < endIdx; j++) {
                chunk.add(String.valueOf(ids[j]));
            }

            System.debug(LoggingLevel.INFO,
                label + ' [' + i + '-' + (endIdx - 1) + ']: ' + String.join(chunk, ','));
        }
    }
}