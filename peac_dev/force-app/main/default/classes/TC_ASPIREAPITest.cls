/**
* @author : sfdc, Tamarack Consulting, Inc.
* @date : 12/21/2016
* @description: Test class for ASPIRE API integration.
*
* © Copyright 2003 - 2016 Tamarack Consulting, Inc.  All Rights Reserved.
* 
*/

@isTest
global class TC_ASPIREAPITest {

    @TestSetup
    static void setup ()
    {
        List<Account> accList = new List<Account>();
        Account act = new Account();
        act.name = 'TestAspire1';
        act.BillingCity = 'Minneapolis';
        act.BillingCountryCode = 'US';
        act.BillingPostalCode = '55401';
        act.BillingStateCode = 'MN';
        act.BillingStreet = '411 Washington Ave N';
        act.Phone = '2225551234';
        act.Business_Phone__c = '2225551234';
        act.CCID__c = 'C004343';
        
        Schema.DescribeSObjectResult d = Schema.SObjectType.Account;
        Map<String,Schema.RecordTypeInfo> rtMapByName = d.getRecordTypeInfosByName();
        act.RecordTypeId = rtMapByName.get('End User Account').getRecordTypeId();
        accList.add(act);
        
        Marlin_Configuration__c setting = new Marlin_Configuration__c();
        setting.Static_Standard_Asset_Account_Id__c = act.Id;
        insert setting;
        
        Account act2 = new Account();
        act2.name = 'Aspire2';
        act2.BillingCity = 'Saint Paul';
        act2.BillingCountryCode = 'US';
        act2.BillingPostalCode = '55402';
        act2.BillingStateCode = 'MN';
        act2.BillingStreet = '412 Washington Ave N';
        act2.Phone = '9856349855';
        act2.Business_Phone__c = '2225551234';
        accList.add(act2);
        
        Account act3 = new Account();
        act3.name = 'AspireTest3';
        act3.BillingCity = 'Saint Paul';
        act3.BillingCountryCode = 'US';
        act3.BillingPostalCode = '55403';
        act3.BillingStateCode = 'MN';
        act3.BillingStreet = '413 Washington Ave N';
        act3.Phone = '6664441234';
        act3.Business_Phone__c = '2225551234';
        accList.add(act3);
        insert accList;



        Contact contact = new Contact();        
        contact.FirstName = 'Jeff';
        contact.LastName = 'Heidman';
        contact.AccountId = act.id;
        insert contact;
        
        Opportunity opp = new Opportunity();
        opp.accountId = act.Id;
        opp.amount = 1000;
        opp.name = 'Aspire Test Opportunity 1';
        opp.StageName = 'Ready for Booking';
        Date today = Date.today();
        opp.CloseDate = today;
        opp.Credit_Stips_Completed_Date__c = today;
        opp.Funding_Booking_Loan_Completed_Date__c = today;
        opp.Payment_Amount__c = 1000;
        opp.Account_Business_Street__c = '123';
        //opp.Book_Date__c = today.toStartOfMonth();
        //opp.Term__c = 60;
        //opp.Payment__c = 1200.00;
        insert opp;

        List<TC_ASPIRE__Account__c> aspireAccounts = new List<TC_ASPIRE__Account__c>();
        aspireAccounts.add(new TC_ASPIRE__Account__c(TC_ASPIRE__LastName__c = 'AAA',TC_ASPIRE__AccountId__c = String.valueOf(accList[0].Id).substring(0, 15), TC_ASPIRE__RecordId__c = accList[0].Id, TC_ASPIRE__AccountType__c='Individual'));
        aspireAccounts.add(new TC_ASPIRE__Account__c(TC_ASPIRE__LastName__c = 'AAA',TC_ASPIRE__AccountId__c = String.valueOf(accList[1].Id).substring(0, 15), TC_ASPIRE__RecordId__c = accList[1].Id, TC_ASPIRE__AccountType__c='Individual'));
        aspireAccounts.add(new TC_ASPIRE__Account__c(TC_ASPIRE__LastName__c = 'AAA',TC_ASPIRE__AccountId__c = String.valueOf(accList[2].Id).substring(0, 15), TC_ASPIRE__RecordId__c = accList[2].Id, TC_ASPIRE__AccountType__c='Individual'));
        insert aspireAccounts;


        List<TC_ASPIRE__Contract__c> contracts = new List<TC_ASPIRE__Contract__c>();
        contracts.add(new TC_ASPIRE__Contract__c(TC_ASPIRE__FinanceCompanyRecordId__c = 'ASPIRE_OID_2', TC_ASPIRE__RecordId__c = opp.Id, 	TC_ASPIRE__CustomerRecordId__c = aspireAccounts[0].Id));
        contracts.add(new TC_ASPIRE__Contract__c(TC_ASPIRE__FinanceCompanyRecordId__c = 'ASPIRE_OID_3', TC_ASPIRE__RecordId__c = opp.Id, 	TC_ASPIRE__CustomerRecordId__c = aspireAccounts[1].Id));
        contracts.add(new TC_ASPIRE__Contract__c(TC_ASPIRE__FinanceCompanyRecordId__c = 'ASPIRE_OID_4', TC_ASPIRE__RecordId__c = opp.Id, 	TC_ASPIRE__CustomerRecordId__c = aspireAccounts[2].Id));
        insert contracts;
        

        List<TC_ASPIRE__Location__c> locations = new List<TC_ASPIRE__Location__c>();
        locations.add(new TC_ASPIRE__Location__c(	TC_ASPIRE__Address1__c = 'test 123', 	TC_ASPIRE__RecordId__c = aspireAccounts[0].Id));
        locations.add(new TC_ASPIRE__Location__c(	TC_ASPIRE__Address1__c = 'test 1234', 	TC_ASPIRE__RecordId__c = aspireAccounts[1].Id));
        locations.add(new TC_ASPIRE__Location__c(	TC_ASPIRE__Address1__c = 'test 1235', 	TC_ASPIRE__RecordId__c = aspireAccounts[2].Id));
        insert locations;

        List<TC_ASPIRE__ContractAsset__c> contractAssets = new List<TC_ASPIRE__ContractAsset__c>();
        contractAssets.add(new TC_ASPIRE__ContractAsset__c(	TC_ASPIRE__ContractId__c = contracts[0].Id, TC_ASPIRE__BillToLocationId__c =locations[0].Id, TC_ASPIRE__ContractAssetId__c = 'TEST_1234', TC_ASPIRE__RecordId__c = 'TEST_1234' ));
        contractAssets.add(new TC_ASPIRE__ContractAsset__c(	TC_ASPIRE__ContractId__c = contracts[1].Id ,TC_ASPIRE__BillToLocationId__c =locations[1].Id , TC_ASPIRE__ContractAssetId__c = 'TEST_1234', TC_ASPIRE__RecordId__c = 'TEST_1234'));
        contractAssets.add(new TC_ASPIRE__ContractAsset__c(	TC_ASPIRE__ContractId__c = contracts[2].Id  ,TC_ASPIRE__BillToLocationId__c =locations[2].Id, TC_ASPIRE__ContractAssetId__c = 'TEST_1234', TC_ASPIRE__RecordId__c = 'TEST_1234'));
        insert contractAssets;

        List<TC_ASPIRE__Asset__c> assets = new List<TC_ASPIRE__Asset__c>();
        assets.add(new TC_ASPIRE__Asset__c(TC_ASPIRE__LocationEntityRecordId__c = aspireAccounts[0].Id, TC_ASPIRE__Description__c = 'test', TC_ASPIRE__Quantity__c = 1, TC_ASPIRE__RecordId__c = aspireAccounts[0].Id ));
        assets.add(new TC_ASPIRE__Asset__c(TC_ASPIRE__LocationEntityRecordId__c = aspireAccounts[1].Id, TC_ASPIRE__Description__c = 'test', TC_ASPIRE__Quantity__c = 1, TC_ASPIRE__RecordId__c = aspireAccounts[1].Id ));
        assets.add(new TC_ASPIRE__Asset__c(TC_ASPIRE__LocationEntityRecordId__c = aspireAccounts[2].Id, TC_ASPIRE__Description__c = 'test', TC_ASPIRE__Quantity__c = 1, TC_ASPIRE__RecordId__c = aspireAccounts[2].Id ));
        insert assets;
              


        
        /*Guarantor__c rel = new Guarantor__c();
        rel.Type__c = 'Personal Guarantor';
        rel.Opportunity__c = opp.Id;
        rel.Contact__c = contact.Id;
        insert rel;*/
        
        /*
        Relationship__c rel = new Relationship__c();
        rel.Relationship_Type__c = 'Personal Guarantee';
        rel.Related_Opportunity__c = opp.Id;
        rel.Person__c = contact.Id;
        insert rel;
        
        Relationship__c rel2 = new Relationship__c();
        rel2.Relationship_Type__c = 'Business Guarantee';
        rel2.Related_Opportunity__c = opp.Id;
        rel2.Business__c = act2.Id;
        insert rel2;
        
        Equipment__c equip = new Equipment__c();
        equip.Opportunity__c = opp.Id;
        insert equip;*/
        
        /*Asset__c equip = new Asset__c();
        equip.Opportunity__c = opp.Id;
        equip.Equipment_Street__c = '123';
        equip.Quantity__c = 1;
        equip.Cost__c = 100;
        insert equip;
        
        equip.Equipment_Location_City__c = 'Seattle';
        update equip;*/
    }



    static testMethod void testSendToASPIRE()
    {
        Opportunity opp = [SELECT Id FROM Opportunity];
        String resp;
        test.startTest();
        resp = TC_ASPIREAPI.sendToASPIRE(opp.Id);
        test.stopTest();
        System.assert(resp != null);
    }

    /*@isTest
    static void runTest() {   
    
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        

          
        Test.startTest();
        
        Asset__c equip = new Asset__c();
        equip.Opportunity__c = opp.Id;
        equip.Equipment_Street__c = '123';
        equip.Quantity__c = 1;
        equip.Cost__c = 100;
        insert equip;
        
        equip.Equipment_Location_City__c = 'Seattle';
        update equip;
        
        TC_SubmitToAspireCtrl.refreshAspireData(opp.Id);
        TC_SubmitToAspireCtrl.submitToAspire(opp.Id);
        
        List<TC_ASPIRE__Contract__c> contracts = (List<TC_ASPIRE__Contract__c>) TC_ASPIREDataUtility.selectASPIREObjectData(opp.Id).get('contracts');
        TC_ASPIREAPI.handleAPIException(new TC_ASPIREAPI.APIException(), contracts);
        
        TC_ASPIRE__API_Setting__mdt settings = [SELECT TC_ASPIRE__Server__c, TC_ASPIRE__API__c, TC_ASPIRE__Version__c,
                                                TC_ASPIRE__Authorization__c, TC_ASPIRE__Content_Type__c, TC_ASPIRE__Accept__c,
                                                TC_ASPIRE__Output_Debug__c, TC_ASPIRE__Days_of_History__c
                                                FROM TC_ASPIRE__API_Setting__mdt
                                                WHERE MasterLabel = 'Default'];
        TC_ASPIREAPI.handleException(new TC_ASPIREAPI.APIException(), contracts, 'token', settings);
        
        opp.StageName = '555 - Sales Force Funded';
        opp.Auto_Submit_to_Aspire__c = true;
        update opp;
        

        Test.stopTest();        
    }   */
    
    @isTest
    static void runTestSubmit() {   
    
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        
        Test.startTest ();
          
        
        
        /*Asset__c equip = new Asset__c();
        equip.Opportunity__c = opp.Id;
        equip.Equipment_Street__c = '123';
        equip.Quantity__c = 1;
        equip.Cost__c = 100;
        insert equip;
        
        equip.Equipment_Location_City__c = 'Seattle';
        update equip;*/
        
        //TC_SubmitToAspireCtrl.refreshAspireData(opp.Id);
        
        //TC_SubmitToAspireCtrl.submitToAspire(opp.Id);
        Test.stopTest ();
        /*
        List<TC_ASPIRE__Contract__c> contracts = (List<TC_ASPIRE__Contract__c>) TC_ASPIREDataUtility.selectASPIREObjectData(opp.Id).get('contracts');
        TC_ASPIREAPI.handleAPIException(new TC_ASPIREAPI.APIException(), contracts);
        
        TC_ASPIRE__API_Setting__mdt settings = [SELECT TC_ASPIRE__Server__c, TC_ASPIRE__API__c, TC_ASPIRE__Version__c,
                                                TC_ASPIRE__Authorization__c, TC_ASPIRE__Content_Type__c, TC_ASPIRE__Accept__c,
                                                TC_ASPIRE__Output_Debug__c, TC_ASPIRE__Days_of_History__c
                                                FROM TC_ASPIRE__API_Setting__mdt
                                                WHERE MasterLabel = 'Default'];
        TC_ASPIREAPI.handleException(new TC_ASPIREAPI.APIException(), contracts, 'token', settings);
        
        opp.StageName = '555 - Sales Force Funded';
        opp.Auto_Submit_to_Aspire__c = true;
        update opp;*/
        
        /*
        try {
            TC_SubmitToAspireCtrl.submitToAspire(null);
        }
        catch (Exception e) {
        }*/
        
      
    }   
    
    @isTest
    static void runTestRefresh() {   
    
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        

          
        Test.startTest();
        
        /*Asset__c equip = new Asset__c();
        equip.Opportunity__c = opp.Id;
        equip.Equipment_Street__c = '123';
        equip.Quantity__c = 1;
        equip.Cost__c = 100;
        insert equip;
        
        equip.Equipment_Location_City__c = 'Seattle';
        update equip;*/
        
        TC_SubmitToAspireCtrl.refreshAspireData(opp.Id);
        /*TC_SubmitToAspireCtrl.submitToAspire(opp.Id);
        
        List<TC_ASPIRE__Contract__c> contracts = (List<TC_ASPIRE__Contract__c>) TC_ASPIREDataUtility.selectASPIREObjectData(opp.Id).get('contracts');
        TC_ASPIREAPI.handleAPIException(new TC_ASPIREAPI.APIException(), contracts);
        
        TC_ASPIRE__API_Setting__mdt settings = [SELECT TC_ASPIRE__Server__c, TC_ASPIRE__API__c, TC_ASPIRE__Version__c,
                                                TC_ASPIRE__Authorization__c, TC_ASPIRE__Content_Type__c, TC_ASPIRE__Accept__c,
                                                TC_ASPIRE__Output_Debug__c, TC_ASPIRE__Days_of_History__c
                                                FROM TC_ASPIRE__API_Setting__mdt
                                                WHERE MasterLabel = 'Default'];
        TC_ASPIREAPI.handleException(new TC_ASPIREAPI.APIException(), contracts, 'token', settings);
        
        opp.StageName = '555 - Sales Force Funded';
        opp.Auto_Submit_to_Aspire__c = true;
        update opp;
        
        *//*
        try {
            TC_SubmitToAspireCtrl.submitToAspire(null);
        }
        catch (Exception e) {
        }*/
        
        Test.stopTest();        
    }   
    
    @isTest
    static void runTestAfterSubmission() {   
    
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        

          
        
        
        /*Asset__c equip = new Asset__c();
        equip.Opportunity__c = opp.Id;
        equip.Equipment_Street__c = '123';
        equip.Quantity__c = 1;
        equip.Cost__c = 100;
        insert equip;*/
        
        Test.startTest();
        
        //equip.Equipment_Location_City__c = 'Seattle';
        //update equip;
        
        //TC_SubmitToAspireCtrl.refreshAspireData(opp.Id);
        //TC_SubmitToAspireCtrl.submitToAspire(opp.Id);
        
        List<TC_ASPIRE__Contract__c> contracts = (List<TC_ASPIRE__Contract__c>) TC_ASPIREDataUtility.selectASPIREObjectData(opp.Id).get('contracts');
        TC_ASPIREAPI.handleAPIException(new TC_ASPIREAPI.APIException(), contracts);
        
        TC_ASPIRE__API_Setting__mdt settings = [SELECT TC_ASPIRE__Server__c, TC_ASPIRE__API__c, TC_ASPIRE__Version__c,
                                                TC_ASPIRE__Authorization__c, TC_ASPIRE__Content_Type__c, TC_ASPIRE__Accept__c,
                                                TC_ASPIRE__Output_Debug__c, TC_ASPIRE__Days_of_History__c
                                                FROM TC_ASPIRE__API_Setting__mdt
                                                WHERE MasterLabel = 'Default'];
        TC_ASPIREAPI.handleException(new TC_ASPIREAPI.APIException(), contracts, 'token', settings);
        
        opp.StageName = '555 - Sales Force Funded';
        opp.Auto_Submit_to_Aspire__c = true;
        update opp;
        

        /*
        try {
            TC_SubmitToAspireCtrl.submitToAspire(null);
        }
        catch (Exception e) {
        }*/
        
        Test.stopTest();        
    } 
    
    static testMethod void testRefreshASPIREData()
    {
        Opportunity opp = [SELECT Id FROM Opportunity];
        String resp;
        Test.startTest();
        resp = TC_ASPIREAPI.refreshASPIREData(opp.Id);
        Test.stopTest();
        System.assert(resp != null);
    }
   
}