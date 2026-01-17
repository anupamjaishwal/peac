@isTest
public class PEAC_CustomerBuyoutLetterControllerTest {
    
    private static Contract__c createTestContract() {
        
        Account acct = new Account(Name = 'Test Customer');
        insert acct;
        
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = [SELECT Id FROM Contract__c];
        return contract;
    }
    
    private static Buyout__c createTestBuyout(Id contractId, Boolean isPartial, String nameVal) {
        Buyout__c buyout = new Buyout__c(
            Contract__c = contractId,
            Name = nameVal,
            Buyout_Amount__c = 1000.0,
            Receivable_Balance__c = 300.0,
            Residual__c = 100.0,
            SalesTax__c = 50.0,
            LateCharges__c = 20.0,
            Early_Termination_Fee__c = 75.0,
            Security_Deposit__c = 150.0,
            Ending_Deposit__c = 0.0,
            Service_pass_through__c = 10.0,
            Property_tax__c = 25.0,
            Insurance__c = 40.0,
            Other_Lease_Charges__c = 30.0,
            Total_Buyout__c = 800.0,
            Partial_Buyout__c = isPartial,
            Date_Quoted__c = Date.today(),
            Expiration_Date__c = Date.today().addDays(30),
            Most_Recent__c = true,
            Most_Recent_DP__c = true
        );
        insert buyout;
        return buyout;
    }
    
    @isTest
    static void testControllerWithBuyoutDPSource() {
        Contract__c contract = createTestContract();
        Buyout__c buyout = createTestBuyout(contract.Id, false, 'Customer Buyout to Keep');
        
        Test.startTest();
        PageReference pageRef = Page.PEAC_BPCustomerBuyoutLetter; // Replace with actual VF page name
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('recId', contract.Id);
        ApexPages.currentPage().getParameters().put('sourceName', 'Customer_Letter_DP');
        ApexPages.currentPage().getParameters().put('buyoutId', buyout.Id);
        
        PEAC_CustomerBuyoutLetterController controller = new PEAC_CustomerBuyoutLetterController();
        Test.stopTest();
        
        System.assert(controller.isFound, 'Buyout should be found for DP source');
        System.assert(controller.fields.size() > 0, 'Fields should be populated');
    }
    
    @isTest
    static void testControllerWithMostRecentDPBuyoutFallback() {
        Contract__c contract = createTestContract();
        Buyout__c buyout = createTestBuyout(contract.Id, true, 'Customer Buyout to Return');
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('recId', contract.Id);
        PEAC_CustomerBuyoutLetterController controller = new PEAC_CustomerBuyoutLetterController();
        Test.stopTest();
        
        System.assert(controller.isFound, 'Buyout should be selected from fallback logic');
    }
    
    @isTest
    static void testControllerHandlesNoBuyoutFound() {
        Contract__c contract = createTestContract();
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('recId', contract.Id);
        ApexPages.currentPage().getParameters().put('sourceName', 'Customer_Letter_SC');
        ApexPages.currentPage().getParameters().put('quoteSeq', '999'); // No matching quote
        
        PEAC_CustomerBuyoutLetterController controller = new PEAC_CustomerBuyoutLetterController();
        Test.stopTest();
        
        System.assert(!controller.isFound, 'Should not find any buyout with invalid quote');
    }
    
    @isTest
    static void testActionAndFieldFiltering() {
        Contract__c contract = createTestContract();
        Buyout__c buyout = createTestBuyout(contract.Id, false, 'Customer Buyout to Return');
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('recId', contract.Id);
        ApexPages.currentPage().getParameters().put('action', 'generatePDF');
        PEAC_CustomerBuyoutLetterController controller = new PEAC_CustomerBuyoutLetterController();
        Test.stopTest();
        
    }
    
}