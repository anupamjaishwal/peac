public with sharing class TC_AspireSubmitQueueable implements Queueable, Database.AllowsCallouts {
    public Id opportunityId;
    public String error;

    public TC_AspireSubmitQueueable(Id opportunityId) {
        this.opportunityId = opportunityId;
        System.debug(opportunityId);
        
        error = TC_ASPIREAPI.refreshASPIREData(opportunityId);
    }

    public void execute(QueueableContext context) {
        if (String.isEmpty(error))
            error = TC_ASPIREAPI.sendToAspire(opportunityId);

        if (String.isEmpty(error))
            error = 'Opportunity has been submitted successfully to Aspire API.';
        
        Opportunity opp = new Opportunity();
        opp.Id = opportunityId;
        opp.Auto_Submit_to_Aspire_Message__c = error;
        update opp;
    }
}