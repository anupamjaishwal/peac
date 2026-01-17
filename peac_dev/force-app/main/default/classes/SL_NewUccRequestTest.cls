@isTest
public with sharing class SL_NewUccRequestTest {
    @isTest
    static void getObjectApiName_Account() {
        Account act = new Account(Name = 'Test act');
        insert act;
        String serializedJson;
        test.startTest();
        serializedJson = SL_NewUccRequest.getObjectAPIName(act.Id);
        test.stopTest();
        system.assert(serializedJson.contains('Account'));
    }
    @isTest
    static void getObjectApiName_Contract() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = new Contract__c(Name = '21', Status__c = 'Active');
        insert contract;
        String serializedJson;
        test.startTest();
        serializedJson = SL_NewUccRequest.getObjectAPIName(contract.Id);
        test.stopTest();
        system.assert(serializedJson.contains('Contract__c'));
    }
}