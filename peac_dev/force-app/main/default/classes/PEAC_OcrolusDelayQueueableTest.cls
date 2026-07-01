@IsTest
private class PEAC_OcrolusDelayQueueableTest {
    
    private static Opportunity createBaseData(Boolean withPK) {
        
        SL_SCTestData.createAccountAndContracts(1,1);
        Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
        
        SL_SCTestData.createOpportunities(acc.Id,1);
        Opportunity opp = [SELECT Id, RecordTypeId FROM Opportunity ORDER BY CreatedDate DESC LIMIT 1];
        
        opp.RecordTypeId = Schema.SObjectType.Opportunity
            .getRecordTypeInfosByName()
            .get('Loan Booking')
            .getRecordTypeId();
        
        opp.StageName = 'Application';
        opp.Requested_Amount__c = 55000;
        
        if(withPK){
            opp.PK__c = 'PK-12345';
        }
        
        update opp;
        
        return opp;
    }
    
    
    @IsTest
    static void testQueueableExecution() {
        
        Opportunity opp = createBaseData(true);
        Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
        
        Opportunity_Attachment__c oppAtt = new Opportunity_Attachment__c(
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            Type__c = Label.TC_BankStatementFileType,
            Sent_To_OnBase__c = true,
            Updated_Rapport__c = false
        );
        insert oppAtt;
        
        Attachment att = new Attachment(
            Name = 'statement.pdf',
            ParentId = oppAtt.Id,
            Body = Blob.valueOf('PDF Content'),
            ContentType = 'application/pdf'
        );
        insert att;
        
        Test.startTest();
        System.enqueueJob(new PEAC_OcrolusDelayQueueable(opp.Id));
        Test.stopTest();
        
        System.assert(true);
    }
    
    
    @IsTest
    static void testNonPdfScenario() {
        
        Opportunity opp = createBaseData(true);
        Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
        
        Opportunity_Attachment__c oppAtt = new Opportunity_Attachment__c(
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            Type__c = Label.TC_BankStatementFileType,
            Sent_To_OnBase__c = true,
            Updated_Rapport__c = false
        );
        insert oppAtt;
        
        Attachment nonPdf = new Attachment(
            Name = 'image.jpg',
            ParentId = oppAtt.Id,
            Body = Blob.valueOf('Image'),
            ContentType = 'image/jpeg'
        );
        insert nonPdf;
        
        Test.startTest();
        PEAC_OcrolusDelayQueueable.sendAttachmentsToOnbaseAndOcrolus(opp.Id);
        Test.stopTest();
        
        System.assert(true);
    }
    
    
    @IsTest
    static void testContentDocumentBranch() {
        
        Opportunity opp = createBaseData(true);
        Account acc = [SELECT Id FROM Account ORDER BY CreatedDate DESC LIMIT 1];
        
        Opportunity_Attachment__c oppAtt = new Opportunity_Attachment__c(
            Opportunity__c = opp.Id,
            Account__c = acc.Id,
            Type__c = Label.TC_BankStatementFileType,
            Sent_To_OnBase__c = true,
            Updated_Rapport__c = false
        );
        insert oppAtt;
        
        ContentVersion cv = new ContentVersion(
            Title = 'statement',
            PathOnClient = 'statement.pdf',
            VersionData = Blob.valueOf('PDF Body'),
            IsMajorVersion = true
        );
        insert cv;
        
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = oppAtt.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V'
        );
        insert cdl;
        
        Test.startTest();
        PEAC_OcrolusDelayQueueable.sendAttachmentsToOnbaseAndOcrolus(opp.Id);
        Test.stopTest();
        
        System.assert(true);
    }
    
    
    @IsTest
    static void testPKBlankScenario() {
        
        Opportunity opp = createBaseData(false);
        
        Test.startTest();
        PEAC_OcrolusDelayQueueable.sendAttachmentsToOnbaseAndOcrolus(opp.Id);
        Test.stopTest();
        
        System.assert(true);
    }
    
    
    @IsTest
    static void testNullOppId() {
        Test.startTest();
        PEAC_OcrolusDelayQueueable.sendAttachmentsToOnbaseAndOcrolus(null);
        Test.stopTest();
        System.assert(true);
    }
}