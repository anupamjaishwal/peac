/**
 * ContentDocumentPurgeBatch
 * 
 * Batch job to delete Content Documents linked to Opportunity_Attachment__c records
 * that have been sent to OnBase and have exceeded the configured retention period.
 * 
 * Retention period is driven by the Opportunity_Attachment_Retention__c custom setting
 * (Retention_Days__c field), defaulting to 50 days if not configured.
 * 
 * Scheduling:
 *   System.schedule('SL_ContentDocumentDeleteBatch', '0 0 2 * * ?', new SL_ContentDocumentDeleteBatch());
 */


public with sharing class SL_ContentDocumentDeleteBatch implements Database.Batchable<SObject>, Database.Stateful {

    // Injectable error lists — populated by tests to simulate DML failures
    @TestVisible private String mockDeleteResultsJson;
    @TestVisible private String mockUpdateResultsJson;


    // ── Instance variables ───────────────────────────────────────────────────
    private DateTime cutoff;

    // Stateful counters for finish() summary
    private Integer totalProcessed  = 0;
    private Integer totalDeleted    = 0;
    private Integer totalFailed     = 0;
    private List<String> errorMessages = new List<String>();

    // ── Constructor ──────────────────────────────────────────────────────────

    public SL_ContentDocumentDeleteBatch() {
        Opportunity_Attachment_Retention__c settings = Opportunity_Attachment_Retention__c.getInstance();
        Integer retentionDays = (settings != null && settings.Retention_Days__c != null)
            ? settings.Retention_Days__c.intValue()
            : 50;

        this.cutoff = DateTime.now().addDays(-retentionDays);
    }

    // ── start() ──────────────────────────────────────────────────────────────

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Opportunity_Attachment__c
            WHERE Sent_To_OnBase__c        = true
            AND   IsContentDocument__c     = true
            AND   Content_Document_Deleted__c  = false
            AND   CreatedDate             <= :cutoff
        ]);
    }

    // ── execute() ────────────────────────────────────────────────────────────

    public void execute(Database.BatchableContext bc, List<Opportunity_Attachment__c> scope) {

        Set<Id> oppAttIds = new Map<Id, Opportunity_Attachment__c>(scope).keySet();

        // ── Step 1: Get linked Content Document Ids ──────────────────────────
        // ContentDocumentLink requires a filter by Id using IN — cannot be used
        // as a QueryLocator source directly with these filters.
        List<ContentDocumentLink> cdLinks = [
            SELECT ContentDocumentId
            FROM   ContentDocumentLink
            WHERE  LinkedEntityId IN :oppAttIds
        ];

        Set<Id> docIds = new Set<Id>();
        for (ContentDocumentLink cdl : cdLinks) {
            docIds.add(cdl.ContentDocumentId);
        }

        // ── Step 2: Delete eligible Content Documents ────────────────────────
        if (!docIds.isEmpty()) {

            // Apply the CreatedDate filter here since we couldn't do it via
            // ContentDocumentLink in start(). This guards against docs uploaded
            // after the parent record was created but before the cutoff.
            List<ContentDocument> docsToDelete = [
                SELECT Id
                FROM   ContentDocument
                WHERE  Id          IN :docIds
                AND    CreatedDate <= :cutoff
            ];

            if (!docsToDelete.isEmpty()) {
                System.debug('TO DELETE: ' + docsToDelete);
                
                List<Database.DeleteResult> results = (Test.isRunningTest() && mockDeleteResultsJson != null)
                    ? (List<Database.DeleteResult>) JSON.deserialize(mockDeleteResultsJson, List<Database.DeleteResult>.class)
                    : Database.delete(docsToDelete, false);
                    
                for (Database.DeleteResult dr : results) {
                    if (dr.isSuccess()) {
                        totalDeleted++;
                    } else {
                        totalFailed++;
                        for (Database.Error err : dr.getErrors()) {
                            String msg = 'DocId: ' + dr.getId()
                                + ' | ' + err.getStatusCode()
                                + ' | ' + err.getMessage();
                            errorMessages.add(msg);
                            System.debug(LoggingLevel.ERROR, 'ContentDocumentPurgeBatch delete error: ' + msg);
                        }
                    }
                } 
            }
        }

        // ── Step 3: Stamp ALL records in scope as processed ──────────────────
        // We stamp regardless of whether docs were found. If a record had no
        // CDLs it has nothing to delete — no point pulling it into scope again.
        List<Opportunity_Attachment__c> toUpdate = new List<Opportunity_Attachment__c>();
        for (Id oppAttId : oppAttIds) {
            toUpdate.add(new Opportunity_Attachment__c(
                Id                    = oppAttId,
                Content_Document_Deleted__c  = true
            ));
        }

        if (!toUpdate.isEmpty()) {
            List<Database.SaveResult> updateResults = (Test.isRunningTest() && mockUpdateResultsJson != null)
                ? (List<Database.SaveResult>) JSON.deserialize(mockUpdateResultsJson, List<Database.SaveResult>.class)
                : Database.update(toUpdate, false);
            for (Database.SaveResult sr : updateResults) {
                if (!sr.isSuccess()) {
                    for (Database.Error err : sr.getErrors()) {
                        String msg = 'Flag update failed for Id: ' + sr.getId()
                            + ' | ' + err.getStatusCode()
                            + ' | ' + err.getMessage();
                        errorMessages.add(msg);
                        System.debug(LoggingLevel.ERROR, 'ContentDocumentPurgeBatch flag error: ' + msg);
                    }
                }
            } 
        }

        totalProcessed += scope.size();
    }

    // ── finish() ─────────────────────────────────────────────────────────────

    public void finish(Database.BatchableContext bc) {

        String subject = 'Content Document Purge Batch – Completed';
        String body    = 'Batch job finished.\n\n'
            + 'Cutoff Date     : ' + cutoff.format() + '\n'
            + 'Records Processed: ' + totalProcessed  + '\n'
            + 'Documents Deleted: ' + totalDeleted    + '\n'
            + 'Delete Failures  : ' + totalFailed     + '\n';

        if (!errorMessages.isEmpty()) {
            subject = 'Content Document Purge Batch – Completed WITH ERRORS';
            body   += '\nErrors:\n';
            for (String err : errorMessages) {
                body += '  - ' + err + '\n';
            }
        }

        System.debug(LoggingLevel.INFO, 'ContentDocumentPurgeBatch finish: ' + body);
    }

}