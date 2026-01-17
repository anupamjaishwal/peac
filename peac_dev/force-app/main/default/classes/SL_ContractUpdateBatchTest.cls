@isTest
public class SL_ContractUpdateBatchTest {
    @isTest
    static void testBatchExecution() {
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
            GL_Code__c = '0017', 
            First_Payment_Date__c = Date.today().addDays(-10), 
            Final_Payment_Date__c = Date.today().addDays(-1)
        );
        insert new List<Contract_Misc_Billable__c>{cmb1, cmb2};
        
        // Manually set the contract's Active_Service_Billable__c to false
        contract.Active_Service_Billable__c = false;
        update contract;
        
        // Verify initial state
        contract = [SELECT Id, Active_Service_Billable__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(false, contract.Active_Service_Billable__c, 'Initial Active_Service_Billable__c should be false');
        
        // Run the batch
        Test.startTest();
        SL_ContractUpdateBatch batch = new SL_ContractUpdateBatch();
        Database.executeBatch(batch);
        
        Test.stopTest();
        // Verify that Active_Service_Billable__c is set to true
        contract = [SELECT Id, Active_Service_Billable__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(true, contract.Active_Service_Billable__c, 'Active_Service_Billable__c should be true after batch execution');
        
    }
    
    @isTest
    static void testScheduledBatch() {
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
            GL_Code__c = '0017', 
            First_Payment_Date__c = Date.today().addDays(-10), 
            Final_Payment_Date__c = Date.today().addDays(-1)
        );
        insert new List<Contract_Misc_Billable__c>{cmb1, cmb2};
        
        // Manually set the contract's Active_Service_Billable__c to false
        contract.Active_Service_Billable__c = false;
        update contract;
        
        // Verify initial state
        contract = [SELECT Id, Active_Service_Billable__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(false, contract.Active_Service_Billable__c, 'Initial Active_Service_Billable__c should be false');
        
        // Schedule the batch
        Test.startTest();
        String cronExp = '0 30 0 * * ?'; // This cron expression schedules the job to run daily at 00:30
        System.schedule('Test Scheduled Contract Update Batch Job', cronExp, new SL_ScheduleContractUpdateBatch());
        SL_ScheduleContractUpdateBatch scheduledBatch = new SL_ScheduleContractUpdateBatch();
        scheduledBatch.execute(null);
        Test.stopTest();
        
        // Verify that Active_Service_Billable__c is set to true
        contract = [SELECT Id, Active_Service_Billable__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(true, contract.Active_Service_Billable__c, 'Active_Service_Billable__c should be true after scheduled batch execution');
                
    }
}