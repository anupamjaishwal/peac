@isTest
public with sharing class TC_AutoCreateLoanPaymentRecordsTest {
    @TestSetup
    static void dataSetup(){

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
            , Dealer_Number__c = '855331.7237'
        );
        accountList.add(brokerAccount);

        Account franchiseeAccount = new Account(
                Name = 'TC_CreditDecisionTriggerTest Franchisee Account'
                , RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisee Account').getRecordTypeId()
                , Business_Address__c = 'Test Address', Business_City__c = 'Test City', Business_State__c = 'MN', Business_Zip__c = '11111'
                , Account_EU_FS_SIC_Description__c = '8661'
                , Account_Months_In_Business__c = 13
                , Tax_ID__c = '900978989'
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
                , RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Docs').getRecordTypeId()
                , AccountId = franchiseeAccount.Id
                , Application__c = 'TestApplicationNumber'
                , Loan_Ready_To_Doc__c = 'Yes'
                , Lessor__c = 201
                , Origination_Fee__c = 0
                , Months_Verified__c = 12
                ,Loan_Points_Amount__c = 4
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

        Payee__c payee = new Payee__c(Dealer__c =dealerAccount.Id, Contact__c = dc.Id, Tax_ID_Nbr__c = '900978989', Payee_ID__c	= '855331.7237', Active__c = true, SL_Vendor_ID__c ='900-090-ASD', Payee_Name__c = 'Test Payee' );
        insert payee;
    }

    @IsTest
    public static void AutoCreateLoanPaymentRecordsTest(){

            Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>([SELECT Id, Loan_Points_Amount__c, Contract__c, Origination_Fee__c, Loan_Amount__c, Loan_Record_Type__c, StageName, RecordTypeId FROM Opportunity]);
            Map<Id, Opportunity> newMap = new Map<Id, Opportunity>([SELECT Id, Loan_Points_Amount__c, Contract__c, Origination_Fee__c, Loan_Amount__c, Loan_Record_Type__c, StageName, RecordTypeId FROM Opportunity]);

            for(Id key : newMap.keyset()){
                newMap.get(key).StageName = 'Review for Booking';
                oldMap.get(key).StageName = 'Docs In';
            }
    
            try{
                TC_AutoCreateLoanPaymentRecords.autoCreateLoanPaymentRecords(oldMap,newMap);
                }
                catch (Exception e) {
                    System.debug(e.getMessage());
                }
    }

}