/**
 * Unit tests for SL_OtherContractsController Developed by Harsh@Silverline 11/04/2022
 */
@IsTest
public with sharing class SL_OtherContractsControllerTest {
    @TestSetup
    static void makeData(){
        SL_SCTestData.createAccountAndContracts(1, 2);
    }

    @IsTest
    static void testGetContracts(){
        Contract__c thisContract = [SELECT Id FROM Contract__c LIMIT 1];
        Test.startTest();
        List<Contract__c> conList = SL_OtherContractsController.getContractList(thisContract.Id);
        Test.stopTest();

        System.assertEquals(1, conList.size(), 'Other Contracts controller failed');
        
    }
}