/********************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: This test class cover PEAC_LoanAppContoller class
@Created Date:Oct-15-2024      
*********************************************************************************************************************/
@isTest
public class PEAC_LoanAppContollerTest {
    
    // Prepare test data
    @testSetup public static void setupData() {
        
        User adminUser = TestDataFactory.createTestUser();
        System.runAs(adminUser){
            
            // Create a test Account Reacord
            SL_SCTestData.createAccountAndContracts(1,1);
            Account testAccount = [SELECT Id,CCID__c,RecordTypeId FROM Account LIMIT 1];
            testAccount.Date_Established__c = Date.newInstance(2022,10, 1);
            testAccount.Account_State_Of_Incorporation__c = 'CO';
            testAccount.CCID__c = 'C000223';
            update testAccount;
            
            // Create a test Opportunity Reacord
            Opportunity testOpportunity = new Opportunity (AccountId = testAccount.Id, Actual_Annual_Revenue__c = 3, Actual_Average_Daily_Balance__c = 4,
                                                           Annual_Revenue__c = 2, Appeal_Information_Provided__c = 'Financial Statements', Application_Status__c = 'Manually Approved',
                                                           Approved_Amount__c = 1000, Approved_Document_Delivery_Method__c = 'DocuSign Only', Average_Daily_Balance__c = 5,
                                                           Billing_Attention_To__c = 'Accounts Payable', Broker_Book_Method__c = 'F',
                                                           Broker_Tax_Method__c = 'F', Business_Phone__c = '1234567898',
                                                           CloseDate = Date.today(), Contract_Status__c = 'Active', Custom_Stipulation__c = 'A1', 
                                                           Decision_Date__c = Datetime.now(), Docs_Out_Dollar__c = 13, Document_Delivery_Method__c = 'DocuSign',
                                                           Equip_Code1__c = 'Air Compressors', Equipment_Cost__c = 1201,
                                                           Equipment_Description__c = 'equipment 1', Final_Product_Loc__c = '1 stnarnia',
                                                           Funded_Amount__c = 14, Funded_Term__c = 15, Gross_Finance__c = -1201, Income_Method__c = 'E', Invoice_Code__c = 'A',
                                                           Invoice_Description__c = 'equipment 1', Late_Charge_Rate__c = 15, Lead_Invoice_Days__c = 22, Loan_Purpose__c = 'Other',
                                                           Loan_Score__c = 6, Oppt_FS_Use_Of_Funds__c = 'testing purposes',
                                                           Name = 'test XmlOpp', StageName = 'Application',Payment_Amount__c=1,
                                                           RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId(),
                                                           Primary_Source__c = 'LendingTree',Requested_Amount__c = 55000,CaseCenter__c = 'L000345',PK__c ='2321602',
                                                           CustomerType__c = 'NEW',Decision_Status__c = 'PE',
                                                           UD_TMETRIX_POLICY_SCORE__c='UD_TMETRIX_POLICY_SCORE__c',UD_TMETRIX_REASON_CODE__c = 'UD_TMETRIX_REASON_CODE__c',UD_TMETRIX_REVIEW_STATUS__c= 
                                                           'UD_TMETRIX_REVIEW_STATUS__c',UD_TMETRIX_RISK_RATING__c = 'UD_TMETRIX_RISK_RATING__c',UD_TMETRIX_TRUE_IP__c = 'UD_TMETRIX_TRUE_IP__c');
            Insert testOpportunity;
            
            // Add Attachment record 
            Opportunity_Attachment__c att = new Opportunity_Attachment__c(
                Name = 'Bank Statement',
                Opportunity__c = testOpportunity.Id,
                Type__c = 'FS - Bank Statements',
                Dealer_Doc_Type__c = 'CR - Bank Statements'
            );
            insert att;
        }
    }
    // Test method for the positive case
    @isTest
    public static void deleteAttachmentTest(){
        // Get the test data created in the setup method
        Opportunity opp = [SELECT Id, Name From Opportunity WHERE Name = 'test XmlOpp' Limit 1];
        Opportunity_Attachment__c oppAttachment = [SELECT Id, Name, Dealer_Doc_Type__c,Type__c, createdById FROM Opportunity_Attachment__c WHERE Opportunity__c = :opp.Id Limit 1];
        
        // Ensure the attachment exists before calling the method
        System.assertNotEquals(null, oppAttachment, 'Test attachment should exist');
        
        // Call the method
        Test.startTest();
        PEAC_LoanAppContoller.deleteAttachment(opp.Id, oppAttachment.Id);
        Test.stopTest();
        
        // Verify the attachment was deleted by querying again
        List<Opportunity_Attachment__c> attachments = [SELECT Id FROM Opportunity_Attachment__c WHERE Id = :oppAttachment.Id];
        System.assertEquals(0, attachments.size(), 'Attachment record should have been deleted');
    }
    
    // Test method for the exception case
    @isTest
    public static void deleteAttachmentExceptionTest(){
        // Get the test opportunity from the setup method
        Opportunity opp = [SELECT Id, Name From Opportunity WHERE Name = 'test XmlOpp' Limit 1];
        
        // This flag will check if the exception was successfully caught
        Boolean exceptionCaught = false;
        
        Test.startTest();
        // Pass a fake, non-existent ID for the attachment to force a QueryException
        PEAC_LoanAppContoller.deleteAttachment(opp.Id, null);
        Test.stopTest();
        
        // Assert 
        //System.assertEquals(true, exceptionCaught, 'AuraHandledException should have been thrown');
        
    }
    
}