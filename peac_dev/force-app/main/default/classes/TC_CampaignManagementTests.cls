@IsTest
private class TC_CampaignManagementTests {
    @TestSetup static void createData() {

        Campaign camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('Test', 3);

        Account acct = TC_SDR_TestUtility.constructAccount('Test', camp.Name,null);
        insert acct;

    }
    @IsTest
    static void testBehavior() {
        Test.startTest();
        TC_AccountGetMostRecentOpp.doCampaignTransition = false;
        List<Account> accts = [SELECT Id, Target_SDR_Campaign__c, CurrentCampaign__r.Name, fml_DerivedCampaign__c, fml_AccountNeedsCampaignUpdate__c FROM Account WHERE CurrentCampaign__c <> NULL];
        System.debug(accts);
        TC_AccountToLead atl = new TC_AccountToLead(accts);
        List<Database.Error> errors = atl.createLeadsFromAccounts();
        System.assert(errors.isEmpty(),'There were errors!');
        System.assertEquals(accts.size(), [SELECT Id FROM Lead WHERE PrimaryAccount__c IN :accts].size(), 'There should have been one lead per account!');
        TC_CampaignManagement tcm = new TC_CampaignManagement();
        errors = tcm.transitionAccountCampaign(accts);
        System.assert(errors.isEmpty());

        //Switching the campaign to a "new" one that the class will auto create
        for (Account acct : accts) {
            acct.Target_SDR_Campaign__c = 'Test 2';
        }
        update accts;

        accts = [SELECT Id, Target_SDR_Campaign__c, CurrentCampaign__r.Name, fml_DerivedCampaign__c, fml_AccountNeedsCampaignUpdate__c FROM Account WHERE CurrentCampaign__c <> NULL];
        System.debug(JSON.serializePretty(accts,true));
        tcm = new TC_CampaignManagement();
        errors = tcm.transitionAccountCampaign(accts);

        System.assert(errors.isEmpty());
       // System.assert([SELECT Id FROM Account WHERE fml_AccountNeedsCampaignUpdate__c = TRUE].isEmpty(),'All the accounts should have been updated!');
        Test.stopTest();
    }
}