@isTest
public with sharing class showContractDocumentsTest {
    @isTest
    public static void scenario1() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        SL_SCTestData.createContractAttachment(contract.Id);
        Contract_Attachment__c conattachment = [SELECT Id FROM Contract_Attachment__c];
        conattachment.Type__c = 'LC - External';
        conattachment.Type_Group__c = 'Lease Contract';
        update conattachment;
        String contractAttas = showContractDocuments.hubExecute('getContractAttachments',new List<String>{contract.Id});
        system.debug('contractAttas:'+contractAttas);
        Boolean containsId = contractAttas.contains(conattachment.Id);
        Assert.isTrue(containsId); 
    }
}