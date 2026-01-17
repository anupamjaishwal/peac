@isTest
private class TC_OnBaseApexTest {
    @testSetup public static void setup () {
       
    }
    
    @isTest static void test () {
        Account acc = new Account (Name = 'testbeni', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId(), Business_Phone__c = '1234567890');
        insert acc;
        
        Contact c = new Contact (AccountId = acc.Id, FirstName = 'test', LastName = 'testbeni', OtherStreet = 'test', OtherCity = 'test', OtherStateCode = 'MN', OtherPostalCode = '11111', Title = 'title', SSN__c = '111111111', BirthDate = Date.today ());
        
        insert c;
        
        Opportunity opp = new Opportunity (AccountId = acc.Id
                               , StageName = 'test'
                               , CloseDate = date.today () + 10
                               , Name = 'test');
        
        insert opp;
        
        Test.startTest ();
        
        
        
        TC_Origination__Checklist_Template__c ct = new TC_Origination__Checklist_Template__c ();
        ct.Name = 'Test Checklist';
        ct.TC_Origination__External_Email_Recipient_API_Names__c = 'TC_Origination__Box_Folder_Id__c';
        ct.TC_Origination__Internal_Recipient_Email_Addresses__c = 'test@test.com';
        ct.TC_Origination__Start_Sharing_Probability__c = 0;
        ct.TC_Origination__End_Sharing_Probability__c = 100;
        
        insert ct;
        

        TC_Origination__Checklist_Template_Item__c cti = new TC_Origination__Checklist_Template_Item__c ();
        cti.TC_Origination__Checklist_Template__c = ct.Id;
        cti.TC_Origination__OnBase_Document_Type__c = 'CR - Misc';
        
        insert cti;
        

        TC_Origination__Checklist__c ch = new TC_Origination__Checklist__c ();
        ch.Name = 'Test Checklist';
        ch.TC_Origination__Opportunity__c = opp.Id;
        ch.TC_Origination__Checklist_Template__c = ct.Id;
       
        insert ch;
        
        
        TC_OnBaseApex a = new TC_OnBaseApex ();
        a.doUploadAttachment ('BLOB', 'new.log', 'log', '', [SELECT Id FROM TC_Origination__Checklist_Item_with_Attachments__c LIMIT 1][0].Id, '', true);
        Test.stopTest ();
    }
}