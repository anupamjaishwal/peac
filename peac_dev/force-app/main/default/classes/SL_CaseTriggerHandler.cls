public with sharing class SL_CaseTriggerHandler extends SL_Trigger.baseHandler {
    Map<Id, Group> Queues = new Map<Id, Group>();
    Set<Id> caseIds = new Set<Id>();
    Map<Id, EmailMessage> emailMessages = new Map<Id, EmailMessage>();
    Map<Id, Contract__c> contracts = new Map<Id, Contract__c>();
    Map<Id, Map<Id, Task>> tasks = new Map<Id, Map<Id, Task>>();
    Set<Id> contractIds = new Set<Id>();
    Set<Id> accountIds = new Set<Id>();
    Map<Id, Id> primaryContacts = new Map<Id, Id>();
    Set<Id> casesChangedSourceId = new Set<Id>();
    Set<Id> casesWithInitialResponse = new Set<Id>();
    Set<Id> casesContractJustAdded = new Set<Id>();
    private Map<Id, List<String>> fieldsChangedById = new Map<Id, List<String>>();
    List<Task> tasksToUpdate = new List<Task>();
    
    public override void beforeInsert(List<SObject> newList){
        List<Case> caseList = new List<Case>();
        for(SObject theObject :newList){
            caseList.add((Case)theObject);
            getLookupMaps(theObject, true);
           }
        beforeChangesToSelf(caseList,null);
    }

    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        List<Case> caseList = new List<Case>();
        checkUpdatedFields(oldMap, newMap);
        for (Id caseId :newMap.keySet()){
            caseList.add((Case)newMap.get(caseId));
            getLookupMaps(newMap.get(caseId), false);
        }
        beforeChangesToSelf(caseList,oldMap);
    }
    

    private void beforeChangesToSelf(List<Case> newList,Map<Id,Sobject> oldMap){
        Boolean isNew = oldMap == null;
        //added by rsirivella on 31-01-2022
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Id businessHourId = [SELECT Id FROM BusinessHours WHERE IsDefault = true].id;
        Map<Id,String> groupMap = new Map<Id,String>();
        List<Group> grpList = [select Id,NAME,developerName from Group where Type = 'Queue'];
        for(Group p : grpList){
            groupMap.put(p.Id,p.Name);
        }
        //end

        //added by Jonathan Munguia - 07/29/24
        Set<String> setContractNumbers = new Set<String>();
        Map<String, Contract__c> mapContractsByName = new Map<String, Contract__c>();
        //end

        for (Case theCase :newList){
            Case oldCase = null;

            if(!isNew){
                oldCase = (Case)oldMap.get(theCase.Id);
            }

            if(theCase.OwnerId != null){
                this.Queues.put(theCase.OwnerId, new Group());
                if( groupMap.containsKey(theCase.OwnerId) && 
                  groupMap.get(theCase.OwnerId) == 'Insurance' && theCase.Origin<>'Web'){
                theCase.Type='Insurance';
            }
            else if( groupMap.containsKey(theCase.OwnerId) && 
                  groupMap.get(theCase.OwnerId) == 'Titled Vehicle'){
                theCase.Type='Titled Vehicle';
            }
            }
            if(theCase.SourceId != null){
                this.emailMessages.put(theCase.SourceId, new EmailMessage());
            }

            //added by Jonathan Munguia - 07/29/24
            if(isNew && theCase.Web_Contracts__c != null){ // from the site they send ccc not Contracts__c, we will check later if we are using Contracts__c somewhere else
                setContractNumbers.addAll(SL_CaseTriggerHelper.getContractNumber(theCase.Web_Contracts__c));
            }else if(!isNew && theCase.Web_Contracts__c != oldCase.Web_Contracts__c){
                setContractNumbers.addAll(SL_CaseTriggerHelper.getContractNumber(theCase.Web_Contracts__c));
            }
            //end
        }
        this.Queues.putAll([SELECT Id, DeveloperName FROM Group where Type = 'Queue' AND Id IN : this.Queues.keySet()]);
        getInfoFromOthers();
        //added by Jonathan Munguia - 07/29/24
        mapContractsByName = SL_CaseTriggerHelper.getRelatedContract(setContractNumbers);
        //end

        for (Case theCase :newList){
            List<String> fieldsChanged = fieldsChangedById.get(theCase.Id);
            if(isNew || this.casesChangedSourceId.contains(theCase.Id)){ // new or updated source email
                Group ownerQueue = this.Queues.get(theCase.OwnerId);
                EmailMessage sourceEmail = this.emailMessages.get(theCase.SourceId);
                String queueName = ownerQueue != null? ownerQueue.DeveloperName: '';
                String caseOrigin = theCase.Origin != null? theCase.Origin: '';
                String finalSubject = '';
                String body = '';
                if (sourceEmail == null){
                    finalSubject = theCase.Subject != null? theCase.Subject.toLowerCase(): '';
                    body = theCase.Description != null? theCase.Description.toLowerCase(): '';
                }else{
                    finalSubject = sourceEmail.Subject != null? sourceEmail.Subject.toLowerCase(): '';
                    body = sourceEmail.TextBody != null? sourceEmail.TextBody.toLowerCase(): '';
                }
                if((queueName == 'Partner' || queueName == 'Working_Capital')){
                    theCase.Initial_Response_SLA__c = 4;               
                }else if(queueName == 'All_Other' || queueName == 'Blind'
                    || queueName == 'End_of_Term' || queueName == 'File_Room'
                    || queueName == 'Insurance' || queueName == 'Internal_Servicing'
                    || queueName == 'Ops_Email_Box' || queueName == 'Titled_Vehicle'){
                    theCase.Initial_Response_SLA__c = 72;
                }else{
                    theCase.Initial_Response_SLA__c = 72;
                }
                if(theCase.ParentId == null){
                    String closedCaseNumber = '';
                    if(finalSubject.contains('new case email notification. case number ') || finalSubject.contains('case number ')){
                        closedCaseNumber = finalSubject.substringAfter(' case number ').trim();
                    }else{
                        if(body.contains('an email has been received for case ')){
                            closedCaseNumber = body.substringAfter('an email has been received for case ').left(8).trim();
                        }
                    }
                    if(closedCaseNumber.length() == 8 && theCase.CaseNumber != closedCaseNumber){
                        List<Case> existingCases = [SELECT Id, IsClosed, Status,
                            AccountId, Contract_custom__c, Reason, secondary_Reasons__c,
                            Comments, ContactId, Priority, SuppliedCompany, 
                            SuppliedEmail, SuppliedName, SuppliedPhone,
                            Web_Contracts__c FROM Case WHERE CaseNumber = :closedCaseNumber];
                        if(existingCases.size() == 1 && (existingCases[0].Status == 'Closed' || existingCases[0].IsClosed)){
                            Case closedCase = existingCases[0];
                            theCase.ParentId = closedCase.Id;
                            theCase.AccountId = closedCase.AccountId;
                            theCase.Contract_custom__c = closedCase.Contract_custom__c;
                            theCase.Reason = closedCase.Reason;
                            theCase.secondary_Reasons__c = closedCase.secondary_Reasons__c;
                            theCase.Comments = closedCase.Comments;
                            theCase.ContactId = closedCase.ContactId;
                            theCase.Priority = closedCase.Priority;
                            theCase.SuppliedCompany = closedCase.SuppliedCompany;
                            theCase.SuppliedEmail = closedCase.SuppliedEmail;
                            theCase.SuppliedName = closedCase.SuppliedName;
                            theCase.SuppliedPhone = closedCase.SuppliedPhone;
                            theCase.Web_Contracts__c = closedCase.Web_Contracts__c;
                        }
                    }
                }
            }
            Id contactId = theCase.Contract_custom__c != null? this.primaryContacts.get(theCase.Contract_custom__c):
                this.primaryContacts.get(theCase.AccountId);
            if(contactId != null && theCase.ContactId == null){
                theCase.ContactId = contactId;
            }
            
           Boolean isSameDayWithinBusinessHour =  BusinessDays.isWithin(System.now());
            Datetime currentTime ;
            if(theCase.CreatedDate == null){
                currentTime = System.now();
            }else{
                currentTime = theCase.CreatedDate;
            }
            Integer slaHours = Integer.valueOf(theCase.Initial_Response_SLA__c);
            if( slaHours == 4 || slaHours == 48 || slaHours == 72){
                if(slaHours == 48){
                    //slaHours = 18; // 48 was removed as per the business
                }else if(slaHours == 72){
                    slaHours = 27;
                }
                
                Datetime targetDT = BusinessHours.add(businessHourId,currentTime, slaHours* 60 * 60 * 1000L);
                theCase.Response_Due__c = targetDT;
            }
            //End by raja
            //added by Raja
            IF(oldMap != null && ((Case)oldMap.get(theCase.Id)).OwnerId != theCase.OwnerId ){
                if( groupMap.containsKey(theCase.OwnerId) && 
                    groupMap.get(theCase.OwnerId) == 'Insurance'&& theCase.Origin<>'Web'){
                    theCase.Type='Insurance';
                }
                else if( groupMap.containsKey(theCase.OwnerId) && 
                    groupMap.get(theCase.OwnerId) == 'Titled Vehicle'){
                    theCase.Type='Titled Vehicle';
                }
            }
            if(oldMap != null && ((Case)oldMap.get(theCase.Id)).Type != theCase.Type ) {
                List<Case> updateCase = new List<Case>();
                 Messaging.SingleEmailMessage CaseNotificationmail = new Messaging.SingleEmailMessage(); 
                
               // Map<Id,case> newCases = new Map<Id,Case>([Select Id, CaseNumber,Owner.Name, Escalated_Date_Time__c,IsEscalated, Type from Case where Id IN :newMap.keySet()]);
                 //EmailTemplate emailTemplate_insurance = [SELECT Id, Subject, HtmlValue, Body FROM EmailTemplate WHERE DeveloperName = 'Insurance_Escalation_and_Customer_Service_Escalation'];
        
                if(theCase.IsEscalated){
                     theCase.Escalated_Date_Time__c = system.now();
                        
                     SL_Email_Addresses__c toAddress_str = SL_Email_Addresses__c.getValues('Insurance_TitleVehicle');
                    List<String> toAddress ;
                    if((toAddress_str.TypeEmailAddress__c).contains(',')){
                     toAddress = (toAddress_str.TypeEmailAddress__c).split(',');
                    }
                    else{
                        toAddress = new List<String>{toAddress_str.TypeEmailAddress__c};
                    }
                
                    SL_Email_Addresses__c toAddress_str1 = SL_Email_Addresses__c.getValues('OtherTypes');
                    List<String> toAddress1;
                    if((toAddress_str.TypeEmailAddress__c).contains(',')){
                        toAddress1 = (toAddress_str1.TypeEmailAddress__c).split(',');
                    }else{
                        toAddress1 = new List<String>{toAddress_str1.TypeEmailAddress__c};
                    }
                //get custom setting --> split','
                //CaseNotificationmail.setToAddresses(toAddress);
                    if(theCase.Type == 'Titled Vehicle' || theCase.Type == 'Insurance'){
                    mails.add(sendEmailAlert(toAddress,theCase)); 
                    }
                    else{
                        mails.add(sendEmailAlert(toAddress1,theCase));
                    }
           
                }
            Messaging.sendEmail(mails);
            //end by Raja   
            }
            setAccountId(isNew, theCase);
            acceptWorkInOmniChannel(isNew, fieldsChanged, theCase);

            //added by Jonathan Munguia - 07/29/24
            if(isNew){
                SL_CaseTriggerHelper.setXBSValue(theCase, mapContractsByName);
            }else if(!isNew && theCase.Web_Contracts__c != ((Case)oldMap.get(theCase.Id)).Web_Contracts__c){
                SL_CaseTriggerHelper.setXBSValue(theCase, mapContractsByName);
            }
            //end
            setXBS(theCase);
            //Logic for SL-2825
            if(oldMap != null && ((Case)oldMap.get(theCase.Id)).Status != theCase.Status  && theCase.Status == 'Closed' && theCase.Closed_By__c == null ){
                theCase.Closed_By__c=UserInfo.getUserId();
            }
        }
    }

    public Messaging.SingleEmailMessage sendEmailAlert(List<String> toAddress, case theCase){
        //List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage CaseNotificationmail = new Messaging.SingleEmailMessage(); 
        CaseNotificationmail.setReplyTo('customerservice@peacsolutions.com');
        CaseNotificationmail.setSenderDisplayName('Customer Service');  
        CaseNotificationmail.setSubject(theCase.CaseNumber+' has been escalated');
        String Recordlink = URL.getOrgDomainUrl().toExternalForm()+'/'+theCase.Id;
        CaseNotificationmail.setHtmlBody(
                                   	'Case ' + theCase.CaseNumber +' has been escalated'+' <a href='+Recordlink+'>'+theCase.CaseNumber+'</a><br/>'+
                                    //'type= '+theCase.Type+'<br/>'+
                                 	'Name of the rep = '+UserInfo.getFirstName()+' '+UserInfo.getLastName()+'<br/>'+
                                 	'Escalated DateTime= '+theCase.Escalated_Date_Time__c+'<br/>'
                                 	//'Case isEscalaed= '+theCase.IsEscalated+'<br/>'
            ); 
        CaseNotificationmail.setToAddresses(toAddress);
        
                return CaseNotificationmail;
    }
    public override void afterInsert(Map<Id, SObject> newMap){
        for(SObject obj : newMap.values()){
            getLookupMaps(obj, true);
        }
        getInfoFromOthers();
        afterChangesToOthers(null, newMap);
    }
    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        for(SObject obj : newMap.values()){
            getLookupMaps(obj, false);
        }
        getInfoFromOthers();
        checkUpdatedFields(oldMap, newMap);
        afterChangesToOthers(oldMap, newMap);
        //Case Response time on case closed
        PEAC_EmailMessageTriggerHelper.updateResponseTimeOnCaseClose(oldMap, newMap);
    }

    private void afterChangesToOthers(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        Boolean isNew = oldMap == null;
        // Map<Id, AgentWork> agentWorkToInsertById = new Map<Id, AgentWork>();
        for(Id caseId :newMap.keySet()){
            Case theCase = (Case)newMap.get(caseId);
            Case oldCase = isNew? null: (Case)oldMap.get(caseId);
            if((isNew && theCase.Initial_Response__c != null) || casesWithInitialResponse.contains(caseId)){
                for(Task childTask : tasks.get(caseId).values()){
                    if(childTask.Initial_Response__c == null){
                        childTask.Initial_Response__c = theCase.Initial_Response__c;
                        tasksToUpdate.add(childTask);
                    }
                }
            }
            if(isNew && theCase.Origin=='Web'){
                activateAutoResponse(theCase.Id);
            }
            List<String> fieldsChanged = fieldsChangedById.get(caseId);
            // just change the name of the below function and use it as you see fit, didn't remove just to have the placeholder
            // someWorkOnRelatedRecord(isNew, fieldsChanged, theCase, oldCase, agentWorkToInsertById);
        }
        if(tasksToUpdate.size() > 0){
            SL_UpdateTasks.updateTasks(tasksToUpdate);
        }
        // if(agentWorkToInsertById.values().size() > 0){
        //     //insert agentWorkToInsertById.values();
        // }
    }

    private void checkUpdatedFields(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<String> fieldsToCheck = new List<String>{'OwnerId', 'Web_Contracts__c'};
        for(Id caseId :newMap.keySet()){
            Case theCase = (Case)newMap.get(caseId);
            Case oldCase = (Case)oldMap.get(caseId);
            if(theCase.SourceId != null && theCase.SourceId != oldCase.SourceId){
                this.casesChangedSourceId.add(caseId);
            }
            if(theCase.Initial_Response__c != null && theCase.Initial_Response__c != oldCase.Initial_Response__c){
                this.casesWithInitialResponse.add(caseId);
            }
            if(theCase.Contract_custom__c != null && oldCase.Contract_custom__c == null){
                this.casesContractJustAdded.add(caseId);
            }
            SL_TriggerUtil.findChangedFields(caseId, theCase, oldCase, fieldsChangedById, fieldsToCheck);
        }
    }

    private void getLookupMaps(SObject obj, Boolean isNew){
        Case theCase = (Case)obj;
        if(theCase.SourceId != null){
            this.emailMessages.put(theCase.SourceId, new EmailMessage());
        }
        if(theCase.Id != null){
            this.caseIds.add(theCase.Id);
            this.tasks.put(theCase.Id, new Map<Id, Task>());
        }
        if(theCase.Contract_custom__c != null){
            this.contractIds.add(theCase.Contract_custom__c);
            this.contracts.put(theCase.Contract_custom__c, new Contract__c());
        }else {
            if(isNew && theCase.AccountId != null){
                this.accountIds.add(theCase.AccountId);
            }
        }
    }

    private void getInfoFromOthers(){
        if(caseIds.size() > 0){
            for(Case related : [SELECT Id, Contract_custom__r.Customer__c, SourceId,
                (SELECT Id, Initial_Response_SLA__c, Response_Due__c, Initial_Response__c, WhatId FROM Tasks)
                FROM Case WHERE Id IN: caseIds
                ]){
                if(this.contracts.get(related.Contract_custom__c) != null){
                    this.contracts.put(related.Contract_custom__c, related.Contract_custom__r);
                }
                
                // List<Task> relatedTasks = new List<Task>();
                // for(Task taskWithInfo : [SELECT Id, Initial_Response_SLA__c, Response_Due__c, Initial_Response__c, WhatId FROM Task WHERE whatId IN :tasks.keySet()]){
                //     tasks.put(taskWithInfo.Id, taskWithInfo);
                // }
                
            }
            
        }
        if(Trigger.isBefore && this.contracts.size() > 0 && SL_TriggerUtil.checkForMissingInfo(this.contracts.values())){
            this.contracts.putAll([SELECT Id, Customer__c FROM Contract__c WHERE Id IN :this.contracts.keySet()]);
        }
        if(this.emailMessages.size() > 0){
            this.emailMessages.putAll([SELECT Id, ToAddress, Subject, TextBody, ParentId FROM EmailMessage where Id IN : this.emailMessages.keySet()]);
        }
        if(this.tasks.size() > 0){
            for(Task theTask : [SELECT Id, Initial_Response_SLA__c, Response_Due__c, Initial_Response__c, WhatId FROM Task WHERE whatId IN :tasks.keySet()]){
                tasks.get(theTask.WhatId).put(theTask.Id, theTask);
            }
        }
        if(this.contractIds.size() > 0){
            for(Contract_Contact_Role__c ccr :[SELECT Id, Contract__c, Contact__c FROM Contract_Contact_Role__c 
                WHERE Role__c ='Primary Contact' AND Contract__c IN :this.contractIds
                ORDER BY Contract__c, Name DESC]){
                this.primaryContacts.put(ccr.Contract__c, ccr.Contact__c);
            }
        }
        if(this.accountIds.size() > 0){
            for(AccountContactRelation acr :[SELECT Id, AccountId, ContactId FROM AccountContactRelation 
                WHERE Roles INCLUDES('Primary Contact') AND AccountId IN :this.accountIds
                ORDER BY AccountId, LastModifiedDate DESC]){
                this.primaryContacts.put(acr.AccountId, acr.ContactId);
            }
        }
    }

    private void setAccountId(Boolean isNew, Case theCase){
        if((isNew && theCase.Contract_Custom__c != null) || this.casesContractJustAdded.contains(theCase.Id)){
            Contract__c contract = this.contracts.get(theCase.Contract_Custom__c);
            if(contract != null && contract.Customer__c != null){
                theCase.AccountId = contract.Customer__c;
            }
        }
    }
    
    private void acceptWorkInOmniChannel(Boolean isNew, List<String> fieldsChanged, Case theCase){
        List<String> omniChannelOpenStages = new List<String>{'New', 'On Hold', 'Escalated'};
        if(!isNew && fieldsChanged != null && fieldsChanged.contains('OwnerId') 
            && theCase.OwnerId == System.UserInfo.getUserId() && omniChannelOpenStages.contains(theCase.Status)){
            theCase.Status = 'In Progress';
        }
    }

    private void setXBS(Case theCase){
        if(theCase.Origin != null && theCase.Origin.contains('XBS')){
            theCase.XBS__c = true;
        }
    }
    
    private static void activateAutoResponse(String WebcaseId){
        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerAutoResponseEmail = true;
        Case webCase = new Case();
        webCase.Id = WebcaseId;
        webCase.Comments__c = '.';
        dlo.EmailHeader.triggerAutoResponseEmail = true;
        database.update(webCase,dlo);
    }
}