@IsTest
private class TC_AccountToLeadTests {
    @TestSetup static void createData() {

        Campaign camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('Test', 3);

        Account acct = TC_SDR_TestUtility.constructAccount('Test', camp.Name,null);
        insert acct;

    }
    @IsTest
    static void testBehavior() {
        Test.startTest();
        List<Account> accts = [SELECT Id FROM Account WHERE CurrentCampaign__c <> NULL];
        TC_AccountToLead atl = new TC_AccountToLead(accts);
        List<Database.Error> errors = atl.createLeadsFromAccounts();
        System.assert(errors.isEmpty(),'There were errors!');
        System.assertEquals(accts.size(), [SELECT Id FROM Lead WHERE PrimaryAccount__c IN :accts].size(), 'There should have been one lead per account!');
        Test.stopTest();
    }
}