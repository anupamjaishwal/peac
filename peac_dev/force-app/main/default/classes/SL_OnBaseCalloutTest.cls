@isTest
public class SL_OnBaseCalloutTest {
    static final String TYPE = 'Title';
    static final String ATTACHMENT_NAME = 'new.log ';
    @testSetup
    public static void prepareData(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c c = [SELECT Id FROM Contract__c];
        SL_SCTestData.createContractAttachment(c.Id);
        SL_SCTestData.createOnBaseCredentials();
        Account acc = SL_SCTestData.testAccounts[0];
        SL_SCTestData.createOpportunitiesAndAssets(acc.Id, 1, 1);
        Opportunity opp = SL_SCTestData.testOpportunities[0];

        Opportunity_Attachment__c oppAttObj = new Opportunity_Attachment__c();
        oppAttObj.Account__c = acc.Id;
        oppAttObj.Opportunity__c = opp.Id;
        oppAttObj.Description__c = 'Test';
        oppAttObj.Sent_To_Ocrolus__c  = false;
        oppAttObj.Updated_Rapport__c = false;
        oppAttObj.Type__c = 'LC - Misc';
        oppAttObj.Sent_To_OnBase__c = false;
        insert oppAttObj;
    }

    @isTest
    static void test_sendAttachmentsToOnBase() {
        Contract_Attachment__c attachmentBefore = [SELECT Id FROM Contract_Attachment__c];
        SL_UploadAttachment.saveAttachment(attachmentBefore.Id, ATTACHMENT_NAME, 'BLOB');
        Contract_Attachment__c attachmentRecord = [SELECT Id,Sent_To_OnBase__c, Updated_Rapport__c FROM Contract_Attachment__c];
        system.assert([SELECT Id FROM Contract_Attachment__c].size()> 0);
        system.assert(attachmentRecord.Id != null);
        attachmentRecord.Sent_To_OnBase__c = true;
        attachmentRecord.Updated_Rapport__c = true;
        update attachmentRecord;
        
        Test.startTest();
        
        SL_OnBaseCallout.sendAttachmentsToOnBase(attachmentRecord.Id, true, true);
        Opportunity_Attachment__c oppAttachment = [SELECT Id, Opportunity__c FROM Opportunity_Attachment__c LIMIT 1];
        SL_UploadAttachment.saveAttachment(oppAttachment.Id, ATTACHMENT_NAME, 'BLOB');
        MARLIN_OnBaseCallout.sendRapportAttachmentToOnBase(oppAttachment.Opportunity__c, true);
        MARLIN_OnBaseCallout.sendRapportAttachmentToOnBase(oppAttachment.Opportunity__c, true, new List<String>{String.valueOf(oppAttachment.Id)});
        Test.stopTest();
        System.Assert.areEqual(2, [select Id from Attachment].size(), 'one is the attachment for Contract and the other is the one for Opportunity.');
    }
    @isTest
    static void sendAttachmentToOnBase_FS() {
        Contract__c contract = [SELECT Id,Name FROM Contract__c];
        Contract_Attachment__c attachmentBefore = [SELECT Id FROM Contract_Attachment__c];
        attachmentBefore.Type_Group__c = 'Funding Stream';
        attachmentBefore.Type__c = 'FS - Additional Stipulations';
        update attachmentBefore;
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        SL_UploadAttachment ctrl = new SL_UploadAttachment();
        SL_UploadAttachment.saveAttachment(attachmentBefore.Id, ATTACHMENT_NAME, 'BLOB');
        ctrl.sendAttachmentToOnBase();
        Test.stopTest();
        system.assert(true);
    }
    
    @isTest
    static void retrieveDocument(){
        Test.setMock(HttpCalloutMock.class, new RetrieveMock());
        Contract__c c = [SELECT Id FROM Contract__c];
        String result;
        Test.startTest();
        result = SL_OnBaseCallout.retrieveDocuments(c.Id, false);
        Test.stopTest();
        System.assert(true);
    }
    @isTest
    static void retrieveDocument2(){
        Test.setMock(HttpCalloutMock.class, new RetrieveMock());
        Contract__c c = [SELECT Id, Customer__c, Infolease_Environment__c, Name,
            Customer__r.CCAN__c, RecordTypeId FROM Contract__c];
        Contract_Attachment__c attachment = [SELECT Id, sent_to_OnBase__c FROM Contract_Attachment__c];
        attachment.Sent_To_OnBase__c = true;
        update attachment;
        String result;
        Test.startTest();
        result = SL_OnBaseCallout.retrieveDocuments(c.Id, false);
        Test.stopTest();
        System.assert(true);
    }
    @isTest
    static void retrieveDocument3(){
        Test.setMock(HttpCalloutMock.class, new RetrieveMock());
        Contract__c c = [SELECT Id FROM Contract__c];
        Contract_Attachment__c attachment = [SELECT Id, sent_to_OnBase__c FROM Contract_Attachment__c];
        attachment.Sent_To_OnBase__c = true;
        update attachment;
        String result;
        Test.startTest();
        result = SL_OnBaseCallout.retrieveDocuments(c.Id, true);
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void buildOnBaseUrl(){
        Test.setMock(HttpCalloutMock.class, new RetrieveMock());
        Contract__c c = [SELECT Id, Customer__c, Infolease_Environment__c, Name,
            Customer__r.CCAN__c, RecordTypeId FROM Contract__c];
        SL_SCTestData.createInvoices(c.Customer__c, c.Id, 1, true);
        String result2;
        Test.startTest();
        result2 = SL_OnBaseCallout.buildOnBaseUrl(c, 'LC - EndUser Invoices');
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    static void test_sendOnBaseAttachment(){
              Test.startTest();

      Account acc = [SELECT Id FROM Account LIMIT 1];
      acc.RecordTypeId = SL_SCTestData.DEALER_ACC;
      update acc;
      List<OnBase_Attachment__c> lstOnBaseAttachment = new List<OnBase_Attachment__c>();
      for(Integer i=0; i<10; i++){
        OnBase_Attachment__c onBaseAttachment = new OnBase_Attachment__c();
        onBaseAttachment.Name = 'Test ' + i;
        onBaseAttachment.Type__c = 'IF-Internal';
        onBaseAttachment.Account__c = acc.Id;

        lstOnBaseAttachment.add(onBaseAttachment);
      } 

      INSERT lstOnBaseAttachment;

      List<Attachment> lstAttachment = new List<Attachment>();
      for(OnBase_Attachment__c onBaseAttachment :lstOnBaseAttachment){
        Attachment attachment = new Attachment();
        attachment.body = EncodingUtil.base64Decode(EncodingUtil.urlDecode('test', 'UTF-8'));
        attachment.name = onBaseAttachment.Name;
        attachment.parentId = onBaseAttachment.Id;

        lstAttachment.add(attachment);
      }
      
      INSERT lstAttachment;

      OnBase_Attachment__c onBaseAttachment = [SELECT Id, Account__c FROM OnBase_Attachment__c LIMIT 1];
      SL_OnBaseCallout.sendAttachmentsToOnBase(onBaseAttachment.Account__c);
      Test.stopTest();
      Assert.isTrue([SELECT Id FROM Attachment WHERE ParentId = :onBaseAttachment.Id].size() == 0, 'Attachment must be deleted');
    }
    
    @isTest
    public static void test_sendAttachmenttoHCL(){
		Test.startTest();
        Opportunity opp = [Select id from Opportunity Limit 1];
        Test.setMock(HttpCalloutMock.class, new HCLMock());
        SL_OnBaseCallout.sendOnbaseAttachemntToHCL(opp.Id);
        Test.stopTest();
    }
    
    

    public class RetrieveMock implements HttpCalloutMock {

        public HTTPResponse respond(HTTPRequest req) {
            OnBase_Credentials__c onBaseCreds = OnBase_Credentials__c.getOrgDefaults();
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'application/json');
            String keywordsForDocTypes = onBaseCreds.Keywords_For_DocTypes__c != null? onBaseCreds.Keywords_For_DocTypes__c: 'test/keywords/doctype';
            String retrieveDocs = onBaseCreds.Retrieve_Documents__c != null? onBaseCreds.Retrieve_Documents__c: 'test/retrieve/docs';
            if(req.getEndpoint().contains(keywordsForDocTypes)){
                res.setBody(SL_SCTestData.ONBASE_FAKE_RESPONSE_JSON_KEYWORDS);
            }else if(req.getEndpoint().contains(retrieveDocs)){
                String docsResponse ='{"Documents":[{"Id":3120982,"AutoName":false,"Status":"Active","CreatedBy":"API","Name":"LC - EndUser Invoices - 875551111 for MADOKA INTERNATIONAL INC - 9/30/2024","Comment":null,"DocType":"LC - EndUser Invoices","FileExtension":"img","DocPopUrl":"https://testonbase.marlinfinance.com/AppNet/docpop/docpop.aspx?docid=3120982&clienttype=HTML&chksum=3fd5c4f40221b581f1c81c97202af4f093360a08780f8ef04313d8087cf32668","FileType":"PDF","CreateDate":"09/30/2024 14:44:34","Bytes":null,"Keywords":[{"Id":0,"Name":"Application #","CurrentValue":"875551111","UpdatedValue":"","DataType":null,"DataLength":0,"KeyGroupName":"Standard Keyword Types","FullFieldRequired":false,"MaskedString":null,"StaticValue":null,"DeafultValue":null,"IsShielded":false},{"Id":0,"Name":"Name","CurrentValue":"","UpdatedValue":"","DataType":null,"DataLength":0,"KeyGroupName":"Standard Keyword Types","FullFieldRequired":false,"MaskedString":null,"StaticValue":null,"DeafultValue":null,"IsShielded":false},{"Id":0,"Name":"Contract #","CurrentValue":"","UpdatedValue":"","DataType":null,"DataLength":0,"KeyGroupName":"Standard Keyword Types","FullFieldRequired":false,"MaskedString":null,"StaticValue":null,"DeafultValue":null,"IsShielded":false},{"Id":0,"Name":"Booking Date","CurrentValue":"","UpdatedValue":"","DataType":null,"DataLength":0,"KeyGroupName":"Standard Keyword Types","FullFieldRequired":false,"MaskedString":null,"StaticValue":null,"DeafultValue":null,"IsShielded":false},{"Id":0,"Name":"Status","CurrentValue":"","UpdatedValue":"","DataType":null,"DataLength":0,"KeyGroupName":"Standard Keyword Types","FullFieldRequired":false,"MaskedString":null,"StaticValue":null,"DeafultValue":null,"IsShielded":false},{"Id":0,"Name":"Submission Date","CurrentValue":"","UpdatedValue":"","DataType":null,"DataLength":0,"KeyGroupName":"Standard Keyword Types","FullFieldRequired":false,"MaskedString":null,"StaticValue":null,"DeafultValue":null,"IsShielded":false}],"Upload_Reference_ID":null,"Notes":[],"Document_Ref_ID":null,"SendToWorkFlow":false,"DocSize":0,"PdfPopUrl":null,"keywordGroup":null,"DateStored":null,"NumberOfPages":0,"IsKeywordDuplicated":false}]}';
                res.setBody(docsResponse);
            }else if(req.getBody().contains('BW.GET.BUYOUT.QUOTES')){
                res.setBody('{"response": {"Response": { "Errors": [], "ContractNumber": "101-0003519-012", "Messages": [], "Quotes": [{ "MiscSummary": [ { "MiscDescription": "0030", "MiscTotal": "12972.34" }, { "MiscDescription": "0972", "MiscTotal": "6.00" }, { "MiscDescription": "0971", "MiscTotal": "372.55" }, { "MiscDescription": "0017", "MiscTotal": "1323.04" }, { "MiscDescription": "0086", "MiscTotal": "4464.95" }, { "MiscDescription": "0625", "MiscTotal": "15424.79" } ], "DailyFinance": "471.83", "Miscellaneous": "34563.67", "QuoteUserId": "marlin", "OriginalTerm": "60", "QuotedBy": "elivingston@peac", "Residual": "", "LateCharges": "2438.52", "UnearnedIDC": "", "SalesTax": "0.00", "CustomerReceivableBalance": "326546.43", "CommencementDate": "08/30/2021", "QuoteSeq": "1", "BuyoutDate": "02/28/2025", "QuotedTo": "", "SecurityDeposit": "", "DealerNumber": "31252.3678", "QuoteExpireDatet": "03/30/2025", "PurgeDate": "04/29/2025", "NumberOfPayments": "40.00", "DealerName": "Green Office Partner", "Status": "EXPIRED", "InvoiceDescription": "OFFICE EQUIPMENT", "UnearnedFinance": "", "ReceivableBalance": "326546.43", "Fees": "0.00", "EndingDeposit": "", "TotalBuyout": "363548.62", "DailyResidual": "0.00", "ITC": "", "QuoteType": "76", "PartialCode": "Complete Contract Buyout", "QuoteTypeDesc": "XFS-Upgrade to Return" }]}}}');
            }else{
                res.setBody(SL_SCTestData.FAKE_RESPONSE_JSON_DEFAULT);
            }
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class HCLMock implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
            HTTPResponse res = new HTTPResponse();
            //res.setHeader('Content-Type', 'application/json');
            String endpoint = '/sfdocuments/v1/createUploadDocSFOnbaseAPI/';
            if(req.getEndpoint().contains(endpoint)){
             	res.setStatusCode(200);   
            }else{
                res.setStatusCode(404);
            }
            
            
            return res;
        }
    }
    
}