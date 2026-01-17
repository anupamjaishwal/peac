@IsTest
/** 
 * @description test coverage for TC_OnbaseSendButtonExtension added for SAL-3037
 * Created by: Trohweder 7/12/21
 * SAL-3037
 */
public with sharing class Tc_OnBaseSendButtonTest {

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

    @IsTest
    public static void testSuccess(){
        List<Opportunity_Attachment__c> oppAttachments = new List<Opportunity_Attachment__c>();
        Test.startTest();

        Opportunity_Attachment__c onBaseAttachment = new Opportunity_Attachment__c();
        onBaseAttachment.Opportunity__c = [SELECT Id FROM Opportunity WHERE Loan_Record_Type__c=false LIMIT 1].Id;
        onBaseAttachment.Name = 'Test';
        onBaseAttachment.Type__c = 'CR - Misc';
        insert onBaseAttachment;
        
		//Insert Attachments
        Attachment att = new Attachment(
            Name = String.valueOf('Test Attachment'), 
            Body = Blob.valueOf('text'),
        	ParentId = onBaseAttachment.Id);
        insert att;

        oppAttachments.add(onBaseAttachment);

        Test.setCurrentPage(Page.OnBaseSendButton);
        ApexPages.currentPage().getParameters().put('id',onBaseAttachment.Opportunity__c);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(oppAttachments);
        stdSetController.setSelected(oppAttachments);
        TC_OnbaseSendButtonExtension ext = new TC_OnbaseSendButtonExtension(stdSetController);
        ext.sendAttachmentToOnBase();
        ext.back();
		Test.stopTest();

        //System.assert(ApexPages.getMessages()[0].getDetail().contains('Request submitted!'), 'There are errors with this Page');
    }

        @IsTest
    public static void testSuccessLoan(){
        List<Opportunity_Attachment__c> oppAttachments = new List<Opportunity_Attachment__c>();
        Test.startTest();

        Opportunity_Attachment__c onBaseAttachment = new Opportunity_Attachment__c();
        onBaseAttachment.Opportunity__c = [SELECT Id FROM Opportunity WHERE Loan_Record_Type__c=true LIMIT 1].Id;
        onBaseAttachment.Name = 'Test';
        onBaseAttachment.Type__c = 'CR - Misc';
        insert onBaseAttachment;

        oppAttachments.add(onBaseAttachment);
        
		//Insert Attachments
        Attachment att = new Attachment(
            Name = String.valueOf('Test Attachment'), 
            Body = Blob.valueOf('text'),
        	ParentId = onBaseAttachment.Id);
        insert att;

        Test.setCurrentPage(Page.OnBaseSendButton);
        ApexPages.currentPage().getParameters().put('id',onBaseAttachment.Opportunity__c);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(oppAttachments);
        stdSetController.setSelected(oppAttachments);
        TC_OnbaseSendButtonExtension ext = new TC_OnbaseSendButtonExtension(stdSetController);
        ext.sendAttachmentToOnBase();
        ext.back();
        Test.stopTest();

        //System.assert(ApexPages.getMessages()[0].getDetail().contains('Request submitted!'), 'There are errors with this Page');
    }
    @IsTest
    public static void testFail1(){
        List<Opportunity_Attachment__c> oppAttachments = new List<Opportunity_Attachment__c>();
        Test.startTest();

        Opportunity_Attachment__c onBaseAttachment = new Opportunity_Attachment__c();
        onBaseAttachment.Opportunity__c = [SELECT Id FROM Opportunity LIMIT 1].Id;
        onBaseAttachment.Name = 'Test';
        onBaseAttachment.Type__c = 'CR - Misc';
        insert onBaseAttachment;

        oppAttachments.add(onBaseAttachment);

        Test.setCurrentPage(Page.OnBaseSendButton);
        ApexPages.currentPage().getParameters().put('id',onBaseAttachment.Opportunity__c);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(oppAttachments);
        TC_OnbaseSendButtonExtension ext = new TC_OnbaseSendButtonExtension(stdSetController);
        ext.sendAttachmentToOnBase();
        Test.stopTest();
        System.assert(ApexPages.getMessages().size() > 0, 'No Errors thrown for not having attachment selected.');
    }
    @IsTest
    public static void testFail2(){
        List<Opportunity_Attachment__c> oppAttachments = new List<Opportunity_Attachment__c>();
        Test.startTest();

        Opportunity_Attachment__c onBaseAttachment = new Opportunity_Attachment__c();
        onBaseAttachment.Opportunity__c = [SELECT Id FROM Opportunity LIMIT 1].Id;
        onBaseAttachment.Name = 'Test';
        onBaseAttachment.Type__c = 'CR - Misc';
        insert onBaseAttachment;

        oppAttachments.add(onBaseAttachment);

        Test.setCurrentPage(Page.OnBaseSendButton);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(oppAttachments);
        stdSetController.setSelected(oppAttachments);
        TC_OnbaseSendButtonExtension ext = new TC_OnbaseSendButtonExtension(stdSetController);
        ext.sendAttachmentToOnBase();
        Test.stopTest();
        System.assert(ApexPages.getMessages().size() > 0, 'No Errors thrown for not having Opportunity Id.');
    }


    @IsTest
    public static void testGetDocumentTypesLWC(){
        List<Map<String,String>> result = new List<Map<String,String>>();
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        result = UploadAttachment.getDocumentTypesLWC(opp.Id);
        System.assert(result.size() > 0, 'No Document Types were found.');
    }
}