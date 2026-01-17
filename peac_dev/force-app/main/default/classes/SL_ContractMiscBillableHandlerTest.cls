@isTest
public class SL_ContractMiscBillableHandlerTest {
    @isTest
    static void testAfterInsert() {
        // Create accounts and contracts
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Contract__c> contracts = [SELECT Id FROM Contract__c];
        Contract__c contract = contracts[0];
        
        // Create Contract_Misc_Billable__c records
        Contract_Misc_Billable__c cmb1 = new Contract_Misc_Billable__c(
            Contract__c = contract.Id, 
            GL_Code__c = '0017', 
            First_Payment_Date__c = Date.today().addDays(-10), 
            Final_Payment_Date__c = Date.today().addDays(10)
        );
        Contract_Misc_Billable__c cmb2 = new Contract_Misc_Billable__c(
            Contract__c = contract.Id, 
            GL_Code__c = '0020', 
            First_Payment_Date__c = Date.today().addDays(-10), 
            Final_Payment_Date__c = Date.today().addDays(10)
        );
        insert new List<Contract_Misc_Billable__c>{cmb1, cmb2};
        
        // Verify that Active_Service_Billable__c is set to true
        Contract__c updatedContract = [SELECT Id, Active_Service_Billable__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(true, updatedContract.Active_Service_Billable__c, 'Active_Service_Billable__c should be true');
    }
    
    @isTest
    static void testAfterUpdateGLCodeChange() {
        // Create accounts and contracts
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Contract__c> contracts = [SELECT Id FROM Contract__c];
        Contract__c contract = contracts[0];
        
        // Create and insert a Contract_Misc_Billable__c record
        Contract_Misc_Billable__c cmb = new Contract_Misc_Billable__c(
            Contract__c = contract.Id, 
            GL_Code__c = '0017', 
            First_Payment_Date__c = Date.today().addDays(-10), 
            Final_Payment_Date__c = Date.today().addDays(10)
        );
        insert cmb;
        
        // Update the GL_Code__c to a different value
        cmb.GL_Code__c = '0020';
        update cmb;
        
        // Verify that Active_Service_Billable__c is set to false
        Contract__c updatedContract = [SELECT Id, Active_Service_Billable__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(false, updatedContract.Active_Service_Billable__c, 'Active_Service_Billable__c should be false');
    }
    
    @isTest
    static void testAfterDelete() {
        // Create accounts and contracts
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Contract__c> contracts = [SELECT Id FROM Contract__c];
        Contract__c contract = contracts[0];
        
        // Create and insert Contract_Misc_Billable__c records
        Contract_Misc_Billable__c cmb1 = new Contract_Misc_Billable__c(
            Contract__c = contract.Id, 
            GL_Code__c = '0017', 
            First_Payment_Date__c = Date.today().addDays(-10), 
            Final_Payment_Date__c = Date.today().addDays(10)
        );
        Contract_Misc_Billable__c cmb2 = new Contract_Misc_Billable__c(
            Contract__c = contract.Id, 
            GL_Code__c = '0020', 
            First_Payment_Date__c = Date.today().addDays(-10), 
            Final_Payment_Date__c = Date.today().addDays(10)
        );
        insert new List<Contract_Misc_Billable__c>{cmb1, cmb2};
        
        // Delete the Contract_Misc_Billable__c record with GL_Code__c = '0017'
        delete cmb1;
        
        // Verify that Active_Service_Billable__c is set to false
        Contract__c updatedContract = [SELECT Id, Active_Service_Billable__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(false, updatedContract.Active_Service_Billable__c, 'Active_Service_Billable__c should be false');
    }
    
    @isTest
    static void testAfterUpdateActiveChange() {
        // Create accounts and contracts
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Contract__c> contracts = [SELECT Id FROM Contract__c];
        Contract__c contract = contracts[0];
        
        // Create and insert a Contract_Misc_Billable__c record
        Contract_Misc_Billable__c cmb = new Contract_Misc_Billable__c(
            Contract__c = contract.Id, 
            GL_Code__c = '0017', 
            First_Payment_Date__c = Date.today().addDays(-10), 
            Final_Payment_Date__c = Date.today().addDays(10)
        );
        insert cmb;
        
        // Update the Final_Payment_Date__c to a past date to make Active__c false
        cmb.Final_Payment_Date__c = Date.today().addDays(-1);
        update cmb;
        
        // Verify that Active_Service_Billable__c is set to false
        Contract__c updatedContract = [SELECT Id, Active_Service_Billable__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(false, updatedContract.Active_Service_Billable__c, 'Active_Service_Billable__c should be false');
    }
}