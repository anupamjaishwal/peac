@isTest
public with sharing class showAllDocumentsTest{
    
    @TestSetup
    static void setup() {
        Account account = new Account(
            Name = 'showAllDocuments',
            Business_City__c = 'Minneapolis',
            Business_State__c = 'MN',
            Business_Address__c = '701 N 3rd St',
            Business_Zip__c = '55401',
            Business_Type__c = 'Proprietorship'
        );
        insert account;
        System.assertNotEquals(null, account.Id);
        
        Opportunity opportunity = new Opportunity(
            Name = 'showAllDocuments',
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
    static void showAllDocuments() {
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Name = 'showAllDocuments'];
        
        Attachment attachment = new Attachment(
            Name = 'Loan Booking Sheet',
            ParentId = opp.Id,
            Description = 'This is a booking sheet',
            Body = Blob.valueOf('Booking sheet')
        );
        
        insert attachment;
        
        ContentVersion contentVersion = new ContentVersion(
                    Title          = 'a picture',
                    PathOnClient   = 'Pic.jpg',
                    VersionData    = Blob.valueOf('Test Content'),
                    IsMajorVersion = true);
        insert contentVersion;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = documents[0].Id;
            cdl.LinkedEntityId = opp.Id;
            cdl.ShareType = 'V';
            insert cdl;
        showAllDocuments.generatedDocuments(opp.Id);
    }
}