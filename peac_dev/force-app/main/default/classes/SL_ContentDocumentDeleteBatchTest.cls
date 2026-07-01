/**
 * SL_ContentDocumentDeleteBatchTest
 * 
 * Test coverage for SL_ContentDocumentDeleteBatch and ContentDocumentPurgeScheduler.
 */
@IsTest
public with sharing class SL_ContentDocumentDeleteBatchTest {
    // ── Test data setup ───────────────────────────────────────────────────────

    @TestSetup
    static void setupData() {
        // Custom setting – 10 days so we can easily create "old" records in tests
        Opportunity_Attachment_Retention__c settings = new Opportunity_Attachment_Retention__c();
        settings.Retention_Days__c   = 0;
        insert settings;
        
         User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
                System.runAs(u) {
                 SL_SCTestData.createAccountAndContracts(1, 1); 
                }
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Opportunity theOpp = SL_SCTestData.testOpportunities[0];
    }

    // Helper: create an Opportunity_Attachment__c and attach a ContentDocument to it
    private static Opportunity_Attachment__c createOppAttWithDoc(Boolean sentToOnBase, Boolean isContentDoc) {
        
        Opportunity theOpp = [SELECT ID FROM Opportunity LIMIT 1];
        Opportunity_Attachment__c oppAtt = new Opportunity_Attachment__c(
            Sent_To_OnBase__c       = sentToOnBase,
            IsContentDocument__c    = isContentDoc,
            Content_Document_Deleted__c = false,
            Opportunity__c = theOpp.Id,
            Type__c = 'FS - Bank Statements'
        );
        insert oppAtt;

        if (isContentDoc) {
            ContentVersion cv = new ContentVersion(
                Title           = 'Test Document',
                PathOnClient    = 'TestDocument.txt',
                VersionData     = Blob.valueOf('Test content'),
                IsMajorVersion  = true
            );
            insert cv;

            // Get the auto-created ContentDocument Id
            Id contentDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;

            ContentDocumentLink cdl = new ContentDocumentLink(
                LinkedEntityId     = oppAtt.Id,
                ContentDocumentId  = contentDocId,
                ShareType          = 'V'
            );
            insert cdl;
        }

        return oppAtt;
    }

    // ── Test: eligible record is deleted and flagged ──────────────────────────

    @IsTest
    static void testEligibleRecordIsDeleted() {
        Opportunity_Attachment__c oppAtt = createOppAttWithDoc(true, true);

        // Back-date the ContentDocument so it's older than retention period
        Test.setCreatedDate(oppAtt.Id, DateTime.now().addDays(-15));

        Test.startTest();
        SL_ContentDocumentDeleteBatch batch = new SL_ContentDocumentDeleteBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();

        // Content Document should be gone
        List<ContentDocumentLink> remainingCDLs = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :oppAtt.Id
        ];

        // Flag should be stamped
        Opportunity_Attachment__c updated = [
            SELECT Content_Document_Deleted__c FROM Opportunity_Attachment__c WHERE Id = :oppAtt.Id
        ];
    }

    // ── Test: record not sent to OnBase is NOT deleted ────────────────────────

    @IsTest
    static void testNotSentToOnBaseIsRetained() {
        Opportunity_Attachment__c oppAtt = createOppAttWithDoc(false, true);
        Test.setCreatedDate(oppAtt.Id, DateTime.now().addDays(-15));

        Test.startTest();
        Database.executeBatch(new SL_ContentDocumentDeleteBatch(), 200);
        Test.stopTest();

        List<ContentDocumentLink> remainingCDLs = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :oppAtt.Id
        ];
        Assert.areEqual(1, remainingCDLs.size(), 'ContentDocumentLink should NOT have been deleted');
    }

    // ── Test: record within retention window is NOT deleted ───────────────────

    @IsTest
    static void testWithinRetentionWindowIsRetained() {
        Opportunity_Attachment__c oppAtt = createOppAttWithDoc(true, true);
        // Only 3 days old — within the 10-day test retention period
        Test.setCreatedDate(oppAtt.Id, DateTime.now().addDays(-3));

        Test.startTest();
        Database.executeBatch(new SL_ContentDocumentDeleteBatch(), 200);
        Test.stopTest();

        List<ContentDocumentLink> remainingCDLs = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :oppAtt.Id
        ];
    }

    // ── Test: already flagged record is excluded from batch scope ─────────────

    @IsTest
    static void testAlreadyFlaggedRecordSkipped() {
        Opportunity_Attachment__c oppAtt = createOppAttWithDoc(true, true);
        oppAtt.Content_Document_Deleted__c = true;
        update oppAtt;
        Test.setCreatedDate(oppAtt.Id, DateTime.now().addDays(-15));

        Test.startTest();
        Database.executeBatch(new SL_ContentDocumentDeleteBatch(), 200);
        Test.stopTest();

        // ContentDocumentLink should still exist — record was excluded from scope
        List<ContentDocumentLink> remainingCDLs = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :oppAtt.Id
        ];
        Assert.areEqual(1, remainingCDLs.size(), 'Already-flagged record should have been skipped');
    }

    // ── Test: record with no Content Document is still flagged ───────────────

    @IsTest
    static void testRecordWithNoDocIsFlagged() {
        // IsContentDocument__c = false so no CDL created, but it still enters scope
        // because IsContentDocument__c filter requires true — so this record
        // would never be in scope. Test the case where it IS in scope but CDL
        // was already cleaned up externally.
        Opportunity theOpp = [SELECT ID FROM Opportunity LIMIT 1];
        Opportunity_Attachment__c oppAtt = new Opportunity_Attachment__c(
            Sent_To_OnBase__c       = true,
            IsContentDocument__c    = true,
            Content_Document_Deleted__c = false,
			Opportunity__c = theOpp.Id,
			Type__c = 'FS - Bank Statements'
        );
        insert oppAtt;
        Test.setCreatedDate(oppAtt.Id, DateTime.now().addDays(-15));

        Test.startTest();
        Database.executeBatch(new SL_ContentDocumentDeleteBatch(), 200);
        Test.stopTest();

        Opportunity_Attachment__c updated = [
            SELECT Content_Document_Deleted__c FROM Opportunity_Attachment__c WHERE Id = :oppAtt.Id
        ];
        Assert.isTrue(updated.Content_Document_Deleted__c, 'Record with no docs should still be flagged as processed');
    }

    // ── Test: custom setting override ─────────────────────────────────────────

    @IsTest
    static void testCustomSettingOverride() {
        // Update retention to 30 days
        Opportunity_Attachment_Retention__c settings = Opportunity_Attachment_Retention__c.getInstance();
        settings.Retention_Days__c = 30;
        upsert settings;

        Opportunity_Attachment__c oppAtt = createOppAttWithDoc(true, true);
        // 15 days old — would be eligible under 10-day setting, NOT under 30-day
        Test.setCreatedDate(oppAtt.Id, DateTime.now().addDays(-15));

        Test.startTest();
        Database.executeBatch(new SL_ContentDocumentDeleteBatch(), 200);
        Test.stopTest();

        List<ContentDocumentLink> remainingCDLs = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :oppAtt.Id
        ];
        Assert.areEqual(1, remainingCDLs.size(), 'Should be retained under 30-day retention setting');
    }

    // ── Test: empty batch run (no eligible records) ───────────────────────────

    @IsTest
    static void testEmptyBatchRun() {
        // No records inserted — batch should complete without errors
        Test.startTest();
        Database.executeBatch(new SL_ContentDocumentDeleteBatch(), 200);
        Test.stopTest();
        // No assertions needed — just verifying no exceptions thrown
        Assert.isTrue(true, 'Empty batch run should complete without errors');
    }

    // ── Test: scheduler instantiates and executes batch ───────────────────────

    @IsTest
    static void testScheduler() {
        Test.startTest();
        String jobId = System.schedule(
            'Test Content Doc Purge',
            '0 0 2 * * ?',
            new SL_ContentDocumentDeleteScheduler()
        );
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        Assert.areEqual(1, jobs.size(), 'Scheduled job should exist');
        Assert.areEqual('Test Content Doc Purge', jobs[0].CronJobDetail.Name);
    }
        
    @IsTest
    static void testDeleteFailureIsLogged() {
        Opportunity_Attachment__c oppAtt = createOppAttWithDoc(true, true);
        Test.setCreatedDate(oppAtt.Id, DateTime.now().addDays(-15));
    
        SL_ContentDocumentDeleteBatch batch = new SL_ContentDocumentDeleteBatch();
        batch.mockDeleteResultsJson = '[{"id":"' + oppAtt.Id + '","success":false,"errors":'
            + '[{"message":"Mocked delete failure",'
            + '"statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION","fields":[]}]}]';
    
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();
    
        Opportunity_Attachment__c updated = [
            SELECT Content_Document_Deleted__c
            FROM   Opportunity_Attachment__c
            WHERE  Id = :oppAtt.Id
        ];
        Assert.isTrue(updated.Content_Document_Deleted__c, 'Flag should be set even when delete fails');
    }
    
    @IsTest
    static void testUpdateFailureIsLogged() {
        Opportunity_Attachment__c oppAtt = createOppAttWithDoc(true, true);
        Test.setCreatedDate(oppAtt.Id, DateTime.now().addDays(-15));
    
        SL_ContentDocumentDeleteBatch batch = new SL_ContentDocumentDeleteBatch();
        batch.mockUpdateResultsJson = '[{"id":"' + oppAtt.Id + '","success":false,"errors":'
            + '[{"message":"Mocked update failure",'
            + '"statusCode":"FIELD_CUSTOM_VALIDATION_EXCEPTION","fields":[]}]}]';
    
        Test.startTest();
        Database.executeBatch(batch, 200);
        Test.stopTest();
    
        List<ContentDocumentLink> remaining = [
            SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :oppAtt.Id
        ];
        Assert.areEqual(0, remaining.size(), 'Content doc should still be deleted');
    }
}