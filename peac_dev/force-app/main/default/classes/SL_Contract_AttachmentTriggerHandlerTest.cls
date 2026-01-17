@isTest
public with sharing class SL_Contract_AttachmentTriggerHandlerTest {
    @isTest
    static void insertAndUpdate() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        Test.startTest();
        SL_SCTestData.createContractAttachment(contract.Id);
        SL_SCTestData.testCAttachments[0].Status__c = 'Approved';
        update SL_SCTestData.testCAttachments;
        Test.stopTest();
        List<Contract_Attachment__c> cAttAfter = [SELECT isFromDocGen__c FROM Contract_Attachment__c];
        system.assertEquals(true, cAttAfter[0].isFromDocGen__c);
    }
}