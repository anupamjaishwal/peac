@isTest
public class SL_TaskTriggerHandlerTest {
    static final Id serviceRecordTypeId = [SELECT Id, Name, DeveloperName, IsActive  FROM RecordType Where isActive = true AND SobjectType = 'Task' AND DeveloperName = 'Service_Activity' LIMIT 1].Id;
    @isTest
    static void testInsertTask(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contact cn = SL_SCTestData.testContacts[0];
        Case c = new Case(Subject ='Test Case', ContactId = cn.Id, Contract_Custom__c = SL_SCTestData.testContracts[0].Id);
        insert c;
        Test.startTest();
        Task t = new Task(Subject = 'Test Task', whatId = c.Id, WhoId = cn.Id, RecordTypeId = serviceRecordTypeId);
        insert t;
        Test.stopTest();
        Case caseAfter = [SELECT Id, Initial_Response__c FROM Case WHERE Id = :c.Id];
        Task taskAfter = [SELECT Id, Subject, WhatId, WhoId, RecordTypeId, Contract__c FROM Task WHERE Id = :t.Id];
        System.assert(caseAfter.Initial_Response__c != null);
        System.assertEquals(SL_SCTestData.testContracts[0].Id, taskAfter.Contract__c);
    }
    @isTest
    static void testUpdateTaskAfterCase(){
        Contact cn = new Contact(FirstName ='Bobby', LastName = 'Newmark', Phone = '1234567890');
        insert cn;
        Case c = new Case(Subject ='Test Case', ContactId = cn.Id);
        insert c;
        Task t2 = new Task(Subject = 'Test Task 2', whatId = c.Id, RecordTypeId = serviceRecordTypeId);
        insert t2;
        Test.startTest();
        Task t = new Task(Subject = 'Test Task', whatId = c.Id, WhoId = cn.Id, RecordTypeId = serviceRecordTypeId);
        insert t;
        Task t3 = new Task(Subject = 'Test Task 3', whatId = c.Id, RecordTypeId = serviceRecordTypeId);
        insert t3;
        Test.stopTest();
        Case caseAfter = [SELECT Id, Initial_Response_SLA__c, Response_Due__c, Initial_Response__c FROM Case WHERE Id = :c.Id];
        List<Task> tasksAfter = [SELECT Id, Initial_Response_SLA__c, Response_Due__c, Initial_Response__c FROM Task];
        System.assert(tasksAfter[0].Initial_Response__c != null);
        System.assert(tasksAfter[1].Initial_Response__c != null);
        System.assert(tasksAfter[2].Initial_Response__c != null);
        System.assert(tasksAfter[0].Initial_Response_SLA__c == caseAfter.Initial_Response_SLA__c);
        System.assert(tasksAfter[1].Initial_Response_SLA__c == caseAfter.Initial_Response_SLA__c);
        System.assert(tasksAfter[2].Initial_Response_SLA__c == caseAfter.Initial_Response_SLA__c);
        System.assert(tasksAfter[0].Response_Due__c == caseAfter.Response_Due__c);
        System.assert(tasksAfter[1].Response_Due__c == caseAfter.Response_Due__c);
        System.assert(tasksAfter[2].Response_Due__c == caseAfter.Response_Due__c);
    }

    @isTest
    static void DatesForOutcomes(){
        SL_SCTestData.createAccountAndContracts(1, 1);
        Contract__c contract = SL_SCTestData.testContracts[0];
        List<Task> newTasks = new List<Task>();
        Task t = new Task(Subject = 'Test Task', Department__c = 'Collections', Primary_Call_Outcome__c = 'Demand Letter Sent', isContractCallFollowup__c = true, whatId = contract.Customer__c, Contract__c = contract.Id, RecordTypeId = serviceRecordTypeId);
        Task t2 = new Task(Subject = 'Test Task 2', Department__c = 'Collections', Primary_Call_Outcome__c = 'Legal Letter Sent', isContractCallFollowup__c = true, whatId = contract.Customer__c, Contract__c = contract.Id, RecordTypeId = serviceRecordTypeId);
        Task t3 = new Task(Subject = 'Test Task 3', Department__c = 'Collections', Primary_Call_Outcome__c = 'NOD Requested', isContractCallFollowup__c = true, whatId = contract.Customer__c, Contract__c = contract.Id, RecordTypeId = serviceRecordTypeId);
        Task t4 = new Task(Subject = 'Test Task 4', Department__c = 'Collections', Primary_Call_Outcome__c = 'Direct Debit Authorization Revoked', isContractCallFollowup__c = true, whatId = contract.Customer__c, Contract__c = contract.Id, RecordTypeId = serviceRecordTypeId);
        Task t5 = new Task(Subject = 'Test Task 5', Department__c = 'Operations', Primary_Call_Outcome__c = 'RA Issued', isContractCallFollowup__c = true, whatId = contract.Customer__c, Contract__c = contract.Id, RecordTypeId = serviceRecordTypeId);
        newTasks.add(t);
        newTasks.add(t2);
        newTasks.add(t3);
        newTasks.add(t4);
        newTasks.add(t5);
        Test.startTest();
        insert newTasks;
        Test.stopTest();
        Contract__c contractAfter = [SELECT Id, Demand_Letter_Sent__c, Legal_Letter_Sent__c, NOD_Letter_Sent__c,
            No_More_Direct_Debits__c, RA_Issued__c FROM Contract__c WHERE Id = :contract.Id];
        System.assertEquals(Date.today(), contractAfter.Demand_Letter_Sent__c);
        System.assertEquals(Date.today(), contractAfter.Legal_Letter_Sent__c);
        System.assertEquals(Date.today(), contractAfter.NOD_Letter_Sent__c);
        System.assertEquals(Date.today(), contractAfter.No_More_Direct_Debits__c);
        System.assertEquals(Date.today(), contractAfter.RA_Issued__c);
    }
    @isTest
    static void messageCodes(){
        SL_SCTestData.createAccountAndContracts(23, 1);
        SL_MessageCodeHelper theHelper = new SL_MessageCodeHelper();
        List<Contract__c> contracts = SL_SCTestData.testContracts;
        List<String> callOutcomes = new List<String>{
            'Updated AR Address',
            'Updated Equipment Location',
            'Updated Corporate Address',
            'NOD Sent',
            'Call Back Requested',
            'Contact Out of Office',
            'Customer Will Call Back',
            'Emailed Sales',
            'Follow Up',
            'Phone Disconnection Requested',
            'Second Voice',
            'Virtual Call',
            'Payment Processed',
            'Phone Reconnection Requested',
            'Sales Issue',
            'Friday Direct Debit',
            'Friday Payment',
            'Pay by Phone',
            'Direct Debit Processed',
            'Requested Deferral',
            'Weather Related Deferral Approved',
            'Weather Related Deferral Requested'
        };
        List<Task> newTasks = new List<Task>();
        for(Integer i = 0; i < contracts.size() - 1; i++){
            Task t = new Task(Subject = 'Test Task ' + String.valueOf(i), Department__c = 'Collections', Primary_Call_Outcome__c = callOutcomes[i], isContractCallFollowup__c = true,
                // Followup_Date__c = theHelper.handleMessageCodes('Collections', callOutcomes[i]),
                whatId = contracts[i].Customer__c, Contract__c = contracts[i].Id, RecordTypeId = serviceRecordTypeId);
            newTasks.add(t);
        }
        Task taskForSystem = new Task(Subject = 'Test Task 15', Department__c = 'System', Primary_Call_Outcome__c = 'IVR Payment', isContractCallFollowup__c = true,
            whatId = contracts[22].Customer__c, Contract__c = contracts[22].Id, RecordTypeId = serviceRecordTypeId);
        newTasks.add(taskForSystem);
        Test.startTest();
        insert newTasks;
        Test.stopTest();
        List<Contract__c> contractsAfter = [SELECT Id, Customer__c, Followup_Date__c, Hold_from_Dialer_Until__c FROM Contract__c];
        // SL-1832 Misael Romero
        List<Integer> daysToAdd = new List<Integer> {1,1,1,1,1,1,1,1,1,1,1,1,2,2,2,2,2,4,4,5,5,5, 1};
        for(Integer i = 0; i < contractsAfter.size(); i++){
            System.debug('contractsAfter: ' + contractsAfter[i]);
            System.assertEquals(theHelper.addBussinessDaysV2(Date.today(), daysToAdd[i]), contractsAfter[i].Followup_Date__c, 'followup Date pushes according to the metadata');
            System.assertEquals(contractsAfter[i].Hold_from_Dialer_Until__c, contractsAfter[i].Followup_Date__c, 'hold from dialer needs to push alongside followup Date');
        }
    }
}