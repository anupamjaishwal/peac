/**************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description:This test is used in PEAC_CreditStipsChecklistItem Apex Class where removed stipulations from the Opportunity 
Record and deletes related Checklist Items under the 'Credit Stips' checklist.
@User Story:SAL-4872
@Created Date:April-02-2025
**************************************************************************************************************/
@isTest
public class PEAC_CreditStipsChecklistItemTest {
    
    /**
@testSetup Creates test data including Account, Opportunity, Checklist, and Checklist Items.
**/
    @testSetup
    public static void setupTestData() {
        // Create a test Account
        SL_SCTestData.createAccountAndContracts(1,1);
        List<Account> accountList = [SELECT Id,OwnerId FROM Account LIMIT 1];
        Test.StartTest();
        // Create a test Opportunity with initial stipulations
        SL_SCTestData.createOpportunitiesAndAssets(accountList[0].Id,1,1);
        Opportunity testOpportunity = [SELECT Id,Stipulations__c,OwnerId FROM Opportunity WHERE AccountId = :accountList[0].Id LIMIT 1];
        testOpportunity.Stipulations__c ='Municipal addendum;Residual Stip';
        update testOpportunity;
        
        
        // Create a Checklist Template
        TC_Origination__Checklist_Template__c checklistTemplate = new TC_Origination__Checklist_Template__c(
            Name = 'Credit Stips'
        );
        insert checklistTemplate;
        
        // Create a Checklist related to the Opportunity
        TC_Origination__Checklist__c creditStipsChecklist = new TC_Origination__Checklist__c(
            Name = 'Credit Stips',
            TC_Origination__API_Name__c = 'Credit Stips',
            TC_Origination__Checklist_Template__c = checklistTemplate.Id,
            TC_Origination__Opportunity__c = testOpportunity.Id
        );
        insert creditStipsChecklist;
        
        // Create related Checklist Items
        List<TC_Origination__Checklist_Item_with_Attachments__c> checklistItems = new List<TC_Origination__Checklist_Item_with_Attachments__c>{
            new TC_Origination__Checklist_Item_with_Attachments__c(
                TC_Origination__API_Name__c = 'Municipal addendum',
                TC_Origination__Checklist__c = creditStipsChecklist.Id,
                TC_Origination__Checklist_s_Opportunity__c = testOpportunity.Id,
                TC_Origination__Primary_Reviewer__c = FALSE,
                TC_Origination__External_Record_Id__c = '',
                TC_Origination__Included__c = FALSE,
                TC_Origination__No_Comments__c = '',
                TC_Origination__Secondary_Approval_Required__c = FALSE,
                TC_Origination__Secondary_Reviewer__c = FALSE,
                TC_Origination__Parent_Org_Verified_Date__c = NULL
            ),
                new TC_Origination__Checklist_Item_with_Attachments__c(
                    TC_Origination__API_Name__c = 'Residual Stip',
                    TC_Origination__Checklist__c = creditStipsChecklist.Id,
                    TC_Origination__Checklist_s_Opportunity__c = testOpportunity.Id,
                    TC_Origination__Primary_Reviewer__c = FALSE,
                    TC_Origination__External_Record_Id__c = '',
                    TC_Origination__Included__c = FALSE,
                    TC_Origination__No_Comments__c = '',
                    TC_Origination__Secondary_Approval_Required__c = FALSE,
                    TC_Origination__Secondary_Reviewer__c = FALSE,
                    TC_Origination__Parent_Org_Verified_Date__c = NULL
                )
                };
                    insert checklistItems;
        Test.StopTest();
    }
    
    /************************************************************************************
@Author: Vinod Rathod(LTIMindtree)
@Description: test Ensures that when a stipulation is removed from the Opportunity,
the corresponding checklist item is deleted.
*************************************************************************************/
    @isTest
    static void testDeleteRemovedChecklistItem() {
        // Retrieve the test Opportunity
        Opportunity testOpportunity = [SELECT Id, Stipulations__c FROM Opportunity LIMIT 1];
        
        // Update the Opportunity by removing 'Residual Stip' and adding 'Site Inspection'
        testOpportunity.Stipulations__c = 'Municipal addendum;Site Inspection';
        update testOpportunity;
        
        System.debug('Updated Opportunity Stipulations: ' + testOpportunity);
        
        // Retrieve remaining checklist items
        List<TC_Origination__Checklist_Item_with_Attachments__c> remainingChecklistItems = [
            SELECT Id, TC_Origination__API_Name__c, TC_Origination__Checklist_s_Opportunity__c
            FROM TC_Origination__Checklist_Item_with_Attachments__c
            WHERE TC_Origination__Checklist__r.Name = 'Credit Stips'
            AND TC_Origination__Is_Complete__c = FALSE
            AND Item_Waived_or_Cleared__c = FALSE
            AND TC_Origination__Checklist_s_Opportunity__c =:testOpportunity.Id
        ];
        
        System.debug('Remaining Checklist Items: ' + remainingChecklistItems);
        
        Set<String> remainingNames = new Set<String>();
        for (TC_Origination__Checklist_Item_with_Attachments__c item : remainingChecklistItems) {
            remainingNames.add(item.TC_Origination__API_Name__c);
        }
        
        // Assertions
        System.assertEquals(1, remainingChecklistItems.size(), 'Only "Municipal addendum" should remain.');
        System.assert(remainingNames.contains('Municipal addendum'), '"Municipal addendum" should remain.');
        System.assert(!remainingNames.contains('Residual Stip'), '"Residual Stip" should be deleted.');
    }
    
    /************************************************************************************
@Author: Vinod Rathod(LTIMindtree)
@Description: test Ensures that when Stipulations__c is set to NULL,
all related checklist items are deleted.
**************************************************************************************/
    @isTest
    static void testDeleteAllChecklistItemsWhenStipulationsNull() {
        // Retrieve the test Opportunity
        Opportunity testOpportunity = [SELECT Id, Stipulations__c FROM Opportunity LIMIT 1];
        
        // Set Stipulations__c to NULL
        testOpportunity.Stipulations__c = null;
        update testOpportunity;
        
        System.debug('Updated Opportunity Stipulations: NULL'+testOpportunity);
        
        // Retrieve remaining checklist items
        List<TC_Origination__Checklist_Item_with_Attachments__c> remainingChecklistItems = [
            SELECT Id, TC_Origination__API_Name__c, TC_Origination__Checklist_s_Opportunity__c
            FROM TC_Origination__Checklist_Item_with_Attachments__c
            WHERE TC_Origination__Checklist__r.Name = 'Credit Stips'
            AND TC_Origination__Is_Complete__c = FALSE
            AND Item_Waived_or_Cleared__c = FALSE
            AND TC_Origination__Checklist_s_Opportunity__c =:testOpportunity.Id
        ];
        
        System.debug('Remaining Checklist Items after NULL Stipulations: ' + remainingChecklistItems);
        
        // Assertions
        System.assertEquals(0, remainingChecklistItems.size(), 'All checklist items should be deleted when Stipulations is set to NULL.');
    }
}