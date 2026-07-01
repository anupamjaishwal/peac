public with sharing class PEAC_AutoCaseCenterNumberQueueable implements Queueable, Database.AllowsCallouts {
    private Id oppId;
    private String executionType;

    public PEAC_AutoCaseCenterNumberQueueable(Id oppId, String executionType) {
        this.oppId = oppId;
        this.executionType = executionType;
    }

    public void execute(QueueableContext context) {
        try {
            Set<Id> oppIdSet = New Set<Id>();
            oppIdSet.add(oppId);
            PEAC_AutoCaseCenterNumber.updateOppAppNumber(oppIdSet);
        } catch (Exception e) {
            System.debug('PEAC_AutoCaseCenterNumber call failed: ' + e.getMessage());
        }


        // Chain next job
        if(!Test.isRunningTest()) System.enqueueJob(new SL_CreateOcrolusBookQueueable(oppId, executionType));     

        
    }
}