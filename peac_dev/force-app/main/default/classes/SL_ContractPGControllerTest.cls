@isTest
public with sharing class SL_ContractPGControllerTest {
    @testSetup static void setup(){
        SL_SCTestData.createAccountAndContracts(1, 3);
        Account thisAcc = [SELECT Id FROM Account LIMIT 1];
        Contract__c thisContract = [SELECT Id FROM Contract__c LIMIT 1];
        Contact cont = TC_SDR_TestUtility.constructContact('fn','ln','fnln@testingorg.com',thisAcc.Id);
		Contract_contact_role__c contractcontactrolecObj = new Contract_contact_role__c (
			Contact__c = cont.Id,
            Contract__c = thisContract.Id,
            Role__c = 'Personal Guarantor'
		);
		insert contractcontactrolecObj;
	}

	@isTest static void testMethod1() {
        Contract__c thisContract = [SELECT Id FROM Contract__c LIMIT 1];
		List<Contact> testList = SL_ContractPGController.getContacts(thisContract.Id);

        System.assertEquals(1, testList.size(), 'SL_ContractPGController not working as expected');
	}
}