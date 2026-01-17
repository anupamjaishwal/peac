@isTest
public with sharing class TC_LeaseOpportunityDISValidationTest {
    @TestSetup
    static void setup() {
        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;

        Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c ();
        setting.Enable_Debug_Log__c = true;
        setting.Mock_Callout__c = true;
        setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
        setting.SetupOwnerId = UserInfo.getOrganizationId ();
        setting.Config_Name__c = 'TEST';
        insert setting;

        List<Account> accountList = new List<Account>();

        Account brokerAccount = new Account(
            Name = 'TC_CreditDecisionTriggerTest Broker Account'
            , RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Account').getRecordTypeId()
            , Business_Address__c = 'Test Address', Business_City__c = 'Test City', Business_State__c = 'MN', Business_Zip__c = '11111'
            , Account_EU_FS_SIC_Description__c = '8661'
            , Account_Months_In_Business__c = 13
        );
        accountList.add(brokerAccount);

        Account franchiseeAccount = new Account(
                Name = 'TC_CreditDecisionTriggerTest Franchisee Account'
                , RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId()
                , Business_Address__c = 'Test Address', Business_City__c = 'Test City', Business_State__c = 'MN', Business_Zip__c = '11111'
                , Account_EU_FS_SIC_Description__c = '8661'
                , Account_Months_In_Business__c = 13
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

        );
        accountList.add(dealerAccount);

        insert accountList;

        Contact dc = new Contact (
            AccountId = dealerAccount.Id, 
            FirstName = 'dealer test', 
            LastName = 'dealer contact', 
            MailingStreet = 'dealer test', 
            MailingCity = 'dealer test', 
            MailingStateCode = 'MN', 
            MailingPostalCode = '11190', 
            MailingCountry='United States', 
            Phone='1234555555',
            Title = 'Mr', 
            SSN__c = '156431111', 
            BirthDate = Date.today () - 365, 
            Email = 'testdealer123@test.com'
        );
        insert dc;

        Opportunity opp = new Opportunity(
                Name = 'TC_CreditDecisionTriggerTest'
                , StageName = 'Quote'
                , CloseDate = Date.today()
                , Last_Date_Scorex_Retrieved__c = Date.today()
                , RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId()
                , AccountId = franchiseeAccount.Id
                , Application__c = 'TestApplicationNumber'
                , Loan_Ready_To_Doc__c = 'Yes'
                , Lessor__c = 201
                , Months_Verified__c = 12
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

        Broker__c broker = new Broker__c (Opportunity__c = opp.Id, Account__c = brokerAccount.Id);
        insert broker;
    }

    @IsTest
    public static void LeaseOpportunityDISValidationTest(){
        
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Variable_Payment__c, Probability, RecordTypeId, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Loan_Record_Type__c, Probability, First_12_Months_Free__c, Beginning_Maintenance_Fee_Amount__c, 
                                                                Equipment_Cost__c, Opportunity_Funding_Type__c,Variable_Payment__c,
                                                                RecordTypeId, StageName
                                                                FROM Opportunity]);


        for(Id key : newMap.keyset()){
            newMap.get(key).StageName = 'Funding';
        }
        try{
            TC_LeaseOpportunityDocsInStageValidation.leaseOpportunityDocsInStageValidation(oldMap, newMap);
            }
            catch (DmlException e) {
                System.debug(e.getMessage());
                System.debug(e.getStackTraceString());
            }
            catch (Exception e) {
                System.debug(e.getMessage());
                System.debug(e.getStackTraceString());
            }
    }

    @IsTest
    public static void LeaseOpportunityDISValidationTest2(){
      
        Dealer__c d = [SELECT Id FROM Dealer__c];
        delete d;

        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Variable_Payment__c, Probability, RecordTypeId, StageName, Loan_Record_Type__c, PK__c, CaseCenter__c FROM Opportunity]);
        Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Loan_Record_Type__c, Probability, First_12_Months_Free__c, Beginning_Maintenance_Fee_Amount__c, 
                                                                Equipment_Cost__c, Opportunity_Funding_Type__c,Variable_Payment__c,
                                                                RecordTypeId, StageName
                                                                FROM Opportunity]);


        for(Id key : newMap.keyset()){
            newMap.get(key).StageName = 'Funding';
        }
        try{
            TC_LeaseOpportunityDocsInStageValidation.leaseOpportunityDocsInStageValidation(oldMap, newMap);
            }
            catch (DmlException e) {
                System.debug(e.getMessage());
                System.debug(e.getStackTraceString());
            }
            catch (Exception e) {
                System.debug(e.getMessage());
                System.debug(e.getStackTraceString());
            }
    }
}