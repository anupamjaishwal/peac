public without sharing class TC_TaskHelper {
    private static TC_TaskHelperGateway taskGw;
    private Map<Id, Lead> leadsToUpdate;
    private static Map<Id, User> userMap;
    private Map<Id, Integer> userToOpenTaskCount;
    private Map<String, CampaignMember> cmsToUpdate;
    private static Set<String> whoTypes;
    private static Set<String> whatTypes;
    private static Set<String> closedStatuses {
        get {
            if (closedStatuses == null) closedStatuses = taskGw.getClosedStatuses();
            return closedStatuses;
        }
        set;
    }
    private static List<String> afuToTenfoldFields;
    public static SDR_Prospecting_Settings__c sdrProspectingSettings {
        get {
            if (sdrProspectingSettings == null) {
                sdrProspectingSettings = SDR_Prospecting_Settings__c.getInstance();
                if (sdrProspectingSettings.Name == null) sdrProspectingSettings = (SDR_Prospecting_Settings__c) SDR_Prospecting_Settings__c.SObjectType.newSObject(null, true);
            }
            return sdrProspectingSettings;
        }
        set;
    }
    private static Set<String> autoCloseOutcomes;
    private static Set<Id> tasksToRemove;
    private static Map<Id, SObject> whoWhatMap;
    private static SObjectType leadSoType = Lead.getSObjectType();
    private static Map<id,boolean> userIsSdrMap = new Map<id,boolean>();

    //This is the method that the trigger will call during execution
    public void TC_TaskHelperExecute() {
        globalInit();
        //Calling the bulk functions, this is where maps of data will be stored ans queried
        if (Trigger.isBefore) bulkActionsBeforeContext();
        if (Trigger.isAfter)  bulkActionsAfterContext();

        //Calling each of the contexts which will be iterated over
        if (Trigger.isInsert) insertContext();
        if (Trigger.isUpdate) updateContext();
        if (Trigger.isDelete) deleteContext();

        andFinally();
    }

    /**
     * This funciton will initialize global variables
     */
    private void globalInit() {
        taskGw = taskGw == null ? new TC_TaskHelperGateway() : taskGw;
        leadsToUpdate = leadsToUpdate == null ? new Map<Id,Lead>() : leadsToUpdate;
        userToOpenTaskCount = userToOpenTaskCount == null ? new Map<Id,Integer>() : userToOpenTaskCount;
        cmsToUpdate = cmsToUpdate == null ? new Map<String,CampaignMember>() : cmsToUpdate;
        tasksToRemove = tasksToRemove == null ? new Set<Id>() : tasksToRemove;
        whoWhatMap = whoWhatMap == null ? new Map<Id,SObject>() : whoWhatMap;
        whoTypes = whoTypes == null ? new Set<String>(): whoTypes;
        whatTypes = whatTypes == null ? new Set<String>(): whatTypes;
        afuToTenfoldFields = afuToTenfoldFields == null ? getAutoFollowUpToTenfoldFieldSetFields() : afuToTenfoldFields;
        autoCloseOutcomes = autoCloseOutcomes == null ? new Set<String> (Label.Lead_Closed_Lost_Out_Comes.split(',')) : autoCloseOutcomes;
        List<user> allUsers = [select id, UserRole.Id from user where isActive=:true];
        Map<id,id> userWithRoleMap = new Map<id,id>();
        for(user usr : allUsers){
            userWithRoleMap.put(usr.Id, usr.UserRole.Id);
        }
        Map<id, Group> grpList = new Map<ID, Group>([select Id from Group where relatedid IN: userWithRoleMap.values() And Type='Role' AND Id IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'SDR')]);
        for(user usr : allUsers){
            if(grpList.containsKey(userWithRoleMap.get(usr.Id)))
            userIsSdrMap.put(usr.Id, true);
            else
                userIsSdrMap.put(usr.Id, false);
        }
    }

    /**
     * Will process records in bulk in the before context of the trigger before
     * iterating over the each of the records and making adjustments
     */
    private void bulkActionsBeforeContext() {
        for (Task t : Trigger.new == null ? (List<Task>) Trigger.old : Trigger.new) {
            Task tOld = Trigger.oldMap == null ? null : (Task)Trigger.oldMap.get(t.Id);
            if (!Trigger.isDelete) checkIfRelatedRecordQueryIsNeeded(t, tOld);
        }

        if (!whoWhatMap.isEmpty()) whoWhatMap = taskGw.getWhoWhatRecords(whoWhatMap.keySet());
    }

    /**
     * Will process records in bulk in the after context of the trigger before
     * iterating over the each of the records and making adjustments
     */
    private void bulkActionsAfterContext() {
        Boolean queryAllTasks = false;
        Boolean queryWhoWhat = false;
        for (Task t : Trigger.new == null ? (List<Task>) Trigger.old : Trigger.new) {
            Task tOld = Trigger.oldMap == null ? null : (Task)Trigger.oldMap.get(t.Id);

            if (!t.IsClosed && Trigger.isUpdate && t.OwnerId != tOld.OwnerId) userToOpenTaskCount.put(t.OwnerId, null);

            if (warmTransferredTask(t, tOld) && !whoWhatMap.containsKey(t.Lead__c)) {
                whoWhatMap.put(t.Lead__c, null);
                queryAllTasks = true;
            }
        }

        if (userMap == null) userMap = taskGw.getUsers(userToOpenTaskCount.keySet());
        userToOpenTaskCount = taskGw.getOpenCount(userToOpenTaskCount.keySet());
        if (queryWhoWhat) whoWhatMap.putAll(taskGw.getWhoWhatRecords(whoWhatMap.keySet()));
    }

    /**
     * @description This function checks if the task was warm transferred
     *
     * @param t     The triggered record
     * @param tOld  The previous version of te triggered record
     *
     * @return      If the task was warm transferred
     */
    private Boolean warmTransferredTask(Task t, Task tOld) {
        return fieldChanged(t, tOld, 'Task_Outcome__c') && t.Lead__c != null && t.Task_Outcome__c == sdrProspectingSettings.WarmTransferTaskOutcome__c;
    }
    
    /**
     * Will process records in the insert context
     */
    private void insertContext() {
        TC_CampaignMemberHelper.IsFromTrigger = true;
        List<Task> tasks = (List<Task>) Trigger.new;
        
        for (Task t : tasks) {
            if (Trigger.isBefore) {
                updateTenFoldTasks(t, null);
                setPrimaryLead(t);
                checkForClosure(t, null);
            }
            if (Trigger.isAfter) {
                checkForLeadUpdate(t, null);
                checkForCampaignMemberUpdates(t, null);
            }
        }
    }

    /**
     * Will process records in the update context
     */
    private void updateContext() {
        TC_CampaignMemberHelper.IsFromTrigger = true;
        List<Task> tasks = (List<Task>) Trigger.new;
        Map<Id,Task> oldMap = new Map<Id,Task> ((List<Task>) Trigger.old);

        for (Task t : tasks) {
            Task tOld = oldMap.get(t.Id);
            if (Trigger.isBefore) {
                updateTenFoldTasks(t, tOld);
                setPrimaryLead(t);
                checkForClosure(t, tOld);
            }
            if (Trigger.isAfter) {
                checkOwnerOpenTaskCount(t, tOld);
                checkForLeadUpdate(t, tOld);
                checkForCampaignMemberUpdates(t, tOld);
            }
        }
    }
    
    /**
     * Will process records in the delete context
     */
    private void deleteContext() {
        List<Task> tasks = Trigger.New == null ? (List<Task>) Trigger.old : Trigger.new;
        for (Task t : tasks) {
            if (Trigger.isBefore) {}
            if (Trigger.isAfter) {}
        }
    }

    /**
     * This method is where any final actions need to take place for the trigger
     */
    private void andFinally() {
        if (Trigger.isAfter) {
            if (!leadsToUpdate.isEmpty()) Database.update(leadsToUpdate.values());
            if (!cmsToUpdate.isEmpty()) {
               
                    system.debug('****TC_CampaignMemberHelper.IsFromTrigger'+TC_CampaignMemberHelper.IsFromTrigger);
                Database.update(cmsToUpdate.values());
            }
           
            removeTasks();
            TC_CampaignMemberHelper.IsFromTrigger = false;
        }
    }

    /**
     * This is where all queries should be called
     */
    public class TC_TaskHelperGateway {

        public Map<Id, Integer> getOpenCount(Set<Id> userIds) {
            Map<Id, Integer> returnMap = new Map<Id, Integer>();

            for (AggregateResult ar : [SELECT OwnerId, COUNT(Id) taskCount FROM Task WHERE OwnerId = :userIds AND IsClosed = FALSE AND Owner.Username != null GROUP BY OwnerId]) {
                returnMap.put((Id)ar.get('OwnerId'), (Integer) ar.get('taskCount'));
            }

            for (Id uId : userIds) {
                if (!returnMap.containsKey(uId)) returnMap.put(uId, 0);
            }

            return returnMap;
        }

        public Map<Id, User> getUsers(Set<Id> userIds) {

            return new Map<Id, User>([SELECT Id, Name FROM User WHERE Id IN :userIds]);
        }

        /**
         * @description         Getting the related who what records so we can dig into them to grab information
         *
         * @param whoWhatIds    The who or what id's to query
         *
         * @return              The map of who/what id to the sobject
         */
        public Map<Id, SObject> getWhoWhatRecords(Set<Id> whoWhatIds) {

            Map<Id, SObject> returnMap = new Map<Id, SObject>();
            List<String> objectsToQuery = new List<String> {'Lead'};//Creating the ability to accommodate contacts at some point later
            List<Account> accts = (List<Account>) Database.query('SELECT Id, MostRecentLead__c, MostRecentLead__r.LeadOutcomeDate__c, Campaign__c FROM Account WHERE Id IN :whoWhatIds AND MostRecentLead__c <> NULL');

            Set<Id> idsToQuery = new Set<Id>();
            idsToQuery.addAll(whoWhatIds);

            for (Account acct : accts) if (acct.MostRecentLead__c != null && acct.MostRecentLead__r.LeadOutcomeDate__c == null) idsToQuery.add(acct.MostRecentLead__c);
            if (idsToQuery.size() != whoWhatIds.size()) whoTypes.add('Lead');
            if (whatTypes.contains('Account')) returnMap.putAll(new Map<Id, SObject>(accts));

            for (String objNm : objectsToQuery) {
                if (whoTypes.contains(objNm)) returnMap.putAll(new Map<Id, SObject>(Database.query(whoIdQuery()+' FROM '+objNm+' WHERE Id IN :idsToQuery')));
            }

            return returnMap;
        }

        /**
         * @description Will query the closed statuses for task so we can see if the task is actually closed in the before
         * context
         *
         * @return      The closed statuses
         */
        public Set<String> getClosedStatuses() {
            Set<String> returnSet = new Set<String>();
            for (TaskStatus ts :[SELECT Id, ApiName FROM TaskStatus WHERE IsClosed = true]) {
                returnSet.add(ts.ApiName);
            }
            return returnSet;
        }

        /**
         * @description Construct a who Id query with the open tasks sub queried
         *
         * @return      The whoid query
         */
        private String whoIdQuery() {
            List<String> taskFlds = new List<String>(afuToTenfoldFields);
            if (!taskFlds.contains('fml_AccountTargetSDRCampaignId__c')) taskFlds.add('fml_AccountTargetSDRCampaignId__c');
            if (!taskFlds.contains('Id')) taskFlds.add('Id');
            if (!taskFlds.contains('Subject')) taskFlds.add('Subject');

            return 'SELECT Id, (SELECT '+String.join(taskFlds,',')+' FROM Tasks WHERE IsClosed = FALSE AND AutoFollowUp__c <> NULL AND Lead__r.LeadOutcomeDate__c = null ORDER BY ActivityDate DESC), (SELECT Id, CurrentAutoFollowUpStep__c, CampaignId FROM CampaignMembers WHERE AutoFollowUpsCompleted__c = false AND CurrentAutoFollowUpStep__c <> null)';
        }
    }

    /**
     * @description This function will check if the task is a tenfold one, if so, it will attempt to locate and twin
     * specific values from an auto follow up task, then mark that afu task for deletion
     * @see         SAL-1876
     *
     * @param t     The triggered record
     * @param tOld  The previous version of the triggered record
     *
     * @return      The updated task
     */
    private Task updateTenFoldTasks(Task t, Task tOld) {
       
        // This is modified due to SAL-2344 3/2/2021
        //Changes starts
        system.debug('*****userIsSdrMap.get(t.OwnerId)'+ userIsSdrMap.get(t.OwnerId));
        //if (tIsClosed(t) && fieldChanged(t, tOld,'Status')) {
  //if (checkRelatedRecords(t, tOld) && createdByTenFold(t)) { // Existing logic
        //Updated logic
        if (checkRelatedRecords(t, tOld) && createdByTenFold(t) && !userIsSdrMap.get(t.OwnerId) &&   !string.valueOf(t.OwnerId).startsWith('00G')  ) {
            SObject who = whoWhatMap.get(t.WhoId);
            SObject what = whoWhatMap.get(t.WhatId);
           
            //Getting the who record if there is no whoid (e.g. if the task was created from an account that has an open lead)
            who = who == null ? whoWhatMap.get(t.Lead__c) : who;
            if (what != null && who == null && what.getSObjectType() == Account.getSObjectType() && what.get('MostRecentLead__c') != null) who = whoWhatMap.get((Id) what.get('MostRecentLead__c'));

            Task formerTask;
            try {
                formerTask = who != null && who.getSObjects('Tasks') != null && !who.getSObjects('Tasks').isEmpty() ? (Task) who.getSObjects('Tasks')[0] : formerTask;
                formerTask = formerTask == null && what != null && what.getSObject('Tasks') != null && !what.getSObjects('Tasks').isEmpty() ? (Task) what.getSObjects('Tasks')[0] : formerTask;

            } catch (Exception e) {
                System.debug(e.getMessage());
            }
            if (formerTask != null && formerTask.Id != t.Id) tasksToRemove.add(formerTask.Id);
            if (formerTask != null && formerTask.Id != t.Id) t = updateTaskFromOther(t, formerTask);

        }
        return t;
    }

    /**
     * @description     This function will update one task from another
     *
     * @param triggered The task that was triggered
     * @param former    The task to copy information from
     *
     * @return          The updated trigger task
     */
    @TestVisible static Task updateTaskFromOther(Task triggered, Task former) {
        for (String fld : afuToTenfoldFields) {
            triggered.put(fld, former.get(fld));
        }
        triggered.Subject = former.Subject + '-' + triggered.Subject;
        triggered.WhoId = triggered.WhoId != triggered.Lead__c && triggered.Lead__c != null ? triggered.Lead__c : triggered.WhoId;

        //Assumption - we want to maintain ownership chain to the account, Lead tasks can't have a what Id
        if (triggered.WhatId != null && triggered.Lead__c != null && triggered.WhoId == triggered.Lead__c) triggered.WhatId = null;

        return triggered;
    }

    /**
     * @description This function will check if a related records change has taken place that will need a query
     *
     * @param t     The triggered record
     * @param tOld  The previous version of the triggered record
     *
     * @return
     */
    private Boolean checkRelatedRecords(Task t, Task tOld) {

        return ((createdByTenFold(t) && t.AutoFollowUp__c == null) || t.AutoFollowUp__c != null) && tIsClosed(t) && fieldChanged(t, tOld,'Status');
    }

    private Boolean createdByTenFold(Task t) {
        return ((UserInfo.getUserName().startsWith('usertenfold') && Trigger.isInsert) || t.fml_CreatedByTenfold__c);
    }

    /**
     * @description This function will check if the task status is set to a closed status. This is needed because the
     * isClosed field isn't set until the after context. If evaluating in the before context, we need to check against
     * the statuses that are closed
     *
     * @param t     The triggered record
     *
     * @return      If the task is closed
     */
    private Boolean tIsClosed(Task t) {
        return closedStatuses.contains(t.Status);
    }

    /**
     * @description This function checks if the user has too many open records
     *
     * @param t     The triggered record
     * @param tOld  The previous version of the triggered record
     */
    private void checkOwnerOpenTaskCount(Task t, Task tOld) {
        String message = 'The user ' + (userMap.get(t.OwnerId) != null ? userMap.get(t.OwnerId).Name : '') +' has more than '+sdrProspectingSettings.MaxOpenTasks__c+' open tasks assigned!';
        if (Trigger.isUpdate && !t.IsClosed && tOld.OwnerId != t.OwnerId && t.OwnerId.getSobjectType() == User.getSObjectType()) System.assert(userToOpenTaskCount.get(t.OwnerId) < sdrProspectingSettings.MaxOpenTasks__c, message);
    }

    /**
     * @description This function will set the primary lead
     *
     * @param t     The triggered record
     *
     * @return      The updated task with a primary lead set
     */
    private Task setPrimaryLead(Task t) {
        if (t.Lead__c == null && (t.fml_PrimaryLeadFromAccount__c != null || (t.WhoId != null && t.WhoId.getSobjectType() == leadSoType))) {
            t.Lead__c = t.fml_PrimaryLeadFromAccount__c != null ? t.fml_PrimaryLeadFromAccount__c : t.WhoId;
        }
        //SAL-2418
        if (!t.IsClosed && t.Lead__c != null && t.fml_PrimaryLeadFromAccount__c != null && t.Lead__c != t.fml_PrimaryLeadFromAccount__c && t.AutoFollowUp__c != null) t.Lead__c = t.fml_PrimaryLeadFromAccount__c;
        return t;
    }

    /**
     * @description This function checks if an update to the lead is needed
     *
     * @param t     The triggered record
     * @param tOld  The previous version of the triggered record
     */
    private void checkForLeadUpdate(Task t, Task tOld) {
        if (t.Lead__c != null && leadUpdateNeeded(t, tOld)) {
            Lead l = new Lead (Id = t.Lead__c);
            if (ownerChanged(t, tOld) && userMap.containsKey(t.OwnerId)) {
                l.OwnerId = t.OwnerId;
                //l.Status = sdrProspectingSettings.Lead_Status_On_Task_Assignment__c;
            }
            
            /*if (outcomeChanged(t, tOld)) {
                String status = autoCloseOutcomes.contains(t.LeadOutcomeType__c) ? sdrProspectingSettings.LeadCloseOutcome__c : '';
                       status = String.isBlank(status) && t.LeadOutcomeType__c.contains('Warm Transfer') ? sdrProspectingSettings.LeadWarmTransferStatus__c : status;
                if (String.isNotBlank(status)) l.Status = status;
                l.Lead_Outcome__c = t.LeadOutcomeType__c;
            }*/
           
			if(warmTransferredTask(t, tOld))
            {
                l.Status = sdrProspectingSettings.LeadWarmTransferStatus__c;
            }
            leadsToUpdate.put(t.Lead__c, l);
        }
    }

    /**
     * @description This function will check if the owner of the task has changed
     *
     * @param t     The triggered record
     * @param tOld  The previous version of the triggered record
     *
     * @return      If the owner has changed
     */
    private Boolean ownerChanged(Task t, Task tOld) {
        return !createdByTenFold(t) && t.OwnerId == UserInfo.getUserId() && fieldChanged(t, tOld,'OwnerId');
    }
    

    /**
     * @description This function checks if the task was just closed
     *
     * @param t     The triggered record
     * @param tOld  The previous version of the triggered record
     *
     * @return      The updated record
     */
    private Task checkForClosure(Task t, Task tOld) {
        if (tIsClosed(t) && fieldChanged(t, tOld,'Status') && t.fml_Owner_Is_A_Queue__c) t.OwnerId = UserInfo.getUserId();
       
        return t;
    }

    /**
     * @description This function will check if the field value has changed
     *
     * @param t     The triggered record
     * @param tOld  The previous version of the triggered record
     * @param fld   The field to check
     *
     * @return      If there was a change in field value
     */
    private Boolean fieldChanged(Task t, Task tOld, String fld) {
        return Trigger.isInsert || (Trigger.isUpdate && t.get(fld) != tOld.get(fld));
    }

    /**
     * @description This function will check if the outcome has changed
     *
     * @param t     The triggered record
     * @param tOld  The previous version of the triggered record
     *
     * @return      If the out come has changed
     */
    private Boolean outcomeChanged(Task t, Task tOld) {
        return (String.isNotBlank(t.LeadOutcomeType__c) && fieldChanged(t, tOld, 'LeadOutcomeType__c'));
    }

    /**
     * @description This function will check if there is a lead update needed
     *
     * @param t     The triggered record
     * @param tOld  The previous version of the triggered record
     *
     * @return      If a lead update is needed
     */
    private Boolean leadUpdateNeeded(Task t, Task tOld) {
        return t.Lead__c != null && (outcomeChanged(t, tOld) || ownerChanged(t, tOld) || warmTransferredTask(t, tOld));
    }

    /**
     * @description This function will get the auto follow-up to tenfold field set fields
     *
     * @return      The field sets fields
     */
    private List<String> getAutoFollowUpToTenfoldFieldSetFields() {
        List<String> returnList = new List<String>();
        for (FieldSetMember fsm : Task.getSObjectType().getDescribe().fieldSets.getMap().get('Task_Auto_Follow_Up_to_Tenfold_Fields').fields) {
            returnList.add(fsm.fieldPath);
        }
        return returnList;
    }

    /**
     * @description This function will check if a campaign member update is needed
     *
     * @param t     The triggered record
     * @param tOld  The previous version of the triggered record
     */
    private void checkForCampaignMemberUpdates(Task t, Task tOld) {
        Lead l = (Lead) whoWhatMap.get(t.Lead__c);
        if (l != null && !l.CampaignMembers.isEmpty()) {
            CampaignMember cmRecord = l.CampaignMembers[0];
            Boolean wasWarmTransferred = warmTransferredTask(t, tOld);
            CampaignMember cm = new CampaignMember(Id = cmRecord.Id);
            if (t.Subject.contains('Inbound') && !wasWarmTransferred) cm.DaysUntilNextTransition__c = 0;
            if (wasWarmTransferred) cm.AutoFollowUpsCompleted__c = true;
            if (tIsClosed(t) && fieldChanged(t, tOld, 'Status') && !wasWarmTransferred ){
                cm.DateofLastStepTransition__c = Date.today();
            }
            if (cm.DateofLastStepTransition__c != null || cm.DaysUntilNextTransition__c != null || cm.AutoFollowUpsCompleted__c != null) cmsToUpdate.put(cm.Id, cm);
        }
    }

    /**
     * @description This function will check if related records need to be queried
     *
     * @param t     The triggered record
     * @param tOld  The previous version of the triggered record
     */
    private void checkIfRelatedRecordQueryIsNeeded(Task t, Task tOld) {
        if (checkRelatedRecords(t, tOld) && String.isNotBlank(t.WhoId)) whoWhatMap.put(t.WhoId, null);
        if (whoWhatMap.containsKey(t.WhoId)) whoTypes.add(String.valueOf(t.WhoId.getSobjectType()));

        if (checkRelatedRecords(t, tOld) && String.isNotBlank(t.Lead__c)) whoWhatMap.put(t.Lead__c, null);
        if (whoWhatMap.containsKey(t.Lead__c)) whoTypes.add('Lead');

        if (checkRelatedRecords(t, tOld) && String.isNotBlank(t.WhatId)) whoWhatMap.put(t.WhatId, null);
        if (whoWhatMap.containsKey(t.WhatId)) whatTypes.add(String.valueOf(t.WhatId.getSobjectType()));
    }

    /**
     * @description This function will remove the tasks flagged
     */
    private void removeTasks() {
        List<Id> IdsToRemove = new List<Id>(tasksToRemove);
        tasksToRemove = null;
        if (!IdsToRemove.isEmpty()) Database.delete(IdsToRemove,false);
    }
// copado please
}