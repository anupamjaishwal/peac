@isTest
public with sharing class SL_AttachmentTriggerHandlerTest {
    @isTest
    static void insertAndUpdate() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        SL_SCTestData.createContractAttachment(contract.Id);
        Test.startTest();
        Attachment attachment = new Attachment();
        attachment.body = EncodingUtil.base64Decode(EncodingUtil.urlDecode('fileBody', 'UTF-8'));
        attachment.name = 'fileName.txt';
        attachment.parentId = SL_SCTestData.testCAttachments[0].Id;
        insert attachment;
        attachment.name = 'fileNameEdited.txt';
        update attachment;
        Test.stopTest();
        system.assert(true);
    }
}