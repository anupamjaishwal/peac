@isTest 
public with sharing class SL_TriggerUtilTest {
    @isTest
    public static void updatedFields() {
        Test.startTest();
        SL_SCTestData.createAccountAndContracts(1, 1);
        Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>{SL_SCTestData.testAccounts[0].Id => new List<String>{'Name'}};
        List<String> fieldsToCheck =  new List<String>{'Name'};
        Account accUpdate = new Account(Id = SL_SCTestData.testAccounts[0].Id, Name = 'New Name');

        SL_TriggerUtil.findChangedFields(SL_SCTestData.testAccounts[0].Id,accUpdate, SL_SCTestData.testAccounts[0], fieldsChangedById, fieldsToCheck);
        SL_TriggerUtil.checkForMissingInfo(SL_SCTestData.testAccounts);
        Test.stopTest();
    }
}