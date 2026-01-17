@isTest
public with sharing class showCheckListClsTest {
    
    @TestSetup
    static void setup() {
        Account account = new Account(
            Name = 'showCheckListClsTest',
            Business_City__c = 'Minneapolis',
            Business_State__c = 'MN',
            Business_Address__c = '701 N 3rd St',
            Business_Zip__c = '55401',
            Business_Type__c = 'Proprietorship'
        );
        insert account;
        System.assertNotEquals(null, account.Id);
        
        Opportunity opportunity = new Opportunity(
            Name = 'showCheckListClsTest',
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
    static void getChecklists() {
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Name = 'showCheckListClsTest'];
        
        Attachment attachment = new Attachment(
            Name = 'Loan Booking Sheet',
            ParentId = opp.Id,
            Description = 'This is a booking sheet',
            Body = Blob.valueOf('Booking sheet')
        );
        
        insert attachment;
        Opportunity_Attachment__c onBaseAttachment = [SELECT Id FROM Opportunity_Attachment__c WHERE Name = 'Loan Booking Sheet'];
        showCheckListCls.getChecklists(onBaseAttachment.Id);
        showCheckListCls.getDocuments(onBaseAttachment.Id);
    }

    @IsTest
    static void uploadFile() {
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity WHERE Name = 'showCheckListClsTest'];
        ContentVersion contentVersion = new ContentVersion(
                    Title          = 'a picture',
                    PathOnClient   = 'Pic.jpg',
                    VersionData    = Blob.valueOf('Test Content'),
                    IsMajorVersion = true);
            insert contentVersion;

            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
       
        showCheckListCls.uploadFile('LC - Misc','[{"Name":"Upload File","documentId":"'+documents[0].Id+'"}]' , 'Testing', opp.Id);
    }

    
}