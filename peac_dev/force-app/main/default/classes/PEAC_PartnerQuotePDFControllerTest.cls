@isTest
public class PEAC_PartnerQuotePDFControllerTest {
    @testSetup
    static void setup() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 1);
        Contract__c contract = [SELECT Id FROM Contract__c];
        // Create a test Buyout__c record linked to the Contract__c
        Buyout__c buyout = new Buyout__c(
            Contract__c = contract.Id,
            Buyout_Description__c = 'End of Term Buyout',
            Quote_Sequence__c = '1',
            Buyout_Amount__c = 5000,
            Most_Recent__c = true,
            Receivable_Balance__c = 3000,
            Residual__c = 1500,
            SalesTax__c = 100,
            LateCharges__c = 50,
            Early_Termination_Fee__c = 200,
            Security_Deposit__c = 500,
            Ending_Deposit__c = 200,
            Service_pass_through__c = 50,
            Property_tax__c = 75,
            Insurance__c = 60,
            Other_Lease_Charges__c = 40,
            Total_Buyout__c = 7500,
            Partial_Buyout__c = true,
            Date_Quoted__c = Date.today(),
            Expiration_Date__c = Date.today().addDays(30)
        );
        insert buyout;
         Buyout__c buyout1 = new Buyout__c(
            Contract__c = contract.Id,
            Buyout_Description__c = 'End of Term Buyout',
            Quote_Sequence__c = '1',
            Buyout_Amount__c = 5000,
            Most_Recent__c = true,
            Receivable_Balance__c = 3000,
            Residual__c = 1500,
            SalesTax__c = 100,
            LateCharges__c = 50,
            Early_Termination_Fee__c = 200,
            Security_Deposit__c = 500,
            Ending_Deposit__c = 200,
            Service_pass_through__c = 50,
            Property_tax__c = 75,
            Insurance__c = 60,
            Other_Lease_Charges__c = 40,
            Total_Buyout__c = 7500,
            Partial_Buyout__c = false,
            Date_Quoted__c = Date.today(),
            Expiration_Date__c = Date.today().addDays(30)
        );
        insert buyout1;
        List<Contract_Asset__c> contractAssets = new List<Contract_Asset__c>();
        
        for (Contract_Asset__c asset : [select Id,Serial_Number__c from Contract_Asset__c where Contract__c = :contract.Id]) {
            asset.Serial_Number__c = '12345';
            contractAssets.add(asset);
        }
        update contractAssets;
    }
    
    @isTest
    static void testController() {
        // Retrieve the test Buyout__c record for the buyoutId
        Buyout__c testBuyout = [SELECT Id,Contract__c FROM Buyout__c where Partial_Buyout__c = true LIMIT 1];
        
        // Set up the page and add the parameter
        Test.startTest();
        List<Buyout_Asset__c> buyoutAssets = new List<Buyout_Asset__c>();
        for (Contract_Asset__c asset : [select Id from Contract_Asset__c where Contract__c = :testBuyout.Contract__c]) {
            buyoutAssets.add(new Buyout_Asset__c(
                Buyout__c = testBuyout.Id,
                Contract_Asset__c = asset.Id
            ));
        }
        
        insert buyoutAssets;
        PageReference pageRef = Page.PEAC_PartnerQuotePDF; // Replace with actual VF page name if different
        pageRef.getParameters().put('buyoutId', testBuyout.Id);
        Test.setCurrentPage(pageRef);
        
        // Instantiate the controller
        PEAC_PartnerQuotePDFController controller = new PEAC_PartnerQuotePDFController();
        
        
        Test.stopTest();
    }
     @isTest
    static void testControllerPartial() {
        // Retrieve the test Buyout__c record for the buyoutId
        Buyout__c testBuyout = [SELECT Id FROM Buyout__c where Partial_Buyout__c = false LIMIT 1];
        
        // Set up the page and add the parameter
        Test.startTest();
        PageReference pageRef = Page.PEAC_PartnerQuotePDF; // Replace with actual VF page name if different
        pageRef.getParameters().put('buyoutId', testBuyout.Id);
        Test.setCurrentPage(pageRef);
        
        // Instantiate the controller
        PEAC_PartnerQuotePDFController controller = new PEAC_PartnerQuotePDFController();
        
        
        Test.stopTest();
    }
}