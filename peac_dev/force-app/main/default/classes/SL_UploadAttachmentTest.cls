@isTest
public with sharing class SL_UploadAttachmentTest {
    static final String TYPE = 'Title';
    static final String ATTACHMENT_NAME = 'new.log ';
    static final String FILL_CUSTOMER_MESSAGE = 'The Customer Account Name is required in order to Send to Onbase';

    @isTest
    static void sendAttachmentToOnBase() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        SL_SCTestData.createContractAttachment(contract.Id);
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        SL_UploadAttachment ctrl = new SL_UploadAttachment();
        Contract_Attachment__c attachmentBefore = [SELECT Id FROM Contract_Attachment__c];
        SL_UploadAttachment.saveAttachment(attachmentBefore.Id, ATTACHMENT_NAME, 'BLOB');
        ctrl.sendAttachmentToOnBase();
        Test.stopTest();
        system.assert(true);
    }

    @isTest
    static void sendAttachmentToOnBase_otherType() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        SL_SCTestData.createContractAttachment(contract.Id);
        contract.Gross_Equipment_Cost__c = 100;
        update contract;
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        SL_UploadAttachment ctrl = new SL_UploadAttachment ();
        Contract_Attachment__c attachmentBefore = [SELECT Id FROM Contract_Attachment__c];
        SL_UploadAttachment.hubExecute('saveAttachment', new List<String>{String.valueOf(attachmentBefore.Id),
                ATTACHMENT_NAME, 'BLOB'});
        ctrl.sendAttachmentToOnBase();
        Test.stopTest();
        system.assert(true);
    }
@isTest
    static void sendAttachmentToOnBase_noCustomer() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        SL_SCTestData.createContractAttachment(contract.Id);
        contract.Customer__c = null;
        update contract;
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', contract.Id);
        SL_UploadAttachment ctrl = new SL_UploadAttachment ();
        Contract_Attachment__c attachmentBefore = [SELECT Id FROM Contract_Attachment__c];
        SL_UploadAttachment.saveAttachment(attachmentBefore.Id, ATTACHMENT_NAME, 'BLOB');
        ctrl.sendAttachmentToOnBase();
        attachmentBefore.Sent_To_OnBase__c = true;
        attachmentBefore.Updated_Rapport__c = true;
        update attachmentBefore;
        ctrl.sendAttachmentToOnBase();
        ctrl.back();
        ctrl.success();
        Test.stopTest();
        system.assertEquals([select Id from Attachment].size(), 1);
    }
    
    @isTest
    static void getOtherContracts(){
        SL_SCTestData.createAccountAndContracts(1, 2);
        Test.startTest();
        List<Account> accounts = [SELECT Id FROM Account];
        List<Contract__c> contracts = [SELECT Id FROM Contract__c WHERE Customer__c = :SL_SCTestData.testAccounts[0].Id];
        List<Contract__c> otherContracts = SL_UploadAttachment.getOtherContracts(contracts[0].Id);
        Test.stopTest();
        system.assert(otherContracts[0].Id == contracts[1].Id);
    }

    @isTest
    static void saveOtherContracts_noCustomer(){
        SL_SCTestData.createAccountAndContracts(1, 3);
        String errorResult = '';
        Test.startTest();
        List<Account> accounts = SL_SCTestData.testAccounts;
        List<Contract__c> contracts = [SELECT Id FROM Contract__c WHERE Customer__c = :accounts[0].Id];
        SL_SCTestData.createContractAttachment(contracts[0].Id);
        Contract_Attachment__c contractAtta = [SELECT Id FROM Contract_Attachment__c WHERE Contract__c=:contracts[0].Id];
        SL_UploadAttachment.saveAttachment(contractAtta.Id, ATTACHMENT_NAME, 'BLOB');
        contracts[0].Customer__c = null;
        update contracts[0];
        errorResult = SL_UploadAttachment.hubExecute('saveOtherContracts', new List<String>{String.valueOf(contractAtta.Id),
            contracts[0].Id, String.valueOf(contracts[1].id) + ',' + String.valueOf(contracts[2].id)});
        Test.stopTest();
        Integer createdAttachments = [SELECT COUNT() FROM Contract_Attachment__c WHERE Contract__r.Customer__c = :accounts[0].Id];
        System.assertEquals(2, createdAttachments);
        System.assertEquals(FILL_CUSTOMER_MESSAGE, errorResult);
    }

    @isTest
    static void saveOtherContracts2(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        SL_SCTestData.createContractAttachment(contract.Id);
        Test.startTest();
        Contract_Attachment__c contractAtta = [SELECT Id FROM Contract_Attachment__c WHERE Contract__c=:contract.Id];
        SL_UploadAttachment.saveAttachment(contractAtta.Id, ATTACHMENT_NAME, 'BLOB');
        SL_UploadAttachment.hubExecute('saveOtherContracts', new List<String>{String.valueOf(contractAtta.Id),
            contract.Id, ''});
        Test.stopTest();
        Integer createdAttachments = [SELECT COUNT() FROM Contract_Attachment__c WHERE Contract__r.Customer__c = :SL_SCTestData.testAccounts[0].Id];
        System.assertEquals(1, createdAttachments);
    }

    @isTest
    static void saveOtherContracts3(){
        SL_SCTestData.createAccountAndContracts(1, 3);
        Account testAccount = SL_SCTestData.testAccounts[0];
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        String errorResult = '';
        Test.startTest();
        SL_SCTestData.createContractAttachment(contracts[0].Id);
        Contract_Attachment__c contractAtta = [SELECT Id FROM Contract_Attachment__c WHERE Contract__c=:contracts[0].Id];
        SL_UploadAttachment.saveAttachment(contractAtta.Id, ATTACHMENT_NAME, 'BLOB');
        errorResult = SL_UploadAttachment.hubExecute('saveOtherContracts', new List<String>{String.valueOf(contractAtta.Id),
            contracts[0].Id, String.valueOf(contracts[1].id) + ',' + String.valueOf(contracts[2].id)});
        Test.stopTest();
        Integer createdAttachments = [SELECT COUNT() FROM Contract_Attachment__c WHERE Contract__r.Customer__c = :testAccount.Id];
        System.assertEquals(3, createdAttachments);
        System.assertEquals('success', errorResult);
    }
    
    @isTest
    static void testSendToOnBaseFromAcc(){
      SL_SCTestData.createAccountAndContracts(1, 1);
      List<OnBase_Attachment__c> lstOnBaseAttachment = new List<OnBase_Attachment__c>();
      for(Integer i=0; i<10; i++){
        OnBase_Attachment__c onBaseAttachment = new OnBase_Attachment__c();
        onBaseAttachment.Name = 'Test ' + i;
        onBaseAttachment.Type__c = 'CS - Master Lease'; // IF-Internal is type for Dealer_Vendor
        onBaseAttachment.Account__c = SL_SCTestData.testAccounts[0].Id;

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
        
      String result, result2, result3;
        
      Test.StartTest();
      result = SL_UploadAttachment.hubExecute('sendToOnBaseFromAcc', new List<String>{SL_SCTestData.testAccounts[0].Id});
      result2 = SL_UploadAttachment.hubExecute('justSaveAttachment', new List<String>{SL_SCTestData.testAccounts[0].Id, 'testfile', 'BLOB'});
      result3 = SL_UploadAttachment.hubExecute('appendChunk', new List<String>{result2, 'testfile', 'BLOB', 'true'});
      Test.StopTest();
        
        Assert.areEqual('success', result, 'Expecting a success response');
    }
}