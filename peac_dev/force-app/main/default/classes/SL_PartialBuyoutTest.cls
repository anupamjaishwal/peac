@isTest
public with sharing class SL_PartialBuyoutTest {
    @isTest
    public static void createBuyout() {
        SL_SCTestData.createAccountAndContracts(2, 1);
        
        User testUser1 = SL_SCTestData.testUser;
        System.runAs(testUser1){
            Account portalAccount = SL_SCTestData.testAccounts[0];
            // portalAccount.Preferred_Dealer_Level__c = '2';// DP-1797 Misael Romero
            portalAccount.Account_Branch__c = 'Office Equip Group-OEG';
            User u = SL_SCTestData.createDPDataForUser(portalAccount);
            List<Contract__c> contracts = SL_SCTestData.testContracts;
            contracts[1].Dealer_Name__c = SL_SCTestData.dealerAccountId;
            Contract__c contract = contracts[1];
            contract.Quote_Buyout_Types__c = '1';
            SL_SCTestData.createInsurancesAndContractAssets(2, 2);
            update contract;
            List<Contract_Asset__c> testCAssets = SL_SCTestData.testCAssets;
            List<Buyout__c> buyoutsToCreate = new List<Buyout__c>{new Buyout__c(Buyout_Type__c = '35', Quote_Sequence__c = '1'),
                new Buyout__c(Buyout_Type__c = '36', Quote_Sequence__c = '2')};
            String result1, result2;
            Test.startTest();
            result1 = SL_PartialBuyout.hubExecute('getCAssetsInfo', new List<String>{contract.Id});
            result2 = SL_PartialBuyout.hubExecute('saveBuyouts', new List<String>{contract.Id, 
                JSON.serialize(buyoutsToCreate), '["' + testCAssets[2].Asset_Number__c + '"]'});
            SL_PartialBuyout.checkExistingFullBAssets(contract.Id, '999');
            Test.stopTest();
            List<Buyout__c> buyoutsAfter = [SELECT Id, Name, Buyout_Type__c FROM Buyout__c];
            System.Assert.isTrue(result1.contains('"isPartialBuyout": true'), 'Must be partial for Branch OEG');
            System.Assert.areEqual(2, buyoutsAfter.size(), 'created 2 buyouts');
            Set<String> expectedTypes = new Set<String>{'35', '36'};
            Set<String> actualTypes = new Set<String>();
            for (Buyout__c b : buyoutsAfter) actualTypes.add(b.Buyout_Type__c);
            System.assertEquals(expectedTypes, actualTypes, 'Buyout types should match');
 
            List<Buyout_Asset__c> baList = [SELECT Id FROM Buyout_Asset__c WHERE Buyout__c IN :buyoutsAfter];
            System.assert(baList.size() > 0, 'Buyout assets should have been created');
            
        }
        
    }
    
   
}