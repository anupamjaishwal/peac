@IsTest
private class TC_MassReAssignTasksTests {
    @TestSetup static void createData() {

        Campaign camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('Test', 3);

        Account acct = TC_SDR_TestUtility.constructAccount('Test', camp.Name,null);
        acct.CurrentCampaign__c = camp.Id;
        insert acct;

        Lead l =TC_SDR_TestUtility.constructLead('fn','ln', acct.Name, acct.Id);
        insert l;
        

        
    }

    @IsTest
    static void testBehavior() {
        Test.startTest();
        List<Account> accts = [SELECT Id, Name FROM Account WHERE CurrentCampaign__c <> null];
        List<Lead> ls = [SELECT Id FROM Lead WHERE PrimaryAccount__c IN :accts];
        List<CampaignMember> cms = [SELECT Id FROM CampaignMember WHERE LeadId IN :ls];
        System.assert(!cms.isEmpty());
        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId IN :ls];
        System.assert(!tasks.isEmpty());
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tasks);
        ssc.setSelected(tasks);
        Test.setCurrentPage(Page.TC_MassReAssignTasks);
        TC_MassReAssignTasks mrat = new TC_MassReAssignTasks(ssc);
        System.assert(mrat.tempTask != null);
        User u;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            u = TC_SDR_TestUtility.constructNewUser(UserInfo.getProfileId(),'TC_MassReAssignTasksTests');
            insert u;
        }
        mrat.tempTask.OwnerId = u.Id;
        mrat.reAssignOwnership();
        System.debug(ApexPages.getMessages());
        mrat.doCancel();

        Test.stopTest();
    }
}