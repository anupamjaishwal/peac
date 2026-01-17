public without sharing class SL_DealerPortalCreateAppQ implements Queueable, Database.AllowsCallouts {
    String action;
    Opportunity theOpportunity;
    Boolean isToUpdateOpp;
    public SL_DealerPortalCreateAppQ(String action, Opportunity theOpportunity, Boolean isToUpdateOpp) {
        this.action = action;
        this.theOpportunity = theOpportunity;
        this.isToUpdateOpp = isToUpdateOpp;
    }
    public void execute(QueueableContext context) {
        switch on action {
            when 'callDwhAndAutoPgApi' {
                String resp = TC_LoanApplicationCtrl.getApplicationById(theOpportunity.Id);
                if(!Test.isRunningTest()){
                    TC_LoanApplicationCtrl.callDwhAndAutoPgApi(resp);
                    System.enqueueJob(new SL_DealerPortalCreateAppQ('lastUpdateToApp', theOpportunity, true));
                }
            }
            when 'lastUpdateToApp' {
                if(isToUpdateOpp){
                    update theOpportunity;
                }
                TC_GdsScoreApi.runGdsScoreFromTriggeredAction(new Set <Id> {theOpportunity.Id});
            }
        }
    }
}