@isTest public class TC_UploadAttachmentTest {

        @TestSetup
    static void makeData(){
        Account acc = new Account();
        acc.Name = 'test Account';
        insert acc;


        List<Opportunity> oppsList = new List<Opportunity>();
        Opportunity leaseOpp = new Opportunity();
        leaseOpp.Name = 'Test';
        leaseOpp.AccountId = acc.Id;
        leaseOpp.StageName = 'Quote';
        leaseOpp.CloseDate = Date.today();
        leaseOpp.Primary_Source__c = 'Customer Inbound - Call';
        leaseOpp.Application__c = '1';
        oppsList.add(leaseOpp);
        
		Id oppLoanRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId();

		Opportunity loanOpp = new Opportunity();
        loanOpp.Name = 'Test Loan';
        loanOpp.AccountId = acc.Id;
        loanOpp.StageName = 'Quote';
        loanOpp.CloseDate = Date.today();
        loanOpp.Primary_Source__c = 'Customer Inbound - Call';
        loanOpp.CaseCenter__c = '2';
        loanOpp.recordTypeId =oppLoanRecordTypeId;
        oppsList.add(loanOpp);

        insert oppsList;
    }
    
    @isTest public static void attachmentTest () {
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Loan_Record_Type__c=false LIMIT 1];
        Opportunity_Attachment__c onBaseAttachment = new Opportunity_Attachment__c();
        onBaseAttachment.Opportunity__c = opp.Id;
        onBaseAttachment.Name = 'Test';
        onBaseAttachment.Type__c = 'CR - Misc';
        insert onBaseAttachment;
        
		//Insert Attachments
        Attachment att = new Attachment(
            Name = String.valueOf('Test Attachment'), 
            Body = Blob.valueOf('text'),
        	ParentId = onBaseAttachment.Id);
        insert att;
		Test.startTest();

        ApexPages.StandardController stdOpp = new ApexPages.StandardController(opp);
        UploadAttachment uploadAtt = new UploadAttachment (stdOpp);
        
        uploadAtt.fileBody = Blob.valueOf(' ');
        uploadAtt.fileName = 'test';
        
        uploadAtt.getDocumentTypes ();
        uploadAtt.saveStandardAttachment (opp.Id);
		UploadAttachment.getDocumentTypesLWC(opp.Id);
        uploadAtt.sendAttachmentToOcrolusOnbase();
        uploadAtt.processUpload();
        uploadAtt.back();
        
        
        uploadAtt.selectedAwesomeness = false;
        uploadAtt.responseMessage = 'test';
		Test.stopTest();

    }
    
        @isTest public static void attachmentTestLoan () {
        
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Loan_Record_Type__c=true LIMIT 1];
        Opportunity_Attachment__c onBaseAttachment = new Opportunity_Attachment__c();
        onBaseAttachment.Opportunity__c = opp.Id;
        onBaseAttachment.Name = 'Test';
        onBaseAttachment.Type__c = 'CR - Misc';
        insert onBaseAttachment;
        
		//Insert Attachments
        Attachment att = new Attachment(
            Name = String.valueOf('Test Attachment'), 
            Body = Blob.valueOf('text'),
        	ParentId = onBaseAttachment.Id);
        insert att;
        
		Test.startTest();

        ApexPages.StandardController stdOpp = new ApexPages.StandardController(opp);
        UploadAttachment uploadAtt = new UploadAttachment (stdOpp);
        
        uploadAtt.fileBody = Blob.valueOf(' ');
        uploadAtt.fileName = 'test';
        
        uploadAtt.getDocumentTypes();
        UploadAttachment.getDocumentTypesLWC(opp.Id);
        uploadAtt.saveStandardAttachment (opp.Id);
        uploadAtt.sendAttachmentToOcrolusOnbase();
        uploadAtt.processUpload();
        uploadAtt.back();
        
        uploadAtt.selectedAwesomeness = false;
        uploadAtt.responseMessage = 'test';
            
		Test.stopTest();

    }
}