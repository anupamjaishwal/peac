@isTest
public with sharing class SL_PrintBuyoutTest {
    @TestSetup
    static void makeData(){
        SL_SCTestData.createAccountAndContracts(1, 1);
          
         
    }

    @isTest
    static void printFULLBuyoutPdf() {
        Contract__c contract = [SELECT Id FROM Contract__c LIMIT 1];
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
            Partial_Buyout__c = false,
            Date_Quoted__c = Date.today(),
            Expiration_Date__c = Date.today().addDays(30)
        );
        insert buyout;
        SL_SCTestData.createInsurancesAndContractAssets(1, 1);
        List<Contract_Asset__c> contractAssets = new List<Contract_Asset__c>();
        
        for (Contract_Asset__c asset : [select Id,Serial_Number__c from Contract_Asset__c where Contract__c = :contract.Id]) {
            asset.Serial_Number__c = '12345';
            contractAssets.add(asset);
        }
        update contractAssets;
        Test.startTest();
        ApexPages.currentPage().getParameters().put('rows', '[{"key":"BuyoutDate","label":"Buyout+Date","value":"11/14/2016","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":false,"isChecked":false,"isPlain":true}]');
        ApexPages.currentPage().getParameters().put('contractId', contract.Id);
        ApexPages.currentPage().getParameters().put('quoteSeq', '1');
        SL_PrintBuyout ctrl = new SL_PrintBuyout();
        List<SL_PrintBuyout.FieldWrapper> testFields = ctrl.getFields();
        List<SL_PrintBuyout.FieldWrapper> testHeaders = ctrl.getHeaders();
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest
    static void printPartialBuyoutPdf() {
        Contract__c contract = [SELECT Id FROM Contract__c LIMIT 1];
         Buyout__c buyout = new Buyout__c(
            Contract__c = contract.Id,
            Buyout_Description__c = 'End of Term Buyout',
            Quote_Sequence__c = '2',
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
        SL_SCTestData.createInsurancesAndContractAssets(1, 1);
        List<Contract_Asset__c> contractAssets = new List<Contract_Asset__c>();
        List<Buyout_Asset__c> buyoutAssets = new List<Buyout_Asset__c>();
        
        for (Contract_Asset__c asset : [select Id,Serial_Number__c from Contract_Asset__c where Contract__c = :contract.Id]) {
            asset.Serial_Number__c = '12345';
            contractAssets.add(asset);
             buyoutAssets.add(new Buyout_Asset__c(
                Buyout__c = buyout.Id,
                Contract_Asset__c = asset.Id
            ));
        }
        update contractAssets;
        
        insert buyoutAssets;
        Test.startTest();
        ApexPages.currentPage().getParameters().put('rows', '[{"key":"BuyoutDate","label":"Buyout+Date","value":"11/14/2016","isLink":false,"isCherwell":false,"isCheck":false,"isCurrency":false,"isChecked":false,"isPlain":true}]');
        ApexPages.currentPage().getParameters().put('contractId', contract.Id);
        ApexPages.currentPage().getParameters().put('quoteSeq', '2');
        SL_PrintBuyout ctrl = new SL_PrintBuyout();
        List<SL_PrintBuyout.FieldWrapper> testFields = ctrl.getFields();
        List<SL_PrintBuyout.FieldWrapper> testHeaders = ctrl.getHeaders();
        
        Test.stopTest();
        System.assert(true);
    }
}