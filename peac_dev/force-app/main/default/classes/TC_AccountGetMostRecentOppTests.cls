@IsTest
private class TC_AccountGetMostRecentOppTests {
    @TestSetup static void createData() {
        Campaign camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('Test', 3);

    }

    @IsTest static void setMostRecentOppTest() {
        Test.startTest();
        Account acct = TC_SDR_TestUtility.constructAccount('Test', null,null);

        insert acct;

        Opportunity opp = TC_SDR_TestUtility.constructOpportunity('Test',acct.Id);
        insert opp;
        acct = [SELECT Id, MostRecentOpportunity__c FROM Account WHERE Id = :acct.Id];
        //System.assert(acct.MostRecentOpportunity__c != null);
        Test.stopTest();
    }

    @IsTest static void setCampaignTest() {
        Test.startTest();
        Account acct = TC_SDR_TestUtility.constructAccount('Test', 'Test',null);

        insert acct;
        acct = [SELECT Id, CurrentCampaign__c FROM Account WHERE Id = :acct.Id];

       //System.assert(acct.CurrentCampaign__c != nulL);
    }
}