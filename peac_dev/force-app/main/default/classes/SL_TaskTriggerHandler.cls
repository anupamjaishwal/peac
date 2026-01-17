public without sharing class SL_TaskTriggerHandler extends SL_Trigger.baseHandler {
    Map<Id, Case> cases = new Map<Id, Case>();
    List<Case> casesToUpdate = new List<Case>();

    public override void beforeInsert(List<SObject> newList){
        List<Task> taskList = new List<Task>();
        for(SObject theObject :newList){
            getLookupMaps(theObject);
            taskList.add((Task)theObject);
        }
        getInfoFromOthers();
        beforeChangesToSelf(taskList,null);
    }

    public override void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){
        List<Task> taskList = new List<Task>();
        for(Id theId :newMap.keySet()){
            SObject theObject = newMap.get(theId);
            getLookupMaps(theObject);
            taskList.add((Task)theObject);
        }
        getInfoFromOthers();
        beforeChangesToSelf(taskList, oldMap);
    }

    private void beforeChangesToSelf(List<Task> newList, Map<Id,Sobject> oldMap){
        Boolean isNew = oldMap == null;
        for(Task t: newList){
            Case c = cases.get(t.whatId);            
            if(c != null){
                if(c.Initial_Response_SLA__c != t.Initial_Response_SLA__c){
                    t.Initial_Response_SLA__c = c.Initial_Response_SLA__c;
                }
                if(c.Response_Due__c != t.Response_Due__c){
                    t.Response_Due__c = c.Response_Due__c;
                }
                if(isNew && c.Initial_Response__c == null && c.contactId == t.whoId){
                    t.Initial_Response__c = DateTime.now();
                } else {
                    if(c.Initial_Response__c != null && c.Initial_Response__c != t.Initial_Response__c){
                        t.Initial_Response__c = c.Initial_Response__c;
                    }
                }
                if(isNew && c.Contract_Custom__c != null && t.Contract__c == null){
                    t.Contract__c = c.Contract_Custom__c;
                }
            }
            // SL-1832 Misael Romero newest update; SL-1895 updated to just update when IVR Payment is the Primary Call Outcome
            Task oldTask = (Task)oldMap?.get(t.Id);
            if(isNew || (t.Followup_Date__c == oldTask.Followup_Date__c 
            && (t.Department__c != oldTask.Department__c || t.Primary_Call_Outcome__c != oldTask.Primary_Call_Outcome__c))){
                if(t.Contract__c!=null){
                     SL_MessageCodeHelper msgCodeHelperCls = new SL_MessageCodeHelper();
                     Date nextFollowupDate = null;
                     nextFollowupDate = msgCodeHelperCls.handleMessageCodes(t.Department__c, t.Primary_Call_Outcome__c);
                     if(nextFollowupDate != null){
                         t.Followup_Date__c = nextFollowupDate;
                     }
             }
            }
        }
    }

    public override void afterInsert(Map<Id, SObject> newMap){
        for(SObject obj : newMap.values()){
            getLookupMaps(obj);
        }
        getInfoFromOthers();
        afterChangesToOthers(newMap, true);
    }
    public override void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap){}

    private void afterChangesToOthers(Map<Id, SObject> newMap, Boolean isNew){
        Map<Id, Contract__c> contractsToUpdate = new Map<Id, Contract__c>();
        Map<Id, Contract__c> contractsToFollowup = new Map<Id, Contract__c>();
        for(SObject theObject: newMap.values()){
            Task t = (Task)theObject;
            Case c = cases.get(t.whatId);            
            if(c != null && isNew && c.Initial_Response__c == null && c.contactId == t.whoId){
                c.Initial_Response__c = DateTime.now();
                this.casesToUpdate.add(c);
            }
            if(isNew && t.isContractCallFollowup__c){
                if(t.Contract__c != null){
                    Boolean willUpdate = false;
                    Date nextFollowupDate = null;

                    Contract__c thisContract = contractsToUpdate.get(t.Contract__c);
                    if(thisContract == null){
                        thisContract = new Contract__c();
                        thisContract.Id = t.Contract__c;
                    }
                    nextFollowupDate = t.Followup_Date__c;
                    if(nextFollowupDate != null){
                        thisContract.Followup_Date__c = nextFollowupDate;
                        thisContract.Hold_from_Dialer_Until__c = nextFollowupDate;
                        willUpdate = true;
                        Contract__c thisContract2 = contractsToFollowup.get(thisContract.Id);
                        if(thisContract2 == null){
                            thisContract2 = new Contract__c();
                            thisContract2.Id = thisContract.Id;
                        }
                        thisContract2.Customer__c = t.WhatId;
                        thisContract2.Followup_Date__c = nextFollowupDate;
                        thisContract2.Hold_from_Dialer_Until__c = nextFollowupDate;
                        contractsToFollowup.put(thisContract2.Customer__c, thisContract2);
                    }
                    switch on t.Primary_Call_Outcome__c {
                        when 'Demand Letter Sent'{
                            thisContract.Demand_Letter_Sent__c = Date.today();
                            willUpdate = true;
                        }
                        when 'Legal Letter Sent'{
                            thisContract.Legal_Letter_Sent__c = Date.today();
                            willUpdate = true;
                        }
                        when 'NOD Requested'{// SL-1832 Misael Romero
                            thisContract.NOD_Letter_Sent__c = Date.today();
                            willUpdate = true;
                        }
                        when 'Direct Debit Authorization Revoked'{
                            thisContract.No_More_Direct_Debits__c = Date.today();
                            willUpdate = true;
                        }
                        when 'RA Issued'{
                            thisContract.RA_Issued__c = Date.today();
                            willUpdate = true;
                        }
                    }
                    if(willUpdate){
                        contractsToUpdate.put(thisContract.Id, thisContract);
                    }
                }
            }
        }
        if(casesToUpdate.size() > 0){
            update casesToUpdate;
        }
        if(contractsToFollowup.values().size() > 0){
            List<Contract__c> affectedOnes = [SELECT Id, Customer__c FROM Contract__c WHERE 
                (NOT Status__c LIKE '%Disposed%') AND Customer__c IN : contractsToFollowup.keySet()];
            for(Contract__c contract : affectedOnes){
                Contract__c originalFollowup = contractsToFollowup.get(contract.Customer__c);
                if(contract.Id != originalFollowup.Id){
                    contract.Followup_Date__c = originalFollowup.Followup_Date__c;
                    contract.Hold_from_Dialer_Until__c = originalFollowup.Hold_from_Dialer_Until__c;
                    contractsToUpdate.put(contract.Id, contract);
                }
            }
        }
        if(contractsToUpdate.values().size() > 0){
            update contractsToUpdate.values();
        }
    }

    private void getLookupMaps(SObject obj){
        Task task = (Task)obj;
        if(task.whatId != null && task.whatId.getSObjectType().getDescribe().getName() == 'Case'){
            this.cases.put(task.whatId, new Case());
        }
    }
    
    private void getInfoFromOthers(){
        this.cases.putAll([SELECT Id, Initial_Response_SLA__c, Response_Due__c, Initial_Response__c, ContactId, Contract_Custom__c
            FROM Case WHERE Id IN : this.cases.keySet()]);
    }

}