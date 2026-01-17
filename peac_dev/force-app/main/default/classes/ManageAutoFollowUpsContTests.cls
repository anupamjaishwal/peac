@IsTest
private class ManageAutoFollowUpsContTests {
    private static final String CAMPAIGN_NAME = 'campName';

    @TestSetup static void createData() {
        insert new Campaign(Name = CAMPAIGN_NAME);
    }

    @IsTest static void testBehavior() {
        Test.startTest();

        ManageAutoFollowUpsCont mafuc = new ManageAutoFollowUpsCont();
                                mafuc = new ManageAutoFollowUpsCont(new ApexPages.StandardController([SELECT Id FROM Campaign WHERE Name = :CAMPAIGN_NAME LIMIT 1]));
        System.assert(mafuc.camp != null);
        System.assertEquals(1, mafuc.autoFollowUps.size(), 'There should have been a single auto follow up record found');
        mafuc.addStep();
        mafuc.addStep();
        System.assertEquals(3, mafuc.autoFollowUps.size());
        mafuc.autoFollowUps[0].autoFollowUp.StepNumber__c = 2;
        mafuc.autoFollowUps[0].autoFollowUp.TaskSubject__c = 'test';
        mafuc.autoFollowUps[1].autoFollowUp.TaskSubject__c = 'test';
        mafuc.autoFollowUps[2].autoFollowUp.TaskSubject__c = 'test';
        mafuc.autoFollowUps[0].autoFollowUp.TaskComment__c = 'test';
        mafuc.autoFollowUps[1].autoFollowUp.TaskComment__c = 'test';
        mafuc.autoFollowUps[2].autoFollowUp.TaskComment__c = 'test';
        Test.setCurrentPage(Page.ManageAutoFollowUps);
        ApexPages.currentPage().getParameters().put('pgChangeType','moveDown');
        ApexPages.currentPage().getParameters().put('indexToChange','1');
        System.assert(mafuc.numAutoFollowUps != null);
        mafuc.pgChange();
        mafuc.actionSupport();
        PageReference pr = mafuc.doSave();
        System.assert(pr != null, 'The page reference was returned as null');
        System.assert(mafuc.cancel() != null);
        mafuc.doReOrder();

        Test.stopTest();
    }
}