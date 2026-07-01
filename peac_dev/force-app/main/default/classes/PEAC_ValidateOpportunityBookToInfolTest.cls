@IsTest
public class PEAC_ValidateOpportunityBookToInfolTest {
    
    @testSetup
    static void setupData() {
        List<Account> accounts = PEAC_TestDataFactory.createAccount(5);
        List<Contact> contacts = PEAC_TestDataFactory.createContacts(accounts, 1);
        List<Contract__c> contracts = PEAC_TestDataFactory.createContract(accounts, 1);
		List<Opportunity> testOpportunities = PEAC_TestDataFactory.createOpportunities(accounts[4].Id, 1);
        Test.startTest();
        System.debug(LoggingLevel.INFO, 'Number of SOQL queries used: ' + Limits.getQueries());
        List<Asset__c> testAssets = PEAC_TestDataFactory.createAssets(accounts[4].Id, testOpportunities, 1);
        Test.stopTest();
    }

    @IsTest
    static void test_happyPath_returnsTrue() {
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

        // Insert a SUCCESS log as the latest
        Integration_Log__c latestSuccess = new Integration_Log__c(
            Name = 'Infolease Booking Request',
            Opportunity__c = testOpportunities[0].Id,
            Status__c = 'Success'
        );
        insert latestSuccess;
        Test.setCreatedDate(latestSuccess.Id, DateTime.now());

        Test.startTest();
        Boolean result = PEAC_ValidateOpportunityBookToInfolease.validateOpportunityForBookToInfoleaseProcess(testOpportunities[0].Id);
        Test.stopTest();
    }

    @IsTest
    static void test_getAssetBatchLimit_noDML() {

        Decimal limit1 = PEAC_ValidateOpportunityBookToInfolease.getAssetBatchLimit();
        Decimal limit2 = PEAC_ValidateOpportunityBookToInfolease.getAssetBatchLimit();

        // Assertions
        System.assertNotEquals(
            null,
            limit1,
            'Asset batch limit should never be null'
        );

        System.assertEquals(
            limit1,
            limit2,
            'Second call should return cached asset batch limit'
        );
    }

    @IsTest
    static void testGetLatestInfoleaseIntegrationDetails() {
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

        // Insert a SUCCESS log as the latest
        Integration_Log__c latestSuccess = new Integration_Log__c(
            Name = 'Infolease Booking Request',
            Opportunity__c = testOpportunities[0].Id,
            Status__c = 'Success'
        );
        insert latestSuccess;
        Test.setCreatedDate(latestSuccess.Id, DateTime.now());

        Test.startTest();
        	PEAC_ValidateOpportunityBookToInfolease.getLatestInfoleaseIntegrationDetails(testOpportunities[0].Id);
        Test.stopTest();
    }
}