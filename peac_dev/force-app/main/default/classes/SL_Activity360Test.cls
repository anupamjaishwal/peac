@isTest
public with sharing class SL_Activity360Test {
    @isTest
    static void getAllActivities() {
        SL_SCTestData.createAccountAndContracts(1, 2);
        Account customer = [SELECT Id FROM Account];
        List<Contract__c> contracts = [SELECT Id, Customer__c FROM Contract__c];
        List<Case> cases = new List<Case>{
            new Case(Subject = 'test 1', Description = 'test case with accountId', AccountId = customer.Id),
            new Case(Subject = 'test 2', Description = 'test case without AccountId', Contract_custom__c = contracts[1].Id),
            new Case(Subject = 'test 2', Description = 'test case without Account at all')
        };
        insert cases;
        List<Task> tasks = new List<Task>{
            new Task(Subject = 'Test Task 1', Department__c = 'Collections', Primary_Call_Outcome__c = 'Demand Letter Sent', isContractCallFollowup__c = true,
                whatId = contracts[0].Customer__c, Contract__c = contracts[0].Id, Type = 'Call', ActivityDate = Date.today()),
            new Task(Subject = 'Test Task 2', Department__c = 'Collections', Primary_Call_Outcome__c = 'Demand Letter Sent',
                whatId = customer.Id, ActivityDate = Date.today()),
            new Task(Subject = 'Test Task 3', Department__c = 'Collections', Primary_Call_Outcome__c = 'Demand Letter Sent',
                whatId = cases[0].Id, ActivityDate = Date.today())
        };
        insert tasks;
        Test.startTest();
        EmailMessage email = new EmailMessage(ToAddress = 'yet.another.email@address.com', 
            Subject = 'test', TextBody = 'body with ach test. ', RelatedToId = contracts[1].Id);
        insert email;
        Event loneEvent = new Event(ActivityDate = Date.today() , Subject = 'test event', 
            ActivityDateTime = DateTime.now(), DurationInMinutes = 60, WhatId = customer.Id);
        insert loneEvent;
        CaseComment loneComment = new CaseComment(CommentBody = 'test comment for second Case', ParentId = cases[1].Id);
        insert loneComment;
        String result1 = '', result2 = '', result3 = '', errorResult = '';
        
        result1 = SL_Activity360.hubExecute('getAllActivities', new List<String>{String.valueOf(customer.Id)});
        result2 = SL_Activity360.hubExecute('getAllActivities', new List<String>{String.valueOf(contracts[0].Id)});
        result3 = SL_Activity360.hubExecute('getAllActivities', new List<String>{String.valueOf(cases[0].Id)});
        errorResult = SL_Activity360.hubExecute('getAllActivities', new List<String>{String.valueOf(cases[2].Id)});
        Test.stopTest();
        System.assertEquals(6, result1.countMatches('"id":'));
        System.assertEquals(6, result2.countMatches('"id":'));
        System.assertEquals(6, result3.countMatches('"id":'));
        System.assert(errorResult.contains('"error": '));
    }
}