/**************************************************************************************************************
@Author:Rajesh Kumar(LTIMindtree)
@Description:PEAC_ContractContRoleTriggerHandler_Test class is used to test the business logic of
			Contract_Contact_Role__c object and code cover of PEAC_ContractContactRoleTriggerHandlerand 
			and PEAC_ContractContactRoleTriggerHelper
@User Story:DP-903	
@Created Date:June-19-2024
**************************************************************************************************************/
@isTest
Private with sharing class PEAC_ContractContRoleTriggerHandler_Test {
    /************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)    
    @Description: Testsetup method to create test data for the test class
    ************************************************************************************/
    @TestSetup
    static void createTestData(){
        SL_SCTestData.createAccountAndContracts(3,1);
        List<Contract__c> contracts = [SELECT Id, OwnerId FROM Contract__c];
        List<Contact> conts = [SELECT Id, OwnerId FROM Contact];
        Contract_Contact_Role__c contractConRole = new Contract_Contact_Role__c();
        contractConRole.Contract__c = contracts[0].id;
        contractConRole.Contact__c = conts[0].id;
        contractConRole.Role__c = PEAC_ConstantClass.PRIMARY_CONTACT;
        test.StartTest();
        insert contractConRole;//Insert Contract Contact Role record
        test.StopTest();
        List<Contract_Contact_Role__c> contRolelInsList = [SELECT Id, Contact__c FROM Contract_Contact_Role__c];
        Assert.areEqual(1, contRolelInsList.size(), 'Contract contact role is not created');// Positive test case
    }
    /************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)     
    @Description: updatePrimaryContactTest method is testing the Primary Contact update
    on contract records
    ************************************************************************************/
    @isTest
    static void updatePrimaryContactTest()
    {
        List<Contract__c> contractList = [SELECT Id, OwnerId FROM Contract__c];
        List<Contact> contactList = [SELECT Id, OwnerId FROM Contact];
        List<Contract_Contact_Role__c> contRoleList = [SELECT Id, Contact__c FROM Contract_Contact_Role__c];
        
        contRoleList[0].Contact__c = contactList[1].id;
        test.StartTest();
        Update contRoleList;//Update Contract Contact Role with contact
        test.StopTest();
        List<Contract_Contact_Role__c> contRoleUptList = [SELECT Id, Contact__c FROM Contract_Contact_Role__c WHERE ID =:contRoleList[0].ID];
        Assert.areEqual(contRoleUptList[0].Contact__c, contRoleList[0].Contact__c, 'Contract contact role is not updated with contact');// Positive test case
        
    }
    /************************************************************************************
    @Author:Rajesh Kumar(LTIMindtree)     
    @Description: deletePrimaryContactTest method is testing the Primary Contact
    deletion/update on contract records
    ************************************************************************************/
    @isTest
    static void deletePrimaryContactTest()
    {
        List<Contract_Contact_Role__c> contRoleList = [SELECT Id, Contact__c FROM Contract_Contact_Role__c];
        test.StartTest();
        delete contRoleList;//Delete COntract Contact Role 
        test.StopTest();
        List<Contract_Contact_Role__c> contRoleDelList = [SELECT Id, Contact__c FROM Contract_Contact_Role__c];
        Assert.areEqual(0, contRoleDelList.size(), 'Contract contact role is not deleted');
    }
    
}