public with sharing class SL_Activity360 {
    @AuraEnabled
    public static string hubExecute(String methodName, List<String> methodParameters){
        try {
            String result = '';
            switch on methodName {
                when 'getAllActivities'{
                    result = getAllActivities(methodParameters[0]);
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @testVisible
    static String getAllActivities(String recordId){
        String result = '';
        String objectName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        Id customerId = null;
        switch on objectName {
            when 'Contract__c'{
                customerId = [SELECT Customer__c FROM Contract__c WHERE Id = :recordId].Customer__c;
            }
            when 'Account'{
                customerId = (Id)recordId;
            }
            when 'Case'{
                Case theCase = [SELECT AccountId, Contract_custom__r.Customer__c FROM Case WHERE Id = :recordId];
                customerId = theCase.AccountId != null? theCase.AccountId: theCase.Contract_custom__r.Customer__c;
            }
        }
        if(customerId != null){
            Map<Id, Task> allTasks = new Map<Id, task>();
            List<EmailMessage> emails = new List<EmailMessage>();
            List<Event> allEvents = new List<Event>();
            Set<Id> taskWhatIds = new Set<Id>();
            Map<Id, EmailMessage> emailTasks = new Map<Id, EmailMessage>();
            Set<Id> eventWhatIds = new Set<Id>();
            List<ActivityWrapper> recordList = new List<ActivityWrapper>();
            String orgUrl = URL.getSalesforceBaseUrl().toExternalForm();
            taskWhatIds.add(customerId);
            eventWhatIds.add(customerId);
            Map<Id, Contract__c> contracts = new Map<Id, Contract__c>();
            contracts.putAll([SELECT Id, Customer__c FROM Contract__c WHERE Customer__c = :customerId]);
            eventWhatIds.addAll(contracts.keySet());
            Map<Id, Case> cases = new Map<Id, Case>();
            cases.putAll([SELECT Id, AccountId, Contract_custom__r.Customer__c FROM Case WHERE AccountId = :customerId OR (AccountId = null AND Contract_custom__r.Customer__c = :customerId)]);
            taskWhatIds.addAll(cases.keySet());
            eventWhatIds.addAll(cases.keySet());
            allTasks.putAll([SELECT Id, CompletedDateTime, ActivityDate, Type, Description, Owner.Name,
                Activity__c, Primary_Call_Outcome__c, WhatId, What.Name, Contract__c, Contract__r.Name FROM Task WHERE WhatId IN :taskWhatIds]);
            emails.addAll([SELECT Id, ActivityId, TextBody FROM EmailMessage where ActivityId IN :allTasks.keySet()]);
            for(Id taskId :allTasks.keySet()){
                for(Integer i = 0; i < emails.size(); i++){
                    if(emails[i].ActivityId == taskId){
                        emailTasks.put(taskId, emails[i]);
                        break;
                    }
                }
            }
            allEvents.addAll([SELECT Id, ActivityDate, Type, Description, Owner.Name, Activity__c, Primary_Call_Outcome__c, WhatId, What.Name FROM Event WHERE WhatId IN :eventWhatIds]);
            List<CaseComment> comments = [SELECT Id, CommentBody, CreatedDate, CreatedBy.Name, Parent.Reason, Parent.Closed_Reason__c, ParentId, Parent.CaseNumber FROM CaseComment WHERE ParentId IN :cases.keySet()];
            for(Task theTask :allTasks.values()){
                Datetime TaskDatetime = theTask.CompletedDateTime != null? 
                    theTask.CompletedDateTime: 
                    theTask.ActivityDate != null? Datetime.newInstance(theTask.ActivityDate.year(), theTask.ActivityDate.month(), theTask.ActivityDate.day(), 11, 59, 59):
                    null;
                String taskType = emailTasks.get(theTask.Id) != null? 'Email': theTask.Type;
                String taskDescription = emailTasks.get(theTask.Id) != null? emailTasks.get(theTask.Id).TextBody: theTask.Description;
                String taskParentId = theTask.Contract__c == null? theTask.WhatId: theTask.Contract__c;
                String taskParentName = theTask.Contract__c == null? theTask.What.Name: theTask.Contract__r.Name;
                recordList.add(new ActivityWrapper(theTask.Id,
                    TaskDatetime,
                    taskType,
                    orgUrl + '/' + theTask.Id,
                    taskDescription,
                    theTask.Owner.Name,
                    theTask.Activity__c,
                    theTask.Primary_Call_Outcome__c,
                    '',
                    '',
                    orgUrl + '/' + taskParentId,
                    taskParentName));
            }
            for(Event theEvent :allEvents){
                recordList.add(new ActivityWrapper(theEvent.Id,
                    Datetime.newInstance(theEvent.ActivityDate.year(), theEvent.ActivityDate.month(), theEvent.ActivityDate.day(), 11, 59, 59),
                    'Event',
                    orgUrl + '/' + theEvent.Id,
                    theEvent.Description,
                    theEvent.Owner.Name,
                    theEvent.Activity__c,
                    theEvent.Primary_Call_Outcome__c,
                    '',
                    '',
                    orgUrl + '/' + theEvent.WhatId,
                    theEvent.What.Name));
            }
            for(CaseComment comment :comments){
                recordList.add(new ActivityWrapper(comment.Id,
                    comment.CreatedDate,
                    'Case Comment',
                    orgUrl + '/' + comment.ParentId,
                    comment.CommentBody,
                    comment.CreatedBy.Name,
                    '',
                    '',
                    comment.Parent.Reason,
                    comment.Parent.Closed_Reason__c,
                    orgUrl + '/' + comment.ParentId,
                    comment.Parent.CaseNumber));
            }
            result = '{"data": ' + JSON.serialize(recordList, true) + '}';
        }else{
            result = '{"error": "No valid Customer(Account) found."}';
        }
        return result;
    }

    class ActivityWrapper{
        Id id;
        Datetime activityDate;
        String type;
        String recordUrl;
        String description;
        String owner;
        String activity;
        String primaryCallOutcome;
        String caseReason;
        String closedReason;
        String parentUrl;
        String parentName;

        public ActivityWrapper(Id id, Datetime activityDate, String type, String recordUrl, String description, String owner, String activity, String primaryCallOutcome, String caseReason, String closedReason, String parentUrl, String parentName){
            this.id = id;
            this.activityDate = activityDate;
            this.type = type;
            this.recordUrl = recordUrl;
            this.description = description;
            this.owner = owner;
            this.activity = activity;
            this.primaryCallOutcome = primaryCallOutcome;
            this.caseReason = caseReason;
            this.closedReason = closedReason;
            this.parentUrl = parentUrl;
            this.parentName = parentName;
        }
    }
}