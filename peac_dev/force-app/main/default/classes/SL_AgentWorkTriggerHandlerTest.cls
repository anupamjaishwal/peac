@isTest
public with sharing class SL_AgentWorkTriggerHandlerTest {
    @isTest(seeAllData=true)
    public static void scenario1() {
        Group ownerQueue = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'All_Other'];
        Case newCase = new Case(Subject = 'test', Description = 'test case', OwnerId = ownerQueue.Id, Status = 'New');
        insert newCase;
        ServiceChannel theChannel = [SELECT Id, DeveloperName FROM ServiceChannel WHERE DeveloperName = 'Case_Channel'];
        ServicePresenceStatus thePresenceStatus = [SELECT Id, DeveloperName FROM ServicePresenceStatus WHERE DeveloperName = 'Available_Case'];
        List<User> theAgent = [SELECT Id, Name FROM User WHERE Name = 'Susan Carpenter'];
        // seems like there is no way to do this programmatically, doing this would need more research time
        // UserServicePresence theUserPresence = [SELECT Id FROM UserServicePresence LIMIT 1];
        // theUserPresence.UserId = theAgent.Id;
        // theUserPresence.ServicePresenceStatusId = thePresenceStatus.Id;
        // insert theUserPresence;
        List<AgentWork> oneExisting = [SELECT Id FROM AgentWork LIMIT 1];
        Id testId = oneExisting.size() > 0 ? oneExisting[0].Id: Id.valueOf('0Bz4N0000000001');
        AgentWork theAgentWork = new AgentWork(Id = testId, WorkItemId = newCase.Id, ServiceChannelId = theChannel.Id, UserId = theAgent[0].Id);
        Test.startTest();
        // System.Assert.areNotEqual(null, theAgentWork.Id, 'no agentWork created, problem');
        
        try{
            update theAgentWork;
        }catch(Exception error){}
        List<String> omniChannelOpenStages = new List<String>{'New', 'On Hold', 'Escalated'};
        List<String> fieldsChanged = new List<String>{'Status'};
        List<Case> casesToInProgress = new List<Case>();
        Map<Id, Case> cases = new Map<Id, Case>();
        cases.put(newCase.Id, newCase);
        casesToInProgress = SL_AgentWorkTriggerHandler.setCaseInProgress(theAgentWork, fieldsChanged, cases, casesToInProgress,
            omniChannelOpenStages);
        Test.stopTest();
        System.Assert.areEqual(1, casesToInProgress.size(), 'the case Status needs to be set to In Progress when the AgentWork Status = Opened');
        System.Assert.areEqual('In Progress', casesToInProgress[0].Status, 'the case Status needs to be set to In Progress when the AgentWork Status = Opened');
    }
}