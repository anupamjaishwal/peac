/**
 * @description This class will assist in the transition of accounts from one campaign it will also transition any
 * related leads and generate campaign members based on the transitioned state.
 * @see         SAL-1889
 */
public without sharing class TC_CampaignManagement {

    private Map<String, Set<Id>> campToAccountIdMap {
        get {
            if (this.campToAccountIdMap == null) this.campToAccountIdMap = new Map<String, Set<Id>>();
            return this.campToAccountIdMap;
        }
        set;
    }

    private Map<String, Campaign> campaignMapByName {
        get {
            if (this.campaignMapByName == null) this.campaignMapByName = new Map<String, Campaign>();
            return this.campaignMapByName;
        }
        set;
    }

    private Map<Id, Account> accountMap {
        get {
            if (this.accountMap == null) this.accountMap = new Map<Id, Account>();
            return this.accountMap;
        }
        set;
    }

    private List<Database.Error> errorsEncountered {
        get {
            if (this.errorsEncountered == null) this.errorsEncountered = new List<Database.Error>();
            return this.errorsEncountered;
        }
        set;
    }

    /**
     * @description This function will transition accounts to new campaigns where necessary
     *
     * @param scope The records that need to be processed
     *
     * @return      The errors (if any) that happened
     */
    public List<Database.Error> transitionAccountCampaign(List<SObject> scope) {

        processCampaignsFromAccountList(scope);
        processCampaigns();
        return transitionAccountsAndLeadsToNewCampaign();

    }

    /**
     * @description This function will transition the accounts and leads to a different campaign and the campaign members
     *
     * @return      Any database errors 
     */
    private List<Database.Error> transitionAccountsAndLeadsToNewCampaign() {
        List<Database.Error> returnList = errorsEncountered;
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Map<String, CampaignMember> campaignMemberMap = new Map<String, CampaignMember>();

        //Going through each campaign and getting the related accounts/leads and associating them as needed
        for (String campName : campToAccountIdMap.keySet()) {
            Campaign camp = campaignMapByName.get(campName);
            //Going through each of the accounts related to this campaign
            for (Id acctId : campToAccountIdMap.get(campName)) {
                Account acct = this.accountMap.get(acctId);//Getting 
                //If the campaign is different, setting the current Id and flagging the account for update
                if (acct.CurrentCampaign__c != camp.Id) {
                    acct.CurrentCampaign__c = camp.Id;
                    this.accountMap.put(acct.Id, acct);
                }

                //If the campaign is different on the lead, if it's different, setting
                if (acct.MostRecentLead__c != null && acct.MostRecentLead__r.CurrentCampaign__c != camp.Id) {
                    Lead l = acct.MostRecentLead__r;
                    l.CurrentCampaign__c = camp.Id;
                    leadMap.put(l.Id, l);

                    String cmExtId = camp.Id + '' + l.Id;
                    campaignMemberMap.put(cmExtId, new CampaignMember(CampaignId = camp.Id, LeadId = l.Id, ExternalId__c = cmExtId));
                }
            }
        }
        //making the DML statements needed
        returnList.addAll(JobSequenceUtilities.attemptJobSequenceDML(this.accountMap.values(), 'update',false));
        returnList.addAll(JobSequenceUtilities.attemptJobSequenceDML(leadMap.values(), 'update',false));
        try {
            returnList.addAll(JobSequenceUtilities.attemptJobSequenceDML(campaignMemberMap.values(), 'upsert','ExternalId__c', false, false));
        } catch (Exception e) {
            
        }

        
        return returnList;

    }

    /**
     * @description This function will process the campaigns 
     */
    private void processCampaigns() {
        for (Campaign camp : [SELECT Id, Name FROM Campaign WHERE Name IN :campToAccountIdMap.keySet()]) campaignMapByName.put(camp.Name, camp);

        List<Campaign> newCamps = new List<Campaign>();

        for (String campName : campToAccountIdMap.keySet()) {
            if (!campaignMapByName.containsKey(campName)) {
                Campaign camp = new Campaign(Name = campName, IsActive = true);
                newCamps.add(camp);
                campaignMapByName.put(campName, camp);
            }
        }

        Database.insert(newCamps);
    }

    /**
     * @description This function will query the accounts that are in the scope
     *
     * @param scope The records that wre processed in the batch
     *
     * @return      The list of queried accounts
     */
    private List<Account> getAccounts(List<SObject> scope) {
        return [
                SELECT  Id, Target_SDR_Campaign__c, CurrentCampaign__r.Name, MostRecentLead__c, MostRecentLead__r.Id,
                        MostRecentLead__r.CurrentCampaign__c, MostRecentLead__r.CurrentCampaign__r.Name,
                        MostRecentLead__r.Status, MostRecentLead__r.IsConverted, MostRecentLead__r.LeadOutcomeDate__c,
                        fml_DerivedCampaign__c, MostRecentLead__r.fml_LeadClosed__c
                FROM    Account WHERE Id IN :scope
        ];
    }

    /**
     * @description This function will process the campaigns from the account list
     *
     * @param scope The records to process
     */
    private void processCampaignsFromAccountList(List<SObject> scope) {
        List<Account> acctsNeedingNewLeads = new List<Account>();

        this.accountMap = new Map<Id, Account>(getAccounts(scope));

        for (Account acct : this.accountMap.values()) {

            if (String.isNotBlank(acct.fml_DerivedCampaign__c) && acct.fml_DerivedCampaign__c != acct.CurrentCampaign__r.Name) {
                Set<Id> acctIds = this.campToAccountIdMap.containsKey(acct.fml_DerivedCampaign__c) ? this.campToAccountIdMap.get(acct.fml_DerivedCampaign__c) : new Set<Id>();
                acctIds.add(acct.Id);
                this.campToAccountIdMap.put(acct.fml_DerivedCampaign__c, acctIds);
                if (TC_AccountToLead.accountNeedsNewLead(acct)) acctsNeedingNewLeads.add(acct);
            }
        }

        this.errorsEncountered.addAll(new TC_AccountToLead(acctsNeedingNewLeads).createLeadsFromAccounts());
        this.accountMap.putAll(new Map<Id, Account>(getAccounts(acctsNeedingNewLeads)));//Retrieving the accounts again  the map since they should now have a lead associated

    }
}