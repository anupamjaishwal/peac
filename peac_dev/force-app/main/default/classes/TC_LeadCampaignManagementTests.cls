@IsTest
private class TC_LeadCampaignManagementTests {
    @TestSetup static void createData() {

        Campaign camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('Test', 3);
        TC_SDR_TestUtility.createCampaignAndAutoFollowUps('Digital', 3);

        Account acct = TC_SDR_TestUtility.constructAccount('Test', camp.Name,null);
        acct.Target_SDR_Campaign__c = 'Digital';
        insert acct;

        Lead l =TC_SDR_TestUtility.constructLead('fn','ln', acct.Name, acct.Id);

        insert l;
        Test.startTest(); // SAL-2779
        Opportunity opp = TC_SDR_TestUtility.constructOpportunity('Test', acct.Id);
        insert opp;
        Test.stopTest();
    }

    @IsTest static void digitalLeadTest() {
        Test.startTest();
        Lead l = queryLead(null);
        List<PicklistEntry> ples = Lead.getSObjectType().getDescribe().fields.getMap().get('Primary_Source__c').getDescribe().picklistValues;
        String primarySource;

        for (PicklistEntry ple : ples) {
            if (ple.value.startsWith('Digital')) primarySource = ple.value;
            if (String.isNotBlank(primarySource)) break;
        }

        //Setting the primary source to digital, which should force the lead onto the digital lead campaign
        l.Primary_Source__c = primarySource;
        update l;

        //Querying and testing
        l = queryLead(l.Id);
        System.assert(l.CurrentCampaign__c != null, 'A campaign should be set!');
        System.assert(l.fml_CampaignName__c == 'Digital', 'The campaign name should be Digital!');
        System.assertEquals(l.CampaignMembers.size(), 1, 'Only 1 Campaign Member should be present');
        System.assertEquals(l.Tasks.size(), 1, 'There should have been an open task');

        //Setting the lead outcome and an opportunity id, this should cause the current campaign member to be eliminated
        //as well as any open tasks
        l.Lead_Outcome__c = getLeadOutcomeValue();
        l.Opportunity_Record_ID__c = l.PrimaryAccount__r.MostRecentOpportunity__c;

        update l;

        //Querying and testing
        l = queryLead(l.Id);
        System.assert(l.Tasks.isEmpty(),'There should be no open tasks associated to this lead!');

        Test.stopTest();
    }

    @IsTest static void decisionOppTest() {
        Test.startTest();
        Lead l = queryLead(null);
        List<PicklistEntry> ples = Lead.getSObjectType().getDescribe().fields.getMap().get('Primary_Source__c').getDescribe().picklistValues;
        String primarySource;

        for (PicklistEntry ple : ples) {
            if (ple.value.startsWith('Digital')) primarySource = ple.value;
            if (String.isNotBlank(primarySource)) break;
        }

        update l;
        Opportunity opp = [SELECT Id FROM Opportunity WHERE AccountId = :l.PrimaryAccount__c LIMIT 1];
        opp.StageName = 'Decision';
        Id oppRtId = Opportunity.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get('Funding_Stream_Opportunity').getRecordTypeId();
        opp.RecordTypeId = oppRtId;
        opp.CaseCenter__c = '123456789012345';
        opp.Loan_Purpose__c = Opportunity.getSObjectType().getDescribe().fields.getMap().get('Loan_Purpose__c').getDescribe().picklistValues[0].getValue();
        opp.Primary_Source__c = Opportunity.getSObjectType().getDescribe().fields.getMap().get('Primary_Source__c').getDescribe().picklistValues[0].getValue();
        opp.Oppt_FS_Use_Of_Funds__c = 'Testing 12345';
        update opp;
        update l;
        l = queryLead(l.Id);
        
        for (CampaignMember cm : l.CampaignMembers) {
           // System.assert(cm.AutoFollowUpsCompleted__c);
        }

        Test.stopTest();
    }

    @IsTest static void campaignSwitchTest() {
        Test.startTest();
        //Creating the new campaign
        Campaign newCamp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('NewTest', 3);

        //Getting the existing lead
        Lead l = queryLead(null);

        //Creating an account to update
        Account pAcct = new Account(Id = l.PrimaryAccount__c, Target_SDR_Campaign__c = newCamp.Name);

        //Updating the account so it will get the new campaign
        update pAcct;

        //Updating the lead so it will be forced to the same campaign as the account
        update l;

        //Querying the lead and running tests
        l = queryLead(l.Id);
        System.assertEquals(l.CurrentCampaign__c, newCamp.Id, 'The current campaign on the lead should match that of the new campaign');
        System.assertEquals(l.CampaignMembers.size(), 1, 'Only 1 Campaign Member should be present');
        System.assertEquals(l.CampaignMembers[0].CampaignId, newCamp.Id, 'The campaign Id of the campaign member and new campaign should be the same');
        System.assertEquals(l.Tasks.size(), 1, 'There should have been an open task');

        //Setting the lead outcome so we can test that everything is closed out
        l.Lead_Outcome__c = getLeadOutcomeValue();
        update l;

        //Querying the lead and running tests
        l = queryLead(l.Id);
        System.assertEquals(l.CampaignMembers.size(), 1, 'Only 1 Campaign Member should be present');
        System.assert(l.CampaignMembers[0].AutoFollowUpsCompleted__c, 'The auto follow up campaign was not marked as completed!');
        System.assert(l.Tasks.isEmpty(), 'There were open tasks left!');

        Test.stopTest();
    }

    private static String getLeadOutcomeValue() {
        return Lead.getSObjectType().getDescribe().fields.getMap().get('Lead_Outcome__c').getDescribe().picklistValues[0].getValue();
    }

    private static Lead queryLead(Id lId) {
        String query = 'SELECT  Id, CurrentCampaign__c, fml_CampaignName__c, PrimaryAccount__c, PrimaryAccount__r.MostRecentOpportunity__c,Lead_Outcome__c,'+
                        '(SELECT Id, AutoFollowUpsCompleted__c, Campaign.Name, CampaignId FROM CampaignMembers),'+
                        '(SELECT Id FROM Tasks WHERE IsClosed = FALSE)'+
                        'FROM Lead';
               query += ' WHERE ' + (lId == null ? ' PrimaryAccount__c <> :lId' : ' Id = :lId');

        return (Lead) Database.query(query)[0];
    }
}