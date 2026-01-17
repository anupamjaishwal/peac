/**
 * Created by dsheen on 7/02/21.
 * Part of SAL-3040
 */
@IsTest
public with sharing class TC_SendNotificationHelperTest {

    @TestSetup
    public static void testSetup(){
        Account a = new Account();
        a.Name = 'test';
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        a.BillingStreet = 'alksjdf';
        a.BillingCity = 'asdfad';
        a.BillingState = 'Minnesota';
        a.BillingPostalCode = '66111';

        insert a;
        System.debug('Account Created');

        Contact c = new Contact();
        c.FirstName = 'Bob';
        c.LastName = 'Johnson';
        c.AccountId = a.Id;
        c.Phone = '5555555555';

        insert c;
        System.debug('Contact Created');

        List<Account> accsToInsert = new List<Account>();
        Account b = new Account();
        b.Name = 'broker';
        b.Business_Phone__c = '5558888888';
        b.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Account').getRecordTypeId();
        b.Submitted_Loan__c = true;
        b.Approved_Loan__c = true;
        b.Declined_Loan__c = true;
        b.More_Info_Loan__c = true;
        b.Docs_In_Loan__c = true;
        b.Docs_Out_Loan__c = true;
        b.Docs_Out_Contracts_Loan__c = false;
        b.Funded_Loan__c = true;

        accsToInsert.add(b);
        System.debug('Broker Created');
        
        insert accsToInsert;

        Contact c2 = new Contact();
        c2.FirstName = 'Carmen';
        c2.LastName = 'Contact';
        c2.AccountId = b.Id;
        c2.Email = 'testing@mailinator.com';
        c2.Phone = '5555555555';
        c2.Receive_All_Loan_Notifications__c = true;
        insert c2;
        System.debug('Broker Contact Created');


        Test.startTest();
        RecordType rt2 = [SELECT Id,Name FROM RecordType WHERE SobjectType='Opportunity' AND Name LIKE '%Loan%' LIMIT 1];
        System.debug('Got Record');
        Opportunity op = new Opportunity();
        op.Name = 'Test Opp';
        op.RecordTypeId = rt2.Id;
        op.AccountId = a.Id;
        op.Amount = 100;
        op.StageName = 'Quote';
        op.CloseDate = System.today() + 30;
        op.Primary_Source__c = 'Email';
        op.Loan_Purpose__c = 'Cash Crunch';
        op.CaseCenter__c = 'L78697698';
        op.StageName = 'Proposal';

        insert op;

        System.debug('Opportunity Created Created');
        
        Broker__c broker = new Broker__c();
        broker.Account__c = b.Id;
        broker.Opportunity__c = op.Id;
        insert broker;
        System.debug('Broker Relationship Created');

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = c2.Id;
        ocr.OpportunityId = op.Id;
        ocr.Role = 'Dealer Primary Contact';
        insert ocr;
        Test.stopTest();


    }
    
    @isTest
    public static void testOppsWithEmailAttachments(){
        Opportunity op = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp'];
        
        //Insert Docusign Status
        dsfs__DocuSign_Status__c docStat = new dsfs__DocuSign_Status__c(dsfs__Opportunity__c = op.Id);
        insert docStat;
        
        //Insert Attachments
        Attachment att = new Attachment(
            Name = String.valueOf('Test Attachment'), 
            Body = Blob.valueOf('text'),
        	ParentId = docStat.Id);
        insert att;
        
        //Insert ContentDocument 
        ContentVersion cv = new ContentVersion(
        	Title = 'Test Document',
        	PathOnClient = 'Test Document.pdf',
        	VersionData = Blob.valueOf('text'));
        insert cv;
        
        ContentVersion savedCv = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id LIMIT 1];
        
        ContentDocumentLink cdl = new ContentDocumentLink(
        	LinkedEntityId = docStat.Id,
        	ContentDocumentId = savedCv.ContentDocumentId);
        insert cdl;
        
        
        Set<Id> opSet = new Set<Id>{op.Id};
        
        Test.startTest();
        TC_SendNotificationHelper.oppsWithEmailAttachments(opSet);
        Test.stopTest();
    }
}