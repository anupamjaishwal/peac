/**
 * @description This class is responsible for transitioning accounts into a lead
 * @see         SAL-1872
 */
public without sharing class TC_AccountToLead {
    public List<SObject> scope {get;private set;}

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

    private static Boolean queueQueried {
        get {
            if (queueQueried == null) queueQueried = false;
            return queueQueried;
        }
        set;
    }

    public static Id queueId {
        get {
            if (queueId == null && !queueQueried) {
                queueQueried = true;
                List<Group> grps = [SELECT Id FROM Group WHERE Name = :sdrProspectingSettings.TaskQueueName__c AND Type = 'Queue'];
                if (!grps.isEmpty()) queueId = grps[0].Id;
            }
            return queueId;
        }
        private set;
    }

    private Map<String, Account_To_Lead_Field_Map__mdt> atlfmlMap {
        get {
            if (this.atlfmlMap == null) {
                this.atlfmlMap = new Map<String, Account_To_Lead_Field_Map__mdt>();
                for (Account_To_Lead_Field_Map__mdt atlfm : [SELECT Id, DeveloperName, IsStaticText__c, TargetFieldStaticText__c FROM Account_To_Lead_Field_Map__mdt]) {
                    String fld = atlfm.DeveloperName;
                    fld = fld.endsWith('_c') ? fld.left(fld.length()-2)+'__c' : fld;
                    this.atlfmlMap.put(fld, atlfm);
                }
            }
            return this.atlfmlMap;
        }
        set;
    }

    private Boolean fieldMapPopulated {
        get {
            if (this.fieldMapPopulated == null) this.fieldMapPopulated = false;
            return this.fieldMapPopulated;
        }
        set;
    }

    private Map<String, String> accountToLeadMap {
        get {
            if (this.accountToLeadMap == null) this.accountToLeadMap = new Map<String, String>();
            if (this.accountToLeadMap.isEmpty() && !fieldMapPopulated) populateFieldMappings();
            return this.accountToLeadMap;
        }
        set;
    }

    private Map<String, String> leadToStaticTextMap {
        get {
            if (this.leadToStaticTextMap == null) this.leadToStaticTextMap = new Map<String, String>();
            if (this.leadToStaticTextMap.isEmpty() && !fieldMapPopulated) populateFieldMappings();
            return leadToStaticTextMap;
        }
        set;
    }

    public TC_AccountToLead() {

    }

    public TC_AccountToLead(List<SObject> scope) {
        this.scope = scope;
    }

    public String accountQuery {
        get {
            if (String.isBlank(this.accountQuery)) {
                Set<String> acctFlds = new Set<String> {'Id', 'MostRecentLead__c', 'MostRecentLead__r.fml_LeadClosed__c', 'Target_SDR_Campaign__c','MostRecentLead__r.IsConverted', 'MostRecentLead__r.Status'};
                acctFlds.addAll(accountToLeadMap.keySet());
                this.accountQuery = 'SELECT '+String.join(new List<String>(acctFlds),',')+' FROM Account ';
            }

            return this.accountQuery;
        }

        set;
    }

    /**
     * @description This function will return the save results from creating the leads based on the accounts that were
     * initialized as the scope
     *
     * @return      Any errors encountered
     */
    public List<Database.Error> createLeadsFromAccounts() {
        if (scope == null) throw new TC_AccountToLeadException('No scope was defined!');

        Set<Id> acctIds = new Map<Id, SObject> (scope).keySet();

        List<Lead> newLeads = createNewLeads(acctIds);

        List<Database.Error> returnErrors = JobSequenceUtilities.attemptJobSequenceDML(newLeads, 'insert', false);
        returnErrors.addAll(JobSequenceUtilities.attemptJobSequenceDML(updateAccountWithNewLeadId(newLeads), 'update', false));

        return returnErrors;
    }

    /**
     * @description     This function will create new leads from the account Ids passed into it
     *
     * @param acctIds   The account Ids to query and convert into leads
     *
     * @return          The new list of constructed leads
     */
    public List<Lead> createNewLeads(Set<Id> acctIds) {
        List<Lead> newLeads = new List<Lead>();

        for (Account acct : (List<Account>)Database.query(accountQuery+' WHERE Id IN :acctIds')) {

            //If the most recent lead is still "open' we don't want to create another
            if (accountNeedsNewLead(acct)) {
                Lead l = (Lead) JSON.deserialize(JSON.serializePretty(Lead.getSObjectType().newSObject(null,true), true), Lead.class) ;
                l.OwnerId = queueId;

                for (String fld : accountToLeadMap.keySet()) {
                    l.put(accountToLeadMap.get(fld), acct.get(fld));
                }

                for (String fld : leadToStaticTextMap.keySet()) {
                    l.put(fld, leadToStaticTextMap.get(fld));
                }

                newLeads.add(l);
            }
        }

        return newLeads;
    }

    /**
     * @description This function will construct an account with the Id and the new lead Id defined
     *
     * @param leads The leads the construct the accounts from
     *
     * @return      The list of accounts to update
     */
    private List<Account> updateAccountWithNewLeadId(List<Lead> leads) {
        List<Account> accounts2Update = new List<Account>();

        for (Lead l : leads) {
            if (l.Id != null && l.PrimaryAccount__c != null) accounts2Update.add(new Account(Id = l.PrimaryAccount__c, MostRecentLead__c = l.Id));
        }
        return accounts2Update;
    }

    /**
     * @description This function will evaluate if an account needs to be a new lead
     *
     * @param acct  The account to evaluate
     *
     * @return      If a new lead is needed for the account
     */
    public static Boolean accountNeedsNewLead(Account acct) {
        return (acct.MostRecentLead__c == null || acct.MostRecentLead__r.fml_LeadClosed__c || acct.MostRecentLead__r.Status.contains('Booked') || acct.MostRecentLead__r.IsConverted);
    }

    /**
     * @description This function will populate the field mappings
     */
    private void populateFieldMappings() {
        this.fieldMapPopulated = true;

        for (String fld : atlfmlMap.keySet()) {
            Account_To_Lead_Field_Map__mdt atlfm = atlfmlMap.get(fld);

            if (atlfm.IsStaticText__c) this.leadToStaticTextMap.put(fld, atlfm.TargetFieldStaticText__c);
            if (!atlfm.IsStaticText__c) this.accountToLeadMap.put(fld, atlfm.TargetFieldStaticText__c);
        }

    }

    public class TC_AccountToLeadException extends Exception{}

}