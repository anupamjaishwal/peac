@isTest
public class TC_OpportunityTriggerHelperTest {
    
    @isTest public static void insertOppTest2 () {
        TC_OpportunityTriggerHelper testmtd = new TC_OpportunityTriggerHelper();
    }
    
    
    @testSetup 
    public static void setupBeneficialOwners () {
        Account acc = new Account (Name = 'testbeni', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId(), Business_Phone__c = '1234567890');
        insert acc;
        
        Contact c = new Contact (AccountId = acc.Id, FirstName = 'test', LastName = 'testbeni', OtherStreet = 'test', OtherCity = 'test', OtherStateCode = 'MN', OtherPostalCode = '11111', Title = 'title', SSN__c = '111111111', BirthDate = Date.today (), Email = 'test@test.com');
        insert c;
        
        insert new Beneficial_Owner__c (Account__c = acc.Id, Contact__c = c.Id, Ownership_Percent__c = 50);

        Test.startTest();
        Id loanOppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId();
        Opportunity opp = new Opportunity (AccountId = acc.Id
                                           , StageName = 'Quote'
                                           , CloseDate = date.today () + 10
                                           , Name = 'test', RecordTypeId = loanOppId);

        
        insert opp;
        Test.stopTest();

    }
    
    @isTest public static void TestApproved(){
        Account acc = new Account (Name = 'testbeni', Account_Dealer_Status__c  = '1-time Need Profile Unused', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId());
        Test.startTest();
        insert acc;
        Test.stopTest();
    }
    
    @isTest public static void expressOrtValidationTest() {
        Opportunity op = new Opportunity (Name = 'test'
                                         ,AccountId = [SELECT Id FROM Account WHERE Name = 'testbeni'][0].Id
                                         ,StageName='Quote'
                                         ,CloseDate = date.today()+15
                                         ,Primary_Source__c='LendingTree');
        Test.startTest();
        insert op;
        op.Primary_Source__c='Customer Inbound - Call';
       // op.Lessor__c =409;
        TC_OpportunityTriggerHelper.validationForManager(new Map<Id, Opportunity>{op.Id => op}, new List<Opportunity> {op});
        //update op;
        Test.stopTest();
    }
    
    @isTest public static void insertOppTest () {
        
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Variable_Payment__c objVP = new Variable_Payment__c();
        objVP.Opportunity__c = opp.Id;
        objVP.Payment_Amount__c  = 100;
        objVP.of_payments__c = 2;
        Test.startTest();
        insert objVP;
        Test.stopTest();
        //update opp;

    }
/*
    @isTest public static void insertOppTest2 () {
        
        ORE__c objORE = new ORE__c();
        objORE.Bypass__c = true;
        insert objORE ;
        
        Opportunity testOpp = new Opportunity (AccountId = [SELECT Id FROM Account WHERE Name = 'testbeni'][0].Id
                               , StageName = 'Funding'
                               , CloseDate = date.today () + 10
                               , Name = 'test'
                               , Tax_ID__c = '123456789'
                               , Assign_To_CMS_User__c = [SELECT Id FROM User LIMIT 1][0].Id
                               , Business_Phone__c = '1234563333',
                                Credit_Stips_Completed_Date__c = date.today () +10 );
        insert testOpp;
        
        Payee__c payee = new Payee__c(Payee_Name__c = 'test', Address1__c = 'test', City__c = 'test', State__c ='MN', Email__c ='a@a.com', SL_Vendor_ID__c = 'je3loxm4s90f');
        insert payee;
        
        insert new Payment__c(Payee__c = payee.Id, Opportunity__c = testOpp.Id, Payment_Method__c = 'Check', Less_UPS_Charge__c = 1, Less_Wire_Fee__c = 2, Less_Titling_Fee__c = 3, Less_Delivery_Guarantee__c = 4, Plus_Points__c = 5);
        
        testOpp.StageName = 'Booking';
        update testOpp;
    }*/

    /*
    @isTest public static void insertOppTest3 () {

//
        TC_GenerateTaxMatrixCtrlTestUtil.generateCustomSettings();

        ORE__c ore = ORE__c.getOrgDefaults();
        ore.Bypass__c = true;
        upsert ore;

//        StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'SAL366JSONacc' LIMIT 1][0];
//        String body = sr.Body.toString();
        String body = TC_JSONTestRecordsUtil.SAL366JSONacc;
        Account acc = (Account) JSON.deserialize(body, Account.class);
        acc.Id = null;
        insert acc;

//        sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'SAL366JSON' LIMIT 1][0];
//        body = sr.Body.toString();
        body = TC_JSONTestRecordsUtil.SAL366JSON;
        Opportunity opp = (Opportunity) JSON.deserialize(body, Opportunity.class);
        opp.AccountId = acc.Id;
        opp.Id = null;
        insert opp;

//        sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'SAL366JSONdealAcc' LIMIT 1][0];
//        body = sr.Body.toString();
        body = TC_JSONTestRecordsUtil.SAL366JSONdealAcc;
        Account acc2 = (Account) JSON.deserialize(body, Account.class);
        acc2.Id = null;
        insert acc2;

//        sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'SAL366JSONdlr' LIMIT 1][0];
//        body = sr.Body.toString();
        body = TC_JSONTestRecordsUtil.SAL366JSONdlr;
        Dealer__c d = (Dealer__c) JSON.deserialize(body, Dealer__c.class);
        d.Id = null;
        d.Opportunity__c = opp.Id;
        d.Dealer__c = acc2.Id;
        insert d;

        opp.StageName = 'Funding';
        update opp;

        Contact c = [SELECT Id FROM Contact WHERE LastName = 'testbeni' LIMIT 1][0];
        OpportunityContactRole cr = new OpportunityContactRole(OpportunityId = opp.Id, ContactId = c.Id, Role = 'Dealer Sales Rep');
        insert cr;

        opp.Ready_to_Doc__c = 'Yes';
        update opp;
    }*/
    
    /* Moved to TC_TestSetApprovalMergeFields Apex test class
    @IsTest
    static void testSetApprovalMergeFields() {
        Account account = new Account(Name = 'test account', Business_Phone__c = '1234567890');
        insert account;

        Contact contact = new Contact(
                FirstName = 'Joe',
                LastName = 'Smith',
                AccountId = account.Id
        );
        insert contact;
        
        Opportunity opportunity = new Opportunity(
                AccountId = account.Id,
                Name = 'testSetApprovalMergeFields',
                StageName = 'Decision',
                CloseDate = Date.today(),
                Application__c = '12345'
        );
        Test.startTest();
        insert opportunity;

        Guarantor__c guarantor = new Guarantor__c(
                Opportunity__c = opportunity.Id,
                Contact__c = contact.Id
        );
        insert guarantor;

        opportunity.Application_Status__c = 'Automatically Approved';
        update opportunity;
        Test.stopTest();
    }*/


}