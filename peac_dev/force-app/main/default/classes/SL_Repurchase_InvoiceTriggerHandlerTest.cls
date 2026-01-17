@IsTest
public with sharing class SL_Repurchase_InvoiceTriggerHandlerTest {
    @testSetup static void setup() {
        // Create necessary test data using SL_SCTestData methods
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 2); // Creating 1 insurance with 2 contract assets  
        Contract__c Contract = [SELECT Id FROM Contract__c LIMIT 1];
        List<Contract_Asset__c> assets = [SELECT Id FROM Contract_Asset__c WHERE Contract__c=:Contract.Id];
        String invoiceAssetsJSON = '[{\"Id\":\"'+assets[0].Id+'\",\"UnitPrice\":\"10\"},{\"Id\":\"'+assets[1].Id+'\",\"UnitPrice\":\"15\"}]';    
        String result = '';
        String resultGenerated = '';
        result = SL_DealerRepurchaseController.generateInvoice(Contract.Id, invoiceAssetsJSON);
        resultGenerated = SL_DealerRepurchaseController.generateInvoiceDocument('', '', true, result ,invoiceAssetsJSON ); 

        Repurchase_Invoice__c invoice = [SELECT Id, Status__c FROM Repurchase_Invoice__c WHERE Contract__c=:Contract.Id LIMIT 1];
        invoice.Status__c = 'Open';
        update invoice;
    }

    @IsTest
    static void openToPaidTest(){
        Contract__c Contract = [SELECT Id FROM Contract__c LIMIT 1];
        Repurchase_Invoice__c invoice = [SELECT Id, Status__c FROM Repurchase_Invoice__c WHERE Contract__c=:Contract.Id LIMIT 1];

      
        Test.startTest();
        invoice.Status__c = 'Paid';
        update invoice;
        Test.stopTest();

        Integer paidTask = 0;
        List<Task> tasks = [SELECT Id , Notes__c FROM Task WHERE Contract__c = :Contract.Id ];
        for(Task t : tasks){
            if(t.Notes__c.contains('has been paid.')){
                paidTask += 1;
            }
        }
        Assert.isTrue(paidTask > 0);
    }
    
    @IsTest
    static void openToDelinquentTest(){
        Contract__c Contract = [SELECT Id FROM Contract__c LIMIT 1];
        Repurchase_Invoice__c invoice = [SELECT Id, Status__c FROM Repurchase_Invoice__c WHERE Contract__c=:Contract.Id LIMIT 1];

      
        Test.startTest();
        invoice.Status__c = 'Delinquent';
        update invoice;
        Test.stopTest();

        Integer delinquentTask = 0;
        List<Task> tasks = [SELECT Id , Notes__c FROM Task WHERE Contract__c = :Contract.Id ];
        for(Task t : tasks){
            if(t.Notes__c.contains('is now delinquent.')){
                delinquentTask += 1;
            }
        }
        Assert.isTrue(delinquentTask > 0);
    }
    
    @IsTest
    static void openToCancelled(){
        Contract__c Contract = [SELECT Id FROM Contract__c LIMIT 1];
        Repurchase_Invoice__c invoice = [SELECT Id, Status__c FROM Repurchase_Invoice__c WHERE Contract__c=:Contract.Id LIMIT 1];

      
        Test.startTest();
        invoice.Status__c = 'Cancelled';
        update invoice;
        Test.stopTest();

        Integer CancelledtTask = 0;
        List<Task> tasks = [SELECT Id , Notes__c FROM Task WHERE Contract__c = :Contract.Id ];
        for(Task t : tasks){
            if(t.Notes__c.contains('is now canceled.')){
                CancelledtTask += 1;
            }
        }
        Assert.isTrue(CancelledtTask > 0);
    }
}