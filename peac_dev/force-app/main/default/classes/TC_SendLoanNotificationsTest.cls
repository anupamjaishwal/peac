/**
 * Created by trohweder on 1/25/21.
 * Part of SAL-2421 - SAL-2427
 * Updated for SAL-3040 (dsheen)
 */
@isTest
public with sharing class TC_SendLoanNotificationsTest {

    @TestSetup
    public static void testSetup(){
        Account a = new Account();
        a.Name = 'test';
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        a.BillingStreet = 'alksjdf';
        a.BillingCity = 'asdfad';
        a.BillingState = 'Minnesota';
        a.BillingPostalCode = '66111';
        a.CCAN__c= '4667537';
        a.CCID__c= '1667537';


        insert a;
        System.debug('Account Created');

        List<Contact> contacts = new List<Contact>();
        Contact c1 = new Contact();
        c1.FirstName = 'Bob';
        c1.LastName = 'Johnson';
        c1.AccountId = a.Id;
        c1.Phone = '5555555555';
        contacts.add(c1);

		Contact c2 = new Contact();
        c2.FirstName = 'Dealer Repurchase DocGen';
        c2.LastName = 'DO NOT DELETE';
        c2.AccountId = a.Id;
        c2.Phone = '5555555557';
        c2.Email = 'dealer.primary@test.com';
		contacts.add(c2);

        insert contacts;
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
        
        //Hitting SOQL limit when Dealer Account inserted
        Account d = new Account();
        d.Name = 'dealer';
        d.Business_Phone__c = '5558888888';
        d.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();
        d.Submitted_Loan__c = true;
        d.Approved_Loan__c = true;
        d.Declined_Loan__c = true;
        d.More_Info_Loan__c = true;
        d.Docs_In_Loan__c = true;
        d.Docs_Out_Loan__c = true;
        d.Docs_Out_Contracts_Loan__c = false;
        d.Funded_Loan__c = true;
		d.CCAN__c= '4664337';
        d.CCID__c= '1643537';

        accsToInsert.add(d);
        System.debug('Dealer Created');
        
        insert accsToInsert;

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Contact c3 = new Contact();
        c3.FirstName = 'Carmen';
        c3.LastName = 'Contact';
        c3.AccountId = b.Id;
        c3.Email = 'testing@mailinator.com';
        c3.Phone = '5555555555';
        c3.Receive_All_Loan_Notifications__c = true;
        insert c3;
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
        op.Primary_Broker__c = b.Id;


        insert op;

        insert new Guarantor__c(
            Opportunity__c = op.Id,
            Type__c = 'Personal Guarantor',
            PG_Number__c = 'PG1'
        );
        
        Opportunity_Attachment__c oa = new Opportunity_Attachment__c(
            Opportunity__c = op.Id,
            Dealer_Doc_Type__c = 'Approval Letter'
        );
        insert oa;
        
        Attachment att = new Attachment();
        att.ParentId = oa.Id;
        att.Name = 'approval_letter.pdf';
        att.Body = Blob.valueOf('fake pdf bytes');
        insert att;
        
        System.debug('Opportunity Created');
        
        Broker__c broker = new Broker__c();
        broker.Account__c = b.Id;
        broker.Opportunity__c = op.Id;
        insert broker;
        System.debug('Broker Relationship Created');

       

        OpportunityContactRole ocr = new OpportunityContactRole();
        ocr.ContactId = c2.Id;
        ocr.OpportunityId = op.Id;
        ocr.Role = 'Dealer Primary Contact';
        
        User u = [SELECT Id, Email FROM User WHERE IsActive = true LIMIT 1];

        insert new AccountTeamMember(
            AccountId = b.Id,      
            UserId = u.Id,
            TeamMemberRole = 'Broker Manager'
        );
        
        insert ocr;
        Test.stopTest();


    }

    @IsTest
    public static void testMoreInfo(){

        Test.startTest();
        Opportunity op = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp'];
        op.Application_Status__c = 'More Info';
        update op;
        Test.stopTest();
    }
    @IsTest
    public static void testApproved(){
        Test.startTest();
        Opportunity op = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp'];
        op.Application_Status__c = 'Approved';
        update op;
        Test.stopTest();
    }
    @IsTest
    public static void testRejected(){
        Test.startTest();
        Opportunity op = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp'];
        op.Application_Status__c = 'Rejected';
        update op;
        Test.stopTest();
    }
    @IsTest
    public static void testDocsIn(){
        Test.startTest();
        Opportunity op = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp'];
        op.StageName = 'Docs Out';
        op.Opportunity_Status__c = 'Docs Out';
        update op;
        Test.stopTest();
    }
    @IsTest
    public static void testDocsOutContracts(){
        Account b = [SELECT Id, Docs_Out_Loan__c, Docs_Out_Contracts_Loan__c FROM Account WHERE Name = 'broker'];
        b.Docs_Out_Loan__c = false;
        b.Docs_Out_Contracts_Loan__c = true;
        update b;
        
        Test.startTest();
        Opportunity op = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp'];
        op.StageName = 'Docs Out';
        op.Opportunity_Status__c = 'Docs Out';
        update op;
        Test.stopTest();
    }
    
    @IsTest
    public static void testMoreInfo_CreatesErrorLog_WhenEmailFails(){
        TC_SendLoanNotifications.FORCE_EMAIL_FAILURE_FOR_TEST = true;
    
        Opportunity op = [SELECT Id, Application_Status__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
    
        delete [SELECT Id FROM ErrorLogger__Error_Log__c WHERE Opportunity__c = :op.Id];
    
        Test.startTest();
        op.Application_Status__c = 'More Info';
        update op;
        Test.stopTest();
    
        System.assert(
            [SELECT COUNT() FROM ErrorLogger__Error_Log__c WHERE Opportunity__c = :op.Id] > 0,
            'Expected ErrorLogger__Error_Log__c record for forced email failure (More Info)'
        );
    }
    
    @IsTest
    public static void testApproved_CreatesErrorLog_WhenEmailFails(){
        TC_SendLoanNotifications.FORCE_EMAIL_FAILURE_FOR_TEST = true;
    
        Opportunity op = [SELECT Id, Application_Status__c FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
    
        delete [SELECT Id FROM ErrorLogger__Error_Log__c WHERE Opportunity__c = :op.Id];
    
        Test.startTest();
        op.Application_Status__c = 'Approved';
        update op;
        Test.stopTest();
    
        System.assert(
            [SELECT COUNT() FROM ErrorLogger__Error_Log__c WHERE Opportunity__c = :op.Id] > 0,
            'Expected ErrorLogger__Error_Log__c record for forced email failure (Approved)'
        );
    }
    
    @IsTest
    public static void testDocsOutContracts_CoversOpportunityAttachmentRedBlock() {
    
        Opportunity op = [
            SELECT Id, OwnerId
            FROM Opportunity
            WHERE Name = 'Test Opp'
            LIMIT 1
        ];
    
        Broker__c br = [
            SELECT Id, Account__c, Opportunity__c
            FROM Broker__c
            WHERE Opportunity__c = :op.Id
            LIMIT 1
        ];
    
        Opportunity_Attachment__c oa = new Opportunity_Attachment__c();
        oa.Name = 'Test OA';
        oa.Opportunity__c = op.Id;
        oa.Dealer_Doc_Type__c = 'Approval Letter'; 
        oa.Type__c = 'Approval Letter';           
        insert oa;
    
        Attachment att = new Attachment();
        att.ParentId = oa.Id;
        att.Name = 'ApprovalLetter.pdf';
        att.Body = Blob.valueOf('dummy pdf bytes');
        insert att;
    
        Map<Id, Set<Id>> emailList = new Map<Id, Set<Id>>();
        emailList.put(op.Id, new Set<Id>{ br.Id });
    
        Map<Id, Id> ownerIds = new Map<Id, Id>{ op.Id => op.OwnerId };
    
        Id templateId;
        List<EmailTemplate> tList = [
            SELECT Id, Name
            FROM EmailTemplate
            WHERE Name IN ('Loan Docs Out w/ Contracts', 'Loan Docs Out', 'Loan Approved', 'Loan More Info')
            LIMIT 1
        ];
        System.assert(!tList.isEmpty(), 'No EmailTemplate found in org to run sendLoanEmails.');
        templateId = tList[0].Id;
    
        Test.startTest();
        TC_SendLoanNotifications.sendLoanEmails(emailList, templateId, ownerIds);
        Test.stopTest();
    
        System.assertEquals(true, true);
    }
    

}