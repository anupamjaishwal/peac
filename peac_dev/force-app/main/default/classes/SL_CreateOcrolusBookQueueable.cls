public with sharing class SL_CreateOcrolusBookQueueable implements Queueable, Database.AllowsCallouts {
    private Id oppId;
    private String executionType;

    public SL_CreateOcrolusBookQueueable(Id oppId, String executionType) {
        this.oppId = oppId;
        this.executionType = executionType;
    }

    public void execute(QueueableContext context) {
        String pk;
        try {
            pk = TC_OcrolusService.addBookCallout(oppId);
        } catch (Exception e) {
            System.debug('SL_CreateOcrolusBookQueueable call failed: ' + e.getMessage());
        }

        // Chain next job
        if(pk != null)
        {
            if(!Test.isRunningTest() && executionType != Label.PEAC_Initiate_Loan_App_to_GDS )System.enqueueJob(new SL_CaseCenterStoredProcedureQueueable(new List<String>{'getGdsGetCustCreditExpLoan', 'getGDSFraudFlags'},oppId, executionType)); 
            if(!Test.isRunningTest() && executionType == Label.PEAC_Initiate_Loan_App_to_GDS)System.enqueueJob(new SL_sendAttachmentsQueueable(oppId, false));

        }
    }
}