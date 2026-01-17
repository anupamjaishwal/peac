@isTest
public with sharing class PEAC_BuyoutComparisonControllerTest {
    @isTest
    static void printPdf() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        Test.startTest();
        Contract__c contract = [SELECT Id FROM Contract__c];
        Buyout__c buyout1 = new Buyout__c(
            Contract__c = contract.Id,
            Name = 'Buyout 1',
            Buyout_Type__c = 'Type 1',
            Date_Quoted__c = Date.today(),
            Expiration_Date__c = Date.today().addDays(30),
            Buyout_Amount__c = 1000,
            Buyout_Description__c = 'Test Buyout',
            Most_Recent__c = true,
            Partial_Buyout__c = false
        );
        
        Buyout__c buyout2 = new Buyout__c(
            Contract__c = contract.Id,
            Name = 'Buyout 2',
            Buyout_Type__c = 'Type 2',
            Date_Quoted__c = Date.today().addDays(-10),
            Expiration_Date__c = Date.today().addDays(20),
            Buyout_Amount__c = 2000,
            Buyout_Description__c = 'Test Buyout 2',
            Most_Recent__c = false,
            Partial_Buyout__c = false
        );

        insert new List<Buyout__c>{buyout1, buyout2};
        ApexPages.currentPage().getParameters().put('recId', contract.Id);
        ApexPages.currentPage().getParameters().put('action', 'letter');
        
        PEAC_BuyoutComparisonController ctrl = new PEAC_BuyoutComparisonController();
        ctrl.getLogoResourceName();
        Test.stopTest();
        
    }
}