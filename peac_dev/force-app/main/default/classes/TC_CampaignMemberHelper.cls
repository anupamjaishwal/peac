/**
* @description This class is responsible for managing the campaign member trigger
* @see         SAL-1869
*/
public without sharing class TC_CampaignMemberHelper {
    private static TC_CampaignMemberHelperGateway g_gw;
    private static Map<Id, Campaign> g_cm_campaignMap;
    private static Map<Id, Task> g_cm_TasksToInsertMap;
    private static Map<Id, Lead> g_cm_LeadsToUpdate;
    private static Set<Id> g_cm_tasksToDelete;
    private static Set<Id> g_cm_attemptedClear;
    public static boolean IsFromTrigger = False;
    private Set<Id> g_cm_cmsToRemove;
    private static List<String> campaignNamesToExcludeFromRemoval;
    private Map<Id, SObject> g_cm_WhoIdToWhoObjectMap;
    private static SDR_Prospecting_Settings__c sdrProspectingSettings {
        get {
            if (sdrProspectingSettings == null) {
                sdrProspectingSettings = SDR_Prospecting_Settings__c.getInstance();
                if (sdrProspectingSettings.Name == null) sdrProspectingSettings = (SDR_Prospecting_Settings__c) SDR_Prospecting_Settings__c.SObjectType.newSObject(null, true);
            }
            return sdrProspectingSettings;
        }
        set;
    }
    private static BusinessHours defaultBh;
    // start Fix for SDR leads without any prior activity SAL-2344 
    private static list<lead> leadRecds;
    private static map<id,lead> mapIdLeadRecds =new map<id,lead>();
    // end Fix for SDR leads without any prior activity SAL-2344 
    private static Boolean autoFollowUpsProcessed {
        get {
            if (autoFollowUpsProcessed == null) autoFollowUpsProcessed = false;
            return autoFollowUpsProcessed;
        }
        set;
    }
    private static Id defaultOwner {
        get {
            return TC_AccountToLead.queueId;
        }
    }
    private Map<Id, User> definedUsers;
    
    //This is the method that the Trigger will call during execution
    public void execute() {
        
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
    * @description  This function will initialize global variables
    */
    private void globalInit() {
        g_gw = g_gw == null ? new TC_CampaignMemberHelperGateway() : g_gw;
        g_cm_campaignMap = g_cm_campaignMap == null ? new Map<Id,Campaign>() : g_cm_campaignMap;
        g_cm_TasksToInsertMap = g_cm_TasksToInsertMap == null ? new Map<Id,Task>() : g_cm_TasksToInsertMap;
        g_cm_cmsToRemove = g_cm_cmsToRemove == null ? new Set<Id>(): g_cm_cmsToRemove;
        g_cm_WhoIdToWhoObjectMap = g_cm_WhoIdToWhoObjectMap == null ? new Map<Id,SObject>() : g_cm_WhoIdToWhoObjectMap;
        g_cm_LeadsToUpdate = g_cm_LeadsToUpdate == null ? new Map<Id,Lead>() : g_cm_LeadsToUpdate;
        g_cm_tasksToDelete = g_cm_tasksToDelete == null ? new Set<Id>(): g_cm_tasksToDelete;
        defaultBh = defaultBh == null ? g_gw.getBusinessHours() : defaultBh;
        campaignNamesToExcludeFromRemoval = campaignNamesToExcludeFromRemoval == null ? String.isNotBlank(sdrProspectingSettings.CampaignsToExcludeFromTransitions__c) ? sdrProspectingSettings.CampaignsToExcludeFromTransitions__c.split(',') : new List<String>() : campaignNamesToExcludeFromRemoval;
        definedUsers = definedUsers == null ? new Map<Id, User>() : definedUsers;
        g_cm_attemptedClear = g_cm_attemptedClear == null ? new Set<Id>() : g_cm_attemptedClear;
        
    }
    
    /**
    * @description Will process records in bulk in the before context of the Trigger before
    * iterating over the each of the records and making adjustments
    */
    private void bulkActionsBeforeContext() {
        
        Boolean queryCampaign = false;
        
        for (CampaignMember cm : Trigger.new == null ? (List<CampaignMember>) Trigger.old : Trigger.new) {
            CampaignMember cmOld = Trigger.oldMap == null ? null : (CampaignMember)Trigger.oldMap.get(cm.Id);
            if (Trigger.isUpdate && cmOld.CurrentAutoFollowUpStep__c != null && cm.CurrentAutoFollowUpStep__c == null) g_cm_attemptedClear.add(cm.Id);
            //Checking if the campaign member needs to have an auto follow-up step added or progressed
            if (shouldAddCampaignToQuery(cm, cmOld)) g_cm_campaignMap.put(cm.CampaignId, null);
            if (!queryCampaign && g_cm_campaignMap.containsKey(cm.CampaignId) && g_cm_campaignMap.get(cm.CampaignId) == null) queryCampaign = true;
            if ((queryCampaign || cm.fml_FollowUpTaskNeeded__c) && cm.LeadId != null) g_cm_WhoIdToWhoObjectMap.put(cm.LeadId, null);
            if (cm.fml_MemberOwnerId__c != null && !definedUsers.containsKey(cm.fml_MemberOwnerId__c) && Id.valueOf(cm.fml_MemberOwnerId__c).getSobjectType() == User.getSObjectType()) definedUsers.put(cm.fml_MemberOwnerId__c, null);
        }
        
        if (queryCampaign) g_cm_campaignMap = g_gw.getCampaignAndChildrenMap(g_cm_campaignMap.keySet());
        if (!definedUsers.isEmpty()) definedUsers = new Map<Id, User> ([SELECT Id FROM User WHERE IsActive = TRUE AND Id IN : definedUsers.keySet()]);
        if (!g_cm_WhoIdToWhoObjectMap.isEmpty()) g_cm_WhoIdToWhoObjectMap = g_gw.getWhoIdMap(g_cm_WhoIdToWhoObjectMap.keySet());
    }
    
    /**
    * @description Will process records in bulk in the after context of the Trigger before
    * iterating over the each of the records and making adjustments
    */
    private void bulkActionsAfterContext() {
        Set<String> extIdsToDelete = new Set<String>();
        Set<Id> whoIdsToDeleteTasksFor = new Set<Id>();
        for (CampaignMember cm : Trigger.new == null ? (List<CampaignMember>) Trigger.old : Trigger.new) {
            CampaignMember cmOld = Trigger.oldMap == null ? null : (CampaignMember)Trigger.oldMap.get(cm.Id);
            //Checking if the campaign member needs to have an auto follow-up step added or progressed
            if (Trigger.isInsert && cm.LeadId != null) g_cm_WhoIdToWhoObjectMap.put(cm.LeadId, null);
            if (Trigger.isDelete && cm.LeadId != null && cm.CurrentAutoFollowUpStep__c != null) {
                extIdsToDelete.add(cm.fml_CampaignName__c+''+cm.LeadId);
                whoIdsToDeleteTasksFor.add(cm.LeadId);
            }
            
        }
        if (!g_cm_WhoIdToWhoObjectMap.isEmpty()) g_cm_WhoIdToWhoObjectMap = g_gw.getWhoIdMap(g_cm_WhoIdToWhoObjectMap.keySet());
        if (!extIdsToDelete.isEmpty()) g_cm_tasksToDelete.addAll(g_gw.getOpenTaskMap(extIdsToDelete, whoIdsToDeleteTasksFor).keySet());
    }
    
    /**
    * @description  Will process records in the insert context
    */
    private void insertContext() {
        List<CampaignMember> cms = (List<CampaignMember>) Trigger.new;
        
        for (CampaignMember cm : cms) {
            
            if (Trigger.isBefore) {
                
                updateDaysUntilNextTransition(cm);
                transitionToNextFollowUpStep(cm, null);
                updateCampaignMemberStatus(cm, null);
            }
            
            if (Trigger.isAfter) {
                removeExistingCampaignMembersIfNeeded(cm);
            }
        }
    }
    
    /**
    * @description Will process records in the update context
    */
    private void updateContext() {
        List<id> leadIdsForCM = new List<id>();
        for (CampaignMember cm : (List<CampaignMember>) Trigger.new) {
            if(cm.LeadId != null && mapIdLeadRecds.get(cm.LeadId) == null)
                leadIdsForCM.add(cm.LeadId);
        }
        Datetime oneMinBack = Datetime.now().addMinutes(-1);
        if(!leadIdsForCM.isEmpty()){
            for(Lead ld : [SELECT Id,PrimaryAccount__c, CurrentCampaign__r.Number_Auto_Follow_Up_Steps__c,(select ID, status,AutoFollowUp__c,AutoFollowUp__r.StepNumber__c, AutoFollowUp__r.DefaultDaysUntilNextFollowup__c,AutoFollowUp__r.Name,SystemModstamp,LastModifiedDate , fml_Auto_Follow_Up_Campaign_Name__c, OwnerId from tasks
                                                         where   AutoFollowUp__c != null OR subject ='Outbound Call - Prospecting' ORDER BY CreatedDate DESC NULLS FIRST LIMIT 1) FROM Lead where id IN: leadIdsForCM]){
                                                             mapIdLeadRecds.put(ld.id, ld);                                    
                                                         }
        }
        List<CampaignMember> cms = (List<CampaignMember>) Trigger.new;
        
        Map<Id,CampaignMember> oldMap = new Map<Id,CampaignMember> ((List<CampaignMember>) Trigger.old);
        Map<Id, Campaign> cm_campaignMap = g_gw.getCampaignAndChildrenMap(g_cm_campaignMap.keySet());
        for (CampaignMember cm : cms) {
            
            //Campaign camp1 = cm_campaignMap.get(cm.CampaignId);
            if (Trigger.isBefore &&  (!mapIdLeadRecds.get(cm.LeadId).tasks.isEmpty() && mapIdLeadRecds.get(cm.LeadId).tasks[0].status == 'Completed' )) {
                system.debug('*******CMBefore'+ cm);
                updateDaysUntilNextTransition(cm);
                system.debug('*******CM'+ cm);
                system.debug('============TodaycampNXstep'+ mapIdLeadRecds.get(cm.LeadId).CurrentCampaign__r.Number_Auto_Follow_Up_Steps__c);
                system.debug('============TodaycampAutoFollowupstep'+ mapIdLeadRecds.get(cm.LeadId).tasks[0].AutoFollowUp__r.StepNumber__c);
                if(!IsFromTrigger || (IsFromTrigger && mapIdLeadRecds.get(cm.LeadId).CurrentCampaign__r.Number_Auto_Follow_Up_Steps__c == mapIdLeadRecds.get(cm.LeadId).tasks[0].AutoFollowUp__r.StepNumber__c ))
                //if(!IsFromTrigger ) 
                transitionToNextFollowUpStep(cm, oldMap.get(cm.Id));
                updateCampaignMemberStatus(cm, oldMap.get(cm.Id));
                setOpenTasksToBeDeleted(cm, oldMap.get(cm.Id));
            }
            
            if (Trigger.isAfter) {
                
            }
        }
    }
    
    /**
    * @description Will process records in the delete context
    */
    private void deleteContext() {
        
        List<CampaignMember> cms = Trigger.New == null ? (List<CampaignMember>) Trigger.old : Trigger.new;
        
        for (CampaignMember cm : cms) {
            
            if (Trigger.isBefore) {}
            
            if (Trigger.isAfter) {}
        }
    }
    
    /**
    * @description This method is where any final actions need to take place for the Trigger
    */
    private void andFinally() {
        system.debug('&&&***'+ g_cm_LeadsToUpdate.values());
        if (Trigger.isAfter) {
            system.debug('&&&***1'+ g_cm_LeadsToUpdate.values());
            //Creating the tasks
            if (!autoFollowUpsProcessed && !g_cm_TasksToInsertMap.isEmpty()) {
                
                autoFollowUpsProcessed = Test.isRunningTest() ? false : true;
                List<Task> tasksToInsert = new List<Task>(g_cm_TasksToInsertMap.values());
                
                g_cm_TasksToInsertMap = null;
                List<Database.Error> errors = JobSequenceUtilities.attemptJobSequenceDML(tasksToInsert, 'insert', false);
                if (!errors.isEmpty()) JobSequenceUtilities.logErrors(new JobSequence(), errors, Trigger.newMap.keySet());
            }
            
            try {
                if (!g_cm_cmsToRemove.isEmpty()) Database.delete(new List<Id>(g_cm_cmsToRemove));
                
                if (!g_cm_LeadsToUpdate.isEmpty()) {
                    List<Lead> leads = new List<Lead>(g_cm_LeadsToUpdate.values());
                    g_cm_LeadsToUpdate = null;
                    Database.update(leads,false);
                    
                }
                List<Id> tasksToDel = new List<Id> (g_cm_tasksToDelete);
                g_cm_tasksToDelete = null;
                Database.delete(new List<Id>(tasksToDel),false);
           } catch(Exception e){
                System.debug('The following exception has occurred: ' + e.getMessage());

           }
        }
    }
    
    /**
    * @description This function will transition the campaign member to the next follow up step
    *
    * @param cm    The triggered record
    * @param cmOld The previous version of the triggered record
    *
    * @return      The updated record
    */
    private CampaignMember transitionToNextFollowUpStep(CampaignMember cm, CampaignMember cmOld) {
        system.debug('====UpdateStep==='+ cmOld);
        if(cm.fml_FollowUpTaskNeeded__c|| cm.CurrentAutoFollowUpStep__c == null) {
            
            Campaign camp = g_cm_campaignMap.get(cm.CampaignId);
            Lead l = (Lead) g_cm_WhoIdToWhoObjectMap.get(cm.LeadId);
            system.debug('****transitionToNextFollowUpStep' );
            if (l != null && camp != null) {
                system.debug('****transitionToNextFollowUpStep1' );
                //IF there are auto follow-up steps for the campaign we'll process them here
                if (!camp.Auto_Follow_Ups__r.isEmpty()) {
                    system.debug('****transitionToNextFollowUpStep2' );
                    //Getting the current and next auto follow-up steps
                    Auto_Follow_Up__c afu = getCurrentFollowUpStep(cm, camp.Auto_Follow_Ups__r);
                    system.debug('****transitionToNextFollowUpStep3'+ afu);
                    // start Fix for SDR leads without any prior activity SAL-2344 
                    //if(afu != null && mapIdLeadRecds.get(l.id).tasks == null) return cm;
                    // end Fix for SDR leads without any prior activity SAL-2344 
                    Boolean tasksAreCleared = tasksAreClear(camp, l);
                    system.debug('****transitionToNextFollowUpStep4'+ tasksAreCleared);
                    if (tasksAreCleared) {
                        Auto_Follow_Up__c nextAfu = cm.CurrentAutoFollowUpStep__c != null ? getNextAutoFollowUpStep(cm, afu, camp.Auto_Follow_Ups__r) : afu;
                        progressCampaignMemberToNextAutoFollowUpStep(cm, cmOld, afu, nextAfu);
                        system.debug('****transitionToNextFollowUpStep5'+ !cm.AutoFollowUpsCompleted__c );
                        Task t;
                        if (!cm.AutoFollowUpsCompleted__c && (g_cm_attemptedClear.contains(cm.Id) || cm.fml_FollowUpTaskNeeded__c || (afu != null && (Trigger.isInsert || cmOld.CurrentAutoFollowUpStep__c == null || fieldChanged(cm, cmOld, 'CurrentAutoFollowUpStep__c'))))) t = createNewTaskFromCampaignMember(cm, nextAfu);
                        if (g_cm_attemptedClear.contains(cm.Id)) g_cm_attemptedClear.remove(cm.Id);
                        if (t != null) g_cm_TasksToInsertMap.put(t.WhoId, t);
                    }
                    if (cm.CurrentAutoFollowUpStep__c == null && !cm.AutoFollowUpsCompleted__c && l.Tasks.size() == 1 && !tasksAreCleared && afu != null) cm.CurrentAutoFollowUpStep__c = afu.Id;
                }
            }
        }
        
        return cm;
    }
    
    /**
    * @description This function will check if the tasks are clear for this campaign, and if they are auto follow up
    * from another campaign other than the one passed, they'll be flagged for removal.
    *
    * @param camp      The campaign to validate against
    * @param l         The lead
    *
    * @return      If there are no open tasks for the current campaign
    */
    private Boolean tasksAreClear(Campaign camp, Lead l) {
        Boolean returnVal = l == null || l.Activities__r.isEmpty() && l.Tasks.isEmpty();
        Set<Id> tasks2Del = new Set<Id>();
        
        if (l != null) {
            for (LookedUpFromActivity t : l.Activities__r) if ((t.fml_PrimaryAccountCampaign__c != camp.Name || t.fml_Auto_Follow_Up_Campaign_Name__c != camp.Name) && t.AutoFollowUp__c != null && l.fml_PrimaryAccountCampaignName__c == l.fml_CampaignName__c) tasks2Del.add(t.Id);
            for (Task t : l.Tasks) if ((t.fml_PrimaryAccountCampaign__c != camp.Name || t.fml_Auto_Follow_Up_Campaign_Name__c != camp.Name) && t.AutoFollowUp__c != null && l.fml_PrimaryAccountCampaignName__c == l.fml_CampaignName__c) tasks2Del.add(t.Id);
        }
        g_cm_tasksToDelete.addAll(tasks2Del);
        
        return !returnVal ? tasks2Del.size() == (l.Tasks.size() + l.Activities__r.size()) : returnVal;
    }
    
    /**
    * @description     Will check if the open tasks need to be deleted
    *
    * @param cm        The triggered record
    * @param cmOld     The previous version of the triggered record
    */
    private void setOpenTasksToBeDeleted(CampaignMember cm, CampaignMember cmOld) {
        
        Lead l = (Lead) g_cm_WhoIdToWhoObjectMap.get(cm.LeadId);
        
        if (l != null && l.Tasks != null && !l.Tasks.isEmpty() && shouldDeleteTasks(cm, cmOld)){
            
            g_cm_tasksToDelete.addAll(new Map<Id, Task>(l.Tasks).keySet());
        }
    }
    
    /**
    * @description     Checks if the open tasks should be deleted because the campaign member has been completed
    *
    * @param cm        The triggered record
    * @param cmOld     The previous version of the triggered record
    *
    * @return          If the tasks should be deleted
    */
    private Boolean shouldDeleteTasks(CampaignMember cm, CampaignMember cmOld) {
        
        return fieldChanged(cm, cmOld, 'AutoFollowUpsCompleted__c');
        //&& cm.AutoFollowUpsCompleted__c ;
    }
    
    private Boolean fieldChanged(SObject so, SObject soOld, String field) {
        return soOld == null || (so.get(field) != soOld.get(field));
    }
    
    /**
    * @description     This function will progress the campaign member record to the next auto follow-up step. If there
    * is not one, then it will be flagged as having all of the auto follow-up tasks completed.
    *
    * @param cm        The triggered record
    * @param cmOld     The previous version of the triggered record
    * @param afu       The current auto follow-up record
    * @param nextAfu   The next auto follow-up record
    *
    * @return          The updated campaign member record
    */
    private CampaignMember progressCampaignMemberToNextAutoFollowUpStep(CampaignMember cm, CampaignMember cmOld, Auto_Follow_Up__c afu, Auto_Follow_Up__c nextAfu) {
        
        //If the next auto follow-up step is null and the current auto follow up step is not null, that means the auto follow-up campaign is finished
       if (cm.CurrentAutoFollowUpStep__c != null && afu == nextAfu && !cm.AutoFollowUpsCompleted__c) {
            cm.AutoFollowUpsCompleted__c = true;
            g_cm_LeadsToUpdate.put(cm.LeadId, new Lead(Id = cm.LeadId, Status=sdrProspectingSettings.LeadClosedStatus__c, Lead_Outcome__c=sdrProspectingSettings.LeadCloseOutcome__c));
        }
        
        if (cm.CurrentAutoFollowUpStep__c == null || (afu != null && nextAfu != null && afu != nextAfu)) {
            cm.DateofLastStepTransition__c = Date.today();
            cm.DateTimeOfLastTransition__c = System.now();
            cm.CurrentAutoFollowUpStep__c = nextAfu.Id;
            cm.DaysUntilNextTransition__c = nextAfu.DefaultDaysUntilNextFollowup__c;
            cm.HoursUntilNextTransition__c = nextAfu.DefaultHoursUntilNextFollowUp__c;
         }
        
        return cm;
    }
    
    /**
    * @description This function will determine if a campaign needs to be set to auto follow up complete based on its
    * leads and if the auto follow up steps are completed, then the campaign member status and date of last transition
    * will be set to responded and today respectively.
    *
    * @param cm    The triggered record
    * @param cmOld The previous version of the triggered record
    *
    * @return      The updated campaign member
    */
    private CampaignMember updateCampaignMemberStatus(CampaignMember cm, CampaignMember cmOld) {
        
        if (cm.CurrentAutoFollowUpStep__c != null && !cm.AutoFollowUpsCompleted__c && cm.fml_LeadOutcomeDate__c != null && String.isNotBlank(cm.fml_LeadOutcome__c)) cm.AutoFollowUpsCompleted__c = true;
        
        if (cm.AutoFollowUpsCompleted__c && (cmOld == null || cm.AutoFollowUpsCompleted__c != cmOld.AutoFollowUpsCompleted__c)) cm.DateofLastStepTransition__c = Date.today();
        
        cm.Status = cm.AutoFollowUpsCompleted__c && !cm.HasResponded && g_cm_campaignMap.get(cm.CampaignId) != null ? g_cm_campaignMap.get(cm.CampaignId).CampaignMemberStatuses[0].Label : cm.Status;
        
        return cm;
    }
    
    /**
    * @description This function will remove campaign members if needed
    *
    * @param cm    The triggered record
    */
    private void removeExistingCampaignMembersIfNeeded(CampaignMember cm) {
        if (Trigger.isInsert) {
            
            Lead l = (Lead) g_cm_WhoIdToWhoObjectMap.get(cm.LeadId);
            // Code starts for Marketo fix SAL-2786
            Contact Con = (Contact) g_cm_WhoIdToWhoObjectMap.get(cm.ContactId);
            List<CampaignMember> CMList = new List<CampaignMember>();
            if( l !=null){
                CMList = l.CampaignMembers;
            }
            if( Con !=null){
                CMList = Con.CampaignMembers;
            }
            for (CampaignMember cmc : CMList) {
                // Code ends for Marketo fix SAL-2786
                
                if (cm.Id != cmc.Id) {
                    
                    Boolean exclude = false;
                    for (String camp2Exclude : campaignNamesToExcludeFromRemoval) {
                        
                        exclude = cmc.Campaign.Name.containsIgnoreCase(camp2Exclude);
                        
                        if (exclude) break;
                    }
                    
                    if (!exclude) g_cm_cmsToRemove.add(cmc.Id);
                }
            }
        }
    }
    
    /**
    * @description This function will retrieve the current follow up step record
    *
    * @param cm    The triggered record
    * @param afus  The list of all auto follow-up records
    *
    * @return      The auto follow-up record
    */
    private Auto_Follow_Up__c getCurrentFollowUpStep(CampaignMember cm, List<Auto_Follow_Up__c> afus) {
        
        Integer currentStep = Integer.valueOf(cm.fml_CurrentStepNumber__c);
        
        Auto_Follow_Up__c afu = cm.CurrentAutoFollowUpStep__c == null ? afus[0] : null;
        //Getting the current record based on the defined step
        afu = afu == null && currentStep <= afus.size() ?
            afus[currentStep -1] : afu;
        
        return afu;
    }
    
    /**
    * @description This function will retrieve the next follow up step record
    *
    * @param cm    The triggered record
    * @param afu   The current auto follow-up record
    * @param afus  The list of all auto follow-up records
    *
    * @return      The next auto follow-up step
    */
    private Auto_Follow_Up__c getNextAutoFollowUpStep(CampaignMember cm, Auto_Follow_Up__c afu, List<Auto_Follow_Up__c> afus) {
        
        Integer stepNumber = afu != null ? Integer.valueOf(afu.StepNumber__c) : null;
        Auto_Follow_Up__c nextAfu = afu != null && stepNumber < afus.size() ?
            afus[stepNumber] : afu;
        //If there is no current step defined and the first step has a 0 day follow up it
        //needs to be pushed to the next record
        nextAfu = afu != null && nextAfu != null && afu.Id == nextAfu.Id && cm.CurrentAutoFollowUpStep__c == null && afu.DefaultDaysUntilNextFollowup__c == 0 && afus.size() > 2 ?
            afus[1] : nextAfu;
        return nextAfu;
    }
    
    /**
    * @description This function will construct a task from the campaign member and auto follow-up task
    *
    * @param cm    The triggered record
    * @param afu   The auto follow-up record
    *
    * @return      The constructed task
    */
    private Task createNewTaskFromCampaignMember(CampaignMember cm, Auto_Follow_Up__c afu) {
        
        Task returnRec = new Task();
        returnRec.WhoId = cm.ContactId != null ? cm.ContactId : cm.LeadId;
        if (cm.ContactId == null) returnRec.Lead__c = cm.LeadId;
        returnRec.PrimaryAccount__c = cm.fml_AccountId__c;
        returnRec.Subject = afu != null ? afu.TaskSubject__c : 'Auto Follow-Up';
        returnRec.Description = afu != null ? afu.TaskComment__c : '';
        // Commenting the below line since we need to consider Nextfollowup date mentioned in the campaign member for SAL-2623
        Date activityDate = defaultBh.Id == null ? Date.today() : BusinessHours.isWithin(defaultBh.Id, System.now()) ? Date.today() : BusinessHours.nextStartDate(defaultBh.Id, System.now()).date();
        //returnRec.ActivityDate = defaultBh.Id == null ? Date.today() : BusinessHours.isWithin(defaultBh.Id, System.now()) ? Date.today() : BusinessHours.nextStartDate(defaultBh.Id, System.now()).date();
        // Code starts(Commenting the below line since we need to consider Nextfollowup date mentioned in the campaign member for SAL-2623)
        //returnRec.ActivityDate = activityDate.addDays(Integer.valueOf(afu.DefaultDaysUntilNextFollowup__c));
        returnRec.ActivityDate = activityDate;
        //returnRec.ActivityDate = activityDate.System.now(s)(Integer.valueOf(afu.fml_DefaultHoursUntilNextFollowup__c));
        // Code ends
        returnRec.AutoFollowUp__c = afu != null ? afu.Id : null;
        Id memberOwnerId = Id.valueOf(cm.fml_MemberOwnerId__c);
        returnRec.OwnerId = definedUsers.containsKey(memberOwnerId) ? cm.fml_MemberOwnerId__c : defaultOwner;
        
        return returnRec;
    }
    
    /**
    * @description This is where all queries should be called
    */
    private class TC_CampaignMemberHelperGateway {
        
    /**
    * @description         This function will query the campaign object and get the campaign and related child records
    *
    * @param campaignIds   The campaign Id's to query
    *
    * @return              The map of campaign records with their child records
    */
        public Map<Id, Campaign> getCampaignAndChildrenMap(Set<Id> campaignIds) {
            
            return new Map<Id, Campaign> ([
                SELECT Id, Name,
                (SELECT Id, StepNumber__c, Campaign__c, TaskComment__c, TaskSubject__c, PreviousAutoFollowUp__c, DefaultDaysUntilNextFollowup__c, DefaultHoursUntilNextFollowUp__c FROM Auto_Follow_Ups__r ORDER BY StepNumber__c),
                (SELECT Id, Label FROM CampaignMemberStatuses WHERE HasResponded = TRUE)
                FROM Campaign
                WHERE Id IN :campaignIds
            ]);
        }
        
        public Map<Id, SObject> getWhoIdMap(Set<Id> whoIds) {
            Map<Id, SObject> returnMap = new Map<Id, SObject>();
            String taskQuery = 'SELECT Id, fml_PrimaryAccountCampaign__c, AutoFollowUp__c, WhoId, TargetDateTime__c, fml_Auto_Follow_Up_Campaign_Name__c FROM {0} WHERE IsClosed = FALSE AND AutoFollowUp__c <> NULL';
            
            returnMap.putAll(new Map<Id, SObject>(Database.query('SELECT Id, fml_CampaignName__c, fml_PrimaryAccountCampaignName__c, (SELECT Id, CampaignId, CurrentAutoFollowUpStep__c, Campaign.Name, DateTimeOfLastTransition__c, HoursUntilNextTransition__c FROM CampaignMembers WHERE CurrentAutoFollowUpStep__c <> null ORDER BY LastModifiedDate DESC), ('+String.format(taskQuery, new List<String>{'Tasks'})+'), ('+String.format(taskQuery, new List<String>{'Activities__r'})+') FROM Lead WHERE Id IN :whoIds')));
            returnMap.putAll(new Map<Id, SObject>(Database.query('SELECT Id, (SELECT Id, CampaignId, CurrentAutoFollowUpStep__c, Campaign.Name, DateTimeOfLastTransition__c, HoursUntilNextTransition__c FROM CampaignMembers WHERE CurrentAutoFollowUpStep__c <> null ORDER BY LastModifiedDate DESC), ('+String.format(taskQuery, new List<String>{'Tasks'})+') FROM Contact WHERE Id IN :whoIds')));
            
            return returnMap;
        }
        
        public BusinessHours getBusinessHours() {
            List<BusinessHours> bhs = [SELECT Id, IsActive, Name, IsDefault FROM BusinessHours WHERE IsActive = true AND IsDefault = true LIMIT 1];
            Time eightAm = Time.newInstance(8, 0, 8, 0);
            Time fivePm = Time.newInstance(5, 0, 8, 0);
            if (bhs.isEmpty()) bhs.add(new BusinessHours(MondayStartTime=eightAm,TuesdayStartTime=eightAm,WednesdayStartTime=eightAm,ThursdayStartTime=eightAm,FridayStartTime=eightAm,MondayEndTime=fivePm,TuesdayEndTime=fivePm,WednesdayEndTime=fivePm,ThursdayEndTime=fivePm, FridayEndTime=fivePm,IsActive=true,Name='Default',IsDefault=true,TimeZoneSidKey='America/New_York'));
            return bhs[0];
        }
        
        public Map<Id, Task> getOpenTaskMap(Set<String> extIdsToDelete, Set<Id> whoIds) {
            return new Map<Id, Task> ([
                SELECT Id FROM Task WHERE IsClosed = FALSE AND (Lead__c IN :whoIds OR WhoId IN :whoIds) AND fml_CampaignAndWho__c IN :extIdsToDelete
            ]);
        }
    }
    
    /**
    * @description This function will update the days until next transition field if it's null to match the default from
    * the auto follow up step
    *
    * @param cm    The triggered record
    *
    * @return      The updated record
    */
    private CampaignMember updateDaysUntilNextTransition(CampaignMember cm) {
        if (cm.DaysUntilNextTransition__c == null && !cm.AutoFollowUpsCompleted__c && cm.CurrentAutoFollowUpStep__c != null) cm.DaysUntilNextTransition__c = cm.fml_DefaultDaysUntilNextFollowup__c;
        if (cm.HoursUntilNextTransition__c == null && !cm.AutoFollowUpsCompleted__c && cm.CurrentAutoFollowUpStep__c != null) cm.HoursUntilNextTransition__c = cm.fml_DefaultHoursUntilNextFollowup__c;
        
        return cm;
    }
    
    private Boolean shouldAddCampaignToQuery(CampaignMember cm, CampaignMember cmOld) {
        return !g_cm_campaignMap.containsKey(cm.CampaignId) && ((cm.CurrentAutoFollowUpStep__c == null && cm.fml_Campaign_Num_Auto_Follow_up_Steps__c > 0) || (!cm.AutoFollowUpsCompleted__c && ((cm.fml_LeadOutcomeDate__c != null && String.isNotBlank(cm.fml_LeadOutcome__c)) || cm.CurrentAutoFollowUpStep__c == null || cm.fml_FollowUpTaskNeeded__c)) || (cm.AutoFollowUpsCompleted__c && !cm.HasResponded));
    }
}