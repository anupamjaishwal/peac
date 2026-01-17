@IsTest
public with sharing class TC_CreditDecisionRulesTest {

    @TestSetup
    static void makeData(){
        List<Account> accountList = new List<Account>();

        Account franchiseeAccount = new Account(
                Name = 'TC_CreditDecisionTriggerTest Franchisee Account'
                , RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId()
                , Business_Address__c = 'Test Address', Business_City__c = 'Test City', Business_State__c = 'MN', Business_Zip__c = '11111'
                , Account_EU_FS_SIC_Description__c = '8661'
                , Account_Months_In_Business__c = 13, CCAN__c='458548', Business_Phone__c='4453317237', CCID__c='458578'
        );
        accountList.add(franchiseeAccount);

        Account dealerAccount = new Account (
                Name = 'TC_CreditDecisionTriggerTest Dealer Account'
                , RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId()
                , Business_Address__c = 'Test Address', Business_City__c = 'Test City', Business_State__c = 'MN', Business_Zip__c = '11111'
                , Account_EU_FS_SIC_Description__c = '8661'
                , Preferred_Dealer_Level__c = '3'
                , Dealer_Number__c = '855331.7237'
                ,Equipment_Type__c = 'A/V (General)'
                ,Account_Months_In_Business__c = 12, CCAN__c='457748', Business_Phone__c='8553317237', CCID__c='258578'
        );
        accountList.add(dealerAccount);

        insert accountList;

        Opportunity opp = new Opportunity(
                Name = 'TC_CreditDecisionTriggerTest'
                , StageName = 'Quote'
                , CloseDate = Date.today()
                , Last_Date_Scorex_Retrieved__c = Date.today()
                , RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId()
                , AccountId = franchiseeAccount.Id
                , Application__c = 'TestApplicationNumber'
                , Loan_Ready_To_Doc__c = 'Yes'
                , Lessor__c = 421
                , Months_Verified__c = 12
                , Region__c = '000'
                , Decision_Status__c = 'Pending'
                , Branch__c = 'NJ Retail'
                , Business_Type__c = 'Limited Liability'
                , Terms__c = 60

                //Reason for Approval, Branch, Business Type, Months in Business, Terms
        );
		Test.startTest();
        insert opp;
        

        Dealer__c dealer = new Dealer__c(
                Opportunity__c = opp.Id
                , Primary_Dealer__c = TRUE
                , Dealer__c = dealerAccount.Id
        );
        
        insert dealer;
        Test.stopTest();
    }

    @IsTest
    public static void testUpdateFieldsBasedOnLessor(){

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c FROM Opportunity LIMIT 1 ]);
        TC_CreditDecisionRules.updateFieldsBasedOnLessor(oppMap);    

    }

    @IsTest
    public static void testSetStipsToAchGuaranteeForm(){

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Opportunity_Marlin_Score__c FROM Opportunity LIMIT 1 ]);
        for(Id key : oppMap.keyset()){
            oppMap.get(key).Decision_Status__c = 'Approved';
        }    
        TC_CreditDecisionRules.chatterPosts = new List<FeedItem>();   
        TC_CreditDecisionRules.setStipulationsToAchGuaranteeForm(oppMap);    
    }

    @IsTest
    public static void testSetFacility(){

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c, SFP_Tier_2_Status__c, Program_Type__c FROM Opportunity LIMIT 1 ]);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c, SFP_Tier_2_Status__c, Program_Type__c FROM Opportunity LIMIT 1 ]);
        for(Id key : oldMap.keyset()){
            oppMap.get(key).SFP_Tier_2_Status__c = 'Approved';
            oppMap.get(key).Program_Type__c = 'Hold for Sale';
        } 
        TC_CreditDecisionRules.chatterPosts = new List<FeedItem>();   
        TC_CreditDecisionRules.setFacility(oldMap, oppMap);
        for(Id key : oldMap.keyset()){
            oppMap.get(key).SFP_Tier_2_Status__c = 'Rejected';
            oppMap.get(key).Program_Type__c = 'On Balance Sheet Funding';
        } 
        TC_CreditDecisionRules.setFacility(oldMap, oppMap);
    }

    @IsTest
    public static void testCreateUploadChatterPost(){
        FeedItem post = TC_CreditDecisionRules.createChatterPost([SELECT Id FROM Opportunity LIMIT 1].Id, 'Test', 'Test');
        List<FeedItem> posts = new List<FeedItem>();
        posts.add(post);
        TC_CreditDecisionRules.uploadChatterPosts(posts);
    }

    @IsTest
    public static void testSetNumberOfPaymentsField(){
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c FROM Opportunity LIMIT 1 ]);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c FROM Opportunity LIMIT 1 ]);
        for(Id key : oldMap.keyset()){
            oldMap.get(key).Max_Term_Approved__c = 60;
        } 
        TC_CreditDecisionRules.chatterPosts = new List<FeedItem>();   
        TC_CreditDecisionRules.setNumberOfPaymentsField(oldMap, oppMap);
    }

    @IsTest
    public static void testSetOFACRequiredField(){
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c FROM Opportunity LIMIT 1 ]);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c FROM Opportunity LIMIT 1 ]);
        for(Id key : oldMap.keyset()){
            oldMap.get(key).OFAC_Override__c = false;
            oppMap.get(key).OFAC_Override__c = true;
        } 
        TC_CreditDecisionRules.chatterPosts = new List<FeedItem>(); 
        TC_CreditDecisionRules.setOFACRequiredField(oldMap, oppMap);
    }

    @IsTest
    public static void testSetProgramType(){
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Stipulations__c,Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c FROM Opportunity LIMIT 1 ]);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Stipulations__c,Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c FROM Opportunity LIMIT 1 ]);
        for(Id key : oldMap.keyset()){
            oldMap.get(key).SFP_Tier_2_Status__c = 'Approved';
            oppMap.get(key).SFP_Tier_2_Status__c = 'Approved';
        } 
        TC_CreditDecisionRules.chatterPosts = new List<FeedItem>(); 
        TC_CreditDecisionRules.setProgramType(oldMap, oppMap);
        for(Id key : oldMap.keyset()){
            oldMap.get(key).Lessor__c = 211;
            oppMap.get(key).Lessor__c = 422;
            oldMap.get(key).Region__c = '000';
            oppMap.get(key).Region__c = '001';
             
        }
        //Rajesh(Mindtree)
        update oppMap.values();
        TC_CreditDecisionRules.setProgramType(oldMap, oppMap);
        for(Id key : oldMap.keyset()){
            oldMap.get(key).SFP_Tier_2_Status__c = 'Rejected';
            oppMap.get(key).SFP_Tier_2_Status__c = 'Rejected';
            oppMap.get(key).Stipulations__c = null; 
        }
        update oppMap.values();
        oppMap.Values()[0].Stipulations__c = 'Auto ACH Required';
        update oppMap.values();
        TC_CreditDecisionRules.setProgramType(oldMap, oppMap);
    }

    @IsTest
    public static void testSetSIC8661Settings(){

        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c, Opportunity_Marlin_Score__c FROM Opportunity LIMIT 1 ]);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c, Opportunity_Marlin_Score__c FROM Opportunity LIMIT 1 ]);
        for(Id key : oldMap.keyset()){
            oppMap.get(key).Decision_Status__c = 'A';
            oppMap.get(key).Decision_Status__c = 'A';
        } 
        TC_CreditDecisionRules.chatterPosts = new List<FeedItem>(); 
        TC_CreditDecisionRules.setSIC8661Settings(oldMap, oppMap);
    }

    @IsTest
    public static void testSetOwnerOperatorField(){
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c, Opportunity_Marlin_Score__c FROM Opportunity LIMIT 1 ]);
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([
            SELECT Id, Name, StageName, CloseDate, RecordTypeId, AccountId, Application__c, Lessor__c, Region__c, Decision_Status__c, SIC_Code__c, Max_Term_Approved__c, Terms__c, Opportunity_Marlin_Score__c FROM Opportunity LIMIT 1 ]);

        TC_RecursiveTriggerHelper.populateOwnerOpportunity = true;
        TC_CreditDecisionRules.setOwnerOperatorField(oldMap, oppMap);
    }
    
}