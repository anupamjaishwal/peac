/********************************************************************************************************************
@Author:Vinod Rathod(LTIMindtree)
@Description: This test class send Attachments To OnBase
@Created Date:Augest-14-2024 	    

*********************************************************************************************************************/
@isTest
public class MARLIN_OnBaseCalloutForCCTest {
    
    @testSetup
    Public static void setupTestData(){
        // Create a test Account
        SL_SCTestData.createAccountAndContracts(1,1);
        Account testAccount = [SELECT Id,Name,CCID__c,RecordTypeId FROM Account LIMIT 1];
        testAccount.Date_Established__c = Date.newInstance(2022,10, 1);
        testAccount.Account_State_Of_Incorporation__c = 'CO';
        testAccount.CCID__c = 'C000530';
        update testAccount;
        Test.StartTest();
        // Create a test Opportunity 
        SL_SCTestData.createOpportunitiesAndAssets(testAccount.Id,1,1);
        Opportunity testOpportunity = [SELECT Id,Name,OwnerId,RecordTypeId,CaseCenter__c FROM Opportunity LIMIT 1];
        testOpportunity.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Booking').getRecordTypeId();
        testOpportunity.Requested_Amount__c = 55000;
        testOpportunity.CaseCenter__c = 'L000420';
        update testOpportunity;
        insert new OnBase_Credentials__c (Add_Document__c = 'test', App_Server_Url__c = 'test',
                                          Data_Source__c = 'tet', Gateway_Url__c = 'test',
                                          Initialization_Vector__c = 'Ki01di908lGdQ8ot', Password__c = 'te',
                                          Secret_Key__c = 'Ki0+di908lGdQ8otxkzyKHxqF3ciK411',Username__c = 'test');
        Test.stopTest();
    }
    
    @isTest static void testsendCCAttachmentToOnBase(){
        
        Opportunity opportunityRecord = [SELECT Id,Name,CaseCenter__c FROM Opportunity LIMIT 1];
        Account accountRecord =     [SELECT Id,Name,CCID__c FROM Account LIMIT 1];
        
        Opportunity_Attachment__c opportunityAttachment= New Opportunity_Attachment__c(
            Opportunity__c = opportunityRecord.Id
            ,Account__c = accountRecord.Id
            ,Type__c = 'CR - Credit Application'
            ,Description__c = 'Test Opportunity_Attachment__c '
            ,Sent_To_OnBase__c = True
            ,Updated_Rapport__c = false
        );
        insert opportunityAttachment;
        
        
        // Create the Attachment record
        Attachment newAttachment = new Attachment();
        newAttachment.Name = 'Test Attachment.pdf';
        newAttachment.Body = Blob.valueOf('This is some test data for the attachment.'); 
        newAttachment.ParentId = opportunityAttachment.Id; // Link the attachment to the parent record
        insert newAttachment;
        
        Opportunity_Attachment__c OppAttachment= [SELECT Id,Opportunity__c,Account__c,Type__c,Description__c,Sent_To_OnBase__c,Updated_Rapport__c,Document_URL__c FROM Opportunity_Attachment__c LIMIT 1];
        List<String> onbaseAttachmentIds = New List<String> ();
        onbaseAttachmentIds.add(OppAttachment.Id);
        Test.startTest();
        //Send attachment to onbase
        MARLIN_OnBaseCalloutForCC.sendCCAttachmentToOnBase(opportunityRecord.Id,false);
        MARLIN_OnBaseCalloutForCC.sendCCAttachmentToOnBase(opportunityRecord.Id,false,onbaseAttachmentIds);
        Test.stopTest();
        
    }
    @isTest static void testSendCCAttachmentToOnBaseFalse(){
        Opportunity opportunityRecord = [SELECT Id,Name,CaseCenter__c FROM Opportunity LIMIT 1];
        Account accountRecord =     [SELECT Id,Name,CCID__c FROM Account LIMIT 1];
        
        Dealer__c primaryDealers = new Dealer__c(Opportunity__c = opportunityRecord.Id,Dealer__c = accountRecord.Id,
                                                 Primary_Dealer__c = true);
        //insert primaryDealers;
        
        Opportunity_Attachment__c opportunityAttachment= New Opportunity_Attachment__c(
            Opportunity__c = opportunityRecord.Id
            ,Account__c = accountRecord.Id
            ,Type__c = 'CR - Credit Application'
            ,Description__c = 'Test Opportunity_Attachment__c '
            ,Sent_To_OnBase__c = false
            ,Updated_Rapport__c = false
        );
        insert opportunityAttachment;
        
        // Create the Attachment record
        Attachment newAttachment = new Attachment();
        newAttachment.Name = 'Test Attachment.pdf';
        newAttachment.Body = Blob.valueOf('This is some test data for the attachment.'); 
        newAttachment.ParentId = opportunityAttachment.Id; // Link the attachment to the parent record
        insert newAttachment;
        
        Opportunity_Attachment__c OppAttachment= [SELECT Id,Opportunity__c,Account__c,Type__c,Description__c,Sent_To_OnBase__c,Updated_Rapport__c,Document_URL__c FROM Opportunity_Attachment__c LIMIT 1];
        List<String> onbaseAttachmentIds = New List<String> ();
        onbaseAttachmentIds.add(OppAttachment.Id);
        Test.startTest();
        //Send attachment to onbase
        MARLIN_OnBaseCalloutForCC.sendCCAttachmentToOnBase(opportunityRecord.Id,false);
        MARLIN_OnBaseCalloutForCC.sendCCAttachmentToOnBase(opportunityRecord.Id,false,onbaseAttachmentIds);
        Test.stopTest();
        
    }
}