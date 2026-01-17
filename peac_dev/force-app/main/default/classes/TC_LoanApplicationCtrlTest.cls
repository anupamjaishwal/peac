/**
 * @description       : Test class for TC_LOanApplicationCtrl
 * @author            : lvang@northteq.com
 * @group             :
 * @last modified on  : 08-16-2022
 * @last modified by  : lvang@northteq.com
 **/
@isTest
public with sharing class TC_LoanApplicationCtrlTest {

    static Id personalRecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Personal').getRecordTypeId();
    static Id corpRecordTypeId = Schema.SObjectType.Guarantor__c.getRecordTypeInfosByName().get('Corporate').getRecordTypeId();
    static Id brokerRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Broker Account').getRecordTypeId();
    static Id franchiseRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Franchisor Account').getRecordTypeId();
    static Id dealerRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();


    @TestSetup
    static void testSetup(){
        User ifpRep = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'IFP Rep'].Id,
            LastName = 'last',
            Email = 'test@marlincapitalsolutions.com',
            Username = 'test@marlincapitalsolutions.com',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
            );

        insert ifpRep;
        
        User systemAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        insert new SL_Trigger_Settings__c(SetupOwnerId = systemAdmin.Id, Name = 'default', KillList__c = 'Account');// \nOpportunity
        System.runAs(systemAdmin)
        {

            insert new DeactivateTriggers__c(Name = 'opportunityTrigger', IsDeactived__c = true, ObjectName__c = 'Opportunity');
            insert new DeactivateTriggers__c(Name = 'AccountContactRelTrigger', IsDeactived__c = true, ObjectName__c ='Account Contact Relationship');
            insert new DeactivateTriggers__c(Name = 'OpportunityDocGenTrigger', IsDeactived__c = true, ObjectName__c = 'Opportunity');
            // insert new DeactivateTriggers__c(Name = 'TC_AccountTrigger', IsDeactived__c = true, ObjectName__c = 'Account');
            // insert new DeactivateTriggers__c(Name = 'TC_ContactTrigger', IsDeactived__c = true, ObjectName__c = 'TC_ContactTrigger');
            insert new DeactivateTriggers__c(Name = 'TC_Lead', IsDeactived__c = true, ObjectName__c = 'TC_Lead');
            insert new DeactivateTriggers__c(Name = 'TC_OpportunityTrigger', IsDeactived__c = true, ObjectName__c = 'Opportunity');
            insert new Marlin_Configuration__c(Name = 'test', Disable_Standard_Asset_Generation__c = true,  Apex_Validations_Active__c = false);

            Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c ();
            setting.Enable_Debug_Log__c = true;
            setting.Mock_Callout__c = true;
            setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
            setting.SetupOwnerId = UserInfo.getOrganizationId ();
            setting.Config_Name__c = 'TEST';
            insert setting;



            insert new Quick_App_Settings__c (Broker_Record_Type_Label__c = 'Broker Account'
                                              , CCG_Junction_Record_Type_Label__c = 'Corporate'
                                              , Dealer_Record_Type_Label__c = 'Dealer Account'
                                              , End_User_Record_Type_Label__c = 'End User Account'
                                              , Franchiosor_Record_Type_Label__c = 'Franchisor Account'
                                              , PG_Junction_Record_Type_Label__c = 'Personal');


            Account acct = new Account(Name='Test', CCAN__c='100315', Tax_ID__c='100315111', CCID__c = '1003152');
            insert acct;

            Account acct2 = new Account(Name='Test', RecordTypeId = brokerRecTypeId);
            insert acct2;

            Account acct3 = new Account(Name='Test',  RecordTypeId = franchiseRecTypeId);
            insert acct3;

            Account acct4 = new Account(Name='Test',  RecordTypeId = dealerRecTypeId, Points__c = '1');
            insert acct4;
            Contact contact = new Contact(FirstName='John', LastName='Smith', OK_to_Pull_Credit__c = true, ssn__c = '111111111', AccountId=acct4.Id, phone='888-999-8889', Email='test@test.com', MailingStreet = '123 example street', MailingCity = 'Saint Paul', MailingStateCode = 'MN',OtherCity = 'Saint Paul', OtherStreet = '123 example street', OtherStateCode = 'MN', MailingPostalCode = '55110', OtherPostalCode = '55110', Birthdate = Date.newInstance(1990, 1, 1), Ownership_Pct__c = 99 );
            insert contact;

            Opportunity opp = new Opportunity (Name = 'oppp',  Fraud_PG_Required__c =1, Annual_Revenue__c = 1000000, Requested_Amount__c = 250000, Oppt_FS_Use_Of_Funds__c = 'test', StageName = 'Decision', Points__c = 1, CloseDate = Date.today () + 10, 
                AccountId = acct.Id, Primary_Source__c = 'Direct Mail', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId(), Application_Status__c = 'Manually Approved', Advance_Rental_Amount__c = null,  Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200,  Account_Billing_Street__c = 'test', Loan_Purpose__c = 'testing');
            opp.Payment_Frequency__c = 'Weekly';
            insert opp;

            List<Guarantor__c> guarantors = new List<Guarantor__c>();
            guarantors.add(new Guarantor__c(RecordTypeId = personalRecordTypeId, Opportunity__c = opp.Id, 
                Contact__c = contact.Id, PG_Number__c = 'PG1'));
            guarantors.add(new Guarantor__c(RecordTypeId = corpRecordTypeId, Opportunity__c = opp.Id, 
                Account__c = acct.Id, PG_Number__c = 'PG2'));
            insert guarantors;

            List<Broker__c> brokers = new List<Broker__c>();
            brokers.add(new Broker__c(Opportunity__c = opp.Id, Account__c = acct2.Id));
            insert brokers;

            List<Franchisor__c> franchisors = new List<Franchisor__c>();
            franchisors.add(new Franchisor__c(Opportunity__c = opp.Id,  Franchisor__c = acct3.Id));
            insert franchisors;

            List<Dealer__c> dealers = new List<Dealer__c>();
            dealers.add(new Dealer__c(Opportunity__c = opp.Id,  Dealer__c = acct4.Id, Primary_Dealer__c = false));
            insert dealers;

            OpportunityContactRole ocr = new OpportunityContactRole();
            ocr.OpportunityId = opp.Id;
            ocr.ContactId = contact.Id;
            ocr.IsPrimary = true;
            ocr.Role = 'Dealer Primary Contact';
            insert ocr;

            insert new Webservice_Field__c(Opportunity__c = opp.Id);
        }
    }

    static testMethod void testGetApplicationById(){

        Opportunity opp = [SELECT Id FROM Opportunity];
        String resp;
        test.startTest();
        resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        test.stopTest();
        System.assert (resp != null, 'response should not be null');
    }

    static testMethod void testSaveCompany(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        SL_SCTestData.createIL10FlagSetting();
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.contact.contact = [SELECT FirstName, LastName, MobilePhone, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode FROM Contact];

        clientSideData.contact.contact.FirstName = 'test';
        clientSideData.contact.contact.LastName = 'testl';
        clientSideData.contact.contact.MobilePhone = '1231231234';
        clientSideData.contact.contact.MailingStreet = '123 example street';
        clientSideData.contact.contact.MailingCity = 'star city';
        clientSideData.contact.contact.MailingStateCode = 'MN';
        clientSideData.contact.contact.MailingPostalCode = '55110';
        clientSideData.contact.contact.Email = 'test@test.com';
        clientSideData.contact.contact.ssn__c = '123121234';
        clientSideData.contact.contact.OK_to_Pull_Credit__c = true;
        clientSideData.contact.readOnly = false;
        clientSideData.contact.dupe = false;
        clientSideData.contact.role = 'Dealer Primary Contact';

        clientSideData.company.readOnly = false;
        clientSideData.company.dupe = false;
        clientSideData.company.account.Business_Type__c = 'Partnership';
        clientSideData.company.account.Business_Phone__c = '1231231234';
        clientSideData.company.account.Business_Address__c = '123 example street';
        clientSideData.company.account.Business_City__c = 'Star city';
        clientSideData.company.account.Business_State__c = 'MN';
        clientSideData.company.account.Business_Zip__c = '55110';

        TC_DatabaseUtil.TC_RecordWrapper pgWR = new TC_DatabaseUtil.TC_RecordWrapper ();
        pgWR.saved = true;
        pgWR.contact = new Contact (FirstName = 'asdfasdf', LastName = 'asdfasdf2', MailingStreet = 'asdfasdf', MailingCity = 'asdfasdf', MailingStateCode = 'MN', MailingPostalCode = '99173', Phone = '9998187777', ssn__c = '847398383', Email = 'test@test.com');
        clientSideData.pgContacts = new List <TC_DatabaseUtil.TC_RecordWrapper> {pgWR};

        resp = JSON.serialize(clientSideData);

        BriteVerifyResponse bvResp = new BriteVerifyResponse();
        bvResp.status = 'Valid';
        List<MockCallOutDefinition> defList = new List<MockCallOutDefinition>();
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(bvResp), 200));

        
        try{
            Test.setMock(HttpCalloutMock.class,  new MockCallOut(defList));

            TC_LoanApplicationCtrl.saveCompany(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
        // System.assert (resp != null, 'response should not be null');
    }

    static testMethod void testSaveCompanyContactMIssingFields(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        SL_SCTestData.createIL10FlagSetting();
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.contact.contact = [SELECT FirstName, LastName, MobilePhone, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode FROM Contact];

        clientSideData.contact.contact.FirstName = null;
        clientSideData.contact.contact.LastName= null;
        clientSideData.contact.contact.MobilePhone = null;
        clientSideData.contact.contact.MailingStreet = null;
        clientSideData.contact.contact.MailingCity= null;
        clientSideData.contact.contact.MailingStateCode = null;
        clientSideData.contact.contact.MailingPostalCode = null;
        clientSideData.contact.contact.Email = null;
        clientSideData.contact.contact.ssn__c = '123121234';
        clientSideData.contact.contact.OK_to_Pull_Credit__c = true;
        clientSideData.contact.readOnly = false;
        clientSideData.contact.dupe = false;
        clientSideData.contact.role = null;

        clientSideData.company.readOnly = false;
        clientSideData.company.dupe = false;
        clientSideData.company.account.Business_Type__c = 'Partnership';
        clientSideData.company.account.Business_Phone__c = '1231231234';
        clientSideData.company.account.Business_Address__c = '123 example street';
        clientSideData.company.account.Business_City__c = 'Star city';
        clientSideData.company.account.Business_State__c = 'MN';
        clientSideData.company.account.Business_Zip__c = '55110';

        TC_DatabaseUtil.TC_RecordWrapper pgWR = new TC_DatabaseUtil.TC_RecordWrapper ();
        pgWR.saved = true;
        pgWR.contact = new Contact (FirstName = 'asdfasdf', LastName = 'asdfasdf2', MailingStreet = 'asdfasdf', MailingCity = 'asdfasdf', MailingStateCode = 'MN', MailingPostalCode = '99173', Phone = '9998187777', ssn__c = '847398383', Email = 'test@test.com');
        clientSideData.pgContacts = new List <TC_DatabaseUtil.TC_RecordWrapper> {pgWR};

        resp = JSON.serialize(clientSideData);

        BriteVerifyResponse bvResp = new BriteVerifyResponse();
        bvResp.status = 'Valid';
        List<MockCallOutDefinition> defList = new List<MockCallOutDefinition>();
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(bvResp), 200));

        
        try{
            Test.setMock(HttpCalloutMock.class,  new MockCallOut(defList));

            TC_LoanApplicationCtrl.saveCompany(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
        // System.assert (resp != null, 'response should not be null');
    }

    static testMethod void testSaveCompanyMissingCompanyFields(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        SL_SCTestData.createIL10FlagSetting();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.contact.contact = [SELECT FirstName, LastName, MobilePhone, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode FROM Contact];

        clientSideData.contact.contact.FirstName = 'test';
        clientSideData.contact.contact.LastName = 'testl';
        clientSideData.contact.contact.MobilePhone = '1231231234';
        clientSideData.contact.contact.MailingStreet = '123 example street';
        clientSideData.contact.contact.MailingCity = 'star city';
        clientSideData.contact.contact.MailingStateCode = 'MN';
        clientSideData.contact.contact.MailingPostalCode = '55110';
        clientSideData.contact.contact.Email = 'test@test.com';
        clientSideData.contact.contact.ssn__c = '123121234';
        clientSideData.contact.contact.OK_to_Pull_Credit__c = true;
        clientSideData.contact.readOnly = false;
        clientSideData.contact.dupe = false;
        clientSideData.contact.role = 'Dealer Primary Contact';

        clientSideData.company.readOnly = false;
        clientSideData.company.dupe = false;
        clientSideData.company.account.Business_Type__c = 'Partnership';
        clientSideData.company.account.Business_Phone__c = null;
        clientSideData.company.account.Business_Address__c = null;
        clientSideData.company.account.Business_City__c = null;
        clientSideData.company.account.Business_State__c = null;
        clientSideData.company.account.Business_Zip__c = null;

        TC_DatabaseUtil.TC_RecordWrapper pgWR = new TC_DatabaseUtil.TC_RecordWrapper ();
        pgWR.saved = true;
        pgWR.contact = new Contact (FirstName = 'asdfasdf', LastName = 'asdfasdf2', MailingStreet = 'asdfasdf', MailingCity = 'asdfasdf', MailingStateCode = 'MN', MailingPostalCode = '99173', Phone = '9998187777', ssn__c = '847398383', Email = 'test@test.com');
        clientSideData.pgContacts = new List <TC_DatabaseUtil.TC_RecordWrapper> {pgWR};

        resp = JSON.serialize(clientSideData);

        BriteVerifyResponse bvResp = new BriteVerifyResponse();
        bvResp.status = 'Valid';
        List<MockCallOutDefinition> defList = new List<MockCallOutDefinition>();
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(bvResp), 200));

        
        try{
            Test.setMock(HttpCalloutMock.class,  new MockCallOut(defList));

            TC_LoanApplicationCtrl.saveCompany(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
        // System.assert (resp != null, 'response should not be null');
    }

    static testMethod void testSaveCompanyNoContactId(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        SL_SCTestData.createIL10FlagSetting();
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.contact.contact = [SELECT FirstName, LastName, MobilePhone, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode FROM Contact];

        clientSideData.contact.contact.Id = null;
        clientSideData.contact.contact.FirstName = 'test';
        clientSideData.contact.contact.LastName = 'test';
        clientSideData.contact.contact.MobilePhone = '1231231234';
        clientSideData.contact.contact.MailingStreet = '123 example street';
        clientSideData.contact.contact.MailingCity = 'star city';
        clientSideData.contact.contact.MailingStateCode = 'MN';
        clientSideData.contact.contact.MailingPostalCode = '55110';
        clientSideData.contact.contact.Email = 'test@test.com';
        clientSideData.contact.contact.ssn__c = '123121234';
        clientSideData.contact.contact.OK_to_Pull_Credit__c = true;
        clientSideData.contact.readOnly = false;
        clientSideData.contact.dupe = false;
        clientSideData.contact.role = 'Dealer Primary Contact';

        clientSideData.company.readOnly = false;
        clientSideData.company.dupe = false;
        clientSideData.company.account.Business_Type__c = 'Partnership';
        clientSideData.company.account.Business_Phone__c = '1231231234';
        clientSideData.company.account.Business_Address__c = '123 example street';
        clientSideData.company.account.Business_City__c = 'Star city';
        clientSideData.company.account.Business_State__c = 'MN';
        clientSideData.company.account.Business_Zip__c = '55110';

        TC_DatabaseUtil.TC_RecordWrapper pgWR = new TC_DatabaseUtil.TC_RecordWrapper ();
        pgWR.saved = true;
        pgWR.contact = new Contact (FirstName = 'asdfasdf', LastName = 'asdfasdf2', MailingStreet = 'asdfasdf', MailingCity = 'asdfasdf', MailingStateCode = 'MN', MailingPostalCode = '99173', Phone = '9998187777', ssn__c = '847398383', Email = 'test@test.com');
        clientSideData.pgContacts = new List <TC_DatabaseUtil.TC_RecordWrapper> {pgWR};

        resp = JSON.serialize(clientSideData);

        BriteVerifyResponse bvResp = new BriteVerifyResponse();
        bvResp.status = 'Valid';
        List<MockCallOutDefinition> defList = new List<MockCallOutDefinition>();
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(bvResp), 200));

        
        try{
            Test.setMock(HttpCalloutMock.class,  new MockCallOut(defList));

            TC_LoanApplicationCtrl.saveCompany(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
        // System.assert (resp != null, 'response should not be null');
    }

    static testMethod void testSaveCompanyNullOpportunity(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        SL_SCTestData.createIL10FlagSetting();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.contact.contact = [SELECT FirstName, LastName, MobilePhone, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode FROM Contact];

        clientSideData.contact.contact.FirstName = 'test';
        clientSideData.contact.contact.LastName = 'testl';
        clientSideData.contact.contact.MobilePhone = '1231231234';
        clientSideData.contact.contact.MailingStreet = '123 example street';
        clientSideData.contact.contact.MailingCity = 'star city';
        clientSideData.contact.contact.MailingStateCode = 'MN';
        clientSideData.contact.contact.MailingPostalCode = '55110';
        clientSideData.contact.contact.Email = 'test@test.com';
        clientSideData.contact.contact.ssn__c = '123121234';
        clientSideData.contact.contact.OK_to_Pull_Credit__c = true;
        clientSideData.contact.readOnly = false;
        clientSideData.contact.dupe = false;
        clientSideData.contact.role = 'Dealer Primary Contact';

        clientSideData.company.readOnly = false;
        clientSideData.company.dupe = false;
        clientSideData.company.account.Business_Type__c = 'Partnership';
        clientSideData.company.account.Business_Phone__c = '1231231234';
        clientSideData.company.account.Business_Address__c = '123 example street';
        clientSideData.company.account.Business_City__c = 'Star city';
        clientSideData.company.account.Business_State__c = 'MN';
        clientSideData.company.account.Business_Zip__c = '55110';

        clientSideData.deal.opportunity.id = null;

        TC_DatabaseUtil.TC_RecordWrapper pgWR = new TC_DatabaseUtil.TC_RecordWrapper ();
        pgWR.saved = true;
        pgWR.contact = new Contact (FirstName = 'asdfasdf', LastName = 'asdfasdf2', MailingStreet = 'asdfasdf', MailingCity = 'asdfasdf', MailingStateCode = 'MN', MailingPostalCode = '99173', Phone = '9998187777', ssn__c = '847398383', Email = 'test@test.com');
        clientSideData.pgContacts = new List <TC_DatabaseUtil.TC_RecordWrapper> {pgWR};

        resp = JSON.serialize(clientSideData);

        BriteVerifyResponse bvResp = new BriteVerifyResponse();
        bvResp.status = 'Valid';
        List<MockCallOutDefinition> defList = new List<MockCallOutDefinition>();
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(bvResp), 200));

        
        try{
            Test.setMock(HttpCalloutMock.class,  new MockCallOut(defList));

            TC_LoanApplicationCtrl.saveCompany(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSaveDeal(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        
        TC_LoanApplicationCtrl.saveDeal(resp);
        test.stopTest();
    }


    static testMethod void testSaveDealMissingFields(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.deal.opportunity.Annual_Revenue__c = null;
        resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.saveDeal(resp);
        }catch(Exception ex) {

        }

        test.stopTest();
    }

    static testMethod void testSendApprovedOffers(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        TC_LoanApplicationCtrl.sendApprovedOffers(opp.Id);
        test.stopTest();
    }

    static testMethod void testGetOpportunity(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        TC_LoanApplicationCtrl.getOpportunity(opp.Id);
        test.stopTest();
    }

    static testMethod void testCallDwhAndAutoPgApi(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        update new Opportunity(Id = opp.Id, Requested_Amount__c = 25000, Primary_Source__c = 'Direct Mail', Payment_Frequency__c = 'Monthly', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId(), Application_Status__c = 'Manually Approved', Advance_Rental_Amount__c = null,  Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200,  Account_Billing_Street__c = 'test', Purchase_Options__c = 'Customer Owned');

        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);

        TC_DwhStoredProcedureRespBean respBean = new TC_DwhStoredProcedureRespBean();
        TC_DwhStoredProcedureRespBean.resultBean resultBean = new TC_DwhStoredProcedureRespBean.resultBean();
        resultBean.CustomerType = 'EXISTING';
        resultBean.BizInfoMatch = '10';
        resultBean.RunNewCustomerFlow = '0';
        resultBean.DealerDistance = 1;
        respBean.results.add(resultBean);

        GoogleGeoCodeResponse geoCodeResp = new GoogleGeoCodeResponse();
        GoogleGeoCodeResponse.Result res = new GoogleGeoCodeResponse.Result();
        GoogleGeoCodeResponse.Location location = new GoogleGeoCodeResponse.Location();
        location.lat = '37.52132';
        location.lng = '-123.12312';
        res.geometry.location = location;
        geoCodeResp.results = new List<GoogleGeoCodeResponse.Result> { res };



        List<MockCallOutDefinition> defList = new List<MockCallOutDefinition>();
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(respBean), 200));
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(geoCodeResp), 200));
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(geoCodeResp), 200));
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(respBean), 200));

        
        Test.setMock(HttpCalloutMock.class,  new MockCallOut(defList));
        try{
            TC_LoanApplicationCtrl.callDwhAndAutoPgApi(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testCallDwhAndAutoPgApiBad(){
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = new  TC_DatabaseUtil.TC_ClientWrapper ();
        String resp = JSON.serialize(clientSideData);
        test.startTest();
        try{
            TC_LoanApplicationCtrl.callDwhAndAutoPgApi(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }


    static testMethod void testSaveEquipmenFromASync(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        insert new Asset__c(Opportunity__c = opp.Id, Description__c = 'test', Cost__c = 5000, New_Used__c = 'New', Quantity__c = 1, Equipment_Code__c = 'GPS Unit', End_User_Billing_Address__c = true);
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        
        
        TC_LoanApplicationCtrl.saveEquipment(resp, true, 'save_equipment');
        test.stopTest();
    }

    static testMethod void testSaveEquipmenNotFromAsync(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        insert new Asset__c(Opportunity__c = opp.Id, Description__c = 'test', Cost__c = 5000, New_Used__c = 'New', Quantity__c = 1, Equipment_Code__c = 'GPS Unit', End_User_Billing_Address__c = true);
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        
        TC_LoanApplicationCtrl.saveEquipment(resp, false, 'save_equipment');
        test.stopTest();
    }

    static testMethod void testSaveEquipmenMissingFields(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        insert new Asset__c(Opportunity__c = opp.Id, Description__c = 'test', Cost__c = 5000, New_Used__c = 'New', Quantity__c = 1, Equipment_Code__c = 'GPS Unit', End_User_Billing_Address__c = true);
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.equipment[0].equipment.description__c = null;
        resp = JSON.serialize(clientSideData);

        try{
            TC_LoanApplicationCtrl.saveEquipment(resp, false, 'save_equipment');
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSavePartners() {
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.dealerAccounts[0].readOnly = false;
        clientSideData.dealerAccounts[0].dupe = false;
        clientSideData.dealerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.dealerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.dealerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.dealerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.dealerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.dealerAccounts[0].account.Equipment_Type__c = 'ATM';

        clientSideData.franchisorAccounts[0].readOnly = false;
        clientSideData.franchisorAccounts[0].dupe = false;
        clientSideData.franchisorAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.franchisorAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.franchisorAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.franchisorAccounts[0].account.Business_State__c = 'MN';
        clientSideData.franchisorAccounts[0].account.Business_Zip__c = '55117';


        clientSideData.brokerAccounts[0].readOnly = false;
        clientSideData.brokerAccounts[0].dupe = false;
        clientSideData.brokerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.brokerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.brokerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.brokerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.brokerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.brokerAccounts[0].account.Equipment_Type__c = 'ATM';


        resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.savePartners(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSavePartnersNoAccounts() {
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = new TC_DatabaseUtil.TC_ClientWrapper();
        resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.savePartners(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSavePartnerMissingFranchiseInfo(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.dealerAccounts[0].readOnly = false;
        clientSideData.dealerAccounts[0].dupe = false;
        clientSideData.dealerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.dealerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.dealerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.dealerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.dealerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.dealerAccounts[0].account.Equipment_Type__c = 'ATM';

        clientSideData.franchisorAccounts[0].readOnly = false;
        clientSideData.franchisorAccounts[0].dupe = false;
        clientSideData.franchisorAccounts[0].account.Business_Phone__c =  null;
        clientSideData.franchisorAccounts[0].account.Business_Address__c =  null;
        clientSideData.franchisorAccounts[0].account.Business_City__c =  null;
        clientSideData.franchisorAccounts[0].account.Business_State__c=  null;
        clientSideData.franchisorAccounts[0].account.Business_Zip__c =  null;


        clientSideData.brokerAccounts[0].readOnly = false;
        clientSideData.brokerAccounts[0].dupe = false;
        clientSideData.brokerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.brokerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.brokerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.brokerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.brokerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.brokerAccounts[0].account.Equipment_Type__c = 'ATM';


        resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.savePartners(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSavePartnerNoDealerRole()
    {
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.dealerAccounts[0].readOnly = false;
        clientSideData.dealerAccounts[0].dupe = false;
        clientSideData.dealerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.dealerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.dealerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.dealerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.dealerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.dealerAccounts[0].account.Equipment_Type__c = 'ATM';

        clientSideData.dealerAccounts[0].subRecord = (TC_DatabaseUtil.TC_RecordWrapper) JSON.deserialize(JSON.serialize(clientSideData.dealerAccounts[0]), TC_DatabaseUtil.TC_RecordWrapper.class);
        clientSideData.dealerAccounts[0].subRecord.readOnly = false;
        clientSideData.dealerAccounts[0].subRecord.dupe = false;
        clientSideData.dealerAccounts[0].subRecord.contact = [SELECT FirstName, LastName, MobilePhone, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode FROM Contact];
        clientSideData.dealerAccounts[0].subRecord.role = null;
        clientSideData.dealerAccounts[0].subRecord.contact.FirstName = 'test';
        clientSideData.dealerAccounts[0].subRecord.contact.LastName = 'test';
        clientSideData.dealerAccounts[0].subRecord.contact.MobilePhone = '1231231234';
        clientSideData.dealerAccounts[0].subRecord.contact.MailingStreet = '123 example street';
        clientSideData.dealerAccounts[0].subRecord.contact.MailingCity = 'star city';
        clientSideData.dealerAccounts[0].subRecord.contact.MailingStateCode = 'MN';
        clientSideData.dealerAccounts[0].subRecord.contact.MailingPostalCode = '55110';
        clientSideData.dealerAccounts[0].subRecord.contact.Email = 'test@test.com';

        clientSideData.brokerAccounts[0].readOnly = false;
        clientSideData.brokerAccounts[0].dupe = false;
        clientSideData.brokerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.brokerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.brokerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.brokerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.brokerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.brokerAccounts[0].account.Equipment_Type__c = 'ATM';

        BriteVerifyResponse bvResp = new BriteVerifyResponse();
        bvResp.status = 'Valid';
        List<MockCallOutDefinition> defList = new List<MockCallOutDefinition>();
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(bvResp), 200));


        resp = JSON.serialize(clientSideData);
        //test.startTest();
        try{
            Test.setMock(HttpCalloutMock.class,  new MockCallOut(defList));
            TC_LoanApplicationCtrl.savePartners(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSavePartners3(){

        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.dealerAccounts[0].readOnly = false;
        clientSideData.dealerAccounts[0].dupe = false;
        clientSideData.dealerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.dealerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.dealerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.dealerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.dealerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.dealerAccounts[0].account.Equipment_Type__c = 'ATM';

        clientSideData.dealerAccounts[0].subRecord = (TC_DatabaseUtil.TC_RecordWrapper) JSON.deserialize(JSON.serialize(clientSideData.dealerAccounts[0]), TC_DatabaseUtil.TC_RecordWrapper.class);
        clientSideData.dealerAccounts[0].subRecord.readOnly = false;
        clientSideData.dealerAccounts[0].subRecord.dupe = false;
        clientSideData.dealerAccounts[0].subRecord.contact = [SELECT FirstName, LastName, MobilePhone, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode FROM Contact];
        clientSideData.dealerAccounts[0].subRecord.role = 'Dealer Primary Contact';
        clientSideData.dealerAccounts[0].subRecord.contact.FirstName = 'test';
        clientSideData.dealerAccounts[0].subRecord.contact.LastName = 'test';
        clientSideData.dealerAccounts[0].subRecord.contact.MobilePhone = '1231231234';
        clientSideData.dealerAccounts[0].subRecord.contact.MailingStreet = '123 example street';
        clientSideData.dealerAccounts[0].subRecord.contact.MailingCity = 'star city';
        clientSideData.dealerAccounts[0].subRecord.contact.MailingStateCode = 'MN';
        clientSideData.dealerAccounts[0].subRecord.contact.MailingPostalCode = '55110';
        clientSideData.dealerAccounts[0].subRecord.contact.Email = 'test@test.com';

        clientSideData.brokerAccounts[0].readOnly = false;
        clientSideData.brokerAccounts[0].dupe = false;
        clientSideData.brokerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.brokerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.brokerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.brokerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.brokerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.brokerAccounts[0].account.Equipment_Type__c = 'ATM';


        resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.savePartners(resp);
        }catch(Exception ex) {

        }
        test.stopTest();

    }

    static testMethod void savePartnerMissingContactInfo()
    {    test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity];
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.dealerAccounts[0].readOnly = false;
        clientSideData.dealerAccounts[0].dupe = false;
        clientSideData.dealerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.dealerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.dealerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.dealerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.dealerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.dealerAccounts[0].account.Equipment_Type__c = 'ATM';

        clientSideData.dealerAccounts[0].subRecord = (TC_DatabaseUtil.TC_RecordWrapper) JSON.deserialize(JSON.serialize(clientSideData.dealerAccounts[0]), TC_DatabaseUtil.TC_RecordWrapper.class);
        clientSideData.dealerAccounts[0].subRecord.readOnly = false;
        clientSideData.dealerAccounts[0].subRecord.dupe = false;
        clientSideData.dealerAccounts[0].subRecord.contact = [SELECT FirstName, LastName, MobilePhone, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode FROM Contact];
        clientSideData.dealerAccounts[0].subRecord.role = 'Dealer Primary Contact';
        clientSideData.dealerAccounts[0].subRecord.contact.FirstName = null;
        clientSideData.dealerAccounts[0].subRecord.contact.LastName  = null;
        clientSideData.dealerAccounts[0].subRecord.contact.MobilePhone  = null;
        clientSideData.dealerAccounts[0].subRecord.contact.MailingStreet = null;
        clientSideData.dealerAccounts[0].subRecord.contact.MailingCity = null;
        clientSideData.dealerAccounts[0].subRecord.contact.MailingStateCode  = null;
        clientSideData.dealerAccounts[0].subRecord.contact.MailingPostalCode  = null;
        clientSideData.dealerAccounts[0].subRecord.contact.Email  = null;

        clientSideData.brokerAccounts[0].readOnly = false;
        clientSideData.brokerAccounts[0].dupe = false;
        clientSideData.brokerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.brokerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.brokerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.brokerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.brokerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.brokerAccounts[0].account.Equipment_Type__c = 'ATM';


        resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.savePartners(resp);
        }catch(Exception ex) {

        }
        test.stopTest();

    }

    static testMethod void savePartnerMissingBrokerInfo()
    {
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.dealerAccounts[0].readOnly = false;
        clientSideData.dealerAccounts[0].dupe = false;
        clientSideData.dealerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.dealerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.dealerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.dealerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.dealerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.dealerAccounts[0].account.Equipment_Type__c = 'ATM';

        clientSideData.franchisorAccounts[0].readOnly = false;
        clientSideData.franchisorAccounts[0].dupe = false;
        clientSideData.franchisorAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.franchisorAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.franchisorAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.franchisorAccounts[0].account.Business_State__c = 'MN';
        clientSideData.franchisorAccounts[0].account.Business_Zip__c = '55117';


        clientSideData.brokerAccounts[0].readOnly = false;
        clientSideData.brokerAccounts[0].dupe = false;
        clientSideData.brokerAccounts[0].account.Business_Phone__c = null;
        clientSideData.brokerAccounts[0].account.Business_Address__c = null;
        clientSideData.brokerAccounts[0].account.Business_City__c = null;
        clientSideData.brokerAccounts[0].account.Business_State__c= null;
        clientSideData.brokerAccounts[0].account.Business_Zip__c = null;
        clientSideData.brokerAccounts[0].account.Equipment_Type__c = null;


        resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.savePartners(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSavePartnerMissingDealerInfo(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.dealerAccounts[0].readOnly = false;
        clientSideData.dealerAccounts[0].dupe = false;
        clientSideData.dealerAccounts[0].account.Business_Phone__c = null;
        clientSideData.dealerAccounts[0].account.Business_Address__c = null;
        clientSideData.dealerAccounts[0].account.Business_City__c = null;
        clientSideData.dealerAccounts[0].account.Business_State__c = null;
        clientSideData.dealerAccounts[0].account.Business_Zip__c = null;
        clientSideData.dealerAccounts[0].account.Equipment_Type__c = null;

        clientSideData.franchisorAccounts[0].readOnly = false;
        clientSideData.franchisorAccounts[0].dupe = false;
        clientSideData.franchisorAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.franchisorAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.franchisorAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.franchisorAccounts[0].account.Business_State__c = 'MN';
        clientSideData.franchisorAccounts[0].account.Business_Zip__c = '55117';


        clientSideData.brokerAccounts[0].readOnly = false;
        clientSideData.brokerAccounts[0].dupe = false;
        clientSideData.brokerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.brokerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.brokerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.brokerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.brokerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.brokerAccounts[0].account.Equipment_Type__c = 'ATM';


        resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.savePartners(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSavePartners2() {
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.dealerAccounts[0].readOnly = false;
        clientSideData.dealerAccounts[0].dupe = false;
        clientSideData.dealerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.dealerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.dealerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.dealerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.dealerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.dealerAccounts[0].account.Equipment_Type__c = 'ATM';

        clientSideData.brokerAccounts[0].readOnly = false;
        clientSideData.brokerAccounts[0].dupe = false;
        clientSideData.brokerAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.brokerAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.brokerAccounts[0].account.Business_City__c = 'Star City';
        clientSideData.brokerAccounts[0].account.Business_State__c = 'MN';
        clientSideData.brokerAccounts[0].account.Business_Zip__c = '55117';
        clientSideData.brokerAccounts[0].account.Equipment_Type__c = 'ATM';


        resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.savePartners(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }


    static testMethod void testSavePartnersSad1() {
        test.startTest();
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = new TC_DatabaseUtil.TC_ClientWrapper();
        String resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.savePartners(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSaveQuote(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        
        TC_LoanApplicationCtrl.saveQuote(resp);
        test.stopTest();
    }

    static testMethod void testSaveQuoteGatingNotMet(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        opp.Gating_Criteria_Met__c = 0;
        
        update opp;
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        
        try{
            TC_LoanApplicationCtrl.saveQuote(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSubmitApplication(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        TC_DatabaseUtil.TC_RecordWrapper pgWR = new TC_DatabaseUtil.TC_RecordWrapper ();
        pgWR.saved = true;
        pgWR.contact = new Contact (FirstName = 'asdfasdf', LastName = 'asdfasdf2', MailingStreet = 'asdfasdf', MailingCity = 'asdfasdf', MailingStateCode = 'MN', MailingPostalCode = '99173', Phone = '9998187777', ssn__c = '847398383', Email = 'test@test.com');
        clientSideData.pgContacts = new List <TC_DatabaseUtil.TC_RecordWrapper> {pgWR};
        resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.submitApplication(resp);
        }catch(Exception ex) {

        }

        test.stopTest();
    }


    static testMethod void testSubmitApplicationNoPGSaved(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        TC_DatabaseUtil.TC_RecordWrapper pgWR = new TC_DatabaseUtil.TC_RecordWrapper ();
        pgWR.contact = new Contact (FirstName = 'asdfasdf', LastName = 'asdfasdf2', MailingStreet = 'asdfasdf', MailingCity = 'asdfasdf', MailingStateCode = 'MN', MailingPostalCode = '99173', Phone = '9998187777', ssn__c = '847398383', Email = 'test@test.com');
        clientSideData.pgContacts = new List <TC_DatabaseUtil.TC_RecordWrapper> {pgWR};
        resp = JSON.serialize(clientSideData);
        //test.startTest();
        try{
            TC_LoanApplicationCtrl.submitApplication(resp);
        }catch(Exception ex) {

        }

        test.stopTest();
    }

    static testMethod void testSelectCompany(){
        Account a = [SELECT Id FROM Account LIMIT 1];
        test.startTest();
        TC_LoanApplicationCtrl.selectCompany(a.Id);
        test.stopTest();
    }

    static testMethod void testSelectCompanyBad(){
        test.startTest();
        try{
            TC_LoanApplicationCtrl.selectCompany(null);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSelectGuarantorHappy(){
        test.startTest();
        Account guarantorAccount = new Account (Name = 'test 110704192', Business_Type__c = 'Corporation', Business_Phone__c = '7630000000', 
        Business_Address__c = 'tset', Business_City__c = 'tst', Business_State__c = 'MN', Business_Zip__c = '49485',
        Tax_ID__c = '110704192');
        insert guarantorAccount;
        Contact guarantor = new Contact(AccountId = guarantorAccount.Id, FirstName = 'test', LastName = 'test2', MailingStreet = 'test', MailingCity = 'test', MailingStateCode = 'MN', MailingPostalCode = '99873', Phone = '9998887777', Email = 'test@test.com');
        insert guarantor;
        
        guarantor = TC_LoanApplicationCtrl.selectGuarantor(guarantor.Id);
        test.stopTest();
        System.assert (guarantor != null, 'An contact should have been returned');
    }

    static testMethod void testSelectGuarantorSadPath(){
        Contact guarantor;
        try{
            test.startTest();
            guarantor = TC_LoanApplicationCtrl.selectGuarantor(null);
            test.stopTest();
        }catch(AuraHandledException ex) {
            System.assert (guarantor == null, 'null should have been returned');
        }
    }

    static testMethod void testSelectGuarantorAccountHappy(){
        test.startTest();
        Account guarantorAccount = new Account (Name = 'test 110704191', Business_Type__c = 'Corporation', Business_Phone__c = '7630000000', 
        Business_Address__c = 'tset', Business_City__c = 'tst', Business_State__c = 'MN', Business_Zip__c = '49485',
        Tax_ID__c = '110704191');
        insert guarantorAccount;
        
        guarantorAccount = TC_LoanApplicationCtrl.selectGuarantorAccount(guarantorAccount.Id);
        test.stopTest();
        System.assert (guarantorAccount != null, 'An account should have been returned');
    }

    static testMethod void testSelectGuarantorAccountSadPath(){
        Account guarantorAccount;
        try{
            test.startTest();
            guarantorAccount = TC_LoanApplicationCtrl.selectGuarantorAccount(null);
            test.stopTest();
        }catch(AuraHandledException ex) {
            System.assert (guarantorAccount == null, 'null should have been returned');
        }
    }

    static testMethod void testSaveGuarantors(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp, TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.ccgAccounts[0].readOnly = false;
        clientSideData.ccgAccounts[0].dupe = true;

        clientSideData.ccgAccounts[0].account.Business_Type__c = 'Partnership';
        clientSideData.ccgAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.ccgAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.ccgAccounts[0].account.Business_City__c = 'Star city';
        clientSideData.ccgAccounts[0].account.Business_State__c = 'MN';
        clientSideData.ccgAccounts[0].account.Business_Zip__c = '55110';
        List<TC_DatabaseUtil.TC_RecordWrapper> rwList = new List<TC_DatabaseUtil.TC_RecordWrapper>();
        TC_DatabaseUtil.TC_RecordWrapper rw = new TC_DatabaseUtil.TC_RecordWrapper();
        rw.Contact = new Contact();
        rw.Contact.FirstName = 'test';
        rw.Contact.LastName = 'test';
        rw.Contact.SSNMain__c = '2345';
        
        rw.Contact.OtherStreet = 'street';
        rw.Contact.OtherCity = 'City';
        rw.Contact.OtherStateCode = 'NY';
        rw.Contact.OtherPostalCode = '2345';
        rw.Contact.Birthdate = system.today();
        rw.Contact.Ownership_Pct__c = 100;
        rw.Contact.Email = 'test@test.com';
        //clientSideData.contact = rw;
        rw.dupe = true;
        rwList.add(rw);
        clientSideData.pgContacts = rwList;
        
        resp = JSON.serialize(clientSideData);
        
        system.debug('resp:'+resp);
        try{
            TC_LoanApplicationCtrl.saveGuarantors(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSaveGuarantorsContactMissingFields(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp, TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.ccgAccounts[0].readOnly = false;
        clientSideData.ccgAccounts[0].dupe = false;

        clientSideData.ccgAccounts[0].account.Business_Type__c = 'Partnership';
        clientSideData.ccgAccounts[0].account.Business_Phone__c = '1231231234';
        clientSideData.ccgAccounts[0].account.Business_Address__c = '123 example street';
        clientSideData.ccgAccounts[0].account.Business_City__c = 'Star city';
        clientSideData.ccgAccounts[0].account.Business_State__c = 'MN';
        clientSideData.ccgAccounts[0].account.Business_Zip__c = '55110';

        clientSideData.pgContacts[0].contact.FirstName = null;

        resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.saveGuarantors(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSaveGuarantorsBad(){
        test.startTest();
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = new  TC_DatabaseUtil.TC_ClientWrapper ();
        String resp = JSON.serialize(clientSideData);
        
        try{
            TC_LoanApplicationCtrl.saveGuarantors(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testRunBriteVerifyCheck()
    {
        BriteVerifyResponse bvResp = new BriteVerifyResponse();
        bvResp.status = 'OK';
        List<MockCallOutDefinition> defList = new List<MockCallOutDefinition>();
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(bvResp), 200));
        test.startTest();
        Test.setMock(HttpCalloutMock.class,  new MockCallOut(defList));
        TC_LoanApplicationCtrl.runBriteVerifyCheck(new Set<String> { 'test@test.com'});
        test.stopTest();
    }


    static testMethod void testRunBriteVerifyCheckError()
    {
        BriteVerifyResponse bvResp = new BriteVerifyResponse();
        bvResp.status = 'invalid';
        bvResp.error = 'error';
        List<MockCallOutDefinition> defList = new List<MockCallOutDefinition>();
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(bvResp), 200));
        test.startTest();
        Test.setMock(HttpCalloutMock.class,  new MockCallOut(defList));
        try{
            TC_LoanApplicationCtrl.runBriteVerifyCheck(new Set<String> { 'test@test.com'});
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testSaveGuarantorsNoContactId(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);

        clientSideData.pgContacts[0].contact.id = null;
        clientSideData.pgContacts[0].readOnly = false;
        clientSideData.pgContacts[0].dupe = false;
        resp = JSON.serialize(clientSideData);


        BriteVerifyResponse bvResp = new BriteVerifyResponse();
        bvResp.status = 'OK';

        List<MockCallOutDefinition> defList = new List<MockCallOutDefinition>();
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(bvResp), 200));

        
        try{
            Test.setMock(HttpCalloutMock.class,  new MockCallOut(defList));
            TC_LoanApplicationCtrl.saveGuarantors(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
    }


    static testMethod void testGetCurrentUserProfileName(){
        String profileName;
        test.startTest();
        profileName = TC_LoanApplicationCtrl.getCurrentUserProfileName();
        test.stopTest();
        String currentUserProfileName = [SELECT Id, Name FROM Profile WHERE Id =: UserInfo.getProfileId()].Name;
        System.assertEquals(currentUserProfileName, profileName, 'Profile name should be ' + currentUserProfileName);
    }

    static testMethod void testGetAvailableRecordTypes(){
        List<TC_LoanApplicationCtrl.ProductType> productTypes;
        test.startTest();
        productTypes = TC_LoanApplicationCtrl.getAvailableRecordTypes();
        test.stopTest();
        System.assertEquals(true, productTypes != null && !productTypes.isEmpty(), 'product types should not be null or empty');
    }

    static testMethod void testGrabCustomerContactContactRolesInitial()
    {
        List<TC_DatabaseUtil.LightningPicklist> pickList;
        test.startTest();
        pickList = TC_LoanApplicationCtrl.grabCustomerContactContactRolesInitial();
        test.stopTest();
        System.assert (pickList != null, 'picklist should not be null');
    }

    static testMethod void testCallGdsScoreApex(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        TC_LoanApplicationCtrl.callGdsScoreApex(opp.Id);
        test.stopTest();
    }

    static testMethod void testPopulateCreditAmountField()
    {
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);

        TC_DatabaseUtil.TC_RecordWrapper eqWR = new TC_DatabaseUtil.TC_RecordWrapper ();
        eqWr.equipment = new Asset__c (Orig_Cost__c = 1000, Description__c = 'test', Cost__c = 5000, New_Used__c = 'New', Quantity__c = 1, Equipment_Code__c = '2 Way Radios', End_User_Billing_Address__c = true);
        clientSideData.equipment = new List <TC_DatabaseUtil.TC_RecordWrapper> {eqWr};

        
        TC_LoanApplicationCtrl.populateCreditAmountField(clientSideData);
        test.stopTest();
    }

    static testMethod void testBrokerCheck()
    {
        test.startTest();
        User ifpRep = [SELECT Id FROM User WHERE Username = 'test@marlincapitalsolutions.com'];
        Opportunity opp = [SELECT Id, OwnerId FROM Opportunity];
        opp.OwnerId = ifpRep.Id;
        update opp;

        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.brokerAccounts = new List <TC_DatabaseUtil.TC_RecordWrapper>();
        
        try{
            TC_LoanApplicationCtrl.brokerCheck(clientSideData);
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    static testMethod void testBrokerCheckBad()
    {    test.startTest();
        Opportunity opp = [SELECT Id FROM Opportunity];
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        
        try{
            TC_LoanApplicationCtrl.brokerCheck(clientSideData);
        }catch(Exception ex) {

        }

        test.stopTest();
    }

    static testMethod void testCheckForPrimaryContact()
    {
        Opportunity opp = [SELECT Id FROM Opportunity];
        test.startTest();
        update new Opportunity(Id = opp.Id, Requested_Amount__c = 25000, Primary_Source__c = 'Direct Mail', Payment_Frequency__c = 'Monthly', RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId(), Application_Status__c = 'Manually Approved', Advance_Rental_Amount__c = null,  Application__c = 'test', Equipment_Cost__c = 5000, Equipment_Description__c = 'test', Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0, of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1, Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January', Sec_Dep_Pymts__c = 200,  Account_Billing_Street__c = 'test', Purchase_Options__c = 'Customer Owned');
        
        TC_LoanApplicationCtrl.checkForPrimaryContact(opp);
        test.stopTest();
    }


    static testMethod void testCheckPermissionToPullCreditSad()
    {
        test.startTest();
        try{
            TC_LoanApplicationCtrl.checkPermissionToPullCredit(new Contact(ssn__c = '111111111'));
        }catch(Exception ex) {

        }
        test.stopTest();
    }

    public class MockCallOutDefinition {
        Map<String, String> header;
        String responseBody;
        Integer statusCode;

        public MockCallOutDefinition(Map<String, String> header, String responseBody, Integer statusCode){
            this.responseBody = responseBody;
            this.header = header;
            this.statusCode = statusCode;
        }
        public HttpResponse getResponse(){
            HttpResponse res = new HttpResponse();
            for(String key : this.header.keySet())
            {
                res.setHeader(key, this.header.get(key));
            }
            res.setBody(this.responseBody);
            res.setStatusCode(this.statusCode);
            return res;
        }

    }


    public class MockCallOut implements HttpCalloutMock {
        List<MockCallOutDefinition> mockCallOutDefitions;
        Integer index = 0;
        public MockCallOut(List<MockCallOutDefinition> mockCallOutDefitions){
            this.mockCallOutDefitions = mockCallOutDefitions;
        }
        public HttpResponse respond(HttpRequest req) {
            if( index > mockCallOutDefitions.size() ) return new HttpResponse();
            MockCallOutDefinition def = mockCallOutDefitions.get(index);
            index++;
            return def.getResponse();
        }
    }

        static testMethod void testSaveCompany2(){
        Opportunity opp = [SELECT Id FROM Opportunity];
        SL_SCTestData.createIL10FlagSetting();
        test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp,  TC_DatabaseUtil.TC_ClientWrapper.class);
        clientSideData.contact.contact = [SELECT FirstName, LastName, MobilePhone, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode FROM Contact];

        clientSideData.contact.contact.FirstName = 'test';
        clientSideData.contact.contact.LastName = 'testl';
        clientSideData.contact.contact.MobilePhone = '1231231234';
        clientSideData.contact.contact.MailingStreet = '123 example street';
        clientSideData.contact.contact.MailingCity = 'star city';
        clientSideData.contact.contact.MailingStateCode = 'MN';
        clientSideData.contact.contact.MailingPostalCode = '55110';
        clientSideData.contact.contact.Email = 'test@test.com';
        clientSideData.contact.contact.ssn__c = '123121234';
        clientSideData.contact.contact.OK_to_Pull_Credit__c = true;
        clientSideData.contact.readOnly = true;
        clientSideData.contact.dupe = false;
        clientSideData.contact.role = 'Dealer Primary Contact';
		clientSideData.contact.contact.Id = null;


        clientSideData.company.readOnly = false;
        clientSideData.company.dupe = false;
        clientSideData.company.account.Business_Type__c = 'Partnership';
        clientSideData.company.account.Business_Phone__c = '1231231234';
        clientSideData.company.account.Business_Address__c = '123 example street';
        clientSideData.company.account.Business_City__c = 'Star city';
        clientSideData.company.account.Business_State__c = 'MN';
        clientSideData.company.account.Business_Zip__c = '55110';

        TC_DatabaseUtil.TC_RecordWrapper pgWR = new TC_DatabaseUtil.TC_RecordWrapper ();
        pgWR.saved = true;
        pgWR.contact = new Contact (FirstName = 'asdfasdf', LastName = 'asdfasdf2', MailingStreet = 'asdfasdf', MailingCity = 'asdfasdf', MailingStateCode = 'MN', MailingPostalCode = '99173', Phone = '9998187777', ssn__c = '847398383', Email = 'test@test.com');
        clientSideData.pgContacts = new List <TC_DatabaseUtil.TC_RecordWrapper> {pgWR};

        resp = JSON.serialize(clientSideData);

        BriteVerifyResponse bvResp = new BriteVerifyResponse();
        bvResp.status = 'Valid';
        List<MockCallOutDefinition> defList = new List<MockCallOutDefinition>();
        defList.add(new MockCallOutDefinition(new Map<String, String> {'Content-Type' => 'JSON'}, JSON.serialize(bvResp), 200));

        
        try{
            Test.setMock(HttpCalloutMock.class,  new MockCallOut(defList));

            TC_LoanApplicationCtrl.saveCompany(resp);
        }catch(Exception ex) {

        }
        test.stopTest();
        // System.assert (resp != null, 'response should not be null');
    }

    // @isTest public static void testGetOpportunity (){
    //     Account ac=TestDataFactory.createTestAccount();
    //     Opportunity o=TestDataFactory.createTestOpp(ac.Id);
    //     try{
    //         TC_LoanApplicationCtrl.getOpportunity(o.Id);
    //     }catch(Exception e) {}
    //     try{
    //         TC_LoanApplicationCtrl.sendApprovedOffers(o.Id);
    //     }catch(Exception e) {}

    //     TC_LoanApplicationCtrl.checkForPrimaryContact(o);
    // }
    // @isTest public static void saveWithEquipment () {
    //     // Company
    //     insert new Quick_App_Settings__c (Broker_Record_Type_Label__c = 'Broker Account'
    //                                       , CCG_Junction_Record_Type_Label__c = 'Corporate'
    //                                       , Dealer_Record_Type_Label__c = 'Dealer Account'
    //                                       , End_User_Record_Type_Label__c = 'End User Account'
    //                                       , Franchiosor_Record_Type_Label__c = 'Franchisor Account'
    //                                       , PG_Junction_Record_Type_Label__c = 'Personal');


    //     TC_DatabaseUtil.TC_ClientWrapper clientSideData = new TC_DatabaseUtil.TC_ClientWrapper ();



    //     TC_DatabaseUtil.TC_RecordWrapper companyWR = new TC_DatabaseUtil.TC_RecordWrapper ();
    //     TC_DatabaseUtil.TC_RecordWrapper contactWR = new TC_DatabaseUtil.TC_RecordWrapper ();
    //     TC_DatabaseUtil.TC_RecordWrapper dealWR = new TC_DatabaseUtil.TC_RecordWrapper ();

    //     companyWR.account = new Account (Name = 'test', Business_Type__c = 'Corporation', Business_Phone__c = '7630000000', Business_Address__c = 'tset', Business_City__c = 'tst', Business_State__c = 'MN', Business_Zip__c = '49485');
    //     contactWR.contact = new Contact (FirstName = 'test', LastName = 'test2', MailingStreet = 'test', MailingCity = 'test', MailingStateCode = 'MN', MailingPostalCode = '99873', Phone = '9998887777', Email = 'test@test.com');
    //     contactWR.role = 'Billing Contact';

    //     clientSideData.company = companyWR;
    //     clientSideData.contact = contactWR;
    //     clientSideData.deal = dealWR;

    //     clientSideData.recordTypeName = 'Franchise';

    //     clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(TC_LoanApplicationCtrl.saveCompany (JSON.serialize(clientSideData)), TC_DatabaseUtil.TC_ClientWrapper.class);


    //     // Guarantors


    //     TC_DatabaseUtil.TC_RecordWrapper pgWR = new TC_DatabaseUtil.TC_RecordWrapper ();
    //     TC_DatabaseUtil.TC_RecordWrapper ccgWR = new TC_DatabaseUtil.TC_RecordWrapper ();

    //     pgWR.contact = new Contact (FirstName = 'asdfasdf', LastName = 'asdfasdf2', MailingStreet = 'asdfasdf', MailingCity = 'asdfasdf', MailingStateCode = 'MN', MailingPostalCode = '99173', Phone = '9998187777', ssn__c = '847398383', Email = 'test@test.com');
    //     ccgWR.account = new Account (Name = 'ccg', Business_Phone__c = '7630010000', Business_Address__c = 't1set', Business_City__c = 'ts1t', Business_State__c = 'MN', Business_Zip__c = '49415');


    //     clientSideData.pgContacts = new List <TC_DatabaseUtil.TC_RecordWrapper> {pgWR};
    //     clientSideData.ccgAccounts = new List <TC_DatabaseUtil.TC_RecordWrapper> {ccgWR};
    //     Test.startTest ();
    //     try {
    //         clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(TC_LoanApplicationCtrl.saveGuarantors (JSON.serialize(clientSideData)), TC_DatabaseUtil.TC_ClientWrapper.class);
    //     } catch (Exception e) {
    //         System.debug(e.getMessage());
    //     }

    //     // Deal

    //     clientSideData.deal.opportunity.Primary_Source__c = 'Franchise Direct – Channel Referral';
    //     clientSideData.deal.opportunity.Name = 'appwizardtest';
    //     clientSideData.deal.opportunity.Oppt_Project_Type__c = 'Equipment';

    //     try {
    //         clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(TC_LoanApplicationCtrl.saveDeal (JSON.serialize(clientSideData)), TC_DatabaseUtil.TC_ClientWrapper.class);
    //     } catch (Exception e) {
    //         System.debug(e.getMessage());
    //     }

    //     try {
    //         TC_LoanApplicationCtrl.callDwhAndAutoPgApi (JSON.serialize(clientSideData));
    //     } catch (Exception e) {
    //         System.debug(e.getMessage());
    //     }

    //     try {
    //         TC_LoanApplicationCtrl.populateCreditAmountField (clientSideData);
    //     } catch (Exception e) {
    //         System.debug(e.getMessage());
    //     }

    //     Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c ();
    //     setting.Enable_Debug_Log__c = true;
    //     setting.Mock_Callout__c = true;
    //     setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
    //     setting.SetupOwnerId = UserInfo.getOrganizationId ();
    //     setting.Config_Name__c = 'TEST';
    //     insert setting;


    //     TC_DatabaseUtil.TC_ClientWrapper clientSideData1 = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize (TC_LoanApplicationCtrl.getApplicationById ([SELECT Id FROM Opportunity WHERE Name = 'appwizardtest' LIMIT 1][0].Id), TC_DatabaseUtil.TC_ClientWrapper.class);

    //     //Test.setMock(HttpCalloutMock.class, new TC_BridgewareBookContractCalloutMockImpl ());
    //     Test.setMock(HttpCalloutMock.class, new TC_BridgewareSelectZipGeoCalloutMockImpl ());
    //     // resetting my limits


    //     // Equipment

    //     TC_DatabaseUtil.TC_RecordWrapper eqWR = new TC_DatabaseUtil.TC_RecordWrapper ();
    //     eqWr.equipment = new Asset__c (Description__c = 'test', Cost__c = 5000, New_Used__c = 'New', Quantity__c = 1, Equipment_Code__c = '2 Way Radios', End_User_Billing_Address__c = true);
    //     clientSideData1.equipment = new List <TC_DatabaseUtil.TC_RecordWrapper> {eqWr};
    //     try{
    //         clientSideData1 = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(TC_LoanApplicationCtrl.saveEquipment (JSON.serialize(clientSideData1), true, 'save_equipment'), TC_DatabaseUtil.TC_ClientWrapper.class);
    //     }catch (Exception e) {
    //         System.debug(e.getMessage());
    //     }

    //     clientSideData1 = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(TC_LoanApplicationCtrl.saveQuote (JSON.serialize(clientSideData1)), TC_DatabaseUtil.TC_ClientWrapper.class);

    //     Test.stopTest();


    // }

    // @isTest public static void saveWithPartners () {
    //     // Company
    //     insert new Quick_App_Settings__c (Broker_Record_Type_Label__c = 'Broker Account'
    //                                       , CCG_Junction_Record_Type_Label__c = 'Corporate'
    //                                       , Dealer_Record_Type_Label__c = 'Dealer Account'
    //                                       , End_User_Record_Type_Label__c = 'End User Account'
    //                                       , Franchiosor_Record_Type_Label__c = 'Franchisor Account'
    //                                       , PG_Junction_Record_Type_Label__c = 'Personal');
    //     Account ac=TestDataFactory.createTestAccount();
    //     Opportunity o=TestDataFactory.createTestOpp(ac.Id);

    //     TC_DatabaseUtil.TC_ClientWrapper clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize (TC_LoanApplicationCtrl.getApplicationById ([SELECT Id FROM Opportunity WHERE Name = 'Test opp' LIMIT 1][0].Id), TC_DatabaseUtil.TC_ClientWrapper.class);

    //     // resetting my limits
    //     //Test.startTest();

    //     // Partners
    //     TC_DatabaseUtil.TC_RecordWrapper dealerWR = new TC_DatabaseUtil.TC_RecordWrapper ();
    //     TC_DatabaseUtil.TC_RecordWrapper franchisorWR = new TC_DatabaseUtil.TC_RecordWrapper ();
    //     TC_DatabaseUtil.TC_RecordWrapper brokerWR = new TC_DatabaseUtil.TC_RecordWrapper ();

    //     dealerWR.account = new Account (Name = 'nvks', Business_Phone__c = '7630022200', Business_Address__c = 'osdfasdfsadfasdf', Business_City__c = 'asdfasdfasdfasdf', Business_State__c = 'MN', Business_Zip__c = '49485');
    //     franchisorWR.account = new Account (Name = 'dsfsdfsdfsdfsdfsd', Business_Phone__c = '7630522200', Business_Address__c = 'osdfasdfsaf2dfasdf', Business_City__c = 'asdfasd22fasdfasdf', Business_State__c = 'MN', Business_Zip__c = '49485');
    //     brokerWR.account = new Account (Name = 'fsdfsdeeee', Business_Phone__c = '7630992200', Business_Address__c = 'osdfsadfasdfasdf33saf2dfasdf', Business_City__c = 'asdfasd22fa3sdfasdf3', Business_State__c = 'MN', Business_Zip__c = '49285');

    //     dealerWR.contact = new Contact (FirstName = 'test', LastName = 'test2', MailingStreet = 'test', MailingCity = 'test', MailingStateCode = 'MN', MailingPostalCode = '99873', Phone = '9998887777', Email = 'test@test.com');
    //     brokerWR.contact = new Contact (FirstName = 'test1', LastName = 'test4', MailingStreet = 'test', MailingCity = 'test', MailingStateCode = 'MN', MailingPostalCode = '99873', Phone = '9998887777', Email = 'test2@test.com');
    //     franchisorWR.contact = new Contact (FirstName = 'test3', LastName = 'test5', MailingStreet = 'test', MailingCity = 'test', MailingStateCode = 'MN', MailingPostalCode = '99873', Phone = '9998887777', Email = 'test3@test.com');


    //     clientSideData.dealerAccounts = new List <TC_DatabaseUtil.TC_RecordWrapper> {dealerWR};
    //     clientSideData.franchisorAccounts = new List <TC_DatabaseUtil.TC_RecordWrapper> {franchisorWR};
    //     clientSideData.brokerAccounts = new List <TC_DatabaseUtil.TC_RecordWrapper> {brokerWR};
    //     Test.startTest();


    //     try {
    //         clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(TC_LoanApplicationCtrl.savePartners (JSON.serialize(clientSideData)), TC_DatabaseUtil.TC_ClientWrapper.class);
    //         //clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(TC_LoanApplicationCtrl.submitApplication (JSON.serialize(clientSideData)), TC_DatabaseUtil.TC_ClientWrapper.class);
    //     }catch (Exception e) {

    //     }

    //     try {
    //         //clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(TC_LoanApplicationCtrl.savePartners (JSON.serialize(clientSideData)), TC_DatabaseUtil.TC_ClientWrapper.class);
    //         TC_LoanApplicationCtrl.callDfiOnSubmitToCredit(clientSideData);
    //     }catch (Exception e) {
    //         System.debug(e.getMessage());
    //     }

    //     try {
    //         clientSideData = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(TC_LoanApplicationCtrl.submitApplication (JSON.serialize(clientSideData)), TC_DatabaseUtil.TC_ClientWrapper.class);
    //     }catch (Exception e) {
    //         System.debug(e.getMessage());
    //     }



    //     Test.stopTest();


    // }

    // @isTest
    // public static void testSelectCompany(){
    //     insert new Quick_App_Settings__c (Broker_Record_Type_Label__c = 'Broker Account'
    //                                       , CCG_Junction_Record_Type_Label__c = 'Corporate'
    //                                       , Dealer_Record_Type_Label__c = 'Dealer Account'
    //                                       , End_User_Record_Type_Label__c = 'End User Account'
    //                                       , Franchiosor_Record_Type_Label__c = 'Franchisor Account'
    //                                       , PG_Junction_Record_Type_Label__c = 'Personal');

    //     Boolean hitError = false;

    //     try{
    //         TC_LoanApplicationCtrl.selectCompany(null);
    //     }catch(Exception e) {
    //         hitError = true;
    //     }

    //     System.assert (hitError, 'Error was not hit.');

    // }

/*

    @isTest
    static void testNoApp () {

        Test.startTest();

        TC_LoanApplicationCtrl.getApplicationById(null);

        Test.stopTest();

    }

    @isTest
    static void testWithAppId () {

        Test.startTest();

   //        TC_LoanApplicationCtrl.getApplicationById([SELECT Id FROM Opportunity LIMIT 1].Id);
   //        TC_LoanApplicationCtrl.getCompanyRecordById ([SELECT Id FROM Account LIMIT 1].Id, false);
        Test.stopTest();

    }

    @isTest
    static void testSave () {

        Test.startTest();

        try {
            TC_LoanApplicationCtrl.saveDeal('{"Id":"'+ [SELECT Id FROM Opportunity LIMIT 1].Id +'","Name":"test", "AccountId": "' + [SELECT Id FROM Account LIMIT 1].Id + '"}');
        }
        catch (Exception e) {}

        TC_LoanApplicationCtrl.saveCompany ('{"Id":"'+ [SELECT Id FROM Account LIMIT 1].Id +'","Name":"test","Fed_Tax_ID__c" : "123456789","BillingStreet" : "123 street","BillingStateCode" : "MN","BillingPostalCode" : "12345","Bank_Name__c" : "bank","Bank_Contact__c" : "bank contact","Phone" : "234-234-2345","AnnualRevenue" : "50000", "State_of_Incorporation__c" : "MN"}');

        List<Contact> cons = [SELECT
                              Id,
                              AccountId,
                              FirstName,
                              LastName,
                              ssn__c,
                              MobilePhone,
                              MailingCity,
                              MailingStreet,
                              MailingStateCode,
                              MailingPostalCode,
                              Birthdate
   //                              Guarantor_Ownership__c
                              FROM Contact];
        TC_LoanApplicationCtrl.saveGuarantors (cons);
        Test.stopTest();

    }

    @isTest
    static void testSaveEquipment () {

        Test.startTest();

   //        TC_LoanApplicationCtrl.saveEquipment(new List <Equipment__c> {new Equipment__c(Cost_Per_Unit__c = 100, Name = 'test', Quantity__c = 1)},'{"Id":"'+ [SELECT Id FROM Opportunity LIMIT 1].Id +'","Name":"test", "AccountId": "' + [SELECT Id FROM Account LIMIT 1].Id + '"}');

        Test.stopTest();

    }


    @isTest
    static void testSubmitApp () {

   //        Quote_Setting__mdt quoteSetting = [
   //            SELECT Id
   //                ,Credit_Rating_Config__c
   //                ,Term_Config__c
   //                ,Finance_Type__c
   //                ,Payment_Frequency__c
   //                ,Account_Name_for_Guest_User__c
   //                ,Opp_Stage_Name_on_Create__c
   //            FROM Quote_Setting__mdt
   //            LIMIT 1
   //        ];

        Account a = new Account();
   //        a.Name = quoteSetting.Account_Name_for_Guest_User__c;
   //        a.RecordTypeId = Account.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Broker').getRecordTypeId();

        a.Name = 'Test';
        insert a;

        Contact con = new Contact ();
        con.LastName = 'test_guest';
        con.FirstName = 'test_guest';
        con.AccountId = a.Id;
        insert con;

        Account company = [SELECT Id, Name FROM Account WHERE Id != :a.Id LIMIT 1];
        company.Name = 'test';
   //        company.Fed_Tax_ID__c = '123456789';
        company.BillingStreet = '123 street';
        company.BillingStateCode = 'MN';
        company.BillingPostalCode = '12345';
   //        company.Bank_Name__c = 'bank';
   //        company.Bank_Contact__c = 'bank contact';
        company.Phone = '234-234-2345';
   //        company.Company_Email__c = 'email@email.com';
   //        company.State_of_Incorporation__c = 'MN';
        company.AnnualRevenue = 50000;
        String companyString = JSON.serialize(company);

        Opportunity opp = [SELECT Id, Name FROM Opportunity LIMIT 1];
   //        opp.Credit_Authorization__c = true;
        String dealString = JSON.serialize(opp);

        String guarantorsString = JSON.serialize([SELECT Id, Name, AccountId FROM Contact WHERE AccountId = :company.Id]);

   //        Equipment__c e = new Equipment__c(Cost_Per_Unit__c = 100, Name = 'test', Quantity__c = 1);
   //        e.Opportunity__c = opp.Id;
   //        insert e;

        Test.startTest();

   //        TC_LoanApplicationCtrl.getDependentPicklists();
   //
   //        TC_LoanApplicationCtrl.setIsMasterLine(opp.Id);
   //        TC_LoanApplicationCtrl.getMasterLine (opp.Id);
   //        TC_LoanApplicationCtrl.selectCompany(company.Id);
   //        TC_LoanApplicationCtrl.selectGuarantor(con.Id);

   //        TC_LoanApplicationCtrl.submitApplication(companyString, guarantorsString,  [SELECT Id, Name FROM Equipment__c], dealString);

        Test.stopTest();

    }

    @isTest public static void querySalesUsersTest () {
   //        insert new App_Wizard_Settings__c (Sales_Profile_Name__c = 'System Administrator');

        Test.startTest();
   //        TC_LoanApplicationCtrl.getSalesReps ();
        Test.stopTest();
    }*/
}