@IsTest
public class SL_CaseTriggerHelperTest {

    @IsTest
    static void testGetContractNumber() {
        String contractNumbers = 'Contract1, Contract2';
        Set<String> result = SL_CaseTriggerHelper.getContractNumber(contractNumbers);
    }

    @IsTest
    static void testGetRelatedContract() {
        SL_SCTestData.createAccountAndContracts(1, 2); // Create 1 Account and 2 Contracts

        Set<String> contractNames = new Set<String>{'401-1111112-210', '401-1111113-210'};
        Map<String, Contract__c> result = SL_CaseTriggerHelper.getRelatedContract(contractNames);
    }

    @IsTest
    static void testSetXBSValue() {
        SL_SCTestData.createAccountAndContracts(1, 1); // Create 1 Account and 1 Contract

        List<Contract__c> contracts = [SELECT Id, Name FROM Contract__c WHERE Name = '401-1111112-210'];
        
        Case caseRec = new Case(Web_Contracts__c = '401-1111112-210');
        insert caseRec;

        Set<String> contractNames = new Set<String>{'401-1111112-210'};
        Map<String, Contract__c> mapContracts = SL_CaseTriggerHelper.getRelatedContract(contractNames);

        SL_CaseTriggerHelper.setXBSValue(caseRec, mapContracts);
    }
}