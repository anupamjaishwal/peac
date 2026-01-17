/**
 * @description This is the main batch class that will shift values for any matching accounts
 * @see         SAL-2037
 */
public without sharing class TC_SubCampaignBatch implements Database.Batchable<SObject>,Database.Stateful, Database.AllowsCallouts{

    public JobSequence js {get;set;}
    public Id campaignId {get;set;}
    public Campaign camp {
        get {
            if (this.camp == null && this.campaignId != null) this.camp = [SELECT Id, Name FROM Campaign WHERE Id = :this.campaignId];
            return this.camp;
        }
        set;
    }

    public String query {get;set;}

    public TC_SubCampaignBatch () {

    }

    public TC_SubCampaignBatch(JobSequence js, Id campaignId, String query) {
        this.js = js;
        this.campaignId = campaignId;
        this.query = query;
        System.debug('TC_SubCampaignBatch query:'+query);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator returnLocator;
        try {
            query = String.isBlank(query) ? 'SELECT Id FROM User LIMIT 0' : query;
            returnLocator = Database.getQueryLocator(query);
        } catch (Exception e) {
            js.logError(BC.getJobId(), e, null);
            returnLocator = Database.getQueryLocator('SELECT Id FROM '+query.toUpperCase().substringAfterLast(' FROM ').substringBefore(' ')+' LIMIT 0');
        }

        return returnLocator;
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        //If there is a campaign found and the records are accounts, we'll set the target campaign as the current campaign
        if (camp != null && !scope.isEmpty() && scope[0].getSObjectType() == Account.getSObjectType()) {
            List<Account> accts = (List<Account>) scope;
            for (Account acct : accts) {
                acct.Target_SDR_Campaign__c = camp.Name;
            }
            JobSequenceUtilities.logErrors(js, JobSequenceUtilities.attemptJobSequenceDML(accts, 'UPDATE', js.allOrNone), new Map<Id, SObject>(accts).keySet());
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('finish');
        //Once the batch has finished processing, we'll enqueue the next job
        if (!Test.isRunningTest()) System.enqueueJob(new TC_SubCampaignQueueable(this.js, this.campaignId));
    }

}