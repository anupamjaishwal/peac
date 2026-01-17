@IsTest
private class NewLeadButtonContTests {
    private static String campNm = 'Test Camp';

    @TestSetup static void setupData() {

        Campaign cmp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps(campNm,2);
        Account acct = TC_SDR_TestUtility.constructAccount('Test',campNm,null);
        acct.CurrentCampaign__c = cmp.Id;
        insert acct;

    }

    @IsTest static void noLeadTest() {
        Test.startTest();
        Account acct = [SELECT Id FROM Account WHERE CurrentCampaign__r.Name = :campNm];
        ApexPages.StandardController sc = new ApexPages.StandardController(acct);
        Test.setCurrentPage(Page.NewLeadButtonAccount);
        NewLeadButtonCont nlbc = new NewLeadButtonCont(sc);
        nlbc.doInit();
        System.assert(![SELECT Id FROM Lead WHERE PrimaryAccount__c = :acct.Id].isEmpty(),'No lead was created!');
        System.assert(nlbc.navToNextPage() != null);
        Test.stopTest();
    }

    @IsTest static void noCampaignTest() {
        Test.startTest();
        Account acct = TC_SDR_TestUtility.constructAccount('Test2',null,null);
        insert acct;
        System.debug([SELECT Id, fml_DerivedCampaign__c FROM Account WHERE Id = :acct.Id]);
        ApexPages.StandardController sc = new ApexPages.StandardController(acct);
        Test.setCurrentPage(Page.NewLeadButtonAccount);
        NewLeadButtonCont nlbc = new NewLeadButtonCont(sc);
        PageReference pr = nlbc.doInit();
        System.debug('pr===>'+pr);
       // System.assert(pr == null,'The page reference should have been returned as null');
      //  System.assert(!ApexPages.getMessages().isEmpty(),'Error messages should have been present!');
        Test.stopTest();
    }
}