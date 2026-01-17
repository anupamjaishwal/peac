public without sharing class NewLeadButtonCont {

    private Id startingId {get; set;}

    public Boolean displayNavButton {
        get {
            if (this.displayNavButton == null) this.displayNavButton = true;
            return this.displayNavButton;
        }
        set;
    }
    private String accountRecordTypeName {
        get {
            if (this.accountRecordTypeName == null) this.accountRecordTypeName = 'End User';
            return this.accountRecordTypeName;
        }
        set;
    }
    private Database.SaveResult sr {

        get;

        set {
            if (value != null && value != this.sr) {

                this.sr = value;
                if (!value.isSuccess()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, sr.getErrors()[0].getMessage()));
            }
        }
    }

    public Boolean hasMessage {

        get {
            return !ApexPages.getMessages().isEmpty();
        }
    }

    public Lead thisLead {

        get {
            if (this.thisLead == null && !this.leadCheckDone) {

                this.leadCheckDone = true;
                checkForLead();
            }
            return this.thisLead;
        }

        set;
    }

    private Boolean leadCheckDone {

        get {
            if (this.leadCheckDone == null) this.leadCheckDone = false;
            return this.leadCheckDone;
        }

        set;
    }

    /**
     * @description The initial constructor
     *
     * @param sc    The standard controller
     */
    public NewLeadButtonCont (ApexPages.StandardController sc) {

        if (sc != null) this.startingId = sc.getId();
    }

    /**
     * @description This function will be the initial action when the page is loaded
     *
     * @return      The page reference to re-direct or display the error message
     */
    public PageReference doInit() {

        PageReference pr;
        if (this.thisLead != null && !this.hasMessage) pr = new PageReference('/'+this.thisLead.Id);

        if (pr != null) pr.setRedirect(true);

        return pr;
    }

    /**
     * @description This function will navigate to the next page
     *
     * @return      The page reference to re-direct to the next page
     */
    public PageReference navToNextPage() {

        PageReference pr;
        if (!ApexPages.getMessages().isEmpty()) {
            System.debug(ApexPages.getMessages()[0].getSummary());
            System.debug(ApexPages.getMessages()[0].getDetail());
        }

        if (this.thisLead != null && this.thisLead.OwnerId.getSobjectType() != User.getSObjectType()) {
            ApexPages.getMessages().clear();
            upsertLead();
        }

        if (this.thisLead != null && ApexPages.getMessages().isEmpty()) pr = new PageReference('/'+this.thisLead.Id);

        if (pr != null) pr.setRedirect(true);

        return pr;
    }

    /**
     * @description This function will check and assign a lead as needed
     */
    private void checkForLead() {

        List<Lead> leads = queryLeads();

        if (!leads.isEmpty()) {

            this.thisLead = leads[0];
            System.debug(this.thisLead.OwnerId.getSobjectType() != User.getSObjectType());
            if (this.thisLead.OwnerId.getSobjectType() == User.getSObjectType()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, String.format(Label.New_Lead_Existing_Lead_Error, new List<String>{this.thisLead.Owner.Name})));
                if (this.thisLead.OwnerId.getSobjectType() != User.getSObjectType()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.New_Lead_Existing_Lead_Unassigned_Warning));
        }

        if (leads.isEmpty()) processNewLead();
    }

    /**
     * @description This function will process a new lead if needed
     */
    private void processNewLead() {

        //List<Account> accts = [SELECT Id, RecordTypeId, RecordType.Name FROM Account WHERE Id = :this.startingId AND CurrentCampaign__c <> null];
          List<Account> accts = [SELECT Id, RecordTypeId, RecordType.Name FROM Account WHERE Id = :this.startingId];
        /*if (accts.isEmpty()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There is no campaign associated with this account!'));
            this.displayNavButton = false;
        }*/
        System.debug(accts.isEmpty());
        if (!accts.isEmpty()) {
            this.accountRecordTypeName = accts[0].RecordTypeId != null ? accts[0].RecordType.Name : this.accountRecordTypeName;
            List<Lead> leads = new TC_AccountToLead().createNewLeads(new Set<Id>{this.startingId});
            this.thisLead = leads[0];
            Map<String, RecordTypeInfo> leadRtByDevNm = Lead.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName();
            /*if (String.isNotBlank(this.accountRecordTypeName) && this.accountRecordTypeName.contains('Dealer') && leadRtByDevNm.get('Dealer_Vendor_Franchisor') != null) this.thisLead.RecordTypeId = leadRtByDevNm.get('Dealer_Vendor_Franchisor').getRecordTypeId();
            if (String.isNotBlank(this.accountRecordTypeName) && !this.accountRecordTypeName.contains('Dealer') && leadRtByDevNm.get('End_User_Franchisee') != null) this.thisLead.RecordTypeId = leadRtByDevNm.get('End_User_Franchisee').getRecordTypeId();*/
            this.thisLead.RecordTypeId = leadRtByDevNm.get('End_User_Franchisee').getRecordTypeId();
            system.debug('===========thisLead'+ thisLead);
            upsertLead();
        }
    }

    /**
     * @description This function will assign the lead and set the status then insert or update it
     */
    private void upsertLead() {
        this.thisLead.OwnerId = UserInfo.getUserId();
        for (Task t : thisLead.Tasks) t.OwnerId = UserInfo.getUserId();
        List<Database.SaveResult> srs;

        //this.thisLead.Status = 'Prospecting';

        try {
            if (thisLead.Id == null) this.sr = Database.insert(this.thisLead);
            //if (thisLead.Id != null) this.sr = Database.update(this.thisLead);
            System.debug(this.sr);
            if (this.sr.isSuccess()) this.sr = Database.update(new Account(Id = this.startingId, MostRecentLead__c = this.thisLead.Id));
            if (this.sr.isSuccess()) srs = Database.update(this.thisLead.Tasks, false);
            if (srs != null) for (Database.SaveResult sr : srs) if (!sr.isSuccess()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, sr.getErrors()[0].getMessage()));

        } catch (Exception e) {
            System.debug(e.getStackTraceString());
            System.debug(e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    /**
     * @description This function will query leads based on the id passed through the standard controller
     *
     * @return      The queried leads
     */
    private List<Lead> queryLeads() {

        return [
                SELECT      Id, OwnerId, Owner.Name,
                (SELECT Id FROM Tasks WHERE IsClosed = FALSE AND AutoFollowUp__c <> NULL AND fml_Owner_Is_A_Queue__c = TRUE ORDER BY TargetDateTime__c DESC)
                FROM        Lead
                WHERE       PrimaryAccount__c = :this.startingId AND fml_LeadClosed__c = FALSE
                ORDER BY    CreatedDate DESC
                LIMIT       1
        ];
    }

}