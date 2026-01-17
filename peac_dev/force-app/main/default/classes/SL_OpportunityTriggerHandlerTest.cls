@isTest
public with sharing class SL_OpportunityTriggerHandlerTest {
  private static final String OEG_DEALER_PROFILE = 'OEG Dealer';
  private static final String USERNAME = 'Portal.SL.test.user@silverlinecrm.com';

    @isTest
    static void insertAndUpdate() {
        Id brokerAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Account').getRecordTypeId();
        SL_SCTestData.createAccountAndContracts(5, 1);
        List<Account> accounts = SL_SCTestData.testAccounts;
        
        SL_SCTestData.createOpportunitiesAndAssets(accounts[4].Id, 1, 1);
        Asset__c theAsset = SL_SCTestData.testAssets[0];
        theAsset.Cost__c = 6001;
        Test.startTest();
        Database.SaveResult assetResult = Database.update(theAsset, false);
        
        List<Asset__c> assetsAfter = [SELECT Cost__c FROM Asset__c];
        System.assertEquals(6001.00, assetsAfter[0].Cost__c);
        Opportunity opp = SL_SCTestData.testOpportunities[0];
        opp.StageName = 'Application';
        opp.Program__c = 'XBS';
        opp.Decisioned_By__c ='Test User';
        assetResult = Database.update(opp, false);
        Test.stopTest();
        
        if(assetResult.getErrors().size()>0){
            System.debug('Error is: '+assetResult.getErrors()[0].getMessage());
            System.assert(assetResult.getErrors()[0].getMessage().contains('Cannot Increase Equipment Cost past '));
        }
        assert.areEqual('SF-', [SELECT Portal_User_ID__c FROM Opportunity WHERE Id = :opp.Id].Portal_User_ID__c);
    }

    @isTest
    static void branchAssignment1() {
        Id brokerAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Account').getRecordTypeId();
        Id endUserAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        TestDataFactory.prepareAccounts(3, brokerAccountId, '');
        List<Account> accounts = TestDataFactory.testAccounts;
        accounts[0].Dealer_Number__c = '603294.1420';
        accounts[1].Dealer_Number__c = '800813.4620';
        accounts[2].RecordTypeId = endUserAccountId;
        
        insert accounts;
        
        SL_SCTestData.createOpportunitiesAndAssets(accounts[2].Id, 2, 1);
        List<Opportunity> opportunities = SL_SCTestData.testOpportunities;
        Test.startTest();
        List<Broker__c> brokers = new List<Broker__c>{
        //new Broker__c(Opportunity__c=opportunities[0].Id,Account__c=accounts[0].Id, Primary_Broker__c = true),
        new Broker__c(Opportunity__c=opportunities[1].Id,Account__c=accounts[1].Id, Primary_Broker__c = true)};
        insert brokers;
        opportunities[0].StageName = 'Decision';
        opportunities[0].Opportunity_Status__c = 'Credit - In Queue';
        opportunities[1].StageName = 'Decision';
        opportunities[1].Opportunity_Status__c = 'Credit - In Queue';
        opportunities[1].Application__c = '0317053';
        update opportunities;
        Test.stopTest();
        List<Opportunity> oppsAfter = [SELECT Id, Branch__c, Application_Submitted__c FROM Opportunity];
        //System.Assert.areEqual('Arboretum', oppsAfter[0].Branch__c);
        System.Assert.areEqual('Lending Tree', oppsAfter[1].Branch__c);
        System.Assert.areNotEqual(null, oppsAfter[1].Application_Submitted__c, 'must populate application submitted date when app # is filled in');// SAL-5297 Misael Romero
    }

    // @isTest
    // static void branchAssignment2() {
    //     Id dealerVendorId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
    //     Id endUserAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
    //     TestDataFactory.prepareAccounts(3, dealerVendorId, '');
    //     List<Account> accounts = TestDataFactory.testAccounts;
    //     accounts[0].Dealer_Number__c = '734895.5002';
    //     accounts[2].RecordTypeId = endUserAccountId;
    //     SL_SCTestData.testUser.Vendor_Team__c = 'IFP';
    //     update SL_SCTestData.testUser;
    //     System.runAs(SL_SCTestData.testUser){
    //         insert accounts;
    //     }
    //     User testUser = SL_SCTestData.testUser;
    //     testUser.Vendor_Team__c = 'DLG';
    //     update testUser;
    //     SL_SCTestData.createOpportunitiesAndAssets(accounts[2].Id, 3, 1);
    //     List<Opportunity> opportunities = SL_SCTestData.testOpportunities;
    //     Test.startTest();
    //     List<Dealer__c> dealers = new List<Dealer__c>{
    //         new Dealer__c(Opportunity__c = opportunities[0].Id, Primary_Dealer__c = true, Dealer__c = accounts[0].Id),
    //         new Dealer__c(Opportunity__c = opportunities[2].Id, Primary_Dealer__c = true, Dealer__c = accounts[1].Id)
    //     };
    //     insert dealers;
    //     opportunities[0].StageName = 'Decision';
    //     opportunities[0].Opportunity_Status__c = 'Credit - In Queue';
    //     opportunities[1].StageName = 'Decision';
    //     opportunities[1].Opportunity_Status__c = 'Credit - In Queue';
    //     opportunities[1].OwnerId = testUser.Id;
    //     opportunities[2].StageName = 'Decision';
    //     opportunities[2].Opportunity_Status__c = 'Credit - In Queue';
    //     update opportunities;
        
    //     Test.stopTest();
    //     List<Opportunity> oppsAfter = [SELECT Id, Branch__c FROM Opportunity];
    //     System.assertEquals('Arrow', oppsAfter[0].Branch__c);
    //     System.assertEquals('NJ Retail', oppsAfter[1].Branch__c);
    //     System.assertEquals('IFP - Indirect Funding Pl', oppsAfter[2].Branch__c);
    // }

    // @isTest
    // static void branchAssignment3() {
    //     Id dealerVendorId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
    //     Id endUserAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
    //     TestDataFactory.prepareAccounts(3, dealerVendorId, 'CT&I Field');
    //     List<Account> accounts = TestDataFactory.testAccounts;
    //     //accounts[1].Account_Branch__c = 'IFP - Indirect Funding Pl';
    //     accounts[2].RecordTypeId = endUserAccountId;
    //     SL_SCTestData.testUser.Vendor_Team__c = 'CTIF';
    //     update SL_SCTestData.testUser;
    //     System.runAs(SL_SCTestData.testUser){
    //         insert accounts;
    //     }
    //     User testUser = SL_SCTestData.testUser;
    //     testUser.Vendor_Team__c = 'HC';
    //     update testUser;
    //     SL_SCTestData.createOpportunitiesAndAssets(accounts[2].Id, 3, 1);
    //     List<Opportunity> opportunities = SL_SCTestData.testOpportunities;
    //     Test.startTest();
    //     List<Dealer__c> dealers = new List<Dealer__c>{
    //         new Dealer__c(Opportunity__c = opportunities[1].Id, Primary_Dealer__c = true, Dealer__c = accounts[0].Id)/*,
    //         new Dealer__c(Opportunity__c = opportunities[2].Id, Primary_Dealer__c = true, Dealer__c = accounts[1].Id)*/
    //     };
    //     insert dealers;
    //     opportunities[0].StageName = 'Decision';
    //     opportunities[0].Opportunity_Status__c = 'Credit - In Queue';
    //     opportunities[0].OwnerId = testUser.Id;
    //     opportunities[1].StageName = 'Decision';
    //     opportunities[1].Opportunity_Status__c = 'Credit - In Queue';
    //     //opportunities[2].StageName = 'Decision';
    //     //opportunities[2].Opportunity_Status__c = 'Credit - In Queue';
    //     update opportunities;
        
    //     Test.stopTest();
        
    //     List<Opportunity> oppsAfter = [SELECT Id, Branch__c FROM Opportunity];
    //     System.assertEquals('Healthcare Division', oppsAfter[0].Branch__c);
    //     System.assertEquals('CT&I Field', oppsAfter[1].Branch__c);
    //     //System.assertEquals('IFP - Indirect Funding Pl', oppsAfter[2].Branch__c);
    // }

    @isTest
    static void branchAssignment6() {
        Id dealerVendorId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
        Id endUserAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        TestDataFactory.prepareAccounts(3, dealerVendorId, '');
        List<Account> accounts = TestDataFactory.testAccounts;
        accounts[1].RecordTypeId = endUserAccountId;
        SL_SCTestData.testUser.Vendor_Team__c = 'OEG NC';
        update SL_SCTestData.testUser;
        Integer queriesConsumed = 0;
        System.runAs(SL_SCTestData.testUser){
            insert accounts;
        }
        
        SL_SCTestData.createOpportunitiesAndAssets(accounts[1].Id, 3, 1);
        List<Opportunity> opportunities = SL_SCTestData.testOpportunities;
        List<Dealer__c> dealers = new List<Dealer__c>{
            //new Dealer__c(Opportunity__c = opportunities[0].Id, Primary_Dealer__c = true, Dealer__c = accounts[0].Id),
            new Dealer__c(Opportunity__c = opportunities[0].Id, Primary_Dealer__c = false, Dealer__c = accounts[2].Id)
        };
        Test.startTest();
        insert dealers;
        System.debug('queries after insert dealers (account): ' + System.Limits.getQueries());
        queriesConsumed = System.Limits.getQueries() - queriesConsumed;
        System.assertEquals('OEG Non-Copier', [select account_branch__c from account where id = :accounts[0].Id limit 1].Account_Branch__c);
        opportunities[0].StageName = 'Decision';
        opportunities[0].Opportunity_Status__c = 'Credit - In Queue';
        update opportunities;
        System.debug('queries after update Opportunity: ' + System.Limits.getQueries());
        queriesConsumed = System.Limits.getQueries() - queriesConsumed;
        
        Test.stopTest();
        List<Opportunity> oppsAfter = [SELECT Id, Branch__c FROM Opportunity];
        //System.Assert.areEqual('OEG Non-Copier', oppsAfter[0].Branch__c);
    }

    // @isTest
    // static void resubmitAndRescore() {
    //     Id dealerVendorId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
    //     Id endUserAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
    //     Id tfgDocsId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('TFG_Docs').getRecordTypeId();
    //     TestDataFactory.prepareAccounts(2, dealerVendorId, '');
    //     List<Account> accounts = TestDataFactory.testAccounts;
    //     accounts[1].RecordTypeId = endUserAccountId;
    //     Integer queriesConsumed = 0;
    //     insert accounts;
    //     SL_SCTestData.createOpportunitiesAndAssets(accounts[1].Id, 3, 1);
    //     List<Opportunity> opportunities = SL_SCTestData.testOpportunities;
    //     List<Dealer__c> dealers = new List<Dealer__c>{
    //         new Dealer__c(Opportunity__c = opportunities[0].Id, Primary_Dealer__c = true, Dealer__c = accounts[0].Id)
    //     };
    //     User u = TestDataFactory.createTestUser();
    //     Test.startTest();
    //     insert dealers;
    //     Asset__c theAsset = SL_SCTestData.testAssets[0];
    //     theAsset.List_Price__c = 6001;
    //     update theAsset;
    //     queriesConsumed = System.Limits.getQueries() - queriesConsumed;
    //     opportunities[0].StageName = 'Decision';
    //     opportunities[0].Opportunity_Status__c = 'Credit - In Queue';
    //     opportunities[0].RecordTypeId = tfgDocsId;
    //     opportunities[0].Credit_Decision__c = false;
    //     opportunities[0].Resubmitted_to_Credit__c = true;
    //     System.runAs(u){
    //         update opportunities;
    //         System.debug('queries after update Opportunity: ' + System.Limits.getQueries());
    //         queriesConsumed = System.Limits.getQueries() - queriesConsumed;
    //     }
    //     Test.stopTest();
    // }
    
    @isTest
    static void securityDepositCalculation() {
        Id loanOppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId();
        //Id loanFundingId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Funding').getRecordTypeId();
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Account> accounts = SL_SCTestData.testAccounts;
        accounts[0].DBA__c = '987654321';
        accounts[0].Account_Billing_State_Province__c = 'AZ';
        accounts[0].Date_Established__c = Date.today().addYears(-1);
        //accounts[0].AnnualRevenue = 100.00;
        
        update accounts;
        Test.startTest();
        SL_SCTestData.createOpportunitiesAndAssets(accounts[0].Id, 2, 1);
        
        List<Opportunity> opps = SL_SCTestData.testOpportunities;
        
        opps[0].Sec_Dep_Pymts__c = 4;
        opps[0].Payment_Amount__c = 5;
        opps[1].Funded__c = Date.today();
        opps[1].Opportunity_Booked_Date__c = null;
        // opps[1].StageName = 'Booking';
        // opps[1].Opportunity_Status__c = 'Booking - In Process';
        // opps[1].Assign_To_CMS_User__c = SL_SCTestData.testUser.Id;
        opps[1].DBA_Override__c = null;
        opps[1].Lessor__c = 10;
        /*opps[2].RecordtypeId = loanOppId;
        opps[2].Requested_Amount__c = 100;
        //opps[3].Application_Status__c = 'Booked';
        opps[4].Booked_to_External_System_Date__c = Date.today();
        opps[4].of_ending_payments__c = 2;
        opps[4].Payment_Amount__c = 30;
        opps[4].Equipment_Cost__c = 3000;
        opps[4].Contract_Type__c = 'XX';
        System.debug('opps[4].Payment_Amount__c: ' + opps[4].Payment_Amount__c);*/
        update opps;
        Test.stopTest();
        List<Opportunity> oppsAfter = [SELECT Security_Deposit__c, DBA_Override__c, Region__c, Years_in_Business__c,
            Annual_Revenue__c, StageName, RecordTypeId, Application_Status__c, Ending_Pymts_in_Advance__c, Is_TL_RL_or_OL__c, Portal_User_ID__c,
            Funded__c, Opportunity_Booked_Date__c
             FROM Opportunity];
        System.assertEquals(20, oppsAfter[0].Security_Deposit__c);
        //System.assertEquals(oppsAfter[1].Funded__c, oppsAfter[1].Opportunity_Booked_Date__c);
        System.assertEquals(accounts[0].DBA__c, oppsAfter[1].DBA_Override__c);
        System.assertEquals('000', oppsAfter[1].Region__c);
        //System.assertEquals(1, oppsAfter[2].Years_in_Business__c);
        //System.assertEquals(100.00, oppsAfter[2].Annual_Revenue__c);
        // System.assertEquals('Funding (Loan)', oppsAfter[3].StageName);
        // System.assertEquals(loanFundingId, oppsAfter[3].RecordTypeId);
        //System.assertEquals('Booked', oppsAfter[4].Application_Status__c);
        //System.assertEquals(true, oppsAfter[4].Is_TL_RL_or_OL__c);
        //System.Assert.areEqual('SF-',oppsAfter[0].Portal_User_ID__c, 'SF- must be stamped when creating from Salesforce');
        //System.Assert.areEqual(60, oppsAfter[4].Ending_Pymts_in_Advance__c);
    }

    @isTest
    static void refactorOfManyFlows() {
        Id loanOppId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId();
        Id loanFundingId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Funding').getRecordTypeId();
        List<Database.SaveResult> oppResults;
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Account> accounts = SL_SCTestData.testAccounts;
        List<Contact> contacts = SL_SCTestData.testContacts;
        // accounts[0].DBA__c = '987654321';
        // accounts[0].Account_Billing_State_Province__c = 'AZ';
        // accounts[0].Date_Established__c = Date.today().addYears(-1);
        //accounts[0].AnnualRevenue = 100.00;
        // update accounts;
        SL_SCTestData.createOpportunitiesAndAssets(accounts[0].Id, 2, 1);
        List<Opportunity> opps = SL_SCTestData.testOpportunities;
        Test.startTest();
        Approved_Offer__c approvedOffer = new Approved_Offer__c(Offer_Amount__c = 100, Max_Rate__c = 2, Select__c = true,
            Selected_Frequency__c = 'Weekly', Opportunity__c = opps[0].Id);
        insert approvedOffer;
        opps[0].Origination_Fee__c = 0.30;
        opps[0].Renewal_Payoff_Amount__c = 400;
        opps[0].StageName = 'Review for Booking';
        opps[0].Opportunity_Status__c = null;
        opps[0].RecordtypeId = loanOppId;
        opps[1].Application_Status__c = 'Incomplete';
        opps[1].Bank_Statement_Status__c = 'Complete';
        opps[1].RecordtypeId = loanOppId;
        opps[1].Opportunity_Status__c = 'Credit - In Queue'; // for stageName = 'Decision'
        opps[1].Commencement_Date__c = Date.newInstance(2023, 1, 1);
        opps[1].First_Payment_Date__c = Date.newInstance(2023, 4, 1);
        oppResults = Database.update(opps, false);
        Test.stopTest();
        List<Opportunity> oppsAfter = [SELECT Repayment_Amount__c, StageName, Payments_In_Arrears__c FROM Opportunity];
        if(!oppResults[0].isSuccess()){
            System.debug(oppResults[0].getErrors()[0]?.getMessage());
            System.debug(oppResults[0].getErrors()[0]);
        }
        if(!oppResults[1].isSuccess()){
            System.debug(oppResults[1].getErrors()[0]?.getMessage());
            System.debug(oppResults[1].getErrors()[0]);
        }
        // System.assertEquals(200, oppsAfter[0].Repayment_Amount__c);
        System.assertEquals('Decision', oppsAfter[1].StageName);
        System.assertEquals(true, oppsAfter[1].Payments_In_Arrears__c);
        
    }

    @isTest
    static void refactorOfClasses2() {
        ORE__c o = new ORE__c(Bypass__c = true);
        insert o;
        list<Profile> cmsProfiles = [SELECT Id FROM Profile WHERE Name ='CMS'];
        User u = SL_SCTestData.createTestUser(cmsProfiles[0].Id);
        Id dealerVendorId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Dealer_Vendor').getRecordTypeId();
        List<Database.SaveResult> oppResults;
        System.runAs(u){
            SL_SCTestData.createAccountAndContracts(6, 1);
            List<Account> accounts = SL_SCTestData.testAccounts;
            List<Contact> contacts = SL_SCTestData.testContacts;
            Test.startTest();
            SL_SCTestData.createOpportunitiesAndAssets(accounts[0].Id, 3, 1);
            List<Opportunity> opps = SL_SCTestData.testOpportunities;
            accounts[4].Preferred_Dealer_Level__c = '1';
            accounts[4].RecordTypeId = dealerVendorId;
            update accounts[4];
            
            opps[0].StageName = 'Docs Requested';
            opps[0].Docs_In__c = Datetime.now();
            opps[1].StageName = 'Docs Requested';
            opps[1].Docs_Out__c = Datetime.now();
            oppResults = Database.update(opps, false);
        }
        Test.stopTest();
        // covered classes TC_DocsIn TC_DocsOut
        if(!oppResults[0].isSuccess()){
            System.debug(oppResults[0].getErrors()[0]?.getMessage());
            System.debug(oppResults[0].getErrors()[0]);
        }
    }

    @isTest
    static void test_PortalOpportunityApexSharing(){
        User testAdmin = SL_SCTestData.createTestUser();
        User u = null;
        Account portalAccount = new Account(name = 'portalAccount', Business_Phone__c = '1234567890');//create a portal account first
        Opportunity oppCreated;
        System.runAs(testAdmin){
            INSERT portalAccount;
            
            Contact portalContact = new contact(LastName = 'portalContact', FirstName = 'Test', AccountId = portalAccount.Id); //create a portal contact
            INSERT portalContact;
            u = new User(Alias = 'testuser', Email = 'marlinbusiness@peacsolutions.com', EmailEncodingKey='UTF-8',
                LastName = 'testing', FirstName = 'user', LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US', ProfileId = [SELECT Id, Name FROM Profile WHERE Name = :OEG_DEALER_PROFILE].Id, TimeZoneSidKey = 'America/Los_Angeles',
                Username = USERNAME, Doc_Fee_Exception_Approver__c = true, PortalRole = 'Manager', ContactId = portalContact.Id,
                IsPrmSuperUser = true);
            INSERT u;
        } 
        User portalUser = [SELECT Id, Contact.AccountId FROM User WHERE Id = :u.Id];
        Id PROGRAM_APPLICATION_RT_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get('SNAP_Application').getRecordTypeId();
        Opportunity opp = new Opportunity(Name = 'Test Opp Portal', AccountId = portalAccount.Id, StageName = 'Quote', RecordTypeId = PROGRAM_APPLICATION_RT_ID,
                            CloseDate = Date.today(), Terms__c = 12, Equipment_Cost__c = 1500, Equipment_Description__c = 'Test',
                            Dealer_Account__c = portalAccount.Id, Dealer_User__c = u.Id);
        System.runAs(u){
            Map<Id, List<Opportunity>> mapOppByDealerAcc = new Map<Id, List<Opportunity>>();
            
            Test.startTest();
            TC_OpportunityTriggerHandler.SITE_ID = 'Test Portal';
            INSERT opp;
            mapOppByDealerAcc.put(portalAccount.Id, new List<Opportunity>{opp});
            Set<String> removedDealerIds = new Set<String>();
            Set<Id> removedDealerUserIds = new Set<Id>{u.Id};
            SL_OpportunityTriggerHandler.OppShare(mapOppByDealerAcc, removedDealerIds, removedDealerUserIds);
            // DP-1860 Misael Romero
            Boolean isNew = false;
            List<String> fieldsChanged = new List<String>{'Dealer_Account__c'};
            Map<Id, SObject> oldMap = new Map<Id, SObject>();
            opp.Dealer_Account__c = portalAccount.Id;
            oldMap.put(opp.Id, opp);
            Opportunity newOpp = opp.clone(true, true, true, true);
            newOpp.Dealer_Account__c = null;
            newOpp.Dealer_User__c = u.Id;
            SL_OpportunityTriggerHandler.removeDealerAccountUser(newOpp, isNew, fieldsChanged, oldMap, portalUser);
            System.Assert.areEqual(null, newOpp.Dealer_User__c, 'must clear dealer user when dealer account is removed');
            Test.stopTest();
        }
        oppCreated = [SELECT Id, OwnerId, Portal_User_ID__c FROM Opportunity WHERE Id = :opp.Id];
        Assert.areNotEqual(u.Id, oppCreated.OwnerId, 'Owner of the Dealer Account must be set as the Opportunity Owner.');
        // PortalUserIDTest
        System.Assert.areEqual('DP-',oppCreated.Portal_User_ID__c, 'DP- must be stamped when creating from the Experience Site');
        Assert.areNotEqual(UserInfo.getUserId(), oppCreated.OwnerId, 'Owner of the Dealer Account must be set as the Opportunity Owner.');
        
    }

    // SAL-5486 once the cpu problem is fixed try this
    // @isTest
    // static void portalOpportunityApexSharing2(){
    //     SL_SCTestData.createAccountAndContracts(2, 1);
    //     User testAdmin = SL_SCTestData.testUser;
    //     User dpUser = null;
    //     Account portalAccount = SL_SCTestData.testAccounts[1];
    //     List<Opportunity> oppCreated;
    //     System.runAs(testAdmin){
    //         dpUser = SL_SCTestData.createDPDataForUser(portalAccount);
    //     } 
    //     SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
    //     System.runAs(dpUser){
    //         Opportunity opp = SL_SCTestData.testOpportunities[0];
    //         Test.startTest();
    //         Dealer__c testDealer = new Dealer__c(Opportunity__c = opp.Id, Dealer__c = portalAccount.Id,
    //             Funded__c = false, Primary_Dealer__c = true);
    //         insert testDealer;
    //         Test.stopTest();
    //         oppCreated = [SELECT Id, OwnerId, Portal_User_ID__c FROM Opportunity WHERE Id = :opp.Id];
    //         Assert.areEqual(1, oppCreated.size(), 'Expecting to have access to the record created.');
    //     }
    // }

    
    //DP-1615 Misael Romero
    // @IsTest
    // public static void DealerAccountTest(){
        
    //     Id PROGRAM_APPLICATION_RT_ID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('HKF Opportunity').getRecordTypeId();
    //     SL_SCTestData.createAccountAndContracts(2,1);
    //     //Id UserRoleId = [Select id from UserRole Where Name='System Admin' LIMIT 1].Id;
    //     /*User TestU = SL_SCTestData.createTestUser();
    //     TestU.ProfileId = p;
    //     TestU.UserRoleId = UserRole;
    //     TestU.IsPortalEnabled = true;
    //     TestU.IsPrmSuperUser = true;*/
        
    //     //Dealer account and related contct for user
    //     Integer n = 1 + 2;
    //         Account acc = new Account (Name = (String.valueOf(n) + ' test Customer'), 
    //         RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId(),
    //         Business_Phone__c = String.valueOf(1234567890 + n).left(10),
    //         tax_ID__c = String.valueOf(111000000 + n),
    //         Dealer_Number__c = String.valueOf(111000000 + n).left(18),
    //         CCID__c = String.valueOf(1234567890 + n).right(7),
    //         CCAN__c = String.valueOf(1234567890 + n).right(10));        
    //     insert acc;
    //     Integer uniqueNumber = 1 + 2;
    //         Contact c = new Contact (AccountId = acc.Id, FirstName = 'test' + uniqueNumber,
    //              LastName = 'testbeni' + uniqueNumber, OtherStreet = 'test', OtherCity = 'test', 
    //              OtherStateCode = 'MN', OtherPostalCode = String.valueOf(11111 + uniqueNumber).left(5), Title = 'title' + uniqueNumber, 
    //              SSN__c = String.valueOf(111111111 + uniqueNumber).left(9), BirthDate = Date.today (),
    //              Email = 'test@email' + String.valueOf(11111 + uniqueNumber) + '.com', Validity_Verify__Status__c = 'Valid');
    //     insert c;        
        
    //     Opportunity TestOp = new Opportunity(Name = 'Test Opp Dealer Acc', AccountId = SL_SCTestData.testAccounts[0].Id, StageName = 'Quote',
    //                         CloseDate = Date.today(), Terms__c = 12, Equipment_Cost__c = 1500, Equipment_Description__c = 'Test',RecordTypeId = PROGRAM_APPLICATION_RT_ID);
    //     Opportunity TestOp2 = new Opportunity(Name = 'Test Opp Dealer Acc', AccountId = SL_SCTestData.testAccounts[0].Id, StageName = 'Quote',
    //                         CloseDate = Date.today(), Terms__c = 12, Equipment_Cost__c = 1500, Equipment_Description__c = 'Test',RecordTypeId = PROGRAM_APPLICATION_RT_ID);
    //     Dealer__c testDealer = new Dealer__c(Dealer__c = acc.Id, Funded__c = false, Primary_Dealer__c = true);
    //     List<Opportunity> TestOps = new List<Opportunity>();
    //     Test.startTest();
    //     insert TestOp;
    //     testDealer.Opportunity__c = TestOp.Id;
    //     insert testDealer;
    //     TestOp.Primary_Dealer__c = testDealer.Id;
    //     TestOp2.Primary_Dealer__c = testDealer.Id;
    //     TestOps.add(TestOp);
    //     TestOps.add(TestOp2);
    //     upsert TestOps;       
    //     Test.stopTest();
        
    // }

    @isTest
    static void testSendStatusChangeEmailAlert_Rejected() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        
        Account testAccount = [SELECT Id, Name FROM Account LIMIT 1];

        SL_SCTestData.createOpportunitiesAndAssets(testAccount.Id, 1, 1);
        
        Opportunity testOpp = [SELECT Id, Name, Opportunity_Status__c, Dealer_User__c FROM Opportunity WHERE AccountId = :testAccount.Id LIMIT 1];

        testOpp.StageName = 'Proposal';
        testOpp.Opportunity_Status__c = 'Rejected';
        testOpp.Dealer_User__c = SL_SCTestData.testUser.id;
        //update testOpp;

        List<String> fieldsChanged = new List<String>{'Opportunity_Status__c'};

        Test.startTest();
        SL_OpportunityTriggerHandler.sendStatusChangeEmailAlert(testOpp, fieldsChanged);
        Test.stopTest();
    }
    
    @isTest
    static void UCCFeesTest(){
        SL_SCTestData.createAccountAndContracts(1, 1);      
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 4, 1);
        Opportunity opp1DocsIn = SL_SCTestData.testOpportunities[0];
        Opportunity opp2Booking = SL_SCTestData.testOpportunities[1];
        Opportunity oppAnalistApproved = SL_SCTestData.testOpportunities[2];
        Opportunity oppXbs = SL_SCTestData.testOpportunities[3];
        //Opportunity oppNonXbsNonApproved = SL_SCTestData.testOpportunities[4];
        opp1DocsIn.Equipment_Cost__c = 50001;
        opp1DocsIn.Program__c='XBS';
        opp1DocsIn.StageName='Docs In';
        opp2Booking.Equipment_Cost__c=50001;
        opp2Booking.Program__c='XBS';
        opp2Booking.StageName='Booking';
        User creditUser = new User(Id = SL_SCTestData.testUser.Id, XBS_Risk_Analyst__c = true);
        oppAnalistApproved.Application_Status__c = 'Manually Approved';
        oppAnalistApproved.Assigned_Credit_User__c = creditUser.Id;
        oppAnalistApproved.Lessor__c = 401;
        oppXbs.Program__c = 'XBS';
        List<Opportunity> oppTest = new List<Opportunity>();
        oppTest.add(opp2Booking);
        oppTest.add(opp1DocsIn);
        Map<Id, List<Miscellaneous_Invoice_Item__c>> miscInvoiceItems = new Map<Id, List<Miscellaneous_Invoice_Item__c>>();
        List<Miscellaneous_Invoice_Item__c> misInvItem = new List<Miscellaneous_Invoice_Item__c>();
        List<String> fieldsChanged = new List<String>{'StageName'};
        Map<Id, List<Blended_Income_Item__c>> blendedIncomeItems = new Map<Id, List<Blended_Income_Item__c>>();
        Test.startTest();
        SL_OpportunityTriggerHandler.UCCFees(opp2Booking, miscInvoiceItems, misInvItem, fieldsChanged, blendedIncomeItems);
        SL_OpportunityTriggerHandler.UCCFees(opp1DocsIn, miscInvoiceItems, misInvItem, fieldsChanged, blendedIncomeItems);
        Map<ID,User> assignedCreditUser = new Map<Id, User>{creditUser.Id => creditUser};
        fieldsChanged = new List<String>{'Lessor__c'};
        SL_OpportunityTriggerHandler.setLessorCode(oppAnalistApproved, assignedCreditUser, fieldsChanged);
        SL_OpportunityTriggerHandler.setLessorCode(oppXbs, assignedCreditUser, fieldsChanged);
        //SL_OpportunityTriggerHandler.setLessorCode(oppNonXbsNonApproved, assignedCreditUser, fieldsChanged);
        System.Assert.areEqual(111, oppAnalistApproved.Lessor__c, 'if manually approved by xbs analist lessor code is 111, in stages up to Proposal');
        System.Assert.areEqual(211, oppXbs.Lessor__c, 'if not manually approved by xbs analist, but program contains XBS lessor code is 211, in stages up to Proposal');
        //System.Assert.areEqual(null, oppNonXbsNonApproved.Lessor__c, 'if not manually approved by xbs analist, and program does not contains XBS lessor code is not auto-populated');
        oppAnalistApproved.StageName = 'Docs Requested';
        oppAnalistApproved.Lessor__c = 401;
        SL_OpportunityTriggerHandler.setLessorCode(oppAnalistApproved, assignedCreditUser, fieldsChanged);
        System.Assert.areEqual(401, oppAnalistApproved.Lessor__c, 'Lessor code can be overwritten by user or gds after Proposal');
        oppAnalistApproved.Lessor__c = 401;
        oppAnalistApproved.Program__c = 'XBS';
        fieldsChanged.clear();
        oppXbs.Assigned_Credit_User__c = creditUser.Id;
        oppXbs.Application_Status__c = null;
        oppXbs.Lessor__c = 003;
        SL_OpportunityTriggerHandler.setLessorCode(oppAnalistApproved, assignedCreditUser, fieldsChanged);
        fieldsChanged.add('Program__c');
        SL_OpportunityTriggerHandler.setLessorCode(oppXbs, assignedCreditUser, fieldsChanged);
        Test.stopTest();
        System.Assert.areEqual(401, oppAnalistApproved.Lessor__c, 'Lessor code is Not automatically populated after Proposal');
        System.Assert.areEqual(211, oppXbs.Lessor__c, 'Lessor code is 211 if creditUser is null but program includes XBS');
    }

    @isTest
    static void emailAlertsFormerWorkFlows(){
        SL_SCTestData.createAccountAndContracts(1, 1);      
        SL_SCTestData.createOpportunitiesAndAssets(SL_SCTestData.testAccounts[0].Id, 1, 1);
        Opportunity opp = SL_SCTestData.testOpportunities[0];
        TC_RecursiveTriggerHelper.oppsAlreadyEmailAlerted.clear();
        List<String> fieldsChanged = new List<String>{'Application__c'};
        Boolean isNew = false;
        opp.Application__c = '04010258';
        Test.startTest();
        Map<Id, List<String>> emailTemplatesByOppId = new Map<Id, List<String>>();
        emailTemplatesByOppId = SL_OpportunityTriggerHandler.emailAlertsFormerWorkFlows(opp, isNew, fieldsChanged, emailTemplatesByOppId);
        System.Assert.areEqual('SalesSubmitted', emailTemplatesByOppId.get(Opp.Id)[0], 'Email template must be SalesSubmitted');

        TC_RecursiveTriggerHelper.oppsAlreadyEmailAlerted.clear();
        fieldsChanged = new List<String>{'Credit_Decision__c'};
        opp.Application_Status__c = 'Manually Approved';
        opp.Credit_Decision__c = true;
        emailTemplatesByOppId = new Map<Id, List<String>>();
        emailTemplatesByOppId = SL_OpportunityTriggerHandler.emailAlertsFormerWorkFlows(opp, isNew, fieldsChanged, emailTemplatesByOppId);
        System.Assert.areEqual('SalesApproved', emailTemplatesByOppId.get(Opp.Id)[0], 'Email template must be SalesApproved');
        TC_RecursiveTriggerHelper.oppsAlreadyEmailAlerted.clear();
        fieldsChanged = new List<String>{'Application_Status__c'};
        opp.Application_Status__c = 'Automatically Approved';
        emailTemplatesByOppId = new Map<Id, List<String>>();
        emailTemplatesByOppId = SL_OpportunityTriggerHandler.emailAlertsFormerWorkFlows(opp, isNew, fieldsChanged, emailTemplatesByOppId);
        System.Assert.areEqual('SalesApproved', emailTemplatesByOppId.get(Opp.Id)[0], 'Email template must be SalesApproved');
        TC_RecursiveTriggerHelper.oppsAlreadyEmailAlerted.clear();
        fieldsChanged = new List<String>{'Resubmitted_to_Credit__c'};
        opp.Resubmitted_to_Credit__c = false;
        emailTemplatesByOppId = new Map<Id, List<String>>();
        emailTemplatesByOppId = SL_OpportunityTriggerHandler.emailAlertsFormerWorkFlows(opp, isNew, fieldsChanged, emailTemplatesByOppId);
        System.Assert.areEqual('SalesApproved', emailTemplatesByOppId.get(Opp.Id)[0], 'Email template must be SalesApproved');

        TC_RecursiveTriggerHelper.oppsAlreadyEmailAlerted.clear();
        fieldsChanged = new List<String>{'Application_Status__c'};
        opp.Application_Status__c = 'Rejected';
        emailTemplatesByOppId = new Map<Id, List<String>>();
        emailTemplatesByOppId = SL_OpportunityTriggerHandler.emailAlertsFormerWorkFlows(opp, isNew, fieldsChanged, emailTemplatesByOppId);
        System.Assert.areEqual('SalesDecline', emailTemplatesByOppId.get(Opp.Id)[0], 'Email template must be SalesDecline');
        TC_RecursiveTriggerHelper.oppsAlreadyEmailAlerted.clear();
        fieldsChanged = new List<String>{'Resubmitted_to_Credit__c'};
        opp.Resubmitted_to_Credit__c = false;
        emailTemplatesByOppId = new Map<Id, List<String>>();
        emailTemplatesByOppId = SL_OpportunityTriggerHandler.emailAlertsFormerWorkFlows(opp, isNew, fieldsChanged, emailTemplatesByOppId);
        System.Assert.areEqual('SalesDecline', emailTemplatesByOppId.get(Opp.Id)[0], 'Email template must be SalesDecline');

        TC_RecursiveTriggerHelper.oppsAlreadyEmailAlerted.clear();
        fieldsChanged = new List<String>{'Application_Status__c'};
        opp.Application_Status__c = 'Returned to Submitter';
        emailTemplatesByOppId = new Map<Id, List<String>>();
        emailTemplatesByOppId = SL_OpportunityTriggerHandler.emailAlertsFormerWorkFlows(opp, isNew, fieldsChanged, emailTemplatesByOppId);
        System.Assert.areEqual('SalesPending', emailTemplatesByOppId.get(Opp.Id)[0], 'Email template must be SalesPending');
        TC_RecursiveTriggerHelper.oppsAlreadyEmailAlerted.clear();
        fieldsChanged = new List<String>{'Resubmitted_to_Credit__c'};
        opp.Resubmitted_to_Credit__c = false;
        opp.Application_Status__c = 'More Info';
        emailTemplatesByOppId = new Map<Id, List<String>>();
        emailTemplatesByOppId = SL_OpportunityTriggerHandler.emailAlertsFormerWorkFlows(opp, isNew, fieldsChanged, emailTemplatesByOppId);
        System.Assert.areEqual('SalesPending', emailTemplatesByOppId.get(Opp.Id)[0], 'Email template must be SalesPending');
        // SAL-3883 Misael Romero
        isNew = true;
        opp.Payment_Option__c = 'N';
        SL_OpportunityTriggerHandler.populateInvoiceDataFormerFlow(opp, isNew, fieldsChanged);
        System.Assert.areEqual('A', opp.Invoice_Code__c, 'when payment option = N, Invoice code must be A on new opp');
        System.Assert.areEqual(22, opp.Lead_Invoice_Days__c, 'when payment option = N, lead invoice days must be 22 on new opp');
        isNew = false;
        fieldsChanged = new List<String>{'Payment_Option__c'};
        opp.Payment_Option__c = 'U';
        SL_OpportunityTriggerHandler.populateInvoiceDataFormerFlow(opp, isNew, fieldsChanged);
        System.Assert.areEqual('S', opp.Invoice_Code__c, 'when payment option = U, Invoice code must be S (Inv Suppressed) on update');
        System.Assert.areEqual(3, opp.Lead_Invoice_Days__c, 'when payment option = U, lead invoice days must be 3 on update');
        fieldsChanged = new List<String>{'Payment_Option__c', 'Invoice_Code__c', 'Lead_Invoice_Days__c'};
        opp.Invoice_Code__c = 'C';
        opp.Lead_Invoice_Days__c = 4;
        SL_OpportunityTriggerHandler.populateInvoiceDataFormerFlow(opp, isNew, fieldsChanged);
        System.Assert.areEqual('C', opp.Invoice_Code__c, 'when user sets invoice Code system does not overwrite');
        System.Assert.areEqual(4, opp.Lead_Invoice_Days__c, 'when user sets lead invoice days system does not overwrite');
        // SAL-5486 Misael Romero
        Map<Id, Asset__c> assetsToUpdateById = new Map<Id, Asset__c>();
        Map<Id, List<Asset__c>> assets = new Map<Id, List<Asset__c>>{opp.Id => SL_SCTestData.testAssets};
        Map<Id, List<Blended_Income_Item__c>> blendedIncomeItems = new Map<Id, List<Blended_Income_Item__c>>{
            opp.Id => new List<Blended_Income_Item__c>{new Blended_Income_Item__c(Opportunity__c = opp.Id)}};
        Map<Id, Blended_Income_Item__c> biisToUpdateById = new Map<Id, Blended_Income_Item__c>();
        isNew = true;
        fieldsChanged = new List<String>();
        opp.Opportunity_Booked_Date__c = Datetime.now();
        opp.Commencement_Date__c = Date.today();
        opp.Contract_Type__c = 'RL';
        SL_OpportunityTriggerHandler.bulkUpdateAssetsFromFlows(opp, isNew, fieldsChanged,
            assets, assetsToUpdateById);
        SL_OpportunityTriggerHandler.bookingRulesDepreciationDatesFormerFlow(opp, isNew, fieldsChanged,
            blendedIncomeItems, biisToUpdateById);
        System.Assert.areEqual(1, biisToUpdateById.values().size(), 'updates the Begin_Date__c with Commencement date');
        System.Assert.areEqual(1, assetsToUpdateById.values().size(), 'depreciationDates updates the Begin_Depreciation_Date__c with Booked date');
        isNew = false;
        assetsToUpdateById.clear();
        fieldsChanged = new List<String>{'StageName'};
        opp.Tax_Exempt__c = 'Yes';
        opp.StageName = 'Booking';
        SL_OpportunityTriggerHandler.bulkUpdateAssetsFromFlows(opp, isNew, fieldsChanged,
            assets, assetsToUpdateById);
        System.Assert.areEqual(1, assetsToUpdateById.values().size(), 'taxCode031 and deprecFieldsNull update a lot of fields.');
        System.Assert.areEqual('031', assetsToUpdateById.values()[0].City_Tax_Code__c, 'taxCode031 updates tax fields to 031.');
        System.Assert.areEqual(false, assetsToUpdateById.values()[0].Calculate_ACE_Depr__c, 'deprecFieldsNull update a lot of fields to null or false.');
        assetsToUpdateById.clear();
        fieldsChanged = new List<String>{'Contract_Type__c'};
        opp.Purchase_Options__c = 'Customer Owned';
        opp.StageName = 'Funding';
        SL_OpportunityTriggerHandler.bulkUpdateAssetsFromFlows(opp, isNew, fieldsChanged,
            assets, assetsToUpdateById);
        System.Assert.areEqual('050', assetsToUpdateById.values()[0].County_Tax_Code__c, 'taxCode050 updates tax fields to 050.');
        assetsToUpdateById.clear();
        fieldsChanged = new List<String>{'Purchase_Options__c'};
        opp.Purchase_Options__c = 'FMV';
        SL_OpportunityTriggerHandler.bulkUpdateAssetsFromFlows(opp, isNew, fieldsChanged,
            assets, assetsToUpdateById);
        System.Assert.areEqual(null, assetsToUpdateById.values()[0].State_Tax_Code__c, 'taxCodeNull updates tax fields to null.');
        // SAL-5432 Misael Romero
        // opp.StageName = 'Decision';
        // opp.Application_Status__c = 'Returned to Submitter';
        // fieldsChanged = new List<String>{'Primary_Dealer__c'};
        // List<Id> idsToRescore = new List<Id>();
        // SL_OpportunityTriggerHandler.rescoreWhenPrimaryDealerChanges(opp, fieldsChanged, idsToRescore);
        Test.stopTest();
        // System.Assert.areEqual(1, idsToRescore.size(), 'send opp to rescore if primary dealer changed');// SAL-5432 Misael Romero
        
    }
}