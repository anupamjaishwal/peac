@isTest
public with sharing class SL_SelectChildDealerTest {
    @TestSetup
    static void makeData(){
        SL_SCTestData.createExternalHierarchy();
    }
    @isTest
    public static void getChildAccounts() {
        Set<Id> dpAccountIds = new Set<Id>();
        for(ExternalAccountHierarchy hierarchy : [SELECT Id, ParentId, AccountId, Account.Name, IsActive 
            FROM ExternalAccountHierarchy ]){
            dpAccountIds.add(hierarchy.AccountId);
        }
        List<Contact> dpContacts = [SELECT Id FROM Contact WHERE AccountId IN :dpAccountIds ORDER BY Id DESC LIMIT 2];
        String result1, result2;
        Test.startTest();
        result1 = SL_SelectChildDealer.hubExecute('getChildAccounts', new List<String>{String.valueOf(dpContacts[0].Id)});
        result2 = SL_SelectChildDealer.hubExecute('getChildAccounts', new List<String>{String.valueOf(dpContacts[1].Id)});
        Test.stopTest();
        System.Assert.isTrue(result1.contains('"canAdvocate": false'), 'this is a child user');
        System.Assert.isTrue(result2.contains('"canAdvocate": true'), 'this is a parent user');
    }
}