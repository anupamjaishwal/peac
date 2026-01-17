/********************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: This test class submit Loan app, rescore and submit from portal. Invoke the list of
                business process and orchestrate the callout.
@Created Date:July-22-2024 	    
*********************************************************************************************************************/
@isTest
public class PEAC_GdsScoreLoanQueuableTest {
    @testSetup
    Public static void setupTestData(){
        User adminUser = TestDataFactory.createTestUser();
        System.runAs(adminUser){
            // Create a test Account Record
            SL_SCTestData.createAccountAndContracts(1,1);
            Account testAccount = [SELECT Id,CCID__c,RecordTypeId FROM Account LIMIT 1];
            testAccount.Date_Established__c = Date.newInstance(2022,10, 1);
            testAccount.Account_State_Of_Incorporation__c = 'CO';
            testAccount.CCID__c = 'C00123';
            update testAccount;
            
            // Create a test Opportunity Record
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
                                                           Name = 'test XmlOpp ', StageName = 'Application',Payment_Amount__c=1,
                                                           RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId(),
                                                           Primary_Source__c = 'LendingTree',Requested_Amount__c = 55000,CaseCenter__c = 'L000345',PK__c ='2321602',
                                                           CustomerType__c = 'NEW',Decision_Status__c = 'PE',
                                                           UD_TMETRIX_POLICY_SCORE__c='UD_TMETRIX_POLICY_SCORE__c',UD_TMETRIX_REASON_CODE__c = 'UD_TMETRIX_REASON_CODE__c',UD_TMETRIX_REVIEW_STATUS__c= 
                                                           'UD_TMETRIX_REVIEW_STATUS__c',UD_TMETRIX_RISK_RATING__c = 'UD_TMETRIX_RISK_RATING__c',UD_TMETRIX_TRUE_IP__c = 'UD_TMETRIX_TRUE_IP__c');
            Insert testOpportunity;
           
            // Create a test Contact Reacord
            Contact con = new Contact (AccountId = testAccount.Id, FirstName = 'testGds' ,
                                       LastName = 'testbeni' , OtherStreet = 'test', OtherCity = 'test', 
                                       OtherStateCode = 'CA', OtherPostalCode = String.valueOf(111118), Title = 'title2' , 
                                       SSN__c = '112233489', BirthDate = Date.today (),
                                       Email = 'test@email' + String.valueOf(111116) + '.com', Validity_Verify__Status__c = 'Valid',
                                       OtherState='California',Ownership_Pct__c = 100);
            Insert con;
            
            // Create a test OpportunityContactRole Reacord
            OpportunityContactRole role = new OpportunityContactRole();
            role.ContactId = con.Id;
            role.OpportunityId = testOpportunity.Id;
            role.Role = 'Primary Contact';
            insert role;
            Test.startTest();
            // Create a test Guarantor Reacord
            Guarantor__c g = new Guarantor__c(
                Opportunity__c = testOpportunity.Id,
                Contact__c = con.Id,
                Account__c = testAccount.id,
                RP_PRIN_GUAR_CODE__c = 'Guarantor',
                PG_Number__c = 'PG1',
                RecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId(), 
                Type__c = 'Personal Guarantor'
            );
            Insert g;
            
        }
        Test.stopTest();
    }
    
    // Test Call GDS for final scoring/re scoring / Pull Bank details
    @isTest static void testRescoreQueueable() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_GdsScoreApiCalloutMock ());
        //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity opp = [SELECT Id,CaseCenter__c FROM Opportunity LIMIT 1];
        System.enqueueJob(new PEAC_GdsScoreLoanQueuable(Label.PEAC_Initial_Submission, opp.Id));
        Test.stopTest(); 
        PEAC_GdsScoreLoanMapper.mapSalesforceToBean (opp.Id);
    }
    // Test Call GDS for final scoring/re scoring / Pull Bank details
    @isTest static void testGdsScoreLoanMapper() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new TC_GdsScoreApiCalloutMock ());
        //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity opp = [SELECT Id,CaseCenter__c FROM Opportunity LIMIT 1];
        PEAC_GdsScoreLoanMapper.mapSalesforceToBean (opp.Id);
        Test.stopTest(); 
        
    }
    
}