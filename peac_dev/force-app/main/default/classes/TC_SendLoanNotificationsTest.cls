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

        insert op;

        System.debug('Opportunity Created Created');
        
        Broker__c broker = new Broker__c();
        broker.Account__c = b.Id;
        broker.Opportunity__c = op.Id;
        insert broker;
        System.debug('Broker Relationship Created');

        Dealer__c dealer = new Dealer__c();
        dealer.Opportunity__c = op.Id;
        dealer.Dealer__c = d.Id;
        dealer.Primary_Dealer__c = false;
        insert dealer;

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
}