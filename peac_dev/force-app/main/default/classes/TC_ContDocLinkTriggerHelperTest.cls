@IsTest
/** 
 * @description test coverage for TC_ContDocumentLinkTriggerHelper added for SAL-3037
 * Created by: Trohweder 7/11/21
 * SAL-3037
 */
public with sharing class TC_ContDocLinkTriggerHelperTest {
    
    @TestSetup
    static void makeData(){

        Account acc = new Account();
        acc.Name = 'test Account';
        insert acc;

        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.Name = 'Test';
        opp.AccountId = acc.Id;
        opp.StageName = 'Quote';
        opp.CloseDate = Date.today();
        opp.Primary_Source__c = 'Customer Inbound - Call';
        insert opp;

        Test.stopTest();

        TC_Origination__Checklist_Template__c template = new TC_Origination__Checklist_Template__c();
        template.Name = 'credit stips';
        insert template;

        TC_Origination__Checklist__c cl = new TC_Origination__Checklist__c();
        cl.Name= 'credit stips';
        cl.TC_Origination__Checklist_Template__c = template.Id;
        cl.TC_Origination__Opportunity__c = opp.Id;
        insert cl;

        TC_Origination__Checklist_Item_with_Attachments__c clAttachment = new TC_Origination__Checklist_Item_with_Attachments__c();
        clAttachment.Name = 'credit stips';
        clAttachment.TC_Origination__Checklist__c = cl.Id;
        insert clAttachment;

        
    }

    @IsTest
    static void runTest(){

        Test.startTest();

        ContentVersion doc = new ContentVersion();
        doc.Title = 'Test';
        doc.VersionData = Blob.valueOf('Test Content Data');
        doc.IsMajorVersion = true;
        doc.PathOnClient = 'Test.jpg';
        insert doc;

        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = [SELECT Id FROM ContentDocument LIMIT 1].Id;
        link.LinkedEntityId = [SELECT Id FROM TC_Origination__Checklist_Item_with_Attachments__c LIMIT 1].Id;
        insert link;

        Test.stopTest();

        List<Id> ids = new List<Id>();
        
        ids.add([SELECT Id FROM Opportunity_Attachment__c LIMIT 1].Id);

        System.assert([SELECT Id FROM Attachment WHERE parentId IN :ids].size() > 0, 'No OnBase Attachment was created for the Opportunity');
    }
}