@isTest
public class SL_Invoice_AssetTriggerHandlerTest {

    @isTest
    public static void testInsert(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        SL_SCTestData.createInsurancesAndContractAssets(1, 2);
        Repurchase_Invoice__c ri = new Repurchase_Invoice__c();
        ri.Contract__c=SL_SCTestData.testContracts[0].ID;
        ri.Invoice_Date__c= Date.today();
        ri.Memo__c='Dealer Invoicing';
        ri.Term__c='Net 15';
        ri.Date_Due__c= Date.today().addDays(15);
        ri.Status__c = 'Open';        
        insert ri;
        Invoice_Asset__c ia = new Invoice_Asset__c();
        ia.Invoice__c = ri.Id;
        ia.Asset__c = SL_SCTestData.testCAssets[0].id;
        ia.Unit_Price__c = 12;
        Invoice_Asset__c ia2 = new Invoice_Asset__c();
        ia2.Invoice__c = ri.Id;
        ia2.Asset__c = SL_SCTestData.testCAssets[1].id;
        ia2.Unit_Price__c = 120;
        List<Invoice_Asset__c> ias = new List<Invoice_Asset__c>();
        ias.add(ia);
        ias.add(ia2);
        Test.startTest();
        insert ias;
        Test.stopTest();
        List<Invoice_Asset__c> iasAfter = [SELECT Id, Asset__r.Status2__c, Asset__r.Status_Date__c,  Asset__r.Dealer_Repurchase_Date__c,
             Asset__r.Gross_Sale_Price__c, Unit_Price__c
            FROM Invoice_Asset__c];
        System.Assert.areEqual('DLR Repurchase', iasAfter[0].Asset__r.Status2__c, 'When invoice Asset is created Status2__c is stamped the value DLR Repurchase on the related Contract Asset');
        System.Assert.areEqual(Date.today(), iasAfter[0].Asset__r.Status_Date__c, 'When invoice Asset is created the current date is stamped in the field Status_Date__c on the related Contract Asset');
        System.Assert.areEqual(Date.today(), iasAfter[0].Asset__r.Dealer_Repurchase_Date__c, 'When invoice Asset is created the current date is stamped in the field Dealer_Repurchase_Date__c on the related Contract Asset');
        System.Assert.areEqual(iasAfter[0].Unit_Price__c, iasAfter[0].Asset__r.Gross_Sale_Price__c, 'The unit price in invoice Asset is stamped to the Gross Sale Price of the related Contract Asset');
        System.Assert.areEqual(iasAfter[1].Unit_Price__c, iasAfter[1].Asset__r.Gross_Sale_Price__c, 'The unit price in invoice Asset is stamped to the Gross Sale Price of the related Contract Asset');
    }
}