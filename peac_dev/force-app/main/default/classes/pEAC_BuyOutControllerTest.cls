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
        String serialized = pEAC_BuyOutController.getBuyOuts(testContract.Id);
        List<Buyout__c> result = (List<Buyout__c>)JSON.deserialize(serialized, List<Buyout__c>.class);
        Test.stopTest();

        // Assert the returned buyouts are as expected
        System.assertNotEquals(null, result, 'Buyouts list should not be null');
        System.assertEquals(2, result.size(), 'Expected 2 Buyout records');
    }

    @isTest
    static void mapBuyoutQuoteFields() {
        // Fetch the Contract__c for test setup
        Contract__c testContract = [SELECT Id FROM Contract__c LIMIT 1];

    //     // Create BuyoutWrapper test data
    //     pEAC_BuyOutController.BuyoutWrapper wrapper = new pEAC_BuyOutController.BuyoutWrapper();
    //     wrapper.QuoteType = 'Type 1';
    //     wrapper.QuoteTypeDesc = 'Full Residual';
    //     wrapper.BuyoutDate = '01/01/2024';
    //     wrapper.QuoteExpireDatet = '02/02/2024';
    //     wrapper.TotalBuyout = '5000';
    //     wrapper.InvoiceDescription = 'and\r\nother line \\"quote\ttab';
    //     wrapper.ReceivableBalance = '1000';
    //     wrapper.Residual = '200';
    //     wrapper.SalesTax = '150';
    //     wrapper.LateCharges = '20';
    //     wrapper.Fees = '50';
    //     wrapper.SecurityDeposit = '300';
    //     wrapper.EndingDeposit = '100';
    //     wrapper.QuotedBy = 'Test';
    //     wrapper.QuotedTo = 'Test';
    //     wrapper.QuoteUserId = 'Test';
    //     wrapper.OriginalTerm = 'Test';
    //     wrapper.NumberOfPayments = 'Test';
    //     wrapper.DealerNumber = 'Test';
    //     wrapper.Status = 'Test';
    //     wrapper.InvoiceDescription = 'Test';
    //     wrapper.DealerName = 'Test';
    //     wrapper.CommencementDate = '01/01/2024';
    //     wrapper.DailyResidual = 'Test';
    //     wrapper.UnearnedIDC = 'Test';
    //     wrapper.QuoteSeq = 'Test';
    //     wrapper.ITC = 'Test';
    //     wrapper.showIt = true;
    //     wrapper.Miscellaneous = 'Test';
    //     wrapper.PurgeDate = '01/01/2024';
    //     wrapper.UnearnedFinance = '2232';
    //     wrapper.DailyFinance = '2342';
    //     wrapper.CustomerReceivableBalance = '23432';

    //     List<pEAC_BuyOutController.BuyoutWrapper> wrapList = new List<pEAC_BuyOutController.BuyoutWrapper>{wrapper};
    //     String jsonObj = JSON.serialize(wrapList);
        Test.startTest();
    //     String result = pEAC_BuyOutController.processBuyouts(jsonObj, testContract.Id);
    //     String quotesWithError = '';
    //     String extraresult = pEAC_BuyOutController.processBuyouts(quotesWithError, testContract.Id);

    //     // Assert the result
    //     System.assertEquals('Success', result, 'Expected success message from processBuyouts');
    //     System.assertEquals('Success', extraresult, 'Expected success message from processBuyouts');
        String quotesWithError = '[{"MiscSummary": [  { "MiscDescription": "0625", "MiscTotal": "509.10", "MiscIncludeInRentYN": "N"  },  { "MiscDescription": "0626", "MiscTotal": "458.20", "MiscIncludeInRentYN": "N"  }],"DailyFinance": "","Miscellaneous": "967.30","QuoteUserId": "marlin","OriginalTerm": "60","QuotedBy": "ashley@sentrysur","Residual": "1.00","LateCharges": "16.61","UnearnedIDC": "","SalesTax": "517.51","CustomerReceivableBalance": "7392.00","CommencementDate": "04/20/2022","QuoteSeq": "13","BuyoutDate": "01/12/2026","QuotedTo": "","SecurityDeposit": "","DealerNumber": "77059.2040","QuoteExpireDatet": "02/11/2026","PurgeDate": "05/12/2026","NumberOfPayments": "44.00","DealerName": "Sentry Surveillance Inc","Status": "ACTIVE","InvoiceDescription": "8 IP Cameras, 1\\r\\nAcer Monitor, 1\\r\\nRealeyes Recorder","UnearnedFinance": "","ReceivableBalance": "7392.00","Fees": "0.00","EndingDeposit": "","TotalBuyout": "8894.42","DailyResidual": "","ITC": "0.00","QuoteType": "1","PartialCode": "Complete Contract Buyout","QuoteTypeDesc": "Full Residual"  },  {"MiscSummary": [  { "MiscDescription": "0625", "MiscTotal": "509.10", "MiscIncludeInRentYN": "N"  },  { "MiscDescription": "0626", "MiscTotal": "458.20", "MiscIncludeInRentYN": "N"  }],"DailyFinance": "","Miscellaneous": "967.30","QuoteUserId": "marlin","OriginalTerm": "60","QuotedBy": "ashley@sentrysur","Residual": "1.00","LateCharges": "16.61","UnearnedIDC": "","SalesTax": "0.00","CustomerReceivableBalance": "7392.00","CommencementDate": "04/20/2022","QuoteSeq": "14","BuyoutDate": "01/12/2026","QuotedTo": "","SecurityDeposit": "0.00","DealerNumber": "77059.2040","QuoteExpireDatet": "02/11/2026","PurgeDate": "05/12/2026","NumberOfPayments": "44.00","DealerName": "Sentry Surveillance Inc","Status": "ACTIVE","InvoiceDescription": "8 IP Cameras, 1\\r\\nAcer Monitor, 1\\r\\nRealeyes Recorder","UnearnedFinance": "","ReceivableBalance": "7392.00","Fees": "0.00","EndingDeposit": "","TotalBuyout": "8376.91","DailyResidual": "","ITC": "0.00","QuoteType": "6","PartialCode": "Complete Contract Buyout","QuoteTypeDesc": "Trade-Up no Equip Return"  }]';
        List<pEAC_BuyOutController.BuyoutWrapper> wrapList = (List<pEAC_BuyOutController.BuyoutWrapper>)JSON.deserialize(quotesWithError, List<pEAC_BuyOutController.BuyoutWrapper>.class);
        for(pEAC_BuyOutController.BuyoutWrapper obj : wrapList) {
            Buyout__c newBuyout = pEAC_BuyOutController.mapBuyoutQuoteFields(testContract.Id, obj.QuoteSeq, obj.QuoteType, obj);
            System.Assert.areEqual(967.30, newBuyout.Property_Tax__c, 'property tax comes from GL codes 0625 and 0626');
        }
        Test.stopTest();
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