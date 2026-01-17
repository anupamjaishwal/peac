/********************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: This test class is reasponsilbe for Submitting the loan application from the portal to gds
@Created Date:July-16-2024 	    
*********************************************************************************************************************/
@isTest
public class PEAC_SubmitPotralLoanApplicationTest {
    
    @testSetup
    static void setupTestData() {
        
        // Create a test Account
        SL_SCTestData.createAccountAndContracts(1,1);
        Account testAccount = [SELECT Id,CCID__c,RecordTypeId FROM Account LIMIT 1];
        testAccount.Date_Established__c = Date.newInstance(2022,10, 1);
        testAccount.Account_State_Of_Incorporation__c = 'CO';
        testAccount.CCID__c = 'C000223';
        update testAccount;
        Test.startTest();
        
        //Create test Opportunity with Portal_App_Completed__c = false
        Opportunity opp = new Opportunity (AccountId = testAccount.Id, Actual_Annual_Revenue__c = 3, Actual_Average_Daily_Balance__c = 4,
                                           Annual_Revenue__c = 2, Appeal_Information_Provided__c = 'Financial Statements', Application_Status__c = 'Manually Approved',
                                           Approved_Amount__c = 1000, Approved_Document_Delivery_Method__c = 'DocuSign Only', Average_Daily_Balance__c = 5,
                                           Billing_Attention_To__c = 'Accounts Payable', Broker_Book_Method__c = 'F',
                                           Broker_Tax_Method__c = 'F', Business_Phone__c = '1234567898', CaseCenter__c = 'L000345',
                                           CloseDate = Date.today(), Contract_Status__c = 'Active', Custom_Stipulation__c = 'A1', 
                                           Decision_Date__c = Datetime.now(), Docs_Out_Dollar__c = 13, Document_Delivery_Method__c = 'DocuSign',
                                           Equip_Code1__c = 'Air Compressors', Equipment_Cost__c = 1201,
                                           Equipment_Description__c = 'equipment 1', Final_Product_Loc__c = '1 stnarnia',
                                           Funded_Amount__c = 14, Funded_Term__c = 15, Gross_Finance__c = -1201, Income_Method__c = 'E', Invoice_Code__c = 'A',
                                           Invoice_Description__c = 'equipment 1', Late_Charge_Rate__c = 15, Lead_Invoice_Days__c = 22, Loan_Purpose__c = 'Other',
                                           Loan_Score__c = 6, Oppt_FS_Use_Of_Funds__c = 'testing purposes',
                                           Name = 'Test Portal Opp' , StageName = 'Application', Payment_Amount__c= 1,
                                           RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId(),
                                           Primary_Source__c = 'LendingTree',Portal_App_Completed__c = false,Requested_Amount__c = 55000);
        
        
        insert opp;
        
        Test.stopTest();
    }
    
    // Update Opportunity, setting Portal_App_Completed__c = true
    @isTest static void submitPortalAppTest(){
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        Opportunity oldOpportunity = [SELECT Id,CaseCenter__c,Portal_App_Completed__c FROM Opportunity Where Portal_App_Completed__c = false LIMIT 1];
        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Id = oldOpportunity.Id;
        newOpportunity.Portal_App_Completed__c = true;
        update newOpportunity;
        
        Test.stopTest();  
    }
}