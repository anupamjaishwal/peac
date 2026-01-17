/** @author : Tamarack Consulting, Inc.
* @date : 4/17/20
* @description: 
*
*/
@IsTest
public with sharing class TC_OpportunityAttachmentHelperTest {
    
    @TestSetup
    static void setup() {
        Account account = new Account(
            Name = 'TC_AttachmentTriggerHandlerTest',
            Business_City__c = 'Minneapolis',
            Business_State__c = 'MN',
            Business_Address__c = '701 N 3rd St',
            Business_Zip__c = '55401',
            Business_Type__c = 'Proprietorship'
        );
        insert account;
        System.assertNotEquals(null, account.Id);
        
        Opportunity opportunity = new Opportunity(
            Name = 'TC_AttachmentTriggerHandlerTest',
            StageName = 'Booking',
            CloseDate = Date.today(),
            Tax_ID__c = '123456789',
            Probability = 76,
            Credit_Stips_Completed_Date__c = Date.today(),
            Assign_To_CMS_User__c = UserInfo.getUserId(),
            AccountId = account.Id
        );
        Test.startTest();
        insert opportunity;
        System.assertNotEquals(null, opportunity.Id);
        Test.stopTest();
    }
    
    @IsTest
    static void testDeleteOldAttachments() {
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Name = 'TC_AttachmentTriggerHandlerTest'];
        
        Attachment attachment = new Attachment(
            Name = 'Loan Booking Sheet',
            ParentId = opp.Id,
            Description = 'This is a booking sheet',
            Body = Blob.valueOf('Booking sheet')
        );
        
        insert attachment;
        Opportunity_Attachment__c onBaseAttachment = [SELECT Id FROM Opportunity_Attachment__c WHERE Name = 'Loan Booking Sheet'];
    }
    
    @isTest
    static void test_DocDealerTypeMapping(){
        Opportunity_Attachment__c oppAtt = new Opportunity_Attachment__c();
        test.StartTest();
            oppAtt.Name = 'TestAtt';
            oppAtt.Opportunity__c = [SELECT Id FROM Opportunity LIMIT 1].Id;
            oppAtt.Dealer_Doc_Type__c = 'LC - Invoice';
            
            INSERT oppAtt;
        test.StopTest();
        
        Opportunity_Attachment__c attachment = [SELECT Id, Dealer_Doc_Type__c, Type__c FROM Opportunity_Attachment__c WHERE Id = :oppAtt.Id];
        Assert.areEqual(attachment.Dealer_Doc_Type__c, attachment.Type__c);
        
        attachment.Dealer_Doc_Type__c = 'LC - Lease';
        UPDATE attachment;
        
    }
}