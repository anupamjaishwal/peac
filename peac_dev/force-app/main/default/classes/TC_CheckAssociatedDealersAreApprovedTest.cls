@IsTest
public with sharing class TC_CheckAssociatedDealersAreApprovedTest {
    
    @TestSetup
    static void makeData(){
        Account acc = new Account (
            Name = 'test', 
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId()
        );
        insert acc;

        Account dealer = new Account(
            Name = 'dealer',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId()
        );
        insert dealer;
        
        Contact c = new Contact (
            AccountId = acc.Id, 
            FirstName = 'test', 
            LastName = 'contact', 
            MailingStreet = 'test', 
            MailingCity = 'test', 
            MailingStateCode = 'MN', 
            MailingPostalCode = '11111', 
            MailingCountry='United States', 
            Phone='5555555555',
            Title = 'title', 
            SSN__c = '111111111', 
            BirthDate = Date.today (), 
            Email = 'test123@test.com'
        );
        insert c;

        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            StageName = 'test',
            CloseDate = date.today () + 10,
            Name = 'test'
        );
        Test.startTest();
        insert opp;
        Test.stopTest();
        Dealer__c d = new Dealer__c(Opportunity__c = opp.Id, Dealer__c = dealer.Id, Primary_Dealer__c = false);
        insert d;
        
    }

    @IsTest
    public static void runTestOne(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Branch__c, Docs_In__c, Ready_to_Doc__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Branch__c = oldMap.get(key).Branch__c,
                Docs_In__c = Date.Today(),
                Ready_to_Doc__c = 'Yes');
            newMap.put(key, o);
        }
        String result = '';
        Test.startTest();
        List<Database.SaveResult> oppResults = Database.update(newMap.values(), false);
        Test.stopTest();
        System.assertEquals('All dealers must be approved!', oppResults[0].getErrors()[0]?.getMessage());
    }
    @IsTest
    public static void runTestTwo(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Branch__c, Docs_In__c, Ready_to_Doc__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Branch__c = 'OEG/NATIONAL',
                Docs_In__c = Date.Today(),
                Ready_to_Doc__c = 'Yes');
            newMap.put(key, o);
        }
        String result = '';
        Test.startTest();
        List<Database.SaveResult> oppResults = Database.update(newMap.values(), false);
        Test.stopTest();
        System.assertEquals('All dealers must be approved!', oppResults[0].getErrors()[0]?.getMessage());
    }
    @IsTest
    public static void runTestThree(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Branch__c, Docs_In__c, Ready_to_Doc__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Branch__c = 'OEG - Major Accounts',
                Docs_In__c = Date.Today(),
                Ready_to_Doc__c = 'Yes');
            newMap.put(key, o);
        }
        String result = '';
        Test.startTest();
        List<Database.SaveResult> oppResults = Database.update(newMap.values(), false);
        Test.stopTest();
        System.assertEquals('All dealers must be approved!', oppResults[0].getErrors()[0]?.getMessage());
    }
    @IsTest
    public static void runTestFour(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Branch__c, Docs_In__c, Ready_to_Doc__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Branch__c = 'Office Equip Group-OEG',
                Docs_In__c = Date.Today(),
                Ready_to_Doc__c = 'Yes');
            newMap.put(key, o);
        }
        String result = '';
        Test.startTest();
        List<Database.SaveResult> oppResults = Database.update(newMap.values(), false);
        Test.stopTest();
        System.assertEquals('All dealers must be approved!', oppResults[0].getErrors()[0]?.getMessage());
    }
    @IsTest
    public static void runTestFive(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Branch__c, Docs_In__c, Ready_to_Doc__c, Loan_Record_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Branch__c = 'IFP - Indirect Funding Pl',
                Docs_In__c = Date.Today(),
                Ready_to_Doc__c = 'Yes');
            newMap.put(key, o);
        }
        String result = '';
        Test.startTest();
        List<Database.SaveResult> oppResults = Database.update(newMap.values(), false);
        Test.stopTest();
        System.assertEquals('All dealers must be approved!', oppResults[0].getErrors()[0]?.getMessage());
    }
    @IsTest
    public static void runTestSix(){
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Branch__c, Docs_In__c, Ready_to_Doc__c, Loan_Record_Type__c, Program_Type__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>();

        for(Id key : oldMap.keyset()){
            Opportunity o = new Opportunity(
                Id = key, 
                Branch__c = 'Franchise',
                Docs_In__c = Date.Today(),
                Ready_to_Doc__c = 'Yes',
                Program_Type__c = 'Standard');
            newMap.put(key, o);
        }
        String result = '';
        Test.startTest();
        List<Database.SaveResult> oppResults = Database.update(newMap.values(), false);
        Test.stopTest();
        //System.assertEquals('All dealers must be approved!', oppResults[0].getErrors()[0]?.getMessage());
    }
}