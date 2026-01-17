public with sharing class SL_EmailMessageTriggerHandler extends SL_Trigger.baseHandler {
    private Map<Id, Case> parentCases     = new Map<Id, Case>();
    private Map<Id, Contract__c> contracts = new Map<Id, Contract__c>();
    private Map<String, Group> queuesByDevName = new Map<String, Group>();
    private Map<String, List<EmailMessage>> emailsByMsgIdentifier = new Map<String, List<EmailMessage>>();
    private Map<Id, List<String>> emailAddresByCase = new Map<Id, List<String>>();
    private final String SENDER_NOTIFICATION_ON_REPLY = System.Label.SL_CaseReplyNotificationOrgWideEmailAddress;
    private Id ON_REPLY_ORG_ADDRESS_ID;

    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        List<EmailMessage> emailList = new List<EmailMessage>();
        for (SObject obj : newMap.values()) {
            getLookupMaps(obj);
            emailList.add((EmailMessage)obj);
        }
        beforeChangesToSelf(oldMap, emailList, false);
    }

    public override void beforeInsert(List<SObject> newList) {
        List<EmailMessage> emailList = new List<EmailMessage>();
        for (SObject obj : newList) {
            getLookupMaps(obj);
            emailList.add((EmailMessage)obj);
        }
        beforeChangesToSelf(new Map<Id, SObject>(), emailList, true);
    }

    public override void afterInsert(Map<Id, SObject> newMap) {
        for (SObject obj : newMap.values()) {
            getLookupMaps(obj);
        }
        getInfoFromOthers();

        List<Task> tasksToReparent = new List<Task>();
        List<Id> toProcess = new List<Id>();
        List<Messaging.SingleEmailMessage> messageNotificationOnReplyLst = new List<Messaging.SingleEmailMessage>();
        for (SObject obj : newMap.values()) {
            EmailMessage email = (EmailMessage)obj;
            Case parentCase = this.parentCases.get(email.ParentId);
            afterChangesToOthers(obj, true);
            if (email.RelatedToId != null 
                && email.RelatedToId.getSObjectType().getDescribe().getName() == 'Contract__c') {
                tasksToReparent.add(new Task(
                    Id          = email.ActivityId,
                    Contract__c = email.RelatedToId,
                    WhatId      = contracts.get(email.RelatedToId).Customer__c
                ));
            }
            if (email.isMessageToProcess__c 
            && !TC_RecursiveTriggerHelper.emailsAlreadyRoutingProcessed.contains(email.Id)){
                TC_RecursiveTriggerHelper.emailsAlreadyRoutingProcessed.add(email.Id);
                Boolean isMsgProcessing = false;
                if(parentCase == null || parentCase.SourceId != null 
                || (parentCase.SourceId == null && parentCase.ContactEmail != null)){
                    List<EmailMessage> othersSameMessage = emailsByMsgIdentifier.get(email.MessageIdentifier) ?? new List<EmailMessage>();
                    for(EmailMessage otherEmail:othersSameMessage){
                        if(email.Id != otherEmail.Id && otherEmail.isMessageToProcess__c){
                            isMsgProcessing = true;
                            break;
                        }
                    }
                }
                if(!isMsgProcessing){
                    toProcess.add(email.Id);
                }
            }

            //SL-2828
            Boolean isRepliedOnOpen =  email.Incoming && parentCase?.EmailMessages?.size() > 1;
            Boolean isRepliedOnClosed = email.Cloned_From__c != null;
            Boolean hasAddresses = parentCase != null && emailAddresByCase.containsKey(parentCase.Id) && !emailAddresByCase.get(parentCase.Id).isEmpty();
            if (hasAddresses && !parentCase.isClosed && (isRepliedOnOpen || isRepliedOnClosed)) {
                messageNotificationOnReplyLst.add(setNotificationOpenCaseReplies(parentCase, emailAddresByCase.get(parentCase.Id)));
            }
        }
        if (!tasksToReparent.isEmpty()) {
            update tasksToReparent;
        }

        PEAC_EmailMessageTriggerHelper.calculateIntialResporseDate((Map<Id, EmailMessage>) newMap);

        if (!toProcess.isEmpty()) {
            System.enqueueJob(new SL_EmailRoutingProcessor(toProcess, 'triggered'));
        }

        if (!messageNotificationOnReplyLst.isEmpty()) {
            Messaging.sendEmail(messageNotificationOnReplyLst);
        }
    }

    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        // No-op
    }

    private void getLookupMaps(SObject obj) {
        EmailMessage email = (EmailMessage)obj;
        if (email.ParentId != null) {
            this.parentCases.put(email.ParentId, new Case());
        }
        if (email.RelatedToId != null 
            && email.RelatedToId.getSObjectType().getDescribe().getName() == 'Contract__c') {
            this.contracts.put(email.RelatedToId, new Contract__c());
        }
        if(email.MessageIdentifier != null){
            this.emailsByMsgIdentifier.put(email.MessageIdentifier, new List<EmailMessage>());
        }
    }

    private void getInfoFromOthers() {
        this.parentCases.putAll([
            SELECT Id, IsClosed, Status, OwnerId, SourceId, ContactEmail, CaseNumber, Owner.Email, 
                (SELECT Id FROM EmailMessages WHERE Incoming = true LIMIT 2)
            FROM Case
            WHERE Id IN :this.parentCases.keySet()
        ]);
        this.contracts.putAll([
            SELECT Id, Customer__c
            FROM Contract__c
            WHERE Id IN :this.contracts.keySet()
        ]);
        for (Group q : [
            SELECT Id, DeveloperName 
              FROM Group 
             WHERE Type = 'Queue'
        ]) {
            this.queuesByDevName.put(q.DeveloperName, q);
        }
        if(Trigger.isAfter){
            for(EmailMessage email :[SELECT Id, MessageIdentifier, isMessageToProcess__c 
            FROM EmailMessage WHERE MessageIdentifier IN :this.emailsByMsgIdentifier.keySet()]){
                this.emailsByMsgIdentifier.get(email.MessageIdentifier).add(email);
            }

            //SL-28282
            Map<Id, Id> groupByCaseMap = new Map<Id, Id>();
            for (Case caseRec :this.parentCases.values()) {
                if (caseRec.ownerId.getSobjectType() == User.getSobjectType()) {
                    if (!this.emailAddresByCase.containsKey(caseRec.Id)) {
                        this.emailAddresByCase.put(caseRec.Id, new List<String>());
                    }
                    if (caseRec.Owner.email == null) {
                        continue;
                    }
                    this.emailAddresByCase.get(caseRec.Id).add(caseRec.Owner.email);
                    continue;
                }
                groupByCaseMap.put(caseRec.OwnerId, caseRec.Id);
            }

            if (!groupByCaseMap.isEmpty()) {
                for (GroupMember gm : [SELECT GroupId, UserOrGroup.email FROM GroupMember WHERE GroupId IN :groupByCaseMap.KeySet()]) {
                    Id caseId = groupByCaseMap.get(gm.GroupId);
                    if (!this.emailAddresByCase.containsKey(caseId)) {
                        this.emailAddresByCase.put(caseId, new List<String>());
                    }
                    
                    if (gm.UserOrGroup.email == null) {
                        continue;
                    }
                    this.emailAddresByCase.get(caseId).add(gm.UserOrGroup.email);
                    continue;
                }
            }

            this.ON_REPLY_ORG_ADDRESS_ID = [SELECT Id FROM OrgWideEmailAddress WHERE Address =:SENDER_NOTIFICATION_ON_REPLY].Id;
        }
    }

    private void beforeChangesToSelf(Map<Id, SObject> oldMap, List<EmailMessage> newList, Boolean isNew){
        getInfoFromOthers();
        for (EmailMessage email : newList) {
            Id contractId = null;
            Case parentCase = this.parentCases.get(email.ParentId);
            if (email.RelatedToId != null) {
                String sObj = email.RelatedToId.getSObjectType().getDescribe().getName();
                if (sObj == 'Contract__c') {
                    contractId = email.RelatedToId;
                } else if (sObj == 'Case') {
                    Case cur = [
                        SELECT Contract_custom__c
                          FROM Case
                         WHERE Id = :email.RelatedToId
                         LIMIT 1
                    ];
                    if (cur.Contract_custom__c != null) {
                        contractId = cur.Contract_custom__c;
                    }
                }
            }
            if (contractId != null && !email.Incoming) {
                Contract__c ctr = [ SELECT Name, Is_Blind__c, IsXBS__c
                    FROM Contract__c WHERE Id = :contractId LIMIT 1];
                String err;
                if (!ctr.IsXBS__c) {
                    err = ctr.Is_Blind__c
                        ? 'Contract ' + ctr.Name + ' is a Blind contract. Please send from either an @lease-services.com or @leaseservices.com email address.'
                        : 'Contract ' + ctr.Name + ' is not Blind. Please use @peacsolutions.';
                } else {
                    err = 'Contract ' + ctr.Name + ' is XBS. Please use an XFS address.';
                }
                String senderAddress = email.FromAddress ?? email.ValidatedFromAddress;
                if(senderAddress != null){
                    senderAddress = senderAddress.toLowerCase();
                    if ((ctr.IsXBS__c && !senderAddress.contains('xfs'))
                    || (!ctr.IsXBS__c 
                    && ((ctr.Is_Blind__c && ((!senderAddress.contains('@lease-services.com') && !senderAddress.contains('@leaseservices.com'))
                    || senderAddress.contains('xfs')))
                    || (!ctr.Is_Blind__c && !senderAddress.contains('@peacsolutions.com'))))) {
                    email.addError(err);
                }
            }
                
            }
            if (isNew && parentCase != null && email.Cloned_FromMsg__c == null && email.Incoming){
                email.isMessageToProcess__c = true;
            }
        }
    }

    private void afterChangesToOthers(SObject obj, Boolean isNew) {
        // No-op
    }

    private Messaging.SingleEmailMessage setNotificationOpenCaseReplies(Case caseRec, List<String> toAddress) {
        Messaging.SingleEmailMessage emailNotification = new Messaging.SingleEmailMessage(); 
        emailNotification.setOrgWideEmailAddressId(this.ON_REPLY_ORG_ADDRESS_ID);
        emailNotification.setSubject('New case email notification. Case number ' + caseRec.CaseNumber);
        String Recordlink = URL.getOrgDomainUrl().toExternalForm()+'/'+caseRec.Id;
        emailNotification.setHtmlBody(
            'Case Number <a href=' + Recordlink + '>' + caseRec.CaseNumber + '</a> received an email. Click the link to review and respond.<br/>' 
        ); 
        emailNotification.setToAddresses(toAddress);
        
        return emailNotification;
    }
}