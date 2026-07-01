@isTest
public class PEAC_OpportunityTriggerHandlerTest {

    @testSetup
    static void setupMethod() {
        PEAC_TestDataFactory.createBridgeWareSetting();
        List<Account> accounts = PEAC_TestDataFactory.createAccount(5);
        List<Contact> contacts = PEAC_TestDataFactory.createContacts(accounts, 1);
        List<Contract__c> contracts = PEAC_TestDataFactory.createContract(accounts, 1);
		List<Opportunity> testOpportunities = PEAC_TestDataFactory.createOpportunities(accounts[4].Id, 1);
        Test.startTest();
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        List<Asset__c> testAssets = PEAC_TestDataFactory.createAssets(accounts[4].Id, testOpportunities, 1);
        Test.stopTest();
    }

    public static Opportunity makeOpp() {
        return new Opportunity(
            Name = 'Opp test',
            StageName = 'Proposal',
            CloseDate = System.today().addDays(10)
            //OwnerId = ownerId,
            //AccountId = a.Id
        );
    }

    /*@isTest
    public static void setBranchTest(){
        Id brokerAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Account').getRecordTypeId();
        Id endUserAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        Account acc = PEAC_TestDataFactory.createAccount(1)[0];
        acc.Dealer_Number__c='603294.1420';
        Opportunity opp = new Opportunity(
            Name = 'Opp test',
            StageName = 'Proposal',
            CloseDate = System.today().addDays(10)
            //OwnerId = ownerId,
            //AccountId = a.Id
        );
        
        Broker__c brk = new Broker__c(Account__c=acc.Id, Primary_Broker__c = true);
        insert brk;
        
        Test.startTest();
        	TC_OpportunityTriggerHandler obj = new TC_OpportunityTriggerHandler();
        	obj.setBranch(opp, brk);
        Test.stopTest();
    }*/
 
    @isTest
    static void insertAndUpdate() {
        Id brokerAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Account').getRecordTypeId();
        List<Account> accounts = [SELECT Name, 
            RecordTypeId,
            Business_Phone__c, tax_ID__c,
            Dealer_Number__c, CCID__c,
            CCAN__c, Account_EU_FS_SIC_Description__c,
            Business_Address__c, Account_Billing_Street__c,
            Business_City__c, Account_Billing_City__c,
            Business_State__c, Account_Billing_State_Province__c,
            Business_Zip__c, Account_Billing_Zip_Postal_Code__c, CurrentCampaign__c FROM Account] ;
		List<Opportunity> testOpportunities = [SELECT Id, AccountId, Actual_Annual_Revenue__c, Actual_Average_Daily_Balance__c,
                                               Annual_Revenue__c, Appeal_Information_Provided__c, Application_Status__c,
                                               Approved_Amount__c, Approved_Document_Delivery_Method__c, Average_Daily_Balance__c,
                                               Billing_Attention_To__c, Broker_Book_Method__c,
                                               Broker_Tax_Method__c, Business_Phone__c, CaseCenter__c,
                                               CloseDate, Contract_Status__c, Custom_Stipulation__c, 
                                               Decision_Date__c, Docs_Out_Dollar__c, Document_Delivery_Method__c,
                                               Equip_Code1__c, Equipment_Cost__c,
                                               Equipment_Description__c, Final_Product_Loc__c,
                                               Funded_Amount__c, Funded_Term__c, Gross_Finance__c, Income_Method__c, Invoice_Code__c,
                                               Invoice_Description__c, Late_Charge_Rate__c, Lead_Invoice_Days__c, Loan_Purpose__c,
                                               Loan_Score__c, Oppt_FS_Use_Of_Funds__c,
                                               Name, StageName, Payment_Amount__c,
                                               RecordTypeId,
                                               Primary_Source__c FROM Opportunity];
        //Test.startTest();
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        List<Asset__c> testAssets = [SELECT Id, Opportunity__c, List_Price__c,
                                               Description__c,
                                               Equipment_Code__c, Property_Status__c, County_Tax_Code__c,
                                               State_Tax_Code__c, City_Tax_Code__c, Equipment_Street__c, 
                                               Equipment_City__c, Equipment_State__c, Equipment_Zip__c,
                                               Equipment_Location_City__c, Equipment_Location_County__c,
                                               Equipment_Location_State__c, Manufacturer__c FROM Asset__c];
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        Asset__c theAsset = testAssets[0];
        testAssets[0].Cost__c = 6001;
        
        Test.startTest();
        Database.SaveResult assetResult = Database.update(theAsset, false);
        //Test.startTest();
        List<Asset__c> assetsAfter = [SELECT Cost__c FROM Asset__c];
        System.assertEquals(6001.00, assetsAfter[0].Cost__c);
        Opportunity opp = testOpportunities[0];
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
    static void branchAssignment1Test() {
        Id brokerAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Account').getRecordTypeId();
        Id endUserAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        List<Account> accounts = [SELECT Name, 
            RecordTypeId,
            Business_Phone__c, tax_ID__c,
            Dealer_Number__c, CCID__c,
            CCAN__c, Account_EU_FS_SIC_Description__c,
            Business_Address__c, Account_Billing_Street__c,
            Business_City__c, Account_Billing_City__c,
            Business_State__c, Account_Billing_State_Province__c,
            Business_Zip__c, Account_Billing_Zip_Postal_Code__c, CurrentCampaign__c FROM Account] ;
        accounts[0].Dealer_Number__c = '603294.1420';
        accounts[0].RecordTypeId = brokerAccountId;
        accounts[1].Dealer_Number__c = '800813.4620';
        accounts[1].RecordTypeId = brokerAccountId;
        accounts[2].RecordTypeId = endUserAccountId;
        
        update accounts;
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        
        //SL_SCTestData.createOpportunitiesAndAssets(accounts[2].Id, 2, 1);
        //List<Opportunity> opportunities = SL_SCTestData.testOpportunities;
        //Test.startTest();
		List<Opportunity> testOpportunities = [SELECT Id, AccountId, Actual_Annual_Revenue__c, Actual_Average_Daily_Balance__c,
                                               Annual_Revenue__c, Appeal_Information_Provided__c, Application_Status__c,
                                               Approved_Amount__c, Approved_Document_Delivery_Method__c, Average_Daily_Balance__c,
                                               Billing_Attention_To__c, Broker_Book_Method__c,
                                               Broker_Tax_Method__c, Business_Phone__c, CaseCenter__c,
                                               CloseDate, Contract_Status__c, Custom_Stipulation__c, 
                                               Decision_Date__c, Docs_Out_Dollar__c, Document_Delivery_Method__c,
                                               Equip_Code1__c, Equipment_Cost__c,
                                               Equipment_Description__c, Final_Product_Loc__c,
                                               Funded_Amount__c, Funded_Term__c, Gross_Finance__c, Income_Method__c, Invoice_Code__c,
                                               Invoice_Description__c, Late_Charge_Rate__c, Lead_Invoice_Days__c, Loan_Purpose__c,
                                               Loan_Score__c, Oppt_FS_Use_Of_Funds__c,
                                               Name, StageName, Payment_Amount__c,
                                               RecordTypeId,
                                               Primary_Source__c FROM Opportunity];
        //Test.startTest();
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        List<Asset__c> testAssets = [SELECT Id, Opportunity__c, List_Price__c,
                                               Description__c,
                                               Equipment_Code__c, Property_Status__c, County_Tax_Code__c,
                                               State_Tax_Code__c, City_Tax_Code__c, Equipment_Street__c, 
                                               Equipment_City__c, Equipment_State__c, Equipment_Zip__c,
                                               Equipment_Location_City__c, Equipment_Location_County__c,
                                               Equipment_Location_State__c, Manufacturer__c FROM Asset__c];
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        Test.startTest();
        List<Broker__c> brokers = new List<Broker__c>{
        //new Broker__c(Opportunity__c=opportunities[0].Id,Account__c=accounts[0].Id, Primary_Broker__c = true),
        new Broker__c(Opportunity__c=testOpportunities[0].Id,Account__c=accounts[1].Id, Primary_Broker__c = true)};
        insert brokers;
        testOpportunities[0].StageName = 'Decision';
        testOpportunities[0].Opportunity_Status__c = 'Credit - In Queue';
        /*testOpportunities[1].StageName = 'Decision';
        testOpportunities[1].Opportunity_Status__c = 'Credit - In Queue';
        testOpportunities[1].Application__c = '0317053';*/
        update testOpportunities;
        Test.stopTest();
        /*List<Opportunity> oppsAfter = [SELECT Id, Branch__c, Application_Submitted__c FROM Opportunity];
        //System.Assert.areEqual('Arboretum', oppsAfter[0].Branch__c);
        System.Assert.areEqual('Lending Tree', oppsAfter[1].Branch__c);
        System.Assert.areNotEqual(null, oppsAfter[1].Application_Submitted__c, 'must populate application submitted date when app # is filled in');// SAL-5297 Misael Romero*/
    }

    @isTest
    static void branchAssignment1Test2() {
        Id brokerAccountId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Broker_Account').getRecordTypeId();
        Id endUserAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        List<Account> accounts = [SELECT Name, 
            RecordTypeId,
            Business_Phone__c, tax_ID__c,
            Dealer_Number__c, CCID__c,
            CCAN__c, Account_EU_FS_SIC_Description__c,
            Business_Address__c, Account_Billing_Street__c,
            Business_City__c, Account_Billing_City__c,
            Business_State__c, Account_Billing_State_Province__c,
            Business_Zip__c, Account_Billing_Zip_Postal_Code__c, CurrentCampaign__c FROM Account] ;
        //accounts[0].Dealer_Number__c = '603294.1420';
        accounts[0].RecordTypeId = brokerAccountId;
        //accounts[1].Dealer_Number__c = '800813.4620';
        accounts[1].RecordTypeId = brokerAccountId;
        accounts[2].RecordTypeId = endUserAccountId;
        
        update accounts;
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        
        //SL_SCTestData.createOpportunitiesAndAssets(accounts[2].Id, 2, 1);
        //List<Opportunity> opportunities = SL_SCTestData.testOpportunities;
        //Test.startTest();
		List<Opportunity> testOpportunities = [SELECT Id, AccountId, Actual_Annual_Revenue__c, Actual_Average_Daily_Balance__c,
                                               Annual_Revenue__c, Appeal_Information_Provided__c, Application_Status__c,
                                               Approved_Amount__c, Approved_Document_Delivery_Method__c, Average_Daily_Balance__c,
                                               Billing_Attention_To__c, Broker_Book_Method__c,
                                               Broker_Tax_Method__c, Business_Phone__c, CaseCenter__c,
                                               CloseDate, Contract_Status__c, Custom_Stipulation__c, 
                                               Decision_Date__c, Docs_Out_Dollar__c, Document_Delivery_Method__c,
                                               Equip_Code1__c, Equipment_Cost__c,
                                               Equipment_Description__c, Final_Product_Loc__c,
                                               Funded_Amount__c, Funded_Term__c, Gross_Finance__c, Income_Method__c, Invoice_Code__c,
                                               Invoice_Description__c, Late_Charge_Rate__c, Lead_Invoice_Days__c, Loan_Purpose__c,
                                               Loan_Score__c, Oppt_FS_Use_Of_Funds__c,
                                               Name, StageName, Payment_Amount__c,
                                               RecordTypeId,
                                               Primary_Source__c FROM Opportunity];
        //Test.startTest();
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        List<Asset__c> testAssets = [SELECT Id, Opportunity__c, List_Price__c,
                                               Description__c,
                                               Equipment_Code__c, Property_Status__c, County_Tax_Code__c,
                                               State_Tax_Code__c, City_Tax_Code__c, Equipment_Street__c, 
                                               Equipment_City__c, Equipment_State__c, Equipment_Zip__c,
                                               Equipment_Location_City__c, Equipment_Location_County__c,
                                               Equipment_Location_State__c, Manufacturer__c FROM Asset__c];
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        Test.startTest();
        List<Broker__c> brokers = new List<Broker__c>{
        //new Broker__c(Opportunity__c=opportunities[0].Id,Account__c=accounts[0].Id, Primary_Broker__c = true),
        new Broker__c(Opportunity__c=testOpportunities[0].Id,Account__c=accounts[1].Id, Primary_Broker__c = true)};
        insert brokers;
        testOpportunities[0].StageName = 'Decision';
        testOpportunities[0].Opportunity_Status__c = 'Credit - In Queue';
        /*testOpportunities[1].StageName = 'Decision';
        testOpportunities[1].Opportunity_Status__c = 'Credit - In Queue';
        testOpportunities[1].Application__c = '0317053';*/
        update testOpportunities;
        Test.stopTest();
        /*List<Opportunity> oppsAfter = [SELECT Id, Branch__c, Application_Submitted__c FROM Opportunity];
        //System.Assert.areEqual('Arboretum', oppsAfter[0].Branch__c);
        System.Assert.areEqual('Lending Tree', oppsAfter[1].Branch__c);
        System.Assert.areNotEqual(null, oppsAfter[1].Application_Submitted__c, 'must populate application submitted date when app # is filled in');// SAL-5297 Misael Romero*/
    }
    
    @isTest
    static void setRepayAmountNDisbursementFormerFlowTest(){
        List<Account> accounts = [SELECT Name, 
            RecordTypeId,
            Business_Phone__c, tax_ID__c,
            Dealer_Number__c, CCID__c,
            CCAN__c, Account_EU_FS_SIC_Description__c,
            Business_Address__c, Account_Billing_Street__c,
            Business_City__c, Account_Billing_City__c,
            Business_State__c, Account_Billing_State_Province__c,
            Business_Zip__c, Account_Billing_Zip_Postal_Code__c, CurrentCampaign__c FROM Account] ;
		List<Opportunity> testOpportunities = [SELECT Id, AccountId, Actual_Annual_Revenue__c, Actual_Average_Daily_Balance__c,
                                               Annual_Revenue__c, Appeal_Information_Provided__c, Application_Status__c,
                                               Approved_Amount__c, Approved_Document_Delivery_Method__c, Average_Daily_Balance__c,
                                               Billing_Attention_To__c, Broker_Book_Method__c,
                                               Broker_Tax_Method__c, Business_Phone__c, CaseCenter__c,
                                               CloseDate, Contract_Status__c, Custom_Stipulation__c, 
                                               Decision_Date__c, Docs_Out_Dollar__c, Document_Delivery_Method__c,
                                               Equip_Code1__c, Equipment_Cost__c,
                                               Equipment_Description__c, Final_Product_Loc__c,
                                               Funded_Amount__c, Funded_Term__c, Gross_Finance__c, Income_Method__c, Invoice_Code__c,
                                               Invoice_Description__c, Late_Charge_Rate__c, Lead_Invoice_Days__c, Loan_Purpose__c,
                                               Loan_Score__c, Oppt_FS_Use_Of_Funds__c,
                                               Name, StageName, Payment_Amount__c,
                                               RecordTypeId,Loan_Record_Type__c, Origination_Fee__c,
                                               Primary_Source__c FROM Opportunity];
        //Test.startTest();
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        List<Asset__c> testAssets = [SELECT Id, Opportunity__c, List_Price__c,
                                               Description__c,
                                               Equipment_Code__c, Property_Status__c, County_Tax_Code__c,
                                               State_Tax_Code__c, City_Tax_Code__c, Equipment_Street__c, 
                                               Equipment_City__c, Equipment_State__c, Equipment_Zip__c,
                                               Equipment_Location_City__c, Equipment_Location_County__c,
                                               Equipment_Location_State__c, Manufacturer__c FROM Asset__c];
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        
        Approved_Offer__c offer = new Approved_Offer__c ();
        offer.Opportunity__c = testOpportunities[0].Id;
        offer.Offer_Amount__c = 1200;
        offer.Max_Rate__c = 1.0;
        offer.Term__c = 12;
        offer.Selected_Offer_Amount__c = 10;
        insert offer;
        testOpportunities[0].RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Loan Opportunity').getRecordTypeId();
        testOpportunities[0].Requested_Amount__c = 1000.00;
        testOpportunities[0].Selected_Approved_Offer__c = offer.Id;
        testOpportunities[0].Origination_Fee__c = 1.00;
        update testOpportunities[0];
        
        Test.startTest();
        TC_OpportunityTriggerHandler obj = new TC_OpportunityTriggerHandler();
        obj.setRepayAmountNDisbursementFormerFlow(testOpportunities[0],true,new List<String>{'StageName'});
        Test.stopTest();
        
    }
    
    @isTest
    static void onOpportunityBookedDateChangeTest(){
        
        List<Opportunity> testOpportunities = [SELECT Id, Opportunity_Booked_Date__c,Loan_Record_Type__c FROM Opportunity];
        
        testOpportunities[0].Opportunity_Booked_Date__c = Datetime.now();
        Test.startTest();
        update testOpportunities[0];
        Test.stopTest();
    }
}