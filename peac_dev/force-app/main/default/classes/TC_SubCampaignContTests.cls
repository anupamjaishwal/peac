@IsTest
private class TC_SubCampaignContTests {
    @TestSetup static void createData() {
        Campaign camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('xyz', 3);
    }
    @IsTest static void testBehavior() {
        Test.startTest();

        Campaign camp = [SELECT Id, (SELECT Id FROM Auto_Follow_Ups__r) FROM Campaign WHERE Name = 'xyz' LIMIT 1];
        System.debug(camp.Auto_Follow_Ups__r);
        //Testing saving a new sub campaign
        TC_SubCampaignCont scc = new TC_SubCampaignCont();
        scc.parentCampaignId = camp.Id;
        scc.doCloneAutoFollowups = true;
        System.assert(scc.subCamp != null);
        scc.listViewVal = scc.listViews[1].getValue();
        System.assertEquals(scc.listViews[1].getValue(), scc.subCamp.ListViewDeveloperName__c);
        PageReference pr = scc.saveSubCampaign();
        System.assert(pr != null);
        Campaign subCamp = [SELECT Id, (SELECT Id FROM Auto_Follow_Ups__r) FROM Campaign WHERE ParentId = :camp.Id];
        System.assert(pr != null, 'The page reference was null, that means an error was returned:'+ (ApexPages.getMessages().isEmpty() ? '' : ApexPages.getMessages()[0].getDetail()));
        System.assert(pr.getUrl().contains(subCamp.Id), 'The page reference should contain the sub campaign Id');
        System.assert(!subCamp.Auto_Follow_Ups__r.isEmpty(), 'The auto follow up steps should have been cloned');

        //Testing initializing with the new sub campaign
        scc = new TC_SubCampaignCont();
        scc.existingSubCampaignId = subCamp.Id;
        pr = scc.cancelSubCampaign();
        System.assert(pr != null, 'The page reference was null, that means an error was returned:'+ (ApexPages.getMessages().isEmpty() ? '' : ApexPages.getMessages()[0].getDetail()));
        System.assert(pr.getUrl().contains(subCamp.Id));

        Test.stopTest();
    }
}