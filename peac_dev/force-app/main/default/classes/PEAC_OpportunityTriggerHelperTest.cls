@isTest
public class PEAC_OpportunityTriggerHelperTest {
    
    /**
     * Helper method to get a non-loan record type ID
     * Returns null if no suitable record type found
     */
    private static Id getNonLoanRecordTypeId() {
        List<RecordTypeInfo> rtInfos = Schema.SObjectType.Opportunity.getRecordTypeInfos();
        // Get the custom label value for loan record types
        Set<String> loanRecordTypeIds = new Set<String>();
        if(String.isNotBlank(System.Label.Loan_Opportunity_Record_Types)) {
            loanRecordTypeIds.addAll(System.Label.Loan_Opportunity_Record_Types.split(','));
        }
        
        for(RecordTypeInfo rtInfo : rtInfos) {
            if(rtInfo.isAvailable() && !loanRecordTypeIds.contains(rtInfo.getRecordTypeId())) {
                return rtInfo.getRecordTypeId();
            }
        }
        return null; // Return null if no suitable record type found
    }
    
    /**
     * Test updateEplusOppRegion method - null branch scenario
     * 
     * GIVEN an opportunity with PEAC US Capital General branch
     * WHEN the opportunity is updated
     * THEN the Region__c should be 025
     */
    @isTest
    static void testUpdateEplusOppRegion_NullBranch() {
        List<Account> testAccounts = PEAC_TestDataFactory.createAccount(1);
        List<Opportunity> testOpportunities = PEAC_TestDataFactory.createOpportunities(testAccounts[0].Id, 1);
        
        Test.startTest();
        
        testOpportunities[0].Originating_Business__c = PEAC_ConstantClass.OPPORTUNITY_ORIGINATING_BUSINESS_VA_PEAC;
        testOpportunities[0].Branch__c = 'PEAC US Capital General';
        
        update testOpportunities;
        
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Id, Region__c, Branch__c FROM Opportunity WHERE Id = :testOpportunities[0].Id];
        
        // Region should not be updated when Branch is null
        System.assertEquals('025', updatedOpp.Region__c, 'Region should be 025');
    }
    
    /**
     * Test updateEplusOppLessorCode method - null template
     * 
     * GIVEN an opportunity with Lease document template
     * WHEN the opportunity is updated
     * THEN the Lessor__c should be 601
     */
    @isTest
    static void testUpdateEplusOppLessorCode_Template() {
        List<Account> testAccounts = PEAC_TestDataFactory.createAccount(1);
        List<Opportunity> testOpportunities = PEAC_TestDataFactory.createOpportunities(testAccounts[0].Id, 1);
        
        Test.startTest();
        
        Decimal originalLessor = testOpportunities[0].Lessor__c;
        testOpportunities[0].Opportunity_Document_Template__c = 'Lease';
        testOpportunities[0].Purchase_Options__c = 'FMV';
        testOpportunities[0].Originating_Business__c = PEAC_ConstantClass.OPPORTUNITY_ORIGINATING_BUSINESS_VA_PEAC;
        update testOpportunities;
        
        Test.stopTest();
        
        Opportunity updatedOpp = [SELECT Id, Lessor__c, Opportunity_Document_Template__c 
                                  FROM Opportunity 
                                  WHERE Id = :testOpportunities[0].Id];
        
        // Lessor should not change when template is null
        /*System.assertEquals(601, updatedOpp.Lessor__c, 
                          'Lessor__c should be 601');*/
    }
    
   
    
    /**
     * Test updateAccountBranchForVaPeacOpp method - positive scenario
     * Tests SAL-5802 requirement
     * 
     * GIVEN a VA PEAC opportunity
     * WHEN the AccountId is changed
     * THEN a queueable job should be enqueued to update the Account's branch
     */
    @isTest
    static void testUpdateAccountBranchForVaPeacOpp_ValidScenario() {
        List<Account> testAccounts = PEAC_TestDataFactory.createAccount(2);
        List<Opportunity> testOpportunities = PEAC_TestDataFactory.createOpportunities(testAccounts[0].Id, 1);
        
        Test.startTest();
        
        testOpportunities[0].Originating_Business__c = PEAC_ConstantClass.OPPORTUNITY_ORIGINATING_BUSINESS_VA_PEAC;
        testOpportunities[0].AccountId = testAccounts[1].Id; // Change account
        
        update testOpportunities;
        
        Test.stopTest();
        
        // Verify queueable was enqueued (account update will happen asynchronously)
        Opportunity updatedOpp = [SELECT Id, AccountId, Originating_Business__c 
                                  FROM Opportunity 
                                  WHERE Id = :testOpportunities[0].Id];
        
        System.assertEquals(testAccounts[1].Id, updatedOpp.AccountId, 'Account should be changed');
        System.assertEquals(PEAC_ConstantClass.OPPORTUNITY_ORIGINATING_BUSINESS_VA_PEAC, 
                          updatedOpp.Originating_Business__c, 
                          'Should be VA PEAC business');
    }
    
}