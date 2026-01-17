@IsTest
/**
 * @description Test coverage for all Assign Signers classes
 * SAL-3249
 */
public with sharing class TC_AssignSignersApiTest {
    
    @TestSetup
    static void makeData(){
        
        Account a = new Account();
        a.Name = 'Test Account';
        a.Business_Address__c = 'test street';
        a.Business_City__c = 'Testing';
        a.Business_State__c = 'MN';
        a.Business_Zip__c = '55371';
        insert a;
        Opportunity o = new Opportunity();
        o.AccountId = [Select Id FROM Account LIMIT 1].Id;
        o.Name = 'Test Opp';
        o.CloseDate = Date.today().addDays(10);
        o.StageName = 'Application';
        o.Equipment_Cost__c = 1000;
        o.Equipment_Description__c = 'Test';
        o.Terms__c = 36;
        o.Workflow_Type__c = 'Simple';
        Test.startTest();
        insert o;
        Test.stopTest();
        List<Contact> contacts = new List<Contact>();
        Contact c1 = new Contact();
        c1.FirstName = 'Test';
        c1.LastName = 'Contact1';
        c1.Email = 'tc1@mailinator.com';
        c1.Phone = '1112223333';
        contacts.add(c1);
        Contact c2 = new Contact();
        c2.FirstName = 'Test';
        c2.LastName = 'Contact2';
        c2.Email = 'tc2@mailinator.com';
        c2.Phone = '1112223334';
        contacts.add(c2);
        insert contacts;
        dsfs__DocuSign_Status__c status = new dsfs__DocuSign_Status__c();
        insert status;
        List<dsfs__DocuSign_Recipient_Status__c> recipients = new List<dsfs__DocuSign_Recipient_Status__c>();
        dsfs__DocuSign_Recipient_Status__c sc1 = new dsfs__DocuSign_Recipient_Status__c();
        sc1.dsfs__Contact__c = contacts[0].Id;
        sc1.dsfs__Parent_Status_Record__c = status.Id;
        sc1.dsfs__DocuSign_Recipient_Id__c = 'Test1';
        recipients.add(sc1);
        dsfs__DocuSign_Recipient_Status__c sc2 = new dsfs__DocuSign_Recipient_Status__c();
        sc2.dsfs__Contact__c = contacts[1].Id;
        sc2.dsfs__Parent_Status_Record__c = status.Id;
        sc2.dsfs__DocuSign_Recipient_Id__c = 'Test2';
        recipients.add(sc2);
        insert recipients;
    }

    @IsTest
    /**
     * @description runs the assign signers api classes that return nothing
     * SAL-3249
     */
    public static void runTest(){

        Test.setMock(HttpCalloutMock.class, new TC_AssignSignersAPICalloutMock());

        Test.startTest();
        TC_AssignSignersAPI.callAssignSignersAPI([SELECT Id FROM dsfs__DocuSign_Status__c LIMIT 1].Id);
        Test.stopTest();

    }
}