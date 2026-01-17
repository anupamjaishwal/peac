/**************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description:This test is used in PEAC_GdsScoreCardViewController Apex Class where dynamically fetching specified
fields from Opportunity, its related child objects, and parent objects (Via dot notaion) based on custom metadata.
@User Story:SAL-5547
@Created Date:July-08-2025
**************************************************************************************************************/
@isTest
public class PEAC_GdsScoreCardViewControllerTest {
    
    @isTest
    public static void testFetchScorecrdData() {
        // Create a test Account
        SL_SCTestData.createAccountAndContracts(1,1);
        Account testAccount = [SELECT Id,OwnerId FROM Account LIMIT 1];
        //testAccount.Sic = '5';
        testAccount.SicDesc = 'Test SicDescription';
        update testAccount;
        Test.StartTest();
        // Create a test Opportunity 
        SL_SCTestData.createOpportunitiesAndAssets(testAccount.Id,1,1);
        Opportunity testOpportunity = [SELECT Id,Stipulations__c,OwnerId FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        testOpportunity.Business_Rules_Not_Met__c ='Test Business Rules Not Met';
        testOpportunity.Years_in_Business__c=6;
        testOpportunity.Reasons_Not_Scored__c ='Add Description for Not Scored';
        update testOpportunity;
        
        // Create a test Financial Reacord related to the Opportunity
        Financial__c financialRecord = new Financial__c(
            Opportunity__c = testOpportunity.Id
        );
        upsert financialRecord;
        
        // Create a test Bank Information Reacord 
        Financial_Bank_Information__c bankInformationRecord = new Financial_Bank_Information__c(
            Name = 'Bank Of America',
            Bank_Account_Type__c = 'Checking',
            Bank_Account_Number_No_Masking__c = '1213123213266',
            Bank_Address__c = '530 east ohio street',
            Bank_City__c = 'Indianapolis',
            Bank_State__c = 'IN',
            Bank_Zip__c = '46204',
            Financial__c = financialRecord.Id,
            Opportunity__c = testOpportunity.Id
        );
        insert bankInformationRecord;
        
        // Create a test Bank Statement Reacord 
        Bank_Statement__c bankStatementRecord = new Bank_Statement__c(
            Amount_of_Deposits__c = 1000,
            Number_of_Deposits__c = 4,
            Opening_Balance__c = 1000,
            Daily_Average_Balance__c = 1000,
            Ending_Balance__c = 1000,
            Negative_Days__c = 3,
            NSFs__c = 5,
            Opportunity__c = testOpportunity.Id,
            Bank_Information__c = bankInformationRecord.Id
        );
        upsert bankInformationRecord;
        
        // Create a test GdsScore Reacord related to the Opportunity
        Gds_Score__c gdsScoreRecorec = new Gds_Score__c(
            D_B_Score_41__c = 23,
            Bank_Statements_Score_17__c = 12,
            Experian_Premiere_Score_26__c = 44,
           	Paynet_Score_16__c = 23,
            Loan_Score_105__c = 4,
            Industry_Preference_5__c = 5,
            Meets_Initial_Cutoff_Score__c = '2',
            LP_SF_Eligibility_Rules__c = '7',
            Opportunity__c = testOpportunity.Id
        );
        insert gdsScoreRecorec;
        
        // Create a test Webservice Field Reacord related to the Opportunity
        Webservice_Field__c webserviceFieldRecord = new Webservice_Field__c(
            LN_Total_Exposure__c = '24517',
            LS_Total_Exposure__c = '6517',
            Total_Exposure__c = '18000',
            Opportunity__c = testOpportunity.Id
        );
        insert webserviceFieldRecord;
        // Calling fetchScorecrdData Method of PEAC_GdsScoreCardViewController Apex class and passing Opportunity Id.
        Map<String, map<String,object>> result = PEAC_GdsScoreCardViewController.fetchScorecrdData(testOpportunity.Id);
        Test.StopTest();
        
        // Assertions
        system.assertNotEquals(Null,result, 'Result should not be null');
        system.assert(result.containsKey('Opportunity'), 'Result should contain Opportunity Key');
        system.assert(result.containsKey('Financial__c'), 'Result should contain Financial Key');
       
    }
    
    
    @isTest
    public static void testgetEmptyFieldsMap() {
        // Create a test Account
        SL_SCTestData.createAccountAndContracts(1,1);
        Account testAccount = [SELECT Id,OwnerId FROM Account LIMIT 1];
        //testAccount.Sic = '5';
        testAccount.SicDesc = 'Test SicDescription';
        update testAccount;
        Test.StartTest();
        // Create a test Opportunity 
        SL_SCTestData.createOpportunitiesAndAssets(testAccount.Id,1,1);
        Opportunity testOpportunity = [SELECT Id,Stipulations__c,OwnerId FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        testOpportunity.Business_Rules_Not_Met__c ='Test Business Rules Not Met';
        testOpportunity.Years_in_Business__c=6;
        testOpportunity.Reasons_Not_Scored__c ='Add Description for Not Scored';
        update testOpportunity;
        
        // Create a test Financial Reacord related to the Opportunity
        Financial__c financialRecord = new Financial__c(
            Opportunity__c = testOpportunity.Id
        );
        upsert financialRecord;
        
        // Create a test Bank Information Reacord 
        Financial_Bank_Information__c bankInformationRecord = new Financial_Bank_Information__c(
            Name = 'Bank Of America',
            Bank_Account_Type__c = 'Checking',
            Bank_Account_Number_No_Masking__c = '1213123213266',
            Bank_Address__c = '530 east ohio street',
            Bank_City__c = 'Indianapolis',
            Bank_State__c = 'IN',
            Bank_Zip__c = '46204',
            Financial__c = financialRecord.Id,
            Opportunity__c = testOpportunity.Id
        );
        insert bankInformationRecord;
        
        // Create a test Bank Statement Reacord 
        Bank_Statement__c bankStatementRecord = new Bank_Statement__c(
            Amount_of_Deposits__c = 1000,
            Number_of_Deposits__c = 4,
            Opening_Balance__c = 1000,
            Daily_Average_Balance__c = 1000,
            Ending_Balance__c = 1000,
            Negative_Days__c = 3,
            NSFs__c = 5,
            Opportunity__c = testOpportunity.Id,
            Bank_Information__c = bankInformationRecord.Id
        );
        upsert bankInformationRecord;
        
        // Create a test GdsScore Reacord related to the Opportunity
        Gds_Score__c gdsScoreRecorec = new Gds_Score__c(
            D_B_Score_41__c = 23,
            Bank_Statements_Score_17__c = 12,
            Experian_Premiere_Score_26__c = 44,
            Paynet_Score_16__c = 23,
            Loan_Score_105__c = 4,
            Industry_Preference_5__c = 5,
            Meets_Initial_Cutoff_Score__c = '2',
            LP_SF_Eligibility_Rules__c = '7',
            Opportunity__c = testOpportunity.Id
        );
        insert gdsScoreRecorec;
        
        // Calling fetchScorecrdData Method of PEAC_GdsScoreCardViewController Apex class and passing Opportunity Id.
        Map<String, map<String,object>> result = PEAC_GdsScoreCardViewController.fetchScorecrdData(testOpportunity.Id);
        Test.StopTest();
        
        // Assertions
        system.assertNotEquals(Null,result, 'Result should not be null');
        system.assert(result.containsKey('Opportunity'), 'Result should contain Opportunity Key');
        system.assert(result.containsKey('Financial__c'), 'Result should contain Financial Key');        
    }
    
}