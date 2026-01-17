@isTest
public with sharing class TC_AutoSetPortfolioThresholdsTest {
    @isTest
    static void scenario1() {
        SL_SCTestData.createAccountAndContracts(1, 1);
        User u = SL_SCTestData.testUser;
        Test.startTest();
        User theOwner = testdatafactory.createTestUser();
        System.runAs(u){
            theOwner.ProfileId = [SELECT Id FROM Profile WHERE Name = 'SDR'][0].Id;
            update theOwner;
        }
        Account theAccount = SL_SCTestData.testAccounts[0];
        theAccount.DM_Review_Status__c = 'Submitted for Review';
        theAccount.OwnerId = theOwner.Id;
        Database.SaveResult updateResult = Database.update(theAccount, false);
        Id dealerAccountId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Dealer Account').getRecordTypeId();
        TestDataFactory.prepareAccounts(1, dealerAccountId, '');
        TestDataFactory.testAccounts[0].DM_Review_Status__c = 'Submitted for Review';
        TestDataFactory.testAccounts[0].OwnerId = theOwner.Id;
        Database.SaveResult insertResult = Database.insert(TestDataFactory.testAccounts[0], false);
        Test.stopTest();
        List<Account> accountsAfter = [SELECT Id, Portfolio_Review_Threshold__c FROM Account];
        //System.assert(updateResult.getErrors()[0].getMessage().contains('Invalid DM Review Status for assigned profile'));
        //System.assert(insertResult.getErrors()[0].getMessage().contains('Invalid DM Review Status for assigned profile'));
        // System.assertEquals(null, accountsAfter[0].Portfolio_Review_Threshold__c);
        // System.assertEquals('250,000', accountsAfter[1].Portfolio_Review_Threshold__c);
    }
}