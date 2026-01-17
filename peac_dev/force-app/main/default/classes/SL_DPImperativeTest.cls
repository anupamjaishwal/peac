@isTest
public with sharing class SL_DPImperativeTest {
    @isTest
    public static void general() {
        SL_SCTestData.createAccountAndContracts(2,2);
        Account portalAccount = SL_SCTestData.testAccounts[0];
        User u = null;
        System.runAs(SL_SCTestData.testUser){
            u = SL_SCTestData.createDPDataForUser(portalAccount);
            List<Contract__c> contracts = SL_SCTestData.testContracts;
            contracts[2].Dealer_Name__c = SL_SCTestData.dealerAccountId;
            contracts[3].Dealer_Name__c = SL_SCTestData.dealerAccountId;
            update contracts;
        }
        List<Contract__c> activeContracts = [SELECT Total_Amount_Due__c, Is_Active__c, Status__c, Dealer_Name__c, Customer__c
        FROM Contract__c  
        WHERE Dealer_Name__c = :portalAccount.Id AND Is_Active__c = true AND Customer__c = :SL_SCTestData.testAccounts[1].Id];
        String result;
        Test.startTest();
        System.runAs(u){
            result = SL_DPImperative.hubExecute('getCustomerSummary', new List<String>{String.valueOf(SL_SCTestData.testAccounts[1].Id)});
            portalAccount.Pre_Delivery_20k_Trial__c = false;
            List<Account> accLst = new List<Account>{portalAccount};
            SL_DPImperative.updateDealerAccounts(accLst);
        }
        Test.stopTest();
        System.debug('result: ' + result);
        List<Account> accountsAfter = [SELECT Id, Pre_Delivery_20k_Trial__c FROM Account WHERE Id = :portalAccount.Id];
        System.Assert.areEqual(false, accountsAfter[0].Pre_Delivery_20k_Trial__c);
    }
}