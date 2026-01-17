@IsTest
private class TC_SubCampaignTests {
    @TestSetup static void createData() {
        List<ListView> acctListViews = [SELECT Id, DeveloperName FROM ListView WHERE SobjectType = 'Account' AND IsSoqlCompatible = TRUE LIMIT 2];
        Campaign camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('xyz', 3);
        camp.ListViewDeveloperName__c = acctListViews[0].DeveloperName;
        camp.IsActive = true;
        update camp;
        camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('abc', 3);
        camp.ListViewDeveloperName__c = acctListViews[1].DeveloperName;
        camp.IsActive = true;
        update camp;

        Account acct = TC_SDR_TestUtility.constructAccount('Test', null,null);

        insert acct;
    }
    @IsTest static void TC_SubCampaignQueueableTests() {
        Test.startTest();
        JobSequence js = new JobSequence(getSequenceJob());
        js.batchSize = 10;
        //Testing the various constructors that don't need real validations
        System.assert(new TC_SubCampaignQueueable() != null);
        System.assert(new TC_SubCampaignQueueable(js) != null);

        List<Campaign> camps = Database.query(js.query);
        System.assert(!camps.isEmpty() && camps.size() == 2, 'There should only be two campaigns found!');
        //Simulating the first call from the job sequencer
        TC_SubCampaignQueueable scq = new TC_SubCampaignQueueable(js, camps);
        scq.execute(null);
        System.assert(scq.thisSubCampaign != null, 'There should have been a sub campaign record found!');
        System.assertEquals(camps[0].Id, scq.thisSubCampaign.Id, 'The Id of the sub campaign was incorrect!');
        //Testing as if the batch job had completed its processing
        scq = new TC_SubCampaignQueueable(js, camps[0].Id);
        scq.execute(null);
        System.assert(scq.thisSubCampaign != null, 'There should have been a sub campaign record found!');
        System.assertEquals(camps[1].Id, scq.thisSubCampaign.Id, 'The Id of the sub campaign was incorrect');

        //Testing as if the batch had completed the last sub campaign
        scq = new TC_SubCampaignQueueable(js, camps[1].Id);
        scq.execute(null);
        System.assertEquals(null, scq.thisSubCampaign, 'There should not be another sub campaign to be processed!');
        Test.stopTest();
    }

    @IsTest static void TC_SubCampaignBatchTests() {
        Test.startTest();
        JobSequence js = new JobSequence(getSequenceJob());

        List<Campaign> camps = Database.query(js.query);
        System.assert(!camps.isEmpty() && camps.size() == 2, 'There should only be two campaigns found!');

        Campaign targetCamp = camps[0];
        TC_SubCampaignBatch scb = new TC_SubCampaignBatch();
        System.assert (scb != null);
        scb = new TC_SubCampaignBatch(js, targetCamp.Id, 'SELECT Id FROM Account');
        Database.executeBatch(scb);
        Test.stopTest();
        //Making sure that the batch job executed as expected
        List<Account> accts = [SELECT Id, Target_SDR_Campaign__c FROM Account WHERE Target_SDR_Campaign__c <> null];
        System.assert(!accts.isEmpty(), 'Accounts should have been set with a target SDR Campaign!');
        for (Account acct : accts) {
            System.assertEquals(targetCamp.Name, acct.Target_SDR_Campaign__c, 'The target SDR campaign should have been set to the target campaign!');
        }
    }

    private static Sequence_Job__mdt getSequenceJob() {
        return [
                SELECT
                        Active__c,
                        AllOrNone__c,
                        BatchLimit__c,
                        DeveloperName,
                        ExecutionJob__c,
                        Frequency__c,
                        From__c,
                        HandlerClass__c,
                        Id,
                        IsBatchJob__c,
                        Label,
                        Language,
                        Limit__c,
                        MasterLabel,
                        NamespacePrefix,
                        NotificationEmail__c,
                        Order__c,
                        OrderBy__c,
                        Parameters__c,
                        PermDelete__c,
                        QualifiedApiName,
                        Select__c,
                        Type__c,
                        UpsertExtIdField__c,
                        Where__c
                FROM Sequence_Job__mdt WHERE DeveloperName = 'Process_All_Sub_Campaign_Members'];
    }
}