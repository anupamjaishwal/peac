public with sharing class TC_InfoLeaseBookQueueable implements Queueable, Database.AllowsCallouts {
    public Id opportunityId;
    public String error;

    public TC_InfoLeaseBookQueueable(Id opportunityId) {
        this.opportunityId = opportunityId;
        System.debug(opportunityId);
    }

    public void execute(QueueableContext context) {
        try {
            error = TC_BridgewareUtility.sendToBridgeware(opportunityId).responseMessageDesc;
        }
        catch (Exception e) {
            error = e.getMessage();
        }
        
        Opportunity opp = new Opportunity();
        opp.Id = opportunityId;
        opp.Auto_Book_to_InfoLease_Message__c = error;
        update opp;
    }
}