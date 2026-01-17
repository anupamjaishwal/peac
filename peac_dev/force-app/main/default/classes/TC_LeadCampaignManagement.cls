/**
 * @description This function will handle the transition from one campaign to another if applicable
 * @see         SAL-1868
 */
public without sharing class TC_LeadCampaignManagement implements TC_TriggerActionI{

    private static Map<String, Campaign> campaignMap {
        get {
            if (campaignMap == null) campaignMap = new Map<String, Campaign>();
            return campaignMap;
        }
        set;
    }
    
    private Map<String, CampaignMember> leadIdToCM {
        get {
            if (this.leadIdToCM == null) this.leadIdToCM = new Map<String, CampaignMember>();
            return this.leadIdToCM;
        }
        set;
    }
    
    private Map<Id, CampaignMember> cmsToUpsert {
        get {
            if (this.cmsToUpsert == null) this.cmsToUpsert = new Map<Id, CampaignMember>();
            return this.cmsToUpsert;
        }
        set;
    }
    
    private static Set<Id> cmsToDelete {
        get {
            if (cmsToDelete == null) cmsToDelete = new Set<Id>();
            return cmsToDelete;
        }
        set;
    }

    private static Map<Id, Task> tasksToDelete {
        get {
            if (tasksToDelete == null) tasksToDelete = new Map<Id, Task>();
            return tasksToDelete;
        }
        set;
    }

    private static Map<Id, Id> campaignRemoved {
        get {
            if (campaignRemoved == null) campaignRemoved = new Map<Id, Id>();
            return campaignRemoved;
        }
        set;
    }
    
    private static Map<Id, Account> accountMap {
        get {
            if (accountMap == null) accountMap = new Map<Id, Account>();
            return accountMap;
        }
        set;
    }

    private Map<Id, Lead> leadsWithChildren {
        get {
            if (leadsWithChildren == null) leadsWithChildren = new Map<Id, Lead>();
            return leadsWithChildren;
        }
        set;
    }
    
    // commented chatter notification for SAL-3329
    /*private static Map<String, ConnectApi.BatchInput> chatterNotificationsToBeSent {
        get {
            if (chatterNotificationsToBeSent == null) chatterNotificationsToBeSent = new Map<String, ConnectApi.BatchInput>();
            return chatterNotificationsToBeSent;
        }
        set;
    } */

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

    public void doAction(TC_TriggerContext tc) {

        List<Lead> newLs = tc.getNewList() == null ? (List<Lead>) tc.getOldMap().values() : tc.getNewList();
        List<Lead> oldLs = tc.getOldMap() == null ? null : tc.getOldMap().values();
        if (tc.isBefore()) {
            bulkBefore(newLs, oldLs);
            processBefore(newLs, oldLs);
        }

        if (tc.isAfter()) {
            bulkAfter(newLs, oldLs);
            processAfter(newLs, oldLs);
            andFinallyAfter();
        }
    }

    /**
     * @description     This function will process the bulk changes to the records and do any fills that are needed
     *
     * @param newList   The triggered records
     * @param oldList   The previous versions of the triggered records
     */
    private void bulkBefore(List<Lead> newList, List<Lead> oldList) {
        Map<Id, Lead> oldMap = oldList != null ? new Map<Id, Lead> (oldList) : null;

        for (Lead l : newList == null ? oldMap.values() : newList) {
            Lead lOld = oldMap == null ? null : oldMap.get(l.Id);
            if (bulkBeforeQueryCheck(l, lOld)) {
                bulkBeforeCampaignQueryCheck(l);
                bulkBeforeAccountQueryCheck(l, lOld);
            }
        }

        if (queryCampaigns()) campaignMap.putAll(getCampaignsByName(campaignMap.keySet()));
        if (!accountMap.isEmpty()) accountMap = new Map<Id, Account>(queryAccounts(accountMap.keySet()));
    }

    /**
     * @description     This function will process the bulk changes to the records and do any fills that are needed
     *
     * @param newList   The triggered records
     * @param oldList   The previous versions of the triggered records
     */
    private void bulkAfter(List<Lead> newList, List<Lead> oldList) {
        Map<Id, Lead> oldMap = oldList != null ? new Map<Id, Lead> (oldList) : null;

        for (Lead l : newList == null ? oldMap.values() : newList) {
            Lead lOld = oldMap != null ? oldMap.get(l.Id) : null;
            if (fieldDiff(l, lOld, 'Lead_Outcome__c') || fieldDiff(l, lOld, 'CurrentCampaign__c') || l.Opportunity_Record_ID__c != null || l.fml_PrimaryAccountHasOppInDecision__c) leadsWithChildren.put(l.Id, null);
        }
        System.debug(leadsWithChildren.keySet());

        if (!leadsWithChildren.isEmpty()) leadsWithChildren = new Map<Id, Lead> (queryLeadsWithChildren(leadsWithChildren.keySet()));

        System.debug(JSON.serializePretty(leadsWithChildren.values()));
    }

    /**
     * @description     This function will process the before actions
     *
     * @param newList   The triggered records
     * @param oldList   The previous version of the triggered records
     */
    private void processBefore(List<Lead> newList, List<Lead> oldList) {
        Map<Id, Lead> oldMap = oldList != null ? new Map<Id, Lead> (oldList) : null;

        for (Lead l : newList == null ? oldMap.values() : newList) {
            Lead lOld = oldMap == null ? null : oldMap.get(l.Id);
            reAssignCampaign(l);
            setOppOwnerId(l);
            reAssignLeadOrSendEmail(l, lOld);
            updateLeadIfDecisionOppPresent(l, lOld);
        }
    }

    /**
     * @description     This function will process the after actions
     *
     * @param newList   The triggered records
     * @param oldList   The previous version of the triggered records
     */
    private void processAfter(List<Lead> newList, List<Lead> oldList) {
        Map<Id, Lead> oldMap = oldList != null ? new Map<Id, Lead> (oldList) : null;

        for (Lead l : newList == null ? oldMap.values() : newList) {
            Lead lOld = oldMap != null ? oldMap.get(l.Id) : null;
            doCampaignMemberCheck(l, lOld);
        }
    }

    /**
     * @description does the final actions for the class
     */
    private void andFinallyAfter() {
        try {
            //SAL-2014 - Deleting the tasks if needed
            if (!tasksToDelete.isEmpty()) {
                List<Task> tmp = new List<Task>(tasksToDelete.values());
                tasksToDelete = null;
                System.debug(JobSequenceUtilities.handleDynamicDeletes(tmp,false,false));
            }

            if (!cmsToDelete.isEmpty()) {
                List<Id> ids2Delete = new List<Id>(cmsToDelete);
                cmsToDelete = null;
                Database.delete(ids2Delete, false);
            }

            if (!cmsToUpsert.isEmpty()) System.debug(JobSequenceUtilities.handleDynamicUpsert(cmsToUpsert.values(), 'ExternalId__c'));

            // commented chatter notification for SAL-3329
            /* if (!chatterNotificationsToBeSent.isEmpty()) {
                List<ConnectApi.BatchInput> chatterNotifications = new List<ConnectApi.BatchInput>(chatterNotificationsToBeSent.values());
                chatterNotificationsToBeSent = null;
                if (!Test.isRunningTest()) {
                System.debug(ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(),chatterNotifications));
                }
           } */
        } catch (Exception e) {
            System.debug(e);
        }
    }

    /**
     * @description Checks if the account primary account for the lead needs to be queried
     *
     * @param l     The triggered record
     * @param lOLd  The previous version of the triggered record
     */
    private void bulkBeforeAccountQueryCheck(Lead l, Lead lOLd) {
        if (l.PrimaryAccount__c != null && !accountMap.containsKey(l.PrimaryAccount__c)) {
            if (String.isNotBlank(l.Primary_Source__c) && String.isBlank(l.Lead_Outcome__c) && fieldDiff(l, lOld, 'Primary_Source__c')) accountMap.put(l.PrimaryAccount__c, null);
            if (String.isNotBlank(l.Lead_Outcome__c) && fieldDiff(l, lOld, 'Lead_Outcome__c')) accountMap.put(l.PrimaryAccount__c, null);
        }
    }

    /**
     * @description This function will check if a campaign query is needed for the campaigns related to the lead
     *
     * @param l     The triggered record
     */
    private void bulkBeforeCampaignQueryCheck(Lead l) {
        if (l.fml_CampaignName__c != null && !campaignMap.containsKey(l.fml_CampaignName__c)) campaignMap.put(l.fml_CampaignName__c, null);
        if (l.fml_PrimaryAccountCampaignName__c != null && !campaignMap.containsKey(l.fml_PrimaryAccountCampaignName__c)) campaignMap.put(l.fml_PrimaryAccountCampaignName__c, null);
        if (!campaignMap.containsKey('Digital')) campaignMap.put('Digital', null);
    }

    /**
     * @description This function will re-assign the lead or send an email to the opportunity owner if applicable
     * @see         SAL-2003
     *
     * @param l     The triggered record
     * @param lOld  The previous version of the triggered record
     *
     * @return      The updated record
     */
    private Lead reAssignLeadOrSendEmail(Lead l, Lead lOld) {
        System.debug(l.PrimaryAccount__c != null && String.isNotBlank(l.Primary_Source__c));
        System.debug(fieldDiff(l, lOld, 'Primary_Source__c') && String.isNotBlank(l.Primary_Source__c) && l.Primary_Source__c.containsIgnoreCase('Digital'));
        if (l.PrimaryAccount__c != null && String.isNotBlank(l.Primary_Source__c) &&
            fieldDiff(l, lOld, 'Primary_Source__c') && l.Primary_Source__c.containsIgnoreCase('Digital')
        ) {
            Account acct = accountMap.get(l.PrimaryAccount__c);
            System.debug(acct.Opportunities.size());
            for (Opportunity opp : acct.Opportunities) {
                String key = acct.Id + '' + opp.OwnerId;
                //if(opp.Owner.isActive){
                 l.PrimaryAccountMostRecentOppOwner__c = opp.OwnerId; 
                // commented chatter notification for SAL-3329
                // if (opp.RecordType.Name.contains('Express')) l.OwnerId = opp.OwnerId;
                //}  
                //else{
                //   l.PrimaryAccountMostRecentOppOwner__c = l.OwnerId;
                // } 
               // commented chatter notification for SAL-3329
              // if (!chatterNotificationsToBeSent.containsKey(key) && !Test.isRunningTest()) chatterNotificationsToBeSent.put(key, new ConnectApi.BatchInput(ConnectApiHelper.postFeedItemWithMentions(Network.getNetworkId(),opp.Id,String.format(Label.Opportunity_Owner_New_Lead_Chatter_Notification_Text,new List<String>{'{'+opp.OwnerId+'}'}))));
             }
        }

        return l;
    }

    /**
     * @description This function will set the opp owner id
     *
     * @param l     The triggered record
     *
     * @return      The updated record
     */
    private Lead setOppOwnerId(Lead l) {
        l.PrimaryAccountMostRecentOppOwner__c = l.PrimaryAccountMostRecentOppOwner__c == null ? l.fml_PrimaryAccountMostRecentOppOwnerId__c : l.PrimaryAccountMostRecentOppOwner__c;
        return l;
    }

    /**
     * @description This function will re assign the lead to a new campaign  (if applicable)
     * @see         SAL-1868
     *
     * @param l     The triggered record
     *
     * @return      The updated record
     */
    private Lead reAssignCampaign(Lead l) {
        if (String.isBlank(l.Opportunity_Record_ID__c)) {
            if (l.fml_PrimaryAccountCampaignName__c != l.fml_CampaignName__c && campaignMap.get(l.fml_PrimaryAccountCampaignName__c) != null) l.CurrentCampaign__c = campaignMap.get(l.fml_PrimaryAccountCampaignName__c).Id;
            if (String.isNotBlank(l.Primary_Source__c) && l.Primary_Source__c.containsIgnoreCase('Digital') && campaignMap.get('Digital') != null) l.CurrentCampaign__c = campaignMap.get('Digital').Id;
        }

        if ((String.isNotBlank(l.fml_PrimaryAccountCampaignName__c) || l.fml_CampaignName__c == 'Digital') && String.isNotBlank(l.Opportunity_Record_ID__c)) l.CurrentCampaign__c = null;

        return l;
    }

    /**
     * @description This function will check if there is a need for a bulk before query
     *
     * @param l     The triggered record
     * @param lOld  The previous version of the triggered record
     *
     * @return      If a bulk before query is needed
     */
    private Boolean bulkBeforeQueryCheck(Lead l, Lead lOld) {
        return  l.fml_CampaignName__c != l.fml_PrimaryAccountCampaignName__c ||
                (String.isNotBlank(l.fml_CampaignName__c) && (l.LastActivityDate == null) ||
                l.Opportunity_Record_ID__c != null ||
                fieldDiff(l, lOld, 'Lead_Outcome__c'));
    }

    /**
     * @description     Query the accounts
     *
     * @param acctIds   The account Ids to query
     *
     * @return          THe queried accounts
     */
    private List<Account> queryAccounts(Set<Id> acctIds) {
        return [
                SELECT  Id, MostRecentOpportunity__c, MostRecentOpportunity__r.RecordType.Name,
                        MostRecentOpportunity__r.IsClosed, MostRecentOpportunity__r.OwnerId,
                        (SELECT     Id, RecordType.Name, IsClosed, OwnerId,Owner.isActive, StageName, Application_Status__c
                         FROM       Opportunities
                         WHERE      NOT(StageName IN :Label.Opportunity_Closed_Application_Statuses.split(',') AND fml_Owner_Is_Active_And_SDR__c = TRUE)
                         ORDER BY   CreatedDate)
                FROM    Account
                WHERE   Id IN :acctIds
        ];
    }

    /**
     * @description     Queries the leads with children
     * @see             SAL-2014
     *
     * @param leadIds   The lead Ids to be queried
     *
     * @return          The list of queried leads
     */
    private List<Lead> queryLeadsWithChildren(Set<Id> leadIds) {
        return [
                SELECT  Id,
                        (SELECT Id, CampaignId, Campaign.Name, ExternalId__c, CurrentAutoFollowUpStep__c, AutoFollowUpsCompleted__c
                         FROM   CampaignMembers
                         WHERE  AutoFollowUpsCompleted__c = FALSE),
                        (SELECT Id
                         FROM   Tasks
                         WHERE  IsClosed = FALSE AND AutoFollowUp__c <> NULL)
                FROM    Lead
                WHERE   Id IN :leadIds
        ];
    }

    /**
     * @description This function will do a campaign member check, if one doesn't already exist for the new campaign,
     * then one will be constructed for insertion later
     * @see         SAL-1868
     *
     * @param l     The triggered record
     * @param lOld  The previous version of the triggered record
     */
    private void doCampaignMemberCheck(Lead l, Lead lOld) {
        if (l.CurrentCampaign__c != null || (lOld != null && lOld.CurrentCampaign__c != null)) {
            CampaignMember currentCm = processCampaignMembers(l, lOld);
            if (currentCm != null) {
                Id upsertKey = currentCm.Id == null ? l.Id : currentCm.Id;
                if (currentCm != null && l.fml_PrimaryAccountHasOppInDecision__c) cmsToUpsert.put(upsertKey, currentCm);
                if (l.CurrentCampaign__c != null && String.isBlank(currentCm.ExternalId__c)) currentCm.ExternalId__c = l.CurrentCampaign__c + '' + l.Id;
                //If the current auto follow up is blank but the auto follow up is not complete, we'll want to flag it for an update
                if (currentCm.CurrentAutoFollowUpStep__c == null && !currentCm.AutoFollowUpsCompleted__c) cmsToUpsert.put(upsertKey, currentCm);
                //SAL-1997 - adding a CM update if the lead outcome changes or the opportunity record Id is not null
                if (!cmsToDelete.contains(currentCm.Id) && (String.isNotBlank(l.Lead_Outcome__c) || l.Opportunity_Record_ID__c != null)) cmsToUpsert.put(upsertKey, currentCm);
            }
        }
        System.debug(JSON.serializePretty(cmsToUpsert));
    }

    /**
     * @description This function will process the campaign members related to this lead. It will delete any that do not
     * match its current campaign, set the auto follow up complete status to true if there is an opp Id or lead out come
     * @see         SAL-2014
     *
     * @param l     The triggered record
     * @param lOld  The previous version of the triggered record
     *
     * @return      The campaign member
     */
    private CampaignMember processCampaignMembers(Lead l, Lead lOld) {
        CampaignMember returnVal;
        CampaignMember digitalCm;
        if (leadsWithChildren.get(l.Id) != null) {
            System.debug(leadsWithChildren.get(l.Id).CampaignMembers);
            for (CampaignMember cm : leadsWithChildren.get(l.Id).CampaignMembers) {
                System.debug(cm);
                if (cm.Campaign.Name == 'Digital') digitalCm = cm;
                if (cm.CampaignId == l.CurrentCampaign__c) returnVal = cm;
                if (returnVal == null && digitalCm != null && l.fml_PrimaryAccountHasOppInDecision__c) returnVal = cm;
                if (fieldDiff(l, lOld, 'CurrentCampaign__c') && cm.CampaignId != l.CurrentCampaign__c) cmsToDelete.add(cm.Id);
            }
        }

        if (digitalCm != null && l.Opportunity_Record_ID__c != null) cmsToDelete.add(digitalCm.Id);
        if (returnVal != null) {
            //SAL-2034
            if (l.fml_PrimaryAccountHasOppInDecision__c) returnVal.AutoFollowUpsCompleted__c = true;
            if (returnVal.Id == null || !cmsToDelete.contains(returnVal.Id)) returnVal = createCampaignMember(l, returnVal);
            if (leadsWithChildren.get(l.Id) != null &&
                (returnVal.AutoFollowUpsCompleted__c ||
                (returnVal.Id != null && cmsToDelete.contains(returnVal.Id)))) {
                tasksToDelete.putAll(new Map<Id, Task>(leadsWithChildren.get(l.Id).Tasks));
            }
        }
        if (returnVal == null && l.CurrentCampaign__c != null && String.isBlank(l.Lead_Outcome__c) && l.Opportunity_Record_ID__c == null) returnVal = createCampaignMember(l, returnVal);

        return returnVal;
    }

    /**
     * @description     This function will construct a campaign member. It will use the lead and current campaign
     * member to construct a campaign member
     * @see             SAL-2014
     *
     * @param l         The triggered record
     * @param currentCm The current campaign member
     *
     * @return          The constructed campaign member
     */
    private CampaignMember createCampaignMember(Lead l, CampaignMember currentCm) {
        CampaignMember cm = new CampaignMember();

        if (currentCm != null && currentCm.Id != null) {
            cm.Id = currentCm.Id;
            cm.CurrentAutoFollowUpStep__c = currentCm.CurrentAutoFollowUpStep__c;
        }

        if (currentCm == null || currentCm.Id == null) {
            cm.CampaignId = l.CurrentCampaign__c;
            cm.LeadId = l.Id;
        }

        if (currentCm == null || String.isBlank(currentCm.ExternalId__c)) cm.ExternalId__c = l.CurrentCampaign__c + '' + l.Id;
        if (l.Opportunity_Record_ID__c != null || String.isNotBlank(l.Lead_Outcome__c)) cm.AutoFollowUpsCompleted__c = true;

        return cm;
    }

    /**
     * @description     This function will get campaigns by name
     *
     * @param campNames The campaigns to query
     *
     * @return          The list of campaigns
     */
    private Map<String, Campaign> getCampaignsByName(Set<String> campNames) {
        Map<String, Campaign> returnMap = new Map<String, Campaign>();

        for (Campaign camp : [
                SELECT Id, Name
                FROM Campaign
                WHERE Name IN :campNames]) {
            returnMap.put(camp.Name, camp);
            returnMap.put(camp.Id, camp);
        }

        return returnMap;
    }

    /**
     * @description     Checks if the field has changed
     *
     * @param l         The triggered record
     * @param lOld      The previous version of the triggered record
     * @param fieldNm   The field to check
     *
     * @return          If the field is different
     */
    private Boolean fieldDiff(Lead l, Lead lOld, String fieldNm) {
        return lOld == null || (l.get(fieldNm) != lOld.get(fieldNm));
    }

    /**
     * @description This function determines whether or not to query campaigns
     *
     * @return      If campaigns should be queried
     */
    private Boolean queryCampaigns() {
        Boolean returnVal = false;

        for (String key : campaignMap.keySet()) {
            if (campaignMap.get(key) == null) returnVal = true;
            if (returnVal) break;
        }

        return returnVal;
    }

    /**
     * @description This function will process the lead if there is an opportunity in a stage of decision
     * @see         SAL-2034
     *
     * @param l     The triggered record
     * @param lOld  The previous version of the triggered record
     *
     * @return      The updated lead
     */
    private Lead updateLeadIfDecisionOppPresent(Lead l, Lead lOld) {
        system.debug('======new lead'+ l);
        system.debug('======PrimaryAccountHasOppInDecision'+ l.fml_PrimaryAccountHasOppInDecision__c + l.fml_IsOpenLead__c);
        if (l.fml_PrimaryAccountHasOppInDecision__c && l.fml_IsOpenLead__c) {
           // l.Lead_Outcome__c = sdrProspectingSettings.DecisionOppOutcome__c;
            //l.Status = sdrProspectingSettings.LeadClosedStatus__c;
             l.Status = 'Prospecting';
           // l.CurrentCampaign__c = null;
        }
		system.debug('======updated lead'+ l);
        return l;
    }
}