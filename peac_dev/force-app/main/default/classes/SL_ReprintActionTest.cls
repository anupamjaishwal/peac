@isTest
public with sharing class SL_ReprintActionTest {
    @isTest
    static void updateReprintFields_NotInvoicing() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Contract__c> allContract = SL_SCTestData.testContracts;
        Contract__c testContract = allContract[0];
        allContract[0].Invoice_Code__c = 'S';
        allContract[0].Total_Amount_Due__c = 1;
        update allContract;
        test.startTest();
        String result = SL_ReprintAction.updateReprintFields(testContract.Id, false);
        test.stopTest();
        System.assertEquals('Not Eligible for Reprint - Not Invoicing', result);
    }
    @isTest
    static void updateReprintFields_ZeroDue() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Contract__c> allContract = SL_SCTestData.testContracts;
        Contract__c testContract = allContract[0];
        /*allContract[0].Invoice_Code__c = 'S';
        update allContract;*/
        test.startTest();
        String result = SL_ReprintAction.updateReprintFields(testContract.Id, false);
        test.stopTest();
        System.assertEquals('Not Eligible for Reprint - Zero Due', result);
    }
    @isTest
    static void updateReprintFields_ILACHorCC() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Contract__c> allContract = SL_SCTestData.testContracts;
        Contract__c testContract = allContract[0];
        allContract[0].Total_Amount_Due__c = 1;
        allContract[0].Lead_Invoice_Days__c = 8;
        update allContract;
        test.startTest();
        String result = SL_ReprintAction.updateReprintFields(testContract.Id, false);
        test.stopTest();
        System.assertEquals('Not Eligible for Reprint - IL ACH or CC', result);
    }
    @isTest
    static void updateReprintFields_ConfirmDQ() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Contract__c> allContract = SL_SCTestData.testContracts;
        Contract__c testContract = allContract[0];
        allContract[0].Total_Amount_Due__c = 1;
        allContract[0].Delinquency_Status_Code__c = '01';
        update allContract;
        test.startTest();
        String result = SL_ReprintAction.updateReprintFields(testContract.Id, false);
        test.stopTest();
        System.assertEquals('Confirm reprint on a delinquent contract', result);
    }
    @isTest
    static void updateReprintFields_ConfirmedDQ() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        List<Contract__c> allContract = SL_SCTestData.testContracts;
        Contract__c testContract = allContract[0];
        allContract[0].Total_Amount_Due__c = 1;
        allContract[0].Delinquency_Status_Code__c = '01';
        update allContract;
        SL_SCTestData.testNow = Datetime.now();
        test.startTest();
        String result = SL_ReprintAction.updateReprintFields(testContract.Id, true);
        test.stopTest();
        System.assertEquals('success', result);
    }
    @isTest
    static void updateReprintFields_success() {
        SL_SCTestData.createAccountAndContracts(1, 3);
        List<Contract__c> allContract = SL_SCTestData.testContracts;
        Contract__c testContract = allContract[0];
        allContract[0].Invoice_Code__c = 'A';
        allContract[0].Total_Amount_Due__c = 1;
        allContract[2].Invoice_Code__c = 'A';
        update allContract;
        Date result2, result3, result4, result5, result6, result7, result8;
        SL_SCTestData.testNow = Datetime.newInstance(2023, 1, 24, 11, 59, 59);
        Test.startTest();
        String result = SL_ReprintAction.updateReprintFields(testContract.Id, false);
        allContract[2].Reprint_Invoice__c = false;
        update allContract[2];
        result2 = SL_ReprintAction.calculateNextInvoiceReprintDate(Date.newInstance(2023, 1, 13));
        result3 = SL_ReprintAction.calculateNextInvoiceReprintDate(Date.newInstance(2023, 1, 18));
        result4 = SL_ReprintAction.calculateNextInvoiceReprintDate(Date.newInstance(2023, 1, 30));
        result5 = SL_ReprintAction.calculateNextInvoiceReprintDate(Date.newInstance(2023, 2, 5));
        result6 = SL_ReprintAction.calculateNextInvoiceReprintDate(Date.newInstance(2023, 2, 7));
        result7 = SL_ReprintAction.calculateNextInvoiceReprintDate(Date.newInstance(2023, 2, 16));
        result8 = SL_ReprintAction.calculateNextInvoiceReprintDate(Date.newInstance(2023, 2, 3));
        Test.stopTest();
        List<Contract__c> contractsAfter = [SELECT Id, Reprint_Invoice__c, Invoice_Reprint_Date__c FROM Contract__c];
        System.assertEquals('success', result);
        System.assert(contractsAfter[0].Invoice_Reprint_Date__c != null);
        System.assertEquals(null, contractsAfter[2].Invoice_Reprint_Date__c);
        System.assertEquals(Date.newInstance(2023, 1, 30), contractsAfter[0].Invoice_Reprint_Date__c);
        System.assertEquals(Date.newInstance(2023, 1, 16), result2);
        System.assertEquals(Date.newInstance(2023, 1, 19), result3);
        System.assertEquals(Date.newInstance(2023, 2, 3), result4);
        System.assertEquals(Date.newInstance(2023, 2, 7), result5);
        System.assertEquals(Date.newInstance(2023, 2, 13), result6);
        System.assertEquals(Date.newInstance(2023, 2, 16), result7);
        System.assertEquals(Date.newInstance(2023, 2, 3), result8);
    }
}