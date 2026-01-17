/**
 * Created by jhber on 3/6/2019.
 */

@isTest
public with sharing class TC_BWcreateCustomerTest {

    @TestSetup static void setup () {
        // Setup test data
        SL_SCTestData.createBridgeWareSetting();
        Id devRecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Corporate').getRecordTypeId();
        Id devRecordTypeIdPersonal = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId();
        Account act = new Account ();
        act.name = 'Test1';
        act.BillingCity = 'Minneapolis';
        act.BillingCountryCode = 'US';
        act.BillingPostalCode = '55401';
        act.BillingStateCode = 'MN';
        act.BillingStreet = '411 Washington Ave N';
        act.Phone = '2225551234';
        act.Business_Phone__c = '2225551234';
        insert act;

        Opportunity opp = new Opportunity ();
        opp.accountId = act.Id;
        opp.amount = 1000;
        opp.name = 'Test Create Customer Opportunity 1';
        opp.StageName = 'Ready for Booking';
        Date today = Date.today ();
        opp.CloseDate = today;
        
        Test.startTest();
        
        insert opp;

        Contact contact = new Contact();
        contact.FirstName = 'Jeff';
        contact.LastName = 'Test';
        contact.SSN__c = '123456789';
        contact.MailingStateCode = 'NY';
        contact.MailingStreet = '123 Testing Avenue';
        contact.MailingCity = 'Rochester';
        contact.MailingCountryCode = 'US';
        contact.MailingPostalCode = '14625';
        contact.Title = 'CEO';
        contact.Email = 'jefftest@thiscompany.com';
        contact.AccountId = act.Id;
        contact.OtherStreet='124 Main St';
        contact.OtherCity='Rochester';
         contact.OtherStateCode = 'NY';
        contact.OtherPostalCode = '14625';
        
        //contact.Score__c = 792;

        insert contact;
        Guarantor__c cg = new Guarantor__c();
        cg.Contact__c = contact.Id;
        cg.Opportunity__c = opp.Id;
        cg.RecordTypeId = devRecordTypeIdPersonal;
        insert cg;

        Account createCustomerAccount = new Account();
        createCustomerAccount.Name = 'TestCustomerCreate1';
        createCustomerAccount.BillingCity = 'Minneapolis';
        createCustomerAccount.BillingCountryCode = 'US';
        createCustomerAccount.BillingPostalCode = '55401';
        createCustomerAccount.BillingStateCode = 'MN';
        createCustomerAccount.BillingStreet = '411 Washington Ave N';
        createCustomerAccount.Phone = '2225551234';
        createCustomerAccount.DBA__c = 'TestyTestDBA';
        //insert createCustomerAccount;
        Guarantor__c custg = new Guarantor__c();
        //custg.Account__r = createCustomerAccount;
        custg.Account__c = act.Id;
        custg.Opportunity__c = opp.Id;
        custg.RecordTypeId = devRecordTypeId;
        Test.stopTest();
        insert custg;
		       	
        //Relationship__c contactOpp = new Relationship__c(Person__c = contact.Id, Related_Opportunity__c = opp.Id, Relationship_Type__c = 'Personal Guarantee');
        //insert contactOpp;
    }

    @isTest
    static void testCheckAndUpdate() {

        

        Test.startTest();
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareCreateCustCalloutMockImpl ());
        List<Contact> updateContacts = TC_BWcreateCustomerCtrl.checkAndUpdateILContacts(opp.Id);
        Test.stopTest();
        
        
    }
    
    @isTest
    static void testCheckAndUpdateAccounts() {
        Test.startTest();
        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new TC_BridgewareCreateCustCalloutMockImpl ());
        List<Account> updateAccounts = TC_BWcreateCustomerCtrl.checkAndUpdateILAccounts(opp.Id);
        TC_BWcreateCustomerCtrl.createBorrowerAsCustomerLtng(acc.id);
        Test.stopTest ();
    }
    
    @isTest
    static void testCreateCustomer() {
        Guarantor__c cg = [SELECT id, contact__c, Contact__r.SSN__c, RecordType.Name,Account__r.Id ,Account__r.Name,Account__r.Business_Address__c,
                           Account__r.Business_City__c, Account__r.Business_State__c, Account__r.Business_Zip__c,Account__r.Tax_ID__c,
                           Contact__r.LastName, Contact__r.FirstName,Contact__r.OtherStreet, Contact__r.OtherCity, Contact__r.OtherStateCode,
                           Contact__r.OtherPostalCode,Contact__r.MailingStreet, Contact__r.MailingCity, Contact__r.MailingStateCode,
                           Contact__r.MailingPostalCode, Contact__r.Contact_CCAN__c, Mobile__c, Phone__c, Email__c, opportunity__c 
                           FROM Guarantor__c limit 1];
        Test.startTest();
        try{
            TC_BWcreateCustomerCtrl.createCustomer(cg, false);
        }Catch(Exception e){}
        Contact c=[SELECT id, name, firstname, lastname, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode, title,
            MobilePhone, email, ssn__c, Contact_CCAN__c FROM contact limit 1];
        TC_BWcreateCustomer bcon=new TC_BWcreateCustomer(c);
        bcon.validate();
        TC_BWCustomerRequestBean req=bcon.createRequest();
        System.assertEquals('jefftest@thiscompany.com', req.Request.CsDefaultContactEmail);
        Test.stopTest();
    }

    @isTest
    static void probablyNotEvenUsed() {
        Dealer__c emptyDealer = new Dealer__c();
        Test.startTest();
        try{
            TC_BWcreateCustomerCtrl.createDealerAsCustomer(emptyDealer, true);
        }Catch(Exception e){}
       
        Test.stopTest();
    }
}