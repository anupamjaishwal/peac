public class SL_CollectionAssignmentBatch implements Database.Batchable<SObject>, Database.Stateful {
    Set<Id> accountIds;
    private Map<String, String> queueApiNames;
    private Map<String, Map<String, Integer>> collectionGroups;
    Map<String, List<RR_Assignee__mdt>> collectionAgents;
    Map<Id, RR_Assignee__mdt> agentsAssigned;
    Boolean isFirstAssignment;
    Id workingCL;
    Id endUserId;
    String allErrors;
    public class tooManyQueriesException extends Exception {}

    public SL_CollectionAssignmentBatch(){
        initializeVariables(new Map<String, List<RR_Assignee__mdt>>(), false);
    }
    public SL_CollectionAssignmentBatch(Map<String, List<RR_Assignee__mdt>> testAgents){
        initializeVariables(testAgents, false);
    }
    public SL_CollectionAssignmentBatch(Boolean isFirstDataLoad){
        initializeVariables(new Map<String, List<RR_Assignee__mdt>>(), isFirstDataLoad);
    }

    private void initializeVariables(Map<String, List<RR_Assignee__mdt>> testAgents, Boolean isFirstDataLoad){
        accountIds = new Set<Id>();
        queueApiNames = new Map<String, String>();
        collectionGroups = new Map<String, Map<String, Integer>>();
        collectionAgents = new Map<String, List<RR_Assignee__mdt>>();
        agentsAssigned = new Map<Id, RR_Assignee__mdt>();
        allErrors = '';
        workingCL = Schema.SObjectType.Contract__c.getRecordTypeInfosByDeveloperName().get('Working_Capital_Loan').getRecordTypeId();
        endUserId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User Account').getRecordTypeId();
        isFirstAssignment = isFirstDataLoad;
        List<Group> contractQueues = [SELECT Name, DeveloperName FROM Group WHERE Type='Queue'];
        for(Group contractQueue : contractQueues){
            queueApiNames.put(contractQueue.Name, contractQueue.DeveloperName);
            if(Test.isRunningTest() && testAgents.get(contractQueue.DeveloperName) != null && testAgents.get(contractQueue.DeveloperName).size() > 0){
                collectionAgents.put(contractQueue.DeveloperName, testAgents.get(contractQueue.DeveloperName));
            }else{
                if(Test.isRunningTest() && testAgents.values().size() == 0){
                    collectionAgents.put(contractQueue.DeveloperName, new List<RR_Assignee__mdt>());
                }else{
                    collectionAgents.put(contractQueue.DeveloperName, [SELECT Id, Name__c, Is_Active__c, User__c, Last_Assigned__c, RR_Queue__c 
                        FROM RR_Assignee__mdt WHERE Is_Active__c = true AND RR_Queue__r.Name__c= :contractQueue.DeveloperName
                        ORDER BY Last_Assigned__c]);
                }
            }
        }
    }

    public Database.querylocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Customer__c, Customer__r.Collection_Group__c, Customer__r.XBS_Collection_Group__c ,Customer__r.XBS_Highest_Delinquency_Contract__c , Customer__r.Account_Total_Active_Contracts__c, '+ // Customer__r.Multiples__c, // SL-2805 Misael Romero
            'Delinquency_Status_Code__c, Status__c, Id, Collection_Group__c, RecordTypeId, Agent_Lock__c, Customer__r.RecordTypeId, '+
            'Customer__r.Highest_Delinquency_Contract__c, Customer__r.Collection_Agent__c,Customer__r.XBS_Collection_Agent__c, IsXBS__c, Lessor_Code__c '+
            'FROM Contract__c WHERE Customer__c != null AND (NOT Status__c LIKE \'%Disposed%\')'+ 
            'ORDER BY Customer__c, Delinquency_Status_Code__c DESC, Contract_Balance_Remaining__c DESC');
    }
    public void execute(Database.BatchableContext BC, List<SObject> scope){
        try{

            Map<Id, Account> accountsToChangeGroup = new Map<Id,Account>();
            List<Contract__c> workingCLoansToUpdate = new List<Contract__c>();
            List<Database.SaveResult> allResults = new List<Database.SaveResult>();
            Map<Id, List<Contract__c>> contractsByAccount = new Map<Id, List<Contract__c>>();

            Map<Id, Contract__c> highestXBSByAcct = new Map<Id, Contract__c>();
            Map<Id, Contract__c> highestNonXBSByAcct = new Map<Id, Contract__c>();
            Map<Id, Account> originalAccounts = new Map<Id, Account>();
            List<String> xbsLessorCodes = new List<String>{'101', '102', '471'};


        for (SObject s : scope) {
            Contract__c c = (Contract__c)s;
            if (c.Customer__c == null || c.RecordTypeId == workingCL) continue;
                // Collect original account only once
            if (!originalAccounts.containsKey(c.Customer__c) && c.Customer__r != null) {
                originalAccounts.put(c.Customer__c, c.Customer__r);
            }

            if (c.IsXBS__c || xbsLessorCodes.contains(c.Lessor_Code__c)) {
                // we only take the *first* XBS contract per customer
                if (!highestXBSByAcct.containsKey(c.Customer__c)) {
                    highestXBSByAcct.put(c.Customer__c, c);
                }
            } else {
                // we only take the *first* non-XBS contract per customer
                if (!highestNonXBSByAcct.containsKey(c.Customer__c)) {
                    highestNonXBSByAcct.put(c.Customer__c, c);
                }
            }
        }

        // -------------------------------------------------------
        //   BUILD ACCOUNT UPDATES
        // -------------------------------------------------------
         Set<Id> allAcctIds = new Set<Id>();
        allAcctIds.addAll(highestXBSByAcct.keySet());
        allAcctIds.addAll(highestNonXBSByAcct.keySet());

        for (Id acctId : allAcctIds) {


            Account original = originalAccounts.get(acctId);
            if (original == null) continue;  // safety check

            Contract__c highestXBS    = highestXBSByAcct.get(acctId);
            Contract__c highestNonXBS = highestNonXBSByAcct.get(acctId);

            Boolean shouldUpdate = false;
            Account acctUpdate = new Account(Id = acctId, Collection_Group__c = original.Collection_Group__c, Highest_Delinquency_Contract__c = original.Highest_Delinquency_Contract__c ,
            Collection_Agent__c = original.Collection_Agent__c, XBS_Collection_Group__c = original.XBS_Collection_Group__c, XBS_Highest_Delinquency_Contract__c = original.XBS_Highest_Delinquency_Contract__c ,
            XBS_Collection_Agent__c = original.XBS_Collection_Agent__c);

            // ---------------- NON-XBS LOGIC ----------------
            if (highestNonXBS != null && highestNonXBS.Collection_Group__c != null) {
                String newGroup = highestNonXBS.Collection_Group__c;
                String oldGroup = original.Collection_Group__c;

                if (oldGroup != newGroup) {
                    shouldUpdate = true;

                    acctUpdate.Collection_Group__c = newGroup;
                    acctUpdate.Highest_Delinquency_Contract__c = highestNonXBS.Id;

                    RR_Assignee__mdt ass = getAgentAssigned(newGroup);
                    if (ass != null) {
                        acctUpdate.Collection_Agent__c = ass.User__c;
                        ass.Last_Assigned__c = DateTime.now();
                        agentsAssigned.put(ass.Id, ass);
                    }
                }

            } else if (original.Highest_Delinquency_Contract__c != null) {
                // Clearing values because no Non-XBS delinquency exists now
                shouldUpdate = true;
                acctUpdate.Collection_Group__c = null;
                acctUpdate.Collection_Agent__c = null;
                acctUpdate.Highest_Delinquency_Contract__c = null;
            }

            // ---------------- XBS LOGIC ----------------
            if (highestXBS != null && highestXBS.Collection_Group__c != null) {
                
                String newGroup = highestXBS.Collection_Group__c;
                String oldGroup = original.XBS_Collection_Group__c;

                if (oldGroup != newGroup) {
                    shouldUpdate = true;

                    acctUpdate.XBS_Collection_Group__c = newGroup;
                    acctUpdate.XBS_Highest_Delinquency_Contract__c = highestXBS.Id;

                    RR_Assignee__mdt ass = getAgentAssigned(newGroup);
                    if (ass != null) {
                        acctUpdate.XBS_Collection_Agent__c = ass.User__c;
                        ass.Last_Assigned__c = DateTime.now();
                        agentsAssigned.put(ass.Id, ass);
                    }
                }

            } else if (original.XBS_Highest_Delinquency_Contract__c != null) {
                shouldUpdate = true;
                acctUpdate.XBS_Collection_Group__c = null;
                acctUpdate.XBS_Collection_Agent__c = null;
                acctUpdate.XBS_Highest_Delinquency_Contract__c = null;
            }

            // Add only if account actually changes
            if (shouldUpdate) {
                accountsToChangeGroup.put(acctId, acctUpdate);
            }
        }


            /*for(sObject s : scope){
                Contract__c contract = (Contract__c)s;
                if(!accountIds.contains(contract.Customer__c) && contract.RecordTypeId != workingCL){
                    accountIds.add(contract.Customer__c);
                    String newCollectionGroup = contract.Collection_Group__c;
                    Account acct = contract.Customer__r;
                    if(acct.Collection_Group__c != newCollectionGroup 
                        /*|| (acct.RecordTypeId == endUserId && (acct.Multiples__c || (!acct.Multiples__c && acct.Collection_Group__c == 'Multiples')))*/ // SL-2805 Misael Romero
                        //|| isFirstAssignment){
                        // SL-2684 Rajesh(LTIMindtree) 
                        /*if(acct.RecordTypeId == endUserId && acct.Multiples__c){
                            newCollectionGroup = 'Multiples';
                        }
                        acct.Collection_Group__c = newCollectionGroup;
                        if (newCollectionGroup == null){
                            acct.Highest_Delinquency_Contract__c = null;
                            acct.Collection_Agent__c = null;
                        }else{
                            acct.Highest_Delinquency_Contract__c = contract.Id;
                            RR_Assignee__mdt assignee = getAgentAssigned(newCollectionGroup);
                            if(assignee != null){
                                acct.Collection_Agent__c = assignee.User__c;
                                assignee.Last_Assigned__c = DateTime.now();
                                agentsAssigned.put(assignee.Id, assignee);
                            }
    
                        }
                        accountsToChangeGroup.put(acct.Id, acct);
                    }
                }
            } */
            for(sObject s : scope){
                Contract__c contract = (Contract__c)s;
                if(!contract.Agent_Lock__c
                    && contract.RecordTypeId == workingCL
                    && contract.Collection_Group__c == 'Working Capital Delinquency'){
                    RR_Assignee__mdt assignee = getAgentAssigned(contract.Collection_Group__c);
                    if(assignee != null){
                        contract.OwnerId = assignee.User__c;
                        assignee.Last_Assigned__c = DateTime.now();
                        agentsAssigned.put(assignee.Id, assignee);
                        workingCLoansToUpdate.add(contract);
                    }
                }
            }
            List<Contract__c> allContractsToUpdate = new List<Contract__c>();
            Integer remainingQueries = System.Limits.getLimitQueries() - System.Limits.getQueries();
            if (accountsToChangeGroup.values().size() > 0){
                if(remainingQueries >= 50){
                    List<Database.SaveResult> acctResult = Database.update(accountsToChangeGroup.values(), false);
                    allResults.addAll(acctResult);
                }else{
                    System.enqueueJob(new SL_CollectionAssignmentQ(accountsToChangeGroup.values()));
                }
                List<Contract__c> contractsToUpdate = [SELECT Id, Customer__c, Agent_Lock__c, delinquency_status_code__c, IsXBS__c, Lessor_Code__c FROM Contract__c 
                    WHERE Customer__c IN :accountsToChangeGroup.keySet() AND (NOT Status__c LIKE '%Disposed%') AND RecordTypeId != :workingCL];
                remainingQueries = System.Limits.getLimitQueries() - System.Limits.getQueries();
                for(Contract__c contract :contractsToUpdate){
                    Account acct = accountsToChangeGroup.get(contract.Customer__c);
                    contract.Account_Level_Collection_Agent__c = (contract.IsXBS__c || xbsLessorCodes.contains(contract.Lessor_Code__c)) ? acct.XBS_Collection_Agent__c : acct.Collection_Agent__c;
                    Boolean hasAgent = false;
                    if((contract.IsXBS__c || xbsLessorCodes.contains(contract.Lessor_Code__c))  && acct.XBS_Collection_Agent__c != null){
                        hasAgent = true;
                    } else if(!(contract.IsXBS__c || xbsLessorCodes.contains(contract.Lessor_Code__c)) && acct.Collection_Agent__c != null){
                        hasAgent = true;
                    }


                    if(hasAgent
                        && !contract.Agent_Lock__c
                        && (contract.delinquency_status_code__c != '00' && contract.delinquency_status_code__c != null
                        /*|| (acct.RecordTypeId == endUserId && acct.Multiples__c)*/)){ // SL-2805 Misael Romero
                        contract.OwnerId =  (contract.IsXBS__c || xbsLessorCodes.contains(contract.Lessor_Code__c)) ? acct.XBS_Collection_Agent__c : acct.Collection_Agent__c;
                    }
                    if((!contract.IsXBS__c && !xbsLessorCodes.contains(contract.Lessor_Code__c))&& contract.Id != acct.Highest_Delinquency_Contract__c){
                        contract.AcctLvl_Highest_Delinquency_Contract__c = acct.Highest_Delinquency_Contract__c;
                    }else{
                        if((contract.IsXBS__c || xbsLessorCodes.contains(contract.Lessor_Code__c)) && contract.Id != acct.XBS_Highest_Delinquency_Contract__c){
                        contract.AcctLvl_Highest_Delinquency_Contract__c = acct.XBS_Highest_Delinquency_Contract__c;
                        }
                        else{
                            contract.AcctLvl_Highest_Delinquency_Contract__c = null;
                        }
                    }
                }
                allContractsToUpdate.addAll(contractsToUpdate);
            }
            allContractsToUpdate.addAll(workingCLoansToUpdate);
            if(allContractsToUpdate.size() > 0){
                List<Contract__c> contractsInThisBatch = new List<Contract__c>();
                List<Contract__c> contractsToQ = new List<Contract__c>();
                if(remainingQueries >= 10){
                    contractsInThisBatch.addAll(allContractsToUpdate);
                }else{
                    contractsToQ.addAll(allContractsToUpdate);
                }
                List<Database.SaveResult> contractResult = Database.update(contractsInThisBatch, false);
                allResults.addAll(contractResult);
                if(contractsToQ.size() > 0){
                    //System.enqueueJob(new SL_CollectionAssignmentQ(contractsToQ));
                }
            }
            for(Database.SaveResult result :allResults){
                if(!result.isSuccess() && Limits.getHeapSize() < Limits.getLimitHeapSize() - 2000){
                    System.debug(result.getErrors());
                    allErrors += '\r\nSObject Id: ' + result.getId() + '\r\n' + result.getErrors();
                    System.debug('allErrors: ' + allErrors);
                }
            }
            System.debug('queries after starting batch: ' + limits.getQueries());
        }catch(Exception e){
            //System.enqueueJob(new SL_CollectionAssignmentQ('misael.romero@silverlinecrm.com', 
                //'Line ' + String.valueOf(e.getLineNumber()), e.getMessage()));
        }
    }
    public void finish(Database.BatchableContext BC){
        if(allErrors.length() > 0){
            AsyncApexJob a = [SELECT Id, Status, CreatedBy.Email
                FROM AsyncApexJob WHERE Id =
                :BC.getJobId()];
            //System.enqueueJob(new SL_CollectionAssignmentQ('misael.romero@silverlinecrm.com', a.Status, allErrors));
        }
        if(agentsAssigned.values().size() > 0){
            SL_RRManageMDT.updateLastAssigned(agentsAssigned);
        }
    }

    private RR_Assignee__mdt getAgentAssigned(String collectionGroup){
        RR_Assignee__mdt assignedAgent = null;
        Integer leastAllocatedGroupNumber = 0;
        Integer mostAllocatedGroupNumber = 0;
        String queueApiName = queueApiNames.get(collectionGroup);
        if(queueApiName != null){
            Map<String, Integer> existing = collectionGroups.get(queueApiName);
            if(existing==null){
                for(RR_Assignee__mdt agent :collectionAgents.get(queueApiName)){
                    if (!collectionGroups.containsKey(queueApiName)){
                        collectionGroups.put(queueApiName, new Map<String, Integer>());
                    }
                    collectionGroups.get(queueApiName).put(String.valueOf(agent.RR_Queue__c)+'_'+agent.Name__c, 0);
                }
            }
            Map<String, Integer> alreadyAssigned = collectionGroups.get(queueApiName);
            if(alreadyAssigned != null && alreadyAssigned.values().size() > 0){
                List<Integer> howManyAssigned = alreadyAssigned.values();
                howManyAssigned.sort();
                mostAllocatedGroupNumber = Math.max(mostAllocatedGroupNumber, howManyAssigned[howManyAssigned.size() - 1]);
                leastAllocatedGroupNumber = Math.min(mostAllocatedGroupNumber, howManyAssigned[0]);
            }
            
            if (collectionAgents.get(queueApiName).size() > 0){
                for(RR_Assignee__mdt agent :collectionAgents.get(queueApiName)){
                    String agentName = String.valueOf(agent.RR_Queue__c)+'_'+agent.Name__c;
                    if (collectionGroups.get(queueApiName).containsKey(agentName)){
                        if(collectionGroups.get(queueApiName).get(agentName) == leastAllocatedGroupNumber){
                            Integer prevNumber = collectionGroups.get(queueApiName).get(agentName);
                            collectionGroups.get(queueApiName).put(agentName, prevNumber + 1);
                            assignedAgent = agent;
                            break;
                        }
                    }
                }
            }
        }
        return assignedAgent;
    }

    public static void sendErrorsMail(String toAddress, String status, String allErrors){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {toAddress});
        mail.setSubject('Batch Job ' + status + ' with the below errors:');
        mail.setPlainTextBody(allErrors);
        System.debug('allErrors: ' + allErrors);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}