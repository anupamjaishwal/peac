@IsTest
private class TC_CampaignMemberHelperTests {

    @TestSetup static void createData() {

        Campaign camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('Test', 3);

        Account acct = TC_SDR_TestUtility.constructAccount('Test', camp.Name,null);
        acct.CurrentCampaign__c= camp.Id;
        insert acct;

    }

    @IsTest static void autoFollowupTransitions() {
        
        Campaign camp = [SELECT Id, Name FROM Campaign LIMIT 1];
        Account acct = [SELECT Id, Name FROM Account WHERE CurrentCampaign__c = :camp.Id];
        Lead l = TC_SDR_TestUtility.constructLead('ln', 'fn', acct.Name, acct.Id);
        insert l;

        CampaignMember cm = getCampaignMember(l.Id);

        List<Task> tasks = getTasksByWhoId(l.Id);
        System.assert(cm != null);
        System.assertEquals(1, cm.CurrentAutoFollowUpStep__r.StepNumber__c);
        System.assert(cm.CurrentAutoFollowUpStep__c != null, 'No follow-up step was added!');
        System.assert(cm.DateofLastStepTransition__c == Date.today(), 'The date of last transition was not today!');
        System.assertEquals(1, tasks.size());

        //Making sure that the campaign member was set with an auto follow-up step without the task closing
        cm = constructExistingCampaignMemberForTransition(cm.Id);
        update cm;
        Test.startTest();
        cm = queryCampaignMember(cm);
        System.assertEquals(1, cm.CurrentAutoFollowUpStep__r.StepNumber__c);//Making sure the step didn't transition without the task closing

        //Simulating a transition to the next step

        List<String> closedStatuses = new List<String>(new TC_TaskHelper.TC_TaskHelperGateway().getClosedStatuses());
        tasks[0].Status = closedStatuses[0];
        tasks[0].Activity_Type__c = 'Inbound';
        update tasks;
        
        tasks = getTasksByWhoId(l.Id);
        //System.assertEquals(2, tasks[0].AutoFollowUp__r.StepNumber__c, 'The next task step did not get triggered!');
        Id currentStepId = cm.CurrentAutoFollowUpStep__c;
        cm = constructExistingCampaignMemberForTransition(cm.Id);
        update cm;
        cm = queryCampaignMember(cm);

        //Testing post transition
        System.assertEquals(1, cm.CurrentAutoFollowUpStep__r.StepNumber__c);
        /*tasks = getTasksByWhoId(l.Id);
        System.assertEquals(1, tasks.size(), 'More than one task was open!');

        //Simulating moving to the next step
        tasks[0].Status = closedStatuses[0];
        update tasks;
        cm = constructExistingCampaignMemberForTransition(cm.Id);
        update cm;
        cm = queryCampaignMember(cm);

        //Testing post transition
        System.assertEquals(3, cm.CurrentAutoFollowUpStep__r.StepNumber__c);
        System.assert(cm.CurrentAutoFollowUpStep__c != currentStepId, 'The step was not transitioned!');
        currentStepId = cm.CurrentAutoFollowUpStep__c;
        tasks = getTasksByWhoId(l.Id);
        System.assertEquals(1, tasks.size(), 'More than one task was open!');

        //Testing last transition step
        tasks[0].Status = closedStatuses[0];
        update tasks;
        cm = constructExistingCampaignMemberForTransition(cm.Id);
        update cm;
        //This is the last step in the auto follow-up cycle, making sure that the loop closes
        cm = queryCampaignMember(cm);

        System.assert(cm.AutoFollowUpsCompleted__c,'The auto follow-up was not completed!'); */

        Test.stopTest();
    }

    @IsTest static void campaignSwitchTest() {
        Test.startTest();
        Account acct = [SELECT Id, Name FROM Account WHERE CurrentCampaign__c != null];
        Lead l = TC_SDR_TestUtility.constructLead('ln', 'fn', acct.Name, acct.Id);
        insert l;
        Campaign camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('Test2', 3);
        acct.Target_SDR_Campaign__c = camp.Name;
        update acct;
        update l;
        List<CampaignMember> cms = [SELECT Id, CampaignId FROM CampaignMember WHERE LeadId = :l.Id];
        System.assertEquals(1, cms.size(), 'The old campaign member was not removed!');
        System.assertEquals(camp.Id, cms[0].CampaignId,'The new campaign member did not get generated');
        delete cms;

    }

    private static CampaignMember queryCampaignMember(CampaignMember cm) {
        return getCampaignMember(cm.Id);
    }

    private static CampaignMember getCampaignMember(Id idToQuery) {
        return [SELECT Id, CurrentAutoFollowUpStep__c, CurrentAutoFollowUpStep__r.StepNumber__c, CurrentAutoFollowUpStep__r.Name, DateofLastStepTransition__c, DateTimeOfLastTransition__c, AutoFollowUpsCompleted__c, fml_FollowUpTaskNeeded__c, fml_NextFollowUpDate__c FROM CampaignMember WHERE Id = :idToQuery OR LeadId = :idToQuery];
    }

    private static List<Task> getTasksByWhoId(Id whoId) {
        return [SELECT Id, Status, IsClosed, AutoFollowUp__c, AutoFollowUp__r.StepNumber__c FROM Task WHERE (Lead__c = :whoId OR WhoId = :whoId) AND IsClosed = FALSE AND AutoFollowUp__c <> NULL];
    }
    
    private static CampaignMember constructExistingCampaignMemberForTransition(Id cmId) {
        return new CampaignMember(Id = cmId, DateofLastStepTransition__c = Date.today().addDays(-30), DateTimeOfLastTransition__c = System.now().addDays(-30));
    }
}