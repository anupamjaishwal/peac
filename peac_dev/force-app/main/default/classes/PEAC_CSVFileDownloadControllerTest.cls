/********************************************************************************************************************
@Description: This test class validates The PEAC_CSVFileDownloadController generic calss to generate csv file 
from salesforce objects.
@Author: Vinod Rathod (LTIMindtree)
@User Story: SAL-6229
@Created Date: Feb-26-2026
*********************************************************************************************************************/
@isTest
public class PEAC_CSVFileDownloadControllerTest {
    @TestSetup
    public static void setupAssetTest () {
        //Create Account
        Account acc = new Account (Name = 'test');
        insert acc;
        PEAC_GenerateTaxMatrixBatch.isRunning = true;
        //Create a parent record Opportunity
        Opportunity opp = new Opportunity (CloseDate = Date.today()+10,Name='test',AccountId=acc.Id,Equipment_Cost__c=50000,
                                           StageName='Decision',Contract_Type__c='TL');
        insert opp;
        test.startTest();
        //Create child records (Assets) linked to that Opportunity  
        List <Asset__c> assetList = new List <Asset__c>();
        assetList.add(new Asset__c (End_User_Billing_Address__c = true, Quantity__c = 1, Equipment_Code__c = 'ATM',Usage_Dealer_Invoice_Number__c ='INV-01',
                                    Customer_PO_Number__c = 'PO-001',Equipment_Sub_Category__c = 'ATM', Opportunity__c = opp.Id));
        
       insert assetList; 
       test.StopTest();
    }
    
    @isTest
    static void testGetRecords() {
        // Retrieve the test Opportunity
        Opportunity opportunity = [SELECT Id FROM Opportunity LIMIT 1];
        
        // Define parameters for the dynamic query
        String objName = 'Asset__c';
        List<String> fieldList = new List<String>{'Id', 'End_User_Billing_Address__c', 'Quantity__c','Equipment_Code__c','Usage_Dealer_Invoice_Number__c','Customer_PO_Number__c'};
        String parentField = 'Opportunity__c';
        
        Test.startTest();
        List<SObject> results = PEAC_CSVFileDownloadController.getRecords(objName, fieldList, parentField, opportunity.Id);
        Test.stopTest();
        
        // Assertions: verify the result is not null and contains the expected number of records
        Assert.isNotNull(results, 'The result list should not be null.');
        Assert.areEqual(1, results.size(), 'Should return exactly 1 Assets linked to the Opportunity.');
    }
    
}