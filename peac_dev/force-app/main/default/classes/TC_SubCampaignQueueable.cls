/**
 * @description This class is designed to handle a queueable hand off so a list view for a sub-campaign can be
 * be queried via call out, then a batch job gets executed.
 * @see         SAL-2037
 */
public without sharing class TC_SubCampaignQueueable implements Queueable, Database.AllowsCallouts {
    public JobSequence js {get;set;}
    public List<Campaign> subCampaigns {
        get {
            if (this.subCampaigns == null & js != null) this.subCampaigns = Database.query(js.query);
            return this.subCampaigns;
        }
        set;
    }
    public Id lastSubCampaignId {get;set;}
    @TestVisible Campaign thisSubCampaign;

    public TC_SubCampaignQueueable() {

    }

    public TC_SubCampaignQueueable (JobSequence js, List<Campaign> subCampaigns) {
        this.subCampaigns = subCampaigns;
        this.js = js;
    }
    public TC_SubCampaignQueueable (JobSequence js) {
        this.js = js;
    }

    public TC_SubCampaignQueueable (JobSequence js, Id lastSubCampaignId) {
        this.js = js;
        this.lastSubCampaignId = lastSubCampaignId;
        System.debug(this.lastSubCampaignId);
    }

    public void execute(QueueableContext context) {
        String query;
        //Going through each active sub campaign and attempting to find the next in the list (if one is not defined, the first one will be used)
        for (Integer i = 0; i < this.subCampaigns.size(); i++) {
            Campaign camp = this.subCampaigns[i];

            //If there was a campaign id previously processed, we'll attempt to get the next one
            if (this.lastSubCampaignId != null && this.lastSubCampaignId == camp.Id && (i + 1) < this.subCampaigns.size()) this.thisSubCampaign = this.subCampaigns[(i + 1)];

            //If there no campaign Id has processed, we'll grab the first one
            if (this.lastSubCampaignId == null && this.lastSubCampaignId == null)  this.thisSubCampaign = camp;

            //If there is a sub-campaign assigned, we'll get the query from the list view
            if (this.thisSubCampaign != null) query = getListViewQuery();
            //If we've found a sub campaign, we'll exit the loop
            if (this.thisSubCampaign != null && String.isNotBlank(query)) break;
        }

        //If there is a sub campaign, we'll need to batch it up
        if (this.thisSubCampaign != null && String.isNotBlank(query)) {
            TC_SubCampaignBatch scb = new TC_SubCampaignBatch(this.js, this.thisSubCampaign.Id, query);
            Database.executeBatch(scb, (this.js != null ? this.js.batchSize : 50));
        }

        //If there was no new sub campaign found, and there's a job sequence, we'll queue up the next sequence job
        if (this.thisSubCampaign == null && this.js != null && !Test.isRunningTest()) System.enqueueJob(new JobSequenceQueueable(js));
    }

    /**
     * @description This function will get the list view query
     *
     * @return      The query for the list view
     */
    private String getListViewQuery() {
        String returnVal;
        if (this.thisSubCampaign != null) {
            List<ListView> lvs = [SELECT Id, SobjectType FROM ListView WHERE DeveloperName = :this.thisSubCampaign.ListViewDeveloperName__c];
            if (!lvs.isEmpty()) {
                returnVal = new TC_ListViewUtil('Account').getListViewConditions(lvs[0]);
            }
        }
        
        return returnVal;
    }
}