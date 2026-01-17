@isTest
public with sharing class SL_DeleteCMBillableTest {
    @isTest
    static void deleteExternal() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = [SELECT Id FROM Contract__c];
        Contract_Misc_Billable__c cmb = new Contract_Misc_Billable__c(Contract__c=contract.Id);
        insert cmb;
        String actual;
        Test.StartTest();
        actual = SL_DeleteCMBillable.deleteExternalFirst('deleteExternal', cmb.Id);
        
        PageReference pageRef = Page.SL_DeleteContractMiscBillable;
        pageRef.getParameters().put('id', String.valueOf(cmb.Id));
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController sc = new ApexPages.StandardController(cmb);
        SL_DeleteCMBillable vfController = new SL_DeleteCMBillable(sc);
        vfController.goBackNotDeleted();
        vfController.goToContract();
        Test.stopTest();
        System.assert(true);
    }
    @isTest
    static void deleteInternal() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = [SELECT Id FROM Contract__c];
        Contract_Misc_Billable__c cmb = new Contract_Misc_Billable__c(Contract__c=contract.Id);
        insert cmb;
        String actual;
        Test.StartTest();
        actual = SL_DeleteCMBillable.deleteExternalFirst('deleteInternal', cmb.Id);
        Test.stopTest();
        System.assert(actual.contains('{"isSuccess": true, "contractId": "'));
    }
}