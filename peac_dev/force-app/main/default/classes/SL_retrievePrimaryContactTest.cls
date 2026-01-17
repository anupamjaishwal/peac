@isTest
public with sharing class SL_retrievePrimaryContactTest {
    public static testMethod void SL_retrievePrimaryContactTest() {
        test.startTest();
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c c = [Select id from Contract__c limit 1];
        contact cc = [select id from contact];
        Contract_Contact_Role__c ccr = new Contract_Contact_Role__c();
        ccr.Contract__c = c.Id;
        ccr.Contact__c = cc.Id;
        ccr.Role__c = 'Primary Contact';
        insert ccr;
        SL_retrievePrimaryContact.getPrimaryContactsOfContract(c.Id);
        test.stopTest();
        
    }
}