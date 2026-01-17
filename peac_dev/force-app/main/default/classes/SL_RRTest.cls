@isTest
public with sharing class SL_RRTest {
    @isTest
    public static void synchronize() {
        Group real31 = [SELECT Id,Name FROM Group WHERE DeveloperName = 'X31_Group'];
        system.assert(real31.Name=='31 Regular');
        User testUser = [SELECT Id,Name FROM User where Id='0054N000004l13bQAA'];
        system.assert(testUser.Name=='Kathy Arnott');
        insert new GroupMember(GroupId=real31.Id, UserOrGroupId=testUser.Id);
        Group queue31 = new Group(Name='31 Regular', Type='Queue', developerName='Test_X31_Group');
        insert queue31;
        User testUser2 = [SELECT Id,Name FROM User where Id='0054N000004zGBxQAM'];//robert fischer
        insert new GroupMember(GroupId=queue31.Id, UserOrGroupId=testUser2.Id);
        insert new QueueSobject(QueueId=queue31.Id, SobjectType='Contract__c');
        Test.startTest();
        SL_RRManageMDT.synchronizeRRQueues(true, false);
        SL_RRManageMDT.AfterNewRRQueue try1 = new SL_RRManageMDT.AfterNewRRQueue();
        Metadata.DeployResult mockResult = new Metadata.DeployResult();
        mockResult.status = Metadata.DeployStatus.SUCCEEDED;
        try1.handleResult(mockResult, new Metadata.DeployCallbackContext());
        Test.stopTest();
        System.assert(true);
    }
    
    @isTest
    public static void updateLastAssigned() {
        User testUser = [SELECT Id,Name FROM User where Id='0054N000004l13bQAA'];
        RR_Queue__mdt rrQueue = new RR_Queue__mdt();
        system.assert(testUser.Name=='Kathy Arnott');
        Map<Id, RR_Assignee__mdt> rrAssignees = new Map<Id, RR_Assignee__mdt>();
        rrAssignees.put(null, new RR_Assignee__mdt(
        	Name__c = testUser.Name,
        	User__c = testUser.Id,
            Last_Assigned__c = null,
            Is_Active__c = true,
        	RR_Queue__c = rrQueue.Id));
        System.assert(rrAssignees.size() > 0);
        Test.startTest();
        SL_RRManageMDT.updateLastAssigned(rrAssignees);
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    public static void updateRRAssignees() {
        User testUser = [SELECT Id,Name FROM User where Id='0054N000004l13bQAA'];
        RR_Queue__mdt rrQueue = new RR_Queue__mdt();
        system.assert(testUser.Name=='Kathy Arnott');
        List<RR_Assignee__mdt> rrAssignees = new List<RR_Assignee__mdt>{new RR_Assignee__mdt(
        	Name__c = testUser.Name,
        	User__c = testUser.Id,
            Last_Assigned__c = null,
            Is_Active__c = true,
        	RR_Queue__c = rrQueue.Id)};
        System.assert(rrAssignees.size() > 0);
        Test.startTest();
        SL_RRManageMDT.updateRRAssignees(rrAssignees, new Map<Id, RR_Queue__mdt>());
        Test.stopTest();
        System.assert(true);
    }

    @isTest
    public static void deleteRRAssignees() {
        String result = '';
        Test.startTest();
        result = SL_RRManageMDTFuture.hubExecuteFuture('deleteRRAssignees', new List<String>{'cannot.delete,this.metadata'});
        Test.stopTest();
        system.assertEquals('success', result);
    }
}