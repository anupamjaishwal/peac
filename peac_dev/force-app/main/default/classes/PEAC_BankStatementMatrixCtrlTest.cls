/******************************************************************************************************************************
@Author : Vinod Rathod(LTIMindtree)
@Description : This test class verifies that getBankData returns the expected grouped matrix output for the LWC component.
@User Story : SAL-5551
@Created Date: November-27-2025 	    
*******************************************************************************************************************************/

@isTest
public class PEAC_BankStatementMatrixCtrlTest {
    
    @isTest
    public static void testgetBankData(){
        // Create a test Account
        SL_SCTestData.createAccountAndContracts(1,1);
        Account testAccount = [SELECT Id,OwnerId FROM Account LIMIT 1];
        testAccount.SicDesc = 'Test SicDescription';
        update testAccount;
        
        // Create a test Opportunity 
        SL_SCTestData.createOpportunitiesAndAssets(testAccount.Id,1,1);
        Opportunity testOpportunity = [SELECT Id,Stipulations__c,OwnerId FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];
        testOpportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId();
        testOpportunity.Business_Rules_Not_Met__c ='Test Business Rules Not Met';
        testOpportunity.Years_in_Business__c=6;
        testOpportunity.Requested_Amount__c = 55000;
        testOpportunity.Reasons_Not_Scored__c ='Add Description for Not Scored';
        update testOpportunity;
        
        // Create a test Financial Reacord related to the Opportunity
        Financial__c financialRecord = new Financial__c(
            Opportunity__c = testOpportunity.Id
        );
        insert financialRecord;
        
        // Create a test Bank Information Reacord 
        Financial_Bank_Information__c primaryBankInformationRecord = new Financial_Bank_Information__c(
            Name = 'Bank Of America',
            Bank_Account_Type__c = 'Checking',
            Bank_Account_Number_No_Masking__c = '1213123213266',
            Bank_Address__c = '530 east ohio street',
            Bank_City__c = 'Indianapolis',
            Bank_State__c = 'IN',
            Bank_Zip__c = '46204',
            Indicator__c = 'Primary',
            Financial__c = financialRecord.Id
            
        );
        insert primaryBankInformationRecord;
        
        Financial_Bank_Information__c nonebankInformationRecord = new Financial_Bank_Information__c(
            Name = 'Bank Of America',
            Bank_Account_Type__c = 'Checking',
            Bank_Account_Number_No_Masking__c = '1213123213266',
            Bank_Address__c = '530 east ohio street',
            Bank_City__c = 'Indianapolis',
            Bank_State__c = 'IN',
            Bank_Zip__c = '46204',
            Indicator__c = '-',
            Financial__c = financialRecord.Id
            
        );
        insert nonebankInformationRecord;
        
        // Create a test Bank Statement Reacord 
        Bank_Statement__c primarybankStatementRecord = new Bank_Statement__c(
            Amount_of_Deposits__c = 1000,
            Number_of_Deposits__c = 4,
            Opening_Balance__c = 1000,
            Daily_Average_Balance__c = 1000,
            Ending_Balance__c = 1000,
            Negative_Days__c = 3,
            NSFs__c = 5,
            Month__c = Date.newInstance(2025, 11, 27),
            Exclude__c = false,
            Bank_Information__c = primaryBankInformationRecord.Id
        );
        Insert primarybankStatementRecord;
        
        Bank_Statement__c nonebankStatementRecord = new Bank_Statement__c(
            Amount_of_Deposits__c = 1000,
            Number_of_Deposits__c = 4,
            Opening_Balance__c = 1000,
            Daily_Average_Balance__c = 1000,
            Ending_Balance__c = 1000,
            Negative_Days__c = 3,
            NSFs__c = 5,
            Month__c = Date.newInstance(2025, 11, 27),
            Exclude__c = false,
            Bank_Information__c = nonebankInformationRecord.Id
        );
        Insert nonebankStatementRecord;
        
        Test.StartTest();
        // Calling getBankData Method of PEAC_BankStatementMatrixCtrl Apex class and passing Opportunity Id.
        List<Map<String, Object>> result = PEAC_BankStatementMatrixCtrl.getBankData(testOpportunity.Id);
        Test.StopTest();
        
        system.assert(result.size() > 0, 'Result should contain section');
        system.assertEquals('Primary Bank Statement', result[0].get('header'));
    }
}