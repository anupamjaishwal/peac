@IsTest
private class TC_PullTaskContTests {

    @TestSetup static void createData() {

        Campaign camp = TC_SDR_TestUtility.createCampaignAndAutoFollowUps('xyz', 3);

        Account acct = TC_SDR_TestUtility.constructAccount('Test', camp.Name,null);

        insert acct;

        Lead l =TC_SDR_TestUtility.constructLead('fn','ln', acct.Name, acct.Id);

        insert l;
    }

    @IsTest static void sscTest() {
        Test.startTest();
        List<Account> accts = [SELECT Id, Name FROM Account WHERE CurrentCampaign__c <> null];
        List<Lead> ls = [SELECT Id FROM Lead WHERE PrimaryAccount__c IN :accts];
        List<CampaignMember> cms = [SELECT Id FROM CampaignMember WHERE LeadId IN :ls];
        //System.assert(!cms.isEmpty());
        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId IN :ls];
        //System.assert(!tasks.isEmpty());
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(tasks);
        ssc.setSelected(tasks);
        Test.setCurrentPage(Page.TC_PullTask);
        TC_PullTaskCont ptc = new TC_PullTaskCont(ssc);
        ptc.numToPull = 1;
        ptc.pullTasks();
        System.debug(ApexPages.getMessages());
        System.assert(ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }

   /* @IsTest static void scTest() {
        Test.startTest();
        List<Account> accts = [SELECT Id, Name FROM Account WHERE CurrentCampaign__c <> null];
        List<Lead> ls = [SELECT Id FROM Lead WHERE PrimaryAccount__c IN :accts];
        List<CampaignMember> cms = [SELECT Id FROM CampaignMember WHERE LeadId IN :ls];
        //System.assert(!cms.isEmpty());
        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId IN :ls];
        //System.assert(!tasks.isEmpty());
        ApexPages.StandardController sc = new ApexPages.StandardController(tasks[0]);
        Test.setCurrentPage(Page.TC_PullTask);
        TC_PullTaskCont ptc = new TC_PullTaskCont(sc);
        ptc.goToTask();
        System.debug(ApexPages.getMessages());
        System.assert(ApexPages.getMessages().isEmpty());
        Test.stopTest();
    } */
    @IsTest static void contTest() {
        Test.startTest();
        List<Account> accts = [SELECT Id, Name FROM Account WHERE CurrentCampaign__c <> null];
        List<Lead> ls = [SELECT Id FROM Lead WHERE PrimaryAccount__c IN :accts];
        List<CampaignMember> cms = [SELECT Id FROM CampaignMember WHERE LeadId IN :ls];
        //System.assert(!cms.isEmpty());
        List<Task> tasks = [SELECT Id FROM Task WHERE WhoId IN :ls];
        //System.assert(!tasks.isEmpty());
        Test.setCurrentPage(Page.TC_PullAnyCampaignsTask);
        TC_PullTaskCont ptc = new TC_PullTaskCont();
        System.debug(ptc.pullAnyCampaign);
        ptc.goToTask();
        System.debug(ApexPages.getMessages());
        System.assert(ApexPages.getMessages().isEmpty());
        Test.stopTest();
    }
}