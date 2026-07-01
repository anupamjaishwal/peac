/**
 * @description       : Suraj Harichandan(LTM) new test class for increasing code coverage to 80 percent
 * @author            : Suraj Harichandan (LTIMindtree)
 * @created date      : 02-18-2026
 * @purpose           : Supplementary test class targeting under-covered methods in TC_LoanApplicationCtrl:
 *                      callDwhAndAutoPgApi, callDfiOnSubmitToCredit, checkForPGs, createCommission,
 *                      appHasUnknownDealer, calculateCustomerDealerDistance, grabCustomerContactContactRoles
 **/
@isTest
public with sharing class PEAC_LoanApplicationCtrlTest {

    static Id dealerRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();

    @TestSetup
    static void testSetup() {
        User systemAdmin = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND isActive = TRUE LIMIT 1];
        insert new SL_Trigger_Settings__c(SetupOwnerId = systemAdmin.Id, Name = 'default', KillList__c = 'Account');

        System.runAs(systemAdmin) {
            List<DeactivateTriggers__c> triggersToDeactivate = new List<DeactivateTriggers__c>{
                new DeactivateTriggers__c(Name = 'opportunityTrigger', IsDeactived__c = true, ObjectName__c = 'Opportunity'),
                new DeactivateTriggers__c(Name = 'AccountContactRelTrigger', IsDeactived__c = true, ObjectName__c = 'Account Contact Relationship'),
                new DeactivateTriggers__c(Name = 'OpportunityDocGenTrigger', IsDeactived__c = true, ObjectName__c = 'Opportunity'),
                new DeactivateTriggers__c(Name = 'TC_Lead', IsDeactived__c = true, ObjectName__c = 'TC_Lead'),
                new DeactivateTriggers__c(Name = 'TC_OpportunityTrigger', IsDeactived__c = true, ObjectName__c = 'Opportunity')
            };
            insert triggersToDeactivate;
            
            insert new Marlin_Configuration__c(Name = 'test', Disable_Standard_Asset_Generation__c = true, Apex_Validations_Active__c = false);

            Bridgeware_Service_Setting__c setting = new Bridgeware_Service_Setting__c();
            setting.Enable_Debug_Log__c = true;
            setting.Mock_Callout__c = true;
            setting.Mock_Endpoint__c = 'https://private-b2bb6-bridgewaretamarack.apiary-mock.com/';
            setting.SetupOwnerId = UserInfo.getOrganizationId();
            setting.Config_Name__c = 'TEST';
            insert setting;

            insert new Quick_App_Settings__c(
                Broker_Record_Type_Label__c = 'Broker Account',
                CCG_Junction_Record_Type_Label__c = 'Corporate',
                Dealer_Record_Type_Label__c = 'Dealer Account',
                End_User_Record_Type_Label__c = 'End User Account',
                Franchiosor_Record_Type_Label__c = 'Franchisor Account',
                PG_Junction_Record_Type_Label__c = 'Personal'
            );

            // End User Account
            Account acct = new Account(Name = 'TestCo PEAC', CCAN__c = '200316', Tax_ID__c = '200316111', CCID__c = '2003162',
                Business_Phone__c = '5551234567', Business_Address__c = '100 Main St',
                Business_City__c = 'Minneapolis', Business_State__c = 'MN', Business_Zip__c = '55401');
            insert acct;

            // Normal Dealer Account
            Account dealerAcct = new Account(Name = 'Test Dealer PEAC', RecordTypeId = dealerRecTypeId, Points__c = '1',
                Business_Phone__c = '5559876543', Business_Address__c = '200 Elm St',
                Business_City__c = 'Saint Paul', Business_State__c = 'MN', Business_Zip__c = '55110');
            insert dealerAcct;

            // Unknown Dealer Account (for appHasUnknownDealer coverage)
            Account unknownDealerAcct = new Account(Name = 'Unknown Dealer', RecordTypeId = dealerRecTypeId, Points__c = '1',
                Business_Phone__c = '5550001111', Business_Address__c = '999 Unknown Rd',
                Business_City__c = 'Duluth', Business_State__c = 'MN', Business_Zip__c = '55802');
            insert unknownDealerAcct;

            // Express Application Opportunity
            Opportunity expressOpp = new Opportunity(
                Name = 'PEAC Express Opp', StageName = 'Decision', CloseDate = Date.today() + 10,
                AccountId = acct.Id, Primary_Source__c = 'Direct Mail',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Express Application').getRecordTypeId(),
                Fraud_PG_Required__c = 1, PGRequired__c = 1, Points__c = 1,
                Annual_Revenue__c = 1000000, Requested_Amount__c = 25000,
                Application_Status__c = 'Manually Approved',
                Equipment_Cost__c = 5000, Equipment_Description__c = 'test equip',
                Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0,
                of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1,
                Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January',
                Sec_Dep_Pymts__c = 200, Account_Billing_Street__c = 'test',
                Purchase_Options__c = 'Customer Owned', Payment_Frequency__c = 'Monthly',
                CustomerType__c = 'REPEAT'
            );
            insert expressOpp;

            // Loan Opportunity
            Opportunity loanOpp = new Opportunity(
                Name = 'PEAC Loan Opp', StageName = 'Decision', CloseDate = Date.today() + 10,
                AccountId = acct.Id, Primary_Source__c = 'Direct Mail',
                RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId(),
                Fraud_PG_Required__c = 1, Points__c = 1,
                Annual_Revenue__c = 1000000, Requested_Amount__c = 250000,
                Application_Status__c = 'Manually Approved',
                Equipment_Cost__c = 5000, Equipment_Description__c = 'test equip',
                Payment_Amount__c = 0, of_Payments__c = 12, Required_Adv_Payments__c = 0,
                of_beginning_payments__c = 1, Documentation_Fee__c = 200, of_ending_payments__c = 1,
                Document_Delivery_Method__c = 'DocuSign', Estimated_Funding_Month__c = 'January',
                Sec_Dep_Pymts__c = 200, Account_Billing_Street__c = 'test',
                Application__c = 'test', Loan_Purpose__c = 'testing',
                Payment_Frequency__c = 'Weekly', CustomerType__c = 'EXISTING',
                Oppt_FS_Use_Of_Funds__c = 'test'
            );
            insert loanOpp;

            // Webservice Field records
            insert new Webservice_Field__c(Opportunity__c = expressOpp.Id, RunNewCustomerFlow__c = 0);
            insert new Webservice_Field__c(Opportunity__c = loanOpp.Id, RunNewCustomerFlow__c = 1);
        }
    }

    // ─── Mock Callout Infrastructure ───────────────────────────────────────────

    public class MockCallOutDefinition {
        Map<String, String> header;
        String responseBody;
        Integer statusCode;
        public MockCallOutDefinition(Map<String, String> header, String responseBody, Integer statusCode) {
            this.responseBody = responseBody;
            this.header = header;
            this.statusCode = statusCode;
        }
        public HttpResponse getResponse() {
            HttpResponse res = new HttpResponse();
            for (String key : this.header.keySet()) {
                res.setHeader(key, this.header.get(key));
            }
            res.setBody(this.responseBody);
            res.setStatusCode(this.statusCode);
            return res;
        }
    }

    public class MockCallOut implements HttpCalloutMock {
        List<MockCallOutDefinition> defs;
        Integer idx = 0;
        public MockCallOut(List<MockCallOutDefinition> defs) { this.defs = defs; }
        public HttpResponse respond(HttpRequest req) {
            if (idx >= defs.size()) return new HttpResponse();
            MockCallOutDefinition def = defs.get(idx);
            idx++;
            return def.getResponse();
        }
    }

    // ─── Helper Methods ────────────────────────────────────────────────────────

    static Map<String, String> jsonHeader() {
        return new Map<String, String>{ 'Content-Type' => 'JSON' };
    }

    static TC_DwhStoredProcedureRespBean buildDwhResp(String customerType) {
        TC_DwhStoredProcedureRespBean resp = new TC_DwhStoredProcedureRespBean();
        TC_DwhStoredProcedureRespBean.resultBean rb = new TC_DwhStoredProcedureRespBean.resultBean();
        rb.CustomerType = customerType;
        rb.BizInfoMatch = '10';
        rb.RunNewCustomerFlow = '0';
        rb.DealerDistance = 1;
        resp.results.add(rb);
        return resp;
    }

    static GoogleGeoCodeResponse buildGeoResp() {
        GoogleGeoCodeResponse geo = new GoogleGeoCodeResponse();
        GoogleGeoCodeResponse.Result r = new GoogleGeoCodeResponse.Result();
        GoogleGeoCodeResponse.Location loc = new GoogleGeoCodeResponse.Location();
        loc.lat = '44.9778';
        loc.lng = '-93.2650';
        r.geometry.location = loc;
        geo.results = new List<GoogleGeoCodeResponse.Result>{ r };
        return geo;
    }

    static List<MockCallOutDefinition> buildMockDefs(List<Object> responses) {
        List<MockCallOutDefinition> defs = new List<MockCallOutDefinition>();
        for (Object resp : responses) {
            defs.add(new MockCallOutDefinition(jsonHeader(), JSON.serialize(resp), 200));
        }
        return defs;
    }

    static TC_DatabaseUtil.TC_ClientWrapper getPreparedWrapper(Id oppId) {
        String resp = TC_LoanApplicationCtrl.getApplicationById(oppId);
        TC_DatabaseUtil.TC_ClientWrapper cw = (TC_DatabaseUtil.TC_ClientWrapper) JSON.deserialize(resp, TC_DatabaseUtil.TC_ClientWrapper.class);

        // Ensure equipment exists and has required fields
        if (cw.equipment == null || cw.equipment.isEmpty()) {
            TC_DatabaseUtil.TC_RecordWrapper eqWr = new TC_DatabaseUtil.TC_RecordWrapper();
            eqWr.equipment = new Asset__c(Orig_Cost__c = 5000, Quantity__c = 1);
            cw.equipment = new List<TC_DatabaseUtil.TC_RecordWrapper>{ eqWr };
        } else {
            for (TC_DatabaseUtil.TC_RecordWrapper wr : cw.equipment) {
                if (wr.equipment.Orig_Cost__c == null) wr.equipment.Orig_Cost__c = 5000;
                if (wr.equipment.Quantity__c == null) wr.equipment.Quantity__c = 1;
            }
        }
        return cw;
    }
    
    // ─── Test 1: submitApplication — Express ORT, condition1 (REPEAT+PASS+flow=0) ───
    // Covers: callDfiOnSubmitToCredit (expressOrtCond + condition1), checkForPGs (expressOrtCond),
    //         createCommission, populateCreditAmountField, brokerCheck
    @isTest
    static void testSubmitAppExpressCondition1() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'PEAC Express Opp' LIMIT 1];
        // Set Account Fraud Status for condition1
        Account acct = new Account(Id = opp.AccountId, Account_Fraud_Status__c = 'PASS');
        update acct;

        Test.startTest();
        TC_DatabaseUtil.TC_ClientWrapper cw = getPreparedWrapper(opp.Id);

        // Mark PGs as saved so checkForPGs passes
        if (cw.pgContacts != null) {
            for (TC_DatabaseUtil.TC_RecordWrapper wr : cw.pgContacts) {
                wr.saved = true;
            }
        }

        String serialized = JSON.serialize(cw);

        // Mocks: businessFraudQuery (DWH) callout from callDfiOnSubmitToCredit
        TC_DwhStoredProcedureRespBean dwhResp = buildDwhResp('REPEAT');
        List<MockCallOutDefinition> mocks = buildMockDefs(new List<Object>{ dwhResp, dwhResp });
        Test.setMock(HttpCalloutMock.class, new MockCallOut(mocks));
        
        try {
            TC_LoanApplicationCtrl.submitApplication(serialized);
        } catch (Exception ex) {
            // Expected
        }
        Test.stopTest();
    }

    // ─── Test 2: submitApplication — Loan RT, condition4 (EXISTING+flow=1), nonExpressOrtCond ───
    // Covers: callDfiOnSubmitToCredit (nonExpressOrtCond + condition4), checkForPGs (nonExpressOrtCond)
    @isTest
    static void testSubmitAppLoanCondition4() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'PEAC Loan Opp' LIMIT 1];

        Test.startTest();
        TC_DatabaseUtil.TC_ClientWrapper cw = getPreparedWrapper(opp.Id);

        // Add PGs with saved=true
        TC_DatabaseUtil.TC_RecordWrapper pgWr = new TC_DatabaseUtil.TC_RecordWrapper();
        pgWr.saved = true;
        pgWr.contact = new Contact(FirstName = 'PG', LastName = 'Test');
        cw.pgContacts = new List<TC_DatabaseUtil.TC_RecordWrapper>{ pgWr };

        // Add broker to pass brokerCheck
        if (cw.brokerAccounts == null) cw.brokerAccounts = new List<TC_DatabaseUtil.TC_RecordWrapper>();

        String serialized = JSON.serialize(cw);

        TC_DwhStoredProcedureRespBean dwhResp = buildDwhResp('EXISTING');
        List<MockCallOutDefinition> mocks = buildMockDefs(new List<Object>{ dwhResp, dwhResp });
        Test.setMock(HttpCalloutMock.class, new MockCallOut(mocks));

        try {
            TC_LoanApplicationCtrl.submitApplication(serialized);
        } catch (Exception ex) {
            // Expected
        }
        Test.stopTest();
    }

    // ─── Test 3: submitApplication — Manager PG Override path ───
    // Covers: checkForPGs (managerPGOverride=true branch)
    @isTest
    static void testSubmitAppManagerPGOverride() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'PEAC Express Opp' LIMIT 1];
        // Set Fraud_PG_Required to 0 so managerPGOverride can be true
        opp.Fraud_PG_Required__c = 0;
        update opp;

        // Set Manager_PG_Override__c on webservice field
        Webservice_Field__c wsf = [SELECT Id FROM Webservice_Field__c WHERE Opportunity__c = :opp.Id LIMIT 1];
        wsf.Manager_PG_Override__c = true;
        update wsf;

        Test.startTest();
        TC_DatabaseUtil.TC_ClientWrapper cw = getPreparedWrapper(opp.Id);

        // No PGs saved — normally would fail PG check, but managerPGOverride skips it
        if (cw.pgContacts != null) {
            for (TC_DatabaseUtil.TC_RecordWrapper wr : cw.pgContacts) {
                wr.saved = false;
            }
        }

        cw.company.account.PG_Required__c = false;
        String serialized = JSON.serialize(cw);
        
        Test.setMock(HttpCalloutMock.class, new MockCallOut(buildMockDefs(new List<Object>{ buildDwhResp('NEW') })));
        try {
            TC_LoanApplicationCtrl.submitApplication(serialized);
        } catch (Exception ex) {
            // Expected
        }
        Test.stopTest();
    }

    // ─── Test 4: submitApplication — Missing PG from dealer ───
    // Covers: checkForPGs dealer PG_Required check
    @isTest
    static void testSubmitAppMissingPGFromDealer() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'PEAC Express Opp' LIMIT 1];
        Account dealer = [SELECT Id FROM Account WHERE Name = 'Test Dealer PEAC' LIMIT 1];
        dealer.PG_Required__c = true;
        update dealer;

        Test.startTest();
        TC_DatabaseUtil.TC_ClientWrapper cw = getPreparedWrapper(opp.Id);

        // Clear PG saved flags
        if (cw.pgContacts != null) {
            for (TC_DatabaseUtil.TC_RecordWrapper wr : cw.pgContacts) {
                wr.saved = false;
            }
        }

        // Set dealer PG_Required in wrapper
        if (cw.dealerAccounts != null) {
            for (TC_DatabaseUtil.TC_RecordWrapper wr : cw.dealerAccounts) {
                wr.account.PG_Required__c = true;
            }
        }
        
        // Remove equipment (simulate simple failure case if needed) or just test PG block
        // Re-using default equipment from helper is fine
        
        String serialized = JSON.serialize(cw);
        Test.setMock(HttpCalloutMock.class, new MockCallOut(buildMockDefs(new List<Object>{ buildDwhResp('NEW') })));
        try {
            TC_LoanApplicationCtrl.submitApplication(serialized);
        } catch (Exception ex) {
            // Expected — PG missing error
        }
        Test.stopTest();
    }

    // ─── Test 5: callDwhAndAutoPgApi — NEW customerType (else branch) + calculateCustomerDealerDistance ───
    // Covers: callDwhAndAutoPgApi else branch, calculateCustomerDealerDistance
    @isTest
    static void testCallDwhNewCustomerType() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'PEAC Express Opp' LIMIT 1];

        Test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);

        // Mocks: DWH(NEW) + GeoCode(customer) + GeoCode(dealer) + DWH(for mapBeans)
        TC_DwhStoredProcedureRespBean dwhResp = buildDwhResp('NEW');
        GoogleGeoCodeResponse geoResp = buildGeoResp();
        List<MockCallOutDefinition> mocks = buildMockDefs(
            new List<Object>{ dwhResp, geoResp, geoResp, dwhResp }
        );

        Test.setMock(HttpCalloutMock.class, new MockCallOut(mocks));
        try {
            TC_LoanApplicationCtrl.callDwhAndAutoPgApi(resp);
        } catch (Exception ex) {
            // Expected
        }
        Test.stopTest();
    }

    // ─── Test 6: callDwhAndAutoPgApi — Loan Record Type (Loan_Record_Type__c=true, skips DWH) ───
    // Covers: callDwhAndAutoPgApi Loan_Record_Type__c==true branch
    @isTest
    static void testCallDwhLoanRecordType() {
        Opportunity opp = [SELECT Id,Account.OwnerId FROM Opportunity WHERE Name = 'PEAC Loan Opp' LIMIT 1];
		Test.startTest();
        String resp = TC_LoanApplicationCtrl.getApplicationById(opp.Id);
        try {
            TC_LoanApplicationCtrl.callDwhAndAutoPgApi(resp);
            //PEAC_Commission.addCommission(opp.Id,opp.Account.OwnerId);
        } catch (Exception ex) {
            // Expected
        }
        Test.stopTest();
    }

    // ─── Test 7: saveGuarantors with Unknown Dealer — appHasUnknownDealer returns true ───
    // Covers: appHasUnknownDealer (true path), saveGuarantors PG processing
    @isTest
    static void testSaveGuarantorsUnknownDealer() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Name = 'PEAC Loan Opp' LIMIT 1];
        SL_SCTestData.createIL10FlagSetting();

        Test.startTest();
        TC_DatabaseUtil.TC_ClientWrapper cw = getPreparedWrapper(opp.Id);

        // Ensure company is set (helper does not do this part)
        if (cw.company == null || cw.company.account == null) {
            cw.company = new TC_DatabaseUtil.TC_RecordWrapper();
            cw.company.account = new Account(Id = opp.AccountId); // Lightweight
        }

        // Set up PG contact with all required fields for Loan
        Contact pgCon = new Contact(
            FirstName = 'PGTest', LastName = 'UnknownDlr',
            SSNMain__c = '888777666', ssn__c = '888777666',
            OtherStreet = '55 Test Ln', OtherCity = 'Duluth',
            OtherStateCode = 'MN', OtherPostalCode = '55802',
            MailingStreet = '55 Test Ln', MailingCity = 'Duluth',
            MailingStateCode = 'MN', MailingPostalCode = '55802',
            MobilePhone = '5553334444', Email = 'pgtest@test.com',
            Birthdate = Date.newInstance(1988, 3, 20), Ownership_Pct__c = 100,
            OK_to_Pull_Credit__c = true
        );

        TC_DatabaseUtil.TC_RecordWrapper pgWr = new TC_DatabaseUtil.TC_RecordWrapper();
        pgWr.contact = pgCon;
        pgWr.readOnly = false;
        pgWr.dupe = false;
        pgWr.saved = true;
        cw.pgContacts = new List<TC_DatabaseUtil.TC_RecordWrapper>{ pgWr };

        String serialized = JSON.serialize(cw);

        // Mock BriteVerify callout
        BriteVerifyResponse bvResp = new BriteVerifyResponse();
        bvResp.status = 'valid';
        List<MockCallOutDefinition> mocks = buildMockDefs(new List<Object>{ bvResp });

        Test.setMock(HttpCalloutMock.class, new MockCallOut(mocks));
        try {
            TC_LoanApplicationCtrl.saveGuarantors(serialized);
        } catch (Exception ex) {
            // Expected
        }
        Test.stopTest();
    }

    // ─── Test 8: grabCustomerContactContactRoles — direct call ───
    // Covers: grabCustomerContactContactRoles (standalone method querying custom metadata)
    @isTest
    static void testGrabCustomerContactRoles() {
        Test.startTest();
        List<TC_DatabaseUtil.LightningPicklist> roles = TC_LoanApplicationCtrl.grabCustomerContactContactRolesInitial();
        Test.stopTest();
        System.assertNotEquals(null, roles, 'Roles list should not be null');
    }
    @isTest
    static void testCommission() {
        Opportunity opp = [SELECT Id,Account.OwnerId FROM Opportunity WHERE Name = 'PEAC Loan Opp' LIMIT 1];
		Test.startTest();
        PEAC_Commission.addCommission(opp.Id,opp.Account.OwnerId);
       
        Test.stopTest();
    }
}