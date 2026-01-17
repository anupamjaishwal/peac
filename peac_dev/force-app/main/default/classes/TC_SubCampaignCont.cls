public without sharing class TC_SubCampaignCont {
    private TC_ListViewUtil lvu {
        get {
            if (this.lvu == null) this.lvu = new TC_ListViewUtil('Account');
            return this.lvu;
        }
        set;
    }

    public List<SelectOption> listViews {
        get {
            if (this.listViews == null) this.listViews = this.lvu.listViewsAsSelectOptions;
            return this.listViews;
        }
        set;
    }

    private Map<String, String> params {
        get {
            if (this.params == null) params = ApexPages.currentPage().getParameters();
            return params;
        }
        set;
    }

    public Boolean doCloneAutoFollowups {
        get {
            if (this.doCloneAutoFollowups == null) this.doCloneAutoFollowups = false;
            return this.doCloneAutoFollowups;
        }
        set;
    }

    public Campaign subCamp {
        get {
            if (subCamp == null) {
                System.debug(existingSubCampaignId);
                System.debug(parentCampaignId);
                if (existingSubCampaignId != null && parentCampaignId == null) this.subCamp = [SELECT Id, Name, ParentId, Parent.Name, ListViewDeveloperName__c FROM Campaign WHERE Id = :existingSubCampaignId];
                if (parentCampaignId != null && existingSubCampaignId == null) this.subCamp = new Campaign(ParentId = parentCampaignId);
                if (subCamp != null && subCamp.Id != null) this.listViewVal = subCamp.ListViewDeveloperName__c;
            }
            return this.subCamp;
        }
        set;
    }
    //This property should be set if it's an existing sub campaign
    public Id existingSubCampaignId {
        get {
            if (this.existingSubCampaignId == null && parentCampaignId == null && params.containsKey('existingSubCampaignId')) this.existingSubCampaignId = params.get('existingSubCampaignId');
            return this.existingSubCampaignId;
        }
        set;
    }

    public Id parentCampaignId {
        get {
            if (this.parentCampaignId == null && params.containsKey('parentCampaignId')) this.parentCampaignId = params.get('parentCampaignId');
            return this.parentCampaignId;
        }
        set;
    }

    public TC_SubCampaignCont() {
    }

    public String listViewVal {
        get;
        set {
            if (listViewVal != value) {
                subCamp.ListViewDeveloperName__c = value;
                listViewVal = value;
            }
        }
    }

    public void actionFunction() {}
    
    public PageReference saveSubCampaign() {
        PageReference pr;
        if (String.isBlank(this.subCamp.ListViewDeveloperName__c)) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'A list view must be selected'));
        if (String.isNotBlank(this.subCamp.ListViewDeveloperName__c)) {
            if (this.subCamp.Name == null) this.subCamp.Name = this.lvu.getListViewMap(new Set<String>{this.subCamp.ListViewDeveloperName__c}).get(this.subCamp.ListViewDeveloperName__c).Name;
            Database.SaveResult sr;
            if (this.subCamp.Id == null) sr = Database.insert(this.subCamp);
            if (this.subCamp.Id != null) sr = Database.update(this.subCamp);
            if (this.parentCampaignId != null && this.existingSubCampaignId == null && this.doCloneAutoFollowups) cloneAutoFollowups(this.subCamp.Id);

            if (sr.errors.isEmpty()) pr = new PageReference('/'+this.subCamp.Id);
            if (!sr.errors.isEmpty()) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, sr.errors[0].getMessage()));
            if (pr != null) pr.setRedirect(true);
        }
        System.debug(pr);
        return pr;
    }

    @TestVisible void cloneAutoFollowups(Id newCampId) {
        List<Auto_Follow_Up__c> newAfus = new List<Auto_Follow_Up__c>();
        List<Auto_Follow_Up__c> existingAfus = (List<Auto_Follow_Up__c>) TC_DatabaseUtil.queryManyObjectsFields('Auto_Follow_Up__c', new Map<Id, Auto_Follow_Up__c>([SELECT Id FROM Auto_Follow_Up__c WHERE Campaign__c = :this.parentCampaignId]).keySet());
        for (Auto_Follow_Up__c afu : existingAfus) {
            Auto_Follow_Up__c newAfu = afu.clone(false,false,false,false);
            newAfu.Campaign__c = newCampId;
            newAfus.add(newAfu);
        }
        insert newAfus;
    }
    
    public PageReference cancelSubCampaign() {
        PageReference pr;
        String url = '/';

        if (parentCampaignId != null) url+= this.parentCampaignId;
        if (parentCampaignId == null && existingSubCampaignId != null) url+= this.existingSubCampaignId;

        pr = new PageReference(url);
        pr.setRedirect(true);

        return pr;
    }
}