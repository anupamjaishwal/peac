@IsTest
public with sharing class SL_DealerRepurchaseControllerTest {


    @testSetup static void setup() {
        // Create necessary test data using SL_SCTestData methods
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 2); // Creating 1 insurance with 2 contract assets      
    }


    @IsTest
    static void getContractAssetsTest(){
        Contract__c Contract = [SELECT Id FROM Contract__c LIMIT 1];
        List<Contract_Asset__c> assets = new List<Contract_Asset__c>();
        Test.startTest();
        assets = SL_DealerRepurchaseController.getContractAssets(Contract.Id);            
        Test.stopTest();
        System.debug('RESULT '+assets);
        Assert.isTrue(assets.size()>0);        

        
    }


    @IsTest
    static void generateInvoiceTest(){
        String result = '';
        String resultGenerated = '';
        Contract__c Contract = [SELECT Id FROM Contract__c LIMIT 1];
        List<Contract_Asset__c> assets = [SELECT Id FROM Contract_Asset__c WHERE Contract__c=:Contract.Id];
        String invoiceAssetsJSON = '[{\"Id\":\"'+assets[0].Id+'\",\"UnitPrice\":\"10\"},{\"Id\":\"'+assets[1].Id+'\",\"UnitPrice\":\"15\"}]';
        Test.startTest();
        result = SL_DealerRepurchaseController.generateInvoice(Contract.Id, invoiceAssetsJSON);
        resultGenerated = SL_DealerRepurchaseController.generateInvoiceDocument('', '', true, result ,invoiceAssetsJSON ); 

        Test.stopTest();

        List<Invoice_Asset__c> invoiceAssetsList  = new List<Invoice_Asset__c>();
        List<Repurchase_Invoice__c> invoice = [SELECT Id FROM Repurchase_Invoice__c WHERE Contract__c=:Contract.Id LIMIT 1];
        if(invoice.size()>0) invoiceAssetsList = [SELECT Id FROM Invoice_Asset__c WHERE Invoice__c = :invoice[0].Id ];

        Assert.isTrue(invoice.size()>0);
        Assert.isTrue(invoiceAssetsList.size()>0);
        Assert.isTrue(result != ''); 

    }



}