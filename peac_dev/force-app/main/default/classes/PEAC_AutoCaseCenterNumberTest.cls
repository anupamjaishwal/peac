/********************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: This test class is reasponsilbe to generate case center number.
@User Story:SAL-5449
@Created Date:July-14-2024 	    
*********************************************************************************************************************/
@isTest
public class PEAC_AutoCaseCenterNumberTest {
    
    @testSetup
    public static void testSetupData() {
        
        
        // Create a test Account
        SL_SCTestData.createAccountAndContracts(1,1);
        Account testAccount = [SELECT Id,CCID__c,RecordTypeId FROM Account LIMIT 1];
        testAccount.Date_Established__c = Date.newInstance(2022,10, 1);
        testAccount.Account_State_Of_Incorporation__c = 'CO';
        testAccount.CCID__c = 'C007223';
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
        test.stopTest();
        
    }
    
    @isTest
    public static void testUpdateOppAppNumber() {
        test.startTest();
        Set<ID> oppId= new Set<ID>();
        Opportunity oldOpportunity = [SELECT Id,CaseCenter__c FROM Opportunity LIMIT 1];
        Opportunity newOpportunity = new Opportunity();
        newOpportunity.Id = oldOpportunity.Id;
        newOpportunity.CaseCenter__c = Null;
        newOpportunity.Requested_Amount__c = 25000;
        newOpportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId();
        //update newOpportunity;
        
        oppId.add(newOpportunity.ID);
        PEAC_AutoCaseCenterNumber.updateOppAppNumber(oppId);
        test.stopTest();
        Opportunity opportunityRecord = [SELECT Id,CaseCenter__c FROM Opportunity LIMIT 1];
        assert.areNotEqual(opportunityRecord.CaseCenter__c,Null,'Account Case Center number Should Not be Null');
    }
    
}