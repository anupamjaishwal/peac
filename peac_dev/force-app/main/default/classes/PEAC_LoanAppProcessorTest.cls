/********************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: This test class submit Loan application, rescore and submit from portal. 
              Invoke the list of business process and orchestrate the callout.
@Created Date:July-18-2024      
*********************************************************************************************************************/
@isTest
public class PEAC_LoanAppProcessorTest {
    
    @testSetup
    Public static void setupTestData(){
        // Create a test Account
        SL_SCTestData.createAccountAndContracts(1,1);
        Account testAccount = [SELECT Id,CCID__c,RecordTypeId FROM Account LIMIT 1];
        testAccount.Date_Established__c = Date.newInstance(2022,10, 1);
        testAccount.Account_State_Of_Incorporation__c = 'CO';
        testAccount.CCID__c = null;
        update testAccount;
        Test.StartTest();
        // Create a test Opportunity 
        SL_SCTestData.createOpportunitiesAndAssets(testAccount.Id,1,1);
        Opportunity testOpportunity = [SELECT Id,OwnerId,RecordTypeId,CaseCenter__c FROM Opportunity LIMIT 1];
        testOpportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId();
        testOpportunity.Requested_Amount__c = 55000;
        testOpportunity.CaseCenter__c = null;
        update testOpportunity;
        Test.stopTest();
    }
    @isTest static void testInitialSubmission() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        System.enqueueJob(new PEAC_LoanAppProcessor(Label.PEAC_Initiate_Loan_App_to_GDS, opp.Id));
        Test.stopTest();
        
        Opportunity updated = [SELECT CaseCenter__c FROM Opportunity
                               WHERE Id = :opp.Id];
        System.assertNotEquals(null, updated.CaseCenter__c);
    }
    @isTest static void testRunGDSRescoreEnqueue() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        PEAC_LoanAppProcessor.runGDSRescore(opp.Id);
        Test.stopTest();
        
    }
    @isTest static void testGetAccountIds() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        PEAC_LoanAppProcessor.getAccountIds(opp.Id);
        Test.stopTest();
        
    }
    @isTest static void testOcrolusExecution() {
        Opportunity opp = [SELECT Id,Pk__c FROM Opportunity LIMIT 1];
        opp.Pk__c = '2321602';
        Update opp;
        Test.startTest();
        //PEAC_LoanAppProcessor.ocrolusExecution(opp.Id);
        Test.stopTest();
        
    }
    @isTest static void testPullBankDetails() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        PEAC_LoanAppProcessor.pullBankDetails(opp.Id);
        Test.stopTest();
    }
    
    @isTest static void testGDSInfolease() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        EventBus.publish (new GDS_Action__e  (Record_Id__c  = opp.Id,Action__c = Label.TC_Gds_Infolease));
        EventBus.publish (new GDS_Action__e  (Record_Id__c  = opp.Id,Action__c = Label.TC_Gds_GdsScore));
        EventBus.publish (new GDS_Action__e  (Record_Id__c  = opp.Id,Action__c = Label.TC_Gds_AppNumber));
        EventBus.publish (new GDS_Action__e  (Record_Id__c  = opp.Id,Action__c = Label.TC_GDS_Get_Dealer_InfoLease));

        Test.stopTest();
    }
    @isTest static void testGDSTeaser() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.startTest();
        EventBus.publish (new GDS_Action__e  (Record_Id__c  = opp.Id,Action__c = Label.PEAC_Teaser_Initial_Submission));
        Test.stopTest();
    }
}