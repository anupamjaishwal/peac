@isTest
public class TC_RequiredPrimaryContactTest {
    @isTest
    static void scenario1() {
        Test.startTest();
        SL_SCTestData.createAccountAndContracts(2, 1);
        Account theAccount = SL_SCTestData.testAccounts[0];
        SL_SCTestData.testContacts[0].AccountId = SL_SCTestData.testAccounts[1].Id;
        update SL_SCTestData.testContacts[0];
        theAccount.Review_For__c = 'Approval';
        Id dealerAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();
        theAccount.RecordTypeId = dealerAccountId;
        Database.SaveResult accountResult = Database.update(theAccount, false);
        TestDataFactory.prepareAccounts(1, dealerAccountId, '');
        TestDataFactory.testAccounts[0].Review_For__c = 'Approval';
        Database.SaveResult insertResult = Database.insert(TestDataFactory.testAccounts[0], false);
        Test.stopTest();
        List<Account> accountsAfter = [SELECT Id, Account_Branch__c FROM Account];
        System.assert(accountResult.getErrors()[0].getMessage().contains('“Review For = Approval” requires a Primary Contact Role on the Account'));
        System.assert(insertResult.getErrors()[0].getMessage().contains('“Review For = Approval” requires a Primary Contact Role on the Account'));
    }
}