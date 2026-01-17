public class SL_CaseCenterStoredProcedureQueueable implements Queueable, Database.AllowsCallouts {
    private Id oppId;
    private List<String> storedProcedures;
    private String executionType;

    public SL_CaseCenterStoredProcedureQueueable(List<String> storedProcedures, Id oppId, String executionType) {
        this.storedProcedures = storedProcedures;
        this.oppId = oppId;
        this.executionType = executionType;
    }

    public void execute(QueueableContext context) {
        try {
            SL_CaseCenterStoredProcedure.SL_CaseCenterStoredProcedure(storedProcedures, oppId);
        } catch (Exception e) {
            System.debug('Stored procedure call failed: ' + e.getMessage());
        }

        // Chain next job
         if(!Test.isRunningTest())System.enqueueJob(new PEAC_GdsScoreLoanQueuable(executionType, oppId));
    }
}