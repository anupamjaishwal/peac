/**
 * Created by tamarack on 2019-08-08.
 */

@isTest
public with sharing class TC_OcrolusCtrlTest {

    @testSetup
    static void setUp() {

        Account acc = new Account (Name = 'ocrolusAcc',
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId(),
                Business_Address__c = 'test', Business_City__c = 'test', Business_State__c = 'MN', Business_Zip__c = '11111');
        insert acc;

        Opportunity testOpp = new Opportunity (Name = 'ocrolusOpp', StageName = 'Decision', CloseDate = Date.today () + 10,
                AccountId = acc.Id, Primary_Source__c = 'Direct Mail',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId(),
                Application_Status__c = 'Manually Approved', Application__c = 'test', Equipment_Cost__c = 5000,
                Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0,
                of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1,
                Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January',
                Sec_Dep_Pymts__c = 200, Account_Billing_Street__c = 'test',
                CaseCenter__c = 'L3001');

        insert testOpp;

    }


    @isTest
    static void testSendAttachmentToOcrolusNoOpportunityAttachment() {

        Opportunity opp;
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Name FROM Opportunity WHERE Name = 'ocrolusOpp']);
        if (!oppList.isEmpty()) opp = oppList[0];

        PageReference pageRef = Page.OpportunityAttachmentAsynch;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        UploadAttachment controller = new UploadAttachment(sc);

        controller.sendAttachmentToOcrolus();

    }

    @isTest
    static void testSendAttachmentToOcrolusNoCaseCenterNumber() {

        Opportunity opp;
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Name FROM Opportunity WHERE Name = 'ocrolusOpp']);
        if (!oppList.isEmpty()) opp = oppList[0];
        
        opp.CaseCenter__c = null;
        Test.startTest();
        update opp;

        Opportunity_Attachment__c testOppAttach = new Opportunity_Attachment__c(Opportunity__c = opp.Id,
                Type__c = 'FS - Bank Statements');
        insert testOppAttach;

        

        PageReference pageRef = Page.OpportunityAttachmentAsynch;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        UploadAttachment controller = new UploadAttachment(sc);

        controller.sendAttachmentToOcrolus();

        Test.stopTest();
    }


    @isTest
    static void testSendAttachmentToOcrolusNonBankStmt() {

        Opportunity opp;
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Name FROM Opportunity WHERE Name = 'ocrolusOpp']);
        if (!oppList.isEmpty()) opp = oppList[0];

        opp.Pk__c = '1897239';
        Test.startTest();
        update opp;

        Opportunity_Attachment__c testOppAttach = new Opportunity_Attachment__c(Opportunity__c = opp.Id,
                Type__c = 'FS - SOS/License Verification');
        insert testOppAttach;

        Attachment testAttach = new Attachment();
        testAttach.body = Blob.valueOf('test blob content');
        testAttach.name = 'Test Attachment.pdf';
        testAttach.parentId = testOppAttach.Id;
        insert testAttach;

        PageReference pageRef = Page.OpportunityAttachmentAsynch;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        UploadAttachment controller = new UploadAttachment(sc);

        controller.sendAttachmentToOcrolus();

        Test.stopTest();
    }

    @isTest
    static void testSendAttachmentToOcrolusNoAttachment() {

        Opportunity opp;
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Name FROM Opportunity WHERE Name = 'ocrolusOpp']);
        if (!oppList.isEmpty()) opp = oppList[0];

        opp.Pk__c = '1897239';
        Test.startTest();
        update opp;

        Opportunity_Attachment__c testOppAttach = new Opportunity_Attachment__c(Opportunity__c = opp.Id,
                Type__c = 'FS - Bank Statements');
        insert testOppAttach;

        

        PageReference pageRef = Page.OpportunityAttachmentAsynch;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        UploadAttachment controller = new UploadAttachment(sc);

        controller.sendAttachmentToOcrolus();

        Test.stopTest();

    }


    @isTest
    static void testSendAttachmentToOcrolusCreateBook() {

        Opportunity opp;
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Name FROM Opportunity WHERE Name = 'ocrolusOpp']);
        if (!oppList.isEmpty()) opp = oppList[0];

        Opportunity_Attachment__c testOppAttach = new Opportunity_Attachment__c(Opportunity__c = opp.Id,
                Type__c = 'FS - Bank Statements');
        insert testOppAttach;

        Attachment testAttach = new Attachment();
        testAttach.body = Blob.valueOf('test blob content');
        testAttach.name = 'Test Attachment.pdf';
        testAttach.parentId = testOppAttach.Id;
        insert testAttach;

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ocrolusAddBookTest');
        mock.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();

        PageReference pageRef = Page.OpportunityAttachmentAsynch;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        UploadAttachment controller = new UploadAttachment(sc);

        controller.sendAttachmentToOcrolus();

        Test.stopTest();

    }

    @isTest
    static void testSendAttachmentToOcrolusUploadPDF() {

        Opportunity opp;
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Name FROM Opportunity WHERE Name = 'ocrolusOpp']);
        if (!oppList.isEmpty()) opp = oppList[0];

        opp.Pk__c = '1897239';
        Test.startTest();
        update opp;

        Opportunity_Attachment__c testOppAttach = new Opportunity_Attachment__c(Opportunity__c = opp.Id,
                Type__c = 'FS - Bank Statements');
        insert testOppAttach;

        Attachment testAttach = new Attachment();
        testAttach.body = Blob.valueOf('test blob content');
        testAttach.name = 'Test Attachment.pdf';
        testAttach.parentId = testOppAttach.Id;
        insert testAttach;

        StaticResourceCalloutMock mock = new StaticResourceCalloutMock();
        mock.setStaticResource('ocrolusUploadPDFTest');
        mock.setStatusCode(200);
        Test.setMock(HttpCalloutMock.class, mock);

        PageReference pageRef = Page.OpportunityAttachmentAsynch;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        UploadAttachment controller = new UploadAttachment(sc);

        controller.sendAttachmentToOcrolus();

        Test.stopTest();

    }

    @isTest
    static void testSendAttachmentToOcrolusUnsupportedFileType() {

        Opportunity opp;
        List<Opportunity> oppList = new List<Opportunity>([SELECT Id, Name FROM Opportunity WHERE Name = 'ocrolusOpp']);
        if (!oppList.isEmpty()) opp = oppList[0];

        opp.Pk__c = '1897239';
        Test.startTest();
        update opp;

        Opportunity_Attachment__c testOppAttach = new Opportunity_Attachment__c(Opportunity__c = opp.Id,
                Type__c = 'FS - Bank Statements');
        insert testOppAttach;

        Attachment testAttach = new Attachment();
        testAttach.body = Blob.valueOf('test blob content');
        testAttach.name = 'Test Attachment.txt';
        testAttach.parentId = testOppAttach.Id;
        insert testAttach;


        PageReference pageRef = Page.OpportunityAttachmentAsynch;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('id', opp.Id);
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        UploadAttachment controller = new UploadAttachment(sc);

        controller.sendAttachmentToOcrolus();

        Test.stopTest();

    }
    @isTest
    static void testest() {
    TC_Ocrolus_File_Upload_Invocable.FileUploadParam param = new TC_Ocrolus_File_Upload_Invocable.FileUploadParam ();

        TC_Ocrolus_File_Upload_Invocable inv = new TC_Ocrolus_File_Upload_Invocable ();

    }

}