@isTest
public with sharing class SL_SelectChildDealerTest {
    @isTest
    public static void getChildAccounts() {
        SL_SCTestData.createAccountAndContracts(2, 1);
        User dpUserParent = SL_SCTestData.createDPUser(SL_SCTestData.testAccounts[0].Id);
        Test.startTest();
        SL_SelectChildDealer.hubExecute('getChildAccounts', new List<String>{String.valueOf(dpUserParent.ContactId)});
        Test.stopTest();
    }
}