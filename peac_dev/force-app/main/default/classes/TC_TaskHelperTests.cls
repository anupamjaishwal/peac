@IsTest
private class TC_TaskHelperTests {
    @TestSetup static void createData() {
// copado please
        Campaign camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('Test', 3);

        Account acct = TC_SDR_TestUtility.constructAccount('Test', camp.Name,null);

        insert acct;

        Lead l =TC_SDR_TestUtility.constructLead('fn','ln', acct.Name, acct.Id);

        insert l;
        
        Contact contct = TC_SDR_TestUtility.constructContact('Test', 'Dummy', 'test@test.com',acct.Id);
	contct.Phone = '5565565665';
        insert contct;
        
        Case newCase = new Case(Subject = 'test', Description = 'test case', OwnerId = UserInfo.getUserId(), ContactId = contct.Id);
        insert newCase;
    }

    private static List<String> closedTaskStatuses {
        get {
            if (closedTaskStatuses == null) {
                closedTaskStatuses = TC_SDR_TestUtility.getClosedStatuses();
            }
            return closedTaskStatuses;
        }
        set;
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();
        List<Case> cse = [Select Id,ContactId,Initial_Response__c from Case];
        List<Contact> contct = [Select Id,Name from Contact];
        List<Lead> leads = [SELECT Id FROM Lead WHERE PrimaryAccount__c <> NULL AND CurrentCampaign__c <> NULL];
        List<CampaignMember> cms = [SELECT Id, AutoFollowUpsCompleted__c, LeadId, CurrentAutoFollowUpStep__c FROM CampaignMember WHERE LeadId IN : leads AND CurrentAutoFollowUpStep__c <> NULL];
        System.assert(!cms.isEmpty());
        System.assert(!leads.isEmpty());
        SDR_Prospecting_Settings__c sps = TC_TaskHelper.sdrProspectingSettings;
        User u = [SELECT Id FROM User WHERE UserName like 'usertenfold%'];
        System.runAs(u) {
            insert new Task(Subject = 'test',Activity_Type__c= 'outbound',  Status = closedTaskStatuses[0], ActivityDate = Date.today(),AutoFollowUp__c = cms[0].CurrentAutoFollowUpStep__c, WhoId = cms[0].LeadId, Lead__c = cms[0].LeadId);
            insert new Task(Subject = 'test Case',Activity_Type__c= 'Inbound',  Status = closedTaskStatuses[0], ActivityDate = Date.today(), WhoId = contct[0].Id, WhatId = cse[0].Id);
        }
        System.assertEquals(1,[SELECT Id FROM Task WHERE Lead__c = :cms[0].LeadId AND IsClosed = TRUE].size());

        Test.stopTest();
    }
}