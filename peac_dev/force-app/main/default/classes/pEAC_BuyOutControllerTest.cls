@isTest
public class pEAC_BuyOutControllerTest {
    
    @testSetup
    static void setup() {
        SL_SCTestData.createAccountAndContracts(2, 1);
        // Create test data for Buyout__c objects
        List<Contract__c> contracts = SL_SCTestData.testContracts;
		Contract__c testContract = contracts[0];
        Buyout__c buyout1 = new Buyout__c(
            Contract__c = testContract.Id,
            Name = 'Buyout 1',
            Buyout_Type__c = 'Type 1',
            Date_Quoted__c = Date.today(),
            Expiration_Date__c = Date.today().addDays(30),
            Buyout_Amount__c = 1000,
            Buyout_Description__c = 'Test Buyout',
            Most_Recent__c = true,
            Partial_Buyout__c = false,
            Show_To_DP_Users__c = true
        );
        
        Buyout__c buyout2 = new Buyout__c(
            Contract__c = testContract.Id,
            Name = 'Buyout 2',
            Buyout_Type__c = 'Type 2',
            Date_Quoted__c = Date.today().addDays(-10),
            Expiration_Date__c = Date.today().addDays(20),
            Buyout_Amount__c = 2000,
            Buyout_Description__c = 'Test Buyout 2',
            Most_Recent__c = false,
            Partial_Buyout__c = false,
            Show_To_DP_Users__c = true
        );

        insert new List<Buyout__c>{buyout1, buyout2};

    }

    @isTest
    static void testGetBuyOuts() {
        // Fetch the Contract__c for test setup
        Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];

        Test.startTest();
        List<Buyout__c> result = pEAC_BuyOutController.getBuyOuts(testContract.Id);
        Test.stopTest();

        // Assert the returned buyouts are as expected
        System.assertNotEquals(null, result, 'Buyouts list should not be null');
        System.assertEquals(2, result.size(), 'Expected 2 Buyout records');
    }

    @isTest
    static void testProcessBuyouts() {
        // Fetch the Contract__c for test setup
        Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];

        // Create BuyoutWrapper test data
        pEAC_BuyOutController.BuyoutWrapper wrapper = new pEAC_BuyOutController.BuyoutWrapper();
        wrapper.QuoteType = 'Type 1';
        wrapper.QuoteTypeDesc = 'Full Residual';
        wrapper.BuyoutDate = '01/01/2024';
        wrapper.QuoteExpireDatet = '02/02/2024';
        wrapper.TotalBuyout = '5000';
        wrapper.InvoiceDescription = 'Test Invoice Description';
        wrapper.ReceivableBalance = '1000';
        wrapper.Residual = '200';
        wrapper.SalesTax = '150';
        wrapper.LateCharges = '20';
        wrapper.Fees = '50';
        wrapper.SecurityDeposit = '300';
        wrapper.EndingDeposit = '100';
        wrapper.QuotedBy = 'Test';
        wrapper.QuotedTo = 'Test';
        wrapper.QuoteUserId = 'Test';
        wrapper.OriginalTerm = 'Test';
        wrapper.NumberOfPayments = 'Test';
        wrapper.DealerNumber = 'Test';
        wrapper.Status = 'Test';
        wrapper.InvoiceDescription = 'Test';
        wrapper.DealerName = 'Test';
        wrapper.CommencementDate = '01/01/2024';
        wrapper.DailyResidual = 'Test';
        wrapper.UnearnedIDC = 'Test';
        wrapper.QuoteSeq = 'Test';
        wrapper.ITC = 'Test';
        wrapper.showIt = true;
        wrapper.Miscellaneous = 'Test';
        wrapper.PurgeDate = '01/01/2024';
        wrapper.UnearnedFinance = '2232';
        wrapper.DailyFinance = '2342';
        wrapper.CustomerReceivableBalance = '23432';

        List<pEAC_BuyOutController.BuyoutWrapper> wrapList = new List<pEAC_BuyOutController.BuyoutWrapper>{wrapper};

        Test.startTest();
        String result = pEAC_BuyOutController.processBuyouts(wrapList, testContract.Id);
        Test.stopTest();

        // Assert the result
        System.assertEquals('Success', result, 'Expected success message from processBuyouts');
    }

    @isTest
    static void testCreatePDFRecord() {
        Buyout__c testBuyout = [SELECT Id FROM Buyout__c LIMIT 1];
         Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];
        
        Test.startTest();
        String result = pEAC_BuyOutController.createPDFRecord(testBuyout.Id);
        Test.stopTest();
    }

    @isTest
    static void testCreateCustomerPDFRecord() {
        Buyout__c testBuyout = [SELECT Id FROM Buyout__c LIMIT 1];
         Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];

        Test.startTest();
        String result = pEAC_BuyOutController.createCustomerPDFRecord(testBuyout.Id, testContract.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testGetPartnerPDFDetails() {
        Buyout__c testBuyout = [SELECT Id FROM Buyout__c LIMIT 1];
        
        Test.startTest();
        String result = pEAC_BuyOutController.getPartnerPDFDetails(testBuyout.Id);
        Test.stopTest();
    }

    @isTest
    static void testGetCustomerPDFDetails() {
        Buyout__c testBuyout = [SELECT Id FROM Buyout__c LIMIT 1];
        Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];
        
        Test.startTest();
        String result = pEAC_BuyOutController.getCustomerPDFDetails(testBuyout.Id, testContract.Id);
        Test.stopTest();
    }

}